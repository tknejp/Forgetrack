import 'package:flutter/material.dart';

import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';

/// Cast-shadow oval rendered under hero / companion sprites — reads as
/// the figure's own shadow on the ground, not a soft glow halo.
/// Painted with a RadialGradient squashed onto a horizontal ellipse via
/// FittedBox so the gradient draws as a circle and is then scaled to
/// the requested width/height.
///
/// The gradient holds a solid black core across most of the radius and
/// drops to transparent only in the last fifth, so the silhouette
/// edge stays defined instead of fading away into nothing.
class ProfileHeroFootShadow extends StatelessWidget {
  const ProfileHeroFootShadow({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: width,
            height: width,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  // Core stays near-opaque ~half the radius so the
                  // shadow reads as a defined oval, then eases off
                  // across the outer third — softer than a hard wall
                  // but tighter than the original slow halo.
                  colors: [
                    Color(0xF2000000),
                    Color(0xCC000000),
                    Color(0x40000000),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.45, 0.78, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Warm radial puddle of light under the companion's feet.
class ProfileHeroGroundGlow extends StatelessWidget {
  const ProfileHeroGroundGlow({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: 14,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.6,
              colors: [
                const Color(0xFFF4C152).withValues(alpha: 0.45),
                const Color(0xFFF4C152).withValues(alpha: 0),
              ],
              stops: const [0.0, 0.7],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class ProfileHeroCompanionStandee extends StatelessWidget {
  const ProfileHeroCompanionStandee({
    super.key,
    required this.definition,
    required this.size,
  });

  final Cosmetic definition;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Hero standee renders at scene size — the 512² preview would
    // scale up visibly. Pin to the full painted asset; the catalog's
    // `previewAssetKey` is reserved for compact tiles + chips.
    final assetPath =
        CosmeticsConfig.standard().resolveAssetPath(definition.assetKey);

    return SizedBox(
      width: size,
      height: size,
      child: assetPath == null
          ? const Icon(Icons.pets_rounded, size: 64, color: Colors.white24)
          : Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
