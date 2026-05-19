import 'package:meta/meta.dart';

import '../../../../domain/journal/journal.dart';
import '../../../../domain/player/player.dart';
import '../../../health_connect/domain/goal_board.dart';
import '../../../health_connect/domain/health_snapshot.dart';
import '../../../nutrition/domain/nutrition_snapshot.dart';
import 'evaluation_overrides.dart';
import 'ledger_counters.dart';

/// Internal value object bundling every input the engine evaluator
/// and its sub-evaluators read during one evaluation pass.
///
/// Phase 16 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 16) deletes `EngineEvaluationInput` and reshapes the
/// engine boundary. The public `ProgressionEngine.evaluate()` takes
/// structured named args (player + snapshots + goal board + journal
/// + counters + overrides + evaluatedAt); internally those args are
/// bundled into this context so sub-evaluators
/// (`ObjectiveEvaluator`, `ProgressionNodeResolver`,
/// `UnlockConditionResolver`, `RewardGrantPlanner`) keep a single
/// argument that already carries the discriminated VOs.
///
/// **Semantic split (proposal §2):**
///   - [player] — `level` / `totalXp` / `rpgModeEnabled`.
///   - [healthSnapshot] — Health Connect read-side (steps / sleep /
///     activity / weight).
///   - [nutritionSnapshot] — KT read-side (kcal + macros).
///   - [goalBoard] — per-Player goals. Carried for completeness; the
///     evaluator path today does not read this directly (engine
///     catalog context still mediates goal targets), but Phase 17+
///     consumers will.
///   - [journal] — append-only event history. Carried for
///     completeness; engine still reads via
///     `ProgressionEngineRepository.loadLedger()` until Phase 20
///     ships `JournalProjection`.
///   - [counters] — journal-derived aggregations (reward counts,
///     streaks, rolling windows, node completion counts, distinct
///     active days, today-completion set).
///   - [overrides] — provider-runtime overrides (chapter-step
///     baseline values that bypass the metric switch).
///   - [evaluatedAt] — anchor timestamp for period-key derivation +
///     unlock-condition date logic + bonus-XP timing rules.
///   - [ownedCosmeticIds] — cosmetic ids currently in the cosmetics
///     inventory's `unlocked` map. Read by `OwnsCosmetic` unlock
///     conditions so the engine evaluates relic-ownership gates from
///     the same source of truth as the reveal evaluator. Defaults to
///     the empty set so tests + non-companion evaluations stay
///     unaffected.
@immutable
class EngineEvaluationContext {
  const EngineEvaluationContext({
    required this.player,
    required this.healthSnapshot,
    required this.nutritionSnapshot,
    required this.goalBoard,
    required this.journal,
    required this.counters,
    required this.overrides,
    required this.evaluatedAt,
    this.ownedCosmeticIds = const <String>{},
  });

  final Player player;
  final HealthSnapshot healthSnapshot;
  final NutritionSnapshot nutritionSnapshot;
  final GoalBoard goalBoard;
  final Journal journal;
  final LedgerCounters counters;
  final EvaluationOverrides overrides;
  final DateTime evaluatedAt;
  final Set<String> ownedCosmeticIds;

  EngineEvaluationContext copyWith({
    Player? player,
    HealthSnapshot? healthSnapshot,
    NutritionSnapshot? nutritionSnapshot,
    GoalBoard? goalBoard,
    Journal? journal,
    LedgerCounters? counters,
    EvaluationOverrides? overrides,
    DateTime? evaluatedAt,
    Set<String>? ownedCosmeticIds,
  }) {
    return EngineEvaluationContext(
      player: player ?? this.player,
      healthSnapshot: healthSnapshot ?? this.healthSnapshot,
      nutritionSnapshot: nutritionSnapshot ?? this.nutritionSnapshot,
      goalBoard: goalBoard ?? this.goalBoard,
      journal: journal ?? this.journal,
      counters: counters ?? this.counters,
      overrides: overrides ?? this.overrides,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      ownedCosmeticIds: ownedCosmeticIds ?? this.ownedCosmeticIds,
    );
  }
}
