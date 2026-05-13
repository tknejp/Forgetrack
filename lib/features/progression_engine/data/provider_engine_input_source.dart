import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../domain/catalog/engine_catalog_context.dart';
import '../domain/models/engine_evaluation_input.dart';

/// Builds [EngineEvaluationInput] + [EngineCatalogContext] from the
/// app's live source providers. Equivalent role to V1's
/// `ProviderProgressionSource` but produces the V2-shaped input.
///
/// Today the source pulls "today" metrics + a coarse audit signature
/// so the engine can detect when a recompute is needed. Lifetime
/// totals, streaks, and rolling-window data are not yet derived from
/// the live history — those land as the corresponding V2 metrics
/// reach UI consumers.
class ProviderEngineInputSource {
  ProviderEngineInputSource({
    required this.goals,
    required this.fitness,
    required this.nutrition,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GoalsProvider goals;
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider nutrition;
  final DateTime Function() _clock;

  EngineCatalogContext currentContext() {
    return EngineCatalogContext(
      goals: EngineGoalSet(
        dailySteps: goals.dailySteps,
        dailyCalories: goals.dailyCalories,
        dailyProteinGrams: goals.dailyProtein,
        dailyCarbsGrams: goals.dailyCarbs,
        dailyFatGrams: goals.dailyFat,
        sleepMinutes: (goals.sleepHours * 60).round(),
        weeklyActivityMinutes: goals.weeklyActivityMins,
        targetWeightKg: goals.targetWeight,
      ),
    );
  }

  EngineEvaluationInput buildInput({
    required int totalXpFromLedger,
    required int levelFromLedger,
    int totalRewardCount = 0,
    Map<String, int> rewardCountByRule = const {},
    Map<String, int> rewardCountByDomain = const {},
    Map<String, int> bestStreakByRule = const {},
    Map<String, int> bestStreakByDomain = const {},
    Map<String, int> nodeCompletionCounts = const {},
    int totalQuestCompletions = 0,
    Map<String, int> questCompletionsByBucket = const {},
    int distinctActiveDays = 0,
    Set<String> nodesCompletedToday = const {},
    Map<String, int> comboPoolCompletionCounts = const {},
    Map<String, double> objectiveActualOverrides = const {},
  }) {
    final today = _today();
    return EngineEvaluationInput(
      evaluatedAt: _clock(),
      totalXp: totalXpFromLedger,
      level: levelFromLedger,
      stepsToday: fitness.stepsForDate(today),
      stepsThisWeek: _stepsThisWeek(today),
      stepsLifetime: _stepsLifetime(),
      caloriesToday: nutrition.todayCalories.toDouble(),
      proteinGramsToday: nutrition.todayProtein.toDouble(),
      carbsGramsToday: nutrition.todayCarbs.toDouble(),
      fatGramsToday: nutrition.todayFat.toDouble(),
      fiberGramsToday: nutrition.todayFiber.toDouble(),
      sleepMinutesToday:
          fitness.sleepForDate(today)?.totalDuration.inMinutes ?? 0,
      activityMinutesToday: _activityMinutesForDay(today),
      weightLoggedToday: fitness.weightForDate(today) != null,
      totalRewardCount: totalRewardCount,
      rewardCountByRule: rewardCountByRule,
      rewardCountByDomain: rewardCountByDomain,
      bestStreakByRule: bestStreakByRule,
      bestStreakByDomain: bestStreakByDomain,
      nodeCompletionCounts: nodeCompletionCounts,
      totalQuestCompletions: totalQuestCompletions,
      questCompletionsByBucket: questCompletionsByBucket,
      distinctActiveDays: distinctActiveDays,
      nodesCompletedToday: nodesCompletedToday,
      comboPoolCompletionCounts: comboPoolCompletionCounts,
      objectiveActualOverrides: objectiveActualOverrides,
    );
  }

  /// Stable signature for change detection. Matches V1's pattern —
  /// when this string changes, the engine re-evaluates. Includes the
  /// lifetime / week-rolling step totals so long-term objectives bound
  /// to LifetimeScope progress bars refresh as the player walks, not
  /// just on app restart.
  String auditSignature() {
    final today = _today();
    return [
      goals.dailySteps,
      goals.dailyCalories,
      goals.dailyProtein,
      goals.sleepHours,
      goals.weeklyActivityMins,
      fitness.stepsForDate(today),
      _stepsThisWeek(today),
      _stepsLifetime(),
      nutrition.todayCalories,
      nutrition.todayProtein,
      fitness.sleepForDate(today)?.totalDuration.inMinutes ?? 0,
      _activityMinutesForDay(today),
      fitness.weightForDate(today) != null ? 1 : 0,
    ].join('|');
  }

  /// Sum of all step records the FitnessProvider has loaded. Acts as a
  /// pragmatic lifetime total — bounded by the user's Health Connect
  /// history retention. Pre-tracking days simply do not contribute.
  int _stepsLifetime() {
    return fitness.stepsHistory.fold<int>(0, (sum, r) => sum + r.steps);
  }

  /// Sum of steps from Monday (start of ISO week) up to and including
  /// `today`. Drives weekly-scoped step objectives.
  int _stepsThisWeek(DateTime today) {
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    var sum = 0;
    for (final r in fitness.stepsHistory) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      if (!d.isBefore(monday) && !d.isAfter(today)) sum += r.steps;
    }
    return sum;
  }

  int _activityMinutesForDay(DateTime day) {
    return fitness.activities.fold<int>(0, (sum, activity) {
      final activityDay = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );
      if (activityDay != day) return sum;
      return sum + activity.duration.inMinutes;
    });
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
