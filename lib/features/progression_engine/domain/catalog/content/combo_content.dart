import 'package:forgetrack/domain/progression/catalog/generation_suffix.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/quest_policies.dart';

import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// Daily combo chains — themed sequential quests that live in their
/// own `QuestDisplayBucket.combo` so they don't compete with the
/// 2-per-day base daily rotation.
///
/// **Daily rate-limit.** Only one combo step may complete per day
/// across all combo chains. Each step's `unlockConditions` carry a
/// [NodeCompletedBeforeToday] gate on the prereq, so even if today's
/// atoms would already satisfy step N+1's objective, the step
/// remains gated until tomorrow. `prerequisiteNodeIds` is also set
/// for UI affordances (chain-preview locks, "complete previous step
/// first" hints).
///
/// **Chain rotation (repeatable across `kComboGenerationCount` gens).**
/// Chain 1 → 2 → 3 → chain 1 (next gen) → … Each generation re-uses
/// the same templates but materialises distinct nodes / objectives /
/// chain ids by suffixing `@<gen>` (see [withGenerationSuffix]). The
/// first step of generation N's chain 1 prereqs generation (N-1)'s
/// chain 3 finale, so completing a full loop unlocks the next loop.
/// Generation 1 keeps the canonical (unsuffixed) ids for back-compat
/// with every ledger event emitted before pre-allocation landed.
///
/// **Step shape.** Each step is a `QuestNode` with `displayBucket:
/// combo`, `comboPoolId: ComboPoolId('daily_combo_pool')` (so the existing
/// `combo_victory_10` achievement counts these), and an objective
/// using `TodayCompletionsAmongMetric`. Difficulty escalates per
/// step — step N requires more of today's daily goals than step
/// N-1, and the player must actually meet the larger set today
/// (not retroactively credit yesterday's wins).
///
/// **Triple combo membership.** Steps with 3+ atoms feed the
/// `combo_triple_victory_25` / `combo_triple_victory_100`
/// achievements via [LifetimeCompletionsAmongMetric], which matches
/// completions by **template id** — completions across every
/// generation roll up to the same lifetime tally. The seven
/// template ids live in [tripleComboNodeIds] and the matching
/// `triple_combo_*` objectives in `meta_content.dart`.

const _comboPoolId = ComboPoolId('daily_combo_pool');

/// Pool of **all** daily-bucket quests that count toward
/// "any 1/2/3/4 daily goal" — used by the chain 1 "balanced"
/// progression. Anything completed today from this set counts.
const _allDailyQuests = <ProgressionEntryId>[
  ProgressionEntryId('daily_steps_today'),
  ProgressionEntryId('daily_calories_today'),
  ProgressionEntryId('daily_protein_today'),
  ProgressionEntryId('daily_carbs_today'),
  ProgressionEntryId('daily_fat_today'),
  ProgressionEntryId('daily_fiber_today'),
  ProgressionEntryId('daily_sleep_today'),
  ProgressionEntryId('daily_activity_today'),
];

/// Node ids (template form) whose completion counts as a
/// "triple-or-higher" combo. The evaluator's
/// `LifetimeCompletionsAmongMetric` matches by template id so every
/// generation's `combo_balanced_step_3@<gen>` (etc.) rolls up here.
const tripleComboNodeIds = <ProgressionEntryId>[
  ProgressionEntryId('combo_balanced_step_3'),
  ProgressionEntryId('combo_balanced_finale'),
  ProgressionEntryId('combo_recovery_step_3'),
  ProgressionEntryId('combo_recovery_finale'),
  ProgressionEntryId('combo_nutrition_step_3'),
  ProgressionEntryId('combo_nutrition_step_4'),
  ProgressionEntryId('combo_nutrition_finale'),
];

// ── Template ids — referenced from cross-gen prereq stitching ──────

const _balancedStep1 = 'combo_balanced_step_1';
const _balancedFinale = 'combo_balanced_finale';
const _recoveryStep1 = 'combo_recovery_step_1';
const _recoveryFinale = 'combo_recovery_finale';
const _nutritionStep1 = 'combo_nutrition_step_1';
const _nutritionFinale = 'combo_nutrition_finale';

ProgressionEntryId _nodeId(String template, int gen) =>
    ProgressionEntryId(withGenerationSuffix(template, gen));

ObjectiveId _objId(String template, int gen) =>
    ObjectiveId(withGenerationSuffix(template, gen));

ChainId _chain(String template, int gen) =>
    ChainId(withGenerationSuffix(template, gen));

