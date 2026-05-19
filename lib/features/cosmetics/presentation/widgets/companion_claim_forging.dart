import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_models.dart';
import 'cosmetic_asset_thumb.dart';

/// Fullscreen Orbita-variant forging overlay (5.4 s).
///
/// Drives the hi-fi claim ritual end-to-end:
///   * fly-in / orbit + spiral / pull-to-center for the gating relics,
///   * burst + aura bloom + sprite materialize for the companion,
///   * converging wisps + settle wobble.
///
/// Timeline is verbatim from `design_handoff_companion_claim/claim.jsx`
/// (OrbitVariant). The single source of truth for sub-phase boundaries
/// is [_kRitualSteps] below — every visual derives its progress from
/// fractional intervals against those millisecond marks.
///
/// Lifecycle:
///   * [onReveal] fires once at t ≈ [_kRevealMs] (sprite materialize
///     complete). The host wires this to `progression.claimNode(...)`
///     so the engine write is sequenced AFTER the visible reveal,
///     not concurrent with it (D.1 decision #3).
///   * [onComplete] fires once at t ≥ [_kDurationMs]. The host
///     uses this to remove the [OverlayEntry] hosting this widget.
///   * Tapping anywhere on the overlay short-circuits the timeline:
///     the controller snaps to settle and the same reveal/complete
///     callbacks fire on the next frame (D.1 decision #1).
class CompanionClaimForging extends StatefulWidget {
  const CompanionClaimForging({
    super.key,
    required this.companion,
    required this.assetPath,
    required this.relicIds,
    required this.color,
    required this.onReveal,
    required this.onComplete,
  });

  /// Companion catalog row — drives the reveal text + sprite asset.
  final Cosmetic companion;

  /// Resolved sprite path (already mapped through
  /// `CosmeticsProvider.service.config.resolveAssetPath`).
  final String? assetPath;

  /// Relic ids that gate the companion. The Orbita variant is
  /// authored for exactly two; extra ids are ignored, fewer fall
  /// back gracefully (the missing slots simply do not render).
  final List<String> relicIds;

  /// Accent color (typically companion rarity color).
  final Color color;

  /// Engine-write hook — fires once at t ≈ [_kRevealMs].
  final Future<void> Function() onReveal;

  /// Host-side teardown — fires once at t ≥ [_kDurationMs] (or
  /// immediately after a tap-to-skip).
  final VoidCallback onComplete;

  @override
  State<CompanionClaimForging> createState() => _CompanionClaimForgingState();
}

const int _kDurationMs = 5400;

const int _kFlyInEndMs = 600;
const int _kOrbitEndMs = 2400;
const int _kPullEndMs = 2700;
const int _kBurstStartMs = 2700;
const int _kAuraStartMs = 2700;
const int _kAuraEndMs = 3300;
const int _kSpriteStartMs = 2800;
const int _kSpriteEndMs = 4800;
const int _kWispStartMs = 2800;
const int _kWispEndMs = 4750;
const int _kSettleStartMs = 4800;

/// Status-text crossfade boundaries (ms) — matches design spec §"Stav 2".
const int _kStatusBindingEndMs = 2400;
const int _kStatusHideEndMs = 2900;
const int _kStatusAwakeningEndMs = 4700;
const int _kRevealMs = 4700;

class _CompanionClaimForgingState extends State<CompanionClaimForging>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kDurationMs),
  );

  bool _burstHapticFired = false;
  bool _revealFired = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTick);
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  int get _tMs => (_ctrl.value * _kDurationMs).round();

  void _onTick() {
    final t = _tMs;
    if (!_burstHapticFired && t >= _kBurstStartMs) {
      _burstHapticFired = true;
      HapticFeedback.mediumImpact();
    }
    if (!_revealFired && t >= _kRevealMs) {
      _revealFired = true;
      HapticFeedback.mediumImpact();
      // Fire engine write at the visual reveal point; the host
      // re-renders away from us once the cosmetic lands in
      // inventory but our OverlayEntry persists until [_onStatus]
      // calls [onComplete].
      widget.onReveal();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      // Defer one frame so any in-flight reveal/haptic finishes
      // before the host tears down the overlay.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete();
      });
    }
  }

  void _skip() {
    // Decision #1: tap-anywhere skip (including production).
    // Snap to the settle end; the listeners fire reveal +
    // complete on the next ticks.
    if (_completed) return;
    _ctrl.value = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final cx = screen.width / 2;
    final cy = screen.height * 0.45;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _tMs;
            return _ForgingScene(
              t: t,
              cx: cx,
              cy: cy,
              screen: screen,
              companion: widget.companion,
              assetPath: widget.assetPath,
              relicIds: widget.relicIds,
              color: widget.color,
              l10n: l10n,
            );
          },
        ),
      ),
    );
  }
}

