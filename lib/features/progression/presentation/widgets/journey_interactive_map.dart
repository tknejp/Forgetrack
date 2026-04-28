import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_shared.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// Interactive map — pannable canvas with checkpoints + on-tap tooltip overlay.
// ─────────────────────────────────────────────────────────────────────────────

/// Big interactive journey map.
///
/// Behavior depends on [interactive]:
///   * `true`  → standard pannable map with selection / tooltip / pan hint.
///   * `false` → static mini-preview used in the collapsed header state;
///                no pan, no tooltip, no taps. The same widget renders both
///                states so the path / nodes don't visually re-flow when the
///                map collapses.
class JourneyInteractiveMap extends StatefulWidget {
  const JourneyInteractiveMap({
    super.key,
    required this.checkpoints,
    required this.selectedIndex,
    required this.onSelected,
    required this.height,
    this.interactive = true,
  });

  final List<JourneyCheckpoint> checkpoints;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;
  final double height;

  /// When `false`, behaves as a static mini preview (collapsed state).
  final bool interactive;

  static const String _routeAssetPath = 'assets/map/journey_map_route.json';
  static const double _mapImageWidth = 1408;
  static const double _mapImageHeight = 11712;
  static const double _mapAspectRatio = _mapImageHeight / _mapImageWidth;

  static const double _collapsedTopPadding = 58;
  static const double _collapsedBottomPadding = 58;

  static double _canvasHeight({
    required double viewportWidth,
    required double viewportHeight,
    required bool interactive,
  }) {
    if (!interactive) return viewportHeight;
    return math.max(viewportHeight, viewportWidth * _mapAspectRatio);
  }

  static List<Offset> _nodePositions({
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
          Offset(viewportWidth * 0.50, viewportHeight * 0.50),
        ];
      }

      final availableHeight = math.max(
        1.0,
        viewportHeight - _collapsedTopPadding - _collapsedBottomPadding,
      );
      final step = availableHeight / (checkpointCount - 1);

      // Collapsed mode is not a compressed full map. It is a clean recent
      // progress preview, so keep the points readable and centered.
      const collapsedXs = [0.34, 0.66];

