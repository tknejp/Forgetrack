import '../../models/activity_record.dart';
import '../../models/sleep_record.dart';
import '../../models/weight_card_data.dart';
import '../../models/weight_record.dart';

/// Pure read-only query and aggregation helpers for [FitnessProvider].
///
/// All methods are static and operate on the caller-supplied data slices.
/// No state is held here — the provider owns all data and passes it in.
class FitnessQueries {
  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  // ─── Predicates ───────────────────────────────────────────────────────────

  static bool sameDay(DateTime a, DateTime b) =>
      _dateOnly(a) == _dateOnly(b);

  static bool inRange(DateTime d, DateTime start, DateTime end) {
    final date = _dateOnly(d);
    final startDate = _dateOnly(start);
    final endDate = _dateOnly(end);
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  // ─── Steps ────────────────────────────────────────────────────────────────

  static int stepsForDate(List<StepsRecord> history, DateTime date) =>
      history.where((r) => sameDay(r.date, date)).firstOrNull?.steps ?? 0;

  static int stepsAvgForRange(
    List<StepsRecord> history,
    DateTime start,
    DateTime end,
  ) {
    final records =
        history.where((r) => inRange(r.date, start, end)).toList();
    if (records.isEmpty) return 0;
    return (records.fold(0, (s, r) => s + r.steps) / records.length).round();
  }

  static List<StepsRecord> stepsHistoryForRange(
    List<StepsRecord> history,
    DateTime start,
    DateTime end,
  ) =>
      history.where((r) => inRange(r.date, start, end)).toList();

  // ─── Calories ─────────────────────────────────────────────────────────────

  static double activeCaloriesBurnedForDate(
    List<StepsRecord> stepsHistory,
    List<double> calories,
    DateTime date,
  ) {
    final idx = stepsHistory.indexWhere((r) => sameDay(r.date, date));
    if (idx < 0 || idx >= calories.length) return 0;
    return calories[idx];
  }

  static double activeCaloriesBurnedAvgForRange(
    List<StepsRecord> stepsHistory,
    List<double> calories,
    DateTime start,
    DateTime end,
  ) {
    final indices = <int>[];
    for (var i = 0; i < stepsHistory.length; i++) {
      if (inRange(stepsHistory[i].date, start, end)) indices.add(i);
    }
    if (indices.isEmpty) return 0;
    var total = 0.0;
    for (final idx in indices) {
      if (idx < calories.length) total += calories[idx];
    }
    return total / indices.length;
  }

  // ─── Weight ───────────────────────────────────────────────────────────────

  static List<WeightRecord> weightHistoryForRange(
    List<WeightRecord> history,
    DateTime start,
    DateTime end,
  ) =>
      history.where((r) => inRange(r.date, start, end)).toList();

  static WeightRecord? weightForDate(List<WeightRecord> history, DateTime date) =>
      history.where((r) => sameDay(r.date, date)).lastOrNull;

  static ({double? lastKnown, double? trend}) weightMetricsForRange(
    List<WeightRecord> history,
    double? latestWeight,
    DateTime start,
    DateTime end,
  ) {
    final records = weightHistoryForRange(history, start, end);
    if (records.isEmpty) return (lastKnown: latestWeight, trend: null);
    final lastKnown = records.last.weight;
    final trend =
        records.length >= 2 ? records.last.weight - records.first.weight : null;
    return (lastKnown: lastKnown, trend: trend);
  }

  static double? previousWeightBefore(
      List<WeightRecord> history, DateTime date) {
    final day = _dateOnly(date);
    final before = history
        .where((r) => _dateOnly(r.date).isBefore(day))
        .toList();
    return before.isNotEmpty ? before.last.weight : null;
  }

  static double? weekAvgWeight(List<WeightRecord> history, DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final records = weightHistoryForRange(history, weekStart, end);
    if (records.isEmpty) return null;
    return records.map((r) => r.weight).reduce((a, b) => a + b) /
        records.length;
  }

  static double? monthAvgWeight(
      List<WeightRecord> history, DateTime monthRef) {
    final start = DateTime(monthRef.year, monthRef.month, 1);
    final end = DateTime(monthRef.year, monthRef.month + 1, 0);
    final records = weightHistoryForRange(history, start, end);
    if (records.isEmpty) return null;
    return records.map((r) => r.weight).reduce((a, b) => a + b) /
        records.length;
  }

  static List<WeightChartPoint> dailyWeightChart(
      List<WeightRecord> history, int maxPoints) {
    final src = history.length > maxPoints
        ? history.sublist(history.length - maxPoints)
        : history;
    return src
        .map((r) => WeightChartPoint(date: r.date, weight: r.weight))
        .toList();
  }

  static List<WeightChartPoint> weightChartForRange(
    List<WeightRecord> history,
    DateTime start,
    DateTime end,
  ) {
    final records = weightHistoryForRange(history, start, end);
    if (records.isEmpty) return const [];
    final latestPerDay = <DateTime, WeightRecord>{};
    for (final r in records) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      latestPerDay[day] = r;
    }
    final days = latestPerDay.keys.toList()..sort();
    return [
      for (final day in days)
        WeightChartPoint(date: day, weight: latestPerDay[day]!.weight),
    ];
  }

  static List<WeightChartPoint> weeklyWeightChart(
      List<WeightRecord> history, int weeks) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final currentWeekStart =
        todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    final result = <WeightChartPoint>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final ws = currentWeekStart.subtract(Duration(days: 7 * i));
      final avg = weekAvgWeight(history, ws);
      if (avg != null) result.add(WeightChartPoint(date: ws, weight: avg));
    }
    return result;
  }

  static List<WeightChartPoint> monthlyWeightChart(
      List<WeightRecord> history, int months) {
    final today = DateTime.now();
    final result = <WeightChartPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final ref = DateTime(today.year, today.month - i, 1);
      final avg = monthAvgWeight(history, ref);
      if (avg != null) result.add(WeightChartPoint(date: ref, weight: avg));
    }
    return result;
  }

  // ─── Sleep ────────────────────────────────────────────────────────────────

  static SleepRecord? sleepForDate(List<SleepRecord> history, DateTime date) =>
      history.where((r) => sameDay(r.wakeTime, date)).firstOrNull;

  static Duration? avgSleepForRange(
    List<SleepRecord> history,
    DateTime start,
    DateTime end,
  ) {
    final records =
        history.where((r) => inRange(r.wakeTime, start, end)).toList();
    if (records.isEmpty) return null;
    final totalSec =
        records.fold(0, (s, r) => s + r.totalDuration.inSeconds);
    return Duration(seconds: (totalSec / records.length).round());
  }
}
