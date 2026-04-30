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
