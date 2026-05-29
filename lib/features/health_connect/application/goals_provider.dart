import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_log.dart';
import '../data/goal_history_firestore_gateway.dart';
import '../domain/goal_board.dart';
import '../domain/player_goal.dart';
import 'nutrition_goals_gateway.dart';

/// Persistence façade + `ChangeNotifier` adapter over [GoalBoard].
///
/// Phase 14 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 14) extracted the goal value objects out of this file into
/// `lib/features/health_connect/domain/`. The provider keeps the same
/// public API every screen already consumes (`dailySteps`,
/// `setDailyCalories`, `progressionDailyStepsForDate`, …) so consumer
/// migration to the [board] aggregate can happen incrementally —
/// nothing in this phase is breaking for callers.
///
/// **Persistence shape (unchanged).** SharedPreferences keys
/// `goal_<metric>` (scalar target) + `goal_<metric>_history` (JSON
/// revisions) match the pre-extraction wire format byte-for-byte.
class GoalsProvider extends ChangeNotifier {
  GoalsProvider({
    GoalHistoryFirestoreGateway? gateway,
    NutritionGoalsGateway? nutritionGoals,
    bool Function()? useExternalNutritionGoals,
  })  : _gateway = gateway,
        _nutritionGoals = nutritionGoals,
        _useExternalNutritionGoals = useExternalNutritionGoals;

  final GoalHistoryFirestoreGateway? _gateway;

  /// External per-day nutrition goal source (Kalorické Tabulky, #98).
  /// When [_useExternalNutritionGoals] returns true and this gateway has
  /// usable data for the queried day, the five nutrition getters +
  /// `progression*ForDate` variants return its values; otherwise they fall
  /// back to the local goal board. Steps / activity / sleep / target
  /// weight are always local.
  final NutritionGoalsGateway? _nutritionGoals;
  final bool Function()? _useExternalNutritionGoals;

  String? _cloudUid;

  static const _kDailySteps = 'goal_daily_steps';
  static const _kTargetWeight = 'goal_target_weight';
  static const _kDailyCalories = 'goal_daily_calories';
  static const _kDailyProtein = 'goal_daily_protein';
  static const _kDailyFat = 'goal_daily_fat';
  static const _kDailyCarbs = 'goal_daily_carbs';
  static const _kDailyFiber = 'goal_daily_fiber';
  static const _kSleepHours = 'goal_sleep_hours';
  static const _kWeeklyActivityMins = 'goal_weekly_activity_mins';
  static const _kDailyActivityMins = 'goal_daily_activity_mins';
  static const _kDailyStepsHistory = 'goal_daily_steps_history';
  static const _kDailyCaloriesHistory = 'goal_daily_calories_history';
  static const _kDailyProteinHistory = 'goal_daily_protein_history';
  static const _kDailyFatHistory = 'goal_daily_fat_history';
  static const _kDailyCarbsHistory = 'goal_daily_carbs_history';
  static const _kDailyFiberHistory = 'goal_daily_fiber_history';
  static const _kSleepHoursHistory = 'goal_sleep_hours_history';
  static const _kWeeklyActivityMinsHistory = 'goal_weekly_activity_history';
  static const _kDailyActivityMinsHistory = 'goal_daily_activity_mins_history';

  static const Map<GoalMetric, String> _scalarKey = {
    GoalMetric.dailySteps: _kDailySteps,
    GoalMetric.targetWeight: _kTargetWeight,
    GoalMetric.dailyCalories: _kDailyCalories,
    GoalMetric.dailyProtein: _kDailyProtein,
    GoalMetric.dailyFat: _kDailyFat,
    GoalMetric.dailyCarbs: _kDailyCarbs,
    GoalMetric.dailyFiber: _kDailyFiber,
    GoalMetric.sleepHours: _kSleepHours,
    GoalMetric.weeklyActivityMins: _kWeeklyActivityMins,
    GoalMetric.dailyActivityMins: _kDailyActivityMins,
  };

  static const Map<GoalMetric, String> _historyKey = {
    GoalMetric.dailySteps: _kDailyStepsHistory,
    GoalMetric.dailyCalories: _kDailyCaloriesHistory,
    GoalMetric.dailyProtein: _kDailyProteinHistory,
    GoalMetric.dailyFat: _kDailyFatHistory,
    GoalMetric.dailyCarbs: _kDailyCarbsHistory,
    GoalMetric.dailyFiber: _kDailyFiberHistory,
    GoalMetric.sleepHours: _kSleepHoursHistory,
    GoalMetric.weeklyActivityMins: _kWeeklyActivityMinsHistory,
    GoalMetric.dailyActivityMins: _kDailyActivityMinsHistory,
  };

