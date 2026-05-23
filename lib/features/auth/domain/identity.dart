import 'package:firebase_auth/firebase_auth.dart'; // lint-ignore: domain-purity — auth boundary, Identity wraps the platform User
import 'package:google_sign_in/google_sign_in.dart'; // lint-ignore: domain-purity — auth boundary, Identity.fromGoogle reads the platform account

class Identity {
  const Identity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.googleAccount,
    this.firebaseUid,
  });

  final String id; // lint-ignore: untyped-id — Identity.id wraps the auth-platform user id (Google sub / Firebase uid)
  final String email;
  final String? displayName;
  final String? photoUrl;
  final GoogleSignInAccount? googleAccount;
  final String? firebaseUid;

  bool get hasGoogleAccount => googleAccount != null;

  factory Identity.fromGoogle(GoogleSignInAccount account) {
    return Identity(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      googleAccount: account,
    );
  }

  factory Identity.fromFirebase(User user) {
    UserInfo? googleInfo;
    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        googleInfo = provider;
        break;
      }
    }

    // Firebase Auth UID is the canonical key for Firestore paths
    // (`users/{uid}/...`). Security rules compare it against
    // `request.auth.uid`, so any other choice (e.g. Google sub) would
    // make every owner-only rule deny legitimate writes. Mirrors
    // `canonicalUid` in `core/services/fcm_service.dart`.
    final canonicalId = _firstNonEmpty([
      user.uid,
      googleInfo?.uid,
      user.email,
    ]);

    return Identity(
      id: canonicalId,
      email: _firstNonEmpty([
        user.email,
        googleInfo?.email,
      ]),
      displayName: _firstNonEmptyNullable([
        user.displayName,
        googleInfo?.displayName,
      ]),
      photoUrl: _firstNonEmptyNullable([
        user.photoURL,
        googleInfo?.photoURL,
      ]),
      firebaseUid: user.uid,
    );
  }

  Identity mergeGoogle(GoogleSignInAccount account) {
    return Identity(
      id: account.id.isNotEmpty ? account.id : id,
      email: account.email.isNotEmpty ? account.email : email,
      displayName: _firstNonEmptyNullable([
        account.displayName,
        displayName,
      ]),
      photoUrl: _firstNonEmptyNullable([
        account.photoUrl,
        photoUrl,
      ]),
      googleAccount: account,
      firebaseUid: firebaseUid,
    );
  }

  static String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String? _firstNonEmptyNullable(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
