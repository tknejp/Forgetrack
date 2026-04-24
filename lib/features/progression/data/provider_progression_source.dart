import '../../health_connect/application/fitness_provider.dart';
import '../../../providers/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../nutrition/data/kaloricke_tabulky_service.dart';
import '../application/progression_source.dart';
import '../domain/progression_models.dart';

class ProviderProgressionSource implements ProgressionSource {
  ProviderProgressionSource({
    required GoalsProvider goalsProvider,
    required FitnessProvider fitnessProvider,
    required KalorickeTabulkyProvider nutritionProvider,
    DateTime Function()? clock,
  })  : _goalsProvider = goalsProvider,
        _fitnessProvider = fitnessProvider,
        _nutritionProvider = nutritionProvider,
        _clock = clock ?? DateTime.now;

  final GoalsProvider _goalsProvider;
  final FitnessProvider _fitnessProvider;
  final KalorickeTabulkyProvider _nutritionProvider;
  final DateTime Function() _clock;

  @override
  ProgressionGoalSet get currentGoals => ProgressionGoalSet(
        dailySteps: _goalsProvider.dailySteps,
        dailyCalories: _goalsProvider.dailyCalories,
        dailyProteinGrams: _goalsProvider.dailyProtein,
        sleepMinutes: (_goalsProvider.sleepHours * 60).round(),
        weeklyActivityMinutes: _goalsProvider.weeklyActivityMins,
        targetWeightKg: _goalsProvider.targetWeight,
      );

  @override
  ProgressionGoalSet goalsForPeriod(ProgressionPeriod period) {
    final anchor = progressionDate(period.start);
    return ProgressionGoalSet(
      dailySteps: _goalsProvider.progressionDailyStepsForDate(anchor),
      dailyCalories: _goalsProvider.progressionDailyCaloriesForDate(anchor),
      dailyProteinGrams: _goalsProvider.progressionDailyProteinForDate(anchor),
      sleepMinutes:
          (_goalsProvider.progressionSleepHoursForDate(anchor) * 60).round(),
      weeklyActivityMinutes:
          _goalsProvider.progressionWeeklyActivityMinsForWeek(
        startOfProgressionWeek(anchor),
      ),
      targetWeightKg: _goalsProvider.targetWeight,
    );
  }

  @override
  List<ProgressionSnapshot> buildDailySnapshots() {
    final days = _availableDays();
    final prefetchedNutritionByKey = _prefetchNutrition(days);
    final today = progressionDate(_clock());

    return [
      for (final day in days)
        _dailySnapshotFor(
          day,
          prefetchedNutritionByKey: prefetchedNutritionByKey,
          today: today,
        ),
    ];
  }

  @override
  List<ProgressionSnapshot> buildWeeklySnapshots() {
    final weekStarts =
        _availableDays().map(startOfProgressionWeek).toSet().toList()..sort();

    return [
      for (final weekStart in weekStarts)
        ProgressionSnapshot(
          period: ProgressionPeriod.week(weekStart),
          activityMinutes: _activityMinutesForRange(
            weekStart,
            weekStart.add(const Duration(days: 6)),
          ),
        ),
    ];
  }

  @override
  String get auditSignature {
    final stepSignature = _fitnessProvider.stepsHistory
        .map((record) => '${progressionDateKey(record.date)}:${record.steps}')
        .join(',');
    final weightSignature = _fitnessProvider.weightHistory
        .map((record) =>
            '${progressionDateKey(record.date)}:${record.weight}')
        .join(',');
    final sleepSignature = _fitnessProvider.sleepHistory
        .map((record) =>
            '${progressionDateKey(record.wakeTime)}:${record.totalDuration.inMinutes}')
        .join(',');
    final activitySignature = _fitnessProvider.activities
        .map((record) =>
            '${record.startTime.toIso8601String()}:${record.duration.inMinutes}')
        .join(',');

    return [
      _goalsProvider.dailySteps,
      _goalsProvider.dailyCalories,
      _goalsProvider.dailyProtein,
      _goalsProvider.sleepHours,
      _goalsProvider.weeklyActivityMins,
      _goalsProvider.progressionHistorySignature,
      _fitnessProvider.lastSyncedAt?.toIso8601String() ?? 'no-fitness-sync',
      _nutritionProvider.lastSyncedAt?.toIso8601String() ?? 'no-nutrition-sync',
      _nutritionProvider.isLoggedIn,
      stepSignature,
      sleepSignature,
      activitySignature,
      _nutritionProvider.todayCalories,
      _nutritionProvider.todayProtein,
      weightSignature,
    ].join('|');
  }

  List<DateTime> _availableDays() {
    final days = _fitnessProvider.stepsHistory.map((record) {
      return progressionDate(record.date);
    }).toSet();

    if (days.isEmpty) {
      days.add(progressionDate(_clock()));
    }

    final sorted = days.toList()..sort();
    return sorted;
  }

  ProgressionSnapshot _dailySnapshotFor(
    DateTime day, {
    required Map<String, KtDayNutrition> prefetchedNutritionByKey,
    required DateTime today,
  }) {
    final nutrition = prefetchedNutritionByKey[progressionDateKey(day)];
    final isToday = progressionDate(day) == today;

    return ProgressionSnapshot(
      period: ProgressionPeriod.day(day),
      steps: _fitnessProvider.stepsForDate(day),
      calories: nutrition?.calories ??
          (isToday ? _nutritionProvider.todayCalories : 0),
      proteinGrams:
          nutrition?.protein ?? (isToday ? _nutritionProvider.todayProtein : 0),
      sleepMinutes:
          _fitnessProvider.sleepForDate(day)?.totalDuration.inMinutes ?? 0,
      activityMinutes: _activityMinutesForRange(day, day),
      weightKg: _fitnessProvider.weightForDate(day)?.weight ?? 0.0,
    );
  }

  Map<String, KtDayNutrition> _prefetchNutrition(List<DateTime> days) {
    if (days.isEmpty) {
      return const {};
    }

    final sortedDays = [...days]..sort();
    return _nutritionProvider.nutritionRange(
      sortedDays.first,
      sortedDays.last,
    );
  }

  int _activityMinutesForRange(DateTime start, DateTime end) {
    final rangeStart = progressionDate(start);
    final rangeEnd = progressionDate(end);

    return _fitnessProvider.activities.fold<int>(0, (sum, activity) {
      final day = progressionDate(activity.startTime);
      if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
        return sum;
      }
      return sum + activity.duration.inMinutes;
    });
  }
}
