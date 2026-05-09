import 'package:flutter/material.dart';

import '../../../cosmetics/domain/cosmetic_catalog.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_frame_preview.dart';
import '../../domain/social_models.dart';
import 'social_avatar.dart';

const _catalog = CosmeticCatalog();
const _defaultFrameId = 'frame_pilgrim';
const _defaultBackgroundId = 'background_forest_trail';

class SocialCosmeticAvatar extends StatelessWidget {
  const SocialCosmeticAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
    this.profile,
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
  final String? frameId;
  final Color? color;
  final double? radius;
  final double frameOverscan;
  final EdgeInsetsGeometry? frameMargin;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.28;
    final frame = socialFrameDefinition(
      frameId ?? profile?.equippedCosmetics.frameId,
    );

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
          photoUrl: photoUrl,
          color: color,
          radius: r,
        ),
      ),
    );
  }
}

CosmeticDefinition? socialFrameDefinition(String? id) {
  return _cosmeticById(id ?? _defaultFrameId, CosmeticType.frame);
}

CosmeticDefinition? socialBackgroundDefinition(String? id) {
  return _cosmeticById(id ?? _defaultBackgroundId, CosmeticType.background);
}

CosmeticDefinition? socialCosmeticById(String? id) {
  if (id == null || id.isEmpty) return null;
  final definition = _catalog.byId(id);
  if (definition == null || !definition.isEnabled) return null;
  return definition;
}

List<CosmeticDefinition> socialProfileExtraCosmetics(
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
      .whereType<CosmeticDefinition>()
      .toList(growable: false);
}

CosmeticDefinition? _cosmeticById(String id, CosmeticType type) {
  final definition = _catalog.byId(id);
  if (definition == null || !definition.isEnabled || definition.type != type) {
    return null;
  }
  return definition;
}