      return List<Offset>.generate(
        checkpointCount,
        (index) => Offset(
          viewportWidth * collapsedXs[index % collapsedXs.length],
          _collapsedTopPadding + (index * step),
        ),
        growable: false,
      );
    }

    final positions = List<Offset>.filled(
      checkpointCount,
      Offset(viewportWidth * 0.5, canvasHeight * 0.5),
    );
    final occupied = <_MapCollisionCircle>[];

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
          _MapCollisionCircle(
            center: positions[index],
            radius: _collisionRadius(cp),
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
      final placed = _sideEventPosition(
        checkpoint: cp,
        route: route,
        base: base,
        mapWidth: viewportWidth,
        mapHeight: canvasHeight,
        occupied: occupied,
      );
      positions[index] = placed;
      occupied.add(
        _MapCollisionCircle(
          center: placed,
          radius: _collisionRadius(cp),
        ),
      );
    }

    return positions;
  }

  static Offset _sideEventPosition({
    required JourneyCheckpoint checkpoint,
    required JourneyMapRoute route,
    required Offset base,
    required double mapWidth,
    required double mapHeight,
    required List<_MapCollisionCircle> occupied,
  }) {
    final pointId = checkpoint.mapPointId ?? checkpoint.levelNumber ?? 0;
    final tangent = route.tangentForPointId(
      pointId: pointId,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    final length = tangent.distance;
    final normal = length <= 0.1
        ? const Offset(1, 0)
        : Offset(-tangent.dy / length, tangent.dx / length);

    final preferredSide = checkpoint.mapSide ?? 1.0;
    final preferredSign = preferredSide >= 0 ? 1.0 : -1.0;
    final preferredMagnitude = preferredSide.abs().clamp(0.65, 1.35);
    final baseDistance = (mapWidth * 0.12).clamp(38.0, 68.0).toDouble();
    final along = length <= 0.1
        ? const Offset(0, -1)
        : Offset(tangent.dx / length, tangent.dy / length);
    final radius = _collisionRadius(checkpoint);

    final candidates = <Offset>[
      for (final sign in [preferredSign, -preferredSign])
        for (final distanceMultiplier in [
          preferredMagnitude,
          preferredMagnitude + 0.42,
          preferredMagnitude + 0.84,
        ])
          for (final alongShift in [0.0, -18.0, 18.0, -34.0, 34.0])
            base +
                normal * baseDistance * distanceMultiplier * sign +
                along * alongShift,
    ];

    return candidates
        .map((candidate) => _clampMapOffset(
              candidate,
              mapWidth: mapWidth,
              mapHeight: mapHeight,
              inset: radius + 4,
            ))
        .firstWhere(
          (candidate) => !_collides(
            candidate,
            radius: radius,
            occupied: occupied,
          ),
          orElse: () => _clampMapOffset(
            candidates.first,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            inset: radius + 4,
          ),
        );
  }

  static bool _collides(
    Offset candidate, {
    required double radius,
    required List<_MapCollisionCircle> occupied,
  }) {
    for (final circle in occupied) {
      final minDistance = radius + circle.radius + 4;
      if ((candidate - circle.center).distance < minDistance) return true;
    }
    return false;
  }

  static Offset _clampMapOffset(
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

  static double _collisionRadius(JourneyCheckpoint checkpoint) {
    if (checkpoint.id == 'start' || checkpoint.levelNumber == 100) return 34;
    if (checkpoint.isCurrent || checkpoint.isNext) return 32;
    if (checkpoint.isPathAnchor) return 30;
    if (checkpoint.type == JourneyEventType.achievement) return 24;
    return 22;
  }

  static List<Widget> _routeLevelDots({
    required JourneyMapRoute route,
    required double mapWidth,
    required double mapHeight,
    required int currentRoutePointId,
    required Set<int> hiddenPointIds,
  }) {
    final points = route.points
        .where(
          (point) =>
              point.id >= 1 &&
              point.id <= 100 &&
              !hiddenPointIds.contains(point.id),
        )
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));

    return [
      for (final point in points)
        Positioned(
          left: point.toOffset(mapWidth: mapWidth, mapHeight: mapHeight).dx - 4,
          top: point.toOffset(mapWidth: mapWidth, mapHeight: mapHeight).dy - 4,
          child: IgnorePointer(
            child: _RouteLevelDot(isUnlocked: point.id <= currentRoutePointId),
          ),
        ),
    ];
  }

  /// Collapsed header should not show the whole map compressed into a small box.
  /// It shows the current/nearest unlocked milestone plus the next locked
  /// destination when available, preserving the full map's top-to-bottom order.
  static List<JourneyCheckpoint> _collapsedPreviewCheckpoints(
    List<JourneyCheckpoint> checkpoints,
  ) {
    if (checkpoints.isEmpty) return const [];

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

  @override
  State<JourneyInteractiveMap> createState() => _JourneyInteractiveMapState();
}

