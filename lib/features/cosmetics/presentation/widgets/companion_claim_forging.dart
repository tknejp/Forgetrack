import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_models.dart';
import 'companion_claim_morph.dart';
import 'cosmetic_details_header.dart' show kCompanionDetailsSlotSize;
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
    this.relicColors = const [],
    this.destSlotKey,
    this.hideCompanion,
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

  /// Per-relic rarity colors, parallel to [relicIds]. Drives the
  /// orbit-time drop shadow so each relic glows in its own rarity
  /// tint. Defaults to empty, in which case each relic falls back
  /// to [color] (the companion's rarity).
  final List<Color> relicColors;

  /// Companion rarity color — used for the scene-wide outer glow,
  /// aura bloom inner tint, particle burst / wisps / reveal sparks,
  /// and the sprite drop-shadow. The bright "hot core" of every
  /// gradient stays white-gold so the rarity tint reads as the
  /// halo around the reveal, not as a flat repaint.
  final Color color;

  /// Engine-write hook — fires once at t ≈ [_kRevealMs].
  final Future<void> Function() onReveal;

  /// Host-side teardown — fires once at t ≥ [_kDurationMs] +
  /// morph (or immediately after a tap-to-skip).
  final VoidCallback onComplete;

  /// GlobalKey attached to the unlocked-layout avatar slot in
  /// [CosmeticDetailsSheet]. When provided the overlay transitions
  /// to a [CompanionClaimMorph] handoff at t = [_kDurationMs] before
  /// firing [onComplete]; when null the overlay just dismisses.
  final GlobalKey? destSlotKey;

  /// Notifier the unlocked-layout avatar slot watches to hide its
  /// native rendering while the morph layer owns the companion.
  /// Set to true at the reveal frame (so the sheet rebuild from the
  /// engine grant doesn't show a duplicate avatar in the slot) and
  /// reset to false once the morph reaches the destination.
  final ValueNotifier<bool>? hideCompanion;

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
// Awakening label clears 400 ms BEFORE the reveal frame so its
// fade-out (520 ms in [_ForgingStatusText]) finishes before the
// name + subtitle start their own entry. Without this gap the
// awakening label was sliding down while the reveal name slid up
// at the same screen position — both visible at once, both with
// text shadows. The lead-in is a silent pause that lets the
// sprite materialize uncluttered, then the name surfaces clean.
const int _kStatusAwakeningEndMs = 4200;
const int _kRevealMs = 4700;

class _CompanionClaimForgingState extends State<CompanionClaimForging>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kDurationMs),
  );

  bool _burstHapticFired = false;
  bool _revealFired = false;
  bool _completed = false;
  bool _awaitingTap = false;
  bool _morphing = false;

  /// Where the companion sprite sits at end-of-settle — captured so
  /// the morph layer starts exactly where the forging timeline left
  /// off rather than reading the controller value mid-flight.
  Offset? _spriteCenter;

  @override
  void initState() {
    super.initState();
    // [WidgetsBindingObserver.didPopRoute] catches the system back
    // gesture even though our OverlayEntry isn't a route. We
    // intercept it so back behaves like tap-anywhere during the
    // ritual — without this the back gesture would pop the
    // underlying sheet (and any other route below) while our
    // overlay stays mounted, stranding the sprite on whatever
    // screen lies behind it.
    WidgetsBinding.instance.addObserver(this);
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _ctrl.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.removeListener(_onTick);
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  /// Fires when the platform (Android back gesture, iOS swipe-back
  /// equivalent, hardware ESC on desktop) attempts to pop a route.
  /// Returning true marks the event as handled, so no underlying
  /// route is popped.
  @override
  Future<bool> didPopRoute() async {
    if (_morphing) {
      // Let the 1.15 s morph finish; consume the back so it does
      // not pop the host sheet underneath.
      return true;
    }
    _onTap();
    return true;
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
      // Hide the sheet's native avatar BEFORE the engine write so
      // the rebuild triggered by the cosmetic flipping to Owned
      // (a frame or two later) does not flash a second sprite at
      // the destination slot. The morph layer un-hides it again
      // when the handoff completes.
      widget.hideCompanion?.value = true;
      // Fire engine write at the visual reveal point; the host
      // re-renders away from us once the cosmetic lands in
      // inventory but our OverlayEntry persists until [_onStatus]
      // / the morph layer call [onComplete].
      widget.onReveal();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      if (widget.destSlotKey != null) {
        // Hold on the reveal frame until the player taps. They
        // need a moment to read the companion's name + flavor
        // before the morph yanks the sprite into the small slot.
        setState(() => _awaitingTap = true);
      } else {
        // No destination → straight dismissal (kept for parity with
        // hosts that don't need the handoff, e.g. devtools previews).
        WidgetsBinding.instance.addPostFrameCallback((_) => _finalize());
      }
    }
  }

  void _finalize() {
    widget.hideCompanion?.value = false;
    widget.onComplete();
  }

  void _onTap() {
    if (_morphing) return;
    if (_awaitingTap) {
      // Player acknowledged the reveal → kick off the morph.
      setState(() {
        _awaitingTap = false;
        _morphing = true;
      });
      return;
    }
    if (_completed) return;
    // Decision #1: tap-anywhere skip during the forging timeline
    // (including production). Snap to the settle end; the listeners
    // fire reveal + the hold-screen swap on the next ticks.
    _ctrl.value = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final cx = screen.width / 2;
    final cy = screen.height * 0.45;
    // Account for the settle phase wobble so the morph hands off
    // from the actual visible position rather than the nominal
    // center.
    _spriteCenter ??= Offset(cx, cy - 30);

    if (_morphing && widget.destSlotKey != null) {
      return CompanionClaimMorph(
        assetPath: widget.assetPath,
        color: widget.color,
        displayScale: widget.companion is Companion
            ? (widget.companion as Companion).displayScale
            : 1.0,
        sourceCenter: _spriteCenter!,
        destSlotKey: widget.destSlotKey!,
        // Matches the details-header slot size so the morph lands
        // at the same dimensions as the destination render rather
        // than snapping to a slightly different size at handoff.
        destSize: kCompanionDetailsSlotSize,
        onComplete: _finalize,
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          children: [
            // Scene: ticks during forging, frozen at t=_kDurationMs
            // once we're holding for the tap acknowledgement.
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _awaitingTap ? _kDurationMs : _tMs;
                return _ForgingScene(
                  t: t,
                  cx: cx,
                  cy: cy,
                  screen: screen,
                  companion: widget.companion,
                  assetPath: widget.assetPath,
                  relicIds: widget.relicIds,
                  relicColors: widget.relicColors,
                  color: widget.color,
                  l10n: l10n,
                );
              },
            ),
            if (_awaitingTap)
              _RevealHoldDetails(
                companion: widget.companion,
                color: widget.color,
                cx: cx,
                cy: cy,
                screen: screen,
                l10n: l10n,
              ),
          ],
        ),
      ),
    );
  }
}

