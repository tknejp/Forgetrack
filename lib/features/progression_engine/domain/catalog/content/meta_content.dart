import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/quest_display_bucket.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import '../engine_catalog_context.dart';

/// Cross-domain meta achievements — total-XP milestones and
/// reward-count "reward hunter" mastery achievements. Mirrors V1:
/// `xp_100000`/`xp_1000000`, `reward_hunter_25`/`100`.

List<Objective> metaObjectives(EngineCatalogContext context) {
  return const [
    Objective(
      id: 'lifetime_xp_100k',
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100000,
    ),
    Objective(
      id: 'lifetime_xp_1m',
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1000000,
    ),
    Objective(
      id: 'reward_count_25',
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
    Objective(
      id: 'reward_count_100',
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
    // V1 → V2 ports (Phase 9c follow-up). Backing metrics live in
    // `objective_metric.dart` (QuestCompletionsByBucketMetric,
    // DistinctActiveDaysMetric); ledger aggregations live in
    // `progression_engine_provider.dart`.
    Objective(
      id: 'daily_quest_count_3',
      metric: QuestCompletionsByBucketMetric(bucket: QuestDisplayBucket.daily),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: 'daily_quest_count_7',
      metric: QuestCompletionsByBucketMetric(bucket: QuestDisplayBucket.daily),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
    ),
    Objective(
      id: 'quest_count_250',
      metric: QuestCompletionsByBucketMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 250,
    ),
    Objective(
      id: 'active_days_7',
      metric: DistinctActiveDaysMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
    ),
    Objective(
      id: 'active_days_90',
      metric: DistinctActiveDaysMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 90,
    ),
    // Combo-pool counters (Phase 9c follow-up).
    Objective(
      id: 'combo_pool_10',
      metric: ComboPoolCompletionsMetric(poolId: 'daily_combo_pool'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 10,
    ),
    // The triple-combo achievements count completions across every
    // combo chain step whose target is 3+ atoms — the new combo
    // shape spreads "3-of-N" wins across multiple chains, so we
    // enumerate them explicitly here.
    Objective(
      id: 'triple_combo_25',
      metric: LifetimeCompletionsAmongMetric(
        nodeIds: [
          'combo_balanced_step_3',
          'combo_balanced_finale',
          'combo_recovery_step_3',
          'combo_recovery_finale',
          'combo_nutrition_step_3',
          'combo_nutrition_step_4',
          'combo_nutrition_finale',
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
    Objective(
      id: 'triple_combo_100',
      metric: LifetimeCompletionsAmongMetric(
        nodeIds: [
          'combo_balanced_step_3',
          'combo_balanced_finale',
          'combo_recovery_step_3',
          'combo_recovery_finale',
          'combo_nutrition_step_3',
          'combo_nutrition_step_4',
          'combo_nutrition_finale',
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
  ];
}

List<ProgressionEntry> metaNodes() {
  return [
    Achievement(
      id: 'xp_100000',
      objectiveId: 'lifetime_xp_100k',
      badgeEmoji: '\u{2728}',
      titleKey: (l) => l.progAchievementXp100000Title,
      descriptionKey: (l) => l.progAchievementXp100000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'xp_1000000',
      objectiveId: 'lifetime_xp_1m',
      badgeEmoji: '\u{1F31F}',
      titleKey: (l) => l.progAchievementXp1000000Title,
      descriptionKey: (l) => l.progAchievementXp1000000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: 'reward_hunter_25',
      objectiveId: 'reward_count_25',
      badgeEmoji: '\u{2694}\u{FE0F}',
      titleKey: (l) => l.progAchievementRewardHunter25Title,
      descriptionKey: (l) => l.progAchievementRewardHunter25Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: 'reward_hunter_100',
      objectiveId: 'reward_count_100',
      badgeEmoji: '\u{2694}\u{FE0F}',
      titleKey: (l) => l.progAchievementRewardHunter100Title,
      descriptionKey: (l) => l.progAchievementRewardHunter100Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_bridge_key')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    // V1 → V2 ports (Phase 9c follow-up). Relic ids are already
    // authored in `cosmetic_catalog.dart`; this is the missing
    // achievement→relic wiring.
    Achievement(
      id: 'daily_quest_3',
      objectiveId: 'daily_quest_count_3',
      badgeEmoji: '\u{1F525}', // fire
      titleKey: (l) => l.progAchievementDailyQuest3Title,
      descriptionKey: (l) => l.progAchievementDailyQuest3Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_warm_kindling')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
    ),
    Achievement(
      id: 'daily_quest_7',
      objectiveId: 'daily_quest_count_7',
      badgeEmoji: '\u{1F33F}', // herb
      titleKey: (l) => l.progAchievementDailyQuest7Title,
      descriptionKey: (l) => l.progAchievementDailyQuest7Desc,
      // Relic reward moved to `active_days_90` so the Cave Lynx (lvl 55)
      // unlock pair lands in the right difficulty band rather than week one.
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: 'quest_hunter_250',
      objectiveId: 'quest_count_250',
      badgeEmoji: '\u{1F3F9}', // bow
      titleKey: (l) => l.progAchievementQuestHunter250Title,
      descriptionKey: (l) => l.progAchievementQuestHunter250Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_frozen_lake_heart')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'active_days_7',
      objectiveId: 'active_days_7',
      badgeEmoji: '\u{1F319}', // moon
      titleKey: (l) => l.progAchievementActiveDays7Title,
      descriptionKey: (l) => l.progAchievementActiveDays7Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_moonlit_foxglove')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: 'active_days_90',
      objectiveId: 'active_days_90',
      badgeEmoji: '\u{1F33F}', // herb — re-uses motif from daily_quest_7
      titleKey: (l) => l.progAchievementActiveDays90Title,
      descriptionKey: (l) => l.progAchievementActiveDays90Desc,
      // Sources relic_wildwood_charm — mid-game (~3 months) ingredient for
      // the Cave Lynx (lvl 55) companion pair.
      rewards: const [CosmeticReward(cosmeticId: 'relic_wildwood_charm')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    // Combo achievements (Phase 9c follow-up). Backing infra:
    // ComboPoolCompletionsMetric for the lifetime "all combos" tally,
    // LifetimeCompletionsAmongMetric for the triple-or-higher tally
    // (triple_win + four_pillars). dragonrock_trial composes three
    // existing objectives via unlockConditions since Achievement
    // supports condition-only completion (`objectiveId: null`).
    Achievement(
      id: 'combo_victory_10',
      objectiveId: 'combo_pool_10',
      badgeEmoji: '\u{2728}', // sparkles
      titleKey: (l) => l.progAchievementComboVictory10Title,
      descriptionKey: (l) => l.progAchievementComboVictory10Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_oathbound_mark')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: 'combo_triple_victory_25',
      objectiveId: 'triple_combo_25',
      badgeEmoji: '\u{1F3AF}', // direct hit
      titleKey: (l) => l.progAchievementComboTripleVictory25Title,
      descriptionKey: (l) => l.progAchievementComboTripleVictory25Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_miners_lantern')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'combo_triple_victory_100',
      objectiveId: 'triple_combo_100',
      badgeEmoji: '\u{1F3C6}', // trophy
      titleKey: (l) => l.progAchievementComboTripleVictory100Title,
      descriptionKey: (l) => l.progAchievementComboTripleVictory100Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_summit_feather')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: 'dragonrock_trial',
      // Condition-only: AND of level + quest count + lifetime steps.
      objectiveId: null,
      unlockConditions: const [
        LevelAtLeast(100),
        ObjectiveCompleted('quest_count_250'),
        ObjectiveCompleted('lifetime_steps_10m'),
      ],
      badgeEmoji: '\u{1F409}', // dragon
      titleKey: (l) => l.progAchievementDragonrockTrialTitle,
      descriptionKey: (l) => l.progAchievementDragonrockTrialDesc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_dragonrock_heart')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.mythic,
    ),
  ];
}
