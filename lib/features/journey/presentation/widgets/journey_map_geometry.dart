import 'dart:math' as math;
import 'dart:ui';

import '../../domain/journey_models.dart';
import 'journey_map_layout.dart';
import 'journey_map_route.dart';

class MapCollisionCircle {
  const MapCollisionCircle({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;
}

double journeyMapCanvasHeight({
  required double viewportWidth,
  required double viewportHeight,
  required bool interactive,
}) {
  if (!interactive) return viewportHeight;
  return math.max(
    viewportHeight,
    viewportWidth * JourneyMapLayout.imageAspectRatio,
  );
}

List<Offset> journeyMapNodePositions({
  required List<JourneyCheckpoint> checkpoints,
  required JourneyMapRoute route,
  required double viewportWidth,
  required double viewportHeight,
  required double canvasHeight,
  required bool interactive,
}) {
  final checkpointCount = checkpoints.length;
  if (checkpointCount <= 0) return const [];

  if (!interactive) {
    if (checkpointCount == 1) {
      return [
        Offset(
          viewportWidth * JourneyMapLayout.collapsedSingleNodeX,
          viewportHeight * JourneyMapLayout.collapsedSingleNodeY,
        ),
      ];
    }

    final availableHeight = math.max(
      1.0,
      viewportHeight -
          JourneyMapLayout.collapsedTopPadding -
          JourneyMapLayout.collapsedBottomPadding,
    );
    final step = availableHeight / (checkpointCount - 1);

    // Collapsed mode is not a compressed full map. It is a clean recent
    // progress preview, so keep the points readable and centered.

    return List<Offset>.generate(
      checkpointCount,
      (index) => Offset(
        viewportWidth *
            JourneyMapLayout.collapsedNodeXs[
                index % JourneyMapLayout.collapsedNodeXs.length],
        JourneyMapLayout.collapsedTopPadding + (index * step),
      ),
      growable: false,
    );
  }

  final positions = List<Offset>.filled(
    checkpointCount,
    Offset(viewportWidth * 0.5, canvasHeight * 0.5),
  );
  final occupied = <MapCollisionCircle>[];

  for (var index = 0; index < checkpointCount; index++) {
    final cp = checkpoints[index];
    final point = route.pointForCheckpoint(cp);
    if (point == null) continue;

    positions[index] = point.toOffset(
      mapWidth: viewportWidth,
      mapHeight: canvasHeight,
    );

    if (cp.isPathAnchor) {
      occupied.add(
        MapCollisionCircle(
          center: positions[index],
          radius: journeyMapCollisionRadius(cp),
        ),
      );
    }
  }

  for (var index = 0; index < checkpointCount; index++) {
    final cp = checkpoints[index];
    if (cp.isPathAnchor) continue;

    final point = route.pointForCheckpoint(cp);
    if (point == null) continue;

    final base = point.toOffset(
      mapWidth: viewportWidth,
      mapHeight: canvasHeight,
    );
    final placed = journeyMapSideEventPosition(
      checkpoint: cp,
      route: route,
      base: base,
      mapWidth: viewportWidth,
      mapHeight: canvasHeight,
      occupied: occupied,
    );
    positions[index] = placed;
    occupied.add(
      MapCollisionCircle(
        center: placed,
        radius: journeyMapCollisionRadius(cp),
      ),
    );
  }

  return positions;
}

Offset journeyMapSideEventPosition({
  required JourneyCheckpoint checkpoint,
  required JourneyMapRoute route,
  required Offset base,
  required double mapWidth,
  required double mapHeight,
  required List<MapCollisionCircle> occupied,
}) {
  final pointId = checkpoint.mapPointId ?? checkpoint.levelNumber ?? 0;
  final tangent = route.tangentForPointId(
    pointId: pointId,
    mapWidth: mapWidth,
    mapHeight: mapHeight,
  );
  final length = tangent.distance;
  final normal = length <= JourneyMapLayout.sideEventTangentEpsilon
      ? const Offset(1, 0)
      : Offset(-tangent.dy / length, tangent.dx / length);

  final preferredSide = checkpoint.mapSide ?? 1.0;
  final preferredSign = preferredSide >= 0 ? 1.0 : -1.0;
  final preferredMagnitude = preferredSide.abs().clamp(
        JourneyMapLayout.sideEventPreferredMin,
        JourneyMapLayout.sideEventPreferredMax,
      );
  final baseDistance = (mapWidth * JourneyMapLayout.sideEventDistanceFactor)
      .clamp(
        JourneyMapLayout.sideEventMinDistance,
        JourneyMapLayout.sideEventMaxDistance,
      )
      .toDouble();
  final along = length <= JourneyMapLayout.sideEventTangentEpsilon
      ? const Offset(0, -1)
      : Offset(tangent.dx / length, tangent.dy / length);
  final radius = journeyMapCollisionRadius(checkpoint);

  final candidates = <Offset>[
    for (final sign in [preferredSign, -preferredSign])
      for (final distanceStep in JourneyMapLayout.sideEventDistanceSteps)
        for (final alongShift in JourneyMapLayout.sideEventAlongShifts)
          base +
              normal *
                  baseDistance *
                  (preferredMagnitude + distanceStep) *
                  sign +
              along * alongShift,
  ];

  return candidates
      .map((candidate) => journeyMapClampOffset(
            candidate,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            inset: radius + JourneyMapLayout.collisionGap,
          ))
      .firstWhere(
        (candidate) => !journeyMapCollides(
          candidate,
          radius: radius,
          occupied: occupied,
        ),
        orElse: () => journeyMapClampOffset(
          candidates.first,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          inset: radius + JourneyMapLayout.collisionGap,
        ),
      );
}

bool journeyMapCollides(
  Offset candidate, {
  required double radius,
  required List<MapCollisionCircle> occupied,
}) {
  for (final circle in occupied) {
    final minDistance =
        radius + circle.radius + JourneyMapLayout.collisionGap;
    if ((candidate - circle.center).distance < minDistance) return true;
  }
  return false;
}

Offset journeyMapClampOffset(
  Offset offset, {
  required double mapWidth,
  required double mapHeight,
  required double inset,
}) {
  return Offset(
    offset.dx.clamp(inset, mapWidth - inset).toDouble(),
    offset.dy.clamp(inset, mapHeight - inset).toDouble(),
  );
}

double journeyMapCollisionRadius(JourneyCheckpoint checkpoint) {
  if (checkpoint.id == 'start' ||
      checkpoint.levelNumber == JourneyMapLayout.routePointMaxLevel) {
    return JourneyMapCollisionRadii.specialAnchor;
  }
  if (checkpoint.isCurrent || checkpoint.isNext) {
    return JourneyMapCollisionRadii.highlightedAnchor;
  }
  if (checkpoint.isPathAnchor) return JourneyMapCollisionRadii.pathAnchor;
  if (checkpoint.type == JourneyEventType.achievement) {
    return JourneyMapCollisionRadii.achievement;
  }
  return JourneyMapCollisionRadii.fallback;
}

double journeyMapNodeSize(
  JourneyCheckpoint cp, {
  bool? highlightAsCurrent,
}) {
  final isCurrentVisual = highlightAsCurrent ?? cp.isCurrent;
  if (cp.levelNumber == JourneyMapLayout.routePointMaxLevel) {
    return JourneyMapNodeSizes.finalLevel;
  }
  if (cp.id == 'start') {
    return isCurrentVisual
        ? JourneyMapNodeSizes.current
        : JourneyMapNodeSizes.start;
  }
  if (isCurrentVisual) return JourneyMapNodeSizes.current;
  if (cp.isNext) return JourneyMapNodeSizes.next;

  switch (cp.type) {
    case JourneyEventType.titleMilestone:
      return JourneyMapNodeSizes.titleMilestone;
    case JourneyEventType.achievement:
      return JourneyMapNodeSizes.achievement;
    case JourneyEventType.level:
      return JourneyMapNodeSizes.level;
    case JourneyEventType.quest:
      return JourneyMapNodeSizes.quest;
    case JourneyEventType.streak:
    case JourneyEventType.xpMilestone:
      return JourneyMapNodeSizes.fallback;
  }
}

double journeyMapHalfNodeWidget(
  JourneyCheckpoint cp, {
  bool? highlightAsCurrent,
}) {
  final haloPadding = cp.id == 'start' ||
          cp.levelNumber == JourneyMapLayout.routePointMaxLevel
      ? JourneyMapNodeSizes.specialHaloPadding
      : 0.0;
  return (journeyMapNodeSize(cp, highlightAsCurrent: highlightAsCurrent) +
          JourneyMapNodeSizes.nodeTapPadding +
          haloPadding) /
      2;
}

/// Collapsed header should not show the whole map compressed into a small box.
/// It shows the current/nearest unlocked milestone plus the next locked
/// destination when available, preserving the full map's top-to-bottom order.
List<JourneyCheckpoint> journeyMapCollapsedPreviewCheckpoints(
  List<JourneyCheckpoint> checkpoints,
) {
  if (checkpoints.isEmpty) return const [];

  // Collapsed-mode UI slice — picks ≤2 anchors from the pre-built
  // checkpoint VOs for the mini-preview header; no domain derivation.
  final pathCheckpoints =
      checkpoints.where((cp) => cp.isPathAnchor).toList(growable: false);
  final currentIndex = pathCheckpoints.indexWhere(
    (cp) => cp.isCurrent && cp.isUnlocked,
  );
  final focusIndex = currentIndex >= 0
      ? currentIndex
      : pathCheckpoints.indexWhere((cp) => cp.isUnlocked);

  if (focusIndex < 0) {
    return pathCheckpoints.take(2).toList(growable: false);
  }

  final indexes = <int>[focusIndex];
  final nextIndex = pathCheckpoints.indexWhere((cp) => cp.isNext);

  if (nextIndex >= 0 && nextIndex != focusIndex) {
    indexes.add(nextIndex);
  }

  // If there is no future milestone (level 100 reached), show the previous
  // unlocked anchor so the collapsed preview still has a readable segment.
  if (indexes.length < 2) {
    for (var i = focusIndex + 1; i < pathCheckpoints.length; i++) {
      final cp = pathCheckpoints[i];
      if (!cp.isUnlocked) continue;
      indexes.add(i);
      break;
    }
  }

  indexes.sort();
  return indexes
      .map((i) => pathCheckpoints[i])
      .take(2)
      .toList(growable: false);
}
