import '../../config/cosmetics_config.dart';
import '../../config/skin_asset_resolver.dart';
import '../../domain/cosmetic_models.dart';

/// Resolves the on-disk asset path for a cosmetic preview surface
/// (grid tile, details header, equipped chip, quest reward thumb, …).
///
/// Skins live under `assets/cosmetics/skins/<race>/<id>_<variant>.png`
/// and need the player's selected race + a variant suffix, so they
/// can't be resolved through the flat
/// [CosmeticsConfig.resolveAssetPath] template the way frames, relics,
/// backgrounds etc. are. This helper dispatches the skin case to
/// [SkinAssetResolver] and falls back to the flat resolver for every
/// other cosmetic type.
///
/// [raceId] is optional — pre-onboarding players have none, in which
/// case skin previews return null and the calling widget falls back
/// to its placeholder. [skinVariant] defaults to the framed
/// thumbnail used in tiles / chips; surfaces that render the
/// full-body composition (details preview, hero header) pass
/// [SkinAssetVariant.fullBody].
///
/// [usePreviewKey] (default `true`) honours the catalog's small
/// `previewAssetKey` for surfaces that show the cosmetic in a compact
/// tile / chip / reward thumb. Pass `false` for surfaces that need
/// the full-resolution painted asset — the cosmetic details header
/// for companions (170² slot) and the profile hero scene props all
/// pin to the full asset so the silhouette + glow read at scene size.
/// For skins this flag is ignored (skin variant is controlled by
/// [skinVariant], not the catalog key).
String? resolveCosmeticPreviewPath(
  Cosmetic definition, {
  required CosmeticsConfig config,
  required String? raceId,
  SkinAssetVariant skinVariant = SkinAssetVariant.thumbnail,
  bool usePreviewKey = true,
}) {
  final key = usePreviewKey
      ? (definition.previewAssetKey ?? definition.assetKey)
      : definition.assetKey;
  if (definition is Skin) {
    return const SkinAssetResolver().resolve(
      raceId: raceId,
      skinAssetKey: key,
      variant: skinVariant,
    );
  }
  return config.resolveAssetPath(key);
}