class _JourneyInteractiveMapState extends State<JourneyInteractiveMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// Owns the inner vertical scroll. Living in the state keeps the user's
  /// scroll position stable across rebuilds (e.g. when a checkpoint is
  /// tapped and the parent rebuilds with a new selectedIndex).
  final ScrollController _scroll = ScrollController();
  String? _lastFocusKey;
  late final Future<JourneyMapRoute> _routeFuture;

  @override
  void initState() {
    super.initState();
    _routeFuture = _loadRoute();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<JourneyMapRoute>(
      future: _routeFuture,
      builder: (context, snapshot) {
        final route = snapshot.data;
        if (route == null) {
          return _MapLoadingShell(height: widget.height);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportW = constraints.maxWidth;
            final viewportH = widget.height;

            final visibleCheckpoints = widget.interactive
                ? widget.checkpoints
                : JourneyInteractiveMap._collapsedPreviewCheckpoints(
                    widget.checkpoints,
                  );

            final n = visibleCheckpoints.length;

            final canvasH = JourneyInteractiveMap._canvasHeight(
              viewportWidth: viewportW,
              viewportHeight: viewportH,
              interactive: widget.interactive,
            );

            final absPos = JourneyInteractiveMap._nodePositions(
              checkpoints: visibleCheckpoints,
              route: route,
              viewportWidth: viewportW,
              viewportHeight: viewportH,
              canvasHeight: canvasH,
              interactive: widget.interactive,
            );
            final pathCheckpoints = visibleCheckpoints
                .where((cp) => cp.isPathAnchor)
                .toList(growable: false);
            final currentRoutePointId = _currentRoutePointId(pathCheckpoints);
            final hiddenDotPointIds = {
              for (final cp in pathCheckpoints)
                if (cp.mapPointId != null) cp.mapPointId!,
            };
            final routeLevelDots = widget.interactive
                ? JourneyInteractiveMap._routeLevelDots(
                    route: route,
                    mapWidth: viewportW,
                    mapHeight: canvasH,
                    currentRoutePointId: currentRoutePointId,
                    hiddenPointIds: hiddenDotPointIds,
                  )
                : const <Widget>[];
            final solidSegments = route.edgeSegments(
              mapWidth: viewportW,
              mapHeight: canvasH,
              where: (edge) =>
                  edge.from <= currentRoutePointId &&
                  edge.to <= currentRoutePointId,
            );
            final dashedSegments = route.edgeSegments(
              mapWidth: viewportW,
              mapHeight: canvasH,
              where: (edge) =>
                  edge.from > currentRoutePointId ||
                  edge.to > currentRoutePointId,
            );

            _scheduleFocusScroll(
              checkpoints: visibleCheckpoints,
              positions: absPos,
              viewportHeight: viewportH,
              canvasHeight: canvasH,
            );

            final selected = widget.selectedIndex;
            final hasSelection = widget.interactive &&
                selected != null &&
                selected >= 0 &&
                selected < visibleCheckpoints.length;

            final canvasStack = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.interactive && hasSelection
                  ? () => widget.onSelected(null)
                  : null,
              child: SizedBox(
                width: viewportW,
                height: canvasH,
                child: Stack(
                  children: [
                    _MapBackground(width: viewportW, height: canvasH),
                    if (solidSegments.isNotEmpty || dashedSegments.isNotEmpty)
                      CustomPaint(
                        size: Size(viewportW, canvasH),
                        painter: JourneyPathPainter(
                          nodePositions: const [],
                          pathColor: FtTokens.accent,
                          solidSegments: solidSegments,
                          dashedSegments:
                              widget.interactive ? dashedSegments : const [],
                        ),
                      ),
                    ...routeLevelDots,
                    for (int i = 0; i < n; i++)
                      Positioned(
                        left: absPos[i].dx -
                            _halfNodeWidget(visibleCheckpoints[i]),
                        top: absPos[i].dy -
                            _halfNodeWidget(visibleCheckpoints[i]),
                        child: _nodeWithOptionalStartHalo(
                          checkpoint: visibleCheckpoints[i],
                          isSelected: widget.interactive && selected == i,
                          onTap: widget.interactive
                              ? () => widget.onSelected(i)
                              : () {},
                          pulseAnimation: visibleCheckpoints[i].isCurrent &&
                                  widget.interactive
                              ? _pulse
                              : null,
                          compact: !widget.interactive,
                        ),
                      ),
                    if (hasSelection)
                      _TooltipPosition(
                        anchor: absPos[selected],
                        canvasWidth: viewportW,
                        canvasHeight: canvasH,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: JourneyCheckpointOverlayCard(
                            checkpoint: visibleCheckpoints[selected],
                            onClose: () => widget.onSelected(null),
                            maxWidth: 240,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );

            return Container(
              width: viewportW,
              height: viewportH,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1838), Color(0xFF0F1226)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: FtTokens.accent.withValues(alpha: 0.10),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    if (widget.interactive)
                      // Nested vertical scrollable. Because Flutter's gesture
                      // arena gives a descendant Scrollable priority over an
                      // ancestor Scrollable for drags inside the descendant's
                      // hit area, vertical drags inside the map stay in this
                      // SingleChildScrollView and never reach the surrounding
                      // CustomScrollView — so dragging the map no longer
                      // collapses the SliverPersistentHeader.
                      //
                      // ClampingScrollPhysics keeps the boundary "hard" (no
                      // bounce that would pop the gesture out into the parent)
                      // and matches the pinned-header feel of the rest of the
                      // screen.
                      SingleChildScrollView(
                        controller: _scroll,
                        physics: const ClampingScrollPhysics(),
                        child: canvasStack,
                      )
                    else
                      // Collapsed / mini-preview mode — keep the map static so
                      // the parent CustomScrollView gets all gestures and the
                      // header collapses as expected.
                      IgnorePointer(child: canvasStack),

                    // Pan hint pill — visible only in interactive (expanded) state.
                    if (widget.interactive)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swipe_vertical_rounded,
                                    size: 11, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.journeyPanHint,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.78),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<JourneyMapRoute> _loadRoute() async {
    final raw = await rootBundle.loadString(
      JourneyInteractiveMap._routeAssetPath,
    );
    return JourneyMapRoute.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  int _currentRoutePointId(List<JourneyCheckpoint> checkpoints) {
    final unlocked = checkpoints.where((cp) => cp.isUnlocked).map((cp) =>
        cp.mapUnlockedThroughPointId ?? cp.mapPointId ?? cp.levelNumber ?? 0);

    if (unlocked.isEmpty) return 0;
    return unlocked.reduce(math.max).clamp(0, 100);
  }

  void _scheduleFocusScroll({
    required List<JourneyCheckpoint> checkpoints,
    required List<Offset> positions,
    required double viewportHeight,
    required double canvasHeight,
  }) {
    if (!widget.interactive || checkpoints.isEmpty || positions.isEmpty) {
      return;
    }

    final focusIndex = checkpoints.indexWhere((cp) => cp.isCurrent);
    if (focusIndex < 0) return;

    final focusKey = checkpoints[focusIndex].id;
    if (_lastFocusKey == focusKey) return;
    _lastFocusKey = focusKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;

      final maxScroll = math.max(0.0, canvasHeight - viewportHeight);
      final target = (positions[focusIndex].dy - viewportHeight * 0.62)
          .clamp(0.0, maxScroll);
      _scroll.jumpTo(target);
    });
  }

  /// Type-driven sizing — major title milestones are the largest, quests
  /// the smallest. Current player level is also up-sized (regardless of type).
  static double _nodeSize(JourneyCheckpoint cp) {
    if (cp.levelNumber == 100) return 38.0;
    if (cp.id == 'start') return cp.isCurrent ? 36.0 : 34.0;
    if (cp.isCurrent) return 36.0;
    if (cp.isNext) return 34.0;

    switch (cp.type) {
      case JourneyEventType.titleMilestone:
        return 32.0;
      case JourneyEventType.achievement:
        return 22.0;
      case JourneyEventType.level:
        return 22.0;
      case JourneyEventType.quest:
        return 20.0;
      case JourneyEventType.streak:
      case JourneyEventType.xpMilestone:
        return 22.0;
    }
  }

  static double _halfNodeWidget(JourneyCheckpoint cp) {
    final haloPadding = cp.id == 'start' || cp.levelNumber == 100 ? 12.0 : 0.0;
    return (_nodeSize(cp) + 28 + haloPadding) / 2;
  }

  Widget _nodeWithOptionalStartHalo({
    required JourneyCheckpoint checkpoint,
    required bool isSelected,
    required VoidCallback onTap,
    required Animation<double>? pulseAnimation,
    required bool compact,
  }) {
    final node = JourneyCheckpointNode(
      checkpoint: checkpoint,
      isSelected: isSelected,
      onTap: onTap,
      baseSize: _nodeSize(checkpoint),
      pulseAnimation: pulseAnimation,
      compact: compact,
    );

    if (checkpoint.id == 'start') {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: FtTokens.accent.withValues(alpha: 0.36),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: FtTokens.accent.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.16),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: node,
      );
    }

    if (checkpoint.levelNumber == 100) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.44),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: FtTokens.accent.withValues(alpha: 0.16),
              blurRadius: 18,
              spreadRadius: -2,
            ),
          ],
        ),
        child: node,
      );
    }

    return node;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tooltip positioning helper — places the overlay card next to the anchor
