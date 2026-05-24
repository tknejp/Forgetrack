import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import 'journey_map_layout.dart';

class JourneyMapLoadingShell extends StatelessWidget {
  const JourneyMapLoadingShell({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JourneyMapShellStyle.gradientStart,
            JourneyMapShellStyle.gradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(JourneyMapLayout.mapRadius),
        border: Border.all(
          color:
              Colors.white.withValues(alpha: JourneyMapShellStyle.borderAlpha),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Tokens.accent,
          ),
        ),
      ),
    );
  }
}

class JourneyMapTooltipPosition extends StatelessWidget {
  const JourneyMapTooltipPosition({
    super.key,
    required this.anchor,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.child,
  });

  final Offset anchor;
  final double canvasWidth;
  final double canvasHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final placeRight =
        anchor.dx < canvasWidth * JourneyMapTooltipStyle.flipAtCanvasFraction;

    double left = placeRight
        ? anchor.dx +
            JourneyMapTooltipStyle.nodeRadius +
            JourneyMapTooltipStyle.gap
        : anchor.dx -
            JourneyMapTooltipStyle.nodeRadius -
            JourneyMapTooltipStyle.gap -
            JourneyMapTooltipStyle.maxWidth;
    left = left.clamp(
      JourneyMapTooltipStyle.edgePadding,
      canvasWidth -
          JourneyMapTooltipStyle.maxWidth -
          JourneyMapTooltipStyle.edgePadding,
    );

    double top = anchor.dy - JourneyMapTooltipStyle.approxHeight / 2;
    top = top.clamp(
      JourneyMapTooltipStyle.edgePadding,
      canvasHeight -
          JourneyMapTooltipStyle.approxHeight -
          JourneyMapTooltipStyle.edgePadding,
    );

    return Positioned(
      left: left,
      top: top,
      width: JourneyMapTooltipStyle.maxWidth,
      child: child,
    );
  }
}

// ─── Map background — gradient + radial glows + optional asset ─────────────

class JourneyMapBackground extends StatelessWidget {
  const JourneyMapBackground({
    super.key,
    required this.width,
    required this.height,
    this.collapsed = false,
  });

  final double width;
  final double height;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            collapsed
                ? JourneyMapAssets.collapsedBackground
                : JourneyMapAssets.background,
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Image.asset(
              JourneyMapAssets.fallbackBackground,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: JourneyMapBackgroundStyle.topGlowOffset.dy,
            left: JourneyMapBackgroundStyle.topGlowOffset.dx,
            child: _Glow(
              size: JourneyMapBackgroundStyle.topGlowSize,
              color: Tokens.accent,
              alpha: JourneyMapBackgroundStyle.topGlowAlpha,
            ),
          ),
          Positioned(
            top: height * JourneyMapBackgroundStyle.middleGlowTopFactor,
            right: JourneyMapBackgroundStyle.middleGlowRight,
            child: _Glow(
              size: JourneyMapBackgroundStyle.middleGlowSize,
              color: Tokens.active.color,
              alpha: JourneyMapBackgroundStyle.middleGlowAlpha,
            ),
          ),
          Positioned(
            bottom: JourneyMapBackgroundStyle.bottomGlowBottom,
            left: JourneyMapBackgroundStyle.bottomGlowLeft,
            child: _Glow(
              size: JourneyMapBackgroundStyle.bottomGlowSize,
              color: Tokens.accent,
              alpha: JourneyMapBackgroundStyle.bottomGlowAlpha,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(
                    alpha: JourneyMapBackgroundStyle.overlayTopAlpha,
                  ),
                  Colors.black.withValues(
                    alpha: JourneyMapBackgroundStyle.overlayBottomAlpha,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.alpha});
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
