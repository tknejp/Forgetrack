import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/journey_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Type → colour / icon / label helpers (shared by preview and full map)
// ─────────────────────────────────────────────────────────────────────────────

Color journeyColor(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.level:
      return FtTokens.calories.color; // gold
    case JourneyEventType.title:
      return FtTokens.accent; // purple
    case JourneyEventType.achievement:
      return FtTokens.active.color; // teal
    case JourneyEventType.quest:
      return FtTokens.steps.color; // green
    case JourneyEventType.streak:
      return FtTokens.calories.color; // gold/orange
    case JourneyEventType.xpMilestone:
      return FtTokens.accent; // purple
  }
}

/// Foreground colour drawn on top of the filled node circle.
Color journeyFgColor(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.level:
    case JourneyEventType.achievement:
    case JourneyEventType.quest:
    case JourneyEventType.streak:
      return const Color(0xFF0D0F1C); // dark — high contrast on bright fill
    case JourneyEventType.title:
    case JourneyEventType.xpMilestone:
      return Colors.white;
  }
}

IconData journeyIcon(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.level:
      return Icons.arrow_upward_rounded;
    case JourneyEventType.title:
      return Icons.workspace_premium_rounded;
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

String journeyTypeLabel(JourneyEventType type) {
  switch (type) {
    case JourneyEventType.level:
      return 'LEVEL';
    case JourneyEventType.title:
      return 'TITUL';
    case JourneyEventType.achievement:
      return 'ÚSPĚCH';
    case JourneyEventType.quest:
      return 'QUEST';
    case JourneyEventType.streak:
      return 'SÉRIE';
    case JourneyEventType.xpMilestone:
      return 'XP';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkpoint node
// ─────────────────────────────────────────────────────────────────────────────

/// Interactive circle representing a single journey milestone.
/// Supports current / selected / unlocked / locked visual states.
class JourneyCheckpointNode extends StatelessWidget {
  const JourneyCheckpointNode({
    super.key,
    required this.checkpoint,
    required this.isSelected,
    required this.onTap,
    required this.baseSize,
    this.pulseAnimation,
    this.compact = false,
  });

  final JourneyCheckpoint checkpoint;
  final bool isSelected;
  final VoidCallback onTap;
  final double baseSize;

  /// Pass the repeating [Animation] only for the current node (pulse ring).
  final Animation<double>? pulseAnimation;

  /// Compact mode shrinks padding so the node fits in a tight preview path.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cp = checkpoint;
    final color = journeyColor(cp.type);
    final nodeSize = isSelected ? baseSize + 3.0 : baseSize;
    final pad = compact ? 14.0 : 26.0;
    final totalSize = baseSize + pad;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: cp.isUnlocked
                    ? RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.95),
                          color.withValues(alpha: 0.65),
                        ],
                        radius: 0.85,
                      )
                    : null,
                color: cp.isUnlocked
                    ? null
                    : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: cp.isUnlocked
                      ? color.withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.15),
                  width: cp.isCurrent ? 2.0 : 1.5,
                ),
                boxShadow: cp.isUnlocked
                    ? [
                        BoxShadow(
                          color: color.withValues(
                            alpha: cp.isCurrent ? 0.52 : 0.28,
                          ),
                          blurRadius: cp.isCurrent ? 16 : 8,
                          spreadRadius: cp.isCurrent ? 1 : 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(child: _buildContent(cp, nodeSize)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(JourneyCheckpoint cp, double nodeSize) {
    if (!cp.isUnlocked) {
      return Icon(
        Icons.lock_outline_rounded,
        size: nodeSize * 0.40,
        color: FtTokens.onSurfaceFaint,
      );
    }
    if (cp.type == JourneyEventType.level && cp.levelNumber != null) {
      return Text(
        '${cp.levelNumber}',
        style: TextStyle(
          fontSize: nodeSize * 0.34,
          fontWeight: FontWeight.w900,
          color: journeyFgColor(cp.type),
          letterSpacing: -0.5,
          height: 1,
        ),
      );
    }
    return Icon(
      journeyIcon(cp.type),
      size: nodeSize * 0.46,
      color: journeyFgColor(cp.type),
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
  });

  /// Absolute pixel positions of every node, in display order
  /// (index 0 first along the path).
  final List<Offset> nodePositions;
  final Color pathColor;

  /// Number of leading SEGMENTS drawn dashed (representing future / locked
  /// nodes anchored at the start of the path, e.g. "next milestone" above
  /// the current node). The dashed run connects
  /// `nodePositions[0..dashedHeadCount]`; from `dashedHeadCount` onward the
  /// path is drawn solid.
  final int dashedHeadCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final dashedHead = dashedHeadCount.clamp(0, nodePositions.length - 1);

    // Dashed leading segment (future / locked).
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

    // Solid segment from the first unlocked node onward.
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

  /// Smooth "through-all-points" path using midpoint quadratic beziers.
  /// Starts exactly at `pts[0]` and ends exactly at `pts.last`.
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
      dashedHeadCount != old.dashedHeadCount;
}