// node and clamps it to the canvas bounds so it never disappears off the edge.
// ─────────────────────────────────────────────────────────────────────────────

class _RouteLevelDot extends StatelessWidget {
  const _RouteLevelDot({required this.isUnlocked});

  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked
        ? const Color(0xFFD4AF37)
        : Colors.white.withValues(alpha: 0.26);

    return Container(
      width: isUnlocked ? 8 : 7,
      height: isUnlocked ? 8 : 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _MapCollisionCircle {
  const _MapCollisionCircle({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;
}

class _MapLoadingShell extends StatelessWidget {
  const _MapLoadingShell({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1838), Color(0xFF0F1226)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: FtTokens.accent,
          ),
        ),
      ),
    );
  }
}

class _TooltipPosition extends StatelessWidget {
  const _TooltipPosition({
    required this.anchor,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.child,
  });

  final Offset anchor;
  final double canvasWidth;
  final double canvasHeight;
  final Widget child;

  static const double _tooltipMaxWidth = 240;
  static const double _tooltipApproxHeight = 130;
  static const double _nodeRadius = 18;
  static const double _gap = 10;
  static const double _edgePadding = 8;

  @override
  Widget build(BuildContext context) {
    final placeRight = anchor.dx < canvasWidth * 0.55;

    double left = placeRight
        ? anchor.dx + _nodeRadius + _gap
        : anchor.dx - _nodeRadius - _gap - _tooltipMaxWidth;
    left = left.clamp(
      _edgePadding,
      canvasWidth - _tooltipMaxWidth - _edgePadding,
    );

    double top = anchor.dy - _tooltipApproxHeight / 2;
    top = top.clamp(
      _edgePadding,
      canvasHeight - _tooltipApproxHeight - _edgePadding,
    );

    return Positioned(
      left: left,
      top: top,
      width: _tooltipMaxWidth,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map background — gradient + radial glows + optional asset.
// ─────────────────────────────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  const _MapBackground({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/ui/journey_map_bg.png',
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/ui/journey_map_bg.jpg',
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _Glow(size: 280, color: FtTokens.accent, alpha: 0.22),
          ),
          Positioned(
            top: height * 0.4,
            right: -80,
            child: _Glow(size: 240, color: FtTokens.active.color, alpha: 0.14),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _Glow(size: 220, color: FtTokens.accent, alpha: 0.12),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.alpha});
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating tooltip overlay — compact, dismissable.
// ─────────────────────────────────────────────────────────────────────────────

class JourneyCheckpointOverlayCard extends StatelessWidget {
  const JourneyCheckpointOverlayCard({
    super.key,
    required this.checkpoint,
    this.onClose,
    this.maxWidth,
  });

