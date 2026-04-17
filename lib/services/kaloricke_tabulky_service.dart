import 'dart:convert';
import 'dart:developer' as dev;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ─── Exceptions ───────────────────────────────────────────────────────────────

class KtAuthException implements Exception {
  final String message;
  const KtAuthException(this.message);

  @override
  String toString() => 'KtAuthException: $message';
}

class KtApiException implements Exception {
  final String message;
  const KtApiException(this.message);

  @override
  String toString() => 'KtApiException: $message';
}

// ─── Data model ───────────────────────────────────────────────────────────────

class KtDayNutrition {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  const KtDayNutrition({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
  });

  static const empty = KtDayNutrition(
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
    fiber: 0,
  );

  bool get hasData =>
      calories > 0 || protein > 0 || fat > 0 || carbs > 0 || fiber > 0;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class KalorickeTabulkyService {
  static const _base = 'https://www.kaloricketabulky.cz';

  static const _emailKey = 'kt_email';
  static const _pwdHashKey = 'kt_pwd_hash';

  static const _logName = 'KalorickeTabulkyService';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  String? _cookieHeader;
  bool _loggedIn = false;

  KalorickeTabulkyService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  bool get isLoggedIn => _loggedIn;

  // ─── Logging ────────────────────────────────────────────────────────────────

  void _logDebug(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName);
  }

