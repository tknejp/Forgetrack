import 'package:flutter/widgets.dart';

/// PageView physics that commits to the next page on a much smaller drag
/// than the default [PageScrollPhysics] (which snaps back unless the user
/// crosses the page midpoint or flings hard).
///
/// Why: the stock behaviour feels like the screen is fighting the user when
/// they drag ~30–40 % across — the page reverts. Lowering the position and
/// velocity thresholds makes shell-level swipes feel responsive.
class SnappyPageScrollPhysics extends ScrollPhysics {
  const SnappyPageScrollPhysics({
    super.parent,
    this.commitThreshold = 0.12,
    this.velocityThreshold = 120,
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
    if (velocity <= -velocityThreshold) {
      targetPage = base;
    } else if (velocity >= velocityThreshold) {
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
