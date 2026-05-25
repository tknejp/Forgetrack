import 'package:flutter/material.dart';

/// Wraps [child] with a horizontal-fling detector that snaps the active period
/// to the previous or next one without any visual reveal or slide animation.
///
/// Used at the root of detail screens (Body / Sleep / Activities / Nutrition)
/// so a horizontal swipe anywhere on the page changes the period instantly —
/// the same gesture each screen would otherwise need to wire up itself.
///
/// Gesture-arena behavior: an inner horizontally-scrollable widget (e.g. the
/// chart bar scroller) wins for touches that start inside it, so chart
/// scrolling is unaffected. Touches outside any horizontal scroller bubble up
/// here and trigger the period commit.
class SwipePeriodGesture extends StatelessWidget {
  const SwipePeriodGesture({
    super.key,
    required this.child,
    required this.onPrev,
    required this.onNext,
    this.minVelocity = 120,
    this.minDistance = 20,
  });

  final Widget child;

  /// Called when the user flings right (older period). Pass `null` to disable
  /// (e.g. already at the oldest period).
  final VoidCallback? onPrev;

  /// Called when the user flings left (newer period). Pass `null` to disable
  /// (e.g. already at the current period — `!canGoForward`).
  final VoidCallback? onNext;

  /// Minimum primary velocity (pixels / second) to treat the gesture as a
  /// commit even if the drag was short.
  final double minVelocity;

  /// Minimum drag distance (pixels) below which a slow drag is ignored as
  /// accidental. Used as a fallback when velocity is below [minVelocity].
  final double minDistance;

  @override
  Widget build(BuildContext context) {
    double accumulated = 0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => accumulated = 0,
      onHorizontalDragUpdate: (details) => accumulated += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final distance = accumulated;

        final flingNext =
            velocity <= -minVelocity || distance <= -minDistance;
        final flingPrev = velocity >= minVelocity || distance >= minDistance;

        if (flingNext && onNext != null) {
          onNext!();
        } else if (flingPrev && onPrev != null) {
          onPrev!();
        }
      },
      child: child,
    );
  }
}
