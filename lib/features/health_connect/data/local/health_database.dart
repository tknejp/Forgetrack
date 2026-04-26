import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_log.dart';
import '../../domain/activity_record.dart';
import '../../domain/sleep_record.dart';
import '../../domain/weight_record.dart';
import 'hc_records.dart';

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

    try {
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
    } catch (_) {
      _opened = false;
      _isar = null;
      rethrow;
    }
  }

  Future<void> close({bool clearMemoryCache = false}) async {
    final value = _isar;

    if (value == null) {
      _opened = false;
      if (clearMemoryCache) {
        _clearMemoryCache();
      }
      return;
    }
    try {
      await value.close();
      AppLog.app.debug('$_logName: closed');
    } catch (e, st) {
      AppLog.app.error(
        '$_logName: close() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      _isar = null;
      _opened = false;
      if (clearMemoryCache) {
        _clearMemoryCache();
      }
    }
  }

  void _clearMemoryCache() {
    _stepsHistory = [];
    _caloriesHistory = [];
    _weightHistory = [];
    _sleepHistory = [];
    _activities = [];
    _lastSyncedAt = null;
    _workoutPermission = false;
    _latestBodyFat = null;
  }

  Future<void> _loadCache() async {
    final isar = _isar!;
    final today = _today();

    // Steps — dense 30-day array, oldest first, 0 for missing days.
    final stepRows = await isar.hcStepsDayRecords.where().findAll();
    stepRows.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final stepsByKey = {for (final r in stepRows) r.dateKey: r.steps};
    if (stepRows.isEmpty) {
      _stepsHistory = [];
    } else {
      final oldestStoredDay = _fromKey(stepRows.first.dateKey);
      final totalDays = today.difference(oldestStoredDay).inDays + 1;
      _stepsHistory = [
        for (var i = 0; i < totalDays; i++)
          StepsRecord(
            date: oldestStoredDay.add(Duration(days: i)),
            steps:
                stepsByKey[_toKey(oldestStoredDay.add(Duration(days: i)))] ?? 0,
          ),
      ];
    }

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

  Future<void> saveOverviewRange({
    required List<StepsRecord> steps,
    required List<double> calories,
    required List<WeightRecord> weight,
    required List<SleepRecord> sleep,
    required double? latestBodyFat,
    required DateTime lastSyncedAt,
  }) async {
    final isar = _isar!;

    await isar.writeTxn(() async {
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

      final meta = (await isar.hcMetaRecords.get(1)) ?? HcMetaRecord();
      await isar.hcMetaRecords.put(
        meta
          ..lastSyncedAt = lastSyncedAt
          ..latestBodyFat = latestBodyFat,
      );
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveOverviewRange() done — '
      'steps=${steps.length}d calories=${calories.length}d '
      'weight=${weight.length} sleep=${sleep.length}n',
    );
  }

    /// Partial update: upserts step records only.
  ///
  /// Does not clear existing steps. Safe for normal refresh.
  Future<void> saveStepsPartial(List<StepsRecord> steps) async {
    if (steps.isEmpty) {
      AppLog.app.debug('$_logName: saveStepsPartial() skipped — empty input');
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcStepsDayRecords.putAll([
        for (final r in steps)
          HcStepsDayRecord()
            ..dateKey = _toKey(r.date)
            ..steps = r.steps,
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveStepsPartial() done — steps=${steps.length}d',
    );
  }

  /// Partial update: upserts active calorie records only.
  ///
  /// Calories are currently aligned by index to [dateReference].
  /// This preserves existing records outside the refreshed range.
  Future<void> saveCaloriesPartial({
    required List<StepsRecord> dateReference,
    required List<double> calories,
  }) async {
    if (dateReference.isEmpty || calories.isEmpty) {
      AppLog.app.debug(
        '$_logName: saveCaloriesPartial() skipped — empty input',
      );
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcCalorieDayRecords.putAll([
        for (var i = 0; i < calories.length && i < dateReference.length; i++)
          HcCalorieDayRecord()
            ..dateKey = _toKey(dateReference[i].date)
            ..kcal = calories[i],
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveCaloriesPartial() done — calories=${calories.length}d',
    );
  }

  /// Partial update: upserts weight records only.
  Future<void> saveWeightPartial(List<WeightRecord> weight) async {
    if (weight.isEmpty) {
      AppLog.app.debug('$_logName: saveWeightPartial() skipped — empty input');
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcWeightRecords.putAll([
        for (final r in weight)
          HcWeightRecord()
            ..date = r.date
            ..weight = r.weight
            ..bodyFat = r.bodyFat,
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveWeightPartial() done — weight=${weight.length}',
    );
  }

  /// Partial update: upserts sleep records only.
  ///
  /// Does not clear existing sleep records.
  Future<void> saveSleepPartial(List<SleepRecord> sleep) async {
    if (sleep.isEmpty) {
      AppLog.app.debug('$_logName: saveSleepPartial() skipped — empty input');
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcSleepRecords.putAll([
        for (final r in sleep)
          HcSleepRecord()
            ..dateKey = _toKey(r.wakeTime)
            ..sleepStart = r.sleepStart
            ..wakeTime = r.wakeTime
            ..totalDurationSeconds = r.totalDuration.inSeconds,
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveSleepPartial() done — sleep=${sleep.length}n',
    );
  }

  /// Partial update: upserts activities only.
  ///
  /// Does not clear existing activities.
  Future<void> saveActivitiesPartial(List<ActivityRecord> activities) async {
    if (activities.isEmpty) {
      AppLog.app.debug(
        '$_logName: saveActivitiesPartial() skipped — empty input',
      );
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      await isar.hcActivityRecords.putAll([
        for (final r in activities)
          HcActivityRecord()
            ..startTime = r.startTime
            ..endTime = r.endTime
            ..type = r.type
            ..caloriesBurned = r.caloriesBurned
            ..distanceKm = r.distanceKm,
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveActivitiesPartial() done — '
      'activities=${activities.length}',
    );
  }

  /// Updates metadata only.
  ///
  /// Null values mean "preserve existing".
  Future<void> updateMeta({
    DateTime? lastSyncedAt,
    bool? workoutPermission,
    double? latestBodyFat,
  }) async {
    final isar = _isar!;

    await isar.writeTxn(() async {
      final meta = (await isar.hcMetaRecords.get(1)) ?? HcMetaRecord();

      await isar.hcMetaRecords.put(
        meta
          ..lastSyncedAt = lastSyncedAt ?? meta.lastSyncedAt
          ..workoutPermission = workoutPermission ?? meta.workoutPermission
          ..latestBodyFat = latestBodyFat ?? meta.latestBodyFat,
      );
    });

    await _loadCache();

    AppLog.app.debug(
      '$_logName: updateMeta() done — '
      'lastSync=${_lastSyncedAt?.toIso8601String() ?? "never"} '
      'workoutPermission=$_workoutPermission',
    );
  }
  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _toKey(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static DateTime _fromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Streams notifications when any health data changes in the DB.
  /// Used for live reactive updates when background task writes new data.
  Stream<void> watchForChanges() {
    final isar = _isar;
    if (isar == null) return const Stream.empty();

    late final StreamController<void> controller;
    final subscriptions = <StreamSubscription<void>>[];

    void notify(_) {
      if (!controller.isClosed) {
        controller.add(null);
      }
    }

    controller = StreamController<void>.broadcast(
      onListen: () {
        subscriptions.addAll([
          isar.hcStepsDayRecords.watchLazy().listen(notify),
          isar.hcCalorieDayRecords.watchLazy().listen(notify),
          isar.hcWeightRecords.watchLazy().listen(notify),
          isar.hcSleepRecords.watchLazy().listen(notify),
          isar.hcActivityRecords.watchLazy().listen(notify),
          isar.hcMetaRecords.watchLazy().listen(notify),
        ]);
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }
}
