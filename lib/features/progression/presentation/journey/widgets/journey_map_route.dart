import 'package:flutter/material.dart';

import '../../../domain/journey_models.dart';

class JourneyMapPoint {
  const JourneyMapPoint({
    required this.id,
    required this.x,
    required this.y,
  });

  factory JourneyMapPoint.fromJson(Map<String, dynamic> json) {
    return JourneyMapPoint(
      id: (json['id'] as num).toInt(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  final int id;
  final double x;
  final double y;

  Offset toOffset({
    required double mapWidth,
    required double mapHeight,
  }) {
    return Offset(
      x * mapWidth,
      y * mapHeight,
    );
  }
}

class JourneyMapEdge {
  const JourneyMapEdge({
    required this.from,
    required this.to,
  });

  factory JourneyMapEdge.fromJson(Map<String, dynamic> json) {
    return JourneyMapEdge(
      from: (json['from'] as num).toInt(),
      to: (json['to'] as num).toInt(),
    );
  }

  final int from;
  final int to;
}

class JourneyMapRoute {
  JourneyMapRoute({
    required List<JourneyMapPoint> points,
    required this.edges,
  })  : points = List.unmodifiable(points),
        _pointsById = {
          for (final point in points) point.id: point,
        };

  factory JourneyMapRoute.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>? ?? const [];
    final edgesJson = json['edges'] as List<dynamic>? ?? const [];

    return JourneyMapRoute(
      points: pointsJson
          .whereType<Map<String, dynamic>>()
          .map(JourneyMapPoint.fromJson)
          .toList(growable: false),
      edges: edgesJson
          .whereType<Map<String, dynamic>>()
          .map(JourneyMapEdge.fromJson)
          .toList(growable: false),
    );
  }

  final List<JourneyMapPoint> points;
  final List<JourneyMapEdge> edges;
  final Map<int, JourneyMapPoint> _pointsById;

  JourneyMapPoint? pointById(int id) => _pointsById[id];

  JourneyMapPoint? pointForCheckpoint(JourneyCheckpoint checkpoint) {
    final pointId = checkpoint.mapPointId;
    if (pointId != null) return pointById(pointId);

    if (checkpoint.id == 'start') return pointById(0);
    final level = checkpoint.levelNumber;
    if (level != null) return pointById(level);
    return null;
  }

  Offset tangentForPointId({
    required int pointId,
    required double mapWidth,
    required double mapHeight,
  }) {
    JourneyMapPoint? before;
    JourneyMapPoint? after;

    for (final edge in edges) {
      if (edge.to == pointId) before ??= pointById(edge.from);
      if (edge.from == pointId) after ??= pointById(edge.to);
    }

    before ??= pointById(pointId - 1);
    after ??= pointById(pointId + 1);

    final center = pointById(pointId);
    final start = before ?? center;
    final end = after ?? center;
    if (start == null || end == null) return const Offset(0, -1);

    return end.toOffset(mapWidth: mapWidth, mapHeight: mapHeight) -
        start.toOffset(mapWidth: mapWidth, mapHeight: mapHeight);
  }

  List<List<Offset>> edgeSegments({
    required double mapWidth,
    required double mapHeight,
    required bool Function(JourneyMapEdge edge) where,
  }) {
    final segments = <List<Offset>>[];

    for (final edge in edges) {
      if (!where(edge)) continue;

      final from = pointById(edge.from);
      final to = pointById(edge.to);
      if (from == null || to == null) continue;

      segments.add([
        from.toOffset(mapWidth: mapWidth, mapHeight: mapHeight),
        to.toOffset(mapWidth: mapWidth, mapHeight: mapHeight),
      ]);
    }

    return segments;
  }
}
