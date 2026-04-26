import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:http/http.dart' as http;

import '../../../core/logging/app_log.dart';
import '../../auth/data/google_auth_service.dart';

class GoogleSheetsAuthService {
  GoogleSheetsAuthService({
    GoogleAuthService? googleAuth,
    GoogleSignIn? signIn,
  })  : _googleAuth = googleAuth ?? GoogleAuthService.instance,
        _signIn = signIn ?? GoogleSignIn.instance;

  static const List<String> _scopes = <String>[
    SheetsApi.spreadsheetsScope,
  ];

  final GoogleAuthService _googleAuth;
  final GoogleSignIn _signIn;

  Future<http.Client?> getAuthClient({bool interactive = true}) async {
    AppLog.sync.info(
      'sheetsAuth: requesting auth client',
      payload: 'interactive=$interactive',
    );

    await _googleAuth.initialize();

    final authorizationClient = _googleAuth.currentUser?.authorizationClient ??
        _signIn.authorizationClient;

    try {
      final existing =
          await authorizationClient.authorizationForScopes(_scopes);
      if (existing != null) {
        AppLog.sync.success('sheetsAuth: reusing existing authorization');
        return existing.authClient(scopes: _scopes);
      }

      if (!interactive) {
        AppLog.sync.debug('sheetsAuth: no cached authorization available');
        return null;
      }

      final prompted = await authorizationClient.authorizeScopes(_scopes);
      AppLog.sync.success('sheetsAuth: authorization granted interactively');
      return prompted.authClient(scopes: _scopes);
    } on GoogleSignInException catch (error, stackTrace) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        AppLog.sync.info(
          'sheetsAuth: authorization canceled by user',
          payload: error.description,
        );
        return null;
      }
      AppLog.sync.error(
        'sheetsAuth: authorization failed',
        err: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
