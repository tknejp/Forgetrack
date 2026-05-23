// Domain models for the cosmetics feature: enums and immutable data classes
// used by the catalog, repository and service layers. The cosmetics feature
// is intentionally decoupled from `progression` and `social`.

import '../../../l10n/app_localizations.dart';
import '../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/cosmetics/cosmetic_region.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';

import 'companion_buff.dart';
import 'emblem_buff.dart';
import 'food_trigger.dart';

export '../../../shared/domain/rarity.dart' show Rarity;
// Re-exported from the domain layer so feature-side callers keep using
// `cosmetic_models.dart` as the one-stop import for cosmetic types.
// The canonical home is `lib/domain/cosmetics/cosmetic_region.dart`
// because the cross-feature `CompanionSpec` (consumed by both
// `cosmetics` and `progression_engine`) needs to name it without
// either feature importing the other's domain.
export 'package:forgetrack/domain/cosmetics/cosmetic_region.dart'
    show CosmeticRegion;
export 'companion_buff.dart';
export 'emblem_buff.dart';
export 'food_trigger.dart';

/// Resolves a localized string from the active [AppLocalizations]. Used by
/// [Cosmetic] for player-facing text (name / description / unlock
/// hint) so the catalog itself is the single mapping from cosmetic id to
/// generated `.arb` getter — no separate switch table to maintain.
typedef CosmeticText = String Function(AppLocalizations l10n);

enum CosmeticType {
  frame,
  relic,
  background,
  emblem,
  companion,
  titleFlair,
  mapEffect,
  skin,
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
///
/// Sealed hierarchy with one concrete subtype per [CosmeticType] slot:
/// [Frame], [Background], [Companion], [RelicCosmetic], [Emblem],
/// [TitleFlair], [MapEffect]. Discrimination is by pattern match
/// (`cosmetic is Companion`), not by an enum field.
///
/// The [CosmeticType] enum is retained for slot identification — equipped
/// state keys by slot ([Loadout.slotId]) and the relic catalog
/// disambiguates `Relic` (progression catalog gating node) from
/// [RelicCosmetic] (cosmetic-side visual asset).
///
/// Player-facing text ([name], [description], [unlockHint]) is provided as a
/// closure that pulls the localized string from [AppLocalizations]. Each
/// catalog entry inlines its own `(l) => l.cosmeticXxx` resolver — there is
/// no separate id-to-key switch table. Adding a cosmetic touches the catalog
/// and the `.arb` files, nothing else.
sealed class Cosmetic {
  const Cosmetic({
    required this.id,
    required this.rarity,
    required this.region,
    required this.name,
    required this.description,
    this.assetKey,
    this.previewAssetKey,
    this.sortOrder = 0,
    this.isPremium = false,
    this.isEnabled = true,
    this.unlockHint,
    this.metadata = const <String, Object?>{},
  });

  final CosmeticId id;
  final Rarity rarity;
  final CosmeticRegion region;

  /// Resolves the display name from the active [AppLocalizations]. Typical
  /// usage in the catalog: `name: (l) => l.cosmeticFramePilgrimName`.
  final CosmeticText name;

  /// Resolves the description (player-facing flavour text).
  final CosmeticText description;

  /// Stable asset key in `cosmetics.<type>.<id>` form. Resolved to a path by
  /// `CosmeticsConfig.resolveAssetPath`. Nullable so a definition can ship
  /// without a final image yet.
  final String? assetKey;

  /// Optional smaller preview asset key. Falls back to [assetKey].
  final String? previewAssetKey;

  final int sortOrder;
  final bool isPremium;
  final bool isEnabled;

  /// Resolves the player-facing unlock condition text. Null when the cosmetic
  /// has no hint (e.g. baseline grants, dev-only items).
  final CosmeticText? unlockHint;

  /// Free-form bag for feature-specific overrides (e.g. animation flags).
  final Map<String, Object?> metadata;

  /// Slot identifier. Derived from the concrete subtype — there is no
  /// runtime field; pattern matching (`cosmetic is Companion`) is the
  /// canonical way to discriminate. This getter exists so callers that pass
  /// the slot as a [CosmeticType] value (e.g. `Loadout.slotId`,
  /// `unequip(definition.type)`) stay terse.
  CosmeticType get type;
}

class Frame extends Cosmetic {
  const Frame({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
  });

