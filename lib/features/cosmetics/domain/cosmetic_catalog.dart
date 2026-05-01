import 'cosmetic_models.dart';

/// Single source of truth for all cosmetic definitions in the app.
///
/// Definitions are static and compiled in. Adding a cosmetic = appending to
/// [definitions] and (optionally) shipping an asset under
/// `assets/cosmetics/<type>/<id>.png` (see `assets/cosmetics/README.md`).
///
/// The catalog is intentionally not loaded from JSON or remote config so that
/// every release ships a deterministic set the app can reason about offline.
class CosmeticCatalog {
  const CosmeticCatalog();

  static const List<CosmeticDefinition> definitions = <CosmeticDefinition>[
    // -------------------------------------------------------------------------
    // Frames — Journey milestone set
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'frame_lvl1',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.frame_lvl1.name',
      descriptionKey: 'cosmetics.frame_lvl1.description',
      assetKey: 'cosmetics.frames.lvl1',
      previewAssetKey: 'cosmetics.frames.lvl1',
      sortOrder: 100,
      unlockHintKey: 'cosmetics.frame_lvl1.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_lvl10',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.frame_lvl10.name',
      descriptionKey: 'cosmetics.frame_lvl10.description',
      assetKey: 'cosmetics.frames.lvl10',
      previewAssetKey: 'cosmetics.frames.lvl10',
      sortOrder: 110,
      unlockHintKey: 'cosmetics.frame_lvl10.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_lvl25',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.frame_lvl25.name',
      descriptionKey: 'cosmetics.frame_lvl25.description',
      assetKey: 'cosmetics.frames.lvl25',
      previewAssetKey: 'cosmetics.frames.lvl25',
      sortOrder: 125,
      unlockHintKey: 'cosmetics.frame_lvl25.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_lvl40',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      nameKey: 'cosmetics.frame_lvl40.name',
      descriptionKey: 'cosmetics.frame_lvl40.description',
      assetKey: 'cosmetics.frames.lvl40',
      previewAssetKey: 'cosmetics.frames.lvl40',
      sortOrder: 140,
      unlockHintKey: 'cosmetics.frame_lvl40.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_lvl60',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.frame_lvl60.name',
      descriptionKey: 'cosmetics.frame_lvl60.description',
      assetKey: 'cosmetics.frames.lvl60',
      previewAssetKey: 'cosmetics.frames.lvl60',
      sortOrder: 160,
      unlockHintKey: 'cosmetics.frame_lvl60.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_lvl80',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.frame_lvl80.name',
      descriptionKey: 'cosmetics.frame_lvl80.description',
      assetKey: 'cosmetics.frames.lvl80',
      previewAssetKey: 'cosmetics.frames.lvl80',
      sortOrder: 180,
      unlockHintKey: 'cosmetics.frame_lvl80.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_lvl100',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      nameKey: 'cosmetics.frame_lvl100.name',
      descriptionKey: 'cosmetics.frame_lvl100.description',
      assetKey: 'cosmetics.frames.lvl100',
      previewAssetKey: 'cosmetics.frames.lvl100',
      sortOrder: 200,
      unlockHintKey: 'cosmetics.frame_lvl100.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_developer_tom',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_developer_tom.name',
      descriptionKey: 'cosmetics.frame_developer_tom.description',
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
      nameKey: 'cosmetics.relic_old_compass.name',
      descriptionKey: 'cosmetics.relic_old_compass.description',
      assetKey: 'cosmetics.relics.old_compass',
      previewAssetKey: 'cosmetics.relics.old_compass',
      sortOrder: 300,
    ),

    CosmeticDefinition(
      id: 'relic_old_gate_key',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.relic_old_gate_key.name',
      descriptionKey: 'cosmetics.relic_old_gate_key.description',
      assetKey: 'cosmetics.relics.old_gate_key',
      previewAssetKey: 'cosmetics.relics.old_gate_key',
      sortOrder: 310,
      unlockHintKey: 'cosmetics.relic_old_gate_key.unlock_hint',
    ),

