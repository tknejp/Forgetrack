import '../../../l10n/app_localizations.dart';
import 'cosmetic_models.dart';

/// Single source of truth for all cosmetic definitions in the app.
///
/// Definitions are static and compiled in. Adding a cosmetic = appending to
/// [definitions] and (optionally) shipping an asset under
/// `assets/cosmetics/<type>/<id>.png` (see `assets/cosmetics/README.md`).
///
/// Player-facing text (name / description / unlock hint) is wired directly to
/// the generated [AppLocalizations] getters via a closure, e.g.
/// `name: (l) => l.cosmeticFrameLvl1Name`. There is no separate id-to-key
/// switch table — the catalog *is* the mapping. Renaming an `.arb` key
/// auto-renames all references through the IDE; typos fail to compile.
///
/// The catalog is intentionally not loaded from JSON or remote config so that
/// every release ships a deterministic set the app can reason about offline.
class CosmeticCatalog {
  const CosmeticCatalog();

  static final List<CosmeticDefinition> definitions =
      List.unmodifiable(<CosmeticDefinition>[
    // -------------------------------------------------------------------------
    // Frames — Journey milestone set
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'frame_lvl1',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticFrameLvl1Name,
      description: (l10n) => l10n.cosmeticFrameLvl1Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl1UnlockHint,
      assetKey: 'cosmetics.frames.lvl1',
      previewAssetKey: 'cosmetics.frames.lvl1',
      sortOrder: 100,
    ),
    CosmeticDefinition(
      id: 'frame_lvl10',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticFrameLvl10Name,
      description: (l10n) => l10n.cosmeticFrameLvl10Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl10UnlockHint,
      assetKey: 'cosmetics.frames.lvl10',
      previewAssetKey: 'cosmetics.frames.lvl10',
      sortOrder: 110,
    ),
    CosmeticDefinition(
      id: 'frame_lvl25',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticFrameLvl25Name,
      description: (l10n) => l10n.cosmeticFrameLvl25Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl25UnlockHint,
      assetKey: 'cosmetics.frames.lvl25',
      previewAssetKey: 'cosmetics.frames.lvl25',
      sortOrder: 125,
    ),
    CosmeticDefinition(
      id: 'frame_lvl40',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticFrameLvl40Name,
      description: (l10n) => l10n.cosmeticFrameLvl40Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl40UnlockHint,
      assetKey: 'cosmetics.frames.lvl40',
      previewAssetKey: 'cosmetics.frames.lvl40',
      sortOrder: 140,
    ),
    CosmeticDefinition(
      id: 'frame_lvl60',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticFrameLvl60Name,
      description: (l10n) => l10n.cosmeticFrameLvl60Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl60UnlockHint,
      assetKey: 'cosmetics.frames.lvl60',
      previewAssetKey: 'cosmetics.frames.lvl60',
      sortOrder: 160,
    ),
    CosmeticDefinition(
      id: 'frame_lvl80',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticFrameLvl80Name,
      description: (l10n) => l10n.cosmeticFrameLvl80Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl80UnlockHint,
      assetKey: 'cosmetics.frames.lvl80',
      previewAssetKey: 'cosmetics.frames.lvl80',
      sortOrder: 180,
    ),
    CosmeticDefinition(
      id: 'frame_lvl100',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticFrameLvl100Name,
      description: (l10n) => l10n.cosmeticFrameLvl100Desc,
      unlockHint: (l10n) => l10n.cosmeticFrameLvl100UnlockHint,
      assetKey: 'cosmetics.frames.lvl100',
      previewAssetKey: 'cosmetics.frames.lvl100',
      sortOrder: 200,
    ),
    CosmeticDefinition(
      id: 'frame_developer_tom',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameDeveloperTomName,
      description: (l10n) => l10n.cosmeticFrameDeveloperTomDesc,
      assetKey: 'cosmetics.frames.frame_developer_tom',
      previewAssetKey: 'cosmetics.frames.frame_developer_tom',
      sortOrder: 1000,
      isPremium: true,
      metadata: <String, Object?>{
        'entitlement': 'firebase',
        'exclusive': true,
      },
    ),

    // -------------------------------------------------------------------------
    // Relics
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'relic_old_compass',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicOldCompassName,
      description: (l10n) => l10n.cosmeticRelicOldCompassDesc,
      assetKey: 'cosmetics.relics.old_compass',
      previewAssetKey: 'cosmetics.relics.old_compass',
      sortOrder: 300,
    ),

