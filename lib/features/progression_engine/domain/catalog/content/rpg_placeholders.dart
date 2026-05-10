import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import '../engine_catalog_context.dart';

/// RPG placeholders — one CompanionAvailabilityNode (manual claim)
/// and one RelicNode (auto-unlock). Both gated on `LevelAtLeast(20)`
/// so they don't fire for fresh players and demonstrate the Q3 split:
/// companions are 3-state (locked → available → unlocked via claim),
/// relics are 2-state (locked → unlocked).
///
/// Phase 3 ships exactly one of each as proof-of-concept; real RPG
/// content (multiple companions, multiple relic tiers, chapter-bound
/// relics) lands once the chapter system + RPG mode toggle land.

List<ObjectiveDefinition> rpgObjectives(EngineCatalogContext context) {
  // Placeholders are condition-driven only; no objectives.
  return const [];
}

List<ProgressionNode> rpgNodes() {
  return [
    CompanionAvailabilityNode(
      id: 'companion_pilgrim_fox',
      companionId: 'pilgrim_fox',
      titleKey: (l) => l.progAchievementWelcomeToJourneyTitle,
      descriptionKey: (l) => l.progAchievementWelcomeToJourneyDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'pilgrim_fox'),
      ],
      unlockConditions: const [LevelAtLeast(20)],
      lockedHintKey: (l) => l.progLevelAchievementDesc(20),
      contentTags: const [ContentTag.rpg, ContentTag.companions],
      rarity: Rarity.rare,
    ),
    RelicNode(
      id: 'relic_pilgrim_compass',
      relicId: 'pilgrim_compass',
      titleKey: (l) => l.progAchievementWelcomeToJourneyTitle,
      descriptionKey: (l) => l.progAchievementWelcomeToJourneyDesc,
      rewards: const [RelicReward(relicId: 'pilgrim_compass')],
      unlockConditions: const [LevelAtLeast(20)],
      contentTags: const [ContentTag.rpg, ContentTag.relics],
      rarity: Rarity.rare,
    ),
  ];
}