    // -------------------------------------------------------------------------
    // Backgrounds
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'background_forest_trail',
      type: CosmeticType.background,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.background_forest_trail.name',
      descriptionKey: 'cosmetics.background_forest_trail.description',
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
      nameKey: 'cosmetics.emblem_forest_mark.name',
      descriptionKey: 'cosmetics.emblem_forest_mark.description',
      assetKey: 'cosmetics.emblems.forest_mark',
      previewAssetKey: 'cosmetics.emblems.forest_mark',
      sortOrder: 500,
      unlockHintKey: 'cosmetics.emblem_forest_mark.unlock_hint',
    ),

    // -------------------------------------------------------------------------
    // Backgrounds — Journey map regions (camp → dragonrock fortress)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'background_camp',
      type: CosmeticType.background,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.background_camp.name',
      descriptionKey: 'cosmetics.background_camp.description',
      assetKey: 'cosmetics.backgrounds.camp',
      previewAssetKey: 'cosmetics.backgrounds.camp',
      sortOrder: 410,
      unlockHintKey: 'cosmetics.background_camp.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_ravine',
      type: CosmeticType.background,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.background_ravine.name',
      descriptionKey: 'cosmetics.background_ravine.description',
      assetKey: 'cosmetics.backgrounds.ravine',
      previewAssetKey: 'cosmetics.backgrounds.ravine',
      sortOrder: 420,
      unlockHintKey: 'cosmetics.background_ravine.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_ruins',
      type: CosmeticType.background,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.background_ruins.name',
      descriptionKey: 'cosmetics.background_ruins.description',
      assetKey: 'cosmetics.backgrounds.ruins',
      previewAssetKey: 'cosmetics.backgrounds.ruins',
      sortOrder: 430,
      unlockHintKey: 'cosmetics.background_ruins.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_bridge_crossing',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.background_bridge_crossing.name',
      descriptionKey: 'cosmetics.background_bridge_crossing.description',
      assetKey: 'cosmetics.backgrounds.bridge_crossing',
      previewAssetKey: 'cosmetics.backgrounds.bridge_crossing',
      sortOrder: 440,
      unlockHintKey: 'cosmetics.background_bridge_crossing.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_mines',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      nameKey: 'cosmetics.background_mines.name',
      descriptionKey: 'cosmetics.background_mines.description',
      assetKey: 'cosmetics.backgrounds.mines',
      previewAssetKey: 'cosmetics.backgrounds.mines',
      sortOrder: 450,
      unlockHintKey: 'cosmetics.background_mines.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_frostlands',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.background_frostlands.name',
      descriptionKey: 'cosmetics.background_frostlands.description',
      assetKey: 'cosmetics.backgrounds.frostlands',
      previewAssetKey: 'cosmetics.backgrounds.frostlands',
      sortOrder: 460,
      unlockHintKey: 'cosmetics.background_frostlands.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_frozen_lake',
      type: CosmeticType.background,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.background_frozen_lake.name',
      descriptionKey: 'cosmetics.background_frozen_lake.description',
      assetKey: 'cosmetics.backgrounds.frozen_lake',
      previewAssetKey: 'cosmetics.backgrounds.frozen_lake',
      sortOrder: 470,
      unlockHintKey: 'cosmetics.background_frozen_lake.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_rocky_mountains',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.background_rocky_mountains.name',
      descriptionKey: 'cosmetics.background_rocky_mountains.description',
      assetKey: 'cosmetics.backgrounds.rocky_mountains',
      previewAssetKey: 'cosmetics.backgrounds.rocky_mountains',
      sortOrder: 480,
      unlockHintKey: 'cosmetics.background_rocky_mountains.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'background_dragonrock_fortress',
      type: CosmeticType.background,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      nameKey: 'cosmetics.background_dragonrock_fortress.name',
      descriptionKey: 'cosmetics.background_dragonrock_fortress.description',
      assetKey: 'cosmetics.backgrounds.dragonrock_fortress',
      previewAssetKey: 'cosmetics.backgrounds.dragonrock_fortress',
      sortOrder: 490,
      unlockHintKey: 'cosmetics.background_dragonrock_fortress.unlock_hint',
    ),

    // -------------------------------------------------------------------------
    // Emblems — Journey badges (insignia of crossed milestones)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'emblem_pilgrim_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.emblem_pilgrim_mark.name',
      descriptionKey: 'cosmetics.emblem_pilgrim_mark.description',
      assetKey: 'cosmetics.emblems.pilgrim_mark',
      previewAssetKey: 'cosmetics.emblems.pilgrim_mark',
      sortOrder: 510,
      unlockHintKey: 'cosmetics.emblem_pilgrim_mark.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_ruin_sigil',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.emblem_ruin_sigil.name',
      descriptionKey: 'cosmetics.emblem_ruin_sigil.description',
      assetKey: 'cosmetics.emblems.ruin_sigil',
      previewAssetKey: 'cosmetics.emblems.ruin_sigil',
      sortOrder: 520,
      unlockHintKey: 'cosmetics.emblem_ruin_sigil.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_gatekeeper_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.emblem_gatekeeper_mark.name',
      descriptionKey: 'cosmetics.emblem_gatekeeper_mark.description',
      assetKey: 'cosmetics.emblems.gatekeeper_mark',
      previewAssetKey: 'cosmetics.emblems.gatekeeper_mark',
      sortOrder: 530,
      unlockHintKey: 'cosmetics.emblem_gatekeeper_mark.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_mine_crest',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      nameKey: 'cosmetics.emblem_mine_crest.name',
      descriptionKey: 'cosmetics.emblem_mine_crest.description',
      assetKey: 'cosmetics.emblems.mine_crest',
      previewAssetKey: 'cosmetics.emblems.mine_crest',
      sortOrder: 540,
      unlockHintKey: 'cosmetics.emblem_mine_crest.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_underways_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      nameKey: 'cosmetics.emblem_underways_mark.name',
      descriptionKey: 'cosmetics.emblem_underways_mark.description',
      assetKey: 'cosmetics.emblems.underways_mark',
      previewAssetKey: 'cosmetics.emblems.underways_mark',
      sortOrder: 550,
      unlockHintKey: 'cosmetics.emblem_underways_mark.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_frost_sigil',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.emblem_frost_sigil.name',
      descriptionKey: 'cosmetics.emblem_frost_sigil.description',
      assetKey: 'cosmetics.emblems.frost_sigil',
      previewAssetKey: 'cosmetics.emblems.frost_sigil',
      sortOrder: 560,
      unlockHintKey: 'cosmetics.emblem_frost_sigil.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_icewalker_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.emblem_icewalker_mark.name',
      descriptionKey: 'cosmetics.emblem_icewalker_mark.description',
      assetKey: 'cosmetics.emblems.icewalker_mark',
      previewAssetKey: 'cosmetics.emblems.icewalker_mark',
      sortOrder: 570,
      unlockHintKey: 'cosmetics.emblem_icewalker_mark.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_mountain_crest',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.emblem_mountain_crest.name',
      descriptionKey: 'cosmetics.emblem_mountain_crest.description',
      assetKey: 'cosmetics.emblems.mountain_crest',
      previewAssetKey: 'cosmetics.emblems.mountain_crest',
      sortOrder: 580,
      unlockHintKey: 'cosmetics.emblem_mountain_crest.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_dragon_mark',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.emblem_dragon_mark.name',
      descriptionKey: 'cosmetics.emblem_dragon_mark.description',
      assetKey: 'cosmetics.emblems.dragon_mark',
      previewAssetKey: 'cosmetics.emblems.dragon_mark',
      sortOrder: 590,
      unlockHintKey: 'cosmetics.emblem_dragon_mark.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'emblem_dragonrock_emblem',
      type: CosmeticType.emblem,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      nameKey: 'cosmetics.emblem_dragonrock_emblem.name',
      descriptionKey: 'cosmetics.emblem_dragonrock_emblem.description',
      assetKey: 'cosmetics.emblems.dragonrock_emblem',
      previewAssetKey: 'cosmetics.emblems.dragonrock_emblem',
      sortOrder: 600,
      unlockHintKey: 'cosmetics.emblem_dragonrock_emblem.unlock_hint',
    ),

    // -------------------------------------------------------------------------
    // Relics — Journey-earned tokens (quests, streaks, step totals, prestige)
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'relic_campfire_spark',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.relic_campfire_spark.name',
      descriptionKey: 'cosmetics.relic_campfire_spark.description',
      assetKey: 'cosmetics.relics.campfire_spark',
      previewAssetKey: 'cosmetics.relics.campfire_spark',
      sortOrder: 320,
      unlockHintKey: 'cosmetics.relic_campfire_spark.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_pilgrim_cloak',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.common,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.relic_pilgrim_cloak.name',
      descriptionKey: 'cosmetics.relic_pilgrim_cloak.description',
      assetKey: 'cosmetics.relics.pilgrim_cloak',
      previewAssetKey: 'cosmetics.relics.pilgrim_cloak',
      sortOrder: 330,
      unlockHintKey: 'cosmetics.relic_pilgrim_cloak.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_trail_compass',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.relic_trail_compass.name',
      descriptionKey: 'cosmetics.relic_trail_compass.description',
      assetKey: 'cosmetics.relics.trail_compass',
      previewAssetKey: 'cosmetics.relics.trail_compass',
      sortOrder: 340,
      unlockHintKey: 'cosmetics.relic_trail_compass.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_ancient_root',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.relic_ancient_root.name',
      descriptionKey: 'cosmetics.relic_ancient_root.description',
      assetKey: 'cosmetics.relics.ancient_root',
      previewAssetKey: 'cosmetics.relics.ancient_root',
      sortOrder: 350,
      unlockHintKey: 'cosmetics.relic_ancient_root.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_ravine_stone',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.relic_ravine_stone.name',
      descriptionKey: 'cosmetics.relic_ravine_stone.description',
      assetKey: 'cosmetics.relics.ravine_stone',
      previewAssetKey: 'cosmetics.relics.ravine_stone',
      sortOrder: 360,
      unlockHintKey: 'cosmetics.relic_ravine_stone.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_ruin_seal',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.relic_ruin_seal.name',
      descriptionKey: 'cosmetics.relic_ruin_seal.description',
      assetKey: 'cosmetics.relics.ruin_seal',
      previewAssetKey: 'cosmetics.relics.ruin_seal',
      sortOrder: 370,
      unlockHintKey: 'cosmetics.relic_ruin_seal.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_bridge_key',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.rare,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.relic_bridge_key.name',
      descriptionKey: 'cosmetics.relic_bridge_key.description',
      assetKey: 'cosmetics.relics.bridge_key',
      previewAssetKey: 'cosmetics.relics.bridge_key',
      sortOrder: 380,
      unlockHintKey: 'cosmetics.relic_bridge_key.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_miners_lantern',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      nameKey: 'cosmetics.relic_miners_lantern.name',
      descriptionKey: 'cosmetics.relic_miners_lantern.description',
      assetKey: 'cosmetics.relics.miners_lantern',
      previewAssetKey: 'cosmetics.relics.miners_lantern',
      sortOrder: 390,
      unlockHintKey: 'cosmetics.relic_miners_lantern.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_polar_lantern',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.relic_polar_lantern.name',
      descriptionKey: 'cosmetics.relic_polar_lantern.description',
      assetKey: 'cosmetics.relics.polar_lantern',
      previewAssetKey: 'cosmetics.relics.polar_lantern',
      sortOrder: 392,
      unlockHintKey: 'cosmetics.relic_polar_lantern.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_frost_shard',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.relic_frost_shard.name',
      descriptionKey: 'cosmetics.relic_frost_shard.description',
      assetKey: 'cosmetics.relics.frost_shard',
      previewAssetKey: 'cosmetics.relics.frost_shard',
      sortOrder: 394,
      unlockHintKey: 'cosmetics.relic_frost_shard.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_frozen_lake_heart',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.relic_frozen_lake_heart.name',
      descriptionKey: 'cosmetics.relic_frozen_lake_heart.description',
      assetKey: 'cosmetics.relics.frozen_lake_heart',
      previewAssetKey: 'cosmetics.relics.frozen_lake_heart',
      sortOrder: 396,
      unlockHintKey: 'cosmetics.relic_frozen_lake_heart.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_dragon_scale',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.relic_dragon_scale.name',
      descriptionKey: 'cosmetics.relic_dragon_scale.description',
      assetKey: 'cosmetics.relics.dragon_scale',
      previewAssetKey: 'cosmetics.relics.dragon_scale',
      sortOrder: 397,
      unlockHintKey: 'cosmetics.relic_dragon_scale.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_dragon_crown',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.relic_dragon_crown.name',
      descriptionKey: 'cosmetics.relic_dragon_crown.description',
      assetKey: 'cosmetics.relics.dragon_crown',
      previewAssetKey: 'cosmetics.relics.dragon_crown',
      sortOrder: 398,
      unlockHintKey: 'cosmetics.relic_dragon_crown.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'relic_dragonrock_crown',
      type: CosmeticType.relic,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      nameKey: 'cosmetics.relic_dragonrock_crown.name',
      descriptionKey: 'cosmetics.relic_dragonrock_crown.description',
      assetKey: 'cosmetics.relics.dragonrock_crown',
      previewAssetKey: 'cosmetics.relics.dragonrock_crown',
      sortOrder: 399,
      unlockHintKey: 'cosmetics.relic_dragonrock_crown.unlock_hint',
    ),

    // -------------------------------------------------------------------------
    // Frames — Discipline / streak / prestige rewards
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'frame_discipline',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_discipline.name',
      descriptionKey: 'cosmetics.frame_discipline.description',
      assetKey: 'cosmetics.frames.discipline',
      previewAssetKey: 'cosmetics.frames.discipline',
      sortOrder: 220,
      unlockHintKey: 'cosmetics.frame_discipline.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_endurance',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_endurance.name',
      descriptionKey: 'cosmetics.frame_endurance.description',
      assetKey: 'cosmetics.frames.endurance',
      previewAssetKey: 'cosmetics.frames.endurance',
      sortOrder: 230,
      unlockHintKey: 'cosmetics.frame_endurance.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_steel',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_steel.name',
      descriptionKey: 'cosmetics.frame_steel.description',
      assetKey: 'cosmetics.frames.steel',
      previewAssetKey: 'cosmetics.frames.steel',
      sortOrder: 240,
      unlockHintKey: 'cosmetics.frame_steel.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_eternal_flame',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_eternal_flame.name',
      descriptionKey: 'cosmetics.frame_eternal_flame.description',
      assetKey: 'cosmetics.frames.eternal_flame',
      previewAssetKey: 'cosmetics.frames.eternal_flame',
      sortOrder: 250,
      unlockHintKey: 'cosmetics.frame_eternal_flame.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_balance',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_balance.name',
      descriptionKey: 'cosmetics.frame_balance.description',
      assetKey: 'cosmetics.frames.balance',
      previewAssetKey: 'cosmetics.frames.balance',
      sortOrder: 260,
      unlockHintKey: 'cosmetics.frame_balance.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_master_routine',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_master_routine.name',
      descriptionKey: 'cosmetics.frame_master_routine.description',
      assetKey: 'cosmetics.frames.master_routine',
      previewAssetKey: 'cosmetics.frames.master_routine',
      sortOrder: 270,
      unlockHintKey: 'cosmetics.frame_master_routine.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_endless_trail',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_endless_trail.name',
      descriptionKey: 'cosmetics.frame_endless_trail.description',
      assetKey: 'cosmetics.frames.endless_trail',
      previewAssetKey: 'cosmetics.frames.endless_trail',
      sortOrder: 280,
      unlockHintKey: 'cosmetics.frame_endless_trail.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'frame_worldwalker',
      type: CosmeticType.frame,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.neutral,
      nameKey: 'cosmetics.frame_worldwalker.name',
      descriptionKey: 'cosmetics.frame_worldwalker.description',
      assetKey: 'cosmetics.frames.worldwalker',
      previewAssetKey: 'cosmetics.frames.worldwalker',
      sortOrder: 290,
      unlockHintKey: 'cosmetics.frame_worldwalker.unlock_hint',
    ),

    // -------------------------------------------------------------------------
    // Companions
    // -------------------------------------------------------------------------

    CosmeticDefinition(
      id: 'companion_ember_sprite',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.companion_ember_sprite.name',
      descriptionKey: 'cosmetics.companion_ember_sprite.description',
      assetKey: 'cosmetics.companions.ember_sprite',
      previewAssetKey: 'cosmetics.companions.ember_sprite',
      sortOrder: 700,
      unlockHintKey: 'cosmetics.companion_ember_sprite.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'companion_forest_fox',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.forestTrail,
      nameKey: 'cosmetics.companion_forest_fox.name',
      descriptionKey: 'cosmetics.companion_forest_fox.description',
      assetKey: 'cosmetics.companions.forest_fox',
      previewAssetKey: 'cosmetics.companions.forest_fox',
      sortOrder: 710,
      unlockHintKey: 'cosmetics.companion_forest_fox.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'companion_ruin_raven',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.ruinedPass,
      nameKey: 'cosmetics.companion_ruin_raven.name',
      descriptionKey: 'cosmetics.companion_ruin_raven.description',
      assetKey: 'cosmetics.companions.ruin_raven',
      previewAssetKey: 'cosmetics.companions.ruin_raven',
      sortOrder: 720,
      unlockHintKey: 'cosmetics.companion_ruin_raven.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'companion_lantern_golem',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.dwarvenMines,
      nameKey: 'cosmetics.companion_lantern_golem.name',
      descriptionKey: 'cosmetics.companion_lantern_golem.description',
      assetKey: 'cosmetics.companions.lantern_golem',
      previewAssetKey: 'cosmetics.companions.lantern_golem',
      sortOrder: 730,
      unlockHintKey: 'cosmetics.companion_lantern_golem.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'companion_ice_wisp',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.epic,
      region: CosmeticRegion.frostlands,
      nameKey: 'cosmetics.companion_ice_wisp.name',
      descriptionKey: 'cosmetics.companion_ice_wisp.description',
      assetKey: 'cosmetics.companions.ice_wisp',
      previewAssetKey: 'cosmetics.companions.ice_wisp',
      sortOrder: 740,
      unlockHintKey: 'cosmetics.companion_ice_wisp.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'companion_mountain_gryphon',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonMountains,
      nameKey: 'cosmetics.companion_mountain_gryphon.name',
      descriptionKey: 'cosmetics.companion_mountain_gryphon.description',
      assetKey: 'cosmetics.companions.mountain_gryphon',
      previewAssetKey: 'cosmetics.companions.mountain_gryphon',
      sortOrder: 750,
      unlockHintKey: 'cosmetics.companion_mountain_gryphon.unlock_hint',
    ),
    CosmeticDefinition(
      id: 'companion_dragonling',
      type: CosmeticType.companion,
      rarity: CosmeticRarity.legendary,
      region: CosmeticRegion.dragonrockFortress,
      nameKey: 'cosmetics.companion_dragonling.name',
      descriptionKey: 'cosmetics.companion_dragonling.description',
      assetKey: 'cosmetics.companions.dragonling',
      previewAssetKey: 'cosmetics.companions.dragonling',
      sortOrder: 760,
      unlockHintKey: 'cosmetics.companion_dragonling.unlock_hint',
    ),
  ];

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

      if (def.nameKey.isEmpty) {
        warnings.add('Cosmetic ${def.id} has empty nameKey');
      }

      if (def.descriptionKey.isEmpty) {
        warnings.add('Cosmetic ${def.id} has empty descriptionKey');
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
