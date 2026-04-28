import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_map_route.dart';
import 'journey_shared.dart';

abstract final class _JourneyMapAssets {
  static const route = 'assets/map/journey_map_route.json';
  static const background = 'assets/ui/journey_map_bg.png';
  static const collapsedBackground = 'assets/ui/journey_map_bg_collapsed.png';
  static const fallbackBackground = 'assets/ui/journey_map_bg.jpg';
}

abstract final class _JourneyMapLayout {
  static const imageWidth = 1408.0;
  static const imageHeight = 11712.0;
  static const imageAspectRatio = imageHeight / imageWidth;

  static const collapsedTopPadding = 58.0;
  static const collapsedBottomPadding = 58.0;
  static const collapsedSingleNodeX = 0.50;
  static const collapsedSingleNodeY = 0.50;
  static const collapsedNodeXs = [0.34, 0.66];

  static const sideEventTangentEpsilon = 0.1;
  static const sideEventDistanceFactor = 0.12;
  static const sideEventMinDistance = 38.0;
  static const sideEventMaxDistance = 68.0;
  static const sideEventPreferredMin = 0.65;
  static const sideEventPreferredMax = 1.35;
  static const sideEventDistanceSteps = [0.0, 0.42, 0.84];
  static const sideEventAlongShifts = [0.0, -18.0, 18.0, -34.0, 34.0];
  static const collisionGap = 4.0;

  static const routePointStart = 0;
  static const routePointMinLevel = 1;
  static const routePointMaxLevel = 100;
  static const currentLevelDotSize = 14.0;
  static const unlockedLevelDotSize = 8.0;
  static const lockedLevelDotSize = 7.0;

  static const mapRadius = 20.0;
  static const focusScrollAnchor = 0.62;
}

abstract final class _JourneyMapMotion {
  static const pulseDuration = Duration(milliseconds: 2200);
  static const overlaySwitchDuration = Duration(milliseconds: 180);
  static const overlayScaleBegin = 0.94;
  static const pulseScale = 0.75;
}

abstract final class _JourneyMapNodeSizes {
  static const finalLevel = 38.0;
  static const start = 34.0;
  static const current = 36.0;
  static const next = 34.0;
  static const titleMilestone = 32.0;
  static const achievement = 22.0;
  static const level = 22.0;
  static const quest = 20.0;
  static const fallback = 22.0;

  static const nodeTapPadding = 28.0;
  static const specialHaloPadding = 12.0;
}

abstract final class _JourneyMapCollisionRadii {
  static const specialAnchor = 34.0;
  static const highlightedAnchor = 32.0;
  static const pathAnchor = 30.0;
  static const achievement = 24.0;
  static const fallback = 22.0;
}

abstract final class _JourneyMapLevelDotStyle {
  static const unlockedColor = Color(0xFFD4AF37);
  static const currentTextColor = Color(0xFF20160A);
  static const currentTextSize = 7.0;
  static const currentLetterSpacing = -0.7;
  static const currentBorderWidth = 1.6;
  static const defaultBorderWidth = 0.8;
  static const currentGlowBlur = 9.0;
  static const defaultGlowBlur = 6.0;
  static const currentGlowAlpha = 0.42;
  static const defaultGlowAlpha = 0.32;
  static const pulseBorderWidth = 2.0;
}

abstract final class _JourneyMapShellStyle {
  static const gradientStart = Color(0xFF1A1838);
  static const gradientEnd = Color(0xFF0F1226);
  static const borderAlpha = 0.08;
  static const accentShadowAlpha = 0.10;
  static const accentShadowBlur = 20.0;
  static const accentShadowSpread = -4.0;
  static const shadowOffset = Offset(0, 4);

  static const panHintInset = 10.0;
  static const panHintHorizontalPadding = 8.0;
  static const panHintVerticalPadding = 4.0;
  static const panHintRadius = 8.0;
  static const panHintBgAlpha = 0.40;
  static const panHintBorderAlpha = 0.10;
  static const panHintIconSize = 11.0;
  static const panHintGap = 4.0;
  static const panHintFontSize = 9.0;
  static const panHintTextAlpha = 0.78;
  static const panHintLetterSpacing = 0.4;
}

