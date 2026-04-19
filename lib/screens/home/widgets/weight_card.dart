import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../models/selected_period.dart';
import '../../../models/weight_card_data.dart';
import '../../../theme/app_theme.dart';

// ─── WeightCard ───────────────────────────────────────────────────────────────

class WeightCard extends StatefulWidget {
  final WeightCardData data;

  const WeightCard({super.key, required this.data});

  @override
  State<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<WeightCard> {
  bool _expanded = false;

  String _fmtW(double v) => v.toStringAsFixed(1);

  String _fmtSigned(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    if (!d.hasData) return _NoWeightDataCard(goalWeight: d.goalWeight);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final section = tokens.body;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final progress =
        (d.goalWeight / d.mainValue!).clamp(0.0, 1.0);

    final mainLabel = d.periodType == PeriodType.day
        ? l10n.weightMainLabelDay
        : l10n.weightAverage;

    final trendLabel = switch (d.periodType) {
      PeriodType.day => l10n.weightVsPrevMeasure,
      PeriodType.week => l10n.weightVsPrevWeek,
      PeriodType.month || PeriodType.custom => l10n.weightVsPrevMonth,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          boxShadow: [
            BoxShadow(
              color: tokens.subtleShadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.05,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: section.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(tokens.tileRadius),
                      ),
                      child: Icon(Icons.monitor_weight, color: section.accent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.weightTitle,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Collapsed stats ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: mainLabel,
                      value: '${_fmtW(d.mainValue!)} kg',
                      color: section.accent,
                    ),
                    _StatColumn(
                      label: trendLabel,
                      value: d.trendValue != null
                          ? '${_fmtSigned(d.trendValue!)} kg'
                          : '–',
                      color: _trendColor(context, d.trendValue),
                    ),
                    _StatColumn(
                      label: l10n.weightGoal,
                      value: '${_fmtW(d.goalWeight)} kg',
                      color: cs.onSurface,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Progress bar ──────────────────────────────────────────
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  color: section.accent,
                  backgroundColor: cs.surfaceContainerHighest,
                ),

                // ── Expanded detail ───────────────────────────────────────
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
                        _ExpandedDetail(
                          data: d,
                          locale: locale,
                          fmtW: _fmtW,
                          fmtSigned: _fmtSigned,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _trendColor(BuildContext context, double? trend) {
    if (trend == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.body;
    // Goal: losing weight → negative trend is good
    final goalingDown =
        widget.data.mainValue! >= widget.data.goalWeight;
    final isGood = goalingDown ? trend <= 0 : trend >= 0;
    return isGood ? section.accent : cs.error;
  }
}

// ─── Expanded detail ──────────────────────────────────────────────────────────

class _ExpandedDetail extends StatelessWidget {
  final WeightCardData data;
  final String locale;
  final String Function(double) fmtW;
  final String Function(double) fmtSigned;

  const _ExpandedDetail({
    required this.data,
    required this.locale,
    required this.fmtW,
    required this.fmtSigned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Day mode: body composition ────────────────────────────────────
        if (data.periodType == PeriodType.day) ...[
          if (data.bodyFatPercent != null) ...[
            _BodyCompositionTiles(
              weight: data.mainValue!,
              bodyFat: data.bodyFatPercent!,
              fmtW: fmtW,
            ),
            const SizedBox(height: 12),
          ],
        ],

        // ── Week/Month: min & max ─────────────────────────────────────────
        if (data.periodType != PeriodType.day &&
            (data.periodMin != null || data.periodMax != null)) ...[
          Row(
            children: [
              if (data.periodMin != null)
                Expanded(
                  child: _DetailTile(
                    label: l10n.weightMin,
                    value: '${fmtW(data.periodMin!)} kg',
                  ),
                ),
              if (data.periodMin != null && data.periodMax != null)
                const SizedBox(width: 8),
              if (data.periodMax != null)
                Expanded(
                  child: _DetailTile(
                    label: l10n.weightMax,
                    value: '${fmtW(data.periodMax!)} kg',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Chart ─────────────────────────────────────────────────────────
        if (data.chartPoints.length >= 2) ...[
          SizedBox(
            height: 96,
            child: _WeightChart(
              points: data.chartPoints,
              mode: data.chartMode,
              locale: locale,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Body composition tiles (day mode) ───────────────────────────────────────

class _BodyCompositionTiles extends StatelessWidget {
  final double weight;
  final double bodyFat;
  final String Function(double) fmtW;

  const _BodyCompositionTiles({
    required this.weight,
    required this.bodyFat,
    required this.fmtW,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leanMass = weight * (1 - bodyFat / 100);
    final fatMass = weight * (bodyFat / 100);

    return Row(
      children: [
        Expanded(
          child: _DetailTile(
            label: l10n.weightBodyFat,
            value: '${bodyFat.toStringAsFixed(1)} %',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailTile(
            label: l10n.weightLeanMass,
            value: '${fmtW(leanMass)} kg',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailTile(
            label: l10n.weightFatMass,
            value: '${fmtW(fatMass)} kg',
          ),
        ),
      ],
    );
  }
}

// ─── Chart ────────────────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<WeightChartPoint> points;
  final WeightChartMode mode;
  final String locale;

  const _WeightChart({
    required this.points,
    required this.mode,
    required this.locale,
  });

  String _xLabel(DateTime date) {
    return switch (mode) {
      WeightChartMode.daily => DateFormat('E', locale).format(date),
      WeightChartMode.weekly => DateFormat('d.M.', locale).format(date),
      WeightChartMode.monthly => DateFormat('MMM', locale).format(date),
    };
  }

  @override
  Widget build(BuildContext context) {
    final weights = points.map((p) => p.weight).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b);
    final maxY = weights.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.25).clamp(0.3, 2.0);

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                // Show label only for first, last, and a few middle points
                // to avoid crowding on week/month charts.
                final total = points.length;
                final show = idx == 0 ||
                    idx == total - 1 ||
                    (total > 4 && idx % (total ~/ 4) == 0);
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _xLabel(points[idx].date),
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
            color: context.tokens.body.accent,
            barWidth: 3,
            dotData: FlDotData(show: points.length <= 10),
            belowBarData: BarAreaData(
              show: true,
              color: context.tokens.body.accent.withValues(alpha: 0.12),
            ),
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].weight),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

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
              fontWeight: FontWeight.w700, fontSize: 17, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── No-data state ────────────────────────────────────────────────────────────

class _NoWeightDataCard extends StatelessWidget {
  final double goalWeight;

  const _NoWeightDataCard({required this.goalWeight});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.body.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.monitor_weight_outlined,
                  color: tokens.body.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weightTitle, style: tt.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l10n.weightNoMeasurement,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '${goalWeight.toStringAsFixed(1)} kg',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
