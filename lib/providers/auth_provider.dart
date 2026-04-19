import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/google_auth_service.dart';

enum AuthSessionState { checking, signedIn, signedOut }

class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _auth = GoogleAuthService.instance;

  GoogleSignInAccount? _user;
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;
  AuthSessionState _sessionState = AuthSessionState.checking;
  bool _isLoading = false;
  String? _error;

  GoogleSignInAccount? get user => _user;
  AuthSessionState get sessionState => _sessionState;
  bool get isSignedIn =>
      _sessionState == AuthSessionState.signedIn && _user != null;
  bool get isSignedOut => _sessionState == AuthSessionState.signedOut;
  bool get isRestoring => _sessionState == AuthSessionState.checking;
  bool get isLoading => _isLoading;
  bool get isBusy => _isLoading || isRestoring;
  String? get error => _error;

  AuthProvider() {
    _user = _auth.currentUser;
    _sessionState = _deriveSessionState(_user);
    _authSubscription = _auth.onAuthChanged.listen(_handleAuthChanged);

    if (!_auth.hasResolvedSession) {
      unawaited(_restoreSession());
    }
  }

  AuthSessionState _deriveSessionState(GoogleSignInAccount? user) {
    if (!_auth.hasResolvedSession) return AuthSessionState.checking;
    return user == null
        ? AuthSessionState.signedOut
        : AuthSessionState.signedIn;
  }

  void _handleAuthChanged(GoogleSignInAccount? account) {
    _user = account;
    _sessionState = _deriveSessionState(account);
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    try {
      _error = null;
      _user = await _auth.signInSilently();
    } catch (e) {
      _error = _describeAuthError(e);
    } finally {
      _sessionState = _deriveSessionState(_user);
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _auth.signIn();
      _sessionState = _deriveSessionState(_user);
    } catch (e) {
      _error = _describeAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _error = null;
    await _auth.signOut();
    _user = null;
    _sessionState = AuthSessionState.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
