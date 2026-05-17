import '../../../../../shared/domain/rarity.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';

/// Companion availability nodes — port of the chapter-themed companion
/// unlock chains spec'd in `lib/features/cosmetics/domain/plan.md`
/// (Phase 5 of the cosmetics refactor). Each companion is gated on a
/// player level + completion of the two relic-granting achievements
/// from the matching chapter.
///
/// Unlock condition shape: `[LevelAtLeast(N), NodeCompleted(relic1_ach),
/// NodeCompleted(relic2_ach)]`. The relics themselves are
/// `CosmeticReward`s on achievement nodes (V2 doesn't have standalone
/// Relic entries for them) — so the gate references the *granting*
/// achievement's id, not the relic id.
///
/// All seven nodes use `ClaimPolicy.manual` (inherited from
/// CompanionAvailability). The celebration adapter folds the
/// reveal into the achievement event that granted the final relic
/// via the companion-availability fold pass (`adapter.convert`
/// looks for `NodeCompleted` host matches and merges the companion
/// card into the host's celebration). When un-folded (e.g. the
/// player crosses the level threshold long after both relics
/// completed), the companion gets a standalone fullscreen reveal
/// pointing to the inventory.

List<ProgressionEntry> companionNodes() {
  return [
    CompanionAvailability(
      id: 'companion_ember_sprite',
      companionId: 'companion_ember_sprite',
      titleKey: (l) => l.cosmeticCompanionEmberSpriteName,
      descriptionKey: (l) => l.cosmeticCompanionEmberSpriteDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'companion_ember_sprite'),
      ],
      unlockConditions: const [
        LevelAtLeast(5),
        NodeCompleted('first_reward'),
        NodeCompleted('daily_quest_3'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(5),
      rarity: Rarity.uncommon,
    ),
    CompanionAvailability(
      id: 'companion_forest_fox',
      companionId: 'companion_forest_fox',
      titleKey: (l) => l.cosmeticCompanionForestFoxName,
      descriptionKey: (l) => l.cosmeticCompanionForestFoxDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'companion_forest_fox'),
      ],
      unlockConditions: const [
        LevelAtLeast(10),
        NodeCompleted('active_days_7'),
        NodeCompleted('weekly_activity_mastery'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(10),
      rarity: Rarity.rare,
    ),
    CompanionAvailability(
      id: 'companion_ruin_raven',
      companionId: 'companion_ruin_raven',
      titleKey: (l) => l.cosmeticCompanionRuinRavenName,
      descriptionKey: (l) => l.cosmeticCompanionRuinRavenDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'companion_ruin_raven'),
      ],
      unlockConditions: const [
        LevelAtLeast(25),
        NodeCompleted('steps_streak_7'),
        NodeCompleted('weekly_activity_4'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(25),
      rarity: Rarity.rare,
    ),
    CompanionAvailability(
      id: 'companion_lantern_golem',
      companionId: 'companion_lantern_golem',
      titleKey: (l) => l.cosmeticCompanionLanternGolemName,
      descriptionKey: (l) => l.cosmeticCompanionLanternGolemDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'companion_lantern_golem'),
      ],
      unlockConditions: const [
        LevelAtLeast(45),
        NodeCompleted('steps_total_1000000'),
        NodeCompleted('combo_triple_victory_25'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(45),
      rarity: Rarity.epic,
    ),
    CompanionAvailability(
      id: 'companion_ice_wisp',
      companionId: 'companion_ice_wisp',
      titleKey: (l) => l.cosmeticCompanionIceWispName,
      descriptionKey: (l) => l.cosmeticCompanionIceWispDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'companion_ice_wisp'),
      ],
      unlockConditions: const [
        LevelAtLeast(65),
        NodeCompleted('weekly_activity_24'),
        NodeCompleted('quest_hunter_250'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(65),
      rarity: Rarity.legendary,
    ),
    CompanionAvailability(
      id: 'companion_mountain_gryphon',
      companionId: 'companion_mountain_gryphon',
      titleKey: (l) => l.cosmeticCompanionMountainGryphonName,
      descriptionKey: (l) => l.cosmeticCompanionMountainGryphonDesc,
      rewards: const [
        CompanionAvailabilityReward(
          companionId: 'companion_mountain_gryphon',
        ),
      ],
      unlockConditions: const [
        LevelAtLeast(85),
        NodeCompleted('combo_triple_victory_100'),
        NodeCompleted('weekly_activity_52'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(85),
      rarity: Rarity.legendary,
    ),
    CompanionAvailability(
      id: 'companion_dragonling',
      companionId: 'companion_dragonling',
      titleKey: (l) => l.cosmeticCompanionDragonlingName,
      descriptionKey: (l) => l.cosmeticCompanionDragonlingDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: 'companion_dragonling'),
      ],
      unlockConditions: const [
        LevelAtLeast(100),
        NodeCompleted('steps_total_10000000'),
        NodeCompleted('dragonrock_trial'),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(100),
      rarity: Rarity.mythic,
    ),
  ];
}