/// All combo step objectives use `LifetimeScope()`. The metric
/// [TodayCompletionsAmongMetric] always reads `nodesCompletedToday`
/// regardless of scope, so the *value* (today's atoms) is unchanged;
/// the lifetime scope just makes the *completion event* once-and-done
/// (no per-period reset). That's the correct semantic for chain
/// progression — once step N is claimed it stays completed, and step
/// N+1 picks up tomorrow with a fresh today-atoms tally. Generation
/// suffixing makes each generation's step a distinct once-and-done
/// node, so the chain re-runs without losing per-claim event
/// semantics.
List<Objective> comboObjectives(EngineCatalogContext context) {
  final out = <Objective>[];
  for (var gen = 1; gen <= kComboGenerationCount; gen++) {
    out.addAll(_comboObjectivesForGen(gen));
  }
  return out;
}

List<Objective> _comboObjectivesForGen(int gen) {
  return [
    // ── Chain 1: Balanced — any daily goal ──────────────────────
    Objective(
      id: _objId('combo_balanced_step_1_obj', gen),
      metric: const TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: _objId('combo_balanced_step_2_obj', gen),
      metric: const TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: _objId('combo_balanced_step_3_obj', gen),
      metric: const TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: _objId('combo_balanced_finale_obj', gen),
      metric: const TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    // ── Chain 2: Recovery — sleep-anchored ──────────────────────
    Objective(
      id: _objId('combo_recovery_step_1_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_sleep_today')],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: _objId('combo_recovery_step_2_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_sleep_today'),
          ProgressionEntryId('daily_steps_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: _objId('combo_recovery_step_3_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_sleep_today'),
          ProgressionEntryId('daily_steps_today'),
          ProgressionEntryId('daily_protein_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: _objId('combo_recovery_finale_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_sleep_today'),
          ProgressionEntryId('daily_steps_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_calories_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    // ── Chain 3: Nutrition — macro-anchored ─────────────────────
    Objective(
      id: _objId('combo_nutrition_step_1_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_calories_today')],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: _objId('combo_nutrition_step_2_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: _objId('combo_nutrition_step_3_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_carbs_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: _objId('combo_nutrition_step_4_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_carbs_today'),
          ProgressionEntryId('daily_fat_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    Objective(
      id: _objId('combo_nutrition_finale_obj', gen),
      metric: const TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_carbs_today'),
          ProgressionEntryId('daily_fat_today'),
          ProgressionEntryId('daily_fiber_today'),
        ],
      ),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5,
    ),
  ];
}

List<ProgressionEntry> comboNodes() {
  final out = <ProgressionEntry>[];
  for (var gen = 1; gen <= kComboGenerationCount; gen++) {
    out.addAll(_comboNodesForGen(gen));
  }
  return out;
}

List<ProgressionEntry> _comboNodesForGen(int gen) {
  // Gen N chain 1 step 1's prereq stitches to gen (N-1)'s chain 3
  // finale — completing a full loop unlocks the next one. Generation 1
  // has no predecessor and starts unlocked.
  final balancedStep1Prereqs = <ProgressionEntryId>[
    if (gen > 1) _nodeId(_nutritionFinale, gen - 1),
  ];

  return [
    // ── Chain 1: Balanced ──────────────────────────────────────
    ComboStep(
      id: _nodeId(_balancedStep1, gen),
      objectiveId: _objId('combo_balanced_step_1_obj', gen),
      titleKey: (l) => l.progComboBalancedStep1Title,
      descriptionKey: (l) => l.progComboBalancedStep1Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 50),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_balanced', gen),
      chainOrder: 0,
      chainStepLabelKey: (_) => '1',
      prerequisiteNodeIds: balancedStep1Prereqs,
      nextNodeIds: [_nodeId('combo_balanced_step_2', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_balanced_step_2', gen),
      objectiveId: _objId('combo_balanced_step_2_obj', gen),
      titleKey: (l) => l.progComboBalancedStep2Title,
      descriptionKey: (l) => l.progComboBalancedStep2Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 100),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_balanced', gen),
      chainOrder: 1,
      chainStepLabelKey: (_) => '2',
      prerequisiteNodeIds: [_nodeId(_balancedStep1, gen)],
      nextNodeIds: [_nodeId('combo_balanced_step_3', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_balanced_step_3', gen),
      objectiveId: _objId('combo_balanced_step_3_obj', gen),
      titleKey: (l) => l.progComboBalancedStep3Title,
      descriptionKey: (l) => l.progComboBalancedStep3Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 150),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_balanced', gen),
      chainOrder: 2,
      chainStepLabelKey: (_) => '3',
      prerequisiteNodeIds: [_nodeId('combo_balanced_step_2', gen)],
      nextNodeIds: [_nodeId(_balancedFinale, gen)],
    ),
    ComboFinale(
      id: _nodeId(_balancedFinale, gen),
      objectiveId: _objId('combo_balanced_finale_obj', gen),
      titleKey: (l) => l.progComboBalancedFinaleTitle,
      descriptionKey: (l) => l.progComboBalancedFinaleDesc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 220),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_balanced', gen),
      chainOrder: 3,
      chainStepIcon: ChainStepIcon.comboFlag,
      prerequisiteNodeIds: [_nodeId('combo_balanced_step_3', gen)],
    ),
    // ── Chain 2: Recovery (sleep-anchored) ─────────────────────
    ComboStep(
      id: _nodeId(_recoveryStep1, gen),
      objectiveId: _objId('combo_recovery_step_1_obj', gen),
      titleKey: (l) => l.progComboRecoveryStep1Title,
      descriptionKey: (l) => l.progComboRecoveryStep1Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 60),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_recovery', gen),
      chainOrder: 0,
      chainStepLabelKey: (_) => '1',
      prerequisiteNodeIds: [_nodeId(_balancedFinale, gen)],
      nextNodeIds: [_nodeId('combo_recovery_step_2', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_recovery_step_2', gen),
      objectiveId: _objId('combo_recovery_step_2_obj', gen),
      titleKey: (l) => l.progComboRecoveryStep2Title,
      descriptionKey: (l) => l.progComboRecoveryStep2Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 120),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_recovery', gen),
      chainOrder: 1,
      chainStepLabelKey: (_) => '2',
      prerequisiteNodeIds: [_nodeId(_recoveryStep1, gen)],
      nextNodeIds: [_nodeId('combo_recovery_step_3', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_recovery_step_3', gen),
      objectiveId: _objId('combo_recovery_step_3_obj', gen),
      titleKey: (l) => l.progComboRecoveryStep3Title,
      descriptionKey: (l) => l.progComboRecoveryStep3Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 180),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_recovery', gen),
      chainOrder: 2,
      chainStepLabelKey: (_) => '3',
      prerequisiteNodeIds: [_nodeId('combo_recovery_step_2', gen)],
      nextNodeIds: [_nodeId(_recoveryFinale, gen)],
    ),
    ComboFinale(
      id: _nodeId(_recoveryFinale, gen),
      objectiveId: _objId('combo_recovery_finale_obj', gen),
      titleKey: (l) => l.progComboRecoveryFinaleTitle,
      descriptionKey: (l) => l.progComboRecoveryFinaleDesc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 260),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_recovery', gen),
      chainOrder: 3,
      chainStepIcon: ChainStepIcon.comboFlag,
      prerequisiteNodeIds: [_nodeId('combo_recovery_step_3', gen)],
    ),
    // ── Chain 3: Nutrition (macro-anchored, 5 steps) ──────────
    ComboStep(
      id: _nodeId(_nutritionStep1, gen),
      objectiveId: _objId('combo_nutrition_step_1_obj', gen),
      titleKey: (l) => l.progComboNutritionStep1Title,
      descriptionKey: (l) => l.progComboNutritionStep1Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 60),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_nutrition', gen),
      chainOrder: 0,
      chainStepLabelKey: (_) => '1',
      prerequisiteNodeIds: [_nodeId(_recoveryFinale, gen)],
      nextNodeIds: [_nodeId('combo_nutrition_step_2', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_nutrition_step_2', gen),
      objectiveId: _objId('combo_nutrition_step_2_obj', gen),
      titleKey: (l) => l.progComboNutritionStep2Title,
      descriptionKey: (l) => l.progComboNutritionStep2Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 110),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_nutrition', gen),
      chainOrder: 1,
      chainStepLabelKey: (_) => '2',
      prerequisiteNodeIds: [_nodeId(_nutritionStep1, gen)],
      nextNodeIds: [_nodeId('combo_nutrition_step_3', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_nutrition_step_3', gen),
      objectiveId: _objId('combo_nutrition_step_3_obj', gen),
      titleKey: (l) => l.progComboNutritionStep3Title,
      descriptionKey: (l) => l.progComboNutritionStep3Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 170),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_nutrition', gen),
      chainOrder: 2,
      chainStepLabelKey: (_) => '3',
      prerequisiteNodeIds: [_nodeId('combo_nutrition_step_2', gen)],
      nextNodeIds: [_nodeId('combo_nutrition_step_4', gen)],
    ),
    ComboStep(
      id: _nodeId('combo_nutrition_step_4', gen),
      objectiveId: _objId('combo_nutrition_step_4_obj', gen),
      titleKey: (l) => l.progComboNutritionStep4Title,
      descriptionKey: (l) => l.progComboNutritionStep4Desc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 230),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_nutrition', gen),
      chainOrder: 3,
      chainStepLabelKey: (_) => '4',
      prerequisiteNodeIds: [_nodeId('combo_nutrition_step_3', gen)],
      nextNodeIds: [_nodeId(_nutritionFinale, gen)],
    ),
    ComboFinale(
      id: _nodeId(_nutritionFinale, gen),
      objectiveId: _objId('combo_nutrition_finale_obj', gen),
      titleKey: (l) => l.progComboNutritionFinaleTitle,
      descriptionKey: (l) => l.progComboNutritionFinaleDesc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 320),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: _chain('combo_nutrition', gen),
      chainOrder: 4,
      chainStepIcon: ChainStepIcon.comboFlag,
      prerequisiteNodeIds: [_nodeId('combo_nutrition_step_4', gen)],
    ),
  ];
}
