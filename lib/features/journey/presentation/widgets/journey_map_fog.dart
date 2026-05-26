import 'package:flutter/material.dart';

import 'journey_map_layout.dart';

/// Scrollable fog overlay that lives inside the journey map canvas (NOT
/// viewport-bound) and reveals the route as the player progresses.
///
/// Composition: the dense fog mass above [revealY] is built from several
/// rotated / flipped / horizontally-shifted copies of a single cloud asset,
/// so the result reads as a layered cloud bank rather than a tiled wallpaper.
/// A vertical [ShaderMask] then drives the visibility transition:
///
///   * deep future (top) — fully opaque,
///   * a fade band right above the player — opaque → thin,
///   * the receding wisp around the player line — thin,
///   * everything further below — clear.
///
/// As [revealY] moves with the player's level the gradient stops shift; the
/// tile layout itself is stable so frames don't re-flow each rebuild.
class JourneyMapFog extends StatelessWidget {
  const JourneyMapFog({
    super.key,
    required this.width,
    required this.height,
    required this.revealY,
  });

  final double width;
  final double height;

  /// Canvas-y of the current player position. Fog above this is dense; just
  /// below is the receding wisp; further below the canvas is clear.
  final double revealY;

  /// Height of the dense→thin transition band right above [revealY].
  /// Kept short on purpose — a long transition band makes ~10 future levels
  /// readable through the fog. ~3 levels of softening is plenty.
  static const double _fadeBand = 90.0;

  /// How far below [revealY] the receding wisp tails off.
  static const double _tailLength = 65.0;

  static const double _tileAspect = 1024.0 / 1536.0;

  /// Tile width as a multiple of the canvas width — overscans so the cloud
  /// body covers the full canvas width and the soft asset edges sit outside
  /// the clipped canvas region.
  static const double _tileWidthMultiplier = 1.55;

  /// Vertical step between successive tiles, as a multiple of tile height.
  /// Smaller = more overlap = denser fog.
  static const double _verticalStepFactor = 0.55;

  /// Hand-tuned variations so successive copies of the same asset don't
  /// read as identical. Cycled by index — deterministic, no per-build RNG.
  static const List<_FogTileVariant> _variants = [
    _FogTileVariant(alpha: 0.95, hShift: -0.08, rotation: -0.04, flipX: false),
    _FogTileVariant(alpha: 0.88, hShift: 0.05, rotation: 0.05, flipX: true),
    _FogTileVariant(alpha: 0.92, hShift: -0.12, rotation: -0.03, flipX: false),
    _FogTileVariant(alpha: 0.84, hShift: 0.09, rotation: 0.06, flipX: true),
    _FogTileVariant(alpha: 0.90, hShift: -0.04, rotation: -0.02, flipX: true),
    _FogTileVariant(alpha: 0.86, hShift: 0.11, rotation: 0.04, flipX: false),
    _FogTileVariant(alpha: 0.82, hShift: -0.07, rotation: -0.05, flipX: true),
    _FogTileVariant(alpha: 0.78, hShift: 0.06, rotation: 0.03, flipX: false),
  ];

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    final fogBottom = (revealY + _tailLength).clamp(0.0, height);
    if (fogBottom <= 0) return const SizedBox.shrink();

    final tileWidth = width * _tileWidthMultiplier;
    final tileHeight = tileWidth / _tileAspect;
    final step = tileHeight * _verticalStepFactor;
    final baseDx = (width - tileWidth) / 2;

    final tiles = <Widget>[];
    var y = -tileHeight * 0.15;
    var i = 0;
    while (y < fogBottom && i < 64) {
      final v = _variants[i % _variants.length];
      tiles.add(
        Positioned(
          left: baseDx + width * v.hShift,
          top: y,
          width: tileWidth,
          height: tileHeight,
          child: Transform.rotate(
            angle: v.rotation,
            child: Transform.flip(
              flipX: v.flipX,
              child: Opacity(
                opacity: v.alpha,
                child: Image.asset(
                  JourneyMapAssets.fog,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      );
      y += step;
      i++;
    }

    // Gradient stops that drive the dense → receding → clear transition.
    // Clamped to [0,1] and forced monotonic so degenerate cases at the very
    // top / bottom of the route (revealY near 0 or near canvasH) don't crash
    // the shader on stop ordering.
    final fadeStart = ((revealY - _fadeBand) / height).clamp(0.0, 1.0);
    final midStop =
        ((revealY - _fadeBand * 0.5) / height).clamp(fadeStart, 1.0);
    final revealStop = (revealY / height).clamp(midStop, 1.0);
    final tailStop = ((revealY + _tailLength) / height).clamp(revealStop, 1.0);

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFFFFFFFF), // 1.00 — deep future, fully dense
                Color(0xFFFFFFFF), // 1.00 — body of the fog mass stays solid
                Color(0xEBFFFFFF), // 0.92 — minimally thinning entering band
                Color(0x66FFFFFF), // 0.40 — last cloud near player, see-through
                Color(0x00FFFFFF), // clear
              ],
              stops: [0.0, fadeStart, midStop, revealStop, tailStop],
            ).createShader(rect),
            child: Stack(clipBehavior: Clip.none, children: tiles),
          ),
        ),
      ),
    );
  }
}

class _FogTileVariant {
  const _FogTileVariant({
    required this.alpha,
    required this.hShift,
    required this.rotation,
    required this.flipX,
  });

  final double alpha;

  /// Horizontal offset as a fraction of canvas width (not tile width).
  final double hShift;
  final double rotation;
  final bool flipX;
}
