import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/l10n.dart';
import '../../../models/weight_record.dart';

class WeightCard extends StatefulWidget {
  final double currentWeight;
  final double goalWeight;
  final double? bodyFatPercent;
  final List<WeightRecord> history;

  const WeightCard({
    super.key,
    required this.currentWeight,
    required this.goalWeight,
    this.bodyFatPercent,
    required this.history,
  });

  @override
  State<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<WeightCard> {
  bool _expanded = false;

  String _fmtWeight(double value) => value.toStringAsFixed(1);

  String _fmtSigned(double value) {
    if (value > 0) return '+${value.toStringAsFixed(1)}';
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final difference = widget.currentWeight - widget.goalWeight;
    final progress =
        (widget.goalWeight / widget.currentWeight).clamp(0.0, 1.0);

    final last7 = widget.history.length >= 2
        ? widget.history.skip(widget.history.length > 7 ? widget.history.length - 7 : 0).toList()
        : widget.history;

    final weeklyChange = last7.length >= 2
        ? last7.last.weight - last7.first.weight
        : 0.0;

    final avgWeight = widget.history.isEmpty
        ? widget.currentWeight
        : widget.history.map((e) => e.weight).reduce((a, b) => a + b) /
            widget.history.length;

    final minWeight = widget.history.isEmpty
        ? widget.currentWeight
        : widget.history
            .map((e) => e.weight)
            .reduce((a, b) => a < b ? a : b);

    final maxWeight = widget.history.isEmpty
        ? widget.currentWeight
        : widget.history
            .map((e) => e.weight)
            .reduce((a, b) => a > b ? a : b);

    final bf = widget.bodyFatPercent;
    final leanMass =
        bf != null ? widget.currentWeight * (1 - (bf / 100)) : null;
    final fatMass = bf != null ? widget.currentWeight * (bf / 100) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_weight, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(l10n.weightTitle, style: tt.titleMedium),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: l10n.weightCurrent,
                    value: '${_fmtWeight(widget.currentWeight)} kg',
                    color: cs.primary,
                  ),
                  _StatColumn(
                    label: l10n.weightGoal,
                    value: '${_fmtWeight(widget.goalWeight)} kg',
                    color: cs.onSurface,
                  ),
                  _StatColumn(
                    label: l10n.weightDifference,
                    value: '${_fmtSigned(difference)} kg',
                    color: difference <= 0 ? cs.primary : cs.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: difference <= 0 ? cs.tertiary : cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: cs.outlineVariant),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _DetailTile(
                              label: l10n.weight7Days,
                              value: '${_fmtSigned(weeklyChange)} kg',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DetailTile(
                              label: l10n.weightAverage,
                              value: '${_fmtWeight(avgWeight)} kg',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _DetailTile(
                              label: l10n.weightMin,
                              value: '${_fmtWeight(minWeight)} kg',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DetailTile(
                              label: l10n.weightMax,
                              value: '${_fmtWeight(maxWeight)} kg',
                            ),
                          ),
                        ],
                      ),

                      if (bf != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailTile(
                                label: l10n.weightBodyFat,
                                value: '${bf.toStringAsFixed(1)} %',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DetailTile(
                                label: l10n.weightLeanMass,
                                value: '${_fmtWeight(leanMass!)} kg',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailTile(
                                label: l10n.weightFatMass,
                                value: '${_fmtWeight(fatMass!)} kg',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DetailTile(
                                label: l10n.weightStatus,
                                value: difference <= 0
                                    ? l10n.weightGoalAchieved
                                    : l10n.weightInProgress,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (widget.history.length > 1) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 96,
                          child: _WeightLineChart(
                            history: widget.history,
                            locale: locale,
                          ),
                        ),
                      ],
                    ],
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

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<WeightRecord> history;
  final String locale;

  const _WeightLineChart({required this.history, required this.locale});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final weights = history.map((e) => e.weight).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b);
    final maxY = weights.reduce((a, b) => a > b ? a : b);
    final padding = ((maxY - minY) * 0.25).clamp(0.3, 2.0);

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= history.length) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('E', locale).format(history[idx].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: cs.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: history.length <= 10,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.12),
            ),
            spots: [
              for (int i = 0; i < history.length; i++)
                FlSpot(i.toDouble(), history[i].weight),
            ],
          ),
        ],
      ),
    );
  }
}