  static const Map<GoalMetric, double> _defaults = {
    GoalMetric.dailySteps: 10000,
    GoalMetric.targetWeight: 75.0,
    GoalMetric.dailyCalories: 2000,
    GoalMetric.dailyProtein: 150,
    GoalMetric.dailyFat: 65,
    GoalMetric.dailyCarbs: 250,
    GoalMetric.dailyFiber: 30,
    GoalMetric.sleepHours: 8.0,
    GoalMetric.weeklyActivityMins: 150,
    GoalMetric.dailyActivityMins: 30,
  };

  GoalBoard _board = GoalBoard.empty;

  GoalBoard get board => _board;

  int get dailySteps => _board.goalFor(GoalMetric.dailySteps).target.round();
  double get targetWeight => _board.goalFor(GoalMetric.targetWeight).target;
  double get dailyCalories => _nutritionGoal(
        _todayDate,
        () => _board.goalFor(GoalMetric.dailyCalories).target,
        (v) => v.calories,
      );
  double get dailyProtein => _nutritionGoal(
        _todayDate,
        () => _board.goalFor(GoalMetric.dailyProtein).target,
        (v) => v.protein,
      );
  double get dailyFat => _nutritionGoal(
        _todayDate,
        () => _board.goalFor(GoalMetric.dailyFat).target,
        (v) => v.fat,
      );
  double get dailyCarbs => _nutritionGoal(
        _todayDate,
        () => _board.goalFor(GoalMetric.dailyCarbs).target,
        (v) => v.carbs,
      );
  double get dailyFiber => _nutritionGoal(
        _todayDate,
        () => _board.goalFor(GoalMetric.dailyFiber).target,
        (v) => v.fiber,
      );
  double get sleepHours => _board.goalFor(GoalMetric.sleepHours).target;
  int get weeklyActivityMins =>
      _board.goalFor(GoalMetric.weeklyActivityMins).target.round();
  int get dailyActivityMins =>
      _board.goalFor(GoalMetric.dailyActivityMins).target.round();

  String get progressionHistorySignature => _board.progressionHistorySignature;

  DateTime get _todayDate => progressionDate(DateTime.now());

  /// Re-emits a change notification when an external input feeding the
  /// nutrition getters changes — the #98 source flag flipping, or the KT
  /// gateway re-syncing while the KT source is active. Wired from
  /// `main.dart`; a no-op for consumers while the source stays local.
  void refreshExternalNutritionGoals() => notifyListeners();

