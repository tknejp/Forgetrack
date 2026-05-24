import 'package:flutter/material.dart';

import '../../../cosmetics/domain/cosmetic_catalog.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_frame_preview.dart';
import '../../domain/social_models.dart';
import 'social_avatar.dart';

const _catalog = CosmeticCatalog();
const _defaultFrameId = 'frame_pilgrim';
const _defaultBackgroundId = 'background_camp';

/// Compact framed avatar: race × skin thumbnail inside the equipped
/// Frame cosmetic border.
///
/// Inputs:
///   * `profile` — friend / leaderboard / actor profile. The widget
///     reads `raceId` + `equippedCosmetics.skinId` + `equippedCosmetics
///     .frameId` from here when explicit overrides are not given. Null
///     profile falls back to initials inside the default frame.
///   * `raceId` / `skinId` — explicit overrides used by own-user
///     callsites (top app bar, settings header, hero progression
///     header) that source identity from `CosmeticsProvider` directly
///     instead of routing through a fetched profile snapshot.
///   * `frameId` — explicit override for the same own-user callsites
///     so the equipped Frame border still surrounds the thumb without
///     going through Firestore. Falls back to `profile?.equippedCosmetics
///     .frameId` then to [_defaultFrameId].
///   * `photoUrl` — transitional fallback for legacy share-actor
///     snapshots only. New compact-surface callsites should leave it
///     null and pass `raceId`/`skinId` instead.
class SocialCosmeticAvatar extends StatelessWidget {
  const SocialCosmeticAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
    this.profile,
    this.raceId,
    this.skinId,
    this.frameId,
    this.color,
    this.radius,
    this.frameOverscan = 1.14,
    this.frameMargin,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final SocialUserProfile? profile;
  final String? raceId;
  final String? skinId;
  final String? frameId;
  final Color? color;
  final double? radius;
  final double frameOverscan;
  final EdgeInsetsGeometry? frameMargin;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.28;
    final effectiveFrameId =
        frameId ?? profile?.equippedCosmetics.frameId;
    final frame = socialFrameDefinition(effectiveFrameId);
    final effectiveRaceId = raceId ?? profile?.raceId;
    final effectiveSkinId =
        skinId ?? profile?.equippedCosmetics.skinId;

    final margin = frameMargin ??
        EdgeInsets.all(((size * (frameOverscan - 1)) / 2 + 2).clamp(3, 8));

    return Padding(
      padding: margin,
      child: CosmeticFramePreview(
        definition: frame,
        size: size,
        borderRadius: BorderRadius.circular(r),
        frameOverscan: frameOverscan,
        child: SocialAvatar(
          name: name,
          size: size,
          raceId: effectiveRaceId,
          skinId: effectiveSkinId,
          photoUrl: photoUrl,
          color: color,
          radius: r,
        ),
      ),
    );
  }
}

Cosmetic? socialFrameDefinition(String? id) {
  return _cosmeticById(id ?? _defaultFrameId, CosmeticType.frame);
}

Cosmetic? socialBackgroundDefinition(String? id) {
  return _cosmeticById(id ?? _defaultBackgroundId, CosmeticType.background);
}

Cosmetic? socialCosmeticById(String? id) {
  if (id == null || id.isEmpty) return null;
  final definition = _catalog.byId(id);
  if (definition == null || !definition.isEnabled) return null;
  return definition;
}

List<Cosmetic> socialProfileExtraCosmetics(
  SocialUserProfile? profile,
) {
  final equipped = profile?.equippedCosmetics;
  if (equipped == null) return const [];

  return <String?>[
    equipped.relicId,
    equipped.emblemId,
    equipped.companionId,
    equipped.titleFlairId,
    equipped.mapEffectId,
  ]
      .map(socialCosmeticById)
      .whereType<Cosmetic>()
      .toList(growable: false);
}

Cosmetic? _cosmeticById(String id, CosmeticType type) {
  final definition = _catalog.byId(id);
  if (definition == null || !definition.isEnabled || definition.type != type) {
    return null;
  }
  return definition;
}
