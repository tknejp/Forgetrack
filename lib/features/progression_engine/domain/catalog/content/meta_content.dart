import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import '../engine_catalog_context.dart';

/// Cross-domain meta achievements — total-XP milestones and
/// reward-count "reward hunter" mastery achievements. Mirrors V1:
/// `xp_100000`/`xp_1000000`, `reward_hunter_25`/`100`.

List<Objective> metaObjectives(EngineCatalogContext context) {
  return const [
    Objective(
      id: const ObjectiveId('lifetime_xp_100k'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100000,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_1m'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1000000,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_5m'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5000000,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_10m'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 10000000,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_24m'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      // Level 100 cap (~24M XP).
      targetValue: 24000000,
    ),
    Objective(
      id: const ObjectiveId('reward_count_25'),
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
    Objective(
      id: const ObjectiveId('reward_count_100'),
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
      id: const ObjectiveId('daily_quest_count_3'),
      metric: QuestCompletionsByBucketMetric(bucket: QuestDisplayBucket.daily),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: const ObjectiveId('daily_quest_count_7'),
      metric: QuestCompletionsByBucketMetric(bucket: QuestDisplayBucket.daily),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
    ),
    Objective(
      id: const ObjectiveId('quest_count_250'),
      metric: QuestCompletionsByBucketMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 250,
    ),
    Objective(
      id: const ObjectiveId('active_days_7'),
      metric: DistinctActiveDaysMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
    ),
    Objective(
      id: const ObjectiveId('active_days_90'),
      metric: DistinctActiveDaysMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 90,
    ),
    Objective(
      id: const ObjectiveId('active_days_365'),
      metric: DistinctActiveDaysMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 365,
    ),
    // Combo-pool counters (Phase 9c follow-up).
    Objective(
      id: const ObjectiveId('combo_pool_10'),
      metric: ComboPoolCompletionsMetric(poolId: ComboPoolId('daily_combo_pool')),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 10,
    ),
    // The triple-combo achievements count completions across every
    // combo chain step whose target is 3+ atoms — the new combo
    // shape spreads "3-of-N" wins across multiple chains, so we
    // enumerate them explicitly here.
    Objective(
      id: const ObjectiveId('triple_combo_25'),
      metric: LifetimeCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('combo_balanced_step_3'),
          ProgressionEntryId('combo_balanced_finale'),
          ProgressionEntryId('combo_recovery_step_3'),
          ProgressionEntryId('combo_recovery_finale'),
          ProgressionEntryId('combo_nutrition_step_3'),
          ProgressionEntryId('combo_nutrition_step_4'),
          ProgressionEntryId('combo_nutrition_finale'),
        ],
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
    Objective(
      id: const ObjectiveId('triple_combo_100'),
      metric: LifetimeCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('combo_balanced_step_3'),
          ProgressionEntryId('combo_balanced_finale'),
          ProgressionEntryId('combo_recovery_step_3'),
          ProgressionEntryId('combo_recovery_finale'),
          ProgressionEntryId('combo_nutrition_step_3'),
          ProgressionEntryId('combo_nutrition_step_4'),
          ProgressionEntryId('combo_nutrition_finale'),
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
      id: const ProgressionEntryId('xp_100000'),
      objectiveId: ObjectiveId('lifetime_xp_100k'),
      badgeEmoji: '\u{2728}',
      titleKey: (l) => l.progAchievementXp100000Title,
      descriptionKey: (l) => l.progAchievementXp100000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('xp_1000000'),
      objectiveId: ObjectiveId('lifetime_xp_1m'),
      badgeEmoji: '\u{1F31F}',
      titleKey: (l) => l.progAchievementXp1000000Title,
      descriptionKey: (l) => l.progAchievementXp1000000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: const ProgressionEntryId('xp_5000000'),
      objectiveId: ObjectiveId('lifetime_xp_5m'),
      badgeEmoji: '\u{1F320}',
      titleKey: (l) => l.progAchievementXp5000000Title,
      descriptionKey: (l) => l.progAchievementXp5000000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('xp_10000000'),
      objectiveId: ObjectiveId('lifetime_xp_10m'),
      badgeEmoji: '\u{2604}\u{FE0F}',
      titleKey: (l) => l.progAchievementXp10000000Title,
      descriptionKey: (l) => l.progAchievementXp10000000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: const ProgressionEntryId('xp_24000000'),
      objectiveId: ObjectiveId('lifetime_xp_24m'),
      badgeEmoji: '\u{1F30C}',
      titleKey: (l) => l.progAchievementXp24000000Title,
      descriptionKey: (l) => l.progAchievementXp24000000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.mythic,
    ),
    Achievement(
      id: const ProgressionEntryId('reward_hunter_25'),
      objectiveId: ObjectiveId('reward_count_25'),
      badgeEmoji: '\u{2694}\u{FE0F}',
      titleKey: (l) => l.progAchievementRewardHunter25Title,
      descriptionKey: (l) => l.progAchievementRewardHunter25Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: const ProgressionEntryId('reward_hunter_100'),
      objectiveId: ObjectiveId('reward_count_100'),
      badgeEmoji: '\u{2694}\u{FE0F}',
      titleKey: (l) => l.progAchievementRewardHunter100Title,
      descriptionKey: (l) => l.progAchievementRewardHunter100Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_bridge_key'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    // V1 → V2 ports (Phase 9c follow-up). Relic ids are already
    // authored in `cosmetic_catalog.dart`; this is the missing
    // achievement→relic wiring.
    Achievement(
      id: const ProgressionEntryId('daily_quest_3'),
      objectiveId: ObjectiveId('daily_quest_count_3'),
      badgeEmoji: '\u{1F525}', // fire
      titleKey: (l) => l.progAchievementDailyQuest3Title,
      descriptionKey: (l) => l.progAchievementDailyQuest3Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_warm_kindling'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('daily_quest_7'),
      objectiveId: ObjectiveId('daily_quest_count_7'),
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
      id: const ProgressionEntryId('quest_hunter_250'),
      objectiveId: ObjectiveId('quest_count_250'),
      badgeEmoji: '\u{1F3F9}', // bow
      titleKey: (l) => l.progAchievementQuestHunter250Title,
      descriptionKey: (l) => l.progAchievementQuestHunter250Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_frozen_lake_heart'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('active_days_7'),
      objectiveId: ObjectiveId('active_days_7'),
      badgeEmoji: '\u{1F319}', // moon
      titleKey: (l) => l.progAchievementActiveDays7Title,
      descriptionKey: (l) => l.progAchievementActiveDays7Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_moonlit_foxglove'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: const ProgressionEntryId('active_days_90'),
      objectiveId: ObjectiveId('active_days_90'),
      badgeEmoji: '\u{1F33F}', // herb — re-uses motif from daily_quest_7
      titleKey: (l) => l.progAchievementActiveDays90Title,
      descriptionKey: (l) => l.progAchievementActiveDays90Desc,
      // Sources relic_wildwood_charm — mid-game (~3 months) ingredient for
      // the Cave Lynx (lvl 55) companion pair.
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_wildwood_charm'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: const ProgressionEntryId('active_days_365'),
      objectiveId: ObjectiveId('active_days_365'),
      badgeEmoji: '\u{1F305}',
      titleKey: (l) => l.progAchievementActiveDays365Title,
      descriptionKey: (l) => l.progAchievementActiveDays365Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
    ),
    // Combo achievements (Phase 9c follow-up). Backing infra:
    // ComboPoolCompletionsMetric for the lifetime "all combos" tally,
    // LifetimeCompletionsAmongMetric for the triple-or-higher tally
    // (triple_win + four_pillars). dragonrock_trial composes three
    // existing objectives via unlockConditions since Achievement
    // supports condition-only completion (`objectiveId: null`).
    Achievement(
      id: const ProgressionEntryId('combo_victory_10'),
      objectiveId: ObjectiveId('combo_pool_10'),
      badgeEmoji: '\u{2728}', // sparkles
      titleKey: (l) => l.progAchievementComboVictory10Title,
      descriptionKey: (l) => l.progAchievementComboVictory10Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_oathbound_mark'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: const ProgressionEntryId('combo_triple_victory_25'),
      objectiveId: ObjectiveId('triple_combo_25'),
      badgeEmoji: '\u{1F3AF}', // direct hit
      titleKey: (l) => l.progAchievementComboTripleVictory25Title,
      descriptionKey: (l) => l.progAchievementComboTripleVictory25Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_miners_lantern'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('combo_triple_victory_100'),
      objectiveId: ObjectiveId('triple_combo_100'),
      badgeEmoji: '\u{1F3C6}', // trophy
      titleKey: (l) => l.progAchievementComboTripleVictory100Title,
      descriptionKey: (l) => l.progAchievementComboTripleVictory100Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_summit_feather'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: const ProgressionEntryId('chapter_completionist'),
      // Condition-only: AND of every main-chain chapter finale being
      // completed (claimed). Side quests intentionally excluded — this
      // tracks the canonical journey.
      objectiveId: null,
      unlockConditions: const [
        NodeCompleted(ProgressionEntryId('pilgrim_path_finale')),
        NodeCompleted(ProgressionEntryId('forest_trial_finale')),
        NodeCompleted(ProgressionEntryId('ruins_discipline_finale')),
        NodeCompleted(ProgressionEntryId('mine_descent_finale')),
        NodeCompleted(ProgressionEntryId('forge_momentum_finale')),
        NodeCompleted(ProgressionEntryId('underway_pact_finale')),
        NodeCompleted(ProgressionEntryId('frostbound_oath_finale')),
        NodeCompleted(ProgressionEntryId('icewalker_route_finale')),
        NodeCompleted(ProgressionEntryId('mountain_ascent_finale')),
        NodeCompleted(ProgressionEntryId('dragonroad_finale')),
        NodeCompleted(ProgressionEntryId('dragonrock_sovereign_finale')),
      ],
      badgeEmoji: '\u{1F4DC}', // scroll
      titleKey: (l) => l.progAchievementChapterCompletionistTitle,
      descriptionKey: (l) => l.progAchievementChapterCompletionistDesc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.mythic,
    ),
    Achievement(
      id: const ProgressionEntryId('dragonrock_trial'),
      // Condition-only: AND of level + quest count + lifetime steps.
      objectiveId: null,
      unlockConditions: const [
        LevelAtLeast(100),
        ObjectiveCompleted(ObjectiveId('quest_count_250')),
        ObjectiveCompleted(ObjectiveId('lifetime_steps_10m')),
      ],
      badgeEmoji: '\u{1F409}', // dragon
      titleKey: (l) => l.progAchievementDragonrockTrialTitle,
      descriptionKey: (l) => l.progAchievementDragonrockTrialDesc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_dragonrock_heart'))],
      contentTags: const [ContentTag.core],
      rarity: Rarity.mythic,
    ),
  ];
}
