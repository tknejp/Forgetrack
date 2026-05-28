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

  /// Shifts the entire fog mass upward by this many canvas-px from the
  /// supplied [revealY]. Without it the wisp covers the player line and
  /// everything above; with too much, the future feels too readable for
  /// a "fog of war" effect. ~130 px sits in the middle — clear zone of
  /// ~65 px directly above the player (≈ 1 future route point at the
  /// start-of-trail ~60 px spacing), then 1–2 more points fading through
  /// the wisp + pre-wisp band before the dense fog body takes over.
  static const double _revealLift = 130.0;

  /// Extra softening band that sits immediately above the reveal line,
  /// between the body of the fog mass and the wisp. Introduces an extra
  /// gradient stop so the bottommost ~25 px of the cloud thin out
  /// noticeably before the wisp band takes over — gives the "last cloud"
  /// a gradient-of-transparency look instead of a hard handoff from
  /// 0.92 → 0.40 alpha.
  static const double _preWispBand = 25.0;

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

    // Lifted reveal line — everything below uses this instead of [revealY]
    // so the fog mass, fade band, and wisp all shift up together. Keeps the
    // current player marker + the next slice of path visible underneath.
    final liftedReveal = revealY - _revealLift;

    final fogBottom = (liftedReveal + _tailLength).clamp(0.0, height);
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
    final fadeStart =
        ((liftedReveal - _fadeBand) / height).clamp(0.0, 1.0);
    final midStop =
        ((liftedReveal - _fadeBand * 0.5) / height).clamp(fadeStart, 1.0);
    final revealStop = (liftedReveal / height).clamp(midStop, 1.0);
    final preWispStop =
        ((liftedReveal - _preWispBand) / height).clamp(midStop, revealStop);
    final tailStop =
        ((liftedReveal + _tailLength) / height).clamp(revealStop, 1.0);

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
                Color(0x99FFFFFF), // 0.60 — pre-wisp softening (~25 px above player)
                Color(0x4DFFFFFF), // 0.30 — last cloud near player, see-through
                Color(0x00FFFFFF), // clear
              ],
              stops: [
                0.0,
                fadeStart,
                midStop,
                preWispStop,
                revealStop,
                tailStop,
              ],
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

/// Decorative fog band for the mini map on the hero screen.
///
/// The mini map is a short horizontal strip (~90 px tall) showing 5 visible
/// path slots at a time. Two things drive how the fog appears:
///
///  * [revealX] — the player's viewport-x. Until the player reaches the
///    4th visible slot (where the strip starts scrolling to keep them in
///    frame), the dense band's left edge slides right; by slot 4 the dense
///    band sits only over the 5th (last) visible slot.
///  * [progress] — overall journey progress (0..1). The whole fog fades
///    with progress, so the later the player is in their journey, the less
///    fog there is.
///
/// The asset itself is placed once at full strip width — no horizontal or
/// vertical translation. Only the ShaderMask opacity changes; the cloud
/// silhouette stays anchored at the same vertical level throughout the
/// journey.
class JourneyMiniMapFog extends StatelessWidget {
  const JourneyMiniMapFog({
    super.key,
    required this.width,
    required this.height,
    required this.revealX,
    required this.progress,
  });

  final double width;
  final double height;

  /// Viewport-x of the current player position. Drives the dense-band
  /// horizontal anchor — the band collapses rightward as the player moves
  /// through the 5 visible slots.
  final double revealX;

  /// Overall journey progress (0..1). Drives the asset's downward slide
  /// and the overall fog opacity fade — late game shows only a thin wisp.
  final double progress;

  /// Player-viewport ratio at slot 3 (the 4th of 5 visible slots, where
  /// the strip starts scrolling). Roughly sidePadding + 3*pointSpacing,
  /// which works out to ~0.80 of strip width with the preview layout.
  static const double _slot3Ratio = 0.80;

  /// Dense-band start anchor when the player is at slot 0 vs slot 3.
  static const double _denseStartAtSlot0 = 0.55;
  static const double _denseStartAtSlot3 = 0.85;

  /// Width of the fade band that ramps from clear → dense, just before
  /// [denseStart]. Normalized to strip width.
  static const double _fadeSpan = 0.14;

  /// Max overall fade applied at progress=1. Keeps a wisp at progress=1
  /// rather than going fully transparent — avoids a hard "fog vanished"
  /// cliff when the player hits max level.
  static const double _maxFade = 0.80;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final viewportRatio =
        ((revealX / width) / _slot3Ratio).clamp(0.0, 1.0).toDouble();

    // Horizontal dense-band anchor — slides right with viewport ratio.
    final denseStart = _denseStartAtSlot0 +
        (_denseStartAtSlot3 - _denseStartAtSlot0) * viewportRatio;
    final fadeStart = (denseStart - _fadeSpan).clamp(0.0, denseStart);
    final clearEnd =
        (denseStart - _fadeSpan * 1.5).clamp(0.0, fadeStart);

    // Overall fog presence — multiplies the mask alpha so late-game shows
    // only a thin remnant.
    final fade = (1.0 - clampedProgress * _maxFade).clamp(0.0, 1.0);
    final denseAlpha = 0.95 * fade;
    final midAlpha = 0.55 * fade;

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0x00FFFFFF), // clear — past / walked
                const Color(0x00FFFFFF), // clear through player line
                Colors.white.withValues(alpha: midAlpha),
                Colors.white.withValues(alpha: denseAlpha),
                Colors.white.withValues(alpha: denseAlpha),
              ],
              stops: [0.0, clearEnd, fadeStart, denseStart, 1.0],
            ).createShader(rect),
            child: Image.asset(
              JourneyMapAssets.previewFog,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}
