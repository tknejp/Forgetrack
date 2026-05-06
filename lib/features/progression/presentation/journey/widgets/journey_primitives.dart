import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/journey_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Type → colour / icon / label helpers (shared by preview and full map)
// ─────────────────────────────────────────────────────────────────────────────

/// Primary colour for a journey event type. Distinct enough that achievements
/// (warm violet) don't blend into quests (green) or level milestones (gold).
Color journeyColor(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.titleMilestone:
      // Major title milestones use the gold→purple "title" tone — they're
      // clearly distinct from minor level checkpoints.
      return const Color(0xFFD4AF37); // rich gold; gradient does the rest.
    case JourneyEventType.level:
      return Tokens.calories.color; // amber/gold — minor milestone tone
    case JourneyEventType.achievement:
      return const Color(0xFFC77DFF); // warm violet
    case JourneyEventType.quest:
      return Tokens.steps.color; // green
    case JourneyEventType.streak:
      return Tokens.calories.color;
    case JourneyEventType.xpMilestone:
      return Tokens.accent;
  }
}

/// Event colour with optional item-specific override, e.g. achievement rarity.
Color journeyCheckpointColor(JourneyCheckpoint checkpoint) {
  final override = checkpoint.accentColorValue;
  if (override != null) return Color(override);
  return journeyColor(checkpoint.type);
}

/// Foreground colour drawn on top of the filled node circle.
Color journeyFgColor(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.titleMilestone:
    case JourneyEventType.level:
    case JourneyEventType.achievement:
    case JourneyEventType.quest:
    case JourneyEventType.streak:
      return const Color(0xFF0D0F1C);
    case JourneyEventType.xpMilestone:
      return Colors.white;
  }
}

