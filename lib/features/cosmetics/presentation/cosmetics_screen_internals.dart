import 'package:flutter/material.dart';

import '../../../shared/theme/design_tokens.dart';
import '../domain/cosmetic_models.dart';

// ── Shared badge widget ───────────────────────────────────────────────────────

class CosmeticBadge extends StatelessWidget {
  const CosmeticBadge({
    super.key,
    required this.definition,
    required this.assetPath,
    required this.color,
    this.size = 42,
    this.framed = true,
    this.glow = false,
    this.fit,
    this.contentScale = 1.0,
  });

  final Cosmetic definition;
  final String? assetPath;
  final Color color;
  final double size;

  /// Draws the old badge container/border.
  ///
  /// Keep true for grid/list cards.
  /// Use false in detail sheet when the raw asset should be shown.
  final bool framed;

  /// Draws a soft rarity-colored glow behind the asset.
  ///
  /// Intended mainly for detail sheet previews.
  final bool glow;

  /// Optional override for image fit.
  ///
  /// Detail sheet should usually use BoxFit.contain.
  final BoxFit? fit;

  /// Scale factor for the content within the badge.
  final double contentScale;

  @override
  Widget build(BuildContext context) {
    final isFrame = definition.type == CosmeticType.frame;
    final effectiveFit = fit ?? (isFrame ? BoxFit.contain : BoxFit.cover);

    final content = assetPath == null
        ? CosmeticBadgeFallback(
            type: definition.type,
            color: color,
            size: size,
            framed: framed,
          )
        : Image.asset(
            assetPath!,
            fit: effectiveFit,
            errorBuilder: (_, __, ___) => CosmeticBadgeFallback(
              type: definition.type,
              color: color,
              size: size,
              framed: framed,
            ),
          );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow)
            IgnorePointer(
              child: Container(
                width: size * 0.68,
                height: size * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.32),
                      blurRadius: size * 0.30,
                      spreadRadius: size * 0.045,
                    ),
                  ],
                ),
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: framed
                ? BoxDecoration(
                    color: color.withValues(alpha: isFrame ? 0.10 : 0.18),
                    borderRadius: BorderRadius.circular(size * 0.28),
                    border: Border.all(
                      color: color.withValues(alpha: isFrame ? 0.52 : 0.32),
                      width: isFrame ? 1.8 : 1,
                    ),
                  )
                : null,
            clipBehavior: framed && !isFrame ? Clip.antiAlias : Clip.none,
            child: Transform.scale(
              scale: contentScale,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class CosmeticBadgeFallback extends StatelessWidget {
  const CosmeticBadgeFallback({
    super.key,
    required this.type,
    required this.color,
    required this.size,
    this.framed = true,
  });

  final CosmeticType type;
  final Color color;
  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      cosmeticIconForType(type),
      color: framed
          ? Colors.white.withValues(alpha: 0.9)
          : color.withValues(alpha: 0.9),
      size: size * 0.52,
    );

    if (!framed) {
      return Center(child: icon);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(child: icon),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

IconData cosmeticIconForType(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return Icons.crop_square_rounded;
    case CosmeticType.relic:
      return Icons.auto_awesome_rounded;
    case CosmeticType.background:
      return Icons.landscape_rounded;
    case CosmeticType.emblem:
      return Icons.shield_rounded;
    case CosmeticType.companion:
      return Icons.pets_rounded;
    case CosmeticType.titleFlair:
      return Icons.title_rounded;
    case CosmeticType.mapEffect:
      return Icons.map_rounded;
  }
}

String cosmeticTypeLabel(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return 'Rámeček';
    case CosmeticType.relic:
      return 'Relikvie';
    case CosmeticType.background:
      return 'Pozadí';
    case CosmeticType.emblem:
      return 'Znak';
    case CosmeticType.companion:
      return 'Společník';
    case CosmeticType.titleFlair:
      return 'Titul';
    case CosmeticType.mapEffect:
      return 'Efekt mapy';
  }
}

Color cosmeticRarityColor(Rarity rarity) =>
    RarityPalette.forRarity(rarity).color;