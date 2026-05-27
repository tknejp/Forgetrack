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
    // Hero scene paints the background at the parent's full width
    // (~360 px on phones), so the catalog's small `previewAssetKey`
    // would scale up the 512² thumb and visibly soften the art. Pin
    // to the full assetKey here — preview is reserved for inventory
    // tiles + slot pickers that render at thumb sizes.
    final assetPath = definition == null
        ? null
        : CosmeticsConfig.standard().resolveAssetPath(definition!.assetKey);

    if (assetPath == null) {
      return const ColoredBox(color: Color(0xFF0A0E1C));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Anchor the baked-in standing area onto the ground line
        // (`constraints.maxHeight - groundLineFromBottom`) so the
        // hero/companion sprites can stand on the painted ground at
        // any parent height.
        //
        // Image is scaled UNIFORMLY (no distortion). Its height is
        // the larger of:
        //   * the natural 9:16 fit to the parent's width, and
        //   * the minimum height needed for the standing line to
        //     reach the ground (so the image extends up to / above
        //     the parent's top edge with no transparent gap).
        // The width then overflows horizontally and is centred +
        // clipped by the outer ClipRect, preserving the painted
        // scene's aspect.
        final groundLineY =
            constraints.maxHeight - ProfileHeroLayout.groundLineFromBottom;
        final naturalImageHeight =
            width * ProfileHeroLayout.backgroundAspect;
        final minImageHeight =
            groundLineY / ProfileHeroLayout.backgroundStandingFraction;
        final imageHeight = naturalImageHeight > minImageHeight
            ? naturalImageHeight
            : minImageHeight;
        final imageWidth = imageHeight / ProfileHeroLayout.backgroundAspect;
        final standingY =
            imageHeight * ProfileHeroLayout.backgroundStandingFraction;
        final top = groundLineY - standingY;
        final left = (width - imageWidth) / 2;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: top,
                width: imageWidth,
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
            stops: [0.0, 0.0, 0.78, 1.0],
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