/// Hold-screen overlay shown after the forging timeline finishes
/// and before the morph handoff. Renders the companion description
/// underneath the reveal name/subtitle (the [_ForgingStatusText]
/// already shows those at t ≥ 4700) and a tap-to-continue hint near
/// the bottom of the screen.
///
/// Both pieces animate in on a single 900 ms controller:
///   * description fades + slides up over 0–520 ms
///   * tap-hint fades + slides up over 400–900 ms
/// Staggering them this way keeps the hold frame from popping all
/// at once — the description "joins" the already-revealed name,
/// then the hint surfaces a beat later to invite the tap.
class _RevealHoldDetails extends StatefulWidget {
  const _RevealHoldDetails({
    required this.companion,
    required this.color,
    required this.cx,
    required this.cy,
    required this.screen,
    required this.l10n,
  });

  final Cosmetic companion;
  final Color color;
  final double cx;
  final double cy;
  final Size screen;
  final AppLocalizations l10n;

  @override
  State<_RevealHoldDetails> createState() => _RevealHoldDetailsState();
}

class _RevealHoldDetailsState extends State<_RevealHoldDetails>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _descFade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _hintFade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.44, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.companion.description(widget.l10n);
    return Stack(
      children: [
        // Description — placed below the name/subtitle block
        // (status text anchored at top: cy + 130). Allow up to
        // 80% of screen width so multi-line copy doesn't crowd
        // the sprite's silhouette.
        Positioned(
          left: widget.screen.width * 0.1,
          right: widget.screen.width * 0.1,
          top: widget.cy + 230,
          child: IgnorePointer(
            child: _RisingFade(
              animation: _descFade,
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(color: Color(0xCC000000), blurRadius: 12),
                  ],
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
        // Tap-to-continue hint — anchored near the bottom safe
        // area so it sits outside the reveal composition.
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.screen.height * 0.07,
          child: IgnorePointer(
            child: _RisingFade(
              animation: _hintFade,
              child: _PulsingTapHint(
                label: widget.l10n.cosmeticCompanionClaimTapToContinue,
                color: widget.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fade + small upward slide (+ optional scale-up) driven by an
/// externally-staggered animation. Kept generic so the reveal name,
/// description and tap-hint can share one motion family without
/// each spinning up its own controller.
class _RisingFade extends StatelessWidget {
  const _RisingFade({
    required this.animation,
    required this.child,
    this.translateFrom = 14,
    this.scaleFrom = 1.0,
  });

  final Animation<double> animation;
  final Widget child;

  /// Initial y-offset (px) the child starts at, lerped to 0.
  final double translateFrom;

  /// Initial scale the child starts at, lerped to 1.0. Use values
  /// slightly below 1 (e.g. 0.88) for hero text that should feel
  /// like it grows into place; leave at 1.0 for plain fades.
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        final t = animation.value;
        final scale = scaleFrom + (1.0 - scaleFrom) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * translateFrom),
            child: Transform.scale(
              scale: scale,
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PulsingTapHint extends StatefulWidget {
  const _PulsingTapHint({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  State<_PulsingTapHint> createState() => _PulsingTapHintState();
}

class _PulsingTapHintState extends State<_PulsingTapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final v = _pulse.value;
        final alpha = 0.55 + 0.4 * v;
        return Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Tokens.onSurface.withValues(alpha: alpha),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            shadows: [
              Shadow(
                color: widget.color.withValues(alpha: 0.4 * v),
                blurRadius: 16,
              ),
              const Shadow(color: Color(0xCC000000), blurRadius: 10),
            ],
          ),
        );
      },
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
    required this.relicColors,
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
  final List<Color> relicColors;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Backdrop fades to fully opaque over the first 500 ms. The
    // ritual is its own composition — the inventory grid + the
    // claimable body of the bottom sheet behind it should not
    // bleed through at all. Anything less than full alpha lets
    // the sheet's light CTA + silhouette ghost into the frame
    // (visible at 92 % alpha during device review).
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
        // Backdrop dim — fully opaque once the ritual is in flight.
        Positioned.fill(
          child: ColoredBox(
            color: Tokens.bg.withValues(alpha: dim),
          ),
        ),
        // Soft scene-wide glow under the eventual sprite. Inner
        // stop stays warm white-gold (so the core reads as a
        // luminous hot spot regardless of rarity); the mid stop
        // adopts the companion's rarity tint so the halo
        // colour-codes the reveal.
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
                    const Color(0xFFFFE9A8)
                        .withValues(alpha: 0.32 * aura.clamp(0.0, 1.0)),
                    color.withValues(alpha: 0.22 * sprite),
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
        // Aura bloom — small focused disc that grows before the
        // sprite settles in. Hot white-gold core fades into the
        // companion's rarity tint at the edge.
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFEFC2),
                            color.withValues(alpha: 0.40),
                            const Color(0x00000000),
                          ],
                          stops: const [0.0, 0.4, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Relics (orbit + spiral). Hidden after pull. Each relic
        // glows in its own rarity color; missing entries fall back
        // to the companion's rarity color.
        if (t < _kPullEndMs)
          for (var i = 0; i < relicGeoms.length && i < relicIds.length; i++)
            _PositionedRelic(
              geom: relicGeoms[i],
              relicId: relicIds[i],
              glowColor:
                  i < relicColors.length ? relicColors[i] : color,
              fallbackColor: color,
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
                      displayScale: companion is Companion
                          ? (companion as Companion).displayScale
                          : 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Status text crossfade. Anchored just below the companion
        // sprite (cy + 130 ≈ sprite bottom + 20) so the label sits
        // in the gap between the sprite and the rising bottom
        // sheet, instead of overlapping the sheet's drag-handle
        // area at the bottom of the screen.
        Positioned(
          left: 0,
          right: 0,
          top: cy + 130,
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
    required this.glowColor,
    required this.fallbackColor,
  });

  final _RelicGeom geom;
  final String relicId;

  /// Drop-shadow color — the relic's own rarity tint.
  final Color glowColor;

  /// Tint used by [CosmeticAssetThumb] when the relic has no
  /// resolvable asset.
  final Color fallbackColor;

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
                    color: glowColor.withValues(
                      alpha: (0.45 + 0.45 * geom.glow).clamp(0.0, 1.0),
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
                  fallbackColor: fallbackColor,
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
    required this.displayScale,
  });

  final String? assetPath;
  final Color color;
  final double opacity;

  /// Per-asset display scale from the catalog row. Tiny silhouettes
  /// (ember sprite, ice wisp) zoom up so the reveal frame doesn't
  /// look empty; canvas-filling silhouettes (mountain gryphon) render
  /// closer to raw so wings don't clip against the slot edges. Anchor
  /// is biased below centre so the upward shift compensates for the
  /// bottom-biased composition shared by most companion canvases.
  final double displayScale;

  @override
  Widget build(BuildContext context) {
    final shadowAlpha = (0.55 * opacity).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: shadowAlpha),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: assetPath == null
          ? Icon(Icons.pets_rounded, size: 120, color: color)
          : SizedBox(
              width: 220,
              height: 220,
              child: ClipRect(
                child: Transform.scale(
                  scale: displayScale,
                  alignment: const Alignment(0, 0.5),
                  child: Image.asset(
                    assetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.pets_rounded, size: 120, color: color),
                  ),
                ),
              ),
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

  /// Phase identifier driving the [AnimatedSwitcher] key. The
  /// previous implementation derived the key from `t ~/ 100`, which
  /// caused the switcher to swap the SAME label every 100 ms — the
  /// labels jittered instead of crossfading. Phase-based keys mean
  /// the switcher fires exactly four times across the timeline:
  /// once per label change.
  String _phaseOf(int t) {
    if (t < _kFlyInEndMs) return 'ritual';
    if (t < _kStatusBindingEndMs) return 'binding';
    if (t < _kStatusHideEndMs) return 'hidden';
    if (t < _kStatusAwakeningEndMs) return 'awakening';
    // 4200–4700 ms: silent lead-in to the reveal so the
    // awakening label fully clears before the name surfaces.
    if (t < _kRevealMs) return 'preReveal';
    return 'reveal';
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phaseOf(t);
    final statusLabel = switch (phase) {
      'ritual' => l10n.cosmeticCompanionClaimStepRitual,
      'binding' => l10n.cosmeticCompanionClaimStepBinding,
      'awakening' => l10n.cosmeticCompanionClaimStepAwakening,
      _ => '',
    };

    // Status label (ritual / binding / awakening) lives in an
    // AnimatedSwitcher so phase transitions crossfade in-place.
    // The reveal name + subtitle deliberately do NOT ride this
    // switcher — they need their own staggered fade-up (see
    // [_RevealNameBlock]) so the name doesn't slam in at fontSize
    // 30 the moment "Probouzím společníka…" exits.
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(anim);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(position: slide, child: child),
            );
          },
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.center,
            children: [...previous, if (current != null) current],
          ),
          child: statusLabel.isEmpty
              ? const SizedBox.shrink(key: ValueKey('label-hidden'))
              : Text(
                  statusLabel,
                  key: ValueKey('label-$phase'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Tokens.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(color: Color(0xCC000000), blurRadius: 12),
                    ],
                  ),
                ),
        ),
        if (phase == 'reveal')
          _RevealNameBlock(
            name: companion.name(l10n),
            subtitle: l10n.cosmeticCompanionClaimRevealSubtitle,
          ),
      ],
    );
  }
}

