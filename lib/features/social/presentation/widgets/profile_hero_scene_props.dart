import 'package:flutter/material.dart';

import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';

/// Soft contact-shadow oval rendered under hero / companion sprites.
/// Painted with a RadialGradient squashed onto a horizontal ellipse via
/// FittedBox so the gradient draws as a circle and is then scaled to
/// the requested width/height.
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
                  colors: [
                    Color(0xF2000000),
                    Color(0x66000000),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.55, 1.0],
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
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      definition.previewAssetKey ?? definition.assetKey,
    );

    return SizedBox(
      width: size,
      height: size,
      child: assetPath == null
          ? const Icon(Icons.pets_rounded, size: 64, color: Colors.white24)
          : Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
