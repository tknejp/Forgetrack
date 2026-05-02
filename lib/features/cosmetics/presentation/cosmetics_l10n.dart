import '../../../l10n/app_localizations.dart';
import '../domain/cosmetic_models.dart';

/// Maps stable cosmetic ids to localised strings. Keep all id-based switches
/// in this file so adding a new cosmetic only touches one localisation
/// translation point (besides the catalog and the .arb files).
///
/// Falls back to `definition.id` when an id has no translation yet — this
/// keeps debug builds usable while new cosmetics are being added before
/// their .arb entries land.
class CosmeticsL10n {
  CosmeticsL10n(this._l10n);

  final AppLocalizations _l10n;

  String name(CosmeticDefinition definition) {
    switch (definition.id) {
      case 'frame_lvl1':
        return _l10n.cosmeticFrameLvl1Name;
      case 'frame_lvl10':
        return _l10n.cosmeticFrameLvl10Name;
      case 'frame_lvl25':
        return _l10n.cosmeticFrameLvl25Name;
      case 'frame_lvl40':
        return _l10n.cosmeticFrameLvl40Name;
      case 'frame_lvl60':
        return _l10n.cosmeticFrameLvl60Name;
      case 'frame_lvl80':
        return _l10n.cosmeticFrameLvl80Name;
      case 'frame_lvl100':
        return _l10n.cosmeticFrameLvl100Name;
      case 'frame_developer_tom':
        return 'Developer frame';

      case 'background_dev_altar':
        return 'Dev: Altar';
      case 'background_dev_camp':
        return 'Dev: Camp';
      case 'background_dev_hacker':
        return 'Dev: Hacker';
      case 'background_dev_lord':
        return 'Dev: Lord';
      case 'background_dev_mines':
        return 'Dev: Mines';
      case 'background_dev_throne':
        return 'Dev: Throne';

      case 'relic_old_compass':
        return _l10n.cosmeticRelicOldCompassName;
      case 'background_forest_trail':
        return _l10n.cosmeticBackgroundForestTrailName;
      case 'emblem_forest_mark':
        return _l10n.cosmeticEmblemForestMarkName;
      case 'relic_old_gate_key':
        return _l10n.cosmeticRelicOldGateKeyName;

      case 'background_camp':
        return _l10n.cosmeticBackgroundCampName;
      case 'background_ravine':
        return _l10n.cosmeticBackgroundRavineName;
      case 'background_ruins':
        return _l10n.cosmeticBackgroundRuinsName;
      case 'background_bridge_crossing':
        return _l10n.cosmeticBackgroundBridgeCrossingName;
      case 'background_mines':
        return _l10n.cosmeticBackgroundMinesName;
      case 'background_frostlands':
        return _l10n.cosmeticBackgroundFrostlandsName;
      case 'background_frozen_lake':
        return _l10n.cosmeticBackgroundFrozenLakeName;
      case 'background_rocky_mountains':
        return _l10n.cosmeticBackgroundRockyMountainsName;
      case 'background_dragonrock_fortress':
        return _l10n.cosmeticBackgroundDragonrockFortressName;

      case 'emblem_pilgrim_mark':
        return _l10n.cosmeticEmblemPilgrimMarkName;
      case 'emblem_ruin_sigil':
        return _l10n.cosmeticEmblemRuinSigilName;
      case 'emblem_gatekeeper_mark':
        return _l10n.cosmeticEmblemGatekeeperMarkName;
      case 'emblem_mine_crest':
        return _l10n.cosmeticEmblemMineCrestName;
      case 'emblem_underways_mark':
        return _l10n.cosmeticEmblemUnderwaysMarkName;
      case 'emblem_frost_sigil':
        return _l10n.cosmeticEmblemFrostSigilName;
      case 'emblem_icewalker_mark':
        return _l10n.cosmeticEmblemIcewalkerMarkName;
      case 'emblem_mountain_crest':
        return _l10n.cosmeticEmblemMountainCrestName;
      case 'emblem_dragon_mark':
        return _l10n.cosmeticEmblemDragonMarkName;
      case 'emblem_dragonrock_emblem':
        return _l10n.cosmeticEmblemDragonrockEmblemName;

      case 'relic_campfire_spark':
        return _l10n.cosmeticRelicCampfireSparkName;
      case 'relic_pilgrim_cloak':
        return _l10n.cosmeticRelicPilgrimCloakName;
      case 'relic_trail_compass':
        return _l10n.cosmeticRelicTrailCompassName;
      case 'relic_ancient_root':
        return _l10n.cosmeticRelicAncientRootName;
      case 'relic_ravine_stone':
        return _l10n.cosmeticRelicRavineStoneName;
      case 'relic_ruin_seal':
        return _l10n.cosmeticRelicRuinSealName;
      case 'relic_bridge_key':
        return _l10n.cosmeticRelicBridgeKeyName;
      case 'relic_miners_lantern':
        return _l10n.cosmeticRelicMinersLanternName;
      case 'relic_polar_lantern':
        return _l10n.cosmeticRelicPolarLanternName;
      case 'relic_frost_shard':
        return _l10n.cosmeticRelicFrostShardName;
      case 'relic_frozen_lake_heart':
        return _l10n.cosmeticRelicFrozenLakeHeartName;
      case 'relic_dragon_scale':
        return _l10n.cosmeticRelicDragonScaleName;
      case 'relic_dragon_crown':
        return _l10n.cosmeticRelicDragonCrownName;
      case 'relic_dragonrock_crown':
        return _l10n.cosmeticRelicDragonrockCrownName;

      case 'frame_discipline':
        return _l10n.cosmeticFrameDisciplineName;
      case 'frame_endurance':
        return _l10n.cosmeticFrameEnduranceName;
      case 'frame_steel':
        return _l10n.cosmeticFrameSteelName;
      case 'frame_eternal_flame':
        return _l10n.cosmeticFrameEternalFlameName;
      case 'frame_balance':
        return _l10n.cosmeticFrameBalanceName;
      case 'frame_master_routine':
        return _l10n.cosmeticFrameMasterRoutineName;
      case 'frame_endless_trail':
        return _l10n.cosmeticFrameEndlessTrailName;
      case 'frame_worldwalker':
        return _l10n.cosmeticFrameWorldwalkerName;

      case 'companion_ember_sprite':
        return _l10n.cosmeticCompanionEmberSpriteName;
      case 'companion_forest_fox':
        return _l10n.cosmeticCompanionForestFoxName;
      case 'companion_ruin_raven':
        return _l10n.cosmeticCompanionRuinRavenName;
      case 'companion_lantern_golem':
        return _l10n.cosmeticCompanionLanternGolemName;
      case 'companion_ice_wisp':
        return _l10n.cosmeticCompanionIceWispName;
      case 'companion_mountain_gryphon':
        return _l10n.cosmeticCompanionMountainGryphonName;
      case 'companion_dragonling':
        return _l10n.cosmeticCompanionDragonlingName;
    }

    return definition.id;
  }

