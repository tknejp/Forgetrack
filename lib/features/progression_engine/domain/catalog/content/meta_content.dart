import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';

/// Cross-domain meta achievements — total-XP milestones and
/// reward-count "reward hunter" mastery achievements. Mirrors V1:
/// `xp_100000`/`xp_1000000`, `reward_hunter_25`/`100`.

List<ObjectiveDefinition> metaObjectives(EngineCatalogContext context) {
  return const [
    ObjectiveDefinition(
      id: 'lifetime_xp_100k',
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100000,
    ),
    ObjectiveDefinition(
      id: 'lifetime_xp_1m',
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1000000,
    ),
    ObjectiveDefinition(
      id: 'reward_count_25',
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
    ObjectiveDefinition(
      id: 'reward_count_100',
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
  ];
}

List<ProgressionNode> metaNodes() {
  return [
    AchievementNode(
      id: 'xp_100000',
      objectiveId: 'lifetime_xp_100k',
      badgeEmoji: '\u{2728}',
      titleKey: (l) => l.progAchievementXp100000Title,
      descriptionKey: (l) => l.progAchievementXp100000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
    AchievementNode(
      id: 'xp_1000000',
      objectiveId: 'lifetime_xp_1m',
      badgeEmoji: '\u{1F31F}',
      titleKey: (l) => l.progAchievementXp1000000Title,
      descriptionKey: (l) => l.progAchievementXp1000000Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
    ),
    AchievementNode(
      id: 'reward_hunter_25',
      objectiveId: 'reward_count_25',
      badgeEmoji: '\u{2694}\u{FE0F}',
      titleKey: (l) => l.progAchievementRewardHunter25Title,
      descriptionKey: (l) => l.progAchievementRewardHunter25Desc,
      rewards: const [],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
    ),
    AchievementNode(
      id: 'reward_hunter_100',
      objectiveId: 'reward_count_100',
      badgeEmoji: '\u{2694}\u{FE0F}',
      titleKey: (l) => l.progAchievementRewardHunter100Title,
      descriptionKey: (l) => l.progAchievementRewardHunter100Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_bridge_key')],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
    ),
  ];
}
