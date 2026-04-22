import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/app_log.dart';

class SocialFirebaseSession {
  SocialFirebaseSession({
    FirebaseAuth? auth,
    this.isEnabled = true,
  }) : _auth = auth ?? FirebaseAuth.instance;

  static const List<String> _googleScopes = <String>[
    'email',
    'profile',
  ];

  final FirebaseAuth _auth;
  final bool isEnabled;

  Future<void> ensureSignedInWithGoogle(GoogleSignInAccount user) async {
    if (!isEnabled) return;

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email == user.email) {
      return;
    }

    final idToken = user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    final authorization =
        await user.authorizationClient.authorizationForScopes(_googleScopes) ??
            await user.authorizationClient.authorizeScopes(_googleScopes);

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: authorization.accessToken,
    );

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