  /// #98 dispatch for the five nutrition metrics. Returns the external
  /// (KT) goal for [day] when the source is external AND the gateway is
  /// available AND has usable data for that day; otherwise [local].
  /// [pick] selects the metric off the external view.
  double _nutritionGoal(
    DateTime day,
    double Function() local,
    double Function(NutritionGoalsView) pick,
  ) {
    if (_useExternalNutritionGoals?.call() ?? false) {
      final gateway = _nutritionGoals;
      if (gateway != null && gateway.isAvailable) {
        final view = gateway.goalsForDate(day);
        if (view != null && view.hasData) return pick(view);
      }
    }
    return local();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final goals = <GoalMetric, PlayerGoal>{};
    for (final metric in GoalMetric.values) {
      final target = _readScalar(prefs, metric);
      final history = _historyKey.containsKey(metric)
          ? _loadHistory(
              prefs: prefs,
              key: _historyKey[metric]!,
              fallbackValue: target,
            )
          : const <GoalRevision>[];
      goals[metric] = PlayerGoal(
        metric: metric,
        target: target,
        history: history,
      );
    }
    _board = GoalBoard(goals: goals);

    final today = progressionDate(DateTime.now());
    final currentWeekStart = startOfProgressionWeek(today);
    var historyChanged = false;

    for (final metric in _historyKey.keys) {
      final anchor = metric == GoalMetric.weeklyActivityMins
          ? currentWeekStart
          : today;
      final original = _board.goalFor(metric);
      final migrated = original.ensureRevisionAt(
        anchor: anchor,
        currentValue: original.target,
      );
      if (!identical(migrated, original)) {
        _board = _board.withGoal(migrated);
        historyChanged = true;
        await _saveHistory(
          prefs: prefs,
          key: _historyKey[metric]!,
          entries: migrated.history,
        );
      }
    }

    if (historyChanged) {
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<void> setDailySteps(int v) =>
      _setIntGoal(GoalMetric.dailySteps, v, anchor: progressionDate);

  Future<void> setTargetWeight(double v) async {
    _board = _board.withGoal(PlayerGoal(metric: GoalMetric.targetWeight, target: v));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTargetWeight, v);
  }

  Future<void> setDailyCalories(double v) =>
      _setDoubleGoal(GoalMetric.dailyCalories, v, anchor: progressionDate);

  Future<void> setDailyProtein(double v) =>
      _setDoubleGoal(GoalMetric.dailyProtein, v, anchor: progressionDate);

  Future<void> setDailyFat(double v) =>
      _setDoubleGoal(GoalMetric.dailyFat, v, anchor: progressionDate);

  Future<void> setDailyCarbs(double v) =>
      _setDoubleGoal(GoalMetric.dailyCarbs, v, anchor: progressionDate);

  Future<void> setDailyFiber(double v) =>
      _setDoubleGoal(GoalMetric.dailyFiber, v, anchor: progressionDate);

  Future<void> setSleepHours(double v) =>
      _setDoubleGoal(GoalMetric.sleepHours, v, anchor: progressionDate);

  Future<void> setWeeklyActivityMins(int v) => _setIntGoal(
        GoalMetric.weeklyActivityMins,
        v,
        anchor: startOfProgressionWeek,
      );

  Future<void> setDailyActivityMins(int v) async {
    await _setIntGoal(
      GoalMetric.dailyActivityMins,
      v,
      anchor: progressionDate,
    );
    AppLog.app.info('goals: setDailyActivityMins $v');
  }

  int progressionDailyStepsForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailySteps).resolveForDate(day).round();

  double progressionDailyCaloriesForDate(DateTime day) => _nutritionGoal(
        day,
        () => _board.goalFor(GoalMetric.dailyCalories).resolveForDate(day),
        (v) => v.calories,
      );

  double progressionDailyProteinForDate(DateTime day) => _nutritionGoal(
        day,
        () => _board.goalFor(GoalMetric.dailyProtein).resolveForDate(day),
        (v) => v.protein,
      );

  double progressionDailyFatForDate(DateTime day) => _nutritionGoal(
        day,
        () => _board.goalFor(GoalMetric.dailyFat).resolveForDate(day),
        (v) => v.fat,
      );

  double progressionDailyCarbsForDate(DateTime day) => _nutritionGoal(
        day,
        () => _board.goalFor(GoalMetric.dailyCarbs).resolveForDate(day),
        (v) => v.carbs,
      );

  double progressionDailyFiberForDate(DateTime day) => _nutritionGoal(
        day,
        () => _board.goalFor(GoalMetric.dailyFiber).resolveForDate(day),
        (v) => v.fiber,
      );

  double progressionSleepHoursForDate(DateTime day) =>
      _board.goalFor(GoalMetric.sleepHours).resolveForDate(day);

  int progressionWeeklyActivityMinsForWeek(DateTime weekStart) => _board
      .goalFor(GoalMetric.weeklyActivityMins)
      .resolveForDate(weekStart)
      .round();

  int progressionDailyActivityMinsForDate(DateTime day) => _board
      .goalFor(GoalMetric.dailyActivityMins)
      .resolveForDate(day)
      .round();

  /// Binds the Firestore gateway to [uid]. Call this on sign-in before
  /// [pullAndMergeCloudHistory]. Clears the uid on sign-out (null).
  void bindCloudUser(String? uid) {
    _cloudUid = uid?.isEmpty == true ? null : uid;
  }

