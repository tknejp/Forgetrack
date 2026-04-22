import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/app_log.dart';

class SocialBackendState {
  const SocialBackendState._({
    required this.isReady,
    required this.message,
  });

  const SocialBackendState.ready()
      : this._(
          isReady: true,
          message: 'Firebase social backend is ready.',
        );

  const SocialBackendState.unavailable(String message)
      : this._(
          isReady: false,
          message: message,
        );

  final bool isReady;
  final String message;
}

class SocialFirebaseBootstrap {
  SocialFirebaseBootstrap._();

  static Future<SocialBackendState>? _bootstrapFuture;

  static Future<SocialBackendState> ensureInitialized() {
    return _bootstrapFuture ??= _initialize();
  }

  static Future<SocialBackendState> _initialize() async {
    if (!_supportsFirebasePlatform) {
      return const SocialBackendState.unavailable(
        'Social backend is not configured for this platform.',
      );
    }

    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();
      AppLog.social.info('Firebase initialized', payload: app.name);
      return const SocialBackendState.ready();
    } catch (error, stackTrace) {
      AppLog.social.warn(
        'Firebase initialization skipped',
        payload: error,
      );
      AppLog.social.error(
        'Firebase initialization details',
        err: error,
        stackTrace: stackTrace,
      );
      return const SocialBackendState.unavailable(
        'Firebase social backend is not configured yet for this build.',
      );
    }
  }

  static bool get _supportsFirebasePlatform {
    if (kIsWeb) return true;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }
}
