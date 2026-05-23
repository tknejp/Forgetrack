import 'package:meta/meta.dart';

import 'cosmetic_models.dart' show CosmeticText;

/// Stable id of a [HeroRace] catalog row. Persists in
/// `UserCosmeticsState.selectedRaceId` and on `SocialUserProfile.raceId`
/// (Phase 7 wire format extension).
///
/// Extension type over [String] so the id can flow through repositories,
/// providers and Firestore payloads as a plain string with no boxing,
/// while construction sites stay typed (`HeroRaceId('race_human_male')`
/// catches typos compared to a raw `String`).
extension type const HeroRaceId(String value) implements String {
  /// Stylistic alias for [value]. Matches `ProgressionEntryId.raw`.
  String get raw => value;
}

/// Permanent visual identity picked once at onboarding. Drives the
/// `<race>/` subfolder of every equipped [Skin] asset through
/// [SkinAssetResolver].
///
/// `HeroRace` is NOT a [Cosmetic] subtype — it never flows through
/// the unlock/reward pipeline. The 9 races ship in
/// [HeroRaceCatalog.definitions] and are all available from boot;
/// the player picks one in onboarding Step 1 and the choice is
/// persisted on `UserCosmeticsState`. Re-pick UI does not exist in
/// MVP — factory reset is the only way to flip the choice.
@immutable
class HeroRace {
  const HeroRace({
    required this.id,
    required this.folder,
    required this.name,
    required this.description,
  });

  final HeroRaceId id;

  /// Asset folder name under `assets/cosmetics/skins/`. Stable
  /// technical identifier — kept separate from [name] (which is
  /// localized + UX-stylized) so artwork paths never depend on l10n
  /// changes.
  final String folder;

  /// Resolves the display name from the active `AppLocalizations`.
  /// Male / female variants of the same species share one key
  /// (`heroRaceHumanName`) — the visual portrait communicates the
  /// gender, the text label communicates the species.
  final CosmeticText name;

  /// Resolves the species-level flavor description. Shared across
  /// male / female variants (same lore, different look).
  final CosmeticText description;
}
