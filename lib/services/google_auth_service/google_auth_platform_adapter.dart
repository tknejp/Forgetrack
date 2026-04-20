// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in_android/google_sign_in_android.dart';
import 'package:google_sign_in_android/src/messages.g.dart' as google_sign_in_android;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

bool _adapterInstalled = false;

void installGoogleAuthPlatformAdapter() {
  if (_adapterInstalled) return;

  final platform = GoogleSignInPlatform.instance;
  if (platform is _PassiveStartupGoogleSignInPlatform) {
    _adapterInstalled = true;
    return;
  }

  GoogleSignInPlatform.instance = _PassiveStartupGoogleSignInPlatform(platform);
  _adapterInstalled = true;
}

class _PassiveStartupGoogleSignInPlatform extends GoogleSignInPlatform {
  _PassiveStartupGoogleSignInPlatform(this._delegate);

  final GoogleSignInPlatform _delegate;
  final google_sign_in_android.GoogleSignInApi _androidHostApi =
      google_sign_in_android.GoogleSignInApi();

  InitParameters _initParameters = const InitParameters();
  String? _resolvedServerClientId;

  bool get _usesPassiveAndroidRestore =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      _delegate is GoogleSignInAndroid;

  @override
  Stream<AuthenticationEvent>? get authenticationEvents =>
      _delegate.authenticationEvents;

  @override
  Future<void> init(InitParameters params) async {
    _initParameters = params;
    _resolvedServerClientId = null;
    await _delegate.init(params);
  }

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) {
    if (!_usesPassiveAndroidRestore) {
      return _delegate.attemptLightweightAuthentication(params);
    }

    return _attemptPassiveAndroidRestore();
  }

  @override
  bool supportsAuthenticate() => _delegate.supportsAuthenticate();

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) {
    return _delegate.authenticate(params);
  }

  @override
  bool authorizationRequiresUserInteraction() {
    return _delegate.authorizationRequiresUserInteraction();
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) {
    return _delegate.clientAuthorizationTokensForScopes(params);
  }

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) {
    return _delegate.serverAuthorizationTokensForScopes(params);
  }

  @override
  Future<void> clearAuthorizationToken(ClearAuthorizationTokenParams params) {
    return _delegate.clearAuthorizationToken(params);
  }

  @override
  Future<void> signOut(SignOutParams params) {
    return _delegate.signOut(params);
  }

  @override
  Future<void> disconnect(DisconnectParams params) {
    return _delegate.disconnect(params);
  }

  Future<AuthenticationResults?> _attemptPassiveAndroidRestore() async {
    final result = await _androidHostApi.getCredential(
      google_sign_in_android.GetCredentialRequestParams(
        useButtonFlow: false,
        googleIdOptionParams:
            google_sign_in_android.GetCredentialRequestGoogleIdOptionParams(
          filterToAuthorized: true,
          autoSelectEnabled: true,
        ),
        serverClientId: await _resolveServerClientId(),
        hostedDomain: _initParameters.hostedDomain,
        nonce: _initParameters.nonce,
      ),
    );

    if (result is google_sign_in_android.GetCredentialSuccess) {
      return _authenticationResultFromCredential(result.credential);
    }

    if (result is google_sign_in_android.GetCredentialFailure) {
      return _handleRestoreFailure(result);
    }

    return null;
  }

  Future<String?> _resolveServerClientId() async {
    final configured = _initParameters.serverClientId;
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    return _resolvedServerClientId ??=
        await _androidHostApi.getGoogleServicesJsonServerClientId();
  }

  AuthenticationResults _authenticationResultFromCredential(
    google_sign_in_android.PlatformGoogleIdTokenCredential credential,
  ) {
    final email = credential.id;
    final userId = _extractUserId(credential.idToken) ?? email;

    return AuthenticationResults(
      user: GoogleSignInUserData(
        email: email,
        id: userId,
        displayName: credential.displayName,
        photoUrl: credential.profilePictureUri,
      ),
      authenticationTokens: AuthenticationTokenData(
        idToken: credential.idToken,
      ),
    );
  }

  AuthenticationResults? _handleRestoreFailure(
    google_sign_in_android.GetCredentialFailure failure,
  ) {
    switch (failure.type) {
      case google_sign_in_android.GetCredentialFailureType.noCredential:
      case google_sign_in_android.GetCredentialFailureType.canceled:
      case google_sign_in_android.GetCredentialFailureType.interrupted:
      case google_sign_in_android.GetCredentialFailureType.noActivity:
      case google_sign_in_android.GetCredentialFailureType.unsupported:
        return null;
      case google_sign_in_android.GetCredentialFailureType.unexpectedCredentialType:
        throw GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
          description: 'Unexpected credential type: ${failure.message}',
          details: failure.details,
        );
      case google_sign_in_android.GetCredentialFailureType.providerConfigurationIssue:
        throw GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
          description: failure.message,
          details: failure.details,
        );
      case google_sign_in_android.GetCredentialFailureType.missingServerClientId:
        throw GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'serverClientId must be provided on Android',
          details: failure.details,
        );
      case google_sign_in_android.GetCredentialFailureType.unknown:
        throw GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: failure.message,
          details: failure.details,
        );
    }
  }
}

final Codec<Object?, String> _jwtCodec = json.fuse(utf8).fuse(base64);

String? _extractUserId(String idToken) {
  final match = RegExp(
    r'^(?<header>[^\.\s]+)\.(?<payload>[^\.\s]+)\.(?<signature>[^\.\s]+)$',
  ).firstMatch(idToken);
  final payload = match?.namedGroup('payload');
  if (payload == null) return null;

  try {
    final contents =
        _jwtCodec.decode(base64.normalize(payload)) as Map<String, Object?>?;
    return contents?['sub'] as String?;
  } catch (_) {
    return null;
  }
}
