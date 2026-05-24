import 'package:flutter/material.dart';

/// Bridges the forging reveal frame and the unlocked details sheet:
/// the companion sprite glides from the overlay center (220×220) down
/// into the detail-sheet's avatar slot (130×130) over 1150 ms with
/// the spec curve `cubic-bezier(.22, .8, .2, 1)`.
///
/// The morph layer is intended to live in the root [Overlay] above
/// the rising / settled details sheet. The sheet hides its native
/// avatar via the `hideCompanion` notifier (kept on the sheet's
/// state) so that the morph layer is the only place the companion
/// renders during the handoff — the slot un-hides exactly when this
/// widget invokes [onComplete] and the OverlayEntry is removed.
///
/// Resolves the destination from [destSlotKey] **after first frame**:
/// the sheet's avatar slot may not be laid out yet at the moment the
/// morph spawns (rebuild from claim → unlocked landed only a few
/// frames earlier). A fallback that lands the sprite at the source
/// position keeps the visual safe if the slot turns out to be
/// missing (e.g. sheet dismissed mid-ritual).
class CompanionClaimMorph extends StatefulWidget {
  const CompanionClaimMorph({
    super.key,
    required this.assetPath,
    required this.color,
    required this.displayScale,
    required this.sourceCenter,
    required this.destSlotKey,
    required this.onComplete,
    this.sourceSize = 220,
    this.destSize = 130,
    this.duration = const Duration(milliseconds: 1150),
  });

  /// Resolved companion sprite asset path. Null falls back to a
  /// solid-color circle so the morph never crashes on a missing
  /// asset.
  final String? assetPath;

  /// Tint used for the drop-shadow and the missing-asset fallback.
  final Color color;

  /// Per-asset display scale forwarded from the catalog row. Pinned
  /// for the whole morph so both endpoints visually match their
  /// adjacent screens — the forging sprite and the details-header
  /// preview both apply the same scale, so the morph picking either
  /// (instead of lerping to a generic value) keeps the silhouette
  /// continuous through the handoff.
  final double displayScale;

  /// Companion's last on-screen center in the forging overlay.
  final Offset sourceCenter;

  /// 220 px overlay sprite size.
  final double sourceSize;

  /// GlobalKey attached to the unlocked-layout avatar slot. Read
  /// once on the first frame after mount.
  final GlobalKey destSlotKey;

  /// 130 px target slot size.
  final double destSize;

  /// Spec timing — kept overridable for tests / debugging.
  final Duration duration;

  /// Fires once when the morph reaches the destination and is ready
  /// for the host to remove the OverlayEntry + un-hide the slot.
  final VoidCallback onComplete;

  @override
  State<CompanionClaimMorph> createState() => _CompanionClaimMorphState();
}

class _CompanionClaimMorphState extends State<CompanionClaimMorph>
    with SingleTickerProviderStateMixin {
  static const _curve = Cubic(0.22, 0.8, 0.2, 1.0);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Destination center resolved from [widget.destSlotKey]. Falls
  /// back to [widget.sourceCenter] (a no-op morph) if the slot is
  /// not laid out by the time we measure it.
  Offset? _destCenter;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAndStart());
  }

  void _resolveAndStart() {
    if (!mounted) return;
    setState(() => _destCenter = _measureDest());
    _ctrl.addStatusListener(_onStatus);
    _ctrl.forward();
  }

  Offset _measureDest() {
    final ctx = widget.destSlotKey.currentContext;
    final ro = ctx?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return widget.sourceCenter;
    final origin = ro.localToGlobal(Offset.zero);
    return origin + Offset(ro.size.width / 2, ro.size.height / 2);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Until the destination is measured we render the sprite at its
    // source position so there is no flash / jump. The animation
    // only starts once we have a resolved destination.
    final dest = _destCenter ?? widget.sourceCenter;
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _curve.transform(_ctrl.value);
            final cx = _lerp(widget.sourceCenter.dx, dest.dx, t);
            final cy = _lerp(widget.sourceCenter.dy, dest.dy, t);
            final size = _lerp(widget.sourceSize, widget.destSize, t);
            final shadowBlur = _lerp(32.0, 18.0, t);
            final shadowOffset = _lerp(12.0, 8.0, t);
            final shadowAlpha = _lerp(0.55, 0.45, t);
            // Pin scale to the catalog row's per-asset value. Both
            // the forging sprite and the details-header preview render
            // with the same `displayScale`, so holding the same value
            // here keeps the silhouette continuous through the
            // handoff — no scale lerp needed, only the size + position
            // lerps below.
            final contentScale = widget.displayScale;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: cx - size / 2,
                  top: cy - size / 2,
                  width: size,
                  height: size,
                  child: _MorphSprite(
                    assetPath: widget.assetPath,
                    color: widget.color,
                    shadowBlur: shadowBlur,
                    shadowOffset: shadowOffset,
                    shadowAlpha: shadowAlpha,
                    contentScale: contentScale,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _MorphSprite extends StatelessWidget {
  const _MorphSprite({
    required this.assetPath,
    required this.color,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.shadowAlpha,
    required this.contentScale,
  });

  final String? assetPath;
  final Color color;
  final double shadowBlur;
  final double shadowOffset;
  final double shadowAlpha;

  /// Per-frame Transform.scale applied to the BoxFit.contain'd asset.
  /// Driven by the morph's progress curve so the silhouette continuously
  /// transitions between the forging endpoint (≈1.7×, silhouette fills
  /// the box) and the details-header endpoint (1.0×, raw asset).
  final double contentScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: shadowAlpha),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowOffset),
          ),
        ],
      ),
      child: assetPath == null
          ? Center(
              child: Icon(Icons.pets_rounded, color: color),
            )
          : ClipRect(
              child: Transform.scale(
                scale: contentScale,
                alignment: const Alignment(0, 0.5),
                child: Image.asset(
                  assetPath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Center(child: Icon(Icons.pets_rounded, color: color)),
                ),
              ),
            ),
    );
  }
}
