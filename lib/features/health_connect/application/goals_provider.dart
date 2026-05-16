import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  int _dailySteps = 10000;
  double _targetWeight = 75.0;
  double _dailyCalories = 2000;
  double _dailyProtein = 150;
  double _dailyFat = 65;
  double _dailyCarbs = 250;
  double _dailyFiber = 30;
  double _sleepHours = 8.0;
  int _weeklyActivityMins = 150;
  List<_GoalHistoryEntry> _dailyStepsHistory = const [];
  List<_GoalHistoryEntry> _dailyCaloriesHistory = const [];
  List<_GoalHistoryEntry> _dailyProteinHistory = const [];
  List<_GoalHistoryEntry> _dailyFatHistory = const [];
  List<_GoalHistoryEntry> _dailyCarbsHistory = const [];
  List<_GoalHistoryEntry> _dailyFiberHistory = const [];
  List<_GoalHistoryEntry> _sleepHoursHistory = const [];
  List<_GoalHistoryEntry> _weeklyActivityMinsHistory = const [];

  int get dailySteps => _dailySteps;
  double get targetWeight => _targetWeight;
  double get dailyCalories => _dailyCalories;
  double get dailyProtein => _dailyProtein;
  double get dailyFat => _dailyFat;
  double get dailyCarbs => _dailyCarbs;
  double get dailyFiber => _dailyFiber;
  double get sleepHours => _sleepHours;
  int get weeklyActivityMins => _weeklyActivityMins;
  String get progressionHistorySignature => [
        _historySignature(_dailyStepsHistory),
        _historySignature(_dailyCaloriesHistory),
        _historySignature(_dailyProteinHistory),
        _historySignature(_dailyFatHistory),
        _historySignature(_dailyCarbsHistory),
        _historySignature(_dailyFiberHistory),
        _historySignature(_sleepHoursHistory),
        _historySignature(_weeklyActivityMinsHistory),
      ].join('|');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailySteps = prefs.getInt(_kDailySteps) ?? 10000;
    _targetWeight = prefs.getDouble(_kTargetWeight) ?? 75.0;
    _dailyCalories = prefs.getDouble(_kDailyCalories) ?? 2000;
    _dailyProtein = prefs.getDouble(_kDailyProtein) ?? 150;
    _dailyFat = prefs.getDouble(_kDailyFat) ?? 65;
    _dailyCarbs = prefs.getDouble(_kDailyCarbs) ?? 250;
    _dailyFiber = prefs.getDouble(_kDailyFiber) ?? 30;
    _sleepHours = prefs.getDouble(_kSleepHours) ?? 8.0;
    _weeklyActivityMins = prefs.getInt(_kWeeklyActivityMins) ?? 150;
    _dailyStepsHistory = _loadHistory(
      prefs: prefs,
      key: _kDailyStepsHistory,
      fallbackValue: _dailySteps.toDouble(),
    );
    _dailyCaloriesHistory = _loadHistory(
      prefs: prefs,
      key: _kDailyCaloriesHistory,
      fallbackValue: _dailyCalories,
    );
    _dailyProteinHistory = _loadHistory(
      prefs: prefs,
      key: _kDailyProteinHistory,
      fallbackValue: _dailyProtein,
    );
    _dailyFatHistory = _loadHistory(
      prefs: prefs,
      key: _kDailyFatHistory,
      fallbackValue: _dailyFat,
    );
    _dailyCarbsHistory = _loadHistory(
      prefs: prefs,
      key: _kDailyCarbsHistory,
      fallbackValue: _dailyCarbs,
    );
    _dailyFiberHistory = _loadHistory(
      prefs: prefs,
      key: _kDailyFiberHistory,
      fallbackValue: _dailyFiber,
    );
    _sleepHoursHistory = _loadHistory(
      prefs: prefs,
      key: _kSleepHoursHistory,
      fallbackValue: _sleepHours,
    );
    _weeklyActivityMinsHistory = _loadHistory(
      prefs: prefs,
      key: _kWeeklyActivityMinsHistory,
      fallbackValue: _weeklyActivityMins.toDouble(),
    );
    final today = progressionDate(DateTime.now());
    final currentWeekStart = startOfProgressionWeek(today);
    var historyChanged = false;

    final migratedDailyStepsHistory = _ensureRevisionForAnchor(
      entries: _dailyStepsHistory,
      anchor: today,
      currentValue: _dailySteps.toDouble(),
    );
    if (!_sameHistory(_dailyStepsHistory, migratedDailyStepsHistory)) {
      _dailyStepsHistory = migratedDailyStepsHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kDailyStepsHistory,
        entries: _dailyStepsHistory,
      );
    }

    final migratedDailyCaloriesHistory = _ensureRevisionForAnchor(
      entries: _dailyCaloriesHistory,
      anchor: today,
      currentValue: _dailyCalories,
    );
    if (!_sameHistory(_dailyCaloriesHistory, migratedDailyCaloriesHistory)) {
      _dailyCaloriesHistory = migratedDailyCaloriesHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kDailyCaloriesHistory,
        entries: _dailyCaloriesHistory,
      );
    }

    final migratedDailyProteinHistory = _ensureRevisionForAnchor(
      entries: _dailyProteinHistory,
      anchor: today,
      currentValue: _dailyProtein,
    );
    if (!_sameHistory(_dailyProteinHistory, migratedDailyProteinHistory)) {
      _dailyProteinHistory = migratedDailyProteinHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kDailyProteinHistory,
        entries: _dailyProteinHistory,
      );
    }

    final migratedDailyFatHistory = _ensureRevisionForAnchor(
      entries: _dailyFatHistory,
      anchor: today,
      currentValue: _dailyFat,
    );
    if (!_sameHistory(_dailyFatHistory, migratedDailyFatHistory)) {
      _dailyFatHistory = migratedDailyFatHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kDailyFatHistory,
        entries: _dailyFatHistory,
      );
    }

    final migratedDailyCarbsHistory = _ensureRevisionForAnchor(
      entries: _dailyCarbsHistory,
      anchor: today,
      currentValue: _dailyCarbs,
    );
    if (!_sameHistory(_dailyCarbsHistory, migratedDailyCarbsHistory)) {
      _dailyCarbsHistory = migratedDailyCarbsHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kDailyCarbsHistory,
        entries: _dailyCarbsHistory,
      );
    }

    final migratedDailyFiberHistory = _ensureRevisionForAnchor(
      entries: _dailyFiberHistory,
      anchor: today,
      currentValue: _dailyFiber,
    );
    if (!_sameHistory(_dailyFiberHistory, migratedDailyFiberHistory)) {
      _dailyFiberHistory = migratedDailyFiberHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kDailyFiberHistory,
        entries: _dailyFiberHistory,
      );
    }

    final migratedSleepHoursHistory = _ensureRevisionForAnchor(
      entries: _sleepHoursHistory,
      anchor: today,
      currentValue: _sleepHours,
    );
    if (!_sameHistory(_sleepHoursHistory, migratedSleepHoursHistory)) {
      _sleepHoursHistory = migratedSleepHoursHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kSleepHoursHistory,
        entries: _sleepHoursHistory,
      );
    }

    final migratedWeeklyActivityHistory = _ensureRevisionForAnchor(
      entries: _weeklyActivityMinsHistory,
      anchor: currentWeekStart,
      currentValue: _weeklyActivityMins.toDouble(),
    );
    if (!_sameHistory(
      _weeklyActivityMinsHistory,
      migratedWeeklyActivityHistory,
    )) {
      _weeklyActivityMinsHistory = migratedWeeklyActivityHistory;
      historyChanged = true;
      await _saveHistory(
        prefs: prefs,
        key: _kWeeklyActivityMinsHistory,
        entries: _weeklyActivityMinsHistory,
      );
    }

    if (historyChanged) {
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<void> setDailySteps(int v) async {
    _dailySteps = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailySteps, v);
    _dailyStepsHistory = _withRevision(
      entries: _dailyStepsHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v.toDouble(),
    );
    await _saveHistory(
      prefs: prefs,
      key: _kDailyStepsHistory,
      entries: _dailyStepsHistory,
    );
  }

  Future<void> setTargetWeight(double v) async {
    _targetWeight = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTargetWeight, v);
  }

  Future<void> setDailyCalories(double v) async {
    _dailyCalories = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyCalories, v);
    _dailyCaloriesHistory = _withRevision(
      entries: _dailyCaloriesHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v,
    );
    await _saveHistory(
      prefs: prefs,
      key: _kDailyCaloriesHistory,
      entries: _dailyCaloriesHistory,
    );
  }

  Future<void> setDailyProtein(double v) async {
    _dailyProtein = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyProtein, v);
    _dailyProteinHistory = _withRevision(
      entries: _dailyProteinHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v,
    );
    await _saveHistory(
      prefs: prefs,
      key: _kDailyProteinHistory,
      entries: _dailyProteinHistory,
    );
  }

  Future<void> setDailyFat(double v) async {
    _dailyFat = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyFat, v);
    _dailyFatHistory = _withRevision(
      entries: _dailyFatHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v,
    );
    await _saveHistory(
      prefs: prefs,
      key: _kDailyFatHistory,
      entries: _dailyFatHistory,
    );
  }

  Future<void> setDailyCarbs(double v) async {
    _dailyCarbs = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyCarbs, v);
    _dailyCarbsHistory = _withRevision(
      entries: _dailyCarbsHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v,
    );
    await _saveHistory(
      prefs: prefs,
      key: _kDailyCarbsHistory,
      entries: _dailyCarbsHistory,
    );
  }

  Future<void> setDailyFiber(double v) async {
    _dailyFiber = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyFiber, v);
    _dailyFiberHistory = _withRevision(
      entries: _dailyFiberHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v,
    );
    await _saveHistory(
      prefs: prefs,
      key: _kDailyFiberHistory,
      entries: _dailyFiberHistory,
    );
  }

  Future<void> setSleepHours(double v) async {
    _sleepHours = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSleepHours, v);
    _sleepHoursHistory = _withRevision(
      entries: _sleepHoursHistory,
      effectiveFrom: progressionDate(DateTime.now()),
      value: v,
    );
    await _saveHistory(
      prefs: prefs,
      key: _kSleepHoursHistory,
      entries: _sleepHoursHistory,
    );
  }

  Future<void> setWeeklyActivityMins(int v) async {
    _weeklyActivityMins = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklyActivityMins, v);
    _weeklyActivityMinsHistory = _withRevision(
      entries: _weeklyActivityMinsHistory,
      effectiveFrom: startOfProgressionWeek(DateTime.now()),
      value: v.toDouble(),
    );
    await _saveHistory(
      prefs: prefs,
      key: _kWeeklyActivityMinsHistory,
      entries: _weeklyActivityMinsHistory,
    );
  }

  int progressionDailyStepsForDate(DateTime day) =>
      _resolveValue(_dailyStepsHistory, progressionDate(day)).round();

  double progressionDailyCaloriesForDate(DateTime day) =>
      _resolveValue(_dailyCaloriesHistory, progressionDate(day));

  double progressionDailyProteinForDate(DateTime day) =>
      _resolveValue(_dailyProteinHistory, progressionDate(day));

  double progressionDailyFatForDate(DateTime day) =>
      _resolveValue(_dailyFatHistory, progressionDate(day));

  double progressionDailyCarbsForDate(DateTime day) =>
      _resolveValue(_dailyCarbsHistory, progressionDate(day));

  double progressionDailyFiberForDate(DateTime day) =>
      _resolveValue(_dailyFiberHistory, progressionDate(day));

  double progressionSleepHoursForDate(DateTime day) =>
      _resolveValue(_sleepHoursHistory, progressionDate(day));

  int progressionWeeklyActivityMinsForWeek(DateTime weekStart) => _resolveValue(
        _weeklyActivityMinsHistory,
        startOfProgressionWeek(weekStart),
      ).round();

  List<_GoalHistoryEntry> _loadHistory({
    required SharedPreferences prefs,
    required String key,
    required double fallbackValue,
  }) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return [
        _GoalHistoryEntry(
          effectiveFrom: DateTime(1970, 1, 1),
          value: fallbackValue,
        ),
      ];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [
        _GoalHistoryEntry(
          effectiveFrom: DateTime(1970, 1, 1),
          value: fallbackValue,
        ),
      ];
    }

    final entries = decoded
        .whereType<Map>()
        .map(
          (entry) => _GoalHistoryEntry.fromJson(
            entry.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList()
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

    if (entries.isEmpty) {
      return [
        _GoalHistoryEntry(
          effectiveFrom: DateTime(1970, 1, 1),
          value: fallbackValue,
        ),
      ];
    }

    return entries;
  }

  Future<void> _saveHistory({
    required SharedPreferences prefs,
    required String key,
    required List<_GoalHistoryEntry> entries,
  }) {
    return prefs.setString(
      key,
      jsonEncode([
        for (final entry in entries) entry.toJson(),
      ]),
    );
  }

  List<_GoalHistoryEntry> _withRevision({
    required List<_GoalHistoryEntry> entries,
    required DateTime effectiveFrom,
    required double value,
  }) {
    final normalized = progressionDate(effectiveFrom);
    final nextEntries = entries
        .where((entry) => progressionDate(entry.effectiveFrom) != normalized)
        .toList()
      ..add(_GoalHistoryEntry(effectiveFrom: normalized, value: value))
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    return nextEntries;
  }

  List<_GoalHistoryEntry> _ensureRevisionForAnchor({
    required List<_GoalHistoryEntry> entries,
    required DateTime anchor,
    required double currentValue,
  }) {
    final normalizedAnchor = progressionDate(anchor);
    final resolved = _resolveValue(entries, normalizedAnchor);
    if (resolved == currentValue) {
      return entries;
    }

    return _withRevision(
      entries: entries,
      effectiveFrom: normalizedAnchor,
      value: currentValue,
    );
  }

  bool _sameHistory(
    List<_GoalHistoryEntry> left,
    List<_GoalHistoryEntry> right,
  ) {
    if (left.length != right.length) return false;

    for (var index = 0; index < left.length; index++) {
      if (progressionDate(left[index].effectiveFrom) !=
          progressionDate(right[index].effectiveFrom)) {
        return false;
      }
      if (left[index].value != right[index].value) {
        return false;
      }
    }

    return true;
  }

  double _resolveValue(List<_GoalHistoryEntry> entries, DateTime effectiveDay) {
    final normalizedDay = progressionDate(effectiveDay);
    _GoalHistoryEntry? match;

    for (final entry in entries) {
      final entryDay = progressionDate(entry.effectiveFrom);
      if (entryDay.isAfter(normalizedDay)) {
        break;
      }
      match = entry;
    }

    return match?.value ?? entries.first.value;
  }

  String _historySignature(List<_GoalHistoryEntry> entries) {
    return entries
        .map(
          (entry) =>
              '${progressionDate(entry.effectiveFrom).toIso8601String()}:${entry.value}',
        )
        .join(',');
  }

  DateTime progressionDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime startOfProgressionWeek(DateTime value) {
    final normalized = progressionDate(value);
    return normalized
        .subtract(Duration(days: normalized.weekday - DateTime.monday));
  }
}

class _GoalHistoryEntry {
  const _GoalHistoryEntry({
    required this.effectiveFrom,
    required this.value,
  });

  factory _GoalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return _GoalHistoryEntry(
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  final DateTime effectiveFrom;
  final double value;

  Map<String, dynamic> toJson() => {
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'value': value,
      };
}