class _ForgingScene extends StatelessWidget {
  const _ForgingScene({
    required this.t,
    required this.cx,
    required this.cy,
    required this.screen,
    required this.companion,
    required this.assetPath,
    required this.relicIds,
    required this.color,
    required this.l10n,
  });

  final int t;
  final double cx;
  final double cy;
  final Size screen;
  final Cosmetic companion;
  final String? assetPath;
  final List<String> relicIds;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Backdrop dim ramps to 55% alpha over the first 500ms.
    final dim = (t / 500).clamp(0.0, 1.0);

    final fly = _frac(t, 0, _kFlyInEndMs);
    final orbit = _frac(t, _kFlyInEndMs, _kOrbitEndMs);
    final pull = _frac(t, _kOrbitEndMs, _kPullEndMs);
    final aura = _frac(t, _kAuraStartMs, _kAuraEndMs);
    final sprite = _frac(t, _kSpriteStartMs, _kSpriteEndMs);
    final settle = _frac(t, _kSettleStartMs, _kDurationMs);

    final spriteScale = _lerp(0.12, 1.0, _easeOut(sprite));
    final spriteOpacity = math.pow(sprite, 1.6).toDouble();
    final spriteBlur = _lerp(14.0, 0.0, _easeOut(sprite));
    final spriteRise = _lerp(40.0, 0.0, _easeOut(sprite));
    final compY = cy - 30 - spriteRise +
        (settle > 0 ? math.sin(t / 350.0) * 6.0 : 0.0);

