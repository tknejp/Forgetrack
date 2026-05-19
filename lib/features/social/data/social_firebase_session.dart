import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/logging/app_log.dart';
import '../../auth/domain/identity.dart';

class SocialFirebaseSession {
  SocialFirebaseSession({
    FirebaseAuth? auth,
    this.isEnabled = true,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final bool isEnabled;

  Future<void> ensureSignedInWithGoogle(Identity user) async {
    if (!isEnabled) return;

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email == user.email) {
      return;
    }

    final googleAccount = user.googleAccount;
    if (googleAccount == null) {
      throw StateError(
        'Google account tokens are unavailable for Firebase sign-in.',
      );
    }

    final idToken = googleAccount.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    // Firebase Auth only requires the ID token — no interactive scope
    // authorization needed here.
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    await _auth.signInWithCredential(credential);
    AppLog.social.success(
      'Firebase session ready',
      payload: user.email,
    );
  }

  Future<void> signOut() async {
    if (!isEnabled) return;
    if (_auth.currentUser == null) return;

    await _auth.signOut();
    AppLog.social.info('Firebase session cleared');
  }
}
