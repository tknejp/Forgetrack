import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/l10n.dart';
import '../../../features/health_connect/domain/activity_record.dart';
import '../../../theme/app_theme.dart';

class StepsCard extends StatefulWidget {
  final int todaySteps;
  final List<StepsRecord> history;
  final int goal;
  final String? mainLabel;

  const StepsCard({
    super.key,
    required this.todaySteps,
    required this.history,
    this.goal = 10000,
    this.mainLabel,
  });

  @override
  State<StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends State<StepsCard> {
  bool _expanded = false;

  String _fmt(int n, String locale) =>
      NumberFormat.decimalPattern(locale).format(n);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final section = tokens.steps;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final mainLabel = widget.mainLabel ?? l10n.stepsToday;

    final progress = (widget.todaySteps / widget.goal).clamp(0.0, 1.0);
    final remaining = (widget.goal - widget.todaySteps).clamp(0, widget.goal);

    final avgSteps = widget.history.isEmpty
        ? 0
        : (widget.history.map((e) => e.steps).reduce((a, b) => a + b) /
                widget.history.length)
            .round();

    final bestDay = widget.history.isEmpty
        ? null
        : widget.history.reduce((a, b) => a.steps >= b.steps ? a : b);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: section.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(tokens.tileRadius),
                      ),
                      child: Icon(Icons.directions_walk, color: section.accent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.stepsTitle,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
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
                      label: mainLabel,
                      value: _fmt(widget.todaySteps, locale),
                      color: section.accent,
                    ),
                    _StatColumn(
                      label: l10n.stepsGoal,
                      value: _fmt(widget.goal, locale),
                      color: cs.onSurface,
                    ),
                    _StatColumn(
                      label: l10n.stepsRemaining,
                      value: _fmt(remaining, locale),
                      color: remaining == 0 ? section.accent : cs.onSurface,
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
                                label: l10n.stepsAverage,
                                value:
                                    l10n.stepsAvgPerDay(_fmt(avgSteps, locale)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DetailTile(
                                label: l10n.stepsCompleted,
                                value: widget.todaySteps >= widget.goal
                                    ? l10n.stepsYes
                                    : l10n.stepsNo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (bestDay != null)
                          Row(
                            children: [
                              Expanded(
                                child: _DetailTile(
                                  label: l10n.stepsBestDay,
                                  value: DateFormat('E', locale)
                                      .format(bestDay.date),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DetailTile(
                                  label: l10n.stepsMaxSteps,
                                  value: _fmt(bestDay.steps, locale),
                                ),
                              ),
                            ],
                          ),
                        if (widget.history.length > 1) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 96,
                            child: _StepsBarChart(
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
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: color,
          ),
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

  const _DetailTile({
    required this.label,
    required this.value,
  });

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

class _StepsBarChart extends StatelessWidget {
  final List<StepsRecord> history;
  final String locale;

  const _StepsBarChart({required this.history, required this.locale});

  @override
  Widget build(BuildContext context) {
    final maxSteps =
        history.map((e) => e.steps).reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxSteps == 0 ? 1 : maxSteps * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= history.length) return const SizedBox();

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
        barGroups: [
          for (int i = 0; i < history.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: history[i].steps.toDouble(),
                  color: i == history.length - 1
                      ? context.tokens.steps.accent
                      : context.tokens.steps.accent.withValues(alpha: 0.30),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