  final JourneyCheckpoint checkpoint;
  final VoidCallback? onClose;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cp = checkpoint;
    final color = journeyCheckpointColor(cp);
    final locale = Localizations.localeOf(context).toString();
    final dateStr = cp.unlockedAt != null
        ? DateFormat('d. MMM yyyy', locale).format(cp.unlockedAt!)
        : null;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 6, 11),
      decoration: BoxDecoration(
        color: const Color(0xEE0F1226),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _typeLabelL10n(l10n, cp.type),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (cp.achievementDifficultyLabel != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    cp.achievementDifficultyLabel!,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.92),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              if (cp.isCurrent) ...[
                const SizedBox(width: 5),
                const _CurrentDot(),
                const SizedBox(width: 3),
                Text(
                  l10n.journeyBadgeHere,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.accent,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
              if (!cp.isUnlocked) ...[
                const SizedBox(width: 5),
                const Icon(Icons.lock_outline_rounded,
                    size: 10, color: FtTokens.onSurfaceFaint),
                const SizedBox(width: 2),
                Text(
                  l10n.journeyBadgeLocked,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.onSurfaceMuted,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
              const Spacer(),
              if (onClose != null) _CloseButton(color: color, onTap: onClose!),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withValues(alpha: 0.32)),
                  ),
                  child: Center(child: _emojiOrIcon(cp, color, 18)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cp.isUnlocked
                            ? cp.label
                            : l10n.journeyLevelLabel(cp.levelNumber ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (cp.sublabel != null || dateStr != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _composeSubtitle(cp.sublabel, dateStr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (cp.description != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                cp.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: FtTokens.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(cp.id),
        child: maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: card,
              )
            : card,
      ),
    );
  }

  static String _composeSubtitle(String? sublabel, String? date) {
    if (sublabel != null && date != null) return '$sublabel · $date';
    return sublabel ?? date ?? '';
  }

  Widget _emojiOrIcon(JourneyCheckpoint cp, Color color, double size) {
    if (!cp.isUnlocked) {
      return Icon(Icons.lock_outline_rounded,
          size: size - 2, color: FtTokens.onSurfaceFaint);
    }
    if (cp.emoji != null) {
      return Text(
        cp.emoji!,
        style: TextStyle(fontSize: size, height: 1),
      );
    }
    return Icon(journeyIcon(cp.type), size: size, color: color);
  }
}

String _typeLabelL10n(AppLocalizations l10n, JourneyEventType type) {
  switch (type) {
    // Title breakpoints intentionally show as "LEVEL" (not "TITUL"): the
    // unified UI bucket is Levely; the title is already inside the label
    // ("Level 10 · Pathfinder"), so a separate "TITUL" pill would just
    // duplicate that information.
    case JourneyEventType.titleMilestone:
    case JourneyEventType.level:
      return l10n.journeyTypeLevel;
    case JourneyEventType.achievement:
      return l10n.journeyTypeAchievement;
    case JourneyEventType.quest:
      return l10n.journeyTypeQuest;
    case JourneyEventType.streak:
    case JourneyEventType.xpMilestone:
      return l10n.journeyTypeLevel;
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 14,
            color: FtTokens.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _CurrentDot extends StatelessWidget {
  const _CurrentDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FtTokens.accent,
        boxShadow: [
          BoxShadow(
            color: FtTokens.accent.withValues(alpha: 0.8),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
