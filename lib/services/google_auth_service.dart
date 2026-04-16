import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  GoogleAuthService._() {
    _authChangedController = StreamController<GoogleSignInAccount?>.broadcast(
      onListen: () {
        if (_initialized) {
          _authChangedController.add(_currentUser);
        }
      },
    );
  }

  static final GoogleAuthService instance = GoogleAuthService._();

  static const List<String> _scopes = <String>[
    'email',
    'profile',
    SheetsApi.spreadsheetsScope,
  ];

  final GoogleSignIn _signIn = GoogleSignIn.instance;

  late final StreamController<GoogleSignInAccount?> _authChangedController;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  GoogleSignInAccount? _currentUser;
  bool _initialized = false;
  Future<void>? _initializeFuture;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Stream<GoogleSignInAccount?> get onAuthChanged => _authChangedController.stream;

  Future<void> _ensureInitialized() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    debugPrint('[GoogleAuthService] initializing');
    await _signIn.initialize(
      serverClientId:
          '798278342104-2fbpll2cvco1d4c79mdk9t6t344fkjbp.apps.googleusercontent.com',
    );
    debugPrint('[GoogleAuthService] initialize done');

    _authSub ??= _signIn.authenticationEvents.listen(
      (GoogleSignInAuthenticationEvent event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            debugPrint('[GoogleAuthService] event: sign-in user=${event.user.email}');
            _currentUser = event.user;
            break;
          case GoogleSignInAuthenticationEventSignOut():
            debugPrint('[GoogleAuthService] event: sign-out');
            _currentUser = null;
            break;
        }
        _authChangedController.add(_currentUser);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[GoogleAuthService] authenticationEvents error=$error\n$stackTrace');
        _currentUser = null;
        _authChangedController.add(null);
      },
    );

    _initialized = true;
  }

  Future<void> init() => _ensureInitialized();

  Future<GoogleSignInAccount?> signIn() async {
    debugPrint('[GoogleAuthService] signIn: start');
    await _ensureInitialized();
    try {
      final user = await _signIn.authenticate();
      _currentUser = user;
      debugPrint('[GoogleAuthService] signIn: success user=${user.email}');
      return user;
    } catch (e, st) {
      debugPrint('[GoogleAuthService] signIn: error=$e\n$st');
      rethrow;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    debugPrint('[GoogleAuthService] signInSilently: start');
    await _ensureInitialized();
    final user = await _signIn.attemptLightweightAuthentication();
    _currentUser = user;
    debugPrint('[GoogleAuthService] signInSilently: result=${user?.email ?? 'null'}');
    return user;
  }

  Future<void> signOut() async {
    debugPrint('[GoogleAuthService] signOut: start');
    await _ensureInitialized();
    _currentUser = null;
    _authChangedController.add(null);
    await _signIn.signOut();
    debugPrint('[GoogleAuthService] signOut: done');
  }

  Future<http.Client?> getAuthClient() async {
    debugPrint('[GoogleAuthService] getAuthClient: start');
    await _ensureInitialized();

    final user = _currentUser;
    if (user == null) {
      debugPrint('[GoogleAuthService] getAuthClient: no current user, returning null');
      return null;
    }

    debugPrint('[GoogleAuthService] getAuthClient: authorizing scopes for ${user.email}');
    final GoogleSignInClientAuthorization authorization =
        await user.authorizationClient.authorizationForScopes(_scopes) ??
        await user.authorizationClient.authorizeScopes(_scopes);

    final client = authorization.authClient(scopes: _scopes);
    debugPrint('[GoogleAuthService] getAuthClient: client obtained');
    return client;
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _authChangedController.close();
  }
}