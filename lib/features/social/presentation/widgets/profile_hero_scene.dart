import 'package:flutter/material.dart';

import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import 'profile_hero_layout.dart';

/// Soft alpha fade applied to hero/companion sprites so their crisp
/// pixel edges feather into the painted background instead of looking
/// like cut-out stickers.
class ProfileHeroSceneBlendFade extends StatelessWidget {
  const ProfileHeroSceneBlendFade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.12, 0.78, 1.0],
        colors: [
          Color(0xCCFFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0x33FFFFFF),
        ],
      ).createShader(bounds),
      child: child,
    );
  }
}

class ProfileHeroBackground extends StatelessWidget {
  const ProfileHeroBackground({super.key, required this.definition});

  final Cosmetic? definition;

  @override
  Widget build(BuildContext context) {
    final assetPath = definition == null
        ? null
        : CosmeticsConfig.standard().resolveAssetPath(
            definition!.previewAssetKey ?? definition!.assetKey,
          );

    if (assetPath == null) {
      return const ColoredBox(color: Color(0xFF0A0E1C));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Scale 9:16 source to fill header width; vertical anchor the
        // baked-in standing area onto the card's ground line.
        final imageHeight = width * ProfileHeroLayout.backgroundAspect;
        final standingY =
            imageHeight * ProfileHeroLayout.backgroundStandingFraction;
        final top = ProfileHeroLayout.groundLineY - standingY;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: top,
                width: width,
                height: imageHeight,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Top + bottom feather rendered on top of the painted scene. Pinned
/// to the header frame so the fade always lands at the visible seam,
/// even when the background's image slides vertically to anchor its
/// standing area to the card's ground line.
class ProfileHeroBackgroundEdgeFade extends StatelessWidget {
  const ProfileHeroBackgroundEdgeFade({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Bottom fade lifted from 0.92 to 0.78 on 2026-05-26 so
            // the dark gradient covers the whole "shelf" band below
            // the companion's feet — the buff chip + emblem row
            // read against a clean dark backdrop instead of the
            // painted scene's lower foreground. ≈22 % of the card
            // height (~117 px on 530) versus the previous ~8 %.
            stops: [0.0, 0.08, 0.78, 1.0],
            colors: [
              Color(0xFF0A0E1C),
              Color(0x000A0E1C),
              Color(0x000A0E1C),
              Color(0xFF0A0E1C),
            ],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
