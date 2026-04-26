import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/logging/app_log.dart';
import 'google_auth_platform_adapter.dart';

class GoogleAuthService {
  static const String _serverClientId =
      '798278342104-d2g19o54jbvlo88ih844busim0f74qeu.apps.googleusercontent.com';

  GoogleAuthService._() {
    installGoogleAuthPlatformAdapter();
    _authChangedController = StreamController<GoogleSignInAccount?>.broadcast(
      onListen: () {
        if (_initialized) {
          _authChangedController.add(_currentUser);
        }
      },
    );
  }

  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _signIn = GoogleSignIn.instance;

  late final StreamController<GoogleSignInAccount?> _authChangedController;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  GoogleSignInAccount? _currentUser;
  bool _initialized = false;
  Future<void>? _initializeFuture;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Stream<GoogleSignInAccount?> get onAuthChanged =>
      _authChangedController.stream;

  Future<void> _ensureInitialized() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    AppLog.auth.info('initializing',
        payload:
            'serverClientId=$_serverClientId platform=$defaultTargetPlatform');
    await _signIn.initialize(serverClientId: _serverClientId);
    AppLog.auth.info('initialize done');

    _authSub ??= _signIn.authenticationEvents.listen(
      (GoogleSignInAuthenticationEvent event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            AppLog.auth
                .info('event: sign-in', payload: 'user=${event.user.email}');
            _currentUser = event.user;
            break;
          case GoogleSignInAuthenticationEventSignOut():
            AppLog.auth.info('event: sign-out');
            _currentUser = null;
            break;
        }
        _authChangedController.add(_currentUser);
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLog.auth.error('authenticationEvents error',
            err: error, stackTrace: stackTrace);
        _currentUser = null;
        _authChangedController.add(null);
      },
    );

    _initialized = true;
  }

  Future<void> initialize() => _ensureInitialized();

  Future<GoogleSignInAccount?> signIn() async {
    AppLog.auth.info('signIn: start');
    await _ensureInitialized();
    try {
      final user = await _signIn.authenticate();
      _currentUser = user;
      AppLog.auth.success('signIn', payload: 'user=${user.email}');
      return user;
    } catch (e, st) {
      AppLog.auth.error('signIn', err: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    AppLog.auth.info('signOut: start');
    await _ensureInitialized();
    _currentUser = null;
    _authChangedController.add(null);
    await _signIn.signOut();
    AppLog.auth.success('signOut: done');
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _authChangedController.close();
  }
}
