import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../models/activity_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';

class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  final Health _health;

  bool _configured = false;
  bool? _availabilityCached;

  static const _logName = 'HealthConnectService';

  // Core permissions required for the app to leave the permission gate.
  // Optional scopes (workouts, sleep, body fat) are fetched opportunistically
  // and already degrade gracefully to empty/no-data states.
  static const List<HealthDataType> _requiredReadTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
  ];

  // Additional scopes requested for richer screens, but not used to block
  // the entire app when they are missing.
  //
  // On Android, the `health` plugin enriches WORKOUT reads by querying
  // distance and total-calorie records for each exercise session. If those
  // extra permissions are not granted, the workout fetch can fail and come
  // back empty even though WORKOUT itself is allowed.
  static const List<HealthDataType> _workoutReadTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  static const List<HealthDataType> _optionalReadTypes = [
    ..._workoutReadTypes,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.SLEEP_SESSION,
  ];

  static const List<HealthDataAccess> _requiredReadPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static const List<HealthDataAccess> _optionalReadPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static const List<HealthDataAccess> _workoutReadPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  // ─── Logging ───────────────────────────────────────────────────────────────

  void _logDebug(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName);
  }

  void _logInfo(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName, level: 800);
  }

  void _logWarning(String message) {
    if (!kDebugMode) return;
    dev.log(message, name: _logName, level: 900);
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    dev.log(
      message,
      name: _logName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _fmt(DateTime dt) => dt.toIso8601String();

  // ─── Init / availability ───────────────────────────────────────────────────

  Future<void> _ensureConfigured() async {
    if (_configured) return;

    _logDebug('Configuring health plugin...');
    await _health.configure();
    _configured = true;
    _logInfo('Health plugin configured');
  }

  Future<bool> isAvailable({bool forceRefresh = false}) async {
    await _ensureConfigured();

    if (!forceRefresh && _availabilityCached != null) {
      _logDebug('Using cached availability: $_availabilityCached');
      return _availabilityCached!;
    }

    try {
      final status = await _health.getHealthConnectSdkStatus();
      final available = status == HealthConnectSdkStatus.sdkAvailable;
      _availabilityCached = available;

      _logInfo(
        'Health Connect SDK status: $status, available=$available',
      );

      return available;
    } catch (e, st) {
      _logError('Failed to get Health Connect SDK status', e, st);
      rethrow;
    }
  }

  Future<void> installHealthConnect() async {
    await _ensureConfigured();
    _logInfo('Opening Health Connect installation flow');
    await _health.installHealthConnect();
  }

  Future<void> _assertAvailable() async {
    final available = await isAvailable();
    if (!available) {
      _logWarning('Health Connect is not available');
      throw StateError('Health Connect is not available on this device');
    }
  }

  // ─── Permissions ───────────────────────────────────────────────────────────

  Future<bool?> hasPermissions() async {
    await _ensureConfigured();
    await _assertAvailable();

    try {
      final result = await _health.hasPermissions(
        _requiredReadTypes,
        permissions: _requiredReadPermissions,
      );

      _logInfo('hasPermissions(required read types) => $result');
      return result;
    } catch (e, st) {
      _logError('hasPermissions(required read types) failed', e, st);
      rethrow;
    }
  }

  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    await _assertAvailable();

    try {
      final requestedTypes = <HealthDataType>[
        ..._requiredReadTypes,
        ..._optionalReadTypes,
      ];
      final requestedPermissions = <HealthDataAccess>[
        ..._requiredReadPermissions,
        ..._optionalReadPermissions,
      ];

      _logInfo('Requesting permissions for read types: $requestedTypes');

      final granted = await _health.requestAuthorization(
        requestedTypes,
        permissions: requestedPermissions,
      );

      _logInfo('requestPermissions(read types) => $granted');

      final after = await _health.hasPermissions(
        _requiredReadTypes,
        permissions: _requiredReadPermissions,
      );

      _logInfo('hasPermissions(required read types) after request => $after');

      return after == true;
    } catch (e, st) {
      _logError('requestPermissions(read types) failed', e, st);
      rethrow;
    }
  }

  Future<bool?> hasWorkoutPermission() async {
    await _ensureConfigured();
    await _assertAvailable();

    try {
      final result = await _health.hasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );

      _logInfo('hasWorkoutPermission() => $result');
      return result;
    } catch (e, st) {
      _logError('hasWorkoutPermission() failed', e, st);
      rethrow;
    }
  }

  Future<bool> requestWorkoutPermission() async {
    await _ensureConfigured();
    await _assertAvailable();

    try {
      final before = await _health.hasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _logInfo('WORKOUT permission before request => $before');

      final granted = await _health.requestAuthorization(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _logInfo('WORKOUT requestAuthorization => $granted');

      final after = await _health.hasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _logInfo('WORKOUT permission after request => $after');

      return after == true;
    } catch (e, st) {
      _logError('requestWorkoutPermission() failed', e, st);
      rethrow;
    }
  }

  Future<void> ensureWorkoutPermission() async {
    final hasPermission = await hasWorkoutPermission();
    if (hasPermission == true) return;

    _logWarning('WORKOUT permission missing');
    throw StateError('WORKOUT permission not granted');
  }

  // ─── Internal fetch helpers ────────────────────────────────────────────────

  Future<List<HealthDataPoint>> _fetchData({
    required String label,
    required DateTime start,
    required DateTime end,
    required List<HealthDataType> types,
  }) async {
    await _ensureConfigured();
    await _assertAvailable();

    try {
      _logDebug(
        '$label: fetching types=$types from=${_fmt(start)} to=${_fmt(end)}',
      );

      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      _logInfo('$label: fetched ${points.length} points');
      return points;
    } catch (e, st) {
      _logError(
        '$label: failed fetching types=$types from=${_fmt(start)} to=${_fmt(end)}',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<List<HealthDataPoint>> _fetchWorkoutData({
    required DateTime start,
    required DateTime end,
  }) async {
    return _fetchData(
      label: 'WORKOUT',
      start: start,
      end: end,
      types: const [HealthDataType.WORKOUT],
    );
  }

  double _sumNumericValues(List<HealthDataPoint> points) {
    if (points.isEmpty) return 0.0;

    return points
        .map((p) => (p.value as NumericHealthValue).numericValue.toDouble())
        .fold<double>(0.0, (a, b) => a + b);
  }

  // ─── Steps ─────────────────────────────────────────────────────────────────

  Future<int> getStepsForDate(DateTime date) async {
    await _ensureConfigured();
    await _assertAvailable();

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      _logDebug(
        'getStepsForDate(): date=${start.toIso8601String().split("T").first}',
      );

      final steps = await _health.getTotalStepsInInterval(start, end) ?? 0;

      _logInfo(
        'getStepsForDate(): ${start.toIso8601String().split("T").first} => $steps',
      );

      return steps;
    } catch (e, st) {
      _logError(
        'getStepsForDate() failed for ${start.toIso8601String().split("T").first}',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<List<StepsRecord>> getStepsHistory(int days) async {
    _logDebug('getStepsHistory(days=$days)');

    final now = DateTime.now();
    final records = <StepsRecord>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = await getStepsForDate(date);
      records.add(StepsRecord(date: date, steps: steps));
    }

    _logInfo('getStepsHistory(): produced ${records.length} daily records');
    return records;
  }

  // ─── Active calories ───────────────────────────────────────────────────────

  Future<double> getActiveCaloriesBurned(DateTime start, DateTime end) async {
    final points = await _fetchData(
      label: 'ACTIVE_ENERGY_BURNED',
      start: start,
      end: end,
      types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
    );

    final total = _sumNumericValues(points);

    _logInfo(
      'getActiveCaloriesBurned(): total=$total from=${_fmt(start)} to=${_fmt(end)}',
    );

    return total;
  }

  Future<List<double>> getActiveCaloriesHistory(int days) async {
    _logDebug('getActiveCaloriesHistory(days=$days)');

    final now = DateTime.now();
    final result = <double>[];

    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      result.add(await getActiveCaloriesBurned(start, end));
    }

    _logInfo('getActiveCaloriesHistory(): produced ${result.length} values');
    return result;
  }

  // ─── Weight ────────────────────────────────────────────────────────────────

  Future<List<WeightRecord>> getWeightHistory(int days) async {
    final end = DateTime.now();
    final start = DateTime(end.year, end.month, end.day)
        .subtract(Duration(days: days - 1));

    final points = await _fetchData(
      label: 'WEIGHT',
      start: start,
      end: end,
      types: const [HealthDataType.WEIGHT],
    );

    if (points.isEmpty) {
      _logInfo('getWeightHistory(): no data');
      return [];
    }

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final result = points
        .map(
          (p) => WeightRecord(
            date: p.dateFrom,
            weight: (p.value as NumericHealthValue).numericValue.toDouble(),
          ),
        )
        .toList();

    _logInfo('getWeightHistory(): ${result.length} weight entries');
    return result;
  }

  // ─── Body fat ──────────────────────────────────────────────────────────────

  Future<double?> getLatestBodyFat() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 365));

    final points = await _fetchData(
      label: 'BODY_FAT_PERCENTAGE',
      start: start,
      end: end,
      types: const [HealthDataType.BODY_FAT_PERCENTAGE],
    );

    if (points.isEmpty) {
      _logInfo('getLatestBodyFat(): no data');
      return null;
    }

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final latest =
        (points.last.value as NumericHealthValue).numericValue.toDouble();

    _logInfo('getLatestBodyFat(): latest=$latest');
    return latest;
  }

  // ─── Activities & heart rate ───────────────────────────────────────────────

  Future<List<ActivityRecord>> getActivities(
    DateTime start,
    DateTime end,
  ) async {
    final points = await _fetchWorkoutData(
      start: start,
      end: end,
    );

    final result = points
        .map(ActivityRecord.fromHealthPoint)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    _logInfo(
      'getActivities(): ${result.length} workout records from=${_fmt(start)} to=${_fmt(end)}',
    );

    return result;
  }

  Future<double?> getTodayAvgHeartRate() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final points = await _fetchData(
      label: 'HEART_RATE',
      start: start,
      end: now,
      types: const [HealthDataType.HEART_RATE],
    );

    if (points.isEmpty) {
      _logInfo('getTodayAvgHeartRate(): no data');
      return null;
    }

    final values = points
        .map((p) => (p.value as NumericHealthValue).numericValue.toDouble())
        .toList();

    final avg = values.reduce((a, b) => a + b) / values.length;

    _logInfo('getTodayAvgHeartRate(): avg=$avg from ${values.length} samples');
    return avg;
  }

  // ─── Sleep ─────────────────────────────────────────────────────────────────

  /// Returns the aggregated sleep record for the night ending on [date].
  ///
  /// The lookup window is 18:00 the previous day → 14:00 on [date], which
  /// covers all typical overnight sleep patterns including late bedtimes and
  /// morning lie-ins while excluding the following night's sleep.
  ///
  /// [totalDuration] is the sum of all individual SLEEP_SESSION durations
  /// within the window — not the wall-clock span from first sleep to last
  /// wake, which would inflate the number by awake time between sessions.
  Future<SleepRecord?> getSleepForNight(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final windowStart = dayStart.subtract(const Duration(hours: 6)); // 18:00 prev day
    final windowEnd = dayStart.add(const Duration(hours: 14)); // 14:00 today
    final now = DateTime.now();
    final end = windowEnd.isBefore(now) ? windowEnd : now;

    final points = await _fetchData(
      label: 'SLEEP_SESSION',
      start: windowStart,
      end: end,
      types: const [HealthDataType.SLEEP_SESSION],
    );

    if (points.isEmpty) {
      _logInfo('getSleepForNight(): no sleep data for ${_fmt(dayStart)}');
      return null;
    }

    Duration total = Duration.zero;
    DateTime earliest = points.first.dateFrom;
    DateTime latest = points.first.dateTo;

    for (final p in points) {
      final sessionDuration = p.dateTo.difference(p.dateFrom);
      total += sessionDuration;
      if (p.dateFrom.isBefore(earliest)) earliest = p.dateFrom;
      if (p.dateTo.isAfter(latest)) latest = p.dateTo;
    }

    _logInfo(
      'getSleepForNight(): total=${total.inMinutes}min'
      ' start=${_fmt(earliest)} wake=${_fmt(latest)}',
    );

    return SleepRecord(
      sleepStart: earliest,
      wakeTime: latest,
      totalDuration: total,
    );
  }

  // ─── Debug helpers ─────────────────────────────────────────────────────────

  Future<void> debugWorkoutPermissionFlow() async {
    await _ensureConfigured();
    await _assertAvailable();

    try {
      _logInfo('debugWorkoutPermissionFlow() started');

      final before = await _health.hasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _logInfo('WORKOUT hasPermissions BEFORE => $before');

      final requested = await _health.requestAuthorization(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _logInfo('WORKOUT requestAuthorization => $requested');

      final after = await _health.hasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _logInfo('WORKOUT hasPermissions AFTER => $after');
    } catch (e, st) {
      _logError('debugWorkoutPermissionFlow() failed', e, st);
      rethrow;
    }
  }
}
