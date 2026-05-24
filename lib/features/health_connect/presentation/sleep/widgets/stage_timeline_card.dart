import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/sleep_record.dart';
import 'stage_colors.dart';

class StageTimelineCard extends StatelessWidget {
  const StageTimelineCard({
    super.key,
    required this.cardId,
    required this.expanded,
    required this.onToggle,
    required this.night,
    required this.dateLabel,
    required this.stageNameOf,
    required this.emptyLabel,
  });

  final String cardId;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final SleepRecord? night;
  final String dateLabel;
  final String Function(SleepStage) stageNameOf;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.sleep;
    final hasSegments = night != null && night!.hasStageData;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggle(cardId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: domain.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: domain.dim,
                      borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                      border: Border.all(
                        color: domain.color.withValues(alpha: 0.27),
                      ),
                    ),
                    child: Icon(Icons.timeline_rounded,
                        size: 18, color: domain.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.sleepStagesTitle,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeBody,
                            fontWeight: FontWeight.w700,
                            color: ft.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeCaption,
                            fontWeight: FontWeight.w500,
                            color: ft.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ft.onSurfaceMuted,
                    size: 24,
                  ),
                ],
              ),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  heightFactor: expanded ? 1.0 : 0.0,
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(top: Tokens.spaceMd),
                      child: !hasSegments
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  emptyLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ft.onSurfaceMuted,
                                  ),
                                ),
                              ),
                            )
                          : _StageTimeline(
                              night: night!,
                              stageNameOf: stageNameOf,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.night, required this.stageNameOf});

  final SleepRecord night;
  final String Function(SleepStage) stageNameOf;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage row legend (Awake → REM → Light → Deep, top to bottom)
        Row(
          children: [
            for (final stage in const [
              SleepStage.deep,
              SleepStage.rem,
              SleepStage.light,
              SleepStage.awake,
            ]) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: StageColors.of(stage),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                stageNameOf(stage),
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: ft.onSurfaceMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: Tokens.spaceMd),
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _StageTimelinePainter(
              segments: night.segments,
              start: night.sleepStart,
              end: night.wakeTime,
              trackLineColor: ft.cardBorder,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Time axis labels: bedtime, midpoint, wake
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('HH:mm', locale).format(night.sleepStart),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                color: ft.onSurfaceFaint,
              ),
            ),
            Text(
              DateFormat('HH:mm', locale).format(
                DateTime.fromMillisecondsSinceEpoch(
                  (night.sleepStart.millisecondsSinceEpoch +
                          night.wakeTime.millisecondsSinceEpoch) ~/
                      2,
                ),
              ),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                color: ft.onSurfaceFaint,
              ),
            ),
            Text(
              DateFormat('HH:mm', locale).format(night.wakeTime),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                color: ft.onSurfaceFaint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StageTimelinePainter extends CustomPainter {
  const _StageTimelinePainter({
    required this.segments,
    required this.start,
    required this.end,
    required this.trackLineColor,
  });

  final List<SleepSegment> segments;
  final DateTime start;
  final DateTime end;
  final Color trackLineColor;

  // Track order (top → bottom): Awake, REM, Light, Deep.
  // Visually maps "more awake" = higher on the chart, "deeper" = lower.
  static const _trackOrder = <SleepStage>[
    SleepStage.awake,
    SleepStage.rem,
    SleepStage.light,
    SleepStage.deep,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final spanMs = end.difference(start).inMilliseconds;
    if (spanMs <= 0) return;

    final tracks = _trackOrder.length;
    final trackHeight = size.height / tracks;

    // Subtle baseline per track for empty-stage readability.
    final linePaint = Paint()
      ..color = trackLineColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (int i = 0; i < tracks; i++) {
      final y = trackHeight * (i + 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    double xFor(DateTime t) {
      final clamped = t.isBefore(start)
          ? 0
          : t.isAfter(end)
              ? spanMs
              : t.difference(start).inMilliseconds;
      return (clamped / spanMs) * size.width;
    }

    final barH = trackHeight * 0.72;
    for (final seg in segments) {
      final trackIdx = _trackOrder.indexOf(seg.stage);
      if (trackIdx < 0) continue;
      final x1 = xFor(seg.start);
      final x2 = xFor(seg.end);
      final w = (x2 - x1).clamp(1.5, size.width).toDouble();
      final yCenter = trackHeight * (trackIdx + 0.5);
      final rect = Rect.fromLTWH(x1, yCenter - barH / 2, w, barH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      final paint = Paint()..color = StageColors.of(seg.stage);
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StageTimelinePainter old) {
    return old.segments != segments ||
        old.start != start ||
        old.end != end ||
        old.trackLineColor != trackLineColor;
  }
}
