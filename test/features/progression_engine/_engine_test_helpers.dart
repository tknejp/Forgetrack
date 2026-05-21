import 'package:forgetrack/domain/journal/in_memory_journal.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/player.dart';
import 'package:forgetrack/features/health_connect/domain/goal_board.dart';
import 'package:forgetrack/features/health_connect/domain/health_snapshot.dart';
import 'package:forgetrack/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_context.dart';
import 'package:forgetrack/features/progression_engine/domain/models/evaluation_overrides.dart';
import 'package:forgetrack/features/progression_engine/domain/models/ledger_counters.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_resolution_reason.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_resolution_result.dart';

/// Constructs an [EngineEvaluationContext] for engine tests, defaulting
/// every collaborator so callers only specify what their scenario
/// exercises. Mirrors the pre-refactor `_input(...)` test helper
/// pattern but produces the structured-VO bundle that Phase 16
/// introduced.
EngineEvaluationContext buildTestContext({
  DateTime? evaluatedAt,
  int level = 1,
  int totalXp = 0,
  bool rpgModeEnabled = true,
  int stepsToday = 0,
  int stepsThisWeek = 0,
  int stepsLifetime = 0,
  int sleepMinutesToday = 0,
  int activityMinutesToday = 0,
  bool weightLoggedToday = false,
  int lifetimeNightsStartedAtOrAfter1am = 0,
  int lifetimeNightsStartedBefore10pm = 0,
  int bestSingleDayStepsLifetime = 0,
  double caloriesToday = 0,
  double proteinGramsToday = 0,
  double carbsGramsToday = 0,
  double fatGramsToday = 0,
  double fiberGramsToday = 0,
  int totalRewardCount = 0,
  Map<String, int> rewardCountByRule = const {},
  Map<String, int> rewardCountByDomain = const {},
  Map<String, int> bestStreakByRule = const {},
  Map<String, int> bestStreakByDomain = const {},
  Map<int, int> bestRollingStepsByDays = const {},
  Map<int, int> bestRollingSleepMinutesByDays = const {},
  Map<String, int> nodeCompletionCounts = const {},
  Map<String, int> comboPoolCompletionCounts = const {},
  int totalQuestCompletions = 0,
  Map<String, int> questCompletionsByBucket = const {},
  int distinctActiveDays = 0,
  Set<String> nodesCompletedToday = const {},
  Map<int, int> returnsAfterGapByDays = const {},
  Map<int, int> bestStreakAfterGapByDays = const {},
  Map<String, double> objectiveActualOverrides = const {},
  List<JournalEvent> events = const [],
}) {
  final at = evaluatedAt ?? DateTime(2024, 1, 1);
  final day = DateTime(at.year, at.month, at.day);
  return EngineEvaluationContext(
    player: Player(
      uid: '',
      level: level,
      totalXp: totalXp,
      joinedAt: day,
      rpgModeEnabled: rpgModeEnabled,
    ),
    healthSnapshot: HealthSnapshot(
      evaluatedDate: day,
      stepsToday: stepsToday,
      stepsThisWeek: stepsThisWeek,
      stepsLifetime: stepsLifetime,
      sleepMinutesToday: sleepMinutesToday,
      activityMinutesToday: activityMinutesToday,
      weightLoggedToday: weightLoggedToday,
      lifetimeNightsStartedAtOrAfter1am: lifetimeNightsStartedAtOrAfter1am,
      lifetimeNightsStartedBefore10pm: lifetimeNightsStartedBefore10pm,
      bestSingleDayStepsLifetime: bestSingleDayStepsLifetime,
    ),
    nutritionSnapshot: NutritionSnapshot(
      evaluatedDate: day,
      caloriesToday: caloriesToday,
      proteinGramsToday: proteinGramsToday,
      carbsGramsToday: carbsGramsToday,
      fatGramsToday: fatGramsToday,
      fiberGramsToday: fiberGramsToday,
    ),
    goalBoard: GoalBoard.empty,
    journal: InMemoryJournal(events),
    counters: LedgerCounters(
      totalRewardCount: totalRewardCount,
      rewardCountByRule: rewardCountByRule,
      rewardCountByDomain: rewardCountByDomain,
      bestStreakByRule: bestStreakByRule,
      bestStreakByDomain: bestStreakByDomain,
      bestRollingStepsByDays: bestRollingStepsByDays,
      bestRollingSleepMinutesByDays: bestRollingSleepMinutesByDays,
      nodeCompletionCounts: nodeCompletionCounts,
      comboPoolCompletionCounts: comboPoolCompletionCounts,
      totalQuestCompletions: totalQuestCompletions,
      questCompletionsByBucket: questCompletionsByBucket,
      distinctActiveDays: distinctActiveDays,
      nodesCompletedToday: nodesCompletedToday,
      returnsAfterGapByDays: returnsAfterGapByDays,
      bestStreakAfterGapByDays: bestStreakAfterGapByDays,
    ),
    overrides: EvaluationOverrides(
      objectiveActualOverrides: objectiveActualOverrides,
    ),
    evaluatedAt: at,
  );
}

/// Spreads a [EngineEvaluationContext] across [ProgressionEngine.evaluate]'s
/// named-args signature. Saves test code from writing the same 8-line
/// argument list at every call site.
Future<ProgressionResolutionResult> evaluateWithContext(
  ProgressionEngine engine,
  EngineEvaluationContext context, {
  EngineCatalogContext catalogContext = const EngineCatalogContext(),
  ProgressionResolutionReason reason =
      ProgressionResolutionReason.liveUpdate,
}) {
  return engine.evaluate(
    player: context.player,
    healthSnapshot: context.healthSnapshot,
    nutritionSnapshot: context.nutritionSnapshot,
    goalBoard: context.goalBoard,
    journal: context.journal,
    counters: context.counters,
    overrides: context.overrides,
    evaluatedAt: context.evaluatedAt,
    catalogContext: catalogContext,
    reason: reason,
  );
}
