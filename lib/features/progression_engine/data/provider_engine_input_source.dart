import 'package:forgetrack/domain/journal/in_memory_journal.dart';
import 'package:forgetrack/domain/journal/journal.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/player.dart';

import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../health_connect/domain/goal_board.dart';
import '../../health_connect/domain/health_snapshot.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../nutrition/domain/nutrition_snapshot.dart';
import '../domain/catalog/engine_catalog_context.dart';
import '../domain/models/engine_evaluation_context.dart';
import '../domain/models/evaluation_overrides.dart';
import '../domain/models/ledger_counters.dart';

/// Builds [EngineEvaluationContext] + [EngineCatalogContext] from the
/// app's live source providers.
///
/// Phase 16 replaced the flat `EngineEvaluationInput` record with a
/// bundle of structured VOs (`Player` + snapshots + `GoalBoard` +
/// `Journal` + `LedgerCounters` + `EvaluationOverrides` +
/// `evaluatedAt`). The provider keeps the same per-tick counter
/// derivation it had pre-extraction (`_rewardCountByDomainFromLedger`
/// etc. on the provider side) and passes the resulting maps as
/// `LedgerCounters`. Phase 20 (`JournalProjection`) will move the
/// derivation into the Journal aggregate itself; until then this
/// source bridges the gap.
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

  /// Assembles the engine's per-evaluation context. Caller-supplied
  /// values cover the journal-derived counters + runtime overrides +
  /// player snapshot (level / totalXp / rpgModeEnabled); the source
  /// fabricates the health / nutrition snapshots and wraps the
  /// caller-supplied event list as a [Journal].
  EngineEvaluationContext buildContext({
    required Player player,
    required List<JournalEvent> events,
    LedgerCounters counters = LedgerCounters.empty,
    EvaluationOverrides overrides = EvaluationOverrides.empty,
  }) {
    final today = _today();
    final health = fitness.snapshotForDate(today);
    final nutritionSnap = nutrition.snapshotForDate(today);
    return EngineEvaluationContext(
      player: player,
      healthSnapshot: health,
      nutritionSnapshot: nutritionSnap,
      goalBoard: goals.board,
      journal: InMemoryJournal(events),
      counters: counters,
      overrides: overrides,
      evaluatedAt: _clock(),
    );
  }

  /// Stable signature for change detection. Matches the pre-refactor
  /// pattern — when this string changes, the engine re-evaluates.
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
  /// "today". Used by callers that need snapshot data without
  /// constructing a full evaluation context.
  HealthSnapshot currentHealthSnapshot() => fitness.snapshotForDate(_today());

  /// Builds a [NutritionSnapshot] anchored at the engine's current
  /// "today". Symmetrical convenience to [currentHealthSnapshot].
  NutritionSnapshot currentNutritionSnapshot() =>
      nutrition.snapshotForDate(_today());

  /// Builds a [GoalBoard] snapshot from the bound [GoalsProvider].
  GoalBoard currentGoalBoard() => goals.board;

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
