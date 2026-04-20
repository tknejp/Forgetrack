import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_log.dart';
import '../models/activity_record.dart';
import '../models/hc_records.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';

/// Isar-backed local store for Health Connect data.
///
/// Mirrors the pattern of [KtNutritionDatabase]: an in-memory cache is
/// populated on [open] so all provider reads are synchronous, while writes
/// are persisted to Isar in a single transaction.
class HealthDatabase {
  Isar? _isar;
  bool _opened = false;

  static const _logName = 'HealthDatabase';
  static const _isarName = 'health';
  static const _historyDays = 30;

  // ─── In-memory cache ──────────────────────────────────────────────────────

  List<StepsRecord> _stepsHistory = [];
  List<double> _caloriesHistory = [];
  List<WeightRecord> _weightHistory = [];
  List<SleepRecord> _sleepHistory = [];
  List<ActivityRecord> _activities = [];
  DateTime? _lastSyncedAt;
  bool _workoutPermission = false;
  double? _latestBodyFat;

  // ─── Sync getters (from cache) ────────────────────────────────────────────

  List<StepsRecord> get stepsHistory => _stepsHistory;
  List<double> get caloriesHistory => _caloriesHistory;
  List<WeightRecord> get weightHistory => _weightHistory;
  List<SleepRecord> get sleepHistory => _sleepHistory;
  List<ActivityRecord> get activities => _activities;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get workoutPermission => _workoutPermission;
  double? get latestBodyFat => _latestBodyFat;

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> open() async {
    if (_opened) {
      AppLog.app.debug('$_logName: open() skipped — already open');
      return;
    }
    _opened = true;
    final dir = await getApplicationDocumentsDirectory();
    AppLog.app.info('$_logName: opening Isar store', payload: dir.path);
    _isar = await Isar.open(
      [
        HcStepsDayRecordSchema,
        HcCalorieDayRecordSchema,
        HcWeightRecordSchema,
        HcSleepRecordSchema,
        HcActivityRecordSchema,
        HcMetaRecordSchema,
      ],
      directory: dir.path,
      name: _isarName,
    );
    await _loadCache();
    AppLog.app.info(
      '$_logName: ready — '
      'steps=${_stepsHistory.length}d '
      'weight=${_weightHistory.length} '
      'sleep=${_sleepHistory.length}n '
      'activities=${_activities.length} '
      'lastSync=${_lastSyncedAt?.toIso8601String() ?? "never"}',
    );
  }

