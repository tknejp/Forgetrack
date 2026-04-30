import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';

/// Runtime configuration for the cosmetics feature.
///
/// Centralises:
///   * the asset key → file path mapping (so widgets never hard-code paths),
///   * which cosmetic slots are currently allowed,
///   * default equipped cosmetics for fresh users,
///   * display ordering for rarities and regions,
///   * feature flags (premium, experimental types).
class CosmeticsConfig {
  const CosmeticsConfig({
    required this.defaultEquipped,
    required this.allowedSlots,
    required this.rarityDisplayOrder,
    required this.regionDisplayOrder,
    this.premiumEnabled = true,
    this.experimentalTypesEnabled = false,
  });

  /// Reasonable defaults. Use this in production wiring; tests can build a
  /// custom config.
  factory CosmeticsConfig.standard() {
    return const CosmeticsConfig(
      defaultEquipped: EquippedCosmetics.empty(),
      allowedSlots: <CosmeticType>{
        CosmeticType.frame,
        CosmeticType.relic,
        CosmeticType.background,
        CosmeticType.emblem,
        CosmeticType.companion,
        CosmeticType.titleFlair,
        // mapEffect intentionally omitted — gated behind experimentalTypesEnabled.
      },
      rarityDisplayOrder: <CosmeticRarity>[
        CosmeticRarity.common,
        CosmeticRarity.rare,
        CosmeticRarity.epic,
        CosmeticRarity.legendary,
      ],
      regionDisplayOrder: <CosmeticRegion>[
        CosmeticRegion.neutral,
        CosmeticRegion.forestTrail,
        CosmeticRegion.ruinedPass,
        CosmeticRegion.dwarvenMines,
        CosmeticRegion.frostlands,
        CosmeticRegion.dragonMountains,
        CosmeticRegion.dragonrockFortress,
      ],
    );
  }

  final EquippedCosmetics defaultEquipped;
  final Set<CosmeticType> allowedSlots;
  final List<CosmeticRarity> rarityDisplayOrder;
  final List<CosmeticRegion> regionDisplayOrder;
  final bool premiumEnabled;
  final bool experimentalTypesEnabled;

  /// Maps a stable asset key (`cosmetics.frames.pilgrim`) to a Flutter asset
  /// path (`assets/cosmetics/frames/pilgrim.png`). Returns null when the key
  /// is null or unparseable; widgets must handle null and fall back to a
  /// drawn placeholder.
  String? resolveAssetPath(String? assetKey) {
    if (assetKey == null || assetKey.isEmpty) return null;
    final parts = assetKey.split('.');
    if (parts.length < 3 || parts.first != 'cosmetics') return null;
    final bucket = _bucketFolder(parts[1]);
    if (bucket == null) return null;
    final name = parts.sublist(2).join('_');
    if (name.isEmpty) return null;
    return 'assets/cosmetics/$bucket/$name.png';
  }

  /// True if a cosmetic is currently usable given config flags. Catalog
  /// `isEnabled` is the static gate; this layer adds runtime gating
  /// (premium, experimental, slot availability).
  bool isUsable(CosmeticDefinition definition) {
    if (!definition.isEnabled) return false;
    if (definition.isPremium && !premiumEnabled) return false;
    if (!_slotEnabled(definition.type)) return false;
    return true;
  }

  bool _slotEnabled(CosmeticType type) {
    if (allowedSlots.contains(type)) return true;
    if (type == CosmeticType.mapEffect && experimentalTypesEnabled) return true;
    return false;
  }

  /// Verifies that any non-null id in [defaultEquipped] exists in the catalog
  /// and is enabled. Returns warnings; empty list means valid.
  List<String> validate(CosmeticCatalog catalog) {
    final warnings = <String>[];
    void check(String slot, String? id, CosmeticType expectedType) {
      if (id == null) return;
      final def = catalog.byId(id);
      if (def == null) {
        warnings.add('defaultEquipped.$slot points to unknown id "$id"');
        return;
      }
      if (def.type != expectedType) {
        warnings.add(
          'defaultEquipped.$slot has wrong type '
          '(${def.type.name}, expected ${expectedType.name})',
        );
      }
      if (!def.isEnabled) {
        warnings.add('defaultEquipped.$slot points to disabled cosmetic "$id"');
      }
    }

    check('frameId', defaultEquipped.frameId, CosmeticType.frame);
    check('relicId', defaultEquipped.relicId, CosmeticType.relic);
    check('backgroundId', defaultEquipped.backgroundId, CosmeticType.background);
    check('emblemId', defaultEquipped.emblemId, CosmeticType.emblem);
    check('companionId', defaultEquipped.companionId, CosmeticType.companion);
    check('titleFlairId', defaultEquipped.titleFlairId, CosmeticType.titleFlair);
    check('mapEffectId', defaultEquipped.mapEffectId, CosmeticType.mapEffect);
    return warnings;
  }

  static String? _bucketFolder(String typeKey) {
    switch (typeKey) {
      case 'frames':
        return 'frames';
      case 'relics':
        return 'relics';
      case 'backgrounds':
        return 'backgrounds';
      case 'emblems':
        return 'emblems';
      case 'companions':
        return 'companions';
      case 'title_flairs':
        return 'title_flairs';
      case 'map_effects':
        return 'map_effects';
    }
    return null;
  }
}
