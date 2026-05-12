import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';

/// Welcome flow — the first achievement the player ever unlocks
/// (no objective, no conditions) plus the "first reward" milestone
/// that fires after their first claimed grant.

List<ObjectiveDefinition> welcomeObjectives(EngineCatalogContext context) {
  return const [
    ObjectiveDefinition(
      id: 'reward_count_1',
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
  ];
}

List<ProgressionNode> welcomeNodes() {
  return [
    AchievementNode(
      id: 'welcome_to_journey',
      // No objective, no conditions — fires on first evaluation.
      titleKey: (l) => l.progAchievementWelcomeToJourneyTitle,
      descriptionKey: (l) => l.progAchievementWelcomeToJourneyDesc,
      // Welcome ships a starter pack so the player has something to
      // equip on day one — the camp background + the pilgrim frame.
      // The pilgrim_emblem comes later from the Pilgrim Path chapter
      // finale; this is just the starter wardrobe.
      rewards: const [
        CosmeticReward(cosmeticId: 'background_camp'),
        CosmeticReward(cosmeticId: 'frame_pilgrim'),
      ],
      contentTags: const [ContentTag.core, ContentTag.cosmetics],
      rarity: Rarity.common,
    ),
    AchievementNode(
      id: 'first_reward',
      objectiveId: 'reward_count_1',
      badgeEmoji: '\u{1F3C6}',
      titleKey: (l) => l.progAchievementFirstRewardTitle,
      descriptionKey: (l) => l.progAchievementFirstRewardDesc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_campfire_spark')],
      contentTags: const [ContentTag.core, ContentTag.cosmetics],
      rarity: Rarity.common,
    ),
  ];
}