  Future<void> _loadCache() async {
    final isar = _isar!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: _historyDays - 1));

    // Steps — dense 30-day array, oldest first, 0 for missing days.
    final stepRows = await isar.hcStepsDayRecords.where().findAll();
    final stepsByKey = {for (final r in stepRows) r.dateKey: r.steps};
    _stepsHistory = [
      for (var i = 0; i < _historyDays; i++)
        StepsRecord(
          date: rangeStart.add(Duration(days: i)),
          steps: stepsByKey[_toKey(rangeStart.add(Duration(days: i)))] ?? 0,
        ),
    ];

    // Active calories — aligned with steps by date key.
    final calRows = await isar.hcCalorieDayRecords.where().findAll();
    final calByKey = {for (final r in calRows) r.dateKey: r.kcal};
    _caloriesHistory = [
      for (final s in _stepsHistory) calByKey[_toKey(s.date)] ?? 0.0,
    ];

    // Weight — sorted oldest first.
    final weightRows = await isar.hcWeightRecords.where().findAll();
    weightRows.sort((a, b) => a.date.compareTo(b.date));
    _weightHistory = [
      for (final r in weightRows)
        WeightRecord(date: r.date, weight: r.weight, bodyFat: r.bodyFat),
    ];

    // Sleep — sorted newest first (provider expects [0] = last night).
    final sleepRows = await isar.hcSleepRecords.where().findAll();
    sleepRows.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    _sleepHistory = [
      for (final r in sleepRows)
        SleepRecord(
          sleepStart: r.sleepStart,
          wakeTime: r.wakeTime,
          totalDuration: Duration(seconds: r.totalDurationSeconds),
        ),
    ];

    // Activities — sorted newest first.
    final actRows = await isar.hcActivityRecords.where().findAll();
    actRows.sort((a, b) => b.startTime.compareTo(a.startTime));
    _activities = [
      for (final r in actRows)
        ActivityRecord(
          startTime: r.startTime,
          endTime: r.endTime,
          type: r.type,
          caloriesBurned: r.caloriesBurned,
          distanceKm: r.distanceKm,
        ),
    ];

    // Metadata singleton.
    final meta = await isar.hcMetaRecords.get(1);
    _lastSyncedAt = meta?.lastSyncedAt;
    _workoutPermission = meta?.workoutPermission ?? false;
    _latestBodyFat = meta?.latestBodyFat;
  }

  // ─── Writes ───────────────────────────────────────────────────────────────

  /// Replaces all health data in a single Isar transaction and updates the
  /// in-memory cache. Called only after a successful HC sync.
  Future<void> saveAll({
    required List<StepsRecord> steps,
    required List<double> calories,
    required List<WeightRecord> weight,
    required List<SleepRecord> sleep,
    required List<ActivityRecord> activities,
    required bool workoutPermission,
    required double? latestBodyFat,
    required DateTime lastSyncedAt,
  }) async {
    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcStepsDayRecords.clear();
      await isar.hcCalorieDayRecords.clear();
      await isar.hcWeightRecords.clear();
      await isar.hcSleepRecords.clear();
      await isar.hcActivityRecords.clear();

      await isar.hcStepsDayRecords.putAll([
        for (final r in steps)
          HcStepsDayRecord()
            ..dateKey = _toKey(r.date)
            ..steps = r.steps,
      ]);

      await isar.hcCalorieDayRecords.putAll([
        for (var i = 0; i < calories.length && i < steps.length; i++)
          HcCalorieDayRecord()
            ..dateKey = _toKey(steps[i].date)
            ..kcal = calories[i],
      ]);

      await isar.hcWeightRecords.putAll([
        for (final r in weight)
          HcWeightRecord()
            ..date = r.date
            ..weight = r.weight
            ..bodyFat = r.bodyFat,
      ]);

      await isar.hcSleepRecords.putAll([
        for (final r in sleep)
          HcSleepRecord()
            ..dateKey = _toKey(r.wakeTime)
            ..sleepStart = r.sleepStart
            ..wakeTime = r.wakeTime
            ..totalDurationSeconds = r.totalDuration.inSeconds,
      ]);

      await isar.hcActivityRecords.putAll([
        for (final r in activities)
          HcActivityRecord()
            ..startTime = r.startTime
            ..endTime = r.endTime
            ..type = r.type
            ..caloriesBurned = r.caloriesBurned
            ..distanceKm = r.distanceKm,
      ]);

      await isar.hcMetaRecords.put(
        HcMetaRecord()
          ..lastSyncedAt = lastSyncedAt
          ..workoutPermission = workoutPermission
          ..latestBodyFat = latestBodyFat,
      );
    });

    // Mirror to in-memory cache.
    _stepsHistory = steps;
    _caloriesHistory = calories;
    _weightHistory = weight;
    _sleepHistory = sleep;
    _activities = activities;
    _workoutPermission = workoutPermission;
    _latestBodyFat = latestBodyFat;
    _lastSyncedAt = lastSyncedAt;

    AppLog.app.info(
      '$_logName: saveAll() done — '
      'steps=${steps.length}d '
      'weight=${weight.length} '
      'sleep=${sleep.length}n '
      'activities=${activities.length}',
    );
  }

  /// Partial update: persists activities and workout permission after the user
  /// grants the WORKOUT permission mid-session.
  Future<void> saveActivitiesAndPermission({
    required List<ActivityRecord> activities,
    required bool workoutPermission,
  }) async {
    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcActivityRecords.clear();
      await isar.hcActivityRecords.putAll([
        for (final r in activities)
          HcActivityRecord()
            ..startTime = r.startTime
            ..endTime = r.endTime
            ..type = r.type
            ..caloriesBurned = r.caloriesBurned
            ..distanceKm = r.distanceKm,
      ]);

      final meta = (await isar.hcMetaRecords.get(1)) ?? HcMetaRecord();
      await isar.hcMetaRecords.put(
        meta..workoutPermission = workoutPermission,
      );
    });

    _activities = activities;
    _workoutPermission = workoutPermission;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _toKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
