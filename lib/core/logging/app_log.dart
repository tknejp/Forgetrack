import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

// ─── ANSI colors ──────────────────────────────────────────────────────────────

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

  int get _devLevel => switch (this) {
        debug => 500,
        info => 800,
        success => 800,
        warn => 900,
        error => 1000,
      };

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
    if (!_shouldLog(level)) return;

    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';

    final domainTag = scope != null ? '[$domain][$scope]' : '[$domain]';
    final payloadStr = payload != null ? '  | $payload' : '';
    final line =
        '${level._prefix} [$ts][${level._tag}]$domainTag $message$payloadStr';

    final coloredLine = '${level._ansiColor}$line${_Ansi.reset}';

    // Barevný výstup jen do terminalu.
    debugPrint(coloredLine);

    if (err != null) {
      debugPrint('${_Ansi.red}error: $err${_Ansi.reset}');
    }

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }

    // Čistý výstup do DevTools/logcat, bez ANSI escape sekvencí.
    dev.log(
      line,
      name: 'FT',
      level: level._devLevel,
      error: err,
      stackTrace: stackTrace,
    );
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
}