import 'package:flutter/foundation.dart';

import '../sentry/sentry_breadcrumb_sink.dart';

// ─── ANSI colors ──────────────────────────────────────────────────────────────
//
// Render in real terminals (`flutter run` from cmd) AND in the VSCode Debug
// Console — Dart Debug Adapter forwards stdout verbatim and VSCode renders
// ANSI escape sequences in the Debug Console panel.

abstract final class _Ansi {
  static const reset = '\x1B[0m';

  static const gray = '\x1B[90m';
  static const blue = '\x1B[34m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const red = '\x1B[31m';
}

// ─── Log levels ───────────────────────────────────────────────────────────────

enum _Level {
  debug,
  info,
  success,
  warn,
  error;

  String get _prefix => switch (this) {
        debug => '·',
        info => 'ℹ',
        success => '✓',
        warn => '⚠',
        error => '✖',
      };

  String get _tag => switch (this) {
        debug => 'DEBUG',
        info => 'INFO ',
        success => 'OK   ',
        warn => 'WARN ',
        error => 'ERROR',
      };

  String get _ansiColor => switch (this) {
        debug => _Ansi.gray,
        info => _Ansi.blue,
        success => _Ansi.green,
        warn => _Ansi.yellow,
        error => _Ansi.red,
      };
}

// ─── Level gating ────────────────────────────────────────────────────────────

bool _shouldLog(_Level level) {
  if (kReleaseMode) return false;
  if (kProfileMode) return level.index >= _Level.warn.index;
  return true;
}

// ─── Logger ───────────────────────────────────────────────────────────────────

class AppLogger {
  final String domain;
  final String? scope;

  const AppLogger(this.domain, {this.scope});

  void _emit(
    _Level level,
    String message, {
    Object? payload,
    Object? err,
    StackTrace? stackTrace,
  }) {
    // Forward to Sentry breadcrumb sink BEFORE the _shouldLog gate — in
    // release builds AppLog skips terminal output but breadcrumbs still
    // need to flow. The sink is a no-op when Sentry isn't initialised, so
    // the cost in dev is one call into an empty function.
    SentryBreadcrumbSink.instance.add(
      level: level.name,
      domain: domain,
      scope: scope,
      message: message,
    );

    if (!_shouldLog(level)) return;

    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';

    final domainTag = scope != null ? '[$domain][$scope]' : '[$domain]';
    final payloadStr = payload != null ? '  | $payload' : '';
    // `[Forgetrack]` prefix lets the VSCode Debug Console search filter hide
    // non-app noise (engine prints, plugin stdout). Kept right after the
    // severity glyph so the visual rhythm of the line stays intact.
    final line =
        '${level._prefix} [Forgetrack][$ts][${level._tag}]$domainTag $message$payloadStr';

    // Single sink: debugPrint goes to stdout, which both `flutter run` in cmd
    // and the VSCode Debug Console pick up. dev.log is intentionally not used
    // — the DAP would surface it as a second entry per call, doubling the
    // visible noise in Debug Console for no extra signal.
    debugPrint('${level._ansiColor}$line${_Ansi.reset}');

    if (err != null) {
      debugPrint('${_Ansi.red}[Forgetrack] error: $err${_Ansi.reset}');
    }

    if (stackTrace != null) {
      // Emit each frame as its own debugPrint so every visible line in the
      // VSCode Debug Console starts with `[Forgetrack]` — debugPrintStack
      // writes raw `#0 …` frames that the filter would hide.
      for (final frame in stackTrace.toString().trimRight().split('\n')) {
        debugPrint('${_Ansi.red}[Forgetrack] $frame${_Ansi.reset}');
      }
    }
  }

  void debug(String message, {Object? payload}) =>
      _emit(_Level.debug, message, payload: payload);

  void info(String message, {Object? payload}) =>
      _emit(_Level.info, message, payload: payload);

  void success(String message, {Object? payload}) =>
      _emit(_Level.success, message, payload: payload);

  void warn(String message, {Object? payload}) =>
      _emit(_Level.warn, message, payload: payload);

  void error(
    String message, {
    Object? payload,
    Object? err,
    StackTrace? stackTrace,
  }) =>
      _emit(
        _Level.error,
        message,
        payload: payload,
        err: err,
        stackTrace: stackTrace,
      );
}

// ─── Namespace ────────────────────────────────────────────────────────────────

abstract final class AppLog {
  static const app = AppLogger('APP');
  static const auth = AppLogger('AUTH');
  static const health = AppLogger('HEALTH');
  static const social = AppLogger('SOCIAL');
  static const sync = AppLogger('SYNC');
  static const nav = AppLogger('NAV');
  static const ui = AppLogger('UI');
  static const db = AppLogger('DB');

  static const kt = AppLogger('KT');
  static const ktApi = AppLogger('KT', scope: 'API');
  static const ktParse = AppLogger('KT', scope: 'PARSE');
  static const ktDb = AppLogger('KT', scope: 'DB');
  static const ktProvider = AppLogger('KT', scope: 'PROVIDER');
  static const ktAvg = AppLogger('KT', scope: 'AVG');
  static const ktUi = AppLogger('KT', scope: 'UI');

  static const reset = AppLogger('RESET');
}
