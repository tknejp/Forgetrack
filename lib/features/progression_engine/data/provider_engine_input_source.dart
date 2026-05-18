import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../health_connect/domain/health_snapshot.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../nutrition/domain/nutrition_snapshot.dart';
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
        dailyFiberGrams: goals.dailyFiber,
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
    final health = fitness.snapshotForDate(today);
    final nutritionSnap = nutrition.snapshotForDate(today);
    return EngineEvaluationInput(
      evaluatedAt: _clock(),
      totalXp: totalXpFromLedger,
      level: levelFromLedger,
      stepsToday: health.stepsToday,
      stepsThisWeek: health.stepsThisWeek,
      stepsLifetime: health.stepsLifetime,
      caloriesToday: nutritionSnap.caloriesToday,
      proteinGramsToday: nutritionSnap.proteinGramsToday,
      carbsGramsToday: nutritionSnap.carbsGramsToday,
      fatGramsToday: nutritionSnap.fatGramsToday,
      fiberGramsToday: nutritionSnap.fiberGramsToday,
      sleepMinutesToday: health.sleepMinutesToday,
      activityMinutesToday: health.activityMinutesToday,
      weightLoggedToday: health.weightLoggedToday,
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
    final health = fitness.snapshotForDate(today);
    final nutritionSnap = nutrition.snapshotForDate(today);
    return [
      goals.dailySteps,
      goals.dailyCalories,
      goals.dailyProtein,
      goals.sleepHours,
      goals.weeklyActivityMins,
      health.signature,
      nutritionSnap.signature,
    ].join('|');
  }

  /// Builds a [HealthSnapshot] anchored at the engine's current
  /// "today" without paying for [EngineEvaluationInput] construction.
  /// Exposed for Phase 16 prep — callers that only need snapshot data
  /// can read it without going through `buildInput`.
  HealthSnapshot currentHealthSnapshot() => fitness.snapshotForDate(_today());

  /// Builds a [NutritionSnapshot] anchored at the engine's current
  /// "today". Symmetrical convenience to [currentHealthSnapshot].
  NutritionSnapshot currentNutritionSnapshot() =>
      nutrition.snapshotForDate(_today());

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