  /// Pulls cloud goal histories for [uid], merges with local histories
  /// (cloud wins on same-day conflict), persists merged histories to
  /// prefs, and notifies listeners. On first sign-in also seeds any
  /// local-only history up to Firestore (first-time migration).
  ///
  /// No-op when [_gateway] is null (tests / no Firestore).
  Future<void> pullAndMergeCloudHistory(String uid) async {
    final gateway = _gateway;
    if (gateway == null || uid.isEmpty) return;

    final cloudAll = await gateway.pullRevisions(uid);

    // First-time migration: seed local-only metrics that cloud doesn't know.
    final toSeed = <GoalMetric, List<GoalRevision>>{};
    for (final metric in GoalHistoryFirestoreGateway.syncedMetrics) {
      if (!cloudAll.containsKey(metric)) {
        final local = _board.goalFor(metric).history;
        if (local.isNotEmpty) toSeed[metric] = local;
      }
    }
    if (toSeed.isNotEmpty) {
      await gateway.seedAllRevisions(uid, toSeed);
    }

    if (cloudAll.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    var changed = false;
    for (final entry in cloudAll.entries) {
      final metric = entry.key;
      final cloudRevisions = entry.value;
      final localGoal = _board.goalFor(metric);
      final merged = GoalHistoryFirestoreGateway.merge(
        localGoal.history,
        cloudRevisions,
      );
      if (merged.length == localGoal.history.length &&
          _revisionsEqual(merged, localGoal.history)) {
        continue;
      }
      final updatedGoal = localGoal.copyWith(
        history: merged,
        target: merged.last.value,
      );
      _board = _board.withGoal(updatedGoal);
      await _saveHistory(
        prefs: prefs,
        key: _historyKey[metric]!,
        entries: merged,
      );
      await prefs.setDouble(_scalarKey[metric]!, merged.last.value);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> _setDoubleGoal(
    GoalMetric metric,
    double value, {
    required DateTime Function(DateTime) anchor,
  }) async {
    final updated = _board.goalFor(metric).withRevision(
          effectiveFrom: anchor(DateTime.now()),
          value: value,
        );
    _board = _board.withGoal(updated);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scalarKey[metric]!, value);
    await _saveHistory(
      prefs: prefs,
      key: _historyKey[metric]!,
      entries: updated.history,
    );
    final uid = _cloudUid;
    if (uid != null) {
      await _gateway?.pushRevisions(uid, metric, updated.history);
    }
  }

  Future<void> _setIntGoal(
    GoalMetric metric,
    int value, {
    required DateTime Function(DateTime) anchor,
  }) async {
    final updated = _board.goalFor(metric).withRevision(
          effectiveFrom: anchor(DateTime.now()),
          value: value.toDouble(),
        );
    _board = _board.withGoal(updated);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scalarKey[metric]!, value);
    await _saveHistory(
      prefs: prefs,
      key: _historyKey[metric]!,
      entries: updated.history,
    );
    final uid = _cloudUid;
    if (uid != null) {
      await _gateway?.pushRevisions(uid, metric, updated.history);
    }
  }

  static bool _revisionsEqual(
    List<GoalRevision> a,
    List<GoalRevision> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  double _readScalar(SharedPreferences prefs, GoalMetric metric) {
    final key = _scalarKey[metric]!;
    final fallback = _defaults[metric]!;
    if (metric == GoalMetric.dailySteps ||
        metric == GoalMetric.weeklyActivityMins ||
        metric == GoalMetric.dailyActivityMins) {
      return (prefs.getInt(key) ?? fallback.toInt()).toDouble();
    }
    return prefs.getDouble(key) ?? fallback;
  }

  List<GoalRevision> _loadHistory({
    required SharedPreferences prefs,
    required String key,
    required double fallbackValue,
  }) {
    final raw = prefs.getString(key);
    final fallback = [
      GoalRevision(
        effectiveFrom: DateTime(1970, 1, 1),
        value: fallbackValue,
      ),
    ];
    if (raw == null || raw.isEmpty) return fallback;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return fallback;

    final entries = decoded
        .whereType<Map>()
        .map(
          (entry) => GoalRevision.fromJson(
            entry.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList()
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

    if (entries.isEmpty) return fallback;
    return entries;
  }

  Future<void> _saveHistory({
    required SharedPreferences prefs,
    required String key,
    required List<GoalRevision> entries,
  }) {
    return prefs.setString(
      key,
      jsonEncode([for (final entry in entries) entry.toJson()]),
    );
  }

  DateTime progressionDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime startOfProgressionWeek(DateTime value) {
    final normalized = progressionDate(value);
    return normalized
        .subtract(Duration(days: normalized.weekday - DateTime.monday));
  }
}