    CosmeticDefinition(
      id: 'relic_old_gate_key',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicOldGateKeyName,
      description: (l10n) => l10n.cosmeticRelicOldGateKeyDesc,
      assetKey: 'cosmetics.relics.old_gate_key',
      previewAssetKey: 'cosmetics.relics.old_gate_key',
      sortOrder: 310,
    ),

    // -------------------------------------------------------------------------
    // Backgrounds
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'background_forest_trail',
      type: CosmeticType.background,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticBackgroundForestTrailName,
      description: (l10n) => l10n.cosmeticBackgroundForestTrailDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundForestTrailUnlockHint,
      assetKey: 'cosmetics.backgrounds.forest_trail',
      previewAssetKey: 'cosmetics.backgrounds.forest_trail',
      sortOrder: 400,
    ),

    // -------------------------------------------------------------------------
    // Emblems
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'emblem_forest_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticEmblemForestMarkName,
      description: (l10n) => l10n.cosmeticEmblemForestMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemForestMarkUnlockHint,
      assetKey: 'cosmetics.emblems.forest_mark',
      previewAssetKey: 'cosmetics.emblems.forest_mark',
      sortOrder: 500,
    ),

    // -------------------------------------------------------------------------
    // Backgrounds — Journey map regions (camp → dragonrock fortress)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'background_camp',
      type: CosmeticType.background,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticBackgroundCampName,
      description: (l10n) => l10n.cosmeticBackgroundCampDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundCampUnlockHint,
      assetKey: 'cosmetics.backgrounds.camp',
      previewAssetKey: 'cosmetics.backgrounds.camp',
      sortOrder: 410,
    ),
    CosmeticDefinition(
      id: 'background_ravine',
      type: CosmeticType.background,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticBackgroundRavineName,
      description: (l10n) => l10n.cosmeticBackgroundRavineDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundRavineUnlockHint,
      assetKey: 'cosmetics.backgrounds.ravine',
      previewAssetKey: 'cosmetics.backgrounds.ravine',
      sortOrder: 420,
    ),
    CosmeticDefinition(
      id: 'background_ruins',
      type: CosmeticType.background,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticBackgroundRuinsName,
      description: (l10n) => l10n.cosmeticBackgroundRuinsDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundRuinsUnlockHint,
      assetKey: 'cosmetics.backgrounds.ruins',
      previewAssetKey: 'cosmetics.backgrounds.ruins',
      sortOrder: 430,
    ),
    CosmeticDefinition(
      id: 'background_bridge_crossing',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticBackgroundBridgeCrossingName,
      description: (l10n) => l10n.cosmeticBackgroundBridgeCrossingDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundBridgeCrossingUnlockHint,
      assetKey: 'cosmetics.backgrounds.bridge_crossing',
      previewAssetKey: 'cosmetics.backgrounds.bridge_crossing',
      sortOrder: 440,
    ),
    CosmeticDefinition(
      id: 'background_mines',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticBackgroundMinesName,
      description: (l10n) => l10n.cosmeticBackgroundMinesDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundMinesUnlockHint,
      assetKey: 'cosmetics.backgrounds.mines',
      previewAssetKey: 'cosmetics.backgrounds.mines',
      sortOrder: 450,
    ),
    CosmeticDefinition(
      id: 'background_frostlands',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticBackgroundFrostlandsName,
      description: (l10n) => l10n.cosmeticBackgroundFrostlandsDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundFrostlandsUnlockHint,
      assetKey: 'cosmetics.backgrounds.frostlands',
      previewAssetKey: 'cosmetics.backgrounds.frostlands',
      sortOrder: 460,
    ),
    CosmeticDefinition(
      id: 'background_frozen_lake',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticBackgroundFrozenLakeName,
      description: (l10n) => l10n.cosmeticBackgroundFrozenLakeDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundFrozenLakeUnlockHint,
      assetKey: 'cosmetics.backgrounds.frozen_lake',
      previewAssetKey: 'cosmetics.backgrounds.frozen_lake',
      sortOrder: 470,
    ),
    CosmeticDefinition(
      id: 'background_rocky_mountains',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticBackgroundRockyMountainsName,
      description: (l10n) => l10n.cosmeticBackgroundRockyMountainsDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundRockyMountainsUnlockHint,
      assetKey: 'cosmetics.backgrounds.rocky_mountains',
      previewAssetKey: 'cosmetics.backgrounds.rocky_mountains',
      sortOrder: 480,
    ),
    CosmeticDefinition(
      id: 'background_dragonrock_fortress',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticBackgroundDragonrockFortressName,
      description: (l10n) => l10n.cosmeticBackgroundDragonrockFortressDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundDragonrockFortressUnlockHint,
      assetKey: 'cosmetics.backgrounds.dragonrock_fortress',
      previewAssetKey: 'cosmetics.backgrounds.dragonrock_fortress',
      sortOrder: 490,
    ),

    // -------------------------------------------------------------------------
    // Backgrounds — Developer-only (grant via DevTools only)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'background_dev_altar',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevAltarName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_altar',
      previewAssetKey: 'cosmetics.backgrounds.dev_altar',
      sortOrder: 9010,
      metadata: <String, Object?>{'devOnly': true},
    ),
    CosmeticDefinition(
      id: 'background_dev_camp',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevCampName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_camp',
      previewAssetKey: 'cosmetics.backgrounds.dev_camp',
      sortOrder: 9020,
      metadata: <String, Object?>{'devOnly': true},
    ),
    CosmeticDefinition(
      id: 'background_dev_hacker',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevHackerName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_hacker',
      previewAssetKey: 'cosmetics.backgrounds.dev_hacker',
      sortOrder: 9030,
      metadata: <String, Object?>{'devOnly': true},
    ),
    CosmeticDefinition(
      id: 'background_dev_lord',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevLordName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_lord',
      previewAssetKey: 'cosmetics.backgrounds.dev_lord',
      sortOrder: 9040,
      metadata: <String, Object?>{'devOnly': true},
    ),
    CosmeticDefinition(
      id: 'background_dev_mines',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevMinesName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_mines',
      previewAssetKey: 'cosmetics.backgrounds.dev_mines',
      sortOrder: 9050,
      metadata: <String, Object?>{'devOnly': true},
    ),
    CosmeticDefinition(
      id: 'background_dev_throne',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevThroneName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_throne',
      previewAssetKey: 'cosmetics.backgrounds.dev_throne',
      sortOrder: 9060,
      metadata: <String, Object?>{'devOnly': true},
    ),

    // -------------------------------------------------------------------------
    // Emblems — Journey badges (insignia of crossed milestones)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'emblem_pilgrim_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticEmblemPilgrimMarkName,
      description: (l10n) => l10n.cosmeticEmblemPilgrimMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemPilgrimMarkUnlockHint,
      assetKey: 'cosmetics.emblems.pilgrim_mark',
      previewAssetKey: 'cosmetics.emblems.pilgrim_mark',
      sortOrder: 510,
    ),
    CosmeticDefinition(
      id: 'emblem_ruin_sigil',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticEmblemRuinSigilName,
      description: (l10n) => l10n.cosmeticEmblemRuinSigilDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemRuinSigilUnlockHint,
      assetKey: 'cosmetics.emblems.ruin_sigil',
      previewAssetKey: 'cosmetics.emblems.ruin_sigil',
      sortOrder: 520,
    ),
    CosmeticDefinition(
      id: 'emblem_gatekeeper_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticEmblemGatekeeperMarkName,
      description: (l10n) => l10n.cosmeticEmblemGatekeeperMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemGatekeeperMarkUnlockHint,
      assetKey: 'cosmetics.emblems.gatekeeper_mark',
      previewAssetKey: 'cosmetics.emblems.gatekeeper_mark',
      sortOrder: 530,
    ),
    CosmeticDefinition(
      id: 'emblem_mine_crest',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticEmblemMineCrestName,
      description: (l10n) => l10n.cosmeticEmblemMineCrestDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemMineCrestUnlockHint,
      assetKey: 'cosmetics.emblems.mine_crest',
      previewAssetKey: 'cosmetics.emblems.mine_crest',
      sortOrder: 540,
    ),
    CosmeticDefinition(
      id: 'emblem_underways_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticEmblemUnderwaysMarkName,
      description: (l10n) => l10n.cosmeticEmblemUnderwaysMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemUnderwaysMarkUnlockHint,
      assetKey: 'cosmetics.emblems.underways_mark',
      previewAssetKey: 'cosmetics.emblems.underways_mark',
      sortOrder: 550,
    ),
    CosmeticDefinition(
      id: 'emblem_frost_sigil',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticEmblemFrostSigilName,
      description: (l10n) => l10n.cosmeticEmblemFrostSigilDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemFrostSigilUnlockHint,
      assetKey: 'cosmetics.emblems.frost_sigil',
      previewAssetKey: 'cosmetics.emblems.frost_sigil',
      sortOrder: 560,
    ),
    CosmeticDefinition(
      id: 'emblem_icewalker_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticEmblemIcewalkerMarkName,
      description: (l10n) => l10n.cosmeticEmblemIcewalkerMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemIcewalkerMarkUnlockHint,
      assetKey: 'cosmetics.emblems.icewalker_mark',
      previewAssetKey: 'cosmetics.emblems.icewalker_mark',
      sortOrder: 570,
    ),
    CosmeticDefinition(
      id: 'emblem_mountain_crest',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticEmblemMountainCrestName,
      description: (l10n) => l10n.cosmeticEmblemMountainCrestDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemMountainCrestUnlockHint,
      assetKey: 'cosmetics.emblems.mountain_crest',
      previewAssetKey: 'cosmetics.emblems.mountain_crest',
      sortOrder: 580,
    ),
    CosmeticDefinition(
      id: 'emblem_dragon_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticEmblemDragonMarkName,
      description: (l10n) => l10n.cosmeticEmblemDragonMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemDragonMarkUnlockHint,
      assetKey: 'cosmetics.emblems.dragon_mark',
      previewAssetKey: 'cosmetics.emblems.dragon_mark',
      sortOrder: 590,
    ),
    CosmeticDefinition(
      id: 'emblem_dragonrock_emblem',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticEmblemDragonrockEmblemName,
      description: (l10n) => l10n.cosmeticEmblemDragonrockEmblemDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemDragonrockEmblemUnlockHint,
      assetKey: 'cosmetics.emblems.dragonrock_emblem',
      previewAssetKey: 'cosmetics.emblems.dragonrock_emblem',
      sortOrder: 600,
    ),

    // -------------------------------------------------------------------------
    // Relics — Journey-earned tokens (quests, streaks, step totals, prestige)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'relic_campfire_spark',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicCampfireSparkName,
      description: (l10n) => l10n.cosmeticRelicCampfireSparkDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicCampfireSparkUnlockHint,
      assetKey: 'cosmetics.relics.campfire_spark',
      previewAssetKey: 'cosmetics.relics.campfire_spark',
      sortOrder: 320,
    ),
    CosmeticDefinition(
      id: 'relic_pilgrim_cloak',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicPilgrimCloakName,
      description: (l10n) => l10n.cosmeticRelicPilgrimCloakDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicPilgrimCloakUnlockHint,
      assetKey: 'cosmetics.relics.pilgrim_cloak',
      previewAssetKey: 'cosmetics.relics.pilgrim_cloak',
      sortOrder: 330,
    ),
    CosmeticDefinition(
      id: 'relic_trail_compass',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicTrailCompassName,
      description: (l10n) => l10n.cosmeticRelicTrailCompassDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicTrailCompassUnlockHint,
      assetKey: 'cosmetics.relics.trail_compass',
      previewAssetKey: 'cosmetics.relics.trail_compass',
      sortOrder: 340,
    ),
    CosmeticDefinition(
      id: 'relic_ancient_root',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicAncientRootName,
      description: (l10n) => l10n.cosmeticRelicAncientRootDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicAncientRootUnlockHint,
      assetKey: 'cosmetics.relics.ancient_root',
      previewAssetKey: 'cosmetics.relics.ancient_root',
      sortOrder: 350,
    ),
    CosmeticDefinition(
      id: 'relic_ravine_stone',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicRavineStoneName,
      description: (l10n) => l10n.cosmeticRelicRavineStoneDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicRavineStoneUnlockHint,
      assetKey: 'cosmetics.relics.ravine_stone',
      previewAssetKey: 'cosmetics.relics.ravine_stone',
      sortOrder: 360,
    ),
    CosmeticDefinition(
      id: 'relic_ruin_seal',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicRuinSealName,
      description: (l10n) => l10n.cosmeticRelicRuinSealDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicRuinSealUnlockHint,
      assetKey: 'cosmetics.relics.ruin_seal',
      previewAssetKey: 'cosmetics.relics.ruin_seal',
      sortOrder: 370,
    ),
    CosmeticDefinition(
      id: 'relic_bridge_key',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicBridgeKeyName,
      description: (l10n) => l10n.cosmeticRelicBridgeKeyDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicBridgeKeyUnlockHint,
      assetKey: 'cosmetics.relics.bridge_key',
      previewAssetKey: 'cosmetics.relics.bridge_key',
      sortOrder: 380,
    ),
    CosmeticDefinition(
      id: 'relic_miners_lantern',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticRelicMinersLanternName,
      description: (l10n) => l10n.cosmeticRelicMinersLanternDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicMinersLanternUnlockHint,
      assetKey: 'cosmetics.relics.miners_lantern',
      previewAssetKey: 'cosmetics.relics.miners_lantern',
      sortOrder: 390,
    ),
    CosmeticDefinition(
      id: 'relic_polar_lantern',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicPolarLanternName,
      description: (l10n) => l10n.cosmeticRelicPolarLanternDesc,
      assetKey: 'cosmetics.relics.polar_lantern',
      previewAssetKey: 'cosmetics.relics.polar_lantern',
      sortOrder: 392,
    ),
    CosmeticDefinition(
      id: 'relic_frost_shard',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicFrostShardName,
      description: (l10n) => l10n.cosmeticRelicFrostShardDesc,
      assetKey: 'cosmetics.relics.frost_shard',
      previewAssetKey: 'cosmetics.relics.frost_shard',
      sortOrder: 394,
    ),
    CosmeticDefinition(
      id: 'relic_frozen_lake_heart',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicFrozenLakeHeartName,
      description: (l10n) => l10n.cosmeticRelicFrozenLakeHeartDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicFrozenLakeHeartUnlockHint,
      assetKey: 'cosmetics.relics.frozen_lake_heart',
      previewAssetKey: 'cosmetics.relics.frozen_lake_heart',
      sortOrder: 396,
    ),
    CosmeticDefinition(
      id: 'relic_dragon_scale',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticRelicDragonScaleName,
      description: (l10n) => l10n.cosmeticRelicDragonScaleDesc,
      assetKey: 'cosmetics.relics.dragon_scale',
      previewAssetKey: 'cosmetics.relics.dragon_scale',
      sortOrder: 397,
    ),
    CosmeticDefinition(
      id: 'relic_dragon_crown',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticRelicDragonCrownName,
      description: (l10n) => l10n.cosmeticRelicDragonCrownDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicDragonCrownUnlockHint,
      assetKey: 'cosmetics.relics.dragon_crown',
      previewAssetKey: 'cosmetics.relics.dragon_crown',
      sortOrder: 398,
    ),
    CosmeticDefinition(
      id: 'relic_dragonrock_crown',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticRelicDragonrockCrownName,
      description: (l10n) => l10n.cosmeticRelicDragonrockCrownDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicDragonrockCrownUnlockHint,
      assetKey: 'cosmetics.relics.dragonrock_crown',
      previewAssetKey: 'cosmetics.relics.dragonrock_crown',
      sortOrder: 399,
    ),

    // -------------------------------------------------------------------------
    // Frames — Discipline / streak / prestige rewards
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'frame_discipline',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameDisciplineName,
      description: (l10n) => l10n.cosmeticFrameDisciplineDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameDisciplineUnlockHint,
      assetKey: 'cosmetics.frames.discipline',
      previewAssetKey: 'cosmetics.frames.discipline',
      sortOrder: 220,
    ),
    CosmeticDefinition(
      id: 'frame_endurance',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameEnduranceName,
      description: (l10n) => l10n.cosmeticFrameEnduranceDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameEnduranceUnlockHint,
      assetKey: 'cosmetics.frames.endurance',
      previewAssetKey: 'cosmetics.frames.endurance',
      sortOrder: 230,
    ),
    CosmeticDefinition(
      id: 'frame_steel',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameSteelName,
      description: (l10n) => l10n.cosmeticFrameSteelDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameSteelUnlockHint,
      assetKey: 'cosmetics.frames.steel',
      previewAssetKey: 'cosmetics.frames.steel',
      sortOrder: 240,
    ),
    CosmeticDefinition(
      id: 'frame_eternal_flame',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameEternalFlameName,
      description: (l10n) => l10n.cosmeticFrameEternalFlameDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameEternalFlameUnlockHint,
      assetKey: 'cosmetics.frames.eternal_flame',
      previewAssetKey: 'cosmetics.frames.eternal_flame',
      sortOrder: 250,
    ),
    CosmeticDefinition(
      id: 'frame_balance',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameBalanceName,
      description: (l10n) => l10n.cosmeticFrameBalanceDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameBalanceUnlockHint,
      assetKey: 'cosmetics.frames.balance',
      previewAssetKey: 'cosmetics.frames.balance',
      sortOrder: 260,
    ),
    CosmeticDefinition(
      id: 'frame_master_routine',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameMasterRoutineName,
      description: (l10n) => l10n.cosmeticFrameMasterRoutineDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameMasterRoutineUnlockHint,
      assetKey: 'cosmetics.frames.master_routine',
      previewAssetKey: 'cosmetics.frames.master_routine',
      sortOrder: 270,
    ),
    CosmeticDefinition(
      id: 'frame_endless_trail',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameEndlessTrailName,
      description: (l10n) => l10n.cosmeticFrameEndlessTrailDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameEndlessTrailUnlockHint,
      assetKey: 'cosmetics.frames.endless_trail',
      previewAssetKey: 'cosmetics.frames.endless_trail',
      sortOrder: 280,
    ),
    CosmeticDefinition(
      id: 'frame_worldwalker',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameWorldwalkerName,
      description: (l10n) => l10n.cosmeticFrameWorldwalkerDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameWorldwalkerUnlockHint,
      assetKey: 'cosmetics.frames.worldwalker',
      previewAssetKey: 'cosmetics.frames.worldwalker',
      sortOrder: 290,
    ),

    // -------------------------------------------------------------------------
    // Companions
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'companion_ember_sprite',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticCompanionEmberSpriteName,
      description: (l10n) => l10n.cosmeticCompanionEmberSpriteDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionEmberSpriteUnlockHint,
      assetKey: 'cosmetics.companions.ember_sprite',
      previewAssetKey: 'cosmetics.companions.ember_sprite',
      sortOrder: 700,
    ),
    CosmeticDefinition(
      id: 'companion_forest_fox',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticCompanionForestFoxName,
      description: (l10n) => l10n.cosmeticCompanionForestFoxDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionForestFoxUnlockHint,
      assetKey: 'cosmetics.companions.forest_fox',
      previewAssetKey: 'cosmetics.companions.forest_fox',
      sortOrder: 710,
    ),
    CosmeticDefinition(
      id: 'companion_ruin_raven',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticCompanionRuinRavenName,
      description: (l10n) => l10n.cosmeticCompanionRuinRavenDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionRuinRavenUnlockHint,
      assetKey: 'cosmetics.companions.ruin_raven',
      previewAssetKey: 'cosmetics.companions.ruin_raven',
      sortOrder: 720,
    ),
    CosmeticDefinition(
      id: 'companion_lantern_golem',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticCompanionLanternGolemName,
      description: (l10n) => l10n.cosmeticCompanionLanternGolemDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionLanternGolemUnlockHint,
      assetKey: 'cosmetics.companions.lantern_golem',
      previewAssetKey: 'cosmetics.companions.lantern_golem',
      sortOrder: 730,
    ),
    CosmeticDefinition(
      id: 'companion_ice_wisp',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticCompanionIceWispName,
      description: (l10n) => l10n.cosmeticCompanionIceWispDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionIceWispUnlockHint,
      assetKey: 'cosmetics.companions.ice_wisp',
      previewAssetKey: 'cosmetics.companions.ice_wisp',
      sortOrder: 740,
    ),
    CosmeticDefinition(
      id: 'companion_mountain_gryphon',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticCompanionMountainGryphonName,
      description: (l10n) => l10n.cosmeticCompanionMountainGryphonDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionMountainGryphonUnlockHint,
      assetKey: 'cosmetics.companions.mountain_gryphon',
      previewAssetKey: 'cosmetics.companions.mountain_gryphon',
      sortOrder: 750,
    ),
    CosmeticDefinition(
      id: 'companion_dragonling',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticCompanionDragonlingName,
      description: (l10n) => l10n.cosmeticCompanionDragonlingDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionDragonlingUnlockHint,
      assetKey: 'cosmetics.companions.dragonling',
      previewAssetKey: 'cosmetics.companions.dragonling',
      sortOrder: 760,
    ),
  ]);

  List<CosmeticDefinition> get all => definitions;

  CosmeticDefinition? byId(String id) {
    for (final def in definitions) {
      if (def.id == id) return def;
    }
    return null;
  }

  List<CosmeticDefinition> byType(CosmeticType type) {
    return definitions.where((d) => d.type == type).toList(growable: false);
  }

  List<CosmeticDefinition> byRegion(CosmeticRegion region) {
    return definitions.where((d) => d.region == region).toList(growable: false);
  }

  List<CosmeticDefinition> get enabled {
    return definitions.where((d) => d.isEnabled).toList(growable: false);
  }

  /// Static integrity checks. Returns a list of warning strings; empty list
  /// means the catalog is well-formed. Recommended to call once at startup
  /// in debug mode.
  ///
  /// Localization wiring is checked at compile time because each definition
  /// references generated `AppLocalizations` getters directly.
  List<String> validate() {
    final warnings = <String>[];
    final seenIds = <String>{};

    for (final def in definitions) {
      if (!seenIds.add(def.id)) {
        warnings.add('Duplicate cosmetic id: ${def.id}');
      }

      if (def.id.isEmpty) {
        warnings.add('Cosmetic with empty id (type=${def.type.name})');
      }

      final assetKey = def.assetKey;
      if (assetKey != null && !_isValidAssetKey(assetKey)) {
        warnings.add(
          'Cosmetic ${def.id} has invalid assetKey "$assetKey" '
          '(expected cosmetics.<bucket>.<name>)',
        );
      }
    }

    return warnings;
  }

  static bool _isValidAssetKey(String key) {
    final parts = key.split('.');
    if (parts.length < 3) return false;
    if (parts.first != 'cosmetics') return false;
    return parts.every((p) => p.isNotEmpty);
  }
}
