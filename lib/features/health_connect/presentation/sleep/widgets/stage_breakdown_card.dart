import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/sleep_record.dart';
import 'stage_colors.dart';

class StageBreakdownCard extends StatelessWidget {
  const StageBreakdownCard({
    super.key,
    required this.cardId,
    required this.expanded,
    required this.onToggle,
    required this.dateLabel,
    required this.breakdown,
    required this.hasData,
    required this.stageNameOf,
    required this.emptyLabel,
    required this.formatDuration,
  });

  final String cardId;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final String dateLabel;
  final Map<SleepStage, Duration> breakdown;
  final bool hasData;
  final String Function(SleepStage) stageNameOf;
  final String emptyLabel;
  final String Function(Duration?) formatDuration;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.sleep;

    final totalMin = breakdown.values
        .fold<int>(0, (s, d) => s + d.inMinutes);

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
                    child: Icon(Icons.donut_small_rounded,
                        size: 18, color: domain.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.sleepStagesBreakdown,
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
                      child: !hasData
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
                          : Column(
                              children: [
                                // Stacked horizontal bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SizedBox(
                                    height: 10,
                                    child: Row(
                                      children: [
                                        for (final stage in const [
                                          SleepStage.deep,
                                          SleepStage.light,
                                          SleepStage.rem,
                                          SleepStage.awake,
                                        ])
                                          if ((breakdown[stage] ?? Duration.zero)
                                                  .inMinutes >
                                              0)
                                            Expanded(
                                              flex: breakdown[stage]!.inMinutes,
                                              child: Container(
                                                color: StageColors.of(stage),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Tokens.spaceMd),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 2.1,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  children: [
                                    for (final stage in const [
                                      SleepStage.deep,
                                      SleepStage.light,
                                      SleepStage.rem,
                                      SleepStage.awake,
                                    ])
                                      _StageChip(
                                        label: stageNameOf(stage),
                                        color: StageColors.of(stage),
                                        duration:
                                            breakdown[stage] ?? Duration.zero,
                                        totalMinutes: totalMin,
                                        formatDuration: formatDuration,
                                      ),
                                  ],
                                ),
                              ],
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

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.color,
    required this.duration,
    required this.totalMinutes,
    required this.formatDuration,
  });

  final String label;
  final Color color;
  final Duration duration;
  final int totalMinutes;
  final String Function(Duration?) formatDuration;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final pct =
        totalMinutes > 0 ? (duration.inMinutes / totalMinutes * 100) : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: ft.onSurfaceMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  formatDuration(duration),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                    color: ft.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
