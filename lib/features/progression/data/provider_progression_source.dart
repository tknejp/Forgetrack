import '../../../providers/fitness_provider.dart';
import '../../../providers/goals_provider.dart';
import '../../../providers/kaloricke_tabulky_provider.dart';
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
    );
  }

  @override
  List<ProgressionSnapshot> buildDailySnapshots() {
    final days = _availableDays();
    return [
      for (final day in days)
        ProgressionSnapshot(
          period: ProgressionPeriod.day(day),
          steps: _fitnessProvider.stepsForDate(day),
          calories: _caloriesForDay(day),
          proteinGrams: _proteinForDay(day),
          sleepMinutes:
              _fitnessProvider.sleepForDate(day)?.totalDuration.inMinutes ?? 0,
          activityMinutes: _activityMinutesForRange(day, day),
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

  double _caloriesForDay(DateTime day) {
    final nutrition = _nutritionProvider.nutritionForDate(day);
    if (nutrition != null) return nutrition.calories;

    final today = progressionDate(_clock());
    if (progressionDate(day) == today) {
      return _nutritionProvider.todayCalories;
    }

    return 0;
  }

  double _proteinForDay(DateTime day) {
    final nutrition = _nutritionProvider.nutritionForDate(day);
    if (nutrition != null) return nutrition.protein;

    final today = progressionDate(_clock());
    if (progressionDate(day) == today) {
      return _nutritionProvider.todayProtein;
    }

    return 0;
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