  void _logInfo(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName, level: 800);
  }

  void _logWarning(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName, level: 900);
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    dev.log(
      message,
      name: _logName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts[0];
    final domain = parts[1];

    final maskedLocal = local.length <= 2
        ? '${local[0]}*'
        : '${local[0]}***${local[local.length - 1]}';

    return '$maskedLocal@$domain';
  }

  String _shortBody(String body, {int max = 300}) {
    final normalized = body.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= max) return normalized;
    return '${normalized.substring(0, max)}...';
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    _logInfo('login() called for ${_maskEmail(email)}');

    final pwdHash = md5.convert(utf8.encode(password)).toString();
    await _performLogin(email, pwdHash);

    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _pwdHashKey, value: pwdHash);

    _logInfo('Credentials stored for ${_maskEmail(email)}');
  }

  Future<bool> restoreSession() async {
    _logInfo('restoreSession() called');

    final email = await _storage.read(key: _emailKey);
    final pwdHash = await _storage.read(key: _pwdHashKey);

    if (email == null || pwdHash == null) {
      _logInfo('No stored KT credentials found');
      return false;
    }

    _logInfo('Stored credentials found for ${_maskEmail(email)}');
    await _performLogin(email, pwdHash);
    return true;
  }

  Future<String?> storedEmail() => _storage.read(key: _emailKey);

  Future<void> logout() async {
    _logInfo('logout() called');

    _cookieHeader = null;
    _loggedIn = false;
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _pwdHashKey);

    _logInfo('Session and stored credentials cleared');
  }

  // ─── Public data API ───────────────────────────────────────────────────────

  /// Diary summary endpoint expects date as dd.MM.yyyy
  Future<KtDayNutrition> fetchDaySummary(DateTime date) async {
    _assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    _logDebug('fetchDaySummary() for $dateString');

    final response = await _get(
      '$_base/user/diary/summary/$dateString/get?format=json',
    );

    final body = _decodeJson(response.body, context: dateString);
    final code = body['code'];
    final message = (body['message'] ?? '').toString().trim();

    _logDebug(
      'Diary summary parsed for $dateString: code=$code, message=${message.isEmpty ? "<empty>" : message}',
    );

    if (code == 0 || code == null) {
      final parsed = _parseDaySummary(
        (body['data'] as Map<String, dynamic>?) ?? const {},
      );

      _logInfo(
        'Day summary loaded for $dateString: kcal=${parsed.calories}, P=${parsed.protein}, F=${parsed.fat}, C=${parsed.carbs}, fiber=${parsed.fiber}',
      );

      return parsed;
    }

    final lowerMessage = message.toLowerCase();

    if (_looksLikeAuthProblem(lowerMessage)) {
      _loggedIn = false;
      _logWarning('Auth problem detected while loading $dateString: $message');
      throw KtAuthException(
        message.isNotEmpty ? message : 'Session expired',
      );
    }

    _logError(
      'KT diary summary failed for $dateString: code=$code, message=$message',
    );

    throw KtApiException(
      'KT diary summary failed: code=$code'
      '${message.isNotEmpty ? ', message=$message' : ''}',
    );
  }

  Future<KtDayNutrition> fetchTodayNutrition() {
    _logDebug('fetchTodayNutrition() called');
    return fetchDaySummary(DateTime.now());
  }

  /// Range endpoints use yyyy-MM-dd
  Future<Map<String, double>> fetchEnergyRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _assertLoggedIn();

    final startString = _formatRangeDate(start);
    final endString = _formatRangeDate(end);

    _logDebug('fetchEnergyRange() for $startString -> $endString');

    final response = await _get(
      '$_base/statistic/energy/$startString/$endString/get?format=json',
    );

    final body = _decodeJson(response.body, context: '$startString → $endString');
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final values = (data['values'] as List<dynamic>?) ?? const [];

    final result = {
      for (final raw in values)
        if (raw is Map<String, dynamic> && raw['description'] != null)
          raw['description'] as String: _parseDouble(raw['value']),
    };

    _logInfo(
      'Energy range loaded for $startString -> $endString, items=${result.length}',
    );

    return result;
  }

  /// Returns yyyy-MM-dd -> nutrition map.
  /// Calories and fiber are 0 because this endpoint does not provide them.
  Future<Map<String, KtDayNutrition>> fetchNutrientsRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _assertLoggedIn();

    final startString = _formatRangeDate(start);
    final endString = _formatRangeDate(end);

    _logDebug('fetchNutrientsRange() for $startString -> $endString');

    final response = await _get(
      '$_base/statistic/nutrients/$startString/$endString/get?format=json',
    );

    final body = _decodeJson(response.body, context: '$startString → $endString');
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final list = (data['nutrientsValues'] as List<dynamic>?) ?? const [];

    final result = <String, KtDayNutrition>{};

    for (final rawRec in list) {
      if (rawRec is! Map<String, dynamic>) continue;

      final tsMs = _parseTimestampMs(rawRec['createdDate']);
      final dt = DateTime.fromMillisecondsSinceEpoch(tsMs);
      final day = _formatRangeDate(dt);

      result[day] = KtDayNutrition(
        calories: 0,
        protein: _parseDouble((rawRec['protein'] as Map?)?['value']),
        fat: _parseDouble((rawRec['fat'] as Map?)?['value']),
        carbs: _parseDouble((rawRec['carbs'] as Map?)?['value']),
        fiber: 0,
      );
    }

    _logInfo(
      'Nutrients range loaded for $startString -> $endString, days=${result.length}',
    );

    return result;
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  Future<void> _performLogin(String email, String pwdHash) async {
    _logDebug('Performing KT login for ${_maskEmail(email)}');

    final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('$_base/login/create?=&format=json'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': pwdHash,
        }),
      );
    } catch (e, st) {
      _logError('Network error during login', e, st);
      throw KtApiException('Network error during login: $e');
    }

    _logDebug(
      'Login HTTP response: status=${response.statusCode}, body=${_shortBody(response.body)}',
    );

    if (response.statusCode != 200) {
      _logError('Login failed with HTTP ${response.statusCode}');
      throw KtApiException('Login failed with HTTP ${response.statusCode}');
    }

    final body = _decodeJson(response.body, context: 'login');

    if (body['code'] != 0) {
      final message = (body['message'] ?? 'Invalid credentials').toString();
      _logWarning('Login rejected for ${_maskEmail(email)}: $message');
      throw KtAuthException(message);
    }

    _cookieHeader = _extractCookies(response);
    _loggedIn = true;

    _logInfo(
      'Login successful for ${_maskEmail(email)}, cookiesPresent=${_cookieHeader != null && _cookieHeader!.isNotEmpty}',
    );
  }

  void _assertLoggedIn() {
    if (!_loggedIn) {
      _logWarning('_assertLoggedIn() failed: not logged in');
      throw const KtAuthException('Not logged in');
    }
  }

  Future<http.Response> _get(String url) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (_cookieHeader != null && _cookieHeader!.isNotEmpty) {
      headers['Cookie'] = _cookieHeader!;
    }

    _logDebug(
      'GET $url | hasCookie=${headers.containsKey("Cookie")}',
    );

    final http.Response response;
    try {
      response = await _client.get(Uri.parse(url), headers: headers);
    } catch (e, st) {
      _logError('Network error during GET $url', e, st);
      throw KtApiException('Network error: $e');
    }

    _logDebug(
      'GET response: status=${response.statusCode}, url=$url, body=${_shortBody(response.body)}',
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      _loggedIn = false;
      _logWarning('Session expired for GET $url');
      throw const KtAuthException('Session expired');
    }

    if (response.statusCode != 200) {
      _logError('GET failed: HTTP ${response.statusCode} for $url');
      throw KtApiException('HTTP ${response.statusCode}');
    }

    return response;
  }

  Map<String, dynamic> _decodeJson(String body, {required String context}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object');
      }
      return decoded;
    } catch (e, st) {
      _logError(
        'Invalid JSON from API ($context). Raw body=${_shortBody(body)}',
        e,
        st,
      );
      throw KtApiException('Invalid JSON from API ($context)');
    }
  }

  KtDayNutrition _parseDaySummary(Map<String, dynamic> data) {
    final calories = _parseDouble(data['foodstuffEnergyTotal']);

    double protein = 0;
    double fat = 0;
    double carbs = 0;
    double fiber = 0;

    final itemsDynamic = data['itemsDynamic'];
    if (itemsDynamic is List) {
      for (final category in itemsDynamic) {
        if (category is! List) continue;

        for (final entry in category) {
          if (entry is! Map) continue;

          final code = entry['code']?.toString();
          final value = _parseDouble(entry['actual']);

          if (code == 'protein') {
            protein = value;
          } else if (code == 'fat') {
            fat = value;
          } else if (code == 'carbohydrate') {
            carbs = value;
          } else if (code == 'fiber') {
            fiber = value;
          }
        }
      }
    }

    return KtDayNutrition(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
    );
  }

  bool _looksLikeAuthProblem(String message) {
    return message.contains('login') ||
        message.contains('auth') ||
        message.contains('session') ||
        message.contains('přihl');
  }

  int _parseTimestampMs(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  String? _extractCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      _logWarning('No set-cookie header found in login response');
      return null;
    }

    final cookies = setCookie
        .split(RegExp(r',\s*(?=[A-Za-z0-9_\-]+=)'))
        .map((c) => c.trim().split(';').first.trim())
        .where((c) => c.contains('='))
        .join('; ');

    final result = cookies.isNotEmpty ? cookies : null;

    _logDebug(
      'Cookies extracted: count=${result == null ? 0 : result.split("; ").length}',
    );

    return result;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    return double.tryParse(_cleanNumString(value.toString())) ?? 0.0;
  }

  String _cleanNumString(String raw) {
    return raw
        .replaceAll('\u00a0', '')
        .replaceAll('\u202f', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
  }

  String _formatRangeDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDiaryDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year.toString().padLeft(4, '0')}';
  }
}