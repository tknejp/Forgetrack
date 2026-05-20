import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../engine_catalog_context.dart';

/// Welcome flow — the first achievement the player ever unlocks
/// (no objective, no conditions) plus the "first reward" milestone
/// that fires after their first claimed grant.

List<Objective> welcomeObjectives(EngineCatalogContext context) {
  return const [
    Objective(
      id: const ObjectiveId('reward_count_1'),
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
  ];
}

List<ProgressionEntry> welcomeNodes() {
  return [
    Achievement(
      id: const ProgressionEntryId('welcome_to_journey'),
      // No objective, no conditions — fires on first evaluation.
      titleKey: (l) => l.progAchievementWelcomeToJourneyTitle,
      descriptionKey: (l) => l.progAchievementWelcomeToJourneyDesc,
      // Welcome ships a starter pack so the player has something to
      // equip on day one — the camp background + the pilgrim frame.
      // The pilgrim_emblem comes later from the Pilgrim Path chapter
      // finale; this is just the starter wardrobe.
      rewards: const [
        CosmeticReward(cosmeticId: CosmeticId('background_camp')),
        CosmeticReward(cosmeticId: CosmeticId('frame_pilgrim')),
      ],
      contentTags: const [ContentTag.core, ContentTag.cosmetics],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('first_reward'),
      objectiveId: ObjectiveId('reward_count_1'),
      badgeEmoji: '\u{1F3C6}',
      titleKey: (l) => l.progAchievementFirstRewardTitle,
      descriptionKey: (l) => l.progAchievementFirstRewardDesc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_campfire_spark'))],
      contentTags: const [ContentTag.core, ContentTag.cosmetics],
      rarity: Rarity.common,
    ),
  ];
}
