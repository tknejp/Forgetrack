import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/l10n.dart';
import '../../../domain/weight_card_data.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/stat_display.dart';

class WeightSummaryCard extends StatelessWidget {
  final double currentWeight;
  final double? change30d;
  final double targetWeight;

  const WeightSummaryCard({
    super.key,
    required this.currentWeight,
    required this.change30d,
    required this.targetWeight,
  });

  String _fmtW(double v) => v.toStringAsFixed(1);
  String _fmtSigned(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);

  Color _trendColor(BuildContext context, double? trend) {
    if (trend == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    final section = context.tokens.body;
    final goalingDown = currentWeight >= targetWeight;
    final isGood = goalingDown ? trend <= 0 : trend >= 0;
    return isGood ? section.accent : Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.body;
    final l10n = context.l10n;

    final diff = currentWeight - targetWeight;
    final atGoal = diff.abs() < 0.5;
    final progress = (targetWeight / currentWeight).clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatColumn(
                  label: l10n.bodyCurrentWeight,
                  value: '${_fmtW(currentWeight)} kg',
                  color: section.accent,
                ),
                StatColumn(
                  label: l10n.body30DayChange,
                  value: change30d != null ? '${_fmtSigned(change30d!)} kg' : '–',
                  color: _trendColor(context, change30d),
                ),
                StatColumn(
                  label: l10n.weightGoal,
                  value: '${_fmtW(targetWeight)} kg',
                  color: cs.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
              color: section.accent,
              backgroundColor: cs.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                atGoal
                    ? l10n.bodyAtGoal
                    : l10n.bodyToGo(diff.abs().toStringAsFixed(1)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: atGoal ? section.accent : cs.onSurfaceVariant,
                      fontWeight: atGoal ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BodyCompositionCard extends StatelessWidget {
  final double weight;
  final double bodyFat;

  const BodyCompositionCard({super.key, required this.weight, required this.bodyFat});

  @override
  Widget build(BuildContext context) {
    final leanMass = weight * (1 - bodyFat / 100);
    final fatMass = weight * (bodyFat / 100);
    final l10n = context.l10n;
    final section = context.tokens.body;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Flexible(
                      flex: (leanMass * 100).round(),
                      child: Container(color: section.accent),
                    ),
                    Flexible(
                      flex: (fatMass * 100).round(),
                      child: Container(color: section.accent.withValues(alpha: 0.35)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CompositionTile(
                    label: l10n.weightBodyFat,
                    value: '${bodyFat.toStringAsFixed(1)} %',
                    dotColor: section.accent.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompositionTile(
                    label: l10n.weightLeanMass,
                    value: '${leanMass.toStringAsFixed(1)} kg',
                    dotColor: section.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompositionTile(
                    label: l10n.weightFatMass,
                    value: '${fatMass.toStringAsFixed(1)} kg',
                    dotColor: section.accent.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompositionTile extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;

  const _CompositionTile({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class WeightTrendCard extends StatelessWidget {
  final List<WeightChartPoint> points;
  final String locale;

  const WeightTrendCard({super.key, required this.points, required this.locale});

  @override
  Widget build(BuildContext context) {
    final section = context.tokens.body;
    final weights = points.map((p) => p.weight).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b);
    final maxY = weights.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.3).clamp(0.3, 3.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: minY - pad,
              maxY: maxY + pad,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      final total = points.length;
                      final show = idx == 0 ||
                          idx == total - 1 ||
                          (total > 4 && idx % (total ~/ 4) == 0);
                      if (!show) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('d.M.', locale).format(points[idx].date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: section.accent,
                  barWidth: 3,
                  dotData: FlDotData(show: points.length <= 10),
                  belowBarData: BarAreaData(
                    show: true,
                    color: section.accent.withValues(alpha: 0.12),
                  ),
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].weight),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
