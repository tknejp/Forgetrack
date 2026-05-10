import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/logging/app_log.dart';
import '../../../auth/data/google_auth_service.dart';

/// Disconnects the signed-in Google account and signs out of FirebaseAuth.
///
/// `disconnect()` is stronger than `signOut()` — it revokes all OAuth scopes
/// the app holds (profile, email, openid, drive.file) so the next sign-in
/// goes through the full consent screen rather than silent re-auth. If the
/// platform implementation rejects `disconnect` (some versions return when
/// no user is signed in) we still fall through to `signOut` to avoid leaving
/// cached tokens behind.
class GoogleAccountResetHelper {
  GoogleAccountResetHelper({
    GoogleSignIn? googleSignIn,
    GoogleAuthService? authService,
    FirebaseAuth? firebaseAuth,
  })  : _signIn = googleSignIn ?? GoogleSignIn.instance,
        _authService = authService ?? GoogleAuthService.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final GoogleSignIn _signIn;
  final GoogleAuthService _authService;
  final FirebaseAuth _firebaseAuth;

  /// Best-effort disconnect: revoke OAuth scopes via [GoogleSignIn.disconnect],
  /// then unconditionally call [GoogleSignIn.signOut] through the app's
  /// [GoogleAuthService] so its cached `_currentUser` and stream listeners
  /// are reset too.
  ///
  /// Returns a short note for the reset progress UI.
  Future<String> disconnectGoogle() async {
    AppLog.reset.info('google: disconnect start');
    String? disconnectError;
    try {
      await _signIn.disconnect();
      AppLog.reset.success('google: disconnect ok');
    } catch (e, st) {
      disconnectError = e.toString();
      AppLog.reset.warn(
        'google: disconnect failed (continuing with signOut)',
        payload: e,
      );
      AppLog.reset.debug('google: disconnect stack', payload: st);
    }

    try {
      await _authService.signOut();
      AppLog.reset.success('google: signOut ok');
    } catch (e, st) {
      AppLog.reset.error(
        'google: signOut failed',
        err: e,
        stackTrace: st,
      );
      rethrow;
    }

    return disconnectError == null
        ? 'OAuth scopes revoked + signed out'
        : 'signed out (disconnect rejected: $disconnectError)';
  }

  Future<void> firebaseSignOut() async {
    AppLog.reset.info('firebase: signOut start');
    await _firebaseAuth.signOut();
    AppLog.reset.success('firebase: signOut ok');
  }
}
