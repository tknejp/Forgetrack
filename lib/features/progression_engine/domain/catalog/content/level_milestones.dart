import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import '../../policy/level_policy.dart';
import '../engine_catalog_context.dart';
import '../level_milestone_specs.dart';

/// Level milestone nodes — one per [kLevelMilestones] entry except the
/// level-1 origin. Each tier-anchor + decorative cosmetic level becomes
/// a first-class node so the engine grants cosmetics through the regular
/// completion → reward grant pipeline.
///
/// Each tier also gets a paired XP-threshold objective so a future
/// "level achievement" view (separate from the milestone) can hook
/// into the same data without re-inventing the threshold table.

List<Objective> levelMilestoneObjectives(
  EngineCatalogContext context,
) {
  return [
    for (final spec in kLevelMilestones.where((s) => s.level > 1))
      Objective(
        id: 'level_xp_${spec.level}',
        metric: const TotalXpMetric(),
        scope: const LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: const ProgressionLevelPolicy()
            .xpRequiredForLevel(spec.level)
            .toDouble(),
      ),
  ];
}

List<ProgressionEntry> levelMilestones() {
  return [
    for (final spec in kLevelMilestones.where((s) => s.level > 1))
      LevelMilestone(
        id: 'level_${spec.level}',
        level: spec.level,
        emoji: spec.emoji,
        titleKey: spec.titleKey,
        descriptionKey: (l) => l.progLevelAchievementDesc(spec.level),
        rewards: [
          for (final cosmeticId in spec.cosmeticRewardIds)
            CosmeticReward(cosmeticId: cosmeticId),
        ],
        unlockConditions: [LevelAtLeast(spec.level)],
        isTitleBreakpoint: spec.isTitleBreakpoint,
        isJourneyMapAnchor: spec.isTitleBreakpoint,
        contentTags: spec.isTitleBreakpoint
            ? const [ContentTag.core, ContentTag.journey]
            : const [ContentTag.core, ContentTag.cosmetics],
        rarity: spec.rarity,
      ),
  ];
}
