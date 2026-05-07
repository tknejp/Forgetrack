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
  List<double> _basalCaloriesHistory = [];
  List<WeightRecord> _weightHistory = [];
  List<SleepRecord> _sleepHistory = [];
  List<ActivityRecord> _activities = [];
  DateTime? _lastSyncedAt;
  bool _workoutPermission = false;
  double? _latestBodyFat;

  // ─── Sync getters (from cache) ────────────────────────────────────────────

  List<StepsRecord> get stepsHistory => _stepsHistory;
  List<double> get caloriesHistory => _caloriesHistory;
  List<double> get basalCaloriesHistory => _basalCaloriesHistory;
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

      await _deduplicateWeightRecords();
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
    _basalCaloriesHistory = [];
    _weightHistory = [];
    _sleepHistory = [];
    _activities = [];
    _lastSyncedAt = null;
    _workoutPermission = false;
    _latestBodyFat = null;
  }

  /// Removes duplicate weight records that share the same UTC millisecond
  /// timestamp. Merges bodyFat / bodyWater from duplicates into the surviving
  /// record so no measurement data is lost.  Runs once at open() time.
  Future<void> _deduplicateWeightRecords() async {
    final isar = _isar!;
    final all = await isar.hcWeightRecords.where().findAll();

    final byMs = <int, HcWeightRecord>{};
    for (final r in all) {
      final ms = r.date.toUtc().millisecondsSinceEpoch;
      final existing = byMs[ms];
      if (existing == null) {
        byMs[ms] = r;
      } else {
        existing.bodyFat ??= r.bodyFat;
        existing.bodyWater ??= r.bodyWater;
      }
    }

    if (byMs.length == all.length) return;

    AppLog.app.info(
      '$_logName: deduplicating weight records — ${all.length} → ${byMs.length}',
    );

    await isar.writeTxn(() async {
      await isar.hcWeightRecords.clear();
      await isar.hcWeightRecords.putAll(byMs.values.toList());
    });
  }

  Future<void> _loadCache() async {
    final isar = _isar!;
    final today = _today();
    final todayKey = _toKey(today);

    // Steps — dense local-calendar-day array, oldest first, 0 for missing days.
    //
    // Important:
    // - Do not use DateTime.difference(...).inDays for local calendar days.
    //   DST can make the duration 1 hour shorter/longer and truncate the day count.
    // - Ignore future rows. They can exist from older buggy range syncs and should
    //   not affect the in-memory timeline.
    final rawStepRows = await isar.hcStepsDayRecords.where().findAll();
    final stepRows = rawStepRows
        .where((r) => r.dateKey.compareTo(todayKey) <= 0)
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    final stepsByKey = <String, int>{};
    for (final r in stepRows) {
      stepsByKey[r.dateKey] = r.steps;
    }

    if (stepRows.isEmpty) {
      _stepsHistory = [];
    } else {
      final oldestStoredDay = _fromKey(stepRows.first.dateKey);
      final history = <StepsRecord>[];

      var day = oldestStoredDay;
      while (!day.isAfter(today)) {
        final key = _toKey(day);

        history.add(
          StepsRecord(
            date: day,
            steps: stepsByKey[key] ?? 0,
          ),
        );

        // Calendar-day increment, DST-safe.
        day = DateTime(day.year, day.month, day.day + 1);
      }

      _stepsHistory = history;
      AppLog.app.warn(
        '$_logName(${identityHashCode(this)}): _loadCache steps — '
        'rawRows=${rawStepRows.length}, '
        'usableRows=${stepRows.length}, '
        'first=${stepRows.isEmpty ? "none" : stepRows.first.dateKey}, '
        'last=${stepRows.isEmpty ? "none" : stepRows.last.dateKey}, '
        'cacheCount=${_stepsHistory.length}, '
        'cacheLast=${_stepsHistory.isEmpty ? "none" : "${_toKey(_stepsHistory.last.date)}=${_stepsHistory.last.steps}"}, '
        'today=${_stepsHistory.where((r) => _toKey(r.date) == todayKey).map((r) => r.steps).toList()}',
      );
    }

    // Active calories — aligned with steps by date key.
    // Ignore future calorie rows for the same reason as steps.
    final rawCalRows = await isar.hcCalorieDayRecords.where().findAll();
    final calByKey = <String, double>{};
    final basalCalByKey = <String, double>{};
    for (final r in rawCalRows) {
      if (r.dateKey.compareTo(todayKey) <= 0) {
        calByKey[r.dateKey] = r.kcal;
        basalCalByKey[r.dateKey] = r.basalKcal;
      }
    }

    _caloriesHistory = [
      for (final s in _stepsHistory) calByKey[_toKey(s.date)] ?? 0.0,
    ];
    _basalCaloriesHistory = [
      for (final s in _stepsHistory) basalCalByKey[_toKey(s.date)] ?? 0.0,
    ];

    // Weight — sorted oldest first.
    final weightRows = await isar.hcWeightRecords.where().findAll();
    weightRows.sort((a, b) => a.date.compareTo(b.date));

    _weightHistory = [
      for (final r in weightRows)
        WeightRecord(
          date: r.date,
          weight: r.weight,
          bodyFat: r.bodyFat,
          bodyWater: r.bodyWater,
        ),
    ];

    // Sleep — sorted newest first (provider expects [0] = last night).
    final sleepRows = await isar.hcSleepRecords.where().findAll();
    sleepRows.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    _sleepHistory = [for (final r in sleepRows) _sleepFromRow(r)];

    // Activities — sorted newest first.
    final actRows = await isar.hcActivityRecords.where().findAll();
    actRows.sort((a, b) => b.startTime.compareTo(a.startTime));

    _activities = _dedupeActivities([
      for (final r in actRows) _activityFromRow(r),
    ]);

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
    required List<double> basalCalories,
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
        for (var i = 0;
            i < steps.length &&
                (i < calories.length || i < basalCalories.length);
            i++)
          HcCalorieDayRecord()
            ..dateKey = _toKey(steps[i].date)
            ..kcal = i < calories.length ? calories[i] : 0.0
            ..basalKcal = i < basalCalories.length ? basalCalories[i] : 0.0,
      ]);

      await isar.hcWeightRecords.putAll([
        for (final r in weight)
          HcWeightRecord()
            ..date = r.date
            ..weight = r.weight
            ..bodyFat = r.bodyFat
            ..bodyWater = r.bodyWater,
      ]);

      await isar.hcSleepRecords.putAll([
        for (final r in sleep) _sleepToRow(r),
      ]);

      await isar.hcActivityRecords.putAll([
        for (final r in _dedupeActivities(activities)) _activityToRow(r),
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
    _basalCaloriesHistory = basalCalories;
    _weightHistory = weight;
    _sleepHistory = sleep;
    _activities = _dedupeActivities(activities);
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
        for (final r in _dedupeActivities(activities)) _activityToRow(r),
      ]);

      final meta = (await isar.hcMetaRecords.get(1)) ?? HcMetaRecord();
      await isar.hcMetaRecords.put(
        meta..workoutPermission = workoutPermission,
      );
    });

    _activities = _dedupeActivities(activities);
    _workoutPermission = workoutPermission;
  }

  Future<void> saveOverviewRange({
    required List<StepsRecord> steps,
    required List<double> calories,
    required List<double> basalCalories,
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

      final existingCalories = await isar.hcCalorieDayRecords.where().findAll();
      final existingCaloriesByKey = {
        for (final r in existingCalories) r.dateKey: r
      };
      await isar.hcCalorieDayRecords.putAll([
        for (var i = 0;
            i < steps.length &&
                (i < calories.length || i < basalCalories.length);
            i++)
          HcCalorieDayRecord()
            ..dateKey = _toKey(steps[i].date)
            ..kcal = i < calories.length
                ? calories[i]
                : (existingCaloriesByKey[_toKey(steps[i].date)]?.kcal ?? 0.0)
            ..basalKcal = i < basalCalories.length
                ? basalCalories[i]
                : (existingCaloriesByKey[_toKey(steps[i].date)]?.basalKcal ??
                    0.0),
      ]);

      await isar.hcWeightRecords.putAll([
        for (final r in weight)
          HcWeightRecord()
            ..date = r.date
            ..weight = r.weight
            ..bodyFat = r.bodyFat
            ..bodyWater = r.bodyWater,
      ]);

      await isar.hcSleepRecords.putAll([
        for (final r in sleep) _sleepToRow(r),
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

    AppLog.app.warn(
      'HealthDatabase(${identityHashCode(this)}): saveStepsPartial after load — '
      'steps=${_stepsHistory.length}, '
      'last=${_stepsHistory.isEmpty ? "none" : "${_toKey(_stepsHistory.last.date)}=${_stepsHistory.last.steps}"}, '
      'today=${_stepsHistory.where((r) => _toKey(r.date) == _toKey(_today())).map((r) => r.steps).toList()}',
    );
  }

  /// Partial update: upserts active calorie records only.
  ///
  /// Calories are currently aligned by index to [dateReference].
  /// This preserves existing records outside the refreshed range.
  Future<void> saveCaloriesPartial({
    required List<StepsRecord> dateReference,
    required List<double> calories,
    List<double> basalCalories = const [],
  }) async {
    if (dateReference.isEmpty || (calories.isEmpty && basalCalories.isEmpty)) {
      AppLog.app.debug(
        '$_logName: saveCaloriesPartial() skipped — empty input',
      );
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      final existing = await isar.hcCalorieDayRecords.where().findAll();
      final existingByKey = {for (final r in existing) r.dateKey: r};
      await isar.hcCalorieDayRecords.putAll([
        for (var i = 0;
            i < dateReference.length &&
                (i < calories.length || i < basalCalories.length);
            i++)
          HcCalorieDayRecord()
            ..dateKey = _toKey(dateReference[i].date)
            ..kcal = i < calories.length
                ? calories[i]
                : (existingByKey[_toKey(dateReference[i].date)]?.kcal ?? 0.0)
            ..basalKcal = i < basalCalories.length
                ? basalCalories[i]
                : (existingByKey[_toKey(dateReference[i].date)]?.basalKcal ??
                    0.0),
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveCaloriesPartial() done — calories=${calories.length}d',
    );
  }

  /// Partial update: upserts weight records only.
  ///
  /// Matches incoming records to existing rows by UTC millisecond timestamp so
  /// repeated syncs update in-place rather than creating duplicates. Preserves
  /// an existing bodyFat value when the incoming record has null.
  Future<void> saveWeightPartial(List<WeightRecord> weight) async {
    if (weight.isEmpty) {
      AppLog.app.debug('$_logName: saveWeightPartial() skipped — empty input');
      return;
    }

    final isar = _isar!;

    await isar.writeTxn(() async {
      final existing = await isar.hcWeightRecords.where().findAll();
      final byMs = <int, HcWeightRecord>{
        for (final r in existing) r.date.toUtc().millisecondsSinceEpoch: r,
      };

      final toSave = weight.map((r) {
        final ms = r.date.toUtc().millisecondsSinceEpoch;
        final rec = byMs[ms] ?? HcWeightRecord();
        rec.date = r.date;
        rec.weight = r.weight;
        rec.bodyFat = r.bodyFat ?? rec.bodyFat;
        rec.bodyWater = r.bodyWater ?? rec.bodyWater;
        return rec;
      }).toList();

      await isar.hcWeightRecords.putAll(toSave);
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
        for (final r in sleep) _sleepToRow(r),
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveSleepPartial() done — sleep=${sleep.length}n',
    );
  }

  /// Partial update: replaces the refreshed activity window.
  ///
  /// Workout records do not have a stable persisted id from the plugin, so
  /// appending partial sync results would duplicate the same session on every
  /// refresh. Preserve activities outside the refreshed window and rewrite the
  /// merged, deduped collection.
  Future<void> saveActivitiesPartial(List<ActivityRecord> activities) async {
    if (activities.isEmpty) {
      AppLog.app.debug(
        '$_logName: saveActivitiesPartial() skipped — empty input',
      );
      return;
    }

    final isar = _isar!;
    final incoming = _dedupeActivities(activities);
    final rangeStart = incoming
        .map((r) => r.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final rangeEnd =
        incoming.map((r) => r.startTime).reduce((a, b) => a.isAfter(b) ? a : b);

    await isar.writeTxn(() async {
      final existingRows = await isar.hcActivityRecords.where().findAll();
      final preserved = [
        for (final row in existingRows)
          if (row.startTime.isBefore(rangeStart) ||
              row.startTime.isAfter(rangeEnd))
            _activityFromRow(row),
      ];
      final merged = _dedupeActivities([...preserved, ...incoming]);

      await isar.hcActivityRecords.clear();
      await isar.hcActivityRecords.putAll([
        for (final r in merged) _activityToRow(r),
      ]);
    });

    await _loadCache();

    AppLog.app.info(
      '$_logName: saveActivitiesPartial() done — '
      'activities=${incoming.length}',
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

  // ─── Sleep stage encoding ────────────────────────────────────────────────
  // Stage segments are persisted as one segment per line, fields separated by
  // '|'. Compact, append-only, and trivial to parse without pulling in JSON.
  static String _encodeSegments(List<SleepSegment> segments) {
    if (segments.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      if (i > 0) buf.write('\n');
      final s = segments[i];
      buf
        ..write(s.start.millisecondsSinceEpoch)
        ..write('|')
        ..write(s.end.millisecondsSinceEpoch)
        ..write('|')
        ..write(s.stage.index);
    }
    return buf.toString();
  }

  static List<SleepSegment> _decodeSegments(String encoded) {
    if (encoded.isEmpty) return const [];
    final lines = encoded.split('\n');
    final out = <SleepSegment>[];
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length != 3) continue;
      final startMs = int.tryParse(parts[0]);
      final endMs = int.tryParse(parts[1]);
      final stageIdx = int.tryParse(parts[2]);
      if (startMs == null || endMs == null || stageIdx == null) continue;
      if (stageIdx < 0 || stageIdx >= SleepStage.values.length) continue;
      out.add(SleepSegment(
        start: DateTime.fromMillisecondsSinceEpoch(startMs),
        end: DateTime.fromMillisecondsSinceEpoch(endMs),
        stage: SleepStage.values[stageIdx],
      ));
    }
    return out;
  }

  static SleepRecord _sleepFromRow(HcSleepRecord r) {
    return SleepRecord(
      sleepStart: r.sleepStart,
      wakeTime: r.wakeTime,
      totalDuration: Duration(seconds: r.totalDurationSeconds),
      deepDuration: Duration(seconds: r.deepDurationSeconds),
      lightDuration: Duration(seconds: r.lightDurationSeconds),
      remDuration: Duration(seconds: r.remDurationSeconds),
      awakeDuration: Duration(seconds: r.awakeDurationSeconds),
      segments: _decodeSegments(r.segmentsEncoded),
    );
  }

  HcSleepRecord _sleepToRow(SleepRecord r) {
    return HcSleepRecord()
      ..dateKey = _toKey(r.wakeTime)
      ..sleepStart = r.sleepStart
      ..wakeTime = r.wakeTime
      ..totalDurationSeconds = r.totalDuration.inSeconds
      ..deepDurationSeconds = r.deepDuration.inSeconds
      ..lightDurationSeconds = r.lightDuration.inSeconds
      ..remDurationSeconds = r.remDuration.inSeconds
      ..awakeDurationSeconds = r.awakeDuration.inSeconds
      ..segmentsEncoded = _encodeSegments(r.segments);
  }

  static ActivityRecord _activityFromRow(HcActivityRecord row) {
    return ActivityRecord(
      startTime: row.startTime,
      endTime: row.endTime,
      type: row.type,
      caloriesBurned: row.caloriesBurned,
      distanceKm: row.distanceKm,
    );
  }

  static HcActivityRecord _activityToRow(ActivityRecord activity) {
    return HcActivityRecord()
      ..startTime = activity.startTime
      ..endTime = activity.endTime
      ..type = activity.type
      ..caloriesBurned = activity.caloriesBurned
      ..distanceKm = activity.distanceKm;
  }

  static List<ActivityRecord> _dedupeActivities(
    Iterable<ActivityRecord> activities,
  ) {
    final byKey = <String, ActivityRecord>{};
    for (final activity in activities) {
      byKey[_activityKey(activity)] = activity;
    }

    return byKey.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  static String _activityKey(ActivityRecord activity) {
    return [
      _secondsSinceEpoch(activity.startTime),
      _secondsSinceEpoch(activity.endTime),
      activity.type.trim().toUpperCase(),
      activity.caloriesBurned ?? '',
      activity.distanceKm?.toStringAsFixed(3) ?? '',
    ].join('|');
  }

  static int _secondsSinceEpoch(DateTime value) {
    return value.toUtc().millisecondsSinceEpoch ~/ 1000;
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
