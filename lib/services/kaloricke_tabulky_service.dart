import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/app_log.dart';

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
  final double sugar;
  final double salt;
  final double saturatedFat;
  final double drinkRegime;
  final int foodCount;
  final DateTime lastSyncedAt;

  KtDayNutrition({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    this.sugar = 0,
    this.salt = 0,
    this.saturatedFat = 0,
    this.drinkRegime = 0,
    this.foodCount = 0,
    DateTime? lastSyncedAt,
  }) : lastSyncedAt = lastSyncedAt ?? DateTime(0);

  bool get hasData => foodCount > 0 || calories > 0 || protein > 0;

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
        'salt': salt,
        'saturatedFat': saturatedFat,
        'drinkRegime': drinkRegime,
        'foodCount': foodCount,
        'lastSyncedAt': lastSyncedAt.millisecondsSinceEpoch,
      };

  factory KtDayNutrition.fromJson(Map<String, dynamic> json) => KtDayNutrition(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
        salt: (json['salt'] as num?)?.toDouble() ?? 0,
        saturatedFat: (json['saturatedFat'] as num?)?.toDouble() ?? 0,
        drinkRegime: (json['drinkRegime'] as num?)?.toDouble() ?? 0,
        foodCount: (json['foodCount'] as num?)?.toInt() ?? 0,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncedAt'] as int)
            : null,
      );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class KalorickeTabulkyService {
  static const _base = 'https://www.kaloricketabulky.cz';

  static const _emailKey = 'kt_email';
  static const _pwdHashKey = 'kt_pwd_hash';

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

  // ─── Helpers ───────────────────────────────────────────────────────────────

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
    final normalized =
        body.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= max) return normalized;
    return '${normalized.substring(0, max)}...';
  }

  String _previewKeys(Iterable<Object?> keys, {int max = 12}) {
    final list = keys.map((k) => '$k').toList()..sort();
    if (list.isEmpty) return '<none>';
    if (list.length <= max) return list.join(', ');
    final shown = list.take(max).join(', ');
    return '$shown ... (+${list.length - max} more)';
  }

  String _describeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) return 'Map(keys=${_previewKeys(value.keys)})';
    if (value is List) return 'List(len=${value.length})';
    if (value is String) return '"${_shortBody(value, max: 80)}"';
    return '$value';
  }

  String _describeFields(Map<String, dynamic> data, List<String> keys) {
    return keys.map((key) => '$key=${_describeValue(data[key])}').join(', ');
  }

  String _describeNutrition(KtDayNutrition nutrition) {
    return 'kcal=${nutrition.calories}, '
        'P=${nutrition.protein}, '
        'F=${nutrition.fat}, '
        'C=${nutrition.carbs}, '
        'fiber=${nutrition.fiber}, '
        'sugar=${nutrition.sugar}, '
        'salt=${nutrition.salt}, '
        'satFat=${nutrition.saturatedFat}, '
        'drink=${nutrition.drinkRegime}, '
        'foods=${nutrition.foodCount}, '
        'hasData=${nutrition.hasData}';
  }

  String _previewNutritionRange(Map<String, KtDayNutrition> result,
      {int max = 5}) {
    if (result.isEmpty) return '<none>';
    final keys = result.keys.toList()..sort();
    final preview =
        keys.take(max).map((key) => '$key(${_describeNutrition(result[key]!)})');
    final joined = preview.join('; ');
    if (keys.length <= max) return joined;
    return '$joined; ... (+${keys.length - max} more)';
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    AppLog.ktApi.info('login() called for ${_maskEmail(email)}');

    final pwdHash = md5.convert(utf8.encode(password)).toString();
    await _performLogin(email, pwdHash);

    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _pwdHashKey, value: pwdHash);

    AppLog.ktApi.success('Credentials stored for ${_maskEmail(email)}');
  }

  Future<bool> restoreSession() async {
    AppLog.ktApi.info('restoreSession() called');

    final email = await _storage.read(key: _emailKey);
    final pwdHash = await _storage.read(key: _pwdHashKey);

    if (email == null || pwdHash == null) {
      AppLog.ktApi.info('No stored KT credentials found');
      return false;
    }

    AppLog.ktApi.info('Stored credentials found for ${_maskEmail(email)}');
    await _performLogin(email, pwdHash);
    return true;
  }

  Future<String?> storedEmail() => _storage.read(key: _emailKey);

  Future<void> logout() async {
    AppLog.ktApi.info('logout() called');

    _cookieHeader = null;
    _loggedIn = false;
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _pwdHashKey);

    AppLog.ktApi.info('Session and stored credentials cleared');
  }

  // ─── Public data API ───────────────────────────────────────────────────────

  /// Diary summary endpoint expects date as dd.MM.yyyy
  Future<KtDayNutrition> fetchDaySummary(DateTime date) async {
    _assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    AppLog.ktApi.debug('fetchDaySummary() for $dateString');

    final response = await _get(
      '$_base/user/diary/summary/$dateString/get?format=json',
    );

    final body = _decodeJson(response.body, context: dateString);
    final code = body['code'];
    final message = (body['message'] ?? '').toString().trim();

    AppLog.ktApi.debug(
      'Diary summary response for $dateString: '
      'code=$code, message=${message.isEmpty ? "<empty>" : message}',
    );

    if (code == 0 || code == null) {
      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      AppLog.ktParse.debug(
        'Day summary raw for $dateString: '
        '${_describeFields(data, ['foodstuffEnergyTotal', 'items', 'itemsDynamic'])}; '
        'keys=${_previewKeys(data.keys)}',
      );
      final parsed = _parseDaySummary(data);
      AppLog.ktApi.success(
        'Day summary loaded for $dateString',
        payload: 'kcal=${parsed.calories}, P=${parsed.protein}, '
            'F=${parsed.fat}, C=${parsed.carbs}, fiber=${parsed.fiber}',
      );
      return parsed;
    }

    final lowerMessage = message.toLowerCase();

    if (_looksLikeAuthProblem(lowerMessage)) {
      _loggedIn = false;
      AppLog.ktApi.warn(
          'Auth problem while loading summary $dateString: $message');
      throw KtAuthException(
        message.isNotEmpty ? message : 'Session expired',
      );
    }

    AppLog.ktApi.error(
      'Day summary failed for $dateString',
      payload: 'code=$code, message=$message',
    );

    throw KtApiException(
      'KT diary summary failed: code=$code'
      '${message.isNotEmpty ? ', message=$message' : ''}',
    );
  }

  Future<KtDayNutrition> fetchTodayNutrition() {
    AppLog.ktApi.debug('fetchTodayNutrition() called');
    return fetchDayNutritionMerged(DateTime.now());
  }

  /// Fetches both endpoints in parallel and merges results:
  /// - kcal and macros from the summary endpoint (diary top-level totals are always 0)
  /// - foodCount, drinkRegime, salt from the diary endpoint
  Future<KtDayNutrition> fetchDayNutritionMerged(DateTime date) async {
    _assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    AppLog.ktApi.debug('fetchDayNutritionMerged() for $dateString');

    final results = await Future.wait([
      fetchDaySummary(date),
      fetchDayDiary(date),
    ]);
    final summary = results[0];
    final diary = results[1];

    final merged = KtDayNutrition(
      calories: summary.calories,
      protein: summary.protein,
      fat: summary.fat,
      carbs: summary.carbs,
      fiber: summary.fiber,
      sugar: summary.sugar,
      saturatedFat: summary.saturatedFat,
      salt: diary.salt,
      drinkRegime: diary.drinkRegime,
      foodCount: diary.foodCount,
      lastSyncedAt: DateTime.now(),
    );
    AppLog.ktApi.success(
      'fetchDayNutritionMerged() for $dateString',
      payload: _describeNutrition(merged),
    );
    return merged;
  }

  /// Full diary endpoint — returns foodCount, drinkRegime, salt.
  /// NOTE: top-level totals (energyTotal, proteinTotal, etc.) are always 0.
  /// Use fetchDayNutritionMerged() to get correct macros.
  Future<KtDayNutrition> fetchDayDiary(DateTime date) async {
    _assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    AppLog.ktApi.debug('fetchDayDiary() → GET $dateString');

    final response = await _get(
      '$_base/user/diary/$dateString/get?format=json',
    );

    final body = _decodeJson(response.body, context: dateString);
    final code = body['code'];
    final message = (body['message'] ?? '').toString().trim();

    AppLog.ktApi.debug(
      'Day diary response for $dateString: '
      'code=$code, message=${message.isEmpty ? "<empty>" : message}',
    );

    if (code == 0 || code == null) {
      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      AppLog.ktParse.debug(
        'Day diary raw for $dateString: '
        '${_describeFields(data, [
              'energyTotal',
              'foodstuffEnergyTotal',
              'proteinTotal',
              'protein',
              'fatTotal',
              'fat',
              'carbohydrateTotal',
              'carbohydrate',
              'fiberTotal',
              'fiber',
              'foodstuffCount',
              'drinkRegime',
              'items',
              'itemsDynamic',
            ])}; keys=${_previewKeys(data.keys)}',
      );
      final parsed = _parseDayDiary(data);
      AppLog.ktApi.success(
        'Day diary loaded for $dateString',
        payload: 'kcal=${parsed.calories}, P=${parsed.protein}, '
            'F=${parsed.fat}, C=${parsed.carbs}, fiber=${parsed.fiber}, '
            'sugar=${parsed.sugar}, salt=${parsed.salt}, '
            'drink=${parsed.drinkRegime}, foods=${parsed.foodCount}',
      );
      return parsed;
    }

    final lowerMessage = message.toLowerCase();

    if (_looksLikeAuthProblem(lowerMessage)) {
      _loggedIn = false;
      AppLog.ktApi
          .warn('Auth problem while loading diary $dateString: $message');
      throw KtAuthException(
        message.isNotEmpty ? message : 'Session expired',
      );
    }

    AppLog.ktApi.error(
      'Day diary failed for $dateString',
      payload: 'code=$code, message=$message',
    );

    throw KtApiException(
      'KT day diary failed: code=$code'
      '${message.isNotEmpty ? ', message=$message' : ''}',
    );
  }

  /// Range endpoints use yyyy-MM-dd
  Future<Map<String, double>> fetchEnergyRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _assertLoggedIn();

    final startString = _formatRangeDate(start);
    final endString = _formatRangeDate(end);

    AppLog.ktApi.debug('fetchEnergyRange() $startString → $endString');

    final response = await _get(
      '$_base/statistic/energy/$startString/$endString/get?format=json',
    );

    final body =
        _decodeJson(response.body, context: '$startString → $endString');
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final values = (data['values'] as List<dynamic>?) ?? const [];

    final result = {
      for (final raw in values)
        if (raw is Map<String, dynamic> && raw['description'] != null)
          raw['description'] as String: _parseDouble(raw['value']),
    };

    AppLog.ktApi.success(
      'Energy range loaded $startString → $endString',
      payload: 'items=${result.length}',
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

    AppLog.ktApi.debug('fetchNutrientsRange() $startString ? $endString');

    final url =
        '$_base/statistic/nutrients/$startString/$endString/get?format=json';
    final headers = _buildGetHeaders();
    AppLog.ktApi.info(
      'Nutrient fetch request',
      payload:
          'method=GET, url=$url, headers=${_describeHeaders(headers)}',
    );

    final response = await _get(url, headers: headers);
    AppLog.ktApi.info(
      'Nutrient fetch response',
      payload: 'status=${response.statusCode}, body=${response.body}',
    );

    final body =
        _decodeJson(response.body, context: '$startString ? $endString');
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final list = (data['nutrientsValues'] as List<dynamic>?) ?? const [];
    AppLog.ktParse.debug(
      'Nutrients range raw: records=${list.length}, keys=${_previewKeys(data.keys)}',
    );

    final result = <String, KtDayNutrition>{};

    for (final rawRec in list) {
      if (rawRec is! Map<String, dynamic>) continue;

      final tsMs = _parseTimestampMs(rawRec['createdDate']);
      final dt = DateTime.fromMillisecondsSinceEpoch(tsMs);
      final day = _formatRangeDate(dt);

      final nutrition = KtDayNutrition(
        calories: 0,
        protein: _parseDouble((rawRec['protein'] as Map?)?['value']),
        fat: _parseDouble((rawRec['fat'] as Map?)?['value']),
        carbs: _parseDouble((rawRec['carbs'] as Map?)?['value']),
        fiber: 0,
      );
      result[day] = nutrition;
      AppLog.ktParse.debug(
        'Nutrients range day $day: '
        '${_describeFields(rawRec, ['createdDate', 'protein', 'fat', 'carbs'])} -> '
        '${_describeNutrition(nutrition)}',
      );
    }

    AppLog.ktApi.success(
      'Nutrients range loaded $startString → $endString',
      payload: 'days=${result.length}, preview=${_previewNutritionRange(result)}',
    );

    return result;
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  Future<void> _performLogin(String email, String pwdHash) async {
    AppLog.ktApi.debug('Performing KT login for ${_maskEmail(email)}');

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
      AppLog.ktApi.error('Network error during login', err: e, stackTrace: st);
      throw KtApiException('Network error during login: $e');
    }

    AppLog.ktApi.debug(
      'Login HTTP response: status=${response.statusCode}, '
      'body=${_shortBody(response.body)}',
    );

    if (response.statusCode != 200) {
      AppLog.ktApi.error(
          'Login failed with HTTP ${response.statusCode}');
      throw KtApiException('Login failed with HTTP ${response.statusCode}');
    }

    final body = _decodeJson(response.body, context: 'login');

    if (body['code'] != 0) {
      final message = (body['message'] ?? 'Invalid credentials').toString();
      AppLog.ktApi
          .warn('Login rejected for ${_maskEmail(email)}: $message');
      throw KtAuthException(message);
    }

    _cookieHeader = _extractCookies(response);
    _loggedIn = true;

    AppLog.ktApi.success(
      'Login OK for ${_maskEmail(email)}',
      payload: 'cookiesPresent=${_cookieHeader != null && _cookieHeader!.isNotEmpty}',
    );
  }

  void _assertLoggedIn() {
    if (!_loggedIn) {
      AppLog.ktApi.warn('_assertLoggedIn() failed: not logged in');
      throw const KtAuthException('Not logged in');
    }
  }

  Future<http.Response> _get(String url, {Map<String, String>? headers}) async {
    final requestHeaders = headers ?? _buildGetHeaders();

    AppLog.ktApi.debug(
      'GET $url',
      payload: 'hasCookie=${requestHeaders.containsKey("Cookie")}',
    );

    final http.Response response;
    try {
      response = await _client.get(Uri.parse(url), headers: requestHeaders);
    } catch (e, st) {
      AppLog.ktApi.error('Network error during GET $url',
          err: e, stackTrace: st);
      throw KtApiException('Network error: $e');
    }

    AppLog.ktApi.debug(
      'GET response: status=${response.statusCode}',
      payload: _shortBody(response.body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      _loggedIn = false;
      AppLog.ktApi.warn('Session expired — HTTP ${response.statusCode} for $url');
      throw const KtAuthException('Session expired');
    }

    if (response.statusCode != 200) {
      AppLog.ktApi
          .error('GET failed: HTTP ${response.statusCode} for $url');
      throw KtApiException('HTTP ${response.statusCode}');
    }

    return response;
  }

  Map<String, String> _buildGetHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (_cookieHeader != null && _cookieHeader!.isNotEmpty) {
      headers['Cookie'] = _cookieHeader!;
    }

    return headers;
  }

  String _describeHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return '{}';

    final described = <String, String>{};
    headers.forEach((key, value) {
      described[key] = key.toLowerCase() == 'cookie' ? '<present>' : value;
    });
    return described.toString();
  }

  Map<String, dynamic> _decodeJson(String body, {required String context}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object');
      }
      return decoded;
    } catch (e, st) {
      AppLog.ktParse.error(
        'Invalid JSON from API ($context)',
        payload: 'body=${_shortBody(body)}',
        err: e,
        stackTrace: st,
      );
      throw KtApiException('Invalid JSON from API ($context)');
    }
  }

  KtDayNutrition _parseDaySummary(Map<String, dynamic> data) {
    final summaryMetrics = _parseSummaryMetrics(data);

    double calories = _parseDouble(data['foodstuffEnergyTotal']);
    if (calories == 0) calories = summaryMetrics['total'] ?? 0;

    final parsed = KtDayNutrition(
      calories: calories,
      protein: summaryMetrics['protein'] ?? 0,
      fat: summaryMetrics['fat'] ?? 0,
      carbs: summaryMetrics['carbohydrate'] ?? 0,
      fiber: summaryMetrics['fiber'] ?? 0,
      sugar: summaryMetrics['sugar'] ?? 0,
      saturatedFat: summaryMetrics['saturatedFattyAcid'] ?? 0,
    );
    AppLog.ktParse.debug(
      '_parseDaySummary() → ${_describeNutrition(parsed)}',
      payload: _describeFields(
          data, ['foodstuffEnergyTotal', 'items', 'itemsDynamic']),
    );
    return parsed;
  }

  KtDayNutrition _parseDayDiary(Map<String, dynamic> data) {
    // Primary field names from the full diary endpoint.
    // Fallback to summary-style names in case the endpoint returns either format.
    final summaryMetrics = _parseSummaryMetrics(data);
    bool usedSummaryFallback = false;

    double calories = _parseDouble(data['energyTotal']);
    if (calories == 0) {
      calories = _parseDouble(data['foodstuffEnergyTotal']);
      if (calories != 0) usedSummaryFallback = true;
    }
    if (calories == 0) {
      calories = summaryMetrics['total'] ?? 0;
      if (calories != 0) usedSummaryFallback = true;
    }

    double protein = _parseDouble(data['proteinTotal']);
    if (protein == 0) protein = _parseDouble(data['protein']);
    if (protein == 0) {
      protein = summaryMetrics['protein'] ?? 0;
      if (protein != 0) usedSummaryFallback = true;
    }

    double fat = _parseDouble(data['fatTotal']);
    if (fat == 0) fat = _parseDouble(data['fat']);
    if (fat == 0) {
      fat = summaryMetrics['fat'] ?? 0;
      if (fat != 0) usedSummaryFallback = true;
    }

    double carbs = _parseDouble(data['carbohydrateTotal']);
    if (carbs == 0) carbs = _parseDouble(data['carbohydrate']);
    if (carbs == 0) {
      carbs = summaryMetrics['carbohydrate'] ?? 0;
      if (carbs != 0) usedSummaryFallback = true;
    }

    double fiber = _parseDouble(data['fiberTotal']);
    if (fiber == 0) fiber = _parseDouble(data['fiber']);
    if (fiber == 0) {
      fiber = summaryMetrics['fiber'] ?? 0;
      if (fiber != 0) usedSummaryFallback = true;
    }

    // Summary-style responses can carry secondary metrics only in items/itemsDynamic.
    // structure used by the summary endpoint — same data, different shape.
    double sugar = _parseDouble(data['sugarTotal']);
    if (sugar == 0) {
      sugar = summaryMetrics['sugar'] ?? 0;
      if (sugar != 0) usedSummaryFallback = true;
    }

    double saturatedFat = _parseDouble(data['saturatedFattyAcidTotal']);
    if (saturatedFat == 0) {
      saturatedFat = summaryMetrics['saturatedFattyAcid'] ?? 0;
      if (saturatedFat != 0) usedSummaryFallback = true;
    }

    if (calories == 0 && protein == 0 && fat == 0 && carbs == 0) {
      AppLog.ktParse.warn(
        '_parseDayDiary: all macros zero after all fallbacks',
        payload: 'data keys=${data.keys.toList()}',
      );
    }

    final parsed = KtDayNutrition(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      salt: _parseDouble(data['saltTotal']),
      saturatedFat: saturatedFat,
      drinkRegime: _parseDouble(data['drinkRegime']),
      foodCount: _parseInt(data['foodstuffCount']),
      lastSyncedAt: DateTime.now(),
    );
    AppLog.ktParse.debug(
      '_parseDayDiary() → ${_describeNutrition(parsed)}',
      payload: 'summaryFallback=$usedSummaryFallback, '
          '${_describeFields(data, [
            'energyTotal',
            'foodstuffEnergyTotal',
            'proteinTotal',
            'protein',
            'fatTotal',
            'fat',
            'carbohydrateTotal',
            'carbohydrate',
            'fiberTotal',
            'fiber',
            'sugarTotal',
            'saltTotal',
            'saturatedFattyAcidTotal',
            'drinkRegime',
            'foodstuffCount',
            'items',
            'itemsDynamic',
          ])}',
    );
    return parsed;
  }

  Map<String, double> _parseSummaryMetrics(Map<String, dynamic> data) {
    final metrics = <String, double>{};

    void addMetric(dynamic rawEntry) {
      if (rawEntry is! Map) return;

      final code = rawEntry['code']?.toString();
      if (code == null || code.isEmpty) return;

      final value = _parseSummaryMetricValue(rawEntry);
      final existing = metrics[code];

      if (existing == null || existing == 0 || value != 0) {
        metrics[code] = value;
      }
    }

    void addMetrics(dynamic rawEntries) {
      if (rawEntries is! List) return;

      for (final entry in rawEntries) {
        if (entry is List) {
          addMetrics(entry);
        } else {
          addMetric(entry);
        }
      }
    }

    addMetrics(data['items']);
    addMetrics(data['itemsDynamic']);
    return metrics;
  }

  double _parseSummaryMetricValue(Map rawEntry) {
    final actualValue = _parseDouble(rawEntry['actualValue']);
    final actual = _parseDouble(rawEntry['actual']);

    if (actualValue != 0) return actualValue;
    if (actual != 0) return actual;
    if (rawEntry.containsKey('actualValue')) return actualValue;
    return actual;
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
      AppLog.ktApi.warn('No set-cookie header found in login response');
      return null;
    }

    final cookies = setCookie
        .split(RegExp(r',\s*(?=[A-Za-z0-9_\-]+=)'))
        .map((c) => c.trim().split(';').first.trim())
        .where((c) => c.contains('='))
        .join('; ');

    final result = cookies.isNotEmpty ? cookies : null;

    AppLog.ktApi.debug(
      'Cookies extracted: count=${result == null ? 0 : result.split("; ").length}',
    );

    return result;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
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
