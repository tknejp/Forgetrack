import '../../../../../shared/domain/rarity.dart';
import '../../models/claim_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/quest_display_bucket.dart';
import '../../models/reward_definition.dart';
import 'quest_assets.dart';

/// Long-term goals — the "DLOUHODOBÉ CÍLE" section in the V2 quests
/// screen. Quests live in [QuestDisplayBucket.longTerm] and either
/// stand alone (welcome milestone, XP totals) or chain via
/// [QuestNode.prerequisiteNodeIds] / [QuestNode.nextNodeIds].
///
/// Pilot port from the V1 monolith — three representative chains
/// (welcome, step streaks, XP totals). Other long-term quests
/// (sleep totals, weekly mastery, lifetime steps) follow the same
/// pattern as the catalog grows.

List<ObjectiveDefinition> longTermObjectives() {
  return const [
    ObjectiveDefinition(
      id: 'earn_first_reward_objective',
      domain: ProgressionDomain.activity,
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      debugLabel: 'Earn first reward — total reward grants >= 1',
    ),
    ObjectiveDefinition(
      id: 'steps_streak_7_quest_objective',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
      debugLabel: 'Steps streak 7 — best daily_steps streak >= 7',
    ),
    ObjectiveDefinition(
      id: 'steps_streak_30_quest_objective',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
      debugLabel: 'Steps streak 30 — best daily_steps streak >= 30',
    ),
    ObjectiveDefinition(
      id: 'reach_500_xp_objective',
      domain: ProgressionDomain.activity,
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 500,
      debugLabel: 'Reach 500 XP — total XP >= 500',
    ),
    ObjectiveDefinition(
      id: 'reach_2000_xp_objective',
      domain: ProgressionDomain.activity,
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2000,
      debugLabel: 'Reach 2000 XP — total XP >= 2000',
    ),
  ];
}

List<ProgressionNode> longTermNodes() {
  return [
    QuestNode(
      id: 'earn_first_reward',
      objectiveId: 'earn_first_reward_objective',
      displayBucket: QuestDisplayBucket.longTerm,
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestEarnFirstRewardTitle,
      descriptionKey: (l) => l.progQuestEarnFirstRewardDesc,
      rewards: const [XpReward(amount: 80)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetActivity,
      sortOrder: 10,
    ),
    QuestNode(
      id: 'steps_streak_7_quest',
      objectiveId: 'steps_streak_7_quest_objective',
      displayBucket: QuestDisplayBucket.longTerm,
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestStepsStreak7Title,
      descriptionKey: (l) => l.progQuestStepsStreak7Desc,
      rewards: const [XpReward(amount: 180)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetStreak,
      chainId: 'steps_streak',
      chainOrder: 0,
      displayGroupId: 'steps_streak',
      nextNodeIds: const ['steps_streak_30_quest'],
      chainStepLabelKey: (_) => '7',
      sortOrder: 20,
    ),
    QuestNode(
      id: 'steps_streak_30_quest',
      objectiveId: 'steps_streak_30_quest_objective',
      displayBucket: QuestDisplayBucket.longTerm,
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestStepsStreak30Title,
      descriptionKey: (l) => l.progQuestStepsStreak30Desc,
      rewards: const [XpReward(amount: 420)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
      assetKey: questAssetStreak,
      chainId: 'steps_streak',
      chainOrder: 1,
      displayGroupId: 'steps_streak',
      prerequisiteNodeIds: const ['steps_streak_7_quest'],
      chainStepLabelKey: (_) => '30',
      sortOrder: 21,
    ),
    QuestNode(
      id: 'reach_500_xp',
      objectiveId: 'reach_500_xp_objective',
      displayBucket: QuestDisplayBucket.longTerm,
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach500XpTitle,
      descriptionKey: (l) => l.progQuestReach500XpDesc,
      rewards: const [XpReward(amount: 120)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetActivity,
      chainId: 'xp_milestones',
      chainOrder: 0,
      displayGroupId: 'xp_milestones',
      nextNodeIds: const ['reach_2000_xp'],
      chainStepLabelKey: (_) => '500',
      sortOrder: 30,
    ),
    QuestNode(
      id: 'reach_2000_xp',
      objectiveId: 'reach_2000_xp_objective',
      displayBucket: QuestDisplayBucket.longTerm,
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach2000XpTitle,
      descriptionKey: (l) => l.progQuestReach2000XpDesc,
      rewards: const [XpReward(amount: 220)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetActivity,
      chainId: 'xp_milestones',
      chainOrder: 1,
      displayGroupId: 'xp_milestones',
      prerequisiteNodeIds: const ['reach_500_xp'],
      chainStepLabelKey: (_) => '2K',
      sortOrder: 31,
    ),
  ];
}
