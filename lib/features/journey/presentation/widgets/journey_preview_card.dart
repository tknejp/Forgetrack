import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/presentation/widgets/progression_primitives.dart';
import '../../domain/journey_models.dart';
import '../hero_journey_map_screen.dart';
import 'journey_adapter.dart';
import 'journey_primitives.dart';

abstract final class _JourneyPreviewAssets {
  static const background = 'assets/ui/journey_map_preview_bg.png';
}

abstract final class _JourneyPreviewLayout {
  static const mapHeight = 92.0;
  static const visiblePointCount = 5;
  static const viewportSidePadding = 52.0;
  static const pathNodeGap = 8.0;
  static const mapVerticalCenter = 0.50;
  static const mapWaveAmplitude = 0.16;
}

class JourneyPreviewCard extends StatelessWidget {
  const JourneyPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionEngineProvider>();
    final map = JourneyAdapter.buildMilestoneMap(progression, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgSectionHead(
          label: l10n.journeyTitle,
          accent: Tokens.accent,
        ),
        const SizedBox(height: Tokens.spaceSm),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HeroJourneyMapScreen()),
            ),
            splashColor: Tokens.accent.withValues(alpha: 0.18),
            highlightColor: Tokens.accent.withValues(alpha: 0.08),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF16152F), Color(0xFF0D1021)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Tokens.accent.withValues(alpha: 0.24),
                ),
                boxShadow: [
                  BoxShadow(
                    // Phase 0.2 invariant: blurRadius < 12 on cards in
                    // a scrollable feed (first-paint cost on viewport entry).
                    color: Tokens.accent.withValues(alpha: 0.10),
                    blurRadius: Tokens.glowSm,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _JourneyPreviewLayout.mapHeight,
                    child: _MiniMap(checkpoints: map),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: _SummaryRow(preview: map),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.checkpoints});

  final List<JourneyCheckpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) {
      return const _MiniMapEmpty();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final ordered = checkpoints
            .where((checkpoint) => checkpoint.isPathAnchor) // lint-ignore: widget-no-logic — preview slices the pre-built JourneyCheckpoint list
            .toList(growable: false)
          ..sort(
            (a, b) => _journeyProgress(a).compareTo(_journeyProgress(b)),
          );
        final pointSpacing = _pointSpacing(width);
        final stripWidth = math.max(
          width,
          _JourneyPreviewLayout.viewportSidePadding * 2 +
              pointSpacing * math.max(0, ordered.length - 1),
        );
        final offset = _viewportOffset(
          ordered,
          pointSpacing: pointSpacing,
          stripWidth: stripWidth,
          viewportWidth: width,
        );

        final positions = [
          for (var i = 0; i < ordered.length; i++)
            _positionFor(
              index: i,
              pointCount: ordered.length,
              pointSpacing: pointSpacing,
              offset: offset,
              height: height,
            ),
        ];
        final pathSegments = _pathSegments(ordered, positions);

        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -offset,
                top: 0,
                width: stripWidth,
                height: height,
                child: Image.asset(
                  _JourneyPreviewAssets.background,
                  fit: BoxFit.fill,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              CustomPaint(
                size: Size(width, height),
                painter: JourneyPathPainter(
                  nodePositions: const [],
                  pathColor: Tokens.accent,
                  solidSegments: pathSegments,
                ),
              ),
              for (var i = 0; i < ordered.length; i++)
                if (_isNodeVisible(ordered[i], positions[i], width))
                  Positioned(
                    left: positions[i].dx - _halfNode(ordered[i]),
                    top: positions[i].dy - _halfNode(ordered[i]),
                    child: IgnorePointer(
                      child: JourneyCheckpointNode(
                        checkpoint: ordered[i],
                        isSelected: false,
                        onTap: () {},
                        baseSize: _baseSize(ordered[i]),
                        compact: true,
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  static Offset _positionFor({
    required int index,
    required int pointCount,
    required double pointSpacing,
    required double offset,
    required double height,
  }) {
    final x = _JourneyPreviewLayout.viewportSidePadding +
        index * pointSpacing -
        offset;
    final progress = index / math.max(1, pointCount - 1);
    final y = height * _JourneyPreviewLayout.mapVerticalCenter +
        math.sin(progress * math.pi * 7.0) *
            height *
            _JourneyPreviewLayout.mapWaveAmplitude;
    return Offset(x, y);
  }

  static double _pointSpacing(double viewportWidth) {
    final available =
        viewportWidth - _JourneyPreviewLayout.viewportSidePadding * 2;
    return math.max(
      1.0,
      available / (_JourneyPreviewLayout.visiblePointCount - 1),
    );
  }

  static List<List<Offset>> _pathSegments(
    List<JourneyCheckpoint> checkpoints,
    List<Offset> positions,
  ) {
    final segments = <List<Offset>>[];

    for (var i = 0; i < positions.length - 1; i++) {
      final start = positions[i];
      final end = positions[i + 1];
      final delta = end - start;
      final distance = delta.distance;
      if (distance <= 0) continue;

      final direction = delta / distance;
      final startGap =
          _baseSize(checkpoints[i]) / 2 + _JourneyPreviewLayout.pathNodeGap;
      final endGap =
          _baseSize(checkpoints[i + 1]) / 2 + _JourneyPreviewLayout.pathNodeGap;

      if (distance <= startGap + endGap) continue;

      segments.add([
        start + direction * startGap,
        end - direction * endGap,
      ]);
    }

    return segments;
  }

  static double _viewportOffset(
    List<JourneyCheckpoint> ordered, {
    required double pointSpacing,
    required double stripWidth,
    required double viewportWidth,
  }) {
    final currentIndex = _focusIndex(ordered);
    final scrollAfterIndex = _JourneyPreviewLayout.visiblePointCount - 2;
    final rawOffset = math.max(
      0.0,
      (currentIndex - scrollAfterIndex) * pointSpacing,
    );
    final maxOffset = math.max(0.0, stripWidth - viewportWidth);
    return rawOffset.clamp(0.0, maxOffset).toDouble();
  }

  static int _focusIndex(List<JourneyCheckpoint> ordered) {
    final currentIndex = ordered.indexWhere((cp) => cp.isCurrent); // lint-ignore: widget-no-logic — focus-index over pre-built JourneyCheckpoint list
    if (currentIndex >= 0) return currentIndex;

    final unlockedIndex = ordered.lastIndexWhere((cp) => cp.isUnlocked);
    if (unlockedIndex >= 0) return unlockedIndex;

    return 0;
  }

  static double _journeyProgress(JourneyCheckpoint checkpoint) {
    final mapProgress = checkpoint.mapProgress;
    if (mapProgress == null) {
      return checkpoint.isUnlocked ? 1 : 0;
    }
    return (1 - mapProgress).clamp(0.0, 1.0).toDouble();
  }

  static double _baseSize(JourneyCheckpoint checkpoint) {
    if (checkpoint.isCurrent) return 24;
    if (checkpoint.isMajorMilestone) return 22;
    if (checkpoint.type == JourneyEventType.achievement) return 18;
    return 16;
  }

  static double _halfNode(JourneyCheckpoint checkpoint) {
    return (_baseSize(checkpoint) + 14) / 2;
  }

  static bool _isNodeVisible(
    JourneyCheckpoint checkpoint,
    Offset position,
    double viewportWidth,
  ) {
    final halfNode = _halfNode(checkpoint);
    return position.dx + halfNode >= 0 &&
        position.dx - halfNode <= viewportWidth;
  }
}

class _MiniMapEmpty extends StatelessWidget {
  const _MiniMapEmpty();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_JourneyPreviewAssets.background, fit: BoxFit.cover),
        ColoredBox(color: Colors.black.withValues(alpha: 0.34)),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              context.l10n.journeyMiniMapEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Tokens.fontSizeCaption,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.preview});

  final List<JourneyCheckpoint> preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ordered = preview
        .where((checkpoint) => checkpoint.isPathAnchor) // lint-ignore: widget-no-logic — mini-map slices the pre-built JourneyCheckpoint list
        .toList(growable: false)
      ..sort(
        (a, b) => _MiniMap._journeyProgress(a).compareTo(
          _MiniMap._journeyProgress(b),
        ),
      );

    final lastMilestone = ordered.lastWhere(
      (checkpoint) => checkpoint.isUnlocked,
      orElse: () => const JourneyCheckpoint(
        id: '_none',
        type: JourneyEventType.level,
        label: '-',
        isUnlocked: false,
      ),
    );
    final nextLocked = ordered.firstWhere( // lint-ignore: widget-no-logic — first-locked anchor on pre-built JourneyCheckpoint list
      (checkpoint) => !checkpoint.isUnlocked,
      orElse: () => const JourneyCheckpoint(
        id: '_none',
        type: JourneyEventType.level,
        label: '-',
        isUnlocked: false,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryItem(
            icon: Icons.history_rounded,
            label: l10n.journeyLastMilestone,
            value: _summaryValue(context, lastMilestone),
            color: Tokens.active.color,
          ),
        ),
        const SizedBox(width: Tokens.spaceMd),
        Expanded(
          child: _SummaryItem(
            icon: Icons.lock_outline_rounded,
            label: l10n.journeyNextGoal,
            value: _summaryValue(context, nextLocked),
            color: Tokens.calories.color,
          ),
        ),
      ],
    );
  }

  static String _summaryValue(
    BuildContext context,
    JourneyCheckpoint checkpoint,
  ) {
    if (checkpoint.id == '_none') return '-';
    final level = checkpoint.levelNumber;
    if (level != null) return context.l10n.journeyLevelLabel(level);
    return checkpoint.label;
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: Tokens.spaceXs),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.85),
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: Tokens.fontSizeSmall,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}
