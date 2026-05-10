import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/quest_display_bucket.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';

/// Activity domain — daily 30-minute quest, weekly minutes quest, and
/// the per-rule "weekly warrior" reward-count achievements. Mirrors
/// V1: rules daily_activity / weekly_activity, achievements
/// weekly_activity_mastery / _4 / _12 / _24 / _52.

const double _dailyActivityTargetMinutes = 30;

List<ObjectiveDefinition> activityObjectives(EngineCatalogContext context) {
  final goals = context.goals;
  return [
    const ObjectiveDefinition(
      id: 'daily_activity',
      metric: ActivityMinutesMetric(),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: _dailyActivityTargetMinutes,
    ),
    ObjectiveDefinition(
      id: 'weekly_activity',
      metric: const ActivityMinutesMetric(),
      scope: const ThisWeekScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: goals.weeklyActivityMinutes.toDouble(),
    ),
    const ObjectiveDefinition(
      id: 'reward_count_weekly_activity_1',
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    const ObjectiveDefinition(
      id: 'reward_count_weekly_activity_4',
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
    const ObjectiveDefinition(
      id: 'reward_count_weekly_activity_12',
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 12,
    ),
    const ObjectiveDefinition(
      id: 'reward_count_weekly_activity_24',
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 24,
    ),
    const ObjectiveDefinition(
      id: 'reward_count_weekly_activity_52',
      metric: RewardCountMetric(ruleId: 'weekly_activity'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 52,
    ),
  ];
}

List<ProgressionNode> activityNodes() {
  return [
    QuestNode(
      id: 'daily_activity_today',
      objectiveId: 'daily_activity',
      displayBucket: QuestDisplayBucket.daily,
      titleKey: (l) => l.activitiesActiveMins,
      descriptionKey: (l) => l.activitiesActiveMins,
      rewards: const [XpReward(amount: 50)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    QuestNode(
      id: 'weekly_activity',
      objectiveId: 'weekly_activity',
      displayBucket: QuestDisplayBucket.weekly,
      titleKey: (l) => l.progRuleWeeklyActivity,
      descriptionKey: (l) => l.progRuleWeeklyActivityDesc,
      rewards: const [XpReward(amount: 120)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    AchievementNode(
      id: 'weekly_activity_mastery',
      objectiveId: 'reward_count_weekly_activity_1',
      badgeEmoji: '\u{1F3CB}',
      titleKey: (l) => l.progAchievementWeeklyWarriorTitle,
      descriptionKey: (l) => l.progAchievementWeeklyWarriorDesc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_ancient_root')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    AchievementNode(
      id: 'weekly_activity_4',
      objectiveId: 'reward_count_weekly_activity_4',
      badgeEmoji: '\u{1F3CC}',
      titleKey: (l) => l.progAchievementWeeklyActivity4Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity4Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_ashen_omen')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    AchievementNode(
      id: 'weekly_activity_12',
      objectiveId: 'reward_count_weekly_activity_12',
      badgeEmoji: '\u{1F3C3}',
      titleKey: (l) => l.progAchievementWeeklyActivity12Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity12Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    AchievementNode(
      id: 'weekly_activity_24',
      objectiveId: 'reward_count_weekly_activity_24',
      badgeEmoji: '\u{1F938}',
      titleKey: (l) => l.progAchievementWeeklyActivity24Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity24Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_polar_lantern')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    AchievementNode(
      id: 'weekly_activity_52',
      objectiveId: 'reward_count_weekly_activity_52',
      badgeEmoji: '\u{1F9D7}',
      titleKey: (l) => l.progAchievementWeeklyActivity52Title,
      descriptionKey: (l) => l.progAchievementWeeklyActivity52Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_stormcrest_plume')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
  ];
}
