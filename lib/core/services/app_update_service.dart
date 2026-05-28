import 'dart:async';

import 'package:firebase_app_distribution/firebase_app_distribution.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../build_config.dart';
import '../logging/app_log.dart';

/// FAD in-app updater + FCM topic subscribe — only active on the
/// `internal` flavor (see [BuildConfig.isInternal]). On `dev` / `prod`
/// every entry-point is a no-op so the same Dart code can be compiled
/// for all flavors. The Gradle side strips the full FAD SDK from
/// non-internal builds via `missingDimensionStrategy("default", …)`
/// in `android/app/build.gradle.kts`.
///
/// Lifecycle:
///   - [initialize] — once at app boot. Subscribes to the
///     `forgetrack-internal-builds` FCM topic so testers receive a push
///     when `scripts/release.ps1` finishes uploading a new build.
///   - [checkForUpdate] — from `ForgetrackApp.didChangeAppLifecycleState`
///     (resumed). Calls `updateIfNewReleaseAvailable()` which silently
///     checks FAD and, if newer build exists, prompts the tester to
///     install. A reentrance guard prevents two overlapping calls when
///     Android fires `resumed` twice during a foreground transition.
class AppUpdateService {
  AppUpdateService._();

  static final instance = AppUpdateService._();

  /// FCM broadcast topic name. Mirrored in `scripts/release.ps1` —
  /// keep the two literals in sync.
  static const fcmTopic = 'forgetrack-internal-builds';

  bool _initialized = false;
  bool _checkInFlight = false;

  /// Wire FCM topic subscribe. Safe to call repeatedly; subsequent calls
  /// are no-ops. On non-internal flavors the method returns immediately.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!BuildConfig.isInternal) {
      AppLog.update.debug(
        'AppUpdateService: skipped initialize (flavor=${BuildConfig.flavor.name})',
      );
      return;
    }

    AppLog.update.info('AppUpdateService: initialize start');

    try {
      await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
      AppLog.update.success(
        'AppUpdateService: subscribed to FCM topic "$fcmTopic"',
      );
    } catch (e, st) {
      AppLog.update.error(
        'AppUpdateService: subscribeToTopic failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  /// Ask FAD whether a newer release is available; if yes, the plugin
  /// shows its native sign-in + update dialog. Re-entrance is gated so
  /// the lifecycle observer can safely call this on every `resumed`
  /// event without overlapping platform calls.
  Future<void> checkForUpdate() async {
    if (!BuildConfig.isInternal) return;
    if (_checkInFlight) {
      AppLog.update.debug('AppUpdateService: check already in flight, skipping');
      return;
    }
    _checkInFlight = true;

    try {
      AppLog.update.info('AppUpdateService: updateIfNewReleaseAvailable start');
      await updateIfNewReleaseAvailable();
      AppLog.update.success('AppUpdateService: updateIfNewReleaseAvailable done');
    } catch (e, st) {
      // Plugin throws on tester not signed in, network failure, FAD SDK
      // unavailable. Swallow — we never want this to break boot.
      AppLog.update.warn(
        'AppUpdateService: updateIfNewReleaseAvailable failed',
        payload: e,
      );
      AppLog.update.debug(
        'AppUpdateService: failure stack trace',
        payload: st,
      );
    } finally {
      _checkInFlight = false;
    }
  }
}
