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
  }) {
    final today = _today();
    return EngineEvaluationInput(
      evaluatedAt: _clock(),
      totalXp: totalXpFromLedger,
      level: levelFromLedger,
      stepsToday: fitness.stepsForDate(today),
      caloriesToday: nutrition.todayCalories.toDouble(),
      proteinGramsToday: nutrition.todayProtein.toDouble(),
      sleepMinutesToday:
          fitness.sleepForDate(today)?.totalDuration.inMinutes ?? 0,
      activityMinutesToday: _activityMinutesForDay(today),
    );
  }

  /// Stable signature for change detection. Matches V1's pattern —
  /// when this string changes, the engine re-evaluates.
  String auditSignature() {
    final today = _today();
    return [
      goals.dailySteps,
      goals.dailyCalories,
      goals.dailyProtein,
      goals.sleepHours,
      goals.weeklyActivityMins,
      fitness.stepsForDate(today),
      nutrition.todayCalories,
      nutrition.todayProtein,
      fitness.sleepForDate(today)?.totalDuration.inMinutes ?? 0,
      _activityMinutesForDay(today),
    ].join('|');
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
