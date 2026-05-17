import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Identity {
  const Identity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.googleAccount,
    this.firebaseUid,
  });

  final String id;
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

    final canonicalId = _firstNonEmpty([
      googleInfo?.uid,
      user.email,
      user.uid,
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
