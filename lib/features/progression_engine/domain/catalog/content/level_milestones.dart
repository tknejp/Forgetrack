import '../../../../progression/domain/policy/level_config.dart';
import '../../../../progression/domain/policy/level_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import '../engine_catalog_context.dart';

/// Level milestone nodes — one per `kProgressionLevelTiers` entry
/// (excluding the level-1 origin) plus the four decorative levels
/// (35, 45, 75, 95) that carry their own cosmetic drops.
///
/// Mirrors V1's behaviour where level-up cosmetics dispatch through
/// the cosmetic dispatcher's level-catch-up pass, except the V2 model
/// makes the level milestones first-class nodes that go through the
/// regular completion → reward grant pipeline.
///
/// Each tier also gets a paired XP-threshold objective so a future
/// "level achievement" view (separate from the milestone) can hook
/// into the same data without re-inventing the threshold table.

List<ObjectiveDefinition> levelMilestoneObjectives(
  EngineCatalogContext context,
) {
  return [
    for (final tier in kProgressionLevelTiers.where((t) => t.level > 1))
      ObjectiveDefinition(
        id: 'level_xp_${tier.level}',
        metric: const TotalXpMetric(),
        scope: const LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue:
            const ProgressionLevelPolicy().xpRequiredForLevel(tier.level).toDouble(),
      ),
  ];
}

List<ProgressionNode> levelMilestoneNodes() {
  return [
    // Tier-anchored level milestones (5, 10, 15, 20, 25, 30, 40, 50,
    // 60, 70, 80, 90, 100).
    for (final tier in kProgressionLevelTiers.where((t) => t.level > 1))
      LevelMilestoneNode(
        id: 'level_${tier.level}',
        level: tier.level,
        emoji: tier.emoji,
        titleKey: tier.title,
        descriptionKey: (l) => l.progLevelAchievementDesc(tier.level),
        rewards: [
          for (final cosmeticId in tier.cosmeticRewards)
            CosmeticReward(cosmeticId: cosmeticId),
        ],
        unlockConditions: [LevelAtLeast(tier.level)],
        isTitleBreakpoint: tier.isTitleBreakpoint,
        isJourneyMapAnchor: tier.isJourneyMapAnchor,
        contentTags: const [ContentTag.core, ContentTag.journey],
        rarity: tier.rarity,
      ),
    // Decorative-level milestones (35, 45, 75, 95) — V1 dispatches
    // their cosmetics from the kProgressionDecorativeLevelCosmetics
    // map; V2 mirrors them as proper nodes so the engine grants
    // through the same path.
    for (final entry in kProgressionDecorativeLevelCosmetics.entries)
      LevelMilestoneNode(
        id: 'level_${entry.key}',
        level: entry.key,
        emoji: kProgressionDecorativeLevelEmoji[entry.key] ?? '',
        titleKey: tierForLevel(entry.key).title,
        descriptionKey: (l) => l.progLevelAchievementDesc(entry.key),
        rewards: [
          for (final cosmeticId in entry.value)
            CosmeticReward(cosmeticId: cosmeticId),
        ],
        unlockConditions: [LevelAtLeast(entry.key)],
        isJourneyMapAnchor: false,
        contentTags: const [ContentTag.core, ContentTag.cosmetics],
        rarity: tierForLevel(entry.key).rarity,
      ),
  ];
}
