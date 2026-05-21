import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/constants.dart';
import '../build_config.dart';
import 'sentry_breadcrumb_sink.dart';
import 'sentry_pii_scrubber.dart';

/// Boots Sentry once at app start.
///
/// Gates init on three things, all of which must be true:
///   - [BuildConfig.isProd] — dev flavor never reports
///   - DSN passed via `--dart-define=SENTRY_DSN=…` — no hardcoded value in lib/
///   - User consent persisted in SharedPreferences (caller passes it in)
///
/// When init is skipped the [appRunner] still executes so the app starts
/// normally; the [SentryBreadcrumbSink] stays a no-op so AppLog calls cost
/// nothing.
abstract final class SentryBootstrap {
  SentryBootstrap._();

  static const String _dsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool _enabled = false;

  /// Sentry init succeeded and the runtime is reporting. Read this before
  /// touching `Sentry.configureScope` etc. so the call is cheap when Sentry
  /// is disabled.
  static bool get isEnabled => _enabled;

  /// Whether the running build CAN report (independent of consent / runtime).
  /// Used by Settings to explain why the toggle is greyed out on dev builds.
  static bool get isAvailable => BuildConfig.isProd && _dsn.isNotEmpty;

  static Future<void> init({
    required bool consent,
    required Future<void> Function() appRunner,
  }) async {
    final shouldInit = isAvailable && consent;

    if (!shouldInit) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = 'prod';
        options.release =
            'forgetrack@${AppConstants.appVersion}+${BuildConfig.flavor.name}';
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.tracesSampleRate = 0.2;
        options.replay.sessionSampleRate = 0.1;
        options.replay.onErrorSampleRate = 1.0;
        options.beforeSend = _beforeSend;
        options.beforeBreadcrumb = _beforeBreadcrumb;
      },
      appRunner: () async {
        _enabled = true;
        Sentry.configureScope((scope) {
          scope.setTag('flavor', BuildConfig.flavor.name);
          scope.setTag('app_version', AppConstants.appVersion);
        });
        SentryBreadcrumbSink.instance = const _SentryFlutterBreadcrumbSink();
        await appRunner();
      },
    );
  }

  /// Set / clear the Sentry user scope. Strict-PII policy: only the opaque
  /// Firebase UID, never email or display name.
  static void setUserId(String? uid) {
    if (!_enabled) return;
    Sentry.configureScope((scope) {
      scope.setUser(uid == null ? null : SentryUser(id: uid));
    });
  }

  static FutureOr<SentryEvent?> _beforeSend(
    SentryEvent event,
    Hint hint,
  ) {
    final existingUser = event.user;
    if (existingUser != null) {
      // Drop email / username / ip / data — keep only opaque id.
      event.user = SentryUser(id: existingUser.id);
    }
    event.request = null;

    final formatted = event.message?.formatted;
    if (formatted != null && formatted.isNotEmpty) {
      event.message = SentryMessage(
        SentryPiiScrubber.scrubMessage(formatted),
        template: event.message?.template,
        params: event.message?.params,
      );
    }
    return event;
  }

  static Breadcrumb? _beforeBreadcrumb(
    Breadcrumb? crumb,
    Hint hint,
  ) {
    if (crumb == null) return null;
    final msg = crumb.message;
    if (msg != null) {
      crumb.message = SentryPiiScrubber.scrubMessage(msg);
    }
    final data = crumb.data;
    if (data != null) {
      crumb.data = SentryPiiScrubber.scrubMap(
        Map<String, dynamic>.from(data),
      );
    }
    return crumb;
  }
}

class _SentryFlutterBreadcrumbSink implements SentryBreadcrumbSink {
  const _SentryFlutterBreadcrumbSink();

  // Only these AppLog domains carry signal worth keeping next to a crash.
  // UI / DB / RESET / APP / NAV / SOCIAL are noisy; cosmetics-render and
  // ui-tick (when they exist) would blow past the free-tier event budget.
  static const Set<String> _whitelist = {'AUTH', 'SYNC', 'KT', 'HEALTH'};

  @override
  void add({
    required String level,
    required String domain,
    String? scope,
    required String message,
  }) {
    if (!_whitelist.contains(domain)) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: SentryPiiScrubber.scrubMessage(message),
        level: _mapLevel(level),
        category: scope == null ? domain : '$domain.$scope',
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  SentryLevel _mapLevel(String level) {
    return switch (level) {
      'debug' => SentryLevel.debug,
      'info' => SentryLevel.info,
      'success' => SentryLevel.info,
      'warn' => SentryLevel.warning,
      'error' => SentryLevel.error,
      _ => SentryLevel.info,
    };
  }
}
