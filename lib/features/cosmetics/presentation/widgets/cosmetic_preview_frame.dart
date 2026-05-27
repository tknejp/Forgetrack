import 'package:flutter/material.dart';

/// Soft rounded frame for cosmetic preview thumbs.
///
/// Wraps any preview image with rounded corners + a rarity-tinted
/// outline so the asset reads as "set in" its surrounding card / chip
/// / tile. The image itself is clipped to the rounded shape so its
/// corners follow the outline — no sharp-cornered bitmap floating
/// inside a rounded box.
///
/// Used by the inventory grid card, the equipped chip, the
/// featured-inventory tile, and the slot-picker thumb — same look
/// across every surface that shows a compact cosmetic preview.
class CosmeticPreviewFrame extends StatelessWidget {
  const CosmeticPreviewFrame({
    super.key,
    required this.child,
    required this.borderColor,
    this.size,
    this.radius = 8,
    this.borderWidth = 1.5,
    this.borderAlpha = 0.65,
  });

  /// Image / fallback widget to render inside the frame. Will be
  /// clipped to the rounded shape — there's no inner padding, the
  /// outline sits directly on the image edge for a "framed picture"
  /// read instead of "image floating inside a rounded box".
  final Widget child;

  /// Outline colour. Callers pass the cosmetic's rarity colour
  /// (`cosmeticRarityColor(definition.rarity)`) so each tile carries
  /// its rarity signal on the frame in addition to any rarity-tinted
  /// container behind it.
  final Color borderColor;

  /// Optional fixed edge length. When null the frame sizes to its
  /// child's intrinsic dimensions (use this when the parent layout
  /// constrains size already).
  final double? size;

  /// Corner radius of the rounded clip + border.
  final double radius;

  /// Stroke width of the outline. Bumped above the Material 1-pixel
  /// default so the rarity tint reads clearly even on busy artwork
  /// (companion silhouettes, painted backgrounds).
  final double borderWidth;

  /// Alpha applied to [borderColor]. Slightly under 1.0 keeps the
  /// outline from fighting with the rarity-tinted container behind
  /// the tile while still saturating well over the underlying art.
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    final framed = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor.withValues(alpha: borderAlpha),
          width: borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    if (size == null) return framed;
    return SizedBox(width: size, height: size, child: framed);
  }
}