  @override
  CosmeticType get type => CosmeticType.frame;
}

class Background extends Cosmetic {
  const Background({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
  });

  @override
  CosmeticType get type => CosmeticType.background;
}

class Companion extends Cosmetic {
  const Companion({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
    this.levelGate,
    this.requiredItems = const <CosmeticId>[],
    this.buff,
    this.foodTrigger,
  });

  /// Player level the player must reach before this companion can
  /// unlock through the progression pipeline. `null` means the
  /// companion is granted outside the progression pipeline (today
  /// only DevTools-granted items like Monster Energy), in which case
  /// [requiredItems] is also empty.
  ///
  /// Read by `companions_content.dart` to build the
  /// `CompanionAvailability` node (`LevelAtLeast(N)`) and by
  /// `cosmetic_unlock_rules.dart` to build the `CosmeticUnlockRule`
  /// (`Cond.atLevel(N)`). Neither file holds its own copy of this
  /// value — they read it from here so the catalog row stays the
  /// single source of truth.
  final int? levelGate;

  /// Cosmetic ids the player must own (all of them) to satisfy the
  /// gate. Each id resolves to a [Cosmetic] in [CosmeticCatalog] —
  /// read the resolved entry when you need the item's own attributes
  /// (rarity, region, asset). Empty when the companion has no
  /// ownership prerequisites (today only DevTools-granted items).
  ///
  /// Today every progression companion lists exactly two relics, but
  /// the list shape keeps the contract honest if a future companion
  /// needs three relics, a one-relic + chapter-completion mix, or a
  /// level-only gate.
  final List<CosmeticId> requiredItems;

  /// Passive XP buff this companion grants while equipped in the
  /// active loadout slot. Null when the catalog row has not been
  /// assigned a buff yet (the runtime coverage test
  /// `companion_buff_coverage_test` flags missing assignments).
  final CompanionBuff? buff;

  /// Optional food-driven bonus: when set, the companion grants
  /// claimable XP whenever specific food names appear in today's
  /// nutrition log. Distinct from [buff] — see [FoodTriggerReward]
  /// for the contract. Null on most companions; opt-in per catalog
  /// row.
  final FoodTriggerReward? foodTrigger;

  @override
  CosmeticType get type => CosmeticType.companion;
}

/// Cosmetic-side relic (visual asset). Disambiguated from
/// `Relic` (progression catalog gating node) — both ship under id `relic_*`
/// but represent different concerns. References between them are by id.
class RelicCosmetic extends Cosmetic {
  const RelicCosmetic({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
  });

  @override
  CosmeticType get type => CosmeticType.relic;
}

class Emblem extends Cosmetic {
  const Emblem({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
    this.buff,
  });

  /// XP buff this emblem grants while equipped. `null` means the
  /// emblem is purely cosmetic. See [EmblemBuff] / `docs/emblem_buffs/archive/plan.md`.
  final EmblemBuff? buff;

  @override
  CosmeticType get type => CosmeticType.emblem;
}

class TitleFlair extends Cosmetic {
  const TitleFlair({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
  });

  @override
  CosmeticType get type => CosmeticType.titleFlair;
}

class MapEffect extends Cosmetic {
  const MapEffect({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
  });

  @override
  CosmeticType get type => CosmeticType.mapEffect;
}

/// Avatar skin — a race-agnostic theme (Pilgrim, Hunter, Frostwalker, ...)
/// that resolves to a race-specific asset at render time. Each skin in the
/// catalog represents one visual theme; the player's persisted
/// `selectedRaceId` (on [UserCosmeticsState]) picks which artwork variant
/// to display. See `SkinAssetResolver` for the path composition.
class Skin extends Cosmetic {
  const Skin({
    required super.id,
    required super.rarity,
    required super.region,
    required super.name,
    required super.description,
    super.assetKey,
    super.previewAssetKey,
    super.sortOrder,
    super.isPremium,
    super.isEnabled,
    super.unlockHint,
    super.metadata,
  });

  @override
  CosmeticType get type => CosmeticType.skin;
}

/// Per-user unlock record. Immutable.
class UnlockedCosmetic {
  const UnlockedCosmetic({
    required this.cosmeticId,
    required this.unlockedAt,
    this.sourceType,
    this.sourceId,
  });

  final String cosmeticId; // lint-ignore: untyped-id — UnlockedCosmetic.cosmeticId mirrors CosmeticId; persisted as raw string in Firestore subcollection
  final DateTime unlockedAt;

