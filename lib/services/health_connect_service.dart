import 'package:health/health.dart';

import '../models/activity_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';
import 'health_connect_service/hc_body_service.dart';
import 'health_connect_service/hc_calories_service.dart';
import 'health_connect_service/hc_permission_service.dart';
import 'health_connect_service/hc_read_client.dart';
import 'health_connect_service/hc_sleep_service.dart';
import 'health_connect_service/hc_steps_service.dart';
import 'health_connect_service/hc_workout_service.dart';

/// Public facade consumed by [FitnessProvider] and [main].
///
/// Delegates all feature reads to focused internal collaborators while keeping
/// the public API identical to the original monolithic implementation.
class HealthConnectService {
  HealthConnectService({Health? health}) {
    _client = HcReadClient(health: health);
    _permissions = HcPermissionService(_client);
    _steps = HcStepsService(_client);
    _calories = HcCaloriesService(_client);
    _body = HcBodyService(_client);
    _workouts = HcWorkoutService(_client);
    _sleep = HcSleepService(_client);
  }

  late final HcReadClient _client;
  late final HcPermissionService _permissions;
  late final HcStepsService _steps;
  late final HcCaloriesService _calories;
  late final HcBodyService _body;
  late final HcWorkoutService _workouts;
  late final HcSleepService _sleep;

  // ─── Availability ──────────────────────────────────────────────────────────

  Future<bool> isAvailable({bool forceRefresh = false}) =>
      _client.isAvailable(forceRefresh: forceRefresh);

  Future<void> installHealthConnect() => _client.installHealthConnect();

  // ─── Permissions ───────────────────────────────────────────────────────────

  Future<bool?> hasPermissions() => _permissions.hasPermissions();

  Future<bool> requestPermissions() => _permissions.requestPermissions();

  Future<bool> isHistoryPermissionAvailable() =>
      _permissions.isHistoryPermissionAvailable();

  Future<bool> hasHistoryPermission() => _permissions.hasHistoryPermission();

  Future<bool> requestHistoryPermissionIfAvailable() =>
      _permissions.requestHistoryPermissionIfAvailable();

  Future<bool?> hasWorkoutPermission() => _permissions.hasWorkoutPermission();

  Future<bool> requestWorkoutPermission() =>
      _permissions.requestWorkoutPermission();

  Future<void> ensureWorkoutPermission() =>
      _permissions.ensureWorkoutPermission();

  // ─── Steps ─────────────────────────────────────────────────────────────────

  Future<int> getStepsForDate(DateTime date) => _steps.getStepsForDate(date);

  Future<List<StepsRecord>> getStepsHistory(int days) =>
      _steps.getStepsHistory(days);

  // ─── Active calories ───────────────────────────────────────────────────────

  Future<double> getActiveCaloriesBurned(DateTime start, DateTime end) =>
      _calories.getActiveCaloriesBurned(start, end);

  Future<List<double>> getActiveCaloriesHistory(int days) =>
      _calories.getActiveCaloriesHistory(days);

  // ─── Weight / body ─────────────────────────────────────────────────────────

  Future<List<WeightRecord>> getWeightHistory(int days) =>
      _body.getWeightHistory(days);

  Future<double?> getLatestBodyFat() => _body.getLatestBodyFat();

  // ─── Activities ────────────────────────────────────────────────────────────

  Future<List<ActivityRecord>> getActivities(
    DateTime start,
    DateTime end,
  ) =>
      _workouts.getActivities(start, end);

  // ─── Heart rate (kept in facade — single method, minimal extraction value) ─

  Future<double?> getTodayAvgHeartRate() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final points = await _client.fetchData(
      label: 'HEART_RATE',
      start: start,
      end: now,
      types: const [HealthDataType.HEART_RATE],
    );

    if (points.isEmpty) {
      _client.logInfo('getTodayAvgHeartRate(): no data');
      return null;
    }

    final values = points.map(_client.numericValue).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;

    _client.logInfo(
      'getTodayAvgHeartRate(): avg=$avg from ${values.length} samples',
    );
    return avg;
  }

  // ─── Sleep ─────────────────────────────────────────────────────────────────

  Future<SleepRecord?> getSleepForNight(DateTime date) =>
      _sleep.getSleepForNight(date);

  Future<List<SleepRecord>> getSleepHistory(int nights) =>
      _sleep.getSleepHistory(nights);

  // ─── Debug helpers ─────────────────────────────────────────────────────────

  Future<void> debugWorkoutPermissionFlow() =>
      _permissions.debugWorkoutPermissionFlow();
}
