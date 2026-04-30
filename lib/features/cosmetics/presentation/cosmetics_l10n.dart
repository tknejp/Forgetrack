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

      case 'relic_old_compass':
        return _l10n.cosmeticRelicOldCompassName;
      case 'background_forest_trail':
        return _l10n.cosmeticBackgroundForestTrailName;
      case 'emblem_forest_mark':
        return _l10n.cosmeticEmblemForestMarkName;
      case 'relic_old_gate_key':
        return _l10n.cosmeticRelicOldGateKeyName;
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

      case 'relic_old_compass':
        return _l10n.cosmeticRelicOldCompassDesc;
      case 'background_forest_trail':
        return _l10n.cosmeticBackgroundForestTrailDesc;
      case 'emblem_forest_mark':
        return _l10n.cosmeticEmblemForestMarkDesc;
      case 'relic_old_gate_key':
        return _l10n.cosmeticRelicOldGateKeyDesc;
    }

    return definition.descriptionKey;
  }

  String get equippedBadge => _l10n.cosmeticEquippedBadge;

  String get unknownCosmetic => _l10n.cosmeticUnknown;
}
