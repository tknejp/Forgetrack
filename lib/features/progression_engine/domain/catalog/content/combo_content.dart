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

/// Daily combo chains â€” themed sequential quests that live in their
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
/// **Chain rotation (finite for now).** Chain 1 â†’ 2 â†’ 3. The first
/// step of each subsequent chain has both the prereq and the
/// before-today gate pointing at the previous chain's finale. A
/// perpetual "lap counter" so chain 1 can re-unlock after chain 3
/// finishes is **future engine work** â€” the engine has no per-lap
/// completion semantics today, so once all 13 steps complete the
/// player sees an empty combo section until new content lands.
///
/// **Step shape.** Each step is a `QuestNode` with `displayBucket:
/// combo`, `comboPoolId: ComboPoolId('daily_combo_pool')` (so the existing
/// `combo_victory_10` achievement counts these), and an objective
/// using `TodayCompletionsAmongMetric`. Difficulty escalates per
/// step â€” step N requires more of today's daily goals than step
/// N-1, and the player must actually meet the larger set today
/// (not retroactively credit yesterday's wins).
///
/// **Triple combo membership.** Steps with 3+ atoms feed the
/// `combo_triple_victory_25` / `combo_triple_victory_100`
/// achievements â€” see `tripleComboNodeIds` and the matching
/// `triple_combo_*` objectives in `meta_content.dart`.

const _comboPoolId = ComboPoolId('daily_combo_pool');

/// Pool of **all** daily-bucket quests that count toward
/// "any 1/2/3/4 daily goal" â€” used by the chain 1 "balanced"
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

/// Node ids whose completion counts as a "triple-or-higher" combo.
/// Consumed by `meta_content.dart`'s `triple_combo_25/100` objectives.
const tripleComboNodeIds = <ProgressionEntryId>[
  ProgressionEntryId('combo_balanced_step_3'),
  ProgressionEntryId('combo_balanced_finale'),
  ProgressionEntryId('combo_recovery_step_3'),
  ProgressionEntryId('combo_recovery_finale'),
  ProgressionEntryId('combo_nutrition_step_3'),
  ProgressionEntryId('combo_nutrition_step_4'),
  ProgressionEntryId('combo_nutrition_finale'),
];

/// All combo step objectives use `LifetimeScope()`. The metric
/// [TodayCompletionsAmongMetric] always reads `nodesCompletedToday`
/// regardless of scope, so the *value* (today's atoms) is unchanged;
/// the lifetime scope just makes the *completion event* once-and-done
/// (no per-period reset). That's the correct semantic for chain
/// progression â€” once step N is claimed it stays completed, and step
/// N+1 picks up tomorrow with a fresh today-atoms tally. Without
/// this, the resolver would treat each step as a per-day node and
/// the chain would never advance across days.
List<Objective> comboObjectives(EngineCatalogContext context) {
  return const [
    // â”€â”€ Chain 1: Balanced â€” any daily goal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Objective(
      id: const ObjectiveId('combo_balanced_step_1_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: const ObjectiveId('combo_balanced_step_2_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: const ObjectiveId('combo_balanced_step_3_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: const ObjectiveId('combo_balanced_finale_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _allDailyQuests),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    // â”€â”€ Chain 2: Recovery â€” sleep-anchored â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Objective(
      id: const ObjectiveId('combo_recovery_step_1_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_sleep_today')],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: const ObjectiveId('combo_recovery_step_2_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_sleep_today'), ProgressionEntryId('daily_steps_today')],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: const ObjectiveId('combo_recovery_step_3_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_sleep_today'),
          ProgressionEntryId('daily_steps_today'),
          ProgressionEntryId('daily_protein_today'),
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: const ObjectiveId('combo_recovery_finale_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_sleep_today'),
          ProgressionEntryId('daily_steps_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_calories_today'),
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    // â”€â”€ Chain 3: Nutrition â€” macro-anchored â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Objective(
      id: const ObjectiveId('combo_nutrition_step_1_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_calories_today')],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: const ObjectiveId('combo_nutrition_step_2_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_calories_today'), ProgressionEntryId('daily_protein_today')],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: const ObjectiveId('combo_nutrition_step_3_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_carbs_today'),
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: const ObjectiveId('combo_nutrition_step_4_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_carbs_today'),
          ProgressionEntryId('daily_fat_today'),
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    Objective(
      id: const ObjectiveId('combo_nutrition_finale_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_calories_today'),
          ProgressionEntryId('daily_protein_today'),
          ProgressionEntryId('daily_carbs_today'),
          ProgressionEntryId('daily_fat_today'),
          ProgressionEntryId('daily_fiber_today'),
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5,
    ),
  ];
}

