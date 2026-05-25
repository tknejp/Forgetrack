import 'package:flutter/widgets.dart';

/// PageView physics that commits to the next page on a much smaller drag
/// than the default [PageScrollPhysics] (which snaps back unless the user
/// crosses the page midpoint or flings hard).
///
/// Why: the stock behaviour feels like the screen is fighting the user when
/// they drag ~30–40 % across — the page reverts. Lowering the position and
/// velocity thresholds makes shell-level swipes feel responsive.
///
/// Defaults: a short fast flick (~5 % across @ 60 px/s) commits. Pure-distance
/// drags commit at 8 % of the viewport; anything between 8 % and 92 % with no
/// flick rounds to the nearest page (so a slow half-drag still goes the way
/// the player pushed it).
class SnappyPageScrollPhysics extends ScrollPhysics {
  const SnappyPageScrollPhysics({
    super.parent,
    this.commitThreshold = 0,
    this.velocityThreshold = 0,
  });

  final double commitThreshold;
  final double velocityThreshold;

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      SnappyPageScrollPhysics(
        parent: buildParent(ancestor),
        commitThreshold: commitThreshold,
        velocityThreshold: velocityThreshold,
      );

  double _page(ScrollMetrics position) =>
      position.viewportDimension > 0
          ? position.pixels / position.viewportDimension
          : 0;

  double _pixelsForPage(ScrollMetrics position, double page) =>
      page * position.viewportDimension;

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final current = _page(position);
    final base = current.floorToDouble();
    final progress = current - base;

    double targetPage;
    // Strict inequalities so velocity == 0 falls through to the
    // position-based branches. A tap that interrupts an in-flight
    // ballistic animation re-enters `createBallisticSimulation` with
    // velocity 0 to settle; with `<=` the negative-velocity branch was
    // satisfied (`0 <= -0`) and the page reverted to `floor(current)`.
    // For a leftward swipe (page 0 → 1) that meant snapping back to
    // page 0; the rightward swipe (page 1 → 0) hid the bug because
    // `floor(current)` already pointed at the swipe's target.
    if (velocity < -velocityThreshold) {
      targetPage = base;
    } else if (velocity > velocityThreshold) {
      targetPage = base + 1;
    } else if (progress >= 1 - commitThreshold) {
      targetPage = base + 1;
    } else if (progress <= commitThreshold) {
      targetPage = base;
    } else {
      targetPage = current.roundToDouble();
    }

    final targetPixels = _pixelsForPage(position, targetPage)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    if ((targetPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