abstract final class _JourneyMapTooltipStyle {
  static const maxWidth = 240.0;
  static const approxHeight = 130.0;
  static const nodeRadius = 18.0;
  static const gap = 10.0;
  static const edgePadding = 8.0;
  static const flipAtCanvasFraction = 0.55;

  static const cardColor = Color(0xEE0F1226);
  static const cardRadius = 13.0;
  static const padding = EdgeInsets.fromLTRB(11, 9, 6, 11);
  static const iconBoxSize = 34.0;
  static const iconSize = 18.0;
}

abstract final class _JourneyMapBackgroundStyle {
  static const topGlowSize = 280.0;
  static const topGlowAlpha = 0.22;
  static const topGlowOffset = Offset(-60, -80);

  static const middleGlowSize = 240.0;
  static const middleGlowAlpha = 0.14;
  static const middleGlowTopFactor = 0.4;
  static const middleGlowRight = -80.0;

  static const bottomGlowSize = 220.0;
  static const bottomGlowAlpha = 0.12;
  static const bottomGlowLeft = -50.0;
  static const bottomGlowBottom = -60.0;

  static const overlayTopAlpha = 0.20;
  static const overlayBottomAlpha = 0.45;
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

  static double _canvasHeight({
    required double viewportWidth,
    required double viewportHeight,
    required bool interactive,
  }) {
    if (!interactive) return viewportHeight;
    return math.max(
      viewportHeight,
      viewportWidth * _JourneyMapLayout.imageAspectRatio,
    );
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
          Offset(
            viewportWidth * _JourneyMapLayout.collapsedSingleNodeX,
            viewportHeight * _JourneyMapLayout.collapsedSingleNodeY,
          ),
        ];
      }

      final availableHeight = math.max(
        1.0,
        viewportHeight -
            _JourneyMapLayout.collapsedTopPadding -
            _JourneyMapLayout.collapsedBottomPadding,
      );
      final step = availableHeight / (checkpointCount - 1);

      // Collapsed mode is not a compressed full map. It is a clean recent
      // progress preview, so keep the points readable and centered.

      return List<Offset>.generate(
        checkpointCount,
        (index) => Offset(
          viewportWidth *
              _JourneyMapLayout.collapsedNodeXs[
                  index % _JourneyMapLayout.collapsedNodeXs.length],
          _JourneyMapLayout.collapsedTopPadding + (index * step),
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
    final normal = length <= _JourneyMapLayout.sideEventTangentEpsilon
        ? const Offset(1, 0)
        : Offset(-tangent.dy / length, tangent.dx / length);

    final preferredSide = checkpoint.mapSide ?? 1.0;
    final preferredSign = preferredSide >= 0 ? 1.0 : -1.0;
    final preferredMagnitude = preferredSide.abs().clamp(
          _JourneyMapLayout.sideEventPreferredMin,
          _JourneyMapLayout.sideEventPreferredMax,
        );
    final baseDistance = (mapWidth * _JourneyMapLayout.sideEventDistanceFactor)
        .clamp(
          _JourneyMapLayout.sideEventMinDistance,
          _JourneyMapLayout.sideEventMaxDistance,
        )
        .toDouble();
    final along = length <= _JourneyMapLayout.sideEventTangentEpsilon
        ? const Offset(0, -1)
        : Offset(tangent.dx / length, tangent.dy / length);
    final radius = _collisionRadius(checkpoint);

    final candidates = <Offset>[
      for (final sign in [preferredSign, -preferredSign])
        for (final distanceStep in _JourneyMapLayout.sideEventDistanceSteps)
          for (final alongShift in _JourneyMapLayout.sideEventAlongShifts)
            base +
                normal *
                    baseDistance *
                    (preferredMagnitude + distanceStep) *
                    sign +
                along * alongShift,
    ];

    return candidates
        .map((candidate) => _clampMapOffset(
              candidate,
              mapWidth: mapWidth,
              mapHeight: mapHeight,
              inset: radius + _JourneyMapLayout.collisionGap,
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
            inset: radius + _JourneyMapLayout.collisionGap,
          ),
        );
  }

  static bool _collides(
    Offset candidate, {
    required double radius,
    required List<_MapCollisionCircle> occupied,
  }) {
    for (final circle in occupied) {
      final minDistance =
          radius + circle.radius + _JourneyMapLayout.collisionGap;
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
    if (checkpoint.id == 'start' ||
        checkpoint.levelNumber == _JourneyMapLayout.routePointMaxLevel) {
      return _JourneyMapCollisionRadii.specialAnchor;
    }
    if (checkpoint.isCurrent || checkpoint.isNext) {
      return _JourneyMapCollisionRadii.highlightedAnchor;
    }
    if (checkpoint.isPathAnchor) return _JourneyMapCollisionRadii.pathAnchor;
    if (checkpoint.type == JourneyEventType.achievement) {
      return _JourneyMapCollisionRadii.achievement;
    }
    return _JourneyMapCollisionRadii.fallback;
  }

  static List<Widget> _routeLevelDots({
    required JourneyMapRoute route,
    required double mapWidth,
    required double mapHeight,
    required int currentRoutePointId,
    required Set<int> hiddenPointIds,
    required Animation<double> pulseAnimation,
  }) {
    final points = route.points
        .where(
          (point) =>
              point.id >= _JourneyMapLayout.routePointMinLevel &&
              point.id <= _JourneyMapLayout.routePointMaxLevel &&
              !hiddenPointIds.contains(point.id),
        )
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));

    return [
      for (final point in points)
        _routeLevelDotPositioned(
          point: point,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          currentRoutePointId: currentRoutePointId,
          pulseAnimation: pulseAnimation,
        ),
    ];
  }

  static Widget _routeLevelDotPositioned({
    required JourneyMapPoint point,
    required double mapWidth,
    required double mapHeight,
    required int currentRoutePointId,
    required Animation<double> pulseAnimation,
  }) {
    final isUnlocked = point.id <= currentRoutePointId;
    final isCurrent = point.id == currentRoutePointId;
    final center = point.toOffset(mapWidth: mapWidth, mapHeight: mapHeight);
    final size = isCurrent
        ? _JourneyMapLayout.currentLevelDotSize
        : isUnlocked
            ? _JourneyMapLayout.unlockedLevelDotSize
            : _JourneyMapLayout.lockedLevelDotSize;

    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: IgnorePointer(
        child: _RouteLevelDot(
          level: point.id,
          isUnlocked: isUnlocked,
          isCurrent: isCurrent,
          pulseAnimation: isCurrent ? pulseAnimation : null,
        ),
      ),
    );
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
      duration: _JourneyMapMotion.pulseDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant JourneyInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Collapsed mode detaches the inner scrollable. When the user expands the
    // map again, let the normal focus-scroll path run once more so the player
    // lands near their current journey position instead of the top of the map.
    if (!oldWidget.interactive && widget.interactive) {
      _lastFocusKey = null;
    }
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
                    pulseAnimation: _pulse,
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
            final showMapOverlays = widget.interactive;

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
                    _MapBackground(
                      width: viewportW,
                      height: canvasH,
                      collapsed: !widget.interactive,
                    ),
                    if (showMapOverlays &&
                        (solidSegments.isNotEmpty || dashedSegments.isNotEmpty))
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
                    if (showMapOverlays) ...[
                      ...routeLevelDots,
                      for (int i = 0; i < n; i++)
                        _checkpointNodePositioned(
                          checkpoint: visibleCheckpoints[i],
                          position: absPos[i],
                          index: i,
                          selectedIndex: selected,
                          currentRoutePointId: currentRoutePointId,
                          pulseAnimation: _pulse,
                          compact: !widget.interactive,
                        ),
                    ],
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
                            maxWidth: _JourneyMapTooltipStyle.maxWidth,
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
                  colors: [
                    _JourneyMapShellStyle.gradientStart,
                    _JourneyMapShellStyle.gradientEnd,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(_JourneyMapLayout.mapRadius),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: _JourneyMapShellStyle.borderAlpha,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: FtTokens.accent.withValues(
                      alpha: _JourneyMapShellStyle.accentShadowAlpha,
                    ),
                    blurRadius: _JourneyMapShellStyle.accentShadowBlur,
                    spreadRadius: _JourneyMapShellStyle.accentShadowSpread,
                    offset: _JourneyMapShellStyle.shadowOffset,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(_JourneyMapLayout.mapRadius),
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
                        top: _JourneyMapShellStyle.panHintInset,
                        right: _JourneyMapShellStyle.panHintInset,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _JourneyMapShellStyle
                                  .panHintHorizontalPadding,
                              vertical:
                                  _JourneyMapShellStyle.panHintVerticalPadding,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: _JourneyMapShellStyle.panHintBgAlpha,
                              ),
                              borderRadius: BorderRadius.circular(
                                _JourneyMapShellStyle.panHintRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha:
                                      _JourneyMapShellStyle.panHintBorderAlpha,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swipe_vertical_rounded,
                                  size: _JourneyMapShellStyle.panHintIconSize,
                                  color: Colors.white70,
                                ),
                                const SizedBox(
                                  width: _JourneyMapShellStyle.panHintGap,
                                ),
                                Text(
                                  l10n.journeyPanHint,
                                  style: TextStyle(
                                    fontSize:
                                        _JourneyMapShellStyle.panHintFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(
                                      alpha: _JourneyMapShellStyle
                                          .panHintTextAlpha,
                                    ),
                                    letterSpacing: _JourneyMapShellStyle
                                        .panHintLetterSpacing,
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
      _JourneyMapAssets.route,
    );
    return JourneyMapRoute.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  int _currentRoutePointId(List<JourneyCheckpoint> checkpoints) {
    final unlocked = checkpoints.where((cp) => cp.isUnlocked).map((cp) =>
        cp.mapUnlockedThroughPointId ?? cp.mapPointId ?? cp.levelNumber ?? 0);

    if (unlocked.isEmpty) return _JourneyMapLayout.routePointStart;
    return unlocked
        .reduce(math.max)
        .clamp(
          _JourneyMapLayout.routePointStart,
          _JourneyMapLayout.routePointMaxLevel,
        )
        .toInt();
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
      final target = (positions[focusIndex].dy -
              viewportHeight * _JourneyMapLayout.focusScrollAnchor)
          .clamp(0.0, maxScroll);
      _scroll.jumpTo(target);
    });
  }

  /// Type-driven sizing — major title milestones are the largest, quests
  /// the smallest. Current player level is also up-sized (regardless of type).
  Widget _checkpointNodePositioned({
    required JourneyCheckpoint checkpoint,
    required Offset position,
    required int index,
    required int? selectedIndex,
    required int currentRoutePointId,
    required Animation<double> pulseAnimation,
    required bool compact,
  }) {
    final isExactCurrent = _isExactCurrentCheckpoint(
      checkpoint,
      currentRoutePointId: currentRoutePointId,
    );
    final halfNode = _halfNodeWidget(
      checkpoint,
      highlightAsCurrent: isExactCurrent,
    );

    return Positioned(
      left: position.dx - halfNode,
      top: position.dy - halfNode,
      child: _nodeWithOptionalStartHalo(
        checkpoint: checkpoint,
        isSelected: widget.interactive && selectedIndex == index,
        onTap: widget.interactive ? () => widget.onSelected(index) : () {},
        pulseAnimation:
            isExactCurrent && widget.interactive ? pulseAnimation : null,
        compact: compact,
        highlightAsCurrent: isExactCurrent,
      ),
    );
  }

  bool _isExactCurrentCheckpoint(
    JourneyCheckpoint checkpoint, {
    required int currentRoutePointId,
  }) {
    if (!checkpoint.isCurrent) return false;
    final pointId = checkpoint.mapPointId ?? checkpoint.levelNumber;
    return pointId == currentRoutePointId;
  }

  static double _nodeSize(
    JourneyCheckpoint cp, {
    bool? highlightAsCurrent,
  }) {
    final isCurrentVisual = highlightAsCurrent ?? cp.isCurrent;
    if (cp.levelNumber == _JourneyMapLayout.routePointMaxLevel) {
      return _JourneyMapNodeSizes.finalLevel;
    }
    if (cp.id == 'start') {
      return isCurrentVisual
          ? _JourneyMapNodeSizes.current
          : _JourneyMapNodeSizes.start;
    }
    if (isCurrentVisual) return _JourneyMapNodeSizes.current;
    if (cp.isNext) return _JourneyMapNodeSizes.next;

    switch (cp.type) {
      case JourneyEventType.titleMilestone:
        return _JourneyMapNodeSizes.titleMilestone;
      case JourneyEventType.achievement:
        return _JourneyMapNodeSizes.achievement;
      case JourneyEventType.level:
        return _JourneyMapNodeSizes.level;
      case JourneyEventType.quest:
        return _JourneyMapNodeSizes.quest;
      case JourneyEventType.streak:
      case JourneyEventType.xpMilestone:
        return _JourneyMapNodeSizes.fallback;
    }
  }

  static double _halfNodeWidget(
    JourneyCheckpoint cp, {
    bool? highlightAsCurrent,
  }) {
    final haloPadding = cp.id == 'start' ||
            cp.levelNumber == _JourneyMapLayout.routePointMaxLevel
        ? _JourneyMapNodeSizes.specialHaloPadding
        : 0.0;
    return (_nodeSize(cp, highlightAsCurrent: highlightAsCurrent) +
            _JourneyMapNodeSizes.nodeTapPadding +
            haloPadding) /
        2;
  }

  Widget _nodeWithOptionalStartHalo({
    required JourneyCheckpoint checkpoint,
    required bool isSelected,
    required VoidCallback onTap,
    required Animation<double>? pulseAnimation,
    required bool compact,
    required bool highlightAsCurrent,
  }) {
    final node = JourneyCheckpointNode(
      checkpoint: checkpoint,
      isSelected: isSelected,
      onTap: onTap,
      baseSize: _nodeSize(checkpoint, highlightAsCurrent: highlightAsCurrent),
      pulseAnimation: pulseAnimation,
      compact: compact,
      highlightAsCurrent: highlightAsCurrent,
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

    if (checkpoint.levelNumber == _JourneyMapLayout.routePointMaxLevel) {
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
  const _RouteLevelDot({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    this.pulseAnimation,
  });

  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final Animation<double>? pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked
        ? _JourneyMapLevelDotStyle.unlockedColor
        : Colors.white.withValues(alpha: 0.26);
    final size = isCurrent
        ? _JourneyMapLayout.currentLevelDotSize
        : isUnlocked
            ? _JourneyMapLayout.unlockedLevelDotSize
            : _JourneyMapLayout.lockedLevelDotSize;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (pulseAnimation != null)
            AnimatedBuilder(
              animation: pulseAnimation!,
              builder: (_, __) {
                final v = pulseAnimation!.value;
                return Transform.scale(
                  scale: 1.0 + v * _JourneyMapMotion.pulseScale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: (1 - v) * 0.62),
                        width: _JourneyMapLevelDotStyle.pulseBorderWidth,
                      ),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCurrent
                  ? const RadialGradient(
                      colors: [Color(0xFFFFD980), Color(0xFFE5A833)],
                      radius: 0.85,
                    )
                  : null,
              color: isCurrent ? null : color,
              border: Border.all(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: isCurrent ? 0.70 : 0.34)
                    : Colors.white.withValues(alpha: 0.12),
                width: isCurrent
                    ? _JourneyMapLevelDotStyle.currentBorderWidth
                    : _JourneyMapLevelDotStyle.defaultBorderWidth,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(
                          alpha: isCurrent
                              ? _JourneyMapLevelDotStyle.currentGlowAlpha
                              : _JourneyMapLevelDotStyle.defaultGlowAlpha,
                        ),
                        blurRadius: isCurrent
                            ? _JourneyMapLevelDotStyle.currentGlowBlur
                            : _JourneyMapLevelDotStyle.defaultGlowBlur,
                        spreadRadius: isCurrent ? 0 : -1,
                      ),
                    ]
                  : null,
            ),
            child: isCurrent
                ? Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        fontSize: _JourneyMapLevelDotStyle.currentTextSize,
                        fontWeight: FontWeight.w900,
                        color: _JourneyMapLevelDotStyle.currentTextColor,
                        letterSpacing:
                            _JourneyMapLevelDotStyle.currentLetterSpacing,
                        height: 1,
                      ),
                    ),
                  )
                : null,
          ),
        ],
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
          colors: [
            _JourneyMapShellStyle.gradientStart,
            _JourneyMapShellStyle.gradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(_JourneyMapLayout.mapRadius),
        border: Border.all(
          color:
              Colors.white.withValues(alpha: _JourneyMapShellStyle.borderAlpha),
        ),
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

  @override
  Widget build(BuildContext context) {
    final placeRight =
        anchor.dx < canvasWidth * _JourneyMapTooltipStyle.flipAtCanvasFraction;

    double left = placeRight
        ? anchor.dx +
            _JourneyMapTooltipStyle.nodeRadius +
            _JourneyMapTooltipStyle.gap
        : anchor.dx -
            _JourneyMapTooltipStyle.nodeRadius -
            _JourneyMapTooltipStyle.gap -
            _JourneyMapTooltipStyle.maxWidth;
    left = left.clamp(
      _JourneyMapTooltipStyle.edgePadding,
      canvasWidth -
          _JourneyMapTooltipStyle.maxWidth -
          _JourneyMapTooltipStyle.edgePadding,
    );

    double top = anchor.dy - _JourneyMapTooltipStyle.approxHeight / 2;
    top = top.clamp(
      _JourneyMapTooltipStyle.edgePadding,
      canvasHeight -
          _JourneyMapTooltipStyle.approxHeight -
          _JourneyMapTooltipStyle.edgePadding,
    );

    return Positioned(
      left: left,
      top: top,
      width: _JourneyMapTooltipStyle.maxWidth,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map background — gradient + radial glows + optional asset.
// ─────────────────────────────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  const _MapBackground({
    required this.width,
    required this.height,
    this.collapsed = false,
  });

  final double width;
  final double height;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            collapsed
                ? _JourneyMapAssets.collapsedBackground
                : _JourneyMapAssets.background,
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Image.asset(
              _JourneyMapAssets.fallbackBackground,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: _JourneyMapBackgroundStyle.topGlowOffset.dy,
            left: _JourneyMapBackgroundStyle.topGlowOffset.dx,
            child: _Glow(
              size: _JourneyMapBackgroundStyle.topGlowSize,
              color: FtTokens.accent,
              alpha: _JourneyMapBackgroundStyle.topGlowAlpha,
            ),
          ),
          Positioned(
            top: height * _JourneyMapBackgroundStyle.middleGlowTopFactor,
            right: _JourneyMapBackgroundStyle.middleGlowRight,
            child: _Glow(
              size: _JourneyMapBackgroundStyle.middleGlowSize,
              color: FtTokens.active.color,
              alpha: _JourneyMapBackgroundStyle.middleGlowAlpha,
            ),
          ),
          Positioned(
            bottom: _JourneyMapBackgroundStyle.bottomGlowBottom,
            left: _JourneyMapBackgroundStyle.bottomGlowLeft,
            child: _Glow(
              size: _JourneyMapBackgroundStyle.bottomGlowSize,
              color: FtTokens.accent,
              alpha: _JourneyMapBackgroundStyle.bottomGlowAlpha,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(
                    alpha: _JourneyMapBackgroundStyle.overlayTopAlpha,
                  ),
                  Colors.black.withValues(
                    alpha: _JourneyMapBackgroundStyle.overlayBottomAlpha,
                  ),
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
      padding: _JourneyMapTooltipStyle.padding,
      decoration: BoxDecoration(
        color: _JourneyMapTooltipStyle.cardColor,
        borderRadius: BorderRadius.circular(_JourneyMapTooltipStyle.cardRadius),
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
                  width: _JourneyMapTooltipStyle.iconBoxSize,
                  height: _JourneyMapTooltipStyle.iconBoxSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withValues(alpha: 0.32)),
                  ),
                  child: Center(
                    child: _emojiOrIcon(
                      cp,
                      color,
                      _JourneyMapTooltipStyle.iconSize,
                    ),
                  ),
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
      duration: _JourneyMapMotion.overlaySwitchDuration,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: _JourneyMapMotion.overlayScaleBegin,
            end: 1.0,
          ).animate(anim),
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