List<ProgressionEntry> comboNodes() {
  return [
    // â”€â”€ Chain 1: Balanced â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    ComboStep(
      id: const ProgressionEntryId('combo_balanced_step_1'),
      objectiveId: ObjectiveId('combo_balanced_step_1_obj'),
      titleKey: (l) => l.progComboBalancedStep1Title,
      descriptionKey: (l) => l.progComboBalancedStep1Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 50)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_balanced'),
      chainOrder: 0,
      chainStepLabelKey: (_) => '1',
      nextNodeIds: const [ProgressionEntryId('combo_balanced_step_2')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_balanced_step_2'),
      objectiveId: ObjectiveId('combo_balanced_step_2_obj'),
      titleKey: (l) => l.progComboBalancedStep2Title,
      descriptionKey: (l) => l.progComboBalancedStep2Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 100)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_balanced'),
      chainOrder: 1,
      chainStepLabelKey: (_) => '2',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_balanced_step_1')],
      nextNodeIds: const [ProgressionEntryId('combo_balanced_step_3')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_balanced_step_3'),
      objectiveId: ObjectiveId('combo_balanced_step_3_obj'),
      titleKey: (l) => l.progComboBalancedStep3Title,
      descriptionKey: (l) => l.progComboBalancedStep3Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 150)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_balanced'),
      chainOrder: 2,
      chainStepLabelKey: (_) => '3',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_balanced_step_2')],
      nextNodeIds: const [ProgressionEntryId('combo_balanced_finale')],
    ),
    ComboFinale(
      id: const ProgressionEntryId('combo_balanced_finale'),
      objectiveId: ObjectiveId('combo_balanced_finale_obj'),
      titleKey: (l) => l.progComboBalancedFinaleTitle,
      descriptionKey: (l) => l.progComboBalancedFinaleDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 220)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_balanced'),
      chainOrder: 3,
      chainStepIcon: ChainStepIcon.comboFlag,
      prerequisiteNodeIds: const [ProgressionEntryId('combo_balanced_step_3')],
    ),
    // â”€â”€ Chain 2: Recovery (sleep-anchored) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    ComboStep(
      id: const ProgressionEntryId('combo_recovery_step_1'),
      objectiveId: ObjectiveId('combo_recovery_step_1_obj'),
      titleKey: (l) => l.progComboRecoveryStep1Title,
      descriptionKey: (l) => l.progComboRecoveryStep1Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 60)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_recovery'),
      chainOrder: 0,
      chainStepLabelKey: (_) => '1',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_balanced_finale')],
      nextNodeIds: const [ProgressionEntryId('combo_recovery_step_2')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_recovery_step_2'),
      objectiveId: ObjectiveId('combo_recovery_step_2_obj'),
      titleKey: (l) => l.progComboRecoveryStep2Title,
      descriptionKey: (l) => l.progComboRecoveryStep2Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 120)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_recovery'),
      chainOrder: 1,
      chainStepLabelKey: (_) => '2',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_recovery_step_1')],
      nextNodeIds: const [ProgressionEntryId('combo_recovery_step_3')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_recovery_step_3'),
      objectiveId: ObjectiveId('combo_recovery_step_3_obj'),
      titleKey: (l) => l.progComboRecoveryStep3Title,
      descriptionKey: (l) => l.progComboRecoveryStep3Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 180)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_recovery'),
      chainOrder: 2,
      chainStepLabelKey: (_) => '3',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_recovery_step_2')],
      nextNodeIds: const [ProgressionEntryId('combo_recovery_finale')],
    ),
    ComboFinale(
      id: const ProgressionEntryId('combo_recovery_finale'),
      objectiveId: ObjectiveId('combo_recovery_finale_obj'),
      titleKey: (l) => l.progComboRecoveryFinaleTitle,
      descriptionKey: (l) => l.progComboRecoveryFinaleDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 260)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_recovery'),
      chainOrder: 3,
      chainStepIcon: ChainStepIcon.comboFlag,
      prerequisiteNodeIds: const [ProgressionEntryId('combo_recovery_step_3')],
    ),
    // â”€â”€ Chain 3: Nutrition (macro-anchored, 5 steps) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    ComboStep(
      id: const ProgressionEntryId('combo_nutrition_step_1'),
      objectiveId: ObjectiveId('combo_nutrition_step_1_obj'),
      titleKey: (l) => l.progComboNutritionStep1Title,
      descriptionKey: (l) => l.progComboNutritionStep1Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 60)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_nutrition'),
      chainOrder: 0,
      chainStepLabelKey: (_) => '1',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_recovery_finale')],
      nextNodeIds: const [ProgressionEntryId('combo_nutrition_step_2')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_nutrition_step_2'),
      objectiveId: ObjectiveId('combo_nutrition_step_2_obj'),
      titleKey: (l) => l.progComboNutritionStep2Title,
      descriptionKey: (l) => l.progComboNutritionStep2Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 110)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_nutrition'),
      chainOrder: 1,
      chainStepLabelKey: (_) => '2',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_nutrition_step_1')],
      nextNodeIds: const [ProgressionEntryId('combo_nutrition_step_3')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_nutrition_step_3'),
      objectiveId: ObjectiveId('combo_nutrition_step_3_obj'),
      titleKey: (l) => l.progComboNutritionStep3Title,
      descriptionKey: (l) => l.progComboNutritionStep3Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 170)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_nutrition'),
      chainOrder: 2,
      chainStepLabelKey: (_) => '3',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_nutrition_step_2')],
      nextNodeIds: const [ProgressionEntryId('combo_nutrition_step_4')],
    ),
    ComboStep(
      id: const ProgressionEntryId('combo_nutrition_step_4'),
      objectiveId: ObjectiveId('combo_nutrition_step_4_obj'),
      titleKey: (l) => l.progComboNutritionStep4Title,
      descriptionKey: (l) => l.progComboNutritionStep4Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 230)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_nutrition'),
      chainOrder: 3,
      chainStepLabelKey: (_) => '4',
      prerequisiteNodeIds: const [ProgressionEntryId('combo_nutrition_step_3')],
      nextNodeIds: const [ProgressionEntryId('combo_nutrition_finale')],
    ),
    ComboFinale(
      id: const ProgressionEntryId('combo_nutrition_finale'),
      objectiveId: ObjectiveId('combo_nutrition_finale_obj'),
      titleKey: (l) => l.progComboNutritionFinaleTitle,
      descriptionKey: (l) => l.progComboNutritionFinaleDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 320)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
      chainId: ChainId('combo_nutrition'),
      chainOrder: 4,
      chainStepIcon: ChainStepIcon.comboFlag,
      prerequisiteNodeIds: const [ProgressionEntryId('combo_nutrition_step_4')],
    ),
  ];
}