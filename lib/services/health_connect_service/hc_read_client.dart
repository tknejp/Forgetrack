import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Shared Health Connect query infrastructure used by all HcXxxService collaborators.
///
/// Holds the single [Health] plugin instance, configuration state, and
/// availability cache. All feature services receive a reference to this object
/// and call its helpers instead of touching the plugin directly.
class HcReadClient {
  HcReadClient({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;
  bool? _availabilityCached;

  static const _logName = 'HealthConnectService';

  // ─── Logging ───────────────────────────────────────────────────────────────

  void logDebug(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName);
  }

  void logInfo(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName, level: 800);
  }

  void logWarning(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName, level: 900);
  }

  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    dev.log(
      message,
      name: _logName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  String fmt(DateTime dt) => dt.toIso8601String();

  // ─── Platform lifecycle ────────────────────────────────────────────────────

  Future<void> ensureConfigured() async {
    if (_configured) return;
    logDebug('Configuring health plugin...');
    await _health.configure();
    _configured = true;
    logInfo('Health plugin configured');
  }

  Future<bool> isAvailable({bool forceRefresh = false}) async {
    await ensureConfigured();

    if (!forceRefresh && _availabilityCached != null) {
      logDebug('Using cached availability: $_availabilityCached');
      return _availabilityCached!;
    }

    try {
      final status = await _health.getHealthConnectSdkStatus();
      final available = status == HealthConnectSdkStatus.sdkAvailable;
      _availabilityCached = available;
      logInfo('Health Connect SDK status: $status, available=$available');
      return available;
    } catch (e, st) {
      logError('Failed to get Health Connect SDK status', e, st);
      rethrow;
    }
  }

  Future<void> installHealthConnect() async {
    await ensureConfigured();
    logInfo('Opening Health Connect installation flow');
    await _health.installHealthConnect();
  }

  Future<void> assertAvailable() async {
    final available = await isAvailable();
    if (!available) {
      logWarning('Health Connect is not available');
      throw StateError('Health Connect is not available on this device');
    }
  }

  // ─── Plugin pass-throughs (used by HcPermissionService) ───────────────────

  Future<bool?> pluginHasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) =>
      _health.hasPermissions(types, permissions: permissions);

  Future<bool> pluginRequestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) =>
      _health.requestAuthorization(types, permissions: permissions);

  Future<bool> pluginIsHealthDataHistoryAvailable() =>
      _health.isHealthDataHistoryAvailable();

  Future<bool> pluginIsHealthDataHistoryAuthorized() =>
      _health.isHealthDataHistoryAuthorized();

  Future<bool> pluginRequestHealthDataHistoryAuthorization() =>
      _health.requestHealthDataHistoryAuthorization();

  // ─── Query helpers ─────────────────────────────────────────────────────────

  Future<List<HealthDataPoint>> fetchData({
    required String label,
    required DateTime start,
    required DateTime end,
    required List<HealthDataType> types,
  }) async {
    await ensureConfigured();
    await assertAvailable();

    try {
      logDebug(
        '$label: fetching types=$types from=${fmt(start)} to=${fmt(end)}',
      );

      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      logInfo('$label: fetched ${points.length} points');
      return points;
    } catch (e, st) {
      logError(
        '$label: failed fetching types=$types from=${fmt(start)} to=${fmt(end)}',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<int?> getTotalStepsInInterval(DateTime start, DateTime end) =>
      _health.getTotalStepsInInterval(start, end);

  double sumNumericValues(List<HealthDataPoint> points) {
    if (points.isEmpty) return 0.0;
    return points.map(numericValue).fold<double>(0.0, (a, b) => a + b);
  }

  DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  double numericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    throw StateError('Expected numeric value for ${point.type}');
  }
}
