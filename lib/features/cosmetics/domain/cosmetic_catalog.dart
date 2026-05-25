import 'package:forgetrack/domain/progression/catalog/ids.dart';

import '../../../l10n/app_localizations.dart';
import '../../health_connect/domain/player_goal.dart';
import 'cosmetic_models.dart';

/// Single source of truth for all cosmetic definitions in the app.
///
/// Definitions are static and compiled in. Adding a cosmetic = appending to
/// [definitions] and (optionally) shipping an asset under
/// `assets/cosmetics/<type>/<id>.png` (see `assets/cosmetics/README.md`).
///
/// Player-facing text (name / description / unlock hint) is wired directly to
/// the generated [AppLocalizations] getters via a closure, e.g.
/// `name: (l) => l.cosmeticFramePilgrimName`. There is no separate id-to-key
/// switch table — the catalog *is* the mapping. Renaming an `.arb` key
/// auto-renames all references through the IDE; typos fail to compile.
///
/// The catalog is intentionally not loaded from JSON or remote config so that
/// every release ships a deterministic set the app can reason about offline.
class CosmeticCatalog {
  const CosmeticCatalog();

  static final List<Cosmetic> definitions =
      List.unmodifiable(<Cosmetic>[
    // -------------------------------------------------------------------------
    // Frames — Journey milestone set
    // -------------------------------------------------------------------------

    Frame(
      id: const CosmeticId('frame_pilgrim'),
      rarity: Rarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticFramePilgrimName,
      description: (l10n) => l10n.cosmeticFramePilgrimDesc,
      unlockHint: (l10n) => l10n.cosmeticFramePilgrimUnlockHint,
      assetKey: 'cosmetics.frames.pilgrim',
      previewAssetKey: 'cosmetics.frames.pilgrim',
      sortOrder: 100,
    ),
    Frame(
      id: const CosmeticId('frame_wildwood'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticFrameWildwoodName,
      description: (l10n) => l10n.cosmeticFrameWildwoodDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameWildwoodUnlockHint,
      assetKey: 'cosmetics.frames.wildwood',
      previewAssetKey: 'cosmetics.frames.wildwood',
      sortOrder: 110,
    ),
    Frame(
      id: const CosmeticId('frame_ruins'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticFrameRuinsName,
      description: (l10n) => l10n.cosmeticFrameRuinsDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameRuinsUnlockHint,
      assetKey: 'cosmetics.frames.ruins',
      previewAssetKey: 'cosmetics.frames.ruins',
      sortOrder: 120,
    ),
    Frame(
      id: const CosmeticId('frame_dwarven'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticFrameDwarvenName,
      description: (l10n) => l10n.cosmeticFrameDwarvenDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameDwarvenUnlockHint,
      assetKey: 'cosmetics.frames.dwarven',
      previewAssetKey: 'cosmetics.frames.dwarven',
      sortOrder: 125,
    ),
    Frame(
      id: const CosmeticId('frame_underways'),
      rarity: Rarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticFrameUnderwaysName,
      description: (l10n) => l10n.cosmeticFrameUnderwaysDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameUnderwaysUnlockHint,
      assetKey: 'cosmetics.frames.underways',
      previewAssetKey: 'cosmetics.frames.underways',
      sortOrder: 140,
    ),
    Frame(
      id: const CosmeticId('frame_frost'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticFrameFrostName,
      description: (l10n) => l10n.cosmeticFrameFrostDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameFrostUnlockHint,
      assetKey: 'cosmetics.frames.frost',
      previewAssetKey: 'cosmetics.frames.frost',
      sortOrder: 160,
    ),
    Frame(
      id: const CosmeticId('frame_mountain'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticFrameMountainName,
      description: (l10n) => l10n.cosmeticFrameMountainDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameMountainUnlockHint,
      assetKey: 'cosmetics.frames.mountain',
      previewAssetKey: 'cosmetics.frames.mountain',
      sortOrder: 180,
    ),
    Frame(
      id: const CosmeticId('frame_dragonrock'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticFrameDragonrockName,
      description: (l10n) => l10n.cosmeticFrameDragonrockDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameDragonrockUnlockHint,
      assetKey: 'cosmetics.frames.dragonrock',
      previewAssetKey: 'cosmetics.frames.dragonrock',
      sortOrder: 200,
    ),
    Frame(
      id: const CosmeticId('frame_developer_tom'),
      rarity: Rarity.mythic,
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
    // Backgrounds — Journey map regions (camp → dragonrock fortress)
    // -------------------------------------------------------------------------

    Background(
      id: const CosmeticId('background_camp'),
      rarity: Rarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticBackgroundCampName,
      description: (l10n) => l10n.cosmeticBackgroundCampDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundCampUnlockHint,
      assetKey: 'cosmetics.backgrounds.camp',
      previewAssetKey: 'cosmetics.backgrounds.camp',
      sortOrder: 400,
    ),
    Background(
      id: const CosmeticId('background_forest_trail'),
      rarity: Rarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticBackgroundForestTrailName,
      description: (l10n) => l10n.cosmeticBackgroundForestTrailDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundForestTrailUnlockHint,
      assetKey: 'cosmetics.backgrounds.forest_trail',
      previewAssetKey: 'cosmetics.backgrounds.forest_trail',
      sortOrder: 410,
    ),
    Background(
      id: const CosmeticId('background_ravine'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticBackgroundRavineName,
      description: (l10n) => l10n.cosmeticBackgroundRavineDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundRavineUnlockHint,
      assetKey: 'cosmetics.backgrounds.ravine',
      previewAssetKey: 'cosmetics.backgrounds.ravine',
      sortOrder: 420,
    ),
    Background(
      id: const CosmeticId('background_ruins'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticBackgroundRuinsName,
      description: (l10n) => l10n.cosmeticBackgroundRuinsDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundRuinsUnlockHint,
      assetKey: 'cosmetics.backgrounds.ruins',
      previewAssetKey: 'cosmetics.backgrounds.ruins',
      sortOrder: 430,
    ),
    Background(
      id: const CosmeticId('background_bridge_crossing'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticBackgroundBridgeCrossingName,
      description: (l10n) => l10n.cosmeticBackgroundBridgeCrossingDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundBridgeCrossingUnlockHint,
      assetKey: 'cosmetics.backgrounds.bridge_crossing',
      previewAssetKey: 'cosmetics.backgrounds.bridge_crossing',
      sortOrder: 440,
    ),
    Background(
      id: const CosmeticId('background_mines'),
      rarity: Rarity.rare,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticBackgroundMinesName,
      description: (l10n) => l10n.cosmeticBackgroundMinesDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundMinesUnlockHint,
      assetKey: 'cosmetics.backgrounds.mines',
      previewAssetKey: 'cosmetics.backgrounds.mines',
      sortOrder: 450,
    ),
    Background(
      id: const CosmeticId('background_frostlands'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticBackgroundFrostlandsName,
      description: (l10n) => l10n.cosmeticBackgroundFrostlandsDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundFrostlandsUnlockHint,
      assetKey: 'cosmetics.backgrounds.frostlands',
      previewAssetKey: 'cosmetics.backgrounds.frostlands',
      sortOrder: 460,
    ),
    Background(
      id: const CosmeticId('background_frozen_lake'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticBackgroundFrozenLakeName,
      description: (l10n) => l10n.cosmeticBackgroundFrozenLakeDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundFrozenLakeUnlockHint,
      assetKey: 'cosmetics.backgrounds.frozen_lake',
      previewAssetKey: 'cosmetics.backgrounds.frozen_lake',
      sortOrder: 470,
    ),
    Background(
      id: const CosmeticId('background_rocky_mountains'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticBackgroundRockyMountainsName,
      description: (l10n) => l10n.cosmeticBackgroundRockyMountainsDesc,
      unlockHint: (l10n) => l10n.cosmeticBackgroundRockyMountainsUnlockHint,
      assetKey: 'cosmetics.backgrounds.rocky_mountains',
      previewAssetKey: 'cosmetics.backgrounds.rocky_mountains',
      sortOrder: 480,
    ),
    Background(
      id: const CosmeticId('background_dragonrock_fortress'),
      rarity: Rarity.mythic,
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

    Background(
      id: const CosmeticId('background_dev_altar'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevAltarName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_altar',
      previewAssetKey: 'cosmetics.backgrounds.dev_altar',
      sortOrder: 9010,
      metadata: <String, Object?>{'devOnly': true},
    ),
    Background(
      id: const CosmeticId('background_dev_camp'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevCampName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_camp',
      previewAssetKey: 'cosmetics.backgrounds.dev_camp',
      sortOrder: 9020,
      metadata: <String, Object?>{'devOnly': true},
    ),
    Background(
      id: const CosmeticId('background_dev_hacker'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevHackerName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_hacker',
      previewAssetKey: 'cosmetics.backgrounds.dev_hacker',
      sortOrder: 9030,
      metadata: <String, Object?>{'devOnly': true},
    ),
    Background(
      id: const CosmeticId('background_dev_lord'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevLordName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_lord',
      previewAssetKey: 'cosmetics.backgrounds.dev_lord',
      sortOrder: 9040,
      metadata: <String, Object?>{'devOnly': true},
    ),
    Background(
      id: const CosmeticId('background_dev_mines'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticBackgroundDevMinesName,
      description: (l10n) => l10n.cosmeticBackgroundDevOnlyDesc,
      assetKey: 'cosmetics.backgrounds.dev_mines',
      previewAssetKey: 'cosmetics.backgrounds.dev_mines',
      sortOrder: 9050,
      metadata: <String, Object?>{'devOnly': true},
    ),
    Background(
      id: const CosmeticId('background_dev_throne'),
      rarity: Rarity.mythic,
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

    Emblem(
      id: const CosmeticId('emblem_pilgrim_mark'),
      rarity: Rarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticEmblemPilgrimMarkName,
      description: (l10n) => l10n.cosmeticEmblemPilgrimMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemPilgrimMarkUnlockHint,
      assetKey: 'cosmetics.emblems.pilgrim_mark',
      previewAssetKey: 'cosmetics.emblems.pilgrim_mark',
      sortOrder: 500,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailyCalories),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_forest_mark'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticEmblemForestMarkName,
      description: (l10n) => l10n.cosmeticEmblemForestMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemForestMarkUnlockHint,
      assetKey: 'cosmetics.emblems.forest_mark',
      previewAssetKey: 'cosmetics.emblems.forest_mark',
      sortOrder: 510,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailySteps),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_ruin_sigil'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticEmblemRuinSigilName,
      description: (l10n) => l10n.cosmeticEmblemRuinSigilDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemRuinSigilUnlockHint,
      assetKey: 'cosmetics.emblems.ruin_sigil',
      previewAssetKey: 'cosmetics.emblems.ruin_sigil',
      sortOrder: 520,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailyProtein),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_gatekeeper_mark'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticEmblemGatekeeperMarkName,
      description: (l10n) => l10n.cosmeticEmblemGatekeeperMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemGatekeeperMarkUnlockHint,
      assetKey: 'cosmetics.emblems.gatekeeper_mark',
      previewAssetKey: 'cosmetics.emblems.gatekeeper_mark',
      sortOrder: 530,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailyFat),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_mine_crest'),
      rarity: Rarity.rare,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticEmblemMineCrestName,
      description: (l10n) => l10n.cosmeticEmblemMineCrestDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemMineCrestUnlockHint,
      assetKey: 'cosmetics.emblems.mine_crest',
      previewAssetKey: 'cosmetics.emblems.mine_crest',
      sortOrder: 540,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailyActivityMins),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_underways_mark'),
      rarity: Rarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticEmblemUnderwaysMarkName,
      description: (l10n) => l10n.cosmeticEmblemUnderwaysMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemUnderwaysMarkUnlockHint,
      assetKey: 'cosmetics.emblems.underways_mark',
      previewAssetKey: 'cosmetics.emblems.underways_mark',
      sortOrder: 550,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailyCarbs),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_frost_sigil'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticEmblemFrostSigilName,
      description: (l10n) => l10n.cosmeticEmblemFrostSigilDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemFrostSigilUnlockHint,
      assetKey: 'cosmetics.emblems.frost_sigil',
      previewAssetKey: 'cosmetics.emblems.frost_sigil',
      sortOrder: 560,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.sleepHours),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_icewalker_mark'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticEmblemIcewalkerMarkName,
      description: (l10n) => l10n.cosmeticEmblemIcewalkerMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemIcewalkerMarkUnlockHint,
      assetKey: 'cosmetics.emblems.icewalker_mark',
      previewAssetKey: 'cosmetics.emblems.icewalker_mark',
      sortOrder: 570,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.dailyFiber),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_mountain_crest'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticEmblemMountainCrestName,
      description: (l10n) => l10n.cosmeticEmblemMountainCrestDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemMountainCrestUnlockHint,
      assetKey: 'cosmetics.emblems.mountain_crest',
      previewAssetKey: 'cosmetics.emblems.mountain_crest',
      sortOrder: 580,
      buff: const PerTargetEmblemBuff(
        target: DailyGoalTarget(GoalMetric.targetWeight),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_dragon_mark'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticEmblemDragonMarkName,
      description: (l10n) => l10n.cosmeticEmblemDragonMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemDragonMarkUnlockHint,
      assetKey: 'cosmetics.emblems.dragon_mark',
      previewAssetKey: 'cosmetics.emblems.dragon_mark',
      sortOrder: 590,
      buff: const PerTargetEmblemBuff(
        target: ComboQuestTarget(),
        percent: 10,
      ),
    ),
    Emblem(
      id: const CosmeticId('emblem_dragonrock_emblem'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticEmblemDragonrockEmblemName,
      description: (l10n) => l10n.cosmeticEmblemDragonrockEmblemDesc,
      unlockHint: (l10n) => l10n.cosmeticEmblemDragonrockEmblemUnlockHint,
      assetKey: 'cosmetics.emblems.dragonrock_emblem',
      previewAssetKey: 'cosmetics.emblems.dragonrock_emblem',
      sortOrder: 600,
      buff: const BlanketEmblemBuff(percent: 5),
    ),

    // -------------------------------------------------------------------------
    // Relics — Journey-earned tokens (quests, streaks, step totals, prestige)
    // -------------------------------------------------------------------------

    RelicCosmetic(
      id: const CosmeticId('relic_campfire_spark'),
      rarity: Rarity.common,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticRelicCampfireSparkName,
      description: (l10n) => l10n.cosmeticRelicCampfireSparkDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicCampfireSparkUnlockHint,
      assetKey: 'cosmetics.relics.campfire_spark',
      previewAssetKey: 'cosmetics.relics.campfire_spark',
      sortOrder: 320,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_warm_kindling'),
      rarity: Rarity.common,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticRelicWarmKindlingName,
      description: (l10n) => l10n.cosmeticRelicWarmKindlingDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicWarmKindlingUnlockHint,
      assetKey: 'cosmetics.relics.warm_kindling',
      previewAssetKey: 'cosmetics.relics.warm_kindling',
      sortOrder: 325,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_ancient_root'),
      rarity: Rarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicAncientRootName,
      description: (l10n) => l10n.cosmeticRelicAncientRootDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicAncientRootUnlockHint,
      assetKey: 'cosmetics.relics.ancient_root',
      previewAssetKey: 'cosmetics.relics.ancient_root',
      sortOrder: 350,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_moonlit_foxglove'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicMoonlitFoxgloveName,
      description: (l10n) => l10n.cosmeticRelicMoonlitFoxgloveDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicMoonlitFoxgloveUnlockHint,
      assetKey: 'cosmetics.relics.moonlit_foxglove',
      previewAssetKey: 'cosmetics.relics.moonlit_foxglove',
      sortOrder: 355,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_wildwood_charm'),
      rarity: Rarity.rare,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticRelicWildwoodCharmName,
      description: (l10n) => l10n.cosmeticRelicWildwoodCharmDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicWildwoodCharmUnlockHint,
      assetKey: 'cosmetics.relics.wildwood_charm',
      previewAssetKey: 'cosmetics.relics.wildwood_charm',
      sortOrder: 358,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_ravine_stone'),
      rarity: Rarity.epic,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicRavineStoneName,
      description: (l10n) => l10n.cosmeticRelicRavineStoneDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicRavineStoneUnlockHint,
      assetKey: 'cosmetics.relics.ravine_stone',
      previewAssetKey: 'cosmetics.relics.ravine_stone',
      sortOrder: 360,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_ruin_seal'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicRuinSealName,
      description: (l10n) => l10n.cosmeticRelicRuinSealDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicRuinSealUnlockHint,
      assetKey: 'cosmetics.relics.ruin_seal',
      previewAssetKey: 'cosmetics.relics.ruin_seal',
      sortOrder: 370,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_ashen_omen'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicAshenOmenName,
      description: (l10n) => l10n.cosmeticRelicAshenOmenDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicAshenOmenUnlockHint,
      assetKey: 'cosmetics.relics.ashen_omen',
      previewAssetKey: 'cosmetics.relics.ashen_omen',
      sortOrder: 375,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_oathbound_mark'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticRelicOathboundMarkName,
      description: (l10n) => l10n.cosmeticRelicOathboundMarkDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicOathboundMarkUnlockHint,
      assetKey: 'cosmetics.relics.oathbound_mark',
      previewAssetKey: 'cosmetics.relics.oathbound_mark',
      sortOrder: 378,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_bridge_key'),
      rarity: Rarity.rare,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticRelicBridgeKeyName,
      description: (l10n) => l10n.cosmeticRelicBridgeKeyDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicBridgeKeyUnlockHint,
      assetKey: 'cosmetics.relics.bridge_key',
      previewAssetKey: 'cosmetics.relics.bridge_key',
      sortOrder: 380,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_deep_ember_core'),
      rarity: Rarity.rare,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticRelicDeepEmberCoreName,
      description: (l10n) => l10n.cosmeticRelicDeepEmberCoreDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicDeepEmberCoreUnlockHint,
      assetKey: 'cosmetics.relics.deep_ember_core',
      previewAssetKey: 'cosmetics.relics.deep_ember_core',
      sortOrder: 385,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_miners_lantern'),
      rarity: Rarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticRelicMinersLanternName,
      description: (l10n) => l10n.cosmeticRelicMinersLanternDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicMinersLanternUnlockHint,
      assetKey: 'cosmetics.relics.miners_lantern',
      previewAssetKey: 'cosmetics.relics.miners_lantern',
      sortOrder: 390,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_polar_lantern'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicPolarLanternName,
      description: (l10n) => l10n.cosmeticRelicPolarLanternDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicPolarLanternUnlockHint,
      assetKey: 'cosmetics.relics.polar_lantern',
      previewAssetKey: 'cosmetics.relics.polar_lantern',
      sortOrder: 392,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_frost_shard'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicFrostShardName,
      description: (l10n) => l10n.cosmeticRelicFrostShardDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicFrostShardUnlockHint,
      assetKey: 'cosmetics.relics.frost_shard',
      previewAssetKey: 'cosmetics.relics.frost_shard',
      sortOrder: 394,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_aurora_thread'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicAuroraThreadName,
      description: (l10n) => l10n.cosmeticRelicAuroraThreadDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicAuroraThreadUnlockHint,
      assetKey: 'cosmetics.relics.aurora_thread',
      previewAssetKey: 'cosmetics.relics.aurora_thread',
      sortOrder: 395,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_frozen_lake_heart'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticRelicFrozenLakeHeartName,
      description: (l10n) => l10n.cosmeticRelicFrozenLakeHeartDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicFrozenLakeHeartUnlockHint,
      assetKey: 'cosmetics.relics.frozen_lake_heart',
      previewAssetKey: 'cosmetics.relics.frozen_lake_heart',
      sortOrder: 396,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_dragon_scale'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticRelicDragonScaleName,
      description: (l10n) => l10n.cosmeticRelicDragonScaleDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicDragonScaleUnlockHint,
      assetKey: 'cosmetics.relics.dragon_scale',
      previewAssetKey: 'cosmetics.relics.dragon_scale',
      sortOrder: 397,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_summit_feather'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticRelicSummitFeatherName,
      description: (l10n) => l10n.cosmeticRelicSummitFeatherDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicSummitFeatherUnlockHint,
      assetKey: 'cosmetics.relics.summit_feather',
      previewAssetKey: 'cosmetics.relics.summit_feather',
      sortOrder: 400,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_stormcrest_plume'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticRelicStormcrestPlumeName,
      description: (l10n) => l10n.cosmeticRelicStormcrestPlumeDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicStormcrestPlumeUnlockHint,
      assetKey: 'cosmetics.relics.stormcrest_plume',
      previewAssetKey: 'cosmetics.relics.stormcrest_plume',
      sortOrder: 405,
    ),
    RelicCosmetic(
      id: const CosmeticId('relic_dragonrock_heart'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticRelicDragonrockHeartName,
      description: (l10n) => l10n.cosmeticRelicDragonrockHeartDesc,
      unlockHint: (l10n) => l10n.cosmeticRelicDragonrockHeartUnlockHint,
      assetKey: 'cosmetics.relics.dragonrock_heart',
      previewAssetKey: 'cosmetics.relics.dragonrock_heart',
      sortOrder: 410,
    ),

    // -------------------------------------------------------------------------
    // Frames — Discipline / streak / prestige rewards
    // -------------------------------------------------------------------------

    Frame(
      id: const CosmeticId('frame_discipline'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameDisciplineName,
      description: (l10n) => l10n.cosmeticFrameDisciplineDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameDisciplineUnlockHint,
      assetKey: 'cosmetics.frames.discipline',
      previewAssetKey: 'cosmetics.frames.discipline',
      sortOrder: 220,
    ),
    Frame(
      id: const CosmeticId('frame_endurance'),
      rarity: Rarity.rare,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameEnduranceName,
      description: (l10n) => l10n.cosmeticFrameEnduranceDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameEnduranceUnlockHint,
      assetKey: 'cosmetics.frames.endurance',
      previewAssetKey: 'cosmetics.frames.endurance',
      sortOrder: 230,
    ),
    Frame(
      id: const CosmeticId('frame_steel'),
      rarity: Rarity.epic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameSteelName,
      description: (l10n) => l10n.cosmeticFrameSteelDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameSteelUnlockHint,
      assetKey: 'cosmetics.frames.steel',
      previewAssetKey: 'cosmetics.frames.steel',
      sortOrder: 240,
    ),
    Frame(
      id: const CosmeticId('frame_eternal_flame'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameEternalFlameName,
      description: (l10n) => l10n.cosmeticFrameEternalFlameDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameEternalFlameUnlockHint,
      assetKey: 'cosmetics.frames.eternal_flame',
      previewAssetKey: 'cosmetics.frames.eternal_flame',
      sortOrder: 250,
    ),
    Frame(
      id: const CosmeticId('frame_balance'),
      rarity: Rarity.rare,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameBalanceName,
      description: (l10n) => l10n.cosmeticFrameBalanceDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameBalanceUnlockHint,
      assetKey: 'cosmetics.frames.balance',
      previewAssetKey: 'cosmetics.frames.balance',
      sortOrder: 260,
    ),
    Frame(
      id: const CosmeticId('frame_master_routine'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameMasterRoutineName,
      description: (l10n) => l10n.cosmeticFrameMasterRoutineDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameMasterRoutineUnlockHint,
      assetKey: 'cosmetics.frames.master_routine',
      previewAssetKey: 'cosmetics.frames.master_routine',
      sortOrder: 270,
    ),
    Frame(
      id: const CosmeticId('frame_endless_trail'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticFrameEndlessTrailName,
      description: (l10n) => l10n.cosmeticFrameEndlessTrailDesc,
      unlockHint: (l10n) => l10n.cosmeticFrameEndlessTrailUnlockHint,
      assetKey: 'cosmetics.frames.endless_trail',
      previewAssetKey: 'cosmetics.frames.endless_trail',
      sortOrder: 280,
    ),
    Frame(
      id: const CosmeticId('frame_worldwalker'),
      rarity: Rarity.mythic,
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

    Companion(
      id: const CosmeticId('companion_ember_sprite'),
      rarity: Rarity.common,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticCompanionEmberSpriteName,
      description: (l10n) => l10n.cosmeticCompanionEmberSpriteDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionEmberSpriteUnlockHint,
      assetKey: 'cosmetics.companions.ember_sprite',
      previewAssetKey: 'cosmetics.companions.ember_sprite',
      // Tiny low-biased silhouette inside the 512² canvas (flame body
      // occupies roughly the bottom third) — zoom past the empty top
      // padding so the sprite reads at the same visual size as the
      // standard full-body companions on every preview surface.
      displayScale: 1.8,
      sortOrder: 700,
      levelGate: 5,
      requiredItems: const [
        CosmeticId('relic_campfire_spark'),
        CosmeticId('relic_warm_kindling'),
      ],
      // "Small spark … steady-footed" — flame as a metaphor for
      // streak length. Applies to every main-5 daily-goal claim and
      // resolves its tier from that domain's own streak, so a player
      // can watch the chip climb on their strongest cards while
      // weaker cards sit at floor. See [CompanionBuffPercents] for
      // the five visible tiers + the silent legendary milestone.
      buff: const StreakLengthCompanionBuff(),
    ),
    Companion(
      id: const CosmeticId('companion_forest_fox'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticCompanionForestFoxName,
      description: (l10n) => l10n.cosmeticCompanionForestFoxDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionForestFoxUnlockHint,
      assetKey: 'cosmetics.companions.forest_fox',
      previewAssetKey: 'cosmetics.companions.forest_fox',
      sortOrder: 710,
      levelGate: 15,
      requiredItems: const [
        CosmeticId('relic_moonlit_foxglove'),
        CosmeticId('relic_ancient_root'),
      ],
      // "Quiet wildwood fox" — forager. +10 % on every nutrition
      // daily-goal claim.
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.nutritionXp,
        percent: CompanionBuffPercents.forestFoxNutrition,
      ),
    ),
    Companion(
      id: const CosmeticId('companion_ruin_raven'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticCompanionRuinRavenName,
      description: (l10n) => l10n.cosmeticCompanionRuinRavenDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionRuinRavenUnlockHint,
      assetKey: 'cosmetics.companions.ruin_raven',
      previewAssetKey: 'cosmetics.companions.ruin_raven',
      // Small low-right silhouette — most of the canvas is empty
      // negative space, so the raw asset reads way too small at
      // preview sizes. Bump the per-asset scale to match the other
      // companions.
      displayScale: 1.8,
      sortOrder: 720,
      levelGate: 25,
      requiredItems: const [
        CosmeticId('relic_ruin_seal'),
        CosmeticId('relic_ashen_omen'),
      ],
      // "Seen most often after a weekly quest is closed" — flavor
      // points directly at weekly cadence. Dampened daily so the
      // weekly close lands as a satisfying spike.
      buff: const WeeklyEmphasisCompanionBuff(),
    ),
    Companion(
      id: const CosmeticId('companion_bridge_gargoyle'),
      rarity: Rarity.rare,
      region: CosmeticRegion.ruinedPass,
      name: (l10n) => l10n.cosmeticCompanionBridgeGargoyleName,
      description: (l10n) => l10n.cosmeticCompanionBridgeGargoyleDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionBridgeGargoyleUnlockHint,
      assetKey: 'cosmetics.companions.bridge_gargoyle',
      previewAssetKey: 'cosmetics.companions.bridge_gargoyle',
      sortOrder: 725,
      levelGate: 35,
      requiredItems: const [
        CosmeticId('relic_oathbound_mark'),
        CosmeticId('relic_bridge_key'),
      ],
      // Guards the bridge — bridge-walker, movement-themed. +8 % on
      // activity-domain XP (incl. steps + per-recorded-activity).
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.activityXp,
        percent: CompanionBuffPercents.bridgeGargoyleActivity,
      ),
    ),
    Companion(
      id: const CosmeticId('companion_lantern_golem'),
      rarity: Rarity.rare,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticCompanionLanternGolemName,
      description: (l10n) => l10n.cosmeticCompanionLanternGolemDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionLanternGolemUnlockHint,
      assetKey: 'cosmetics.companions.lantern_golem',
      previewAssetKey: 'cosmetics.companions.lantern_golem',
      sortOrder: 730,
      levelGate: 45,
      requiredItems: const [
        CosmeticId('relic_deep_ember_core'),
        CosmeticId('relic_miners_lantern'),
      ],
      // "Flickering lantern in chest" — persistent inner flame.
      // Applies a flat +30 % to every main-5 daily-goal claim, but
      // only once that domain's streak crosses 7 days. The threshold
      // keeps the rare-tier buff from being an instant payout the
      // moment the companion is equipped — the lantern's warmth has
      // to be earned per card. See [CompanionBuffPercents].
      buff: const StreakThresholdFlatCompanionBuff(
        percent: CompanionBuffPercents.lanternGolemPercent,
        minStreak: CompanionBuffPercents.lanternGolemThreshold,
      ),
    ),
    Companion(
      id: const CosmeticId('companion_cave_lynx'),
      rarity: Rarity.epic,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticCompanionCaveLynxName,
      description: (l10n) => l10n.cosmeticCompanionCaveLynxDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionCaveLynxUnlockHint,
      assetKey: 'cosmetics.companions.cave_lynx',
      previewAssetKey: 'cosmetics.companions.cave_lynx',
      sortOrder: 735,
      levelGate: 55,
      requiredItems: const [
        CosmeticId('relic_wildwood_charm'),
        CosmeticId('relic_ravine_stone'),
      ],
      // "Lynx … follows walkers carrying scent of distant forests
      // and ravines" — goes deeper with the player. Bonus scales
      // with chapter chain position; resets when a new chapter
      // chain begins.
      buff: const ChapterDepthCompanionBuff(),
    ),
    Companion(
      id: const CosmeticId('companion_aurora_stag'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticCompanionAuroraStagName,
      description: (l10n) => l10n.cosmeticCompanionAuroraStagDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionAuroraStagUnlockHint,
      assetKey: 'cosmetics.companions.aurora_stag',
      previewAssetKey: 'cosmetics.companions.aurora_stag',
      // Tall antlers already fill the canvas — extra scaling clips
      // the crown. Render closer to raw so the antlers stay inside
      // the preview slot.
      displayScale: 0.95,
      sortOrder: 738,
      levelGate: 65,
      requiredItems: const [
        CosmeticId('relic_polar_lantern'),
        CosmeticId('relic_aurora_thread'),
      ],
      // "Ice plain … living aurora" — calm of night. sleepXp fires
      // exactly 1×/day on the sleep daily-goal claim — the narrowest
      // source in the taxonomy. Bumped to +80 % so the per-claim
      // payoff feels worth dedicating the slot to (otherwise a flat
      // mid-tier % loses to broader companions that hit 3-5 claims
      // daily). Daily total contribution still lands well under the
      // 25 % daily share cap because it's a single grant.
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.sleepXp,
        percent: CompanionBuffPercents.auroraStagSleep,
      ),
    ),
    Companion(
      id: const CosmeticId('companion_ice_wisp'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticCompanionIceWispName,
      description: (l10n) => l10n.cosmeticCompanionIceWispDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionIceWispUnlockHint,
      assetKey: 'cosmetics.companions.ice_wisp',
      previewAssetKey: 'cosmetics.companions.ice_wisp',
      // Same small low-biased silhouette pattern as ember sprite —
      // zoom past the empty top half so the wisp reads at a
      // comparable visual size to the other companions.
      displayScale: 1.8,
      sortOrder: 740,
      levelGate: 75,
      requiredItems: const [
        CosmeticId('relic_frozen_lake_heart'),
        CosmeticId('relic_frost_shard'),
      ],
      // "Pale spark drawn out" — drawn to signals / tasks.
      // +30 % on every quest claim (daily + weekly + combo +
      // long-term + daily-challenge).
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.questXp,
        percent: CompanionBuffPercents.iceWispQuest,
      ),
    ),
    Companion(
      id: const CosmeticId('companion_mountain_gryphon'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.dragonMountains,
      name: (l10n) => l10n.cosmeticCompanionMountainGryphonName,
      description: (l10n) => l10n.cosmeticCompanionMountainGryphonDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionMountainGryphonUnlockHint,
      assetKey: 'cosmetics.companions.mountain_gryphon',
      previewAssetKey: 'cosmetics.companions.mountain_gryphon',
      // Wings already span almost the full canvas width — any extra
      // scaling clips them. Render closer to raw so the wingspan
      // stays inside the preview slot.
      displayScale: 0.9,
      sortOrder: 750,
      levelGate: 85,
      requiredItems: const [
        CosmeticId('relic_summit_feather'),
        CosmeticId('relic_stormcrest_plume'),
      ],
      // "Rides high ridges with chosen walker" — strong walker
      // companion. +50 % activityXp (incl. steps).
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.activityXp,
        percent: CompanionBuffPercents.mountainGryphonActivity,
      ),
    ),
    Companion(
      id: const CosmeticId('companion_dragonling'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticCompanionDragonlingName,
      description: (l10n) => l10n.cosmeticCompanionDragonlingDesc,
      unlockHint: (l10n) => l10n.cosmeticCompanionDragonlingUnlockHint,
      assetKey: 'cosmetics.companions.dragonling',
      previewAssetKey: 'cosmetics.companions.dragonling',
      sortOrder: 760,
      levelGate: 95,
      requiredItems: const [
        CosmeticId('relic_dragon_scale'),
        CosmeticId('relic_dragonrock_heart'),
      ],
      // Endgame mistr všeho — +15 % on every XP grant regardless of
      // source. The only `allXp` companion.
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.allXp,
        percent: CompanionBuffPercents.dragonlingAll,
      ),
    ),

    // -------------------------------------------------------------------------
    // Companions — Developer-only (grant via DevTools only)
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Skins — full-body avatar themes resolved per race at render time
    // -------------------------------------------------------------------------

    Skin(
      id: const CosmeticId('skin_pilgrim'),
      rarity: Rarity.common,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticSkinPilgrimName,
      description: (l10n) => l10n.cosmeticSkinPilgrimDesc,
      unlockHint: (l10n) => l10n.cosmeticSkinPilgrimUnlockHint,
      assetKey: 'cosmetics.skins.pilgrim',
      previewAssetKey: 'cosmetics.skins.pilgrim',
      sortOrder: 800,
    ),
    Skin(
      id: const CosmeticId('skin_hunter'),
      rarity: Rarity.uncommon,
      region: CosmeticRegion.forestTrail,
      name: (l10n) => l10n.cosmeticSkinHunterName,
      description: (l10n) => l10n.cosmeticSkinHunterDesc,
      unlockHint: (l10n) => l10n.cosmeticSkinHunterUnlockHint,
      assetKey: 'cosmetics.skins.hunter',
      previewAssetKey: 'cosmetics.skins.hunter',
      sortOrder: 810,
    ),
    Skin(
      id: const CosmeticId('skin_mine'),
      rarity: Rarity.rare,
      region: CosmeticRegion.dwarvenMines,
      name: (l10n) => l10n.cosmeticSkinMineName,
      description: (l10n) => l10n.cosmeticSkinMineDesc,
      unlockHint: (l10n) => l10n.cosmeticSkinMineUnlockHint,
      assetKey: 'cosmetics.skins.mine',
      previewAssetKey: 'cosmetics.skins.mine',
      sortOrder: 820,
    ),
    Skin(
      id: const CosmeticId('skin_frostwalker'),
      rarity: Rarity.epic,
      region: CosmeticRegion.frostlands,
      name: (l10n) => l10n.cosmeticSkinFrostwalkerName,
      description: (l10n) => l10n.cosmeticSkinFrostwalkerDesc,
      unlockHint: (l10n) => l10n.cosmeticSkinFrostwalkerUnlockHint,
      assetKey: 'cosmetics.skins.frostwalker',
      previewAssetKey: 'cosmetics.skins.frostwalker',
      sortOrder: 830,
    ),
    Skin(
      id: const CosmeticId('skin_mage'),
      rarity: Rarity.legendary,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticSkinMageName,
      description: (l10n) => l10n.cosmeticSkinMageDesc,
      unlockHint: (l10n) => l10n.cosmeticSkinMageUnlockHint,
      assetKey: 'cosmetics.skins.mage',
      previewAssetKey: 'cosmetics.skins.mage',
      sortOrder: 840,
    ),
    Skin(
      id: const CosmeticId('skin_dragonrock'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.dragonrockFortress,
      name: (l10n) => l10n.cosmeticSkinDragonrockName,
      description: (l10n) => l10n.cosmeticSkinDragonrockDesc,
      unlockHint: (l10n) => l10n.cosmeticSkinDragonrockUnlockHint,
      assetKey: 'cosmetics.skins.dragonrock',
      previewAssetKey: 'cosmetics.skins.dragonrock',
      sortOrder: 850,
    ),

    // -------------------------------------------------------------------------
    // Skins — Developer-only (grant via DevTools only)
    // -------------------------------------------------------------------------

    Skin(
      id: const CosmeticId('skin_extra'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticSkinExtraName,
      description: (l10n) => l10n.cosmeticSkinExtraDesc,
      assetKey: 'cosmetics.skins.extra',
      previewAssetKey: 'cosmetics.skins.extra',
      sortOrder: 9200,
      metadata: <String, Object?>{'devOnly': true},
    ),

    // -------------------------------------------------------------------------
    // Companions — Developer-only (grant via DevTools only)
    // -------------------------------------------------------------------------

    Companion(
      id: const CosmeticId('companion_monster_energy'),
      rarity: Rarity.mythic,
      region: CosmeticRegion.neutral,
      name: (l10n) => l10n.cosmeticCompanionMonsterEnergyName,
      // Unique description (not the shared devOnlyDesc) — it carries
      // the gag for the +13 % activity buff *and* the secret food
      // trigger, so the details sheet hints at the easter egg
      // without spelling out the keyword.
      description: (l10n) => l10n.cosmeticCompanionMonsterEnergyDesc,
      assetKey: 'cosmetics.companions.monster_energy',
      previewAssetKey: 'cosmetics.companions.monster_energy',
      sortOrder: 9100,
      metadata: <String, Object?>{'devOnly': true},
      // Dev-only gag: mythic rarity, +13 % activity XP. The kofein
      // kopne jen do nohou — sleep / nutrition / quests / chapters
      // all see 0. Nicely also tanks any sleep streak in spirit if
      // not in math.
      buff: const FlatCompanionBuff(
        kind: RewardSourceKind.activityXp,
        percent: 13,
      ),
      // Easter-egg claim — log any food whose name contains
      // "monster" and the companion coughs up XP. perDayMaxXp caps
      // it at three plechovky's worth so a player who decides to
      // farm Monster Energy still hits a wall.
      foodTrigger: const FoodKeywordTrigger(
        keywords: ['monster'],
        perEntryXp: 25,
        perDayMaxXp: 75,
      ),
    ),
  ]);

  List<Cosmetic> get all => definitions;

  Cosmetic? byId(String id) {
    for (final def in definitions) {
      if (def.id == id) return def;
    }
    return null;
  }

  List<Cosmetic> byType(CosmeticType type) {
    return definitions.where((d) => d.type == type).toList(growable: false);
  }

  List<Frame> get frames =>
      definitions.whereType<Frame>().toList(growable: false);
  List<Background> get backgrounds =>
      definitions.whereType<Background>().toList(growable: false);
  List<Companion> get companions =>
      definitions.whereType<Companion>().toList(growable: false);
  List<RelicCosmetic> get relics =>
      definitions.whereType<RelicCosmetic>().toList(growable: false);
  List<Emblem> get emblems =>
      definitions.whereType<Emblem>().toList(growable: false);
  List<TitleFlair> get titleFlairs =>
      definitions.whereType<TitleFlair>().toList(growable: false);
  List<MapEffect> get mapEffects =>
      definitions.whereType<MapEffect>().toList(growable: false);
  List<Skin> get skins =>
      definitions.whereType<Skin>().toList(growable: false);

  List<Cosmetic> byRegion(CosmeticRegion region) {
    return definitions.where((d) => d.region == region).toList(growable: false);
  }

  List<Cosmetic> get enabled {
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
