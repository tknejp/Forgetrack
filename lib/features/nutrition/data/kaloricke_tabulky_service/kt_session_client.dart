part of '../kaloricke_tabulky_service.dart';

class _KtSessionClient {
  http.Client _client;
  final bool _ownsClient;
  final FlutterSecureStorage _storage;

  String? _cookieHeader;
  bool _loggedIn = false;

  _KtSessionClient({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _storage = storage ?? const FlutterSecureStorage();

  /// Disposes the current keep-alive pool and creates a fresh client.
  /// No-op when the client was injected (tests) — they manage lifecycle.
  void _resetClient() {
    if (!_ownsClient) return;
    AppLog.ktApi.warn(
      'Resetting HTTP client — likely stale keep-alive socket after network change',
    );
    try {
      _client.close();
    } catch (_) {
      // Closing a client that's already disposed is fine.
    }
    _client = http.Client();
  }

  /// True for errors that typically indicate a pooled TLS socket bound to a
  /// network interface that no longer exists (Wi-Fi -> mobile data hand-off,
  /// VPN drop, sleep wake-up). The cure is to drop the pool and reconnect.
  bool _isStaleConnectionError(Object e) {
    if (e is SocketException) return true;
    if (e is HandshakeException) return true;
    if (e is http.ClientException) {
      final msg = e.message.toLowerCase();
      return msg.contains('connection closed') ||
          msg.contains('connection reset') ||
          msg.contains('connection abort') ||
          msg.contains('broken pipe');
    }
    return false;
  }

  bool get isLoggedIn => _loggedIn;

  Future<void> login(String email, String password) async {
    AppLog.ktApi.info('login() called for ${_maskEmail(email)}');

    final passwordHash = md5.convert(utf8.encode(password)).toString();
    await _performLogin(email, passwordHash);

    await _storage.write(key: _ktEmailKey, value: email);
    await _storage.write(key: _ktPasswordHashKey, value: passwordHash);

    AppLog.ktApi.success('Credentials stored for ${_maskEmail(email)}');
  }

  Future<bool> restoreSession() async {
    AppLog.ktApi.info('restoreSession() called');

    final email = await _storage.read(key: _ktEmailKey);
    final passwordHash = await _storage.read(key: _ktPasswordHashKey);

    if (email == null || passwordHash == null) {
      AppLog.ktApi.info('No stored KT credentials found');
      return false;
    }

    AppLog.ktApi.info('Stored credentials found for ${_maskEmail(email)}');
    await _performLogin(email, passwordHash);
    return true;
  }

  Future<String?> storedEmail() => _storage.read(key: _ktEmailKey);

  Future<void> logout() async {
    AppLog.ktApi.info('logout() called');

    _cookieHeader = null;
    _loggedIn = false;
    await _storage.delete(key: _ktEmailKey);
    await _storage.delete(key: _ktPasswordHashKey);

    AppLog.ktApi.info('Session and stored credentials cleared');
  }

  void invalidateSession() {
    _cookieHeader = null;
    _loggedIn = false;
  }

  Future<void> _performLogin(String email, String passwordHash) async {
    AppLog.ktApi.debug('Performing KT login for ${_maskEmail(email)}');

    final loginUri = Uri.parse('$_ktBaseUrl/login/create?=&format=json');
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final loginPayload = jsonEncode({
      'email': email,
      'password': passwordHash,
    });

    Future<http.Response> postLogin() =>
        _client.post(loginUri, headers: headers, body: loginPayload);

    late http.Response response;

    try {
      response = await postLogin();
    } catch (e, st) {
      if (_isStaleConnectionError(e)) {
        AppLog.ktApi.warn(
          'Login network error looks like stale socket — resetting client and retrying once',
          payload: '$e',
        );
        _resetClient();
        try {
          response = await postLogin();
        } catch (e2, st2) {
          AppLog.ktApi.error(
            'Network error during login (after retry)',
            err: e2,
            stackTrace: st2,
          );
          throw KtApiException('Network error during login: $e2');
        }
      } else {
        AppLog.ktApi
            .error('Network error during login', err: e, stackTrace: st);
        throw KtApiException('Network error during login: $e');
      }
    }

    AppLog.ktApi.debug(
      'Login HTTP response: status=${response.statusCode}, '
      'body=${_shortBody(response.body)}',
    );

    if (response.statusCode != 200) {
      AppLog.ktApi.error('Login failed with HTTP ${response.statusCode}');
      throw KtApiException('Login failed with HTTP ${response.statusCode}');
    }

    final body = decodeJson(response.body, context: 'login');

    if (body['code'] != 0) {
      final message = (body['message'] ?? 'Invalid credentials').toString();
      AppLog.ktApi.warn('Login rejected for ${_maskEmail(email)}: $message');
      throw KtAuthException(message);
    }

    _cookieHeader = _extractCookies(response);
    _loggedIn = true;

    AppLog.ktApi.success(
      'Login OK for ${_maskEmail(email)}',
      payload:
          'cookiesPresent=${_cookieHeader != null && _cookieHeader!.isNotEmpty}',
    );
  }

  void assertLoggedIn() {
    if (!_loggedIn) {
      AppLog.ktApi.warn('_assertLoggedIn() failed: not logged in');
      throw const KtAuthException('Not logged in');
    }
  }

  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final requestHeaders = headers ?? buildGetHeaders();

    AppLog.ktApi.debug(
      'GET $url',
      payload: 'hasCookie=${requestHeaders.containsKey("Cookie")}',
    );

    final uri = Uri.parse(url);
    Future<http.Response> doGet() => _client.get(uri, headers: requestHeaders);

    late http.Response response;
    try {
      response = await doGet();
    } catch (e, st) {
      if (_isStaleConnectionError(e)) {
        AppLog.ktApi.warn(
          'GET network error looks like stale socket — resetting client and retrying once',
          payload: 'url=$url, err=$e',
        );
        _resetClient();
        try {
          response = await doGet();
        } catch (e2, st2) {
          AppLog.ktApi.error(
            'Network error during GET $url (after retry)',
            err: e2,
            stackTrace: st2,
          );
          throw KtApiException('Network error: $e2');
        }
      } else {
        AppLog.ktApi.error(
          'Network error during GET $url',
          err: e,
          stackTrace: st,
        );
        throw KtApiException('Network error: $e');
      }
    }

    AppLog.ktApi.debug(
      'GET response: status=${response.statusCode}',
      payload: _shortBody(response.body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      invalidateSession();
      AppLog.ktApi.warn(
        'Session expired — HTTP ${response.statusCode} for $url',
      );
      throw const KtAuthException('Session expired');
    }

    if (response.statusCode != 200) {
      AppLog.ktApi.error('GET failed: HTTP ${response.statusCode} for $url');
      throw KtApiException('HTTP ${response.statusCode}');
    }

    return response;
  }

  Map<String, String> buildGetHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (_cookieHeader != null && _cookieHeader!.isNotEmpty) {
      headers['Cookie'] = _cookieHeader!;
    }

    return headers;
  }

  Map<String, dynamic> decodeJson(String body, {required String context}) {
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

  bool looksLikeAuthProblem(String message) {
    return message.contains('login') ||
        message.contains('auth') ||
        message.contains('session') ||
        message.contains('pĹ™ihl');
  }

  String? _extractCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      AppLog.ktApi.warn('No set-cookie header found in login response');
      return null;
    }

    final cookies = setCookie
        .split(RegExp(r',\s*(?=[A-Za-z0-9_\-]+=)'))
        .map((cookie) => cookie.trim().split(';').first.trim())
        .where((cookie) => cookie.contains('='))
        .join('; ');

    final result = cookies.isNotEmpty ? cookies : null;

    AppLog.ktApi.debug(
      'Cookies extracted: count=${result == null ? 0 : result.split("; ").length}',
    );

    return result;
  }
}
