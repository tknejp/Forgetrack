import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/goal_board.dart';
import '../domain/player_goal.dart';

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
  static const _kDailySteps = 'goal_daily_steps';
  static const _kTargetWeight = 'goal_target_weight';
  static const _kDailyCalories = 'goal_daily_calories';
  static const _kDailyProtein = 'goal_daily_protein';
  static const _kDailyFat = 'goal_daily_fat';
  static const _kDailyCarbs = 'goal_daily_carbs';
  static const _kDailyFiber = 'goal_daily_fiber';
  static const _kSleepHours = 'goal_sleep_hours';
  static const _kWeeklyActivityMins = 'goal_weekly_activity_mins';
  static const _kDailyStepsHistory = 'goal_daily_steps_history';
  static const _kDailyCaloriesHistory = 'goal_daily_calories_history';
  static const _kDailyProteinHistory = 'goal_daily_protein_history';
  static const _kDailyFatHistory = 'goal_daily_fat_history';
  static const _kDailyCarbsHistory = 'goal_daily_carbs_history';
  static const _kDailyFiberHistory = 'goal_daily_fiber_history';
  static const _kSleepHoursHistory = 'goal_sleep_hours_history';
  static const _kWeeklyActivityMinsHistory = 'goal_weekly_activity_history';

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
  };

  GoalBoard _board = GoalBoard.empty;

  GoalBoard get board => _board;

  int get dailySteps => _board.goalFor(GoalMetric.dailySteps).target.round();
  double get targetWeight => _board.goalFor(GoalMetric.targetWeight).target;
  double get dailyCalories => _board.goalFor(GoalMetric.dailyCalories).target;
  double get dailyProtein => _board.goalFor(GoalMetric.dailyProtein).target;
  double get dailyFat => _board.goalFor(GoalMetric.dailyFat).target;
  double get dailyCarbs => _board.goalFor(GoalMetric.dailyCarbs).target;
  double get dailyFiber => _board.goalFor(GoalMetric.dailyFiber).target;
  double get sleepHours => _board.goalFor(GoalMetric.sleepHours).target;
  int get weeklyActivityMins =>
      _board.goalFor(GoalMetric.weeklyActivityMins).target.round();

  String get progressionHistorySignature => _board.progressionHistorySignature;

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

  int progressionDailyStepsForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailySteps).resolveForDate(day).round();

  double progressionDailyCaloriesForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailyCalories).resolveForDate(day);

  double progressionDailyProteinForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailyProtein).resolveForDate(day);

  double progressionDailyFatForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailyFat).resolveForDate(day);

  double progressionDailyCarbsForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailyCarbs).resolveForDate(day);

  double progressionDailyFiberForDate(DateTime day) =>
      _board.goalFor(GoalMetric.dailyFiber).resolveForDate(day);

  double progressionSleepHoursForDate(DateTime day) =>
      _board.goalFor(GoalMetric.sleepHours).resolveForDate(day);

  int progressionWeeklyActivityMinsForWeek(DateTime weekStart) => _board
      .goalFor(GoalMetric.weeklyActivityMins)
      .resolveForDate(weekStart)
      .round();

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
  }

  double _readScalar(SharedPreferences prefs, GoalMetric metric) {
    final key = _scalarKey[metric]!;
    final fallback = _defaults[metric]!;
    if (metric == GoalMetric.dailySteps ||
        metric == GoalMetric.weeklyActivityMins) {
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
