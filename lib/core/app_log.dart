import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

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
}

// ─── Level gating ────────────────────────────────────────────────────────────

bool _shouldLog(_Level level) {
  if (kReleaseMode) return false;
  if (kProfileMode) return level.index >= _Level.warn.index;
  return true; // debug: all levels
}

// ─── Logger ───────────────────────────────────────────────────────────────────

/// Lightweight logger with a domain tag and optional scope sub-tag.
///
/// Outputs to dart:developer log (visible in DevTools and filterable in
/// logcat with `adb logcat -s FT`).
///
/// Format:  prefix [HH:mm:ss.mmm][LEVEL][DOMAIN][SCOPE] message  | payload
///
/// Levels:
///   · DEBUG   — verbose trace, only in debug mode
///   ℹ INFO    — normal flow milestones
///   ✓ OK      — explicit success (saved, loaded, parsed OK)
///   ⚠ WARN    — recoverable issue, unexpected state
///   ✖ ERROR   — failure, exception caught
///
/// Release builds: silent.
/// Profile builds: WARN+ only.
/// Debug builds:   all levels.
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
      _emit(_Level.error, message,
          payload: payload, err: err, stackTrace: stackTrace);
}

// ─── Namespace ────────────────────────────────────────────────────────────────

/// Central logging namespace. Import this file and use AppLog.xxx throughout.
///
/// Domains:
///   app       — app lifecycle, startup
///   auth      — Google auth
///   health    — Health Connect service / provider
///   sync      — Google Sheets sync
///   nav       — navigation
///   ui        — generic UI events
///   db        — generic DB
///
/// KT domain + scopes:
///   kt         — generic KT
///   ktApi      — [KT][API]      HTTP requests / responses
///   ktParse    — [KT][PARSE]    JSON parsing
///   ktDb       — [KT][DB]       Isar persistence
///   ktProvider — [KT][PROVIDER] state management lifecycle
///   ktAvg      — [KT][AVG]      average calculations
///   ktUi       — [KT][UI]       what reaches the widgets
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