  String description(CosmeticDefinition definition) {
    switch (definition.id) {
      case 'frame_lvl1':
        return _l10n.cosmeticFrameLvl1Desc;
      case 'frame_lvl10':
        return _l10n.cosmeticFrameLvl10Desc;
      case 'frame_lvl25':
        return _l10n.cosmeticFrameLvl25Desc;
      case 'frame_lvl40':
        return _l10n.cosmeticFrameLvl40Desc;
      case 'frame_lvl60':
        return _l10n.cosmeticFrameLvl60Desc;
      case 'frame_lvl80':
        return _l10n.cosmeticFrameLvl80Desc;
      case 'frame_lvl100':
        return _l10n.cosmeticFrameLvl100Desc;
      case 'frame_developer_tom':
        return 'Specialni ramecek odemceny pres Firebase entitlement.';

      case 'background_dev_altar':
      case 'background_dev_camp':
      case 'background_dev_hacker':
      case 'background_dev_lord':
      case 'background_dev_mines':
      case 'background_dev_throne':
        return 'Developer-only background. Grant via DevTools.';

      case 'relic_old_compass':
        return _l10n.cosmeticRelicOldCompassDesc;
      case 'background_forest_trail':
        return _l10n.cosmeticBackgroundForestTrailDesc;
      case 'emblem_forest_mark':
        return _l10n.cosmeticEmblemForestMarkDesc;
      case 'relic_old_gate_key':
        return _l10n.cosmeticRelicOldGateKeyDesc;

      case 'background_camp':
        return _l10n.cosmeticBackgroundCampDesc;
      case 'background_ravine':
        return _l10n.cosmeticBackgroundRavineDesc;
      case 'background_ruins':
        return _l10n.cosmeticBackgroundRuinsDesc;
      case 'background_bridge_crossing':
        return _l10n.cosmeticBackgroundBridgeCrossingDesc;
      case 'background_mines':
        return _l10n.cosmeticBackgroundMinesDesc;
      case 'background_frostlands':
        return _l10n.cosmeticBackgroundFrostlandsDesc;
      case 'background_frozen_lake':
        return _l10n.cosmeticBackgroundFrozenLakeDesc;
      case 'background_rocky_mountains':
        return _l10n.cosmeticBackgroundRockyMountainsDesc;
      case 'background_dragonrock_fortress':
        return _l10n.cosmeticBackgroundDragonrockFortressDesc;

      case 'emblem_pilgrim_mark':
        return _l10n.cosmeticEmblemPilgrimMarkDesc;
      case 'emblem_ruin_sigil':
        return _l10n.cosmeticEmblemRuinSigilDesc;
      case 'emblem_gatekeeper_mark':
        return _l10n.cosmeticEmblemGatekeeperMarkDesc;
      case 'emblem_mine_crest':
        return _l10n.cosmeticEmblemMineCrestDesc;
      case 'emblem_underways_mark':
        return _l10n.cosmeticEmblemUnderwaysMarkDesc;
      case 'emblem_frost_sigil':
        return _l10n.cosmeticEmblemFrostSigilDesc;
      case 'emblem_icewalker_mark':
        return _l10n.cosmeticEmblemIcewalkerMarkDesc;
      case 'emblem_mountain_crest':
        return _l10n.cosmeticEmblemMountainCrestDesc;
      case 'emblem_dragon_mark':
        return _l10n.cosmeticEmblemDragonMarkDesc;
      case 'emblem_dragonrock_emblem':
        return _l10n.cosmeticEmblemDragonrockEmblemDesc;

      case 'relic_campfire_spark':
        return _l10n.cosmeticRelicCampfireSparkDesc;
      case 'relic_pilgrim_cloak':
        return _l10n.cosmeticRelicPilgrimCloakDesc;
      case 'relic_trail_compass':
        return _l10n.cosmeticRelicTrailCompassDesc;
      case 'relic_ancient_root':
        return _l10n.cosmeticRelicAncientRootDesc;
      case 'relic_ravine_stone':
        return _l10n.cosmeticRelicRavineStoneDesc;
      case 'relic_ruin_seal':
        return _l10n.cosmeticRelicRuinSealDesc;
      case 'relic_bridge_key':
        return _l10n.cosmeticRelicBridgeKeyDesc;
      case 'relic_miners_lantern':
        return _l10n.cosmeticRelicMinersLanternDesc;
      case 'relic_polar_lantern':
        return _l10n.cosmeticRelicPolarLanternDesc;
      case 'relic_frost_shard':
        return _l10n.cosmeticRelicFrostShardDesc;
      case 'relic_frozen_lake_heart':
        return _l10n.cosmeticRelicFrozenLakeHeartDesc;
      case 'relic_dragon_scale':
        return _l10n.cosmeticRelicDragonScaleDesc;
      case 'relic_dragon_crown':
        return _l10n.cosmeticRelicDragonCrownDesc;
      case 'relic_dragonrock_crown':
        return _l10n.cosmeticRelicDragonrockCrownDesc;

      case 'frame_discipline':
        return _l10n.cosmeticFrameDisciplineDesc;
      case 'frame_endurance':
        return _l10n.cosmeticFrameEnduranceDesc;
      case 'frame_steel':
        return _l10n.cosmeticFrameSteelDesc;
      case 'frame_eternal_flame':
        return _l10n.cosmeticFrameEternalFlameDesc;
      case 'frame_balance':
        return _l10n.cosmeticFrameBalanceDesc;
      case 'frame_master_routine':
        return _l10n.cosmeticFrameMasterRoutineDesc;
      case 'frame_endless_trail':
        return _l10n.cosmeticFrameEndlessTrailDesc;
      case 'frame_worldwalker':
        return _l10n.cosmeticFrameWorldwalkerDesc;

      case 'companion_ember_sprite':
        return _l10n.cosmeticCompanionEmberSpriteDesc;
      case 'companion_forest_fox':
        return _l10n.cosmeticCompanionForestFoxDesc;
      case 'companion_ruin_raven':
        return _l10n.cosmeticCompanionRuinRavenDesc;
      case 'companion_lantern_golem':
        return _l10n.cosmeticCompanionLanternGolemDesc;
      case 'companion_ice_wisp':
        return _l10n.cosmeticCompanionIceWispDesc;
      case 'companion_mountain_gryphon':
        return _l10n.cosmeticCompanionMountainGryphonDesc;
      case 'companion_dragonling':
        return _l10n.cosmeticCompanionDragonlingDesc;
    }

    return definition.descriptionKey;
  }

  String get equippedBadge => _l10n.cosmeticEquippedBadge;

  String get unknownCosmetic => _l10n.cosmeticUnknown;
}
