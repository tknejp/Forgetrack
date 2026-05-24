import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/skin_asset_resolver.dart';
import '../../../cosmetics/domain/cosmetic_catalog.dart';

/// Compact avatar tile for the signed-in user and friends.
///
/// Render priority:
/// 1. `raceId` + `skinId` → resolves a race-specific skin thumbnail via
///    [SkinAssetResolver] and paints it. This is the canonical post-
///    race-system rendering — every compact surface (top bar, social
///    feed, settings, leaderboard, friend chips) shows the player's
///    chosen race × skin instead of the Google identity selfie.
/// 2. `photoUrl` — transitional fallback retained ONLY for legacy
///    actor / reactor snapshots embedded in older share documents
///    (where raceId/skinId were never captured). New compact-surface
///    callsites should not pass `photoUrl`.
/// 3. Initials derived from `name` — final fallback when neither
///    skin nor photo is available (e.g., friend on a client that
///    predates the race-system rollout).
class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.name,
    required this.size,
    this.raceId,
    this.skinId,
    this.photoUrl,
    this.color,
    this.radius,
  });

  final String name;
  final double size;
  final String? raceId;
  final String? skinId;
  final String? photoUrl;
  final Color? color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Tokens.accent;
    final r = radius ?? size * 0.28;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty) // lint-ignore: widget-no-logic — initials derivation from display-name string
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    final initialsWidget = _Initials(initials: initials, color: c, size: size);
    final skinPath = _resolveSkinPath();

    final inner = skinPath != null
        ? Image.asset(
            skinPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => initialsWidget,
          )
        : (photoUrl != null && photoUrl!.isNotEmpty
            ? Image(
                // Image+CachedNetworkImageProvider renders synchronously when
                // the bitmap is in Flutter's in-memory imageCache (warmed by
                // precacheProfilePhoto on cold start). Falls back to the
                // initials only when the load actually fails.
                image: CachedNetworkImageProvider(photoUrl!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => initialsWidget,
              )
            : initialsWidget);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        color: c.withValues(alpha: 0.18),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }

  String? _resolveSkinPath() {
    if (raceId == null || skinId == null) return null;
    final assetKey = const CosmeticCatalog().byId(skinId!)?.assetKey;
    if (assetKey == null) return null;
    return const SkinAssetResolver().resolve(
      raceId: raceId,
      skinAssetKey: assetKey,
      variant: SkinAssetVariant.thumbnail,
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(
      {required this.initials, required this.color, required this.size});
  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
