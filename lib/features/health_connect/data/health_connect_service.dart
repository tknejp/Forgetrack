import 'package:health/health.dart';

import '../domain/activity_record.dart';
import '../domain/sleep_record.dart';
import '../domain/weight_record.dart';
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
///
/// **R.4 (2026-05-19) — stays bare (no [Result] wrap).** Method
/// returns are `Future<T>` rather than `Future<Result<T, AppError>>`
/// because the failure boundary is **inside** the `health` plugin, not
/// at this facade: quota-exceeded / permission-denied / IO faults all
/// raise as platform exceptions which [FitnessProvider] (and
/// `BackgroundSyncService` via `classifyFirebaseError` /
/// `_classifyBackgroundSyncError`) already catches + classifies. Force-
/// wrapping every getter here (50+ methods) would push duplicate
/// switch boilerplate onto every consumer for a classification that
/// already lands at the orchestrating provider. Health Connect quota
/// errors must preserve DB state (see docs/architecture.md §Health
/// Connect rules); that rule lives at the orchestrator, not this
/// adapter.
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

  Future<bool> isBackgroundPermissionAvailable() =>
      _permissions.isBackgroundPermissionAvailable();

  Future<bool> hasBackgroundPermission() =>
      _permissions.hasBackgroundPermission();

  Future<bool> requestBackgroundPermissionIfAvailable() =>
      _permissions.requestBackgroundPermissionIfAvailable();

  Future<bool?> hasWorkoutPermission() => _permissions.hasWorkoutPermission();

  Future<bool> requestWorkoutPermission() =>
      _permissions.requestWorkoutPermission();

  Future<void> ensureWorkoutPermission() =>
      _permissions.ensureWorkoutPermission();

  // ─── Steps ─────────────────────────────────────────────────────────────────

  Future<int> getStepsForDate(DateTime date) => _steps.getStepsForDate(date);

  Future<List<StepsRecord>> getStepsHistory(int days) =>
      _steps.getStepsHistory(days);

  Future<List<StepsRecord>> getStepsHistoryForRange(
    DateTime start,
    DateTime end,
  ) =>
      _steps.getStepsHistoryForRange(start, end);

  // ─── Active calories ───────────────────────────────────────────────────────

  Future<double> getActiveCaloriesBurned(DateTime start, DateTime end) =>
      _calories.getActiveCaloriesBurned(start, end);

  Future<double> getBasalCaloriesBurned(DateTime start, DateTime end) =>
      _calories.getBasalCaloriesBurned(start, end);

  Future<List<double>> getActiveCaloriesHistory(int days) =>
      _calories.getActiveCaloriesHistory(days);

  Future<List<double>> getBasalCaloriesHistory(int days) =>
      _calories.getBasalCaloriesHistory(days);

  Future<List<double>> getActiveCaloriesHistoryForRange(
    DateTime start,
    DateTime end,
  ) =>
      _calories.getActiveCaloriesHistoryForRange(start, end);

  Future<List<double>> getBasalCaloriesHistoryForRange(
    DateTime start,
    DateTime end,
  ) =>
      _calories.getBasalCaloriesHistoryForRange(start, end);

  // ─── Weight / body ─────────────────────────────────────────────────────────

  Future<List<WeightRecord>> getWeightHistory(int days) =>
      _body.getWeightHistory(days);

  Future<List<WeightRecord>> getWeightHistoryForRange(
    DateTime start,
    DateTime end,
  ) =>
      _body.getWeightHistoryForRange(start, end);

  Future<double?> getLatestBodyFat({int lookbackDays = 365}) =>
      _body.getLatestBodyFat(lookbackDays: lookbackDays);

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

  Future<List<SleepRecord>> getSleepHistoryForRange(
    DateTime start,
    DateTime end,
  ) =>
      _sleep.getSleepHistoryForRange(start, end);

  // ─── Debug helpers ─────────────────────────────────────────────────────────

  Future<void> debugWorkoutPermissionFlow() =>
      _permissions.debugWorkoutPermissionFlow();
}
