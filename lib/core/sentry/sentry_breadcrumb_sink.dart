/// Sink that AppLog calls to forward log lines into Sentry as breadcrumbs.
///
/// AppLog itself stays free of any Sentry import — the bootstrap installs a
/// concrete implementation on app start, otherwise the default no-op is used
/// (dev flavor, no-DSN builds, opt-out users).
///
/// Whitelisting which domains become breadcrumbs lives in the concrete
/// implementation; AppLog forwards every call unconditionally.
abstract interface class SentryBreadcrumbSink {
  void add({
    required String level,
    required String domain,
    String? scope,
    required String message,
  });

  static SentryBreadcrumbSink instance = const _NoopBreadcrumbSink();
}

class _NoopBreadcrumbSink implements SentryBreadcrumbSink {
  const _NoopBreadcrumbSink();

  @override
  void add({
    required String level,
    required String domain,
    String? scope,
    required String message,
  }) {}
}
