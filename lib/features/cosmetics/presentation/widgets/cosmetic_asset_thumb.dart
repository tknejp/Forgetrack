import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_catalog.dart';
import '../../domain/cosmetic_models.dart';
import 'cosmetic_preview_path.dart';

/// Square thumbnail that renders a cosmetic's preview asset (`previewAssetKey`
/// or the main `assetKey`) given the cosmetic id. Falls back to a typed icon
/// glyph when:
///
/// - The id is not in [CosmeticCatalog].
/// - The catalog entry has no asset key.
/// - The asset itself fails to decode at runtime (missing PNG, etc.).
///
/// Used by reward rows on the V2 quest detail sheet so locked rewards show
/// their real artwork instead of a generic palette glyph. Premium / disabled
/// gates are not enforced here — this is a display-only widget.
class CosmeticAssetThumb extends StatelessWidget {
  CosmeticAssetThumb({
    super.key,
    required this.cosmeticId,
    this.size = 36,
    this.borderRadius = 8,
    this.dimmed = false,
    this.fallbackIcon,
    this.fallbackColor,
    this.raceId,
    CosmeticsConfig? config,
  }) : config = config ?? CosmeticsConfig.standard();

  /// Cosmetic id to resolve (e.g. `relic_ravine_stone`, `frame_worldwalker`).
  final String cosmeticId;

  /// Edge length of the rendered square.
  final double size;

  final double borderRadius;

  /// Greys out the thumb — used when the cosmetic is still locked.
  final bool dimmed;

  /// Icon shown when the cosmetic cannot be resolved or its asset fails to
  /// decode. Defaults to a type-appropriate glyph from [_iconForType].
  final IconData? fallbackIcon;

  /// Accent for the fallback glyph + background tint. Falls back to the
  /// design system accent.
  final Color? fallbackColor;

  /// Player's selected race id. Skin thumbs need it to land on the
  /// race-specific artwork; ignored for non-skin types. Null is safe —
  /// the thumb falls back to the type icon placeholder.
  final String? raceId;

  /// Wired so tests can pass a custom config without dragging providers
  /// through. Production usage gets the default const config.
  final CosmeticsConfig config;

  @override
  Widget build(BuildContext context) {
    final definition = const CosmeticCatalog().byId(cosmeticId);
    final accent = fallbackColor ?? Tokens.accent;
    final assetPath = definition == null
        ? null
        : resolveCosmeticPreviewPath(
            definition,
            config: config,
            raceId: raceId,
          );

    Widget fallback() {
      return _Placeholder(
        icon: fallbackIcon ?? _iconForType(definition?.type),
        accent: accent,
        size: size,
        borderRadius: borderRadius,
      );
    }

    final child = assetPath == null
        ? fallback()
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            ),
          );

    if (!dimmed) return child;
    return Opacity(opacity: 0.55, child: child);
  }

  static IconData _iconForType(CosmeticType? type) {
    return switch (type) {
      CosmeticType.frame => Icons.crop_square_rounded,
      CosmeticType.relic => Icons.diamond_rounded,
      CosmeticType.background => Icons.landscape_rounded,
      CosmeticType.emblem => Icons.military_tech_rounded,
      CosmeticType.companion => Icons.groups_2_rounded,
      CosmeticType.titleFlair => Icons.workspace_premium_rounded,
      CosmeticType.mapEffect => Icons.map_rounded,
      CosmeticType.skin => Icons.person_rounded,
      null => Icons.card_giftcard_rounded,
    };
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.accent,
    required this.size,
    required this.borderRadius,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: size * 0.55, color: accent.withValues(alpha: 0.92)),
    );
  }
}
