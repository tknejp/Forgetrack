import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';

/// Companion availability nodes — port of the chapter-themed companion
/// unlock chains spec'd in `lib/features/cosmetics/domain/plan.md`
/// (Phase 5 of the cosmetics refactor). Each companion is gated on a
/// player level + ownership of the two themed relics from the
/// matching chapter.
///
/// Level ladder: every 10 levels from 5 to 95 — 5 / 15 / 25 / 35 / 45 /
/// 55 / 65 / 75 / 85 / 95. Lvl 100 is a quiet cap with no companion
/// unlock. The same ladder is mirrored in `cosmetic_unlock_rules.dart`
/// (must stay in lockstep — the reveal evaluator reads its conditions
/// for the partial-progress checklist, the engine reads ours for the
/// claim CTA, and both rely on the relic-ownership semantic below to
/// stay aligned).
///
/// Unlock condition shape: `[LevelAtLeast(N), OwnsCosmetic(relic_a),
/// OwnsCosmetic(relic_b)]`. Relics themselves are `CosmeticReward`s on
/// achievement nodes; the engine reads the cosmetics inventory's
/// `unlocked` map (via `EngineEvaluationContext.ownedCosmeticIds`) so
/// the gate evaluates the same way the reveal evaluator does. The
/// previous condition shape used `NodeCompleted(<granting_achievement>)`
/// which is equivalent in normal production flow but diverged whenever
/// the cosmetics inventory got mutated through a side channel
/// (devtools `debugGrantCosmetic`, "Unlock all cosmetics", a partial
/// cloud-pull merge) — see ADR `companion-availability-owns-cosmetic`.
///
/// All ten nodes use `ClaimPolicy.manual` (inherited from
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
      id: const ProgressionEntryId('companion_ember_sprite'),
      companionId: CosmeticId('companion_ember_sprite'),
      titleKey: (l) => l.cosmeticCompanionEmberSpriteName,
      descriptionKey: (l) => l.cosmeticCompanionEmberSpriteDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_ember_sprite')),
      ],
      unlockConditions: const [
        LevelAtLeast(5),
        OwnsCosmetic(CosmeticId('relic_campfire_spark')),
        OwnsCosmetic(CosmeticId('relic_warm_kindling')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(5),
      // Synced with `cosmetic_catalog.dart` companion rarity (common).
      rarity: Rarity.common,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_forest_fox'),
      companionId: CosmeticId('companion_forest_fox'),
      titleKey: (l) => l.cosmeticCompanionForestFoxName,
      descriptionKey: (l) => l.cosmeticCompanionForestFoxDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_forest_fox')),
      ],
      unlockConditions: const [
        LevelAtLeast(15),
        OwnsCosmetic(CosmeticId('relic_moonlit_foxglove')),
        OwnsCosmetic(CosmeticId('relic_ancient_root')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(15),
      // Synced with `cosmetic_catalog.dart` companion rarity (uncommon).
      rarity: Rarity.uncommon,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_ruin_raven'),
      companionId: CosmeticId('companion_ruin_raven'),
      titleKey: (l) => l.cosmeticCompanionRuinRavenName,
      descriptionKey: (l) => l.cosmeticCompanionRuinRavenDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_ruin_raven')),
      ],
      unlockConditions: const [
        LevelAtLeast(25),
        OwnsCosmetic(CosmeticId('relic_ruin_seal')),
        OwnsCosmetic(CosmeticId('relic_ashen_omen')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(25),
      // Synced with `cosmetic_catalog.dart` companion rarity (uncommon).
      rarity: Rarity.uncommon,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_bridge_gargoyle'),
      companionId: CosmeticId('companion_bridge_gargoyle'),
      titleKey: (l) => l.cosmeticCompanionBridgeGargoyleName,
      descriptionKey: (l) => l.cosmeticCompanionBridgeGargoyleDesc,
      rewards: const [
        CompanionAvailabilityReward(
          companionId: CosmeticId('companion_bridge_gargoyle'),
        ),
      ],
      unlockConditions: const [
        LevelAtLeast(35),
        OwnsCosmetic(CosmeticId('relic_oathbound_mark')),
        OwnsCosmetic(CosmeticId('relic_bridge_key')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(35),
      rarity: Rarity.rare,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_lantern_golem'),
      companionId: CosmeticId('companion_lantern_golem'),
      titleKey: (l) => l.cosmeticCompanionLanternGolemName,
      descriptionKey: (l) => l.cosmeticCompanionLanternGolemDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_lantern_golem')),
      ],
      unlockConditions: const [
        LevelAtLeast(45),
        OwnsCosmetic(CosmeticId('relic_deep_ember_core')),
        OwnsCosmetic(CosmeticId('relic_miners_lantern')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(45),
      // Synced with `cosmetic_catalog.dart` companion rarity (rare) so
      // the progress node and the inventory display agree.
      rarity: Rarity.rare,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_cave_lynx'),
      companionId: CosmeticId('companion_cave_lynx'),
      titleKey: (l) => l.cosmeticCompanionCaveLynxName,
      descriptionKey: (l) => l.cosmeticCompanionCaveLynxDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_cave_lynx')),
      ],
      unlockConditions: const [
        LevelAtLeast(55),
        OwnsCosmetic(CosmeticId('relic_wildwood_charm')),
        OwnsCosmetic(CosmeticId('relic_ravine_stone')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(55),
      rarity: Rarity.epic,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_aurora_stag'),
      companionId: CosmeticId('companion_aurora_stag'),
      titleKey: (l) => l.cosmeticCompanionAuroraStagName,
      descriptionKey: (l) => l.cosmeticCompanionAuroraStagDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_aurora_stag')),
      ],
      unlockConditions: const [
        LevelAtLeast(65),
        OwnsCosmetic(CosmeticId('relic_polar_lantern')),
        OwnsCosmetic(CosmeticId('relic_aurora_thread')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(65),
      rarity: Rarity.epic,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_ice_wisp'),
      companionId: CosmeticId('companion_ice_wisp'),
      titleKey: (l) => l.cosmeticCompanionIceWispName,
      descriptionKey: (l) => l.cosmeticCompanionIceWispDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_ice_wisp')),
      ],
      unlockConditions: const [
        LevelAtLeast(75),
        OwnsCosmetic(CosmeticId('relic_frozen_lake_heart')),
        OwnsCosmetic(CosmeticId('relic_frost_shard')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(75),
      rarity: Rarity.legendary,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_mountain_gryphon'),
      companionId: CosmeticId('companion_mountain_gryphon'),
      titleKey: (l) => l.cosmeticCompanionMountainGryphonName,
      descriptionKey: (l) => l.cosmeticCompanionMountainGryphonDesc,
      rewards: const [
        CompanionAvailabilityReward(
          companionId: CosmeticId('companion_mountain_gryphon'),
        ),
      ],
      unlockConditions: const [
        LevelAtLeast(85),
        OwnsCosmetic(CosmeticId('relic_summit_feather')),
        OwnsCosmetic(CosmeticId('relic_stormcrest_plume')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(85),
      rarity: Rarity.legendary,
    ),
    CompanionAvailability(
      id: const ProgressionEntryId('companion_dragonling'),
      companionId: CosmeticId('companion_dragonling'),
      titleKey: (l) => l.cosmeticCompanionDragonlingName,
      descriptionKey: (l) => l.cosmeticCompanionDragonlingDesc,
      rewards: const [
        CompanionAvailabilityReward(companionId: CosmeticId('companion_dragonling')),
      ],
      unlockConditions: const [
        LevelAtLeast(95),
        OwnsCosmetic(CosmeticId('relic_dragon_scale')),
        OwnsCosmetic(CosmeticId('relic_dragonrock_heart')),
      ],
      lockedHintKey: (l) => l.cosmeticCompanionLevelGate(95),
      rarity: Rarity.mythic,
    ),
  ];
}
