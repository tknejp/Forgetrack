import 'package:flutter/material.dart';

import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_palette.dart';

/// Wraps an avatar [child] with a cosmetic frame.
///
/// The widget's external bounds are exactly [size] × [size], so callers can
/// stack it with siblings (e.g. an edit-photo button) using the same
/// coordinates as a bare avatar. The frame artwork — and its placeholder
/// fallback — render through a child that is positioned with a negative
/// inset, so the frame visibly extends *around* the avatar instead of
/// being inscribed inside it.
///
/// Important: the parent must use `clipBehavior: Clip.none` (Stack does
/// this by default with `clipBehavior: Clip.none`) for the overscan to
/// be visible. Without it the extra frame area is clipped away and the
/// widget looks identical to `frameOverscan: 1.0`.
class CosmeticFramePreview extends StatelessWidget {
  const CosmeticFramePreview({
    super.key,
    required this.child,
    this.definition,
    this.config,
    this.size = 96,
    this.borderRadius,
    this.frameOverscan = 1.0,
  });

  final Widget child;
  final CosmeticDefinition? definition;
  final CosmeticsConfig? config;

  /// Size of the avatar (and the widget's external bounds).
  final double size;

  /// Border radius the placeholder ring should follow when no asset is
  /// available. Pass null for a circular ring.
  final BorderRadius? borderRadius;

  /// Multiplier applied to the frame canvas. `1.0` (default) draws the
  /// frame inside the avatar's bounds. `> 1.0` lets the frame visibly
  /// extend beyond the avatar — typical good-looking values are 1.15–1.30.
  final double frameOverscan;

  @override
  Widget build(BuildContext context) {
    final def = definition;
    if (def == null) {
      return SizedBox(width: size, height: size, child: child);
    }

    final assetPath = (config ?? CosmeticsConfig.standard())
        .resolveAssetPath(def.previewAssetKey ?? def.assetKey);
    final outer = size * frameOverscan;
    final inset = (outer - size) / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: -inset,
            top: -inset,
            width: outer,
            height: outer,
            child: IgnorePointer(
              child: assetPath != null
                  ? Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _PlaceholderRing(
                        rarity: def.rarity,
                        borderRadius: borderRadius,
                      ),
                    )
                  : _PlaceholderRing(
                      rarity: def.rarity,
                      borderRadius: borderRadius,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderRing extends StatelessWidget {
  const _PlaceholderRing({
    required this.rarity,
    required this.borderRadius,
  });

  final CosmeticRarity rarity;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = CosmeticsPalette.forRarity(rarity);
    final shape = borderRadius == null ? BoxShape.circle : BoxShape.rectangle;
    return Container(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        border: Border.all(color: palette.color, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.gradStart.withValues(alpha: 0.18),
            palette.color.withValues(alpha: 0.32),
          ],
        ),
      ),
    );
  }
}