/// Material icon fallback when a checkpoint doesn't carry an emoji yet.
IconData journeyIcon(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.titleMilestone:
      return Icons.workspace_premium_rounded;
    case JourneyEventType.level:
      return Icons.arrow_upward_rounded;
    case JourneyEventType.achievement:
      return Icons.shield_moon_rounded;
    case JourneyEventType.quest:
      return Icons.flag_rounded;
    case JourneyEventType.streak:
      return Icons.local_fire_department_rounded;
    case JourneyEventType.xpMilestone:
      return Icons.star_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkpoint node
// ─────────────────────────────────────────────────────────────────────────────

/// Interactive circle representing a single journey milestone. Visual
/// hierarchy is type-driven: title milestones are largest (gold + purple
/// double ring), achievements medium (violet), quests small (green), minor
/// level checkpoints sit between minor and achievement.
class JourneyCheckpointNode extends StatelessWidget {
  const JourneyCheckpointNode({
    super.key,
    required this.checkpoint,
    required this.isSelected,
    required this.onTap,
    required this.baseSize,
    this.pulseAnimation,
    this.compact = false,
    this.highlightAsCurrent,
  });

  final JourneyCheckpoint checkpoint;
  final bool isSelected;
  final VoidCallback onTap;
  final double baseSize;
  final Animation<double>? pulseAnimation;
  final bool compact;
  final bool? highlightAsCurrent;

  @override
  Widget build(BuildContext context) {
    final cp = checkpoint;
    final color = journeyCheckpointColor(cp);
    final isMajor = cp.isMajorMilestone;
    final isCurrentVisual = highlightAsCurrent ?? cp.isCurrent;
    final nodeSize = isSelected ? baseSize + 3.0 : baseSize;
    final pad = compact ? 14.0 : 28.0;
    final totalSize = baseSize + pad;

    final body = SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (pulseAnimation != null)
            AnimatedBuilder(
              animation: pulseAnimation!,
              builder: (_, __) {
                final v = pulseAnimation!.value;
                return Transform.scale(
                  scale: 1.0 + v * 0.75,
                  child: Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: (1 - v) * 0.62),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Major-milestone outer ring (purple) — adds the "title" accent
          // around the gold core. Drawn before the selection ring so the
          // selection can highlight on top.
          if (((isMajor && cp.isUnlocked) || cp.isNext) && !compact)
            Container(
              width: nodeSize + (cp.isNext ? 14 : 10),
              height: nodeSize + (cp.isNext ? 14 : 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (cp.isNext ? color : Tokens.accent)
                      .withValues(alpha: cp.isNext ? 0.70 : 0.55),
                  width: cp.isNext ? 2.0 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (cp.isNext ? color : Tokens.accent)
                        .withValues(alpha: cp.isNext ? 0.34 : 0.30),
                    blurRadius: cp.isNext ? 18 : 14,
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),

          if (isSelected)
            Container(
              width: nodeSize + 6,
              height: nodeSize + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.62),
                  width: 2,
                ),
              ),
            ),

          _JourneyNodeCore(
            animated: !compact,
            nodeSize: nodeSize,
            checkpoint: cp,
            color: color,
            isMajor: isMajor,
            isCurrentVisual: isCurrentVisual,
            child: Center(child: _buildContent(cp, nodeSize)),
          ),

          // Tiny level-number badge for unlocked major milestones — emoji is
          // the primary visual; the level number sits as a small chip.
          if (isMajor && cp.isUnlocked && cp.levelNumber != null && !compact)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F1C),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Tokens.accent.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  '${cp.levelNumber}',
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeTiny,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (compact) return body;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }

  Widget _buildContent(JourneyCheckpoint cp, double nodeSize) {
    if (!cp.isUnlocked) {
      return Icon(
        Icons.lock_outline_rounded,
        size: nodeSize * 0.42,
        color: Tokens.onSurfaceFaint,
      );
    }

    // The static origin is a named story node, not a tiny numeric level.
    if (cp.id == 'start' && cp.emoji != null) {
      return Text(
        cp.emoji!,
        style: TextStyle(
          fontSize: nodeSize * 0.52,
          height: 1,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Major title milestone → emoji is the dominant visual.
    if (cp.isMajorMilestone && cp.emoji != null) {
      return Text(
        cp.emoji!,
        style: TextStyle(
          fontSize: nodeSize * 0.50,
          height: 1,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Minor level milestone → level number is the dominant visual.
    if (cp.isMinorMilestone && cp.levelNumber != null) {
      return Text(
        '${cp.levelNumber}',
        style: TextStyle(
          fontSize: nodeSize * 0.36,
          fontWeight: FontWeight.w900,
          color: journeyFgColor(cp.type),
          letterSpacing: -0.5,
          height: 1,
        ),
      );
    }

    // Achievement → emoji.
    if (cp.type == JourneyEventType.achievement && cp.emoji != null) {
      return Text(
        cp.emoji!,
        style: TextStyle(fontSize: nodeSize * 0.50, height: 1),
        textAlign: TextAlign.center,
      );
    }

    // Quest / fallback → material icon.
    return Icon(
      journeyIcon(cp.type),
      size: nodeSize * 0.46,
      color: journeyFgColor(cp.type),
    );
  }
}

class _JourneyNodeCore extends StatelessWidget {
  const _JourneyNodeCore({
    required this.animated,
    required this.nodeSize,
    required this.checkpoint,
    required this.color,
    required this.isMajor,
    required this.isCurrentVisual,
    required this.child,
  });

  final bool animated;
  final double nodeSize;
  final JourneyCheckpoint checkpoint;
  final Color color;
  final bool isMajor;
  final bool isCurrentVisual;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      gradient: checkpoint.isUnlocked
          ? RadialGradient(
              colors: isMajor
                  ? [
                      const Color(0xFFFFD980),
                      const Color(0xFFE5A833),
                    ]
                  : [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.65),
                    ],
              radius: 0.85,
            )
          : null,
      color:
          checkpoint.isUnlocked ? null : Colors.white.withValues(alpha: 0.07),
      border: Border.all(
        color: checkpoint.isUnlocked
            ? color.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.15),
        width: isCurrentVisual || isMajor ? 2.0 : 1.5,
      ),
      boxShadow: checkpoint.isUnlocked
          ? [
              BoxShadow(
                color: color.withValues(
                  alpha: isCurrentVisual || isMajor ? 0.55 : 0.28,
                ),
                blurRadius: isCurrentVisual || isMajor ? 18 : 8,
                spreadRadius: isCurrentVisual || isMajor ? 1 : 0,
              ),
            ]
          : null,
    );

    if (!animated) {
      return Container(
        width: nodeSize,
        height: nodeSize,
        decoration: decoration,
        child: child,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: nodeSize,
      height: nodeSize,
      decoration: decoration,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Path painter — draws ONLY the path, not the rest of the UI.
// ─────────────────────────────────────────────────────────────────────────────

class JourneyPathPainter extends CustomPainter {
  const JourneyPathPainter({
    required this.nodePositions,
    required this.pathColor,
    this.dashedHeadCount = 0,
    this.solidSegments,
    this.dashedSegments,
  });

  final List<Offset> nodePositions;
  final Color pathColor;
  final List<List<Offset>>? solidSegments;
  final List<List<Offset>>? dashedSegments;

  /// Number of leading SEGMENTS drawn dashed (representing future / locked
  /// nodes anchored at the start of the path). The dashed run connects
  /// `nodePositions[0..dashedHeadCount]`; from `dashedHeadCount` onward the
  /// path is drawn solid.
  final int dashedHeadCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (solidSegments != null || dashedSegments != null) {
      _paintSegments(canvas, size);
      return;
    }

    if (nodePositions.length < 2) return;

    final dashedHead = dashedHeadCount.clamp(0, nodePositions.length - 1);

    if (dashedHead >= 1) {
      final dashedPts =
          nodePositions.take(dashedHead + 1).toList(growable: false);
      if (dashedPts.length >= 2) {
        _drawDashed(
          canvas,
          _buildSmoothPath(dashedPts),
          Paint()
            ..color = pathColor.withValues(alpha: 0.30)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    final solidPts = nodePositions.sublist(dashedHead).toList(growable: false);
    if (solidPts.length >= 2) {
      final solidPath = _buildSmoothPath(solidPts);

      canvas.drawPath(
        solidPath,
        Paint()
          ..color = pathColor.withValues(alpha: 0.22)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawPath(
        solidPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pathColor, pathColor.withValues(alpha: 0.48)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintSegments(Canvas canvas, Size size) {
    final dashed = dashedSegments ?? const <List<Offset>>[];
    final solid = solidSegments ?? const <List<Offset>>[];

    if (dashed.isNotEmpty) {
      _drawSegmentSet(
        canvas,
        dashed,
        Paint()
          ..color = pathColor.withValues(alpha: 0.30)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        dashed: true,
      );
    }

    if (solid.isEmpty) return;

    _drawSegmentSet(
      canvas,
      solid,
      Paint()
        ..color = pathColor.withValues(alpha: 0.22)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      dashed: false,
    );

    _drawSegmentSet(
      canvas,
      solid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pathColor, pathColor.withValues(alpha: 0.48)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      dashed: false,
    );
  }

  void _drawSegmentSet(
    Canvas canvas,
    List<List<Offset>> segments,
    Paint paint, {
    required bool dashed,
  }) {
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final path = _buildSmoothPath(segment);
      if (dashed) {
        _drawDashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  Path _buildSmoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += 10;
      }
    }
  }

  @override
  bool shouldRepaint(JourneyPathPainter old) =>
      nodePositions != old.nodePositions ||
      pathColor != old.pathColor ||
      dashedHeadCount != old.dashedHeadCount ||
      solidSegments != old.solidSegments ||
      dashedSegments != old.dashedSegments;
}
