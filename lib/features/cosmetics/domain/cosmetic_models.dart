// Domain models for the cosmetics feature: enums and immutable data classes
// used by the catalog, repository and service layers. The cosmetics feature
// is intentionally decoupled from `progression` and `social`.

enum CosmeticType {
  frame,
  relic,
  background,
  emblem,
  companion,
  titleFlair,
  mapEffect,
}

enum CosmeticRarity {
  common,
  rare,
  epic,
  legendary,
}

enum CosmeticRegion {
  forestTrail,
  ruinedPass,
  dwarvenMines,
  frostlands,
  dragonMountains,
  dragonrockFortress,
  neutral,
}

/// Where an unlock came from. Stored as part of [UnlockedCosmetic] for audit.
/// Open-set on purpose — features that unlock cosmetics may add their own
/// values; consumers should treat unknown values as informational only.
enum CosmeticUnlockSource {
  defaultBaseline,
  progressionLevel,
  achievement,
  quest,
  manual,
  promotional,
  other,
}

/// Static definition of a cosmetic. Lives in [CosmeticCatalog]; never mutated
/// at runtime.
class CosmeticDefinition {
  const CosmeticDefinition({
    required this.id,
    required this.type,
    required this.rarity,
    required this.region,
    required this.nameKey,
    required this.descriptionKey,
    this.assetKey,
    this.previewAssetKey,
    this.sortOrder = 0,
    this.isPremium = false,
    this.isEnabled = true,
    this.unlockHintKey,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final CosmeticType type;
  final CosmeticRarity rarity;
  final CosmeticRegion region;

  /// Localization key for the display name (resolved via l10n later).
  final String nameKey;

  /// Localization key for the description (resolved via l10n later).
  final String descriptionKey;

  /// Stable asset key in `cosmetics.<type>.<id>` form. Resolved to a path by
  /// `CosmeticsConfig.resolveAssetPath`. Nullable so a definition can ship
  /// without a final image yet.
  final String? assetKey;

  /// Optional smaller preview asset key. Falls back to [assetKey].
  final String? previewAssetKey;

  final int sortOrder;
  final bool isPremium;
  final bool isEnabled;

  /// Optional localization key for an in-UI hint about how to unlock this.
  final String? unlockHintKey;

  /// Free-form bag for feature-specific overrides (e.g. animation flags).
  final Map<String, Object?> metadata;
}

/// Per-user unlock record. Immutable.
class UnlockedCosmetic {
  const UnlockedCosmetic({
    required this.cosmeticId,
    required this.unlockedAt,
    this.sourceType,
    this.sourceId,
  });

  final String cosmeticId;
  final DateTime unlockedAt;

  /// Free-form string so callers from any feature can attribute the unlock
  /// without forcing this enum on them. Recommended values match
  /// [CosmeticUnlockSource] names.
  final String? sourceType;
  final String? sourceId;
}

/// Snapshot of which cosmetic id is equipped in each slot. Null = nothing
/// equipped in that slot.
class EquippedCosmetics {
  const EquippedCosmetics({
    this.frameId,
    this.relicId,
    this.backgroundId,
    this.emblemId,
    this.companionId,
    this.titleFlairId,
    this.mapEffectId,
  });

  const EquippedCosmetics.empty()
      : frameId = null,
        relicId = null,
        backgroundId = null,
        emblemId = null,
        companionId = null,
        titleFlairId = null,
        mapEffectId = null;

  final String? frameId;
  final String? relicId;
  final String? backgroundId;
  final String? emblemId;
  final String? companionId;
  final String? titleFlairId;
  final String? mapEffectId;

  String? slotId(CosmeticType type) {
    switch (type) {
      case CosmeticType.frame:
        return frameId;
      case CosmeticType.relic:
        return relicId;
      case CosmeticType.background:
        return backgroundId;
      case CosmeticType.emblem:
        return emblemId;
      case CosmeticType.companion:
        return companionId;
      case CosmeticType.titleFlair:
        return titleFlairId;
      case CosmeticType.mapEffect:
        return mapEffectId;
    }
  }

  EquippedCosmetics copyWithSlot(CosmeticType type, String? cosmeticId) {
    switch (type) {
      case CosmeticType.frame:
        return copyWith(frameId: cosmeticId, clearFrame: cosmeticId == null);
      case CosmeticType.relic:
        return copyWith(relicId: cosmeticId, clearRelic: cosmeticId == null);
      case CosmeticType.background:
        return copyWith(
          backgroundId: cosmeticId,
          clearBackground: cosmeticId == null,
        );
      case CosmeticType.emblem:
        return copyWith(emblemId: cosmeticId, clearEmblem: cosmeticId == null);
      case CosmeticType.companion:
        return copyWith(
          companionId: cosmeticId,
          clearCompanion: cosmeticId == null,
        );
      case CosmeticType.titleFlair:
        return copyWith(
          titleFlairId: cosmeticId,
          clearTitleFlair: cosmeticId == null,
        );
      case CosmeticType.mapEffect:
        return copyWith(
          mapEffectId: cosmeticId,
          clearMapEffect: cosmeticId == null,
        );
    }
  }

  EquippedCosmetics copyWith({
    String? frameId,
    String? relicId,
    String? backgroundId,
    String? emblemId,
    String? companionId,
    String? titleFlairId,
    String? mapEffectId,
    bool clearFrame = false,
    bool clearRelic = false,
    bool clearBackground = false,
    bool clearEmblem = false,
    bool clearCompanion = false,
    bool clearTitleFlair = false,
    bool clearMapEffect = false,
  }) {
    return EquippedCosmetics(
      frameId: clearFrame ? null : (frameId ?? this.frameId),
      relicId: clearRelic ? null : (relicId ?? this.relicId),
      backgroundId:
          clearBackground ? null : (backgroundId ?? this.backgroundId),
      emblemId: clearEmblem ? null : (emblemId ?? this.emblemId),
      companionId: clearCompanion ? null : (companionId ?? this.companionId),
      titleFlairId:
          clearTitleFlair ? null : (titleFlairId ?? this.titleFlairId),
      mapEffectId: clearMapEffect ? null : (mapEffectId ?? this.mapEffectId),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EquippedCosmetics &&
        other.frameId == frameId &&
        other.relicId == relicId &&
        other.backgroundId == backgroundId &&
        other.emblemId == emblemId &&
        other.companionId == companionId &&
        other.titleFlairId == titleFlairId &&
        other.mapEffectId == mapEffectId;
  }

  @override
  int get hashCode => Object.hash(
        frameId,
        relicId,
        backgroundId,
        emblemId,
        companionId,
        titleFlairId,
        mapEffectId,
      );
}

/// Per-user state held by the repository. Immutable; replaced wholesale on
/// each mutation so [ChangeNotifier] consumers always see a stable snapshot.
class UserCosmeticsState {
  const UserCosmeticsState({
    required this.uid,
    required this.unlocked,
    required this.equipped,
    required this.updatedAt,
  });

  final String uid;

  /// Keyed by cosmetic id for O(1) membership checks.
  final Map<String, UnlockedCosmetic> unlocked;
  final EquippedCosmetics equipped;
  final DateTime updatedAt;

  bool isUnlocked(String cosmeticId) => unlocked.containsKey(cosmeticId);

  UserCosmeticsState copyWith({
    Map<String, UnlockedCosmetic>? unlocked,
    EquippedCosmetics? equipped,
    DateTime? updatedAt,
  }) {
    return UserCosmeticsState(
      uid: uid,
      unlocked: unlocked ?? this.unlocked,
      equipped: equipped ?? this.equipped,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Result of a pre-equip check. Use this instead of throwing for UI flows
/// that want to show a disabled state with a reason tooltip.
class CanEquipResult {
  const CanEquipResult.ok()
      : ok = true,
        reason = null;

  const CanEquipResult.blocked(this.reason) : ok = false;

  final bool ok;
  final String? reason;
}

/// Typed exception thrown by the cosmetics service/repository on invalid
/// operations. Catch this to surface user-facing errors without leaking
/// implementation details.
class CosmeticsException implements Exception {
  const CosmeticsException(this.code, this.message);

  /// Machine-readable code so callers can switch on it without parsing
  /// [message]. Keep stable across versions.
  final String code;
  final String message;

  @override
  String toString() => 'CosmeticsException($code): $message';
}
