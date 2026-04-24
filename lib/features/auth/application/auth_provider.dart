import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_user.dart';
import '../data/google_auth_service.dart';

enum AuthSessionState { checking, signedIn, signedOut }

class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _auth = GoogleAuthService.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthUser? _user;
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;
  StreamSubscription<User?>? _firebaseSubscription;
  AuthSessionState _sessionState = AuthSessionState.checking;
  bool _isLoading = false;
  String? _error;

  AuthUser? get user => _user;
  AuthSessionState get sessionState => _sessionState;
  bool get isSignedIn =>
      _sessionState == AuthSessionState.signedIn && _user != null;
  bool get isSignedOut => _sessionState == AuthSessionState.signedOut;
  bool get isRestoring => _sessionState == AuthSessionState.checking;
  bool get isLoading => _isLoading;
  bool get isBusy => _isLoading || isRestoring;
  String? get error => _error;

  AuthProvider() {
    _user = _composeUser(
      googleAccount: _auth.currentUser,
      firebaseUser: _firebaseAuth.currentUser,
    );
    _sessionState =
        _user == null ? AuthSessionState.signedOut : AuthSessionState.signedIn;
    _authSubscription = _auth.onAuthChanged.listen(_handleGoogleAuthChanged);
    _firebaseSubscription =
        _firebaseAuth.authStateChanges().listen(_handleFirebaseAuthChanged);
  }

  Future<void> signIn() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final googleUser = await _auth.signIn();
      if (googleUser == null) {
        _user = _composeUser(
          googleAccount: null,
          firebaseUser: _firebaseAuth.currentUser,
        );
        _sessionState = _user == null
            ? AuthSessionState.signedOut
            : AuthSessionState.signedIn;
        return;
      }
      await _ensureFirebaseSignedIn(googleUser);
      _user = _composeUser(
        googleAccount: googleUser,
        firebaseUser: _firebaseAuth.currentUser,
      );
      _sessionState = _user == null
          ? AuthSessionState.signedOut
          : AuthSessionState.signedIn;
    } catch (e) {
      _error = _describeAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _error = null;
    await Future.wait([
      _auth.signOut(),
      _firebaseAuth.signOut(),
    ]);
    _user = null;
    _sessionState = AuthSessionState.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _firebaseSubscription?.cancel();
    super.dispose();
  }

  void _handleGoogleAuthChanged(GoogleSignInAccount? account) {
    final nextUser = _composeUser(
      googleAccount: account,
      firebaseUser: _firebaseAuth.currentUser,
    );
    _user = nextUser;
    if (nextUser != null) {
      _sessionState = AuthSessionState.signedIn;
    } else if (_sessionState != AuthSessionState.checking) {
      _sessionState = AuthSessionState.signedOut;
    }
    notifyListeners();
  }

  void _handleFirebaseAuthChanged(User? firebaseUser) {
    final nextUser = _composeUser(
      googleAccount: _auth.currentUser,
      firebaseUser: firebaseUser,
    );
    _user = nextUser;
    if (nextUser != null) {
      _sessionState = AuthSessionState.signedIn;
    } else if (_sessionState != AuthSessionState.checking) {
      _sessionState = AuthSessionState.signedOut;
    }
    notifyListeners();
  }

  AuthUser? _composeUser({
    GoogleSignInAccount? googleAccount,
    User? firebaseUser,
  }) {
    final firebaseIdentity =
        firebaseUser == null ? null : AuthUser.fromFirebase(firebaseUser);
    if (googleAccount != null) {
      return (firebaseIdentity ?? AuthUser.fromGoogle(googleAccount))
          .mergeGoogle(googleAccount);
    }
    return firebaseIdentity;
  }

  Future<void> _ensureFirebaseSignedIn(GoogleSignInAccount googleUser) async {
    final current = _firebaseAuth.currentUser;
    if (current != null && current.email == googleUser.email) {
      return;
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  String _describeAuthError(Object error) {
    if (error is GoogleSignInException) {
      final description = error.description?.toLowerCase() ?? '';

      if (error.code == GoogleSignInExceptionCode.canceled &&
          description.contains('account reauth failed')) {
        return 'Google sign-in is not fully configured for this Android build. '
            'Check Firebase Google sign-in, SHA fingerprints, and the latest '
            'google-services.json file.';
      }

      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          description.contains('serverclientid')) {
        return 'Google sign-in client configuration is incomplete. '
            'Check the Android package name, OAuth client IDs, and server client ID.';
      }
    }

    return error.toString();
  }
}
