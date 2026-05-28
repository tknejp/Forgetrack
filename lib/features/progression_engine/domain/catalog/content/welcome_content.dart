import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
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
/// (no objective, no conditions) plus the "first daily goal" milestone
/// that grants the campfire-spark relic after the player completes
/// their first DailyGoal claim.

List<Objective> welcomeObjectives(EngineCatalogContext context) {
  return const [
    // Counts only [DailyGoal] completions — the `daily` bucket is
    // exclusive to that node type, so chapter openers / steps /
    // finales (which auto-claim XP on level-up) can't satisfy it.
    // Earlier shape (`RewardCountMetric() ≥ 1`) tripped on the
    // pilgrim_path_open auto-claim and unlocked the relic on fresh
    // install before the player did anything.
    Objective(
      id: ObjectiveId('daily_goal_complete_1'),
      metric: QuestCompletionsByBucketMetric(bucket: QuestDisplayBucket.daily),
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
      // equip on day one — the camp background, the pilgrim frame,
      // and the pilgrim tier title banner (visible on the social
      // profile header). The pilgrim_emblem comes later from the
      // Pilgrim Path chapter finale; this is just the starter wardrobe.
      rewards: const [
        CosmeticReward(cosmeticId: CosmeticId('background_camp')),
        CosmeticReward(cosmeticId: CosmeticId('frame_pilgrim')),
        CosmeticReward(cosmeticId: CosmeticId('banner_pilgrim')),
      ],
      contentTags: const [ContentTag.core, ContentTag.cosmetics],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('first_daily_goal'),
      objectiveId: ObjectiveId('daily_goal_complete_1'),
      badgeEmoji: '\u{1F3C6}',
      titleKey: (l) => l.progAchievementFirstDailyGoalTitle,
      descriptionKey: (l) => l.progAchievementFirstDailyGoalDesc,
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_campfire_spark'))],
      contentTags: const [ContentTag.core, ContentTag.cosmetics],
      rarity: Rarity.common,
    ),
  ];
}
