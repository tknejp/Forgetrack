import '../../../progression/domain/policy/level_policy.dart';
import '../models/objective_definition.dart';
import '../models/objective_metric.dart';
import '../models/objective_operator.dart';
import '../models/objective_scope.dart';
import 'engine_catalog_context.dart';

/// Catalog of objective definitions.
///
/// Phase 3 (pilot): a representative slice of legacy rules + lifetime
/// objectives ports through here. The full catalog port — every
/// daily / weekly rule, every quest objective, every level XP
/// threshold, every chapter chain — lands incrementally as the
/// migration progresses.
class ObjectiveCatalog {
  const ObjectiveCatalog();

  /// Class-level lookup using the default goal set. Used by display
  /// helpers and the validator that do not know per-player goals.
  /// Live evaluation goes through `build(context)` with current
  /// goals.
  static ObjectiveDefinition? definitionForId(String id) => _byId[id];

  static final Map<String, ObjectiveDefinition> _byId = {
    for (final def in const ObjectiveCatalog().build()) def.id: def,
  };

  /// XP thresholds reused by level milestones — kept on the legacy
  /// `ProgressionLevelPolicy` for now (single XP curve for V1 + V2).
  static const _levelPolicy = ProgressionLevelPolicy();

  List<ObjectiveDefinition> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    final goals = context.goals;
    return [
      // ── Daily fitness objectives (parameterised on goals) ────────
      ObjectiveDefinition(
        id: 'daily_steps_today',
        metric: const StepsMetric(),
        scope: const TodayScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: goals.dailySteps.toDouble(),
        debugLabel: 'Steps today >= dailyStepsGoal',
      ),
      ObjectiveDefinition(
        id: 'daily_protein_today',
        metric: const ProteinGramsMetric(),
        scope: const TodayScope(),
        operator: ObjectiveOperator.atLeastWithTolerance,
        targetValue: goals.dailyProteinGrams,
        toleranceRatio: 0.10,
        debugLabel: 'Protein today >= dailyProteinGoal (10% tolerance)',
      ),

      // ── Lifetime mastery objective ───────────────────────────────
      const ObjectiveDefinition(
        id: 'lifetime_steps_100k',
        metric: StepsMetric(),
        scope: LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: 100000,
        debugLabel: 'Lifetime steps >= 100k',
      ),

      // ── Welcome anchor (always-true) ─────────────────────────────
      const ObjectiveDefinition(
        id: 'welcome_xp',
        metric: TotalXpMetric(),
        scope: LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: 0,
        debugLabel: 'Welcome — totalXp >= 0',
      ),

      // ── Level XP threshold objective (used by level achievements
      // and as cross-check for the matching LevelMilestoneNode).
      ObjectiveDefinition(
        id: 'level_5_xp',
        metric: const TotalXpMetric(),
        scope: const LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: _levelPolicy.xpRequiredForLevel(5).toDouble(),
        debugLabel: 'Level 5 XP threshold',
      ),
    ];
  }
}
