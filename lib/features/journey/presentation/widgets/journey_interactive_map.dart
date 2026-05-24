import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_checkpoint_overlay_card.dart';
import 'journey_map_chrome.dart';
import 'journey_map_geometry.dart';
import 'journey_map_layout.dart';
import 'journey_map_route.dart';
import 'journey_primitives.dart';
import 'journey_route_level_dot.dart';

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
      duration: JourneyMapMotion.pulseDuration,
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
          return JourneyMapLoadingShell(height: widget.height);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportW = constraints.maxWidth;
            final viewportH = widget.height;

            final visibleCheckpoints = widget.interactive
                ? widget.checkpoints
                : journeyMapCollapsedPreviewCheckpoints(widget.checkpoints);

            final n = visibleCheckpoints.length;

            final canvasH = journeyMapCanvasHeight(
              viewportWidth: viewportW,
              viewportHeight: viewportH,
              interactive: widget.interactive,
            );

            final absPos = journeyMapNodePositions(
              checkpoints: visibleCheckpoints,
              route: route,
              viewportWidth: viewportW,
              viewportHeight: viewportH,
              canvasHeight: canvasH,
              interactive: widget.interactive,
            );
            final pathCheckpoints = visibleCheckpoints
                .where((cp) => cp.isPathAnchor) // lint-ignore: widget-no-logic — picks anchor VOs (display-state flag) to drive route-line rendering + hidden-dot set
                .toList(growable: false);
            final currentRoutePointId = _currentRoutePointId(pathCheckpoints);
            final hiddenDotPointIds = {
              for (final cp in pathCheckpoints)
                if (cp.mapPointId != null) cp.mapPointId!,
            };
            final routeLevelDots = widget.interactive
                ? _buildRouteLevelDots(
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
                    JourneyMapBackground(
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
                          pathColor: Tokens.accent,
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
                          compact: !widget.interactive,
                        ),
                    ],
                    if (hasSelection)
                      JourneyMapTooltipPosition(
                        anchor: absPos[selected],
                        canvasWidth: viewportW,
                        canvasHeight: canvasH,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: JourneyCheckpointOverlayCard(
                            checkpoint: visibleCheckpoints[selected],
                            onClose: () => widget.onSelected(null),
                            maxWidth: JourneyMapTooltipStyle.maxWidth,
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
                    JourneyMapShellStyle.gradientStart,
                    JourneyMapShellStyle.gradientEnd,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(JourneyMapLayout.mapRadius),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: JourneyMapShellStyle.borderAlpha,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Tokens.accent.withValues(
                      alpha: JourneyMapShellStyle.accentShadowAlpha,
                    ),
                    blurRadius: JourneyMapShellStyle.accentShadowBlur,
                    spreadRadius: JourneyMapShellStyle.accentShadowSpread,
                    offset: JourneyMapShellStyle.shadowOffset,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(JourneyMapLayout.mapRadius),
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
                        top: JourneyMapShellStyle.panHintInset,
                        right: JourneyMapShellStyle.panHintInset,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: JourneyMapShellStyle
                                  .panHintHorizontalPadding,
                              vertical:
                                  JourneyMapShellStyle.panHintVerticalPadding,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: JourneyMapShellStyle.panHintBgAlpha,
                              ),
                              borderRadius: BorderRadius.circular(
                                JourneyMapShellStyle.panHintRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha:
                                      JourneyMapShellStyle.panHintBorderAlpha,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swipe_vertical_rounded,
                                  size: JourneyMapShellStyle.panHintIconSize,
                                  color: Colors.white70,
                                ),
                                const SizedBox(
                                  width: JourneyMapShellStyle.panHintGap,
                                ),
                                Text(
                                  l10n.journeyPanHint,
                                  style: TextStyle(
                                    fontSize:
                                        JourneyMapShellStyle.panHintFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(
                                      alpha: JourneyMapShellStyle
                                          .panHintTextAlpha,
                                    ),
                                    letterSpacing: JourneyMapShellStyle
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
    final raw = await rootBundle.loadString(JourneyMapAssets.route);
    return JourneyMapRoute.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  int _currentRoutePointId(List<JourneyCheckpoint> checkpoints) {
    final unlocked = checkpoints.where((cp) => cp.isUnlocked).map((cp) => // lint-ignore: widget-no-logic — reduces over pre-built VO display-state flag to find highest unlocked route point for path-line rendering
        cp.mapUnlockedThroughPointId ?? cp.mapPointId ?? cp.levelNumber ?? 0);

    if (unlocked.isEmpty) return JourneyMapLayout.routePointStart;
    return unlocked
        .reduce(math.max)
        .clamp(
          JourneyMapLayout.routePointStart,
          JourneyMapLayout.routePointMaxLevel,
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

    final focusIndex = checkpoints.indexWhere((cp) => cp.isCurrent); // lint-ignore: widget-no-logic — finds rendered-list index for post-frame scroll positioning, not domain derivation
    if (focusIndex < 0) return;

    final focusKey = checkpoints[focusIndex].id;
    if (_lastFocusKey == focusKey) return;
    _lastFocusKey = focusKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;

      final maxScroll = math.max(0.0, canvasHeight - viewportHeight);
      final target = (positions[focusIndex].dy -
              viewportHeight * JourneyMapLayout.focusScrollAnchor)
          .clamp(0.0, maxScroll);
      _scroll.jumpTo(target);
    });
  }

  List<Widget> _buildRouteLevelDots({
    required JourneyMapRoute route,
    required double mapWidth,
    required double mapHeight,
    required int currentRoutePointId,
    required Set<int> hiddenPointIds,
  }) {
    final points = route.points
        .where( // lint-ignore: widget-no-logic — filters route JSON points (asset), not a domain collection
          (point) =>
              point.id >= JourneyMapLayout.routePointMinLevel &&
              point.id <= JourneyMapLayout.routePointMaxLevel &&
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
        ),
    ];
  }

  Widget _routeLevelDotPositioned({
    required JourneyMapPoint point,
    required double mapWidth,
    required double mapHeight,
    required int currentRoutePointId,
  }) {
    final isUnlocked = point.id <= currentRoutePointId;
    final isCurrent = point.id == currentRoutePointId;
    final center = point.toOffset(mapWidth: mapWidth, mapHeight: mapHeight);
    final size = isCurrent
        ? JourneyMapLayout.currentLevelDotSize
        : isUnlocked
            ? JourneyMapLayout.unlockedLevelDotSize
            : JourneyMapLayout.lockedLevelDotSize;

    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: IgnorePointer(
        child: JourneyRouteLevelDot(
          level: point.id,
          isUnlocked: isUnlocked,
          isCurrent: isCurrent,
          pulseAnimation: isCurrent ? _pulse : null,
        ),
      ),
    );
  }

  /// Type-driven sizing — major title milestones are the largest, quests
  /// the smallest. Current player level is also up-sized (regardless of type).
  Widget _checkpointNodePositioned({
    required JourneyCheckpoint checkpoint,
    required Offset position,
    required int index,
    required int? selectedIndex,
    required int currentRoutePointId,
    required bool compact,
  }) {
    final isExactCurrent = _isExactCurrentCheckpoint(
      checkpoint,
      currentRoutePointId: currentRoutePointId,
    );
    final halfNode = journeyMapHalfNodeWidget(
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
            isExactCurrent && widget.interactive ? _pulse : null,
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
      baseSize: journeyMapNodeSize(checkpoint,
          highlightAsCurrent: highlightAsCurrent),
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
            color: Tokens.accent.withValues(alpha: 0.36),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Tokens.accent.withValues(alpha: 0.18),
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

    if (checkpoint.levelNumber == JourneyMapLayout.routePointMaxLevel) {
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
              color: Tokens.accent.withValues(alpha: 0.16),
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