/// Companion name + subtitle revealed via a staggered own-controller
/// fade + slide-up. The name leads (0–600 ms over the 1100 ms
/// entry) and the subtitle joins partway through (440–1100 ms).
/// Kept out of the surrounding [AnimatedSwitcher] so the name
/// doesn't pop in at fontSize 30 the moment "Probouzím společníka…"
/// finishes its swap-out — instead it surfaces gently, well after
/// the previous label has cleared.
class _RevealNameBlock extends StatefulWidget {
  const _RevealNameBlock({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  State<_RevealNameBlock> createState() => _RevealNameBlockState();
}

class _RevealNameBlockState extends State<_RevealNameBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  // Slower easeOutQuart curve + a touch of scale-up gives the name
  // a sense of "emerging" rather than appearing fully formed. The
  // subtitle picks up the same easeOut but waits past the name's
  // halfway mark so the two are perceived as a duet, not a unit.
  late final Animation<double> _nameAnim = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.0, 0.60, curve: Curves.easeOutQuart),
  );
  late final Animation<double> _subAnim = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RisingFade(
          animation: _nameAnim,
          scaleFrom: 0.88,
          translateFrom: 18,
          child: Text(
            widget.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Tokens.onSurface,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              shadows: [
                Shadow(color: Color(0x99FFB450), blurRadius: 24),
                Shadow(color: Color(0xCC000000), blurRadius: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _RisingFade(
          animation: _subAnim,
          child: Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Tokens.onSurface.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              shadows: const [
                Shadow(color: Color(0xCC000000), blurRadius: 10),
              ],
            ),
          ),
        ),
      ],
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
      // Younger particles read as hot-white sparks; as they fade
      // outward they pick up the rarity tint so the burst plume
      // colour-codes the reveal.
      paint.color = _spark(opacity, ageFrac);
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
      // Wisps converge inward and grow into the sprite — fade
      // them from the rarity tint at the outer edge toward
      // hot-white at the convergence point.
      paint.color = _spark(opacity, 1 - ageFrac);
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
      paint.color = _spark(opacity * 0.9, ageFrac);
      canvas.drawCircle(Offset(x, y), s / 2, paint);
    }
  }

  /// Picks a per-particle tint along the white-gold → rarity ramp.
  /// `mix` of 0 keeps the spark hot-white; 1 fully adopts the
  /// companion's rarity color. Alpha is multiplied onto the result.
  Color _spark(double alpha, double mix) {
    final tinted = Color.lerp(
          const Color(0xFFFFE9A8),
          color,
          mix.clamp(0.0, 1.0),
        ) ??
        color;
    return tinted.withValues(alpha: alpha.clamp(0.0, 1.0));
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
