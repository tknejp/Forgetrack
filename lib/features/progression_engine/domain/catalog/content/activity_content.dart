import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// Activity domain — daily minute quest, weekly minutes quest, and
/// the per-rule "weekly warrior" reward-count achievements. Mirrors
/// V1: rules daily_activity / weekly_activity, achievements
/// weekly_activity_mastery / _4 / _12 / _24 / _52.

List<Objective> activityObjectives(EngineCatalogContext context) {
  final goals = context.goals;
  return [
    Objective(
      id: const ObjectiveId('daily_activity'),
      domain: ProgressionDomain.activity,
      metric: const ActivityMinutesMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: goals.dailyActivityMinutes.toDouble(),
    ),
    Objective(
      id: const ObjectiveId('weekly_activity'),
      domain: ProgressionDomain.activity,
      metric: const ActivityMinutesMetric(),
      scope: const ThisWeekScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: goals.weeklyActivityMinutes.toDouble(),
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_1'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_4'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_12'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 12,
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_24'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 24,
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_36'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 36,
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_52'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 52,
    ),
    const Objective(
      id: ObjectiveId('reward_count_weekly_activity_104'),
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 104,
    ),
  ];
}

List<ProgressionEntry> activityNodes() {
  return [
    DailyGoal(
      id: const ProgressionEntryId('daily_activity_today'),
      objectiveId: ObjectiveId('daily_activity'),
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.activitiesActiveMins,
      titleKey: (l) => l.activitiesActiveMins,
      descriptionKey: (l) => l.progRuleDailyActivityHintedDesc,
      // Base 50 XP, +50 bonus when claimed before 12:00 (morning).
      rewards: const [
        XpReward(
          sourceKind: RewardSourceKind.activityXp,
          streakDomain: ProgressionDomain.activity,
          amount: 50,
        ),
        BonusXpReward(
          sourceKind: RewardSourceKind.activityXp,
          streakDomain: ProgressionDomain.activity,
          amount: 50,
          condition: CompletedBeforeHour(12),
        ),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetActivity,
    ),
    WeeklyQuest(
      id: const ProgressionEntryId('weekly_activity'),
      objectiveId: ObjectiveId('weekly_activity'),
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleWeeklyActivityDesc,
      titleKey: (l) => l.progRuleWeeklyActivity,
      descriptionKey: (l) => l.progRuleWeeklyActivityDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 120)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
      assetKey: questAssetActivity,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_mastery'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_1'),
      badgeEmoji: '\u{1F3CB}',
      titleKey: (l) => l.progAchievementWeeklyWarriorTitle,
      descriptionKey: (l) => l.progAchievementWeeklyWarriorDesc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_ancient_root'))],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_4'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_4'),
      badgeEmoji: '\u{1F3CC}',
      titleKey: (l) => l.progAchievementWeeklyActivity4Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity4Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_ashen_omen'))],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_12'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_12'),
      badgeEmoji: '\u{1F3C3}',
      titleKey: (l) => l.progAchievementWeeklyActivity12Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity12Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_24'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_24'),
      badgeEmoji: '\u{1F938}',
      titleKey: (l) => l.progAchievementWeeklyActivity24Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity24Desc,
      // Relic relocated to `sleep_total_1000h` so the Aurora Stag
      // (lvl 65) sleep-buff companion sources its lantern from a
      // sleep grind. This milestone stays as a badge-only milestone.
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_36'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_36'),
      badgeEmoji: '\u{2744}\u{FE0F}', // snowflake
      titleKey: (l) => l.progAchievementWeeklyActivity36Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity36Desc,
      // Sources relic_aurora_thread — ~9 months of consistent weekly
      // activity, the Aurora Stag (lvl 65) ingredient.
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_aurora_thread'))],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_52'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_52'),
      badgeEmoji: '\u{1F9D7}',
      titleKey: (l) => l.progAchievementWeeklyActivity52Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity52Desc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_stormcrest_plume'))],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: const ProgressionEntryId('weekly_activity_104'),
      objectiveId: ObjectiveId('reward_count_weekly_activity_104'),
      badgeEmoji: '\u{1F3D4}\u{FE0F}',
      titleKey: (l) => l.progAchievementWeeklyActivity104Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity104Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.mythic,
    ),
  ];
}