  /// Free-form string so callers from any feature can attribute the unlock
  /// without forcing this enum on them. Recommended values match
  /// [CosmeticUnlockSource] names.
  final String? sourceType;
  final String? sourceId;
}

/// Snapshot of which cosmetic id is equipped in each slot. Null = nothing
/// equipped in that slot.
///
/// **Phase 12 rename** from `EquippedCosmetics` per proposal Â§2.4. The
/// new name reads as a first-class noun ("the player's loadout") and
/// matches the term every consumer already uses verbally. Same shape,
/// same persistence — the rename is purely lexical.
class Loadout {
  const Loadout({
    this.frameId,
    this.relicId,
    this.backgroundId,
    this.emblemId,
    this.companionId,
    this.titleFlairId,
    this.mapEffectId,
    this.skinId,
  });

  const Loadout.empty()
      : frameId = null,
        relicId = null,
        backgroundId = null,
        emblemId = null,
        companionId = null,
        titleFlairId = null,
        mapEffectId = null,
        skinId = null;

  final String? frameId;
  final String? relicId;
  final String? backgroundId;
  final String? emblemId;
  final String? companionId;
  final String? titleFlairId;
  final String? mapEffectId;
  final String? skinId;

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
      case CosmeticType.skin:
        return skinId;
    }
  }

  Loadout copyWithSlot(CosmeticType type, String? cosmeticId) {
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
      case CosmeticType.skin:
        return copyWith(skinId: cosmeticId, clearSkin: cosmeticId == null);
    }
  }

  Loadout copyWith({
    String? frameId,
    String? relicId,
    String? backgroundId,
    String? emblemId,
    String? companionId,
    String? titleFlairId,
    String? mapEffectId,
    String? skinId,
    bool clearFrame = false,
    bool clearRelic = false,
    bool clearBackground = false,
    bool clearEmblem = false,
    bool clearCompanion = false,
    bool clearTitleFlair = false,
    bool clearMapEffect = false,
    bool clearSkin = false,
  }) {
    return Loadout(
      frameId: clearFrame ? null : (frameId ?? this.frameId),
      relicId: clearRelic ? null : (relicId ?? this.relicId),
      backgroundId:
          clearBackground ? null : (backgroundId ?? this.backgroundId),
      emblemId: clearEmblem ? null : (emblemId ?? this.emblemId),
      companionId: clearCompanion ? null : (companionId ?? this.companionId),
      titleFlairId:
          clearTitleFlair ? null : (titleFlairId ?? this.titleFlairId),
      mapEffectId: clearMapEffect ? null : (mapEffectId ?? this.mapEffectId),
      skinId: clearSkin ? null : (skinId ?? this.skinId),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Loadout &&
        other.frameId == frameId &&
        other.relicId == relicId &&
        other.backgroundId == backgroundId &&
        other.emblemId == emblemId &&
        other.companionId == companionId &&
        other.titleFlairId == titleFlairId &&
        other.mapEffectId == mapEffectId &&
        other.skinId == skinId;
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
        skinId,
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
    this.selectedRaceId,
  });

  final String uid; // lint-ignore: untyped-id — Firebase Auth uid is a platform-boundary raw string

  /// Keyed by cosmetic id for O(1) membership checks.
  final Map<String, UnlockedCosmetic> unlocked;
  final Loadout equipped;
  final DateTime updatedAt;

  /// Persisted [HeroRace] id picked at onboarding. `null` until the player
  /// completes race selection. Once set, the chosen race is permanent for
  /// the lifetime of this user state (factory reset / new device login is
  /// the only way to re-pick). Drives the asset path of every equipped
  /// [Skin] through `SkinAssetResolver`.
  final String? selectedRaceId;

  bool isUnlocked(String cosmeticId) => unlocked.containsKey(cosmeticId);

  UserCosmeticsState copyWith({
    Map<String, UnlockedCosmetic>? unlocked,
    Loadout? equipped,
    DateTime? updatedAt,
    String? selectedRaceId,
    bool clearSelectedRaceId = false,
  }) {
    return UserCosmeticsState(
      uid: uid,
      unlocked: unlocked ?? this.unlocked,
      equipped: equipped ?? this.equipped,
      updatedAt: updatedAt ?? this.updatedAt,
      selectedRaceId: clearSelectedRaceId
          ? null
          : (selectedRaceId ?? this.selectedRaceId),
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
