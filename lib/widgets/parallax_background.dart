import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─── Assets ───────────────────────────────────────────────────────────────────

const _kDayAsset = 'assets/ui/bg_day_wide.jpg';
const _kNightAsset = 'assets/ui/bg_night_wide.jpg';

// ─── Tuning ───────────────────────────────────────────────────────────────────

/// Image rendered at 2× screen width — the surplus allows horizontal tab pan.
const _kWidthFactor = 2.0;

/// Image rendered at 1.14× screen height — surplus allows vertical parallax.
const _kHeightFactor = 1.14;

/// Ratio of background upward movement to scroll distance (0–1).
/// 0.14 = subtle depth without distraction.
const _kVerticalRate = 0.14;

/// Duration of the animated tab-switch pan.
const _kTabAnimDuration = Duration(milliseconds: 460);

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Full-screen parallax background.
///
/// Renders a wide landscape image that:
/// - Pans horizontally when [tabIndex] changes (animated).
/// - Moves upward slowly as the user scrolls ([scrollNotifier]).
/// - Switches between day / night asset based on [Brightness].
///
/// Place this as the first child in the outer app [Stack] so all content
/// renders on top of it.  Set `backgroundColor: Colors.transparent` on every
/// inner [Scaffold] so the image shows through.
class ParallaxBackground extends StatefulWidget {
  final int tabIndex;
  final int tabCount;

  /// Updated by the active scroll view.  The background listens independently
  /// so the parent widget never has to rebuild on scroll events.
  final ValueListenable<double> scrollNotifier;

  const ParallaxBackground({
    super.key,
    required this.tabIndex,
    required this.tabCount,
    required this.scrollNotifier,
  });

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;

  // Horizontal-pan endpoints, expressed as a fraction of the full pan range.
  // Stored so rapid tab switches can interpolate smoothly from mid-animation.
  double _fromFraction = 0.0;
  double _toFraction = 0.0;

  double get _currentFraction =>
      lerpDouble(_fromFraction, _toFraction, _curved.value)!;

  @override
  void initState() {
    super.initState();
    _fromFraction = _tabFraction(widget.tabIndex);
    _toFraction = _fromFraction;
    _ctrl = AnimationController(vsync: this, duration: _kTabAnimDuration);
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(ParallaxBackground old) {
    super.didUpdateWidget(old);
    if (old.tabIndex != widget.tabIndex) {
      _fromFraction = _currentFraction; // snapshot current position
      _toFraction = _tabFraction(widget.tabIndex);
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _tabFraction(int index) =>
      widget.tabCount <= 1 ? 0.0 : index / (widget.tabCount - 1);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_curved, widget.scrollNotifier]),
        builder: (context, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final asset = isDark ? _kNightAsset : _kDayAsset;

          // Use sizeOf so this only re-subscribes to screen size, not all
          // MediaQuery fields.
          final size = MediaQuery.sizeOf(context);
          final W = size.width;
          final H = size.height;

          final imgW = W * _kWidthFactor;
          final imgH = H * _kHeightFactor;
          final maxVShift = H * (_kHeightFactor - 1.0);

          // Horizontal: tab 0 = left edge of image, last tab = right edge.
          final hShift = -_currentFraction * (imgW - W);

          // Vertical: image moves up as user scrolls down.
          final vShift =
              (-widget.scrollNotifier.value * _kVerticalRate).clamp(-maxVShift, 0.0);

          final scrimColor = isDark
              ? const Color(0x85000000) // ~52% black
              : const Color(0x61FFFFFF); // ~38% white

          // ClipRect constrains painting to screen bounds.
          // Positioned lets the image exceed those bounds in layout so it
          // is NOT squeezed by parent tight constraints — only the visible
          // portion is painted.
          return ClipRect(
            child: SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: hShift,
                    top: vShift,
                    width: imgW,
                    height: imgH,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                  // Scrim: keeps card text readable in both themes.
                  Positioned.fill(
                    child: ColoredBox(color: scrimColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
