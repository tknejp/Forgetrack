import '../domain/hero_race_catalog.dart';

/// Which rendering context the skin asset is being requested for.
/// Maps to a file-name suffix on disk — `_full.png` is the standalone
/// full-body composition shown on the profile + hero header (no frame
/// border), `_thumb.png` is the framed mini variant shown on top app
/// bar, social feed cards, notification cards, settings header, ...
enum SkinAssetVariant {
  /// Full-body artwork rendered directly on the active background
  /// scene. Used on the profile screen + hero progression header.
  /// No frame cosmetic applies — the figure stands alone in the scene.
  fullBody,

  /// Mini portrait composed inside the equipped frame cosmetic. Used
  /// everywhere the avatar appears in a compact tile (top app bar,
  /// social feed avatars, notifications, settings, friend chips, …).
  thumbnail,
}

/// Composes the disk path of a [Skin] asset from the player's chosen
/// race + the skin's race-agnostic asset key.
///
/// Skin catalog entries carry a template asset key
/// (`cosmetics.skins.<id>`); the resolver substitutes in the race
/// folder + a per-context variant suffix to land on a concrete file:
///
/// ```
/// raceId='race_orc' + 'cosmetics.skins.pilgrim' + fullBody
///   → 'assets/cosmetics/skins/orc/pilgrim_full.png'
/// raceId='race_human_female' + 'cosmetics.skins.frostwalker' + thumbnail
///   → 'assets/cosmetics/skins/human_female/frostwalker_thumb.png'
/// ```
///
/// Returns `null` for any caller without a race set (pre-onboarding)
/// or with an unknown race / malformed asset key — callers render a
/// silhouette placeholder when the result is null rather than crashing
/// on a missing asset.
class SkinAssetResolver {
  const SkinAssetResolver();

  String? resolve({
    required String? raceId,
    required String? skinAssetKey,
    SkinAssetVariant variant = SkinAssetVariant.fullBody,
  }) {
    if (raceId == null) return null;
    if (skinAssetKey == null || skinAssetKey.isEmpty) return null;

    final race = HeroRaceCatalog.byId(raceId);
    if (race == null) return null;

    final parts = skinAssetKey.split('.');
    if (parts.length < 3) return null;
    if (parts[0] != 'cosmetics' || parts[1] != 'skins') return null;

    final skinName = parts.sublist(2).join('_');
    if (skinName.isEmpty) return null;

    final suffix = switch (variant) {
      SkinAssetVariant.fullBody => 'full',
      SkinAssetVariant.thumbnail => 'thumb',
    };
    return 'assets/cosmetics/skins/${race.folder}/${skinName}_$suffix.png';
  }
}