    // Relic positions: fly-in then orbit/spiral then hide.
    final relicGeoms = _buildRelicGeoms(t, fly, orbit, pull, cx, cy);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Backdrop dim.
        Positioned.fill(
          child: ColoredBox(
            color: Tokens.bg.withValues(alpha: 0.55 * dim),
          ),
        ),
        // Soft scene-wide glow under the eventual sprite. Composed
        // from two radial layers so the warm ember tone reads on
        // dark surface without blowing out at full opacity.
        Positioned(
          left: cx - 220,
          top: cy - 220,
          width: 440,
          height: 440,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFC850)
                        .withValues(alpha: 0.35 * aura.clamp(0.0, 1.0)),
                    Tokens.accent.withValues(alpha: 0.15 * sprite),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.7],
                ),
              ),
            ),
          ),
        ),
        // Particles: burst (outward) + wisps (inward) + reveal sparks.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ForgingParticlesPainter(
                tMs: t,
                cx: cx,
                cy: compY,
                color: color,
              ),
            ),
          ),
        ),
        // Aura bloom — small focused white-gold disc that grows
        // before the sprite settles in.
        if (aura > 0 && sprite < 1)
          Positioned(
            left: cx,
            top: compY,
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(-0.5, -0.5),
                child: Transform.scale(
                  scale: _lerp(40.0, 220.0, aura),
                  child: Opacity(
                    opacity: _lerp(0.9, 0.0, sprite).clamp(0.0, 1.0),
                    child: Container(
                      width: 1,
                      height: 1,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFFDC8C),
                            Color(0x66FFA03C),
                            Color(0x00000000),
                          ],
                          stops: [0.0, 0.4, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Relics (orbit + spiral). Hidden after pull.
        if (t < _kPullEndMs)
          for (var i = 0; i < relicGeoms.length && i < relicIds.length; i++)
            _PositionedRelic(
              geom: relicGeoms[i],
              relicId: relicIds[i],
              color: color,
            ),
        // Companion sprite — fades in for the reveal.
        if (sprite > 0)
          Positioned(
            left: cx - 110,
            top: compY - 110,
            width: 220,
            height: 220,
            child: IgnorePointer(
              child: Opacity(
                opacity: spriteOpacity.clamp(0.0, 1.0),
                child: ImageFiltered(
                  imageFilter: spriteBlur > 0.1
                      ? _gaussianBlur(spriteBlur)
                      : _noBlur,
                  child: Transform.scale(
                    scale: spriteScale,
                    child: _CompanionSprite(
                      assetPath: assetPath,
                      color: color,
                      opacity: spriteOpacity.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Status text crossfade.
        Positioned(
          left: 0,
          right: 0,
          bottom: screen.height * 0.18,
          child: IgnorePointer(
            child: _ForgingStatusText(t: t, companion: companion, l10n: l10n),
          ),
        ),
      ],
    );
  }
}

/// Resolved geometry for a single relic this frame.
class _RelicGeom {
  const _RelicGeom({
    required this.x,
    required this.y,
    required this.scale,
    required this.opacity,
    required this.glow,
  });
  final double x;
  final double y;
  final double scale;
  final double opacity;
  final double glow;
}

/// Computes positions for up to two relics through the orbit timeline.
/// Mirrors the OrbitVariant logic in claim.jsx:
/// fly-in from sheet positions (±130, 0.62h) into orbit start (±80, cy),
/// then accelerating orbit + spiral (turns ≈ 2.5, radius lerp 80 → 0),
/// then scale-down during pull-to-center (1 → 0.3, 2400–2700 ms).
List<_RelicGeom> _buildRelicGeoms(
  int t,
  double fly,
  double orbit,
  double pull,
  double cx,
  double cy,
) {
  if (t >= _kPullEndMs) return const [];
  final sheetY = cy + 130; // proxy for sheet-anchored start
  // Two-relic symmetric layout — extra relics aren't authored
  // by this variant; they would land on top of each other.
  final starts = [
    Offset(cx - 130, sheetY),
    Offset(cx + 130, sheetY),
  ];
  final orbitStarts = [
    Offset(cx - 80, cy),
    Offset(cx + 80, cy),
  ];
  final scale = t < _kOrbitEndMs ? 1.0 : _lerp(1.0, 0.3, pull);
  final glow = t < _kFlyInEndMs ? fly : 1.0;
  final out = <_RelicGeom>[];
  for (var i = 0; i < 2; i++) {
    double x, y;
    if (t < _kFlyInEndMs) {
      x = _lerp(starts[i].dx, orbitStarts[i].dx, _easeOut(fly));
      y = _lerp(starts[i].dy, orbitStarts[i].dy, _easeOut(fly));
    } else {
      // Accelerating angular sweep + spiral collapse.
      final o = ((t - _kFlyInEndMs) / (_kPullEndMs - _kFlyInEndMs))
          .clamp(0.0, 1.0);
      const turns = 2.5;
      final ang = o * turns * math.pi * 2 * (1 + o * 1.5);
      final r = _lerp(80.0, 0.0, _easeInOut(orbit.clamp(0.0, 1.0)));
      final phase = i == 0 ? 0.0 : math.pi;
      x = cx + math.cos(ang + phase) * r;
      y = cy + math.sin(ang + phase) * r;
    }
    out.add(_RelicGeom(
      x: x,
      y: y,
      scale: scale,
      opacity: 1.0,
      glow: glow,
    ));
  }
  return out;
}

class _PositionedRelic extends StatelessWidget {
  const _PositionedRelic({
    required this.geom,
    required this.relicId,
    required this.color,
  });

  final _RelicGeom geom;
  final String relicId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    return Positioned(
      left: geom.x - size / 2,
      top: geom.y - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: geom.opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: geom.scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C2A).withValues(
                      alpha: (0.5 + 0.5 * geom.glow).clamp(0.0, 1.0),
                    ),
                    blurRadius: 12 + 16 * geom.glow,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: CosmeticAssetThumb(
                  cosmeticId: relicId,
                  size: size,
                  borderRadius: 18,
                  fallbackColor: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionSprite extends StatelessWidget {
  const _CompanionSprite({
    required this.assetPath,
    required this.color,
    required this.opacity,
  });

  final String? assetPath;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final shadowAlpha = (0.55 * opacity).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C2A).withValues(alpha: shadowAlpha),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: assetPath == null
          ? Icon(Icons.pets_rounded, size: 120, color: color)
          : Image.asset(
              assetPath!,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.pets_rounded, size: 120, color: color),
            ),
    );
  }
}

class _ForgingStatusText extends StatelessWidget {
  const _ForgingStatusText({
    required this.t,
    required this.companion,
    required this.l10n,
  });

  final int t;
  final Cosmetic companion;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    String label;
    String? sub;
    final isReveal = t >= _kStatusAwakeningEndMs;
    if (t < _kFlyInEndMs) {
      label = l10n.cosmeticCompanionClaimStepRitual;
    } else if (t < _kStatusBindingEndMs) {
      label = l10n.cosmeticCompanionClaimStepBinding;
    } else if (t < _kStatusHideEndMs) {
      label = '';
    } else if (t < _kStatusAwakeningEndMs) {
      label = l10n.cosmeticCompanionClaimStepAwakening;
    } else {
      label = companion.name(l10n);
      sub = l10n.cosmeticCompanionClaimRevealSubtitle;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      child: label.isEmpty
          ? const SizedBox.shrink(key: ValueKey('hide'))
          : Column(
              key: ValueKey('label-${isReveal ? 'reveal' : t ~/ 100}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isReveal
                        ? Tokens.onSurface
                        : Tokens.onSurfaceMuted,
                    fontSize: isReveal ? 30 : 15,
                    fontWeight:
                        isReveal ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: isReveal ? 0 : 0.3,
                    shadows: isReveal
                        ? const [
                            Shadow(
                              color: Color(0x66FFB450),
                              blurRadius: 20,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Tokens.onSurfaceMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Custom painter for the three particle layers that don't need
/// hit-testing or layout: outward burst (~60 particles), inward
/// converging wisps (~12), and gentle reveal sparks (~30).
class _ForgingParticlesPainter extends CustomPainter {
  _ForgingParticlesPainter({
    required this.tMs,
    required this.cx,
    required this.cy,
    required this.color,
  });

  final int tMs;
  final double cx;
  final double cy;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Burst: 60 particles fanning out 2700 → 3800 ms.
    if (tMs >= _kBurstStartMs && tMs < _kBurstStartMs + 1100) {
      _paintBurst(canvas);
    }
    // Wisps: converging inward 2800 → 4750 ms.
    if (tMs >= _kWispStartMs && tMs < _kWispEndMs) {
      _paintWisps(canvas);
    }
    // Reveal sparks: drifting upward from companion 3300+ ms.
    if (tMs >= 3300 && tMs < _kDurationMs) {
      _paintRevealSparks(canvas);
    }
  }

  void _paintBurst(Canvas canvas) {
    const count = 60;
    const lifeMs = 1100;
    final localT = tMs - _kBurstStartMs;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final phase = ((i * 97.3) % lifeMs).toInt();
      final ageMs = (localT + phase) % lifeMs;
      final ageFrac = ageMs / lifeMs;
      final rnd1 = _hash(i * 12.9898);
      final rnd2 = _hash(i * 39.346 + 11.135);
      final ang = rnd1 * math.pi * 2;
      final dist = rnd2 * 260 + 20;
      final x = cx + math.cos(ang) * dist * ageFrac;
      final y = cy + math.sin(ang) * dist * ageFrac + 20 * ageFrac * ageFrac;
      final opacity = (1 - ageFrac).clamp(0.0, 1.0);
      final s = 4 * (0.6 + 0.8 * math.sin(ageFrac * math.pi));
      paint.color = const Color(0xFFFFD166).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), s / 2, paint);
    }
  }

  void _paintWisps(Canvas canvas) {
    const count = 14;
    const lifeMs = 900;
    final localT = tMs - _kWispStartMs;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final phase = ((i * 73.7) % lifeMs).toInt();
      final ageMs = (localT + phase) % lifeMs;
      final ageFrac = ageMs / lifeMs;
      final rnd = _hash(i * 12.9898);
      final ang = rnd * math.pi * 2;
      final startR = 150 * (0.7 + 0.5 * _hash(i * 39.346));
      final r = _lerp(startR, 0, ageFrac);
      final x = cx + math.cos(ang) * r;
      final y = cy + math.sin(ang) * r * 0.7;
      final opacity = math.sin(ageFrac * math.pi).clamp(0.0, 1.0);
      final s = 3 * (0.7 + 0.6 * (1 - ageFrac));
      paint.color = const Color(0xFFFFD166).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), s / 2, paint);
    }
  }

  void _paintRevealSparks(Canvas canvas) {
    const count = 30;
    const lifeMs = 2000;
    final localT = tMs - 3300;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final phase = ((i * 113.1) % lifeMs).toInt();
      final ageMs = (localT + phase) % lifeMs;
      final ageFrac = ageMs / lifeMs;
      final rnd1 = _hash(i * 12.9898 + 9.0);
      final rnd2 = _hash(i * 39.346 + 9.0);
      final ang = rnd1 * math.pi * 2;
      final dist = rnd2 * 120 + 20;
      final x = cx + math.cos(ang) * dist * ageFrac;
      // Slight upward drift (gravity = -15)
      final y = cy - 10 +
          math.sin(ang) * dist * ageFrac -
          15 * ageFrac * ageFrac;
      final opacity = (1 - ageFrac).clamp(0.0, 1.0);
      final s = 2.5 * (0.6 + 0.8 * math.sin(ageFrac * math.pi));
      paint.color = const Color(0xFFFFD166).withValues(alpha: opacity * 0.9);
      canvas.drawCircle(Offset(x, y), s / 2, paint);
    }
  }

  static double _hash(double v) {
    final s = math.sin(v) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _ForgingParticlesPainter old) =>
      old.tMs != tMs || old.cx != cx || old.cy != cy;
}

// ── Math helpers ────────────────────────────────────────────────

double _frac(int t, int a, int b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

double _easeInOut(double t) {
  if (t < 0.5) return 4 * t * t * t;
  return 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
}

// `ImageFiltered` requires an `ImageFilter`. Building one per frame
// is fine — they are lightweight value types and Flutter caches the
// shader internally.
ImageFilter _gaussianBlur(double sigma) =>
    ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

final ImageFilter _noBlur = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
