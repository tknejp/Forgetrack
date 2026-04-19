import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../models/activity_record.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/stat_display.dart';

class StepsSummaryCard extends StatelessWidget {
  final int todaySteps;
  final int weekTotal;
  final int monthTotal;
  final int dailyGoal;
  final int avgPerDay;

  const StepsSummaryCard({
    super.key,
    required this.todaySteps,
    required this.weekTotal,
    required this.monthTotal,
    required this.dailyGoal,
    required this.avgPerDay,
  });

  String _fmt(int n) => NumberFormat.decimalPattern().format(n);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.steps;
    final l10n = context.l10n;

    final progress = (todaySteps / dailyGoal).clamp(0.0, 1.0);
    final remaining = (dailyGoal - todaySteps).clamp(0, dailyGoal);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatColumn(label: l10n.stepsToday, value: _fmt(todaySteps), color: section.accent),
                StatColumn(label: l10n.stepsGoal, value: _fmt(dailyGoal), color: cs.onSurface),
                StatColumn(
                  label: l10n.stepsRemaining,
                  value: _fmt(remaining),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: StatDetailTile(label: l10n.activitiesWeekTotal, value: _fmt(weekTotal))),
                const SizedBox(width: 8),
                Expanded(child: StatDetailTile(label: l10n.activitiesMonthTotal, value: _fmt(monthTotal))),
                const SizedBox(width: 8),
                Expanded(child: StatDetailTile(label: l10n.activitiesDailyAvg, value: l10n.stepsAvgPerDay(_fmt(avgPerDay)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StepsTrendCard extends StatelessWidget {
  final List<StepsRecord> history;
  final String locale;

  const StepsTrendCard({super.key, required this.history, required this.locale});

  @override
  Widget build(BuildContext context) {
    final section = context.tokens.steps;
    final maxSteps = history.map((e) => e.steps).reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              maxY: maxSteps == 0 ? 1 : maxSteps * 1.25,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
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
                            ? section.accent
                            : section.accent.withValues(alpha: 0.30),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

class ActiveCaloriesCard extends StatelessWidget {
  final double today;
  final double week;
  final double month;

  const ActiveCaloriesCard({
    super.key,
    required this.today,
    required this.week,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StatColumn(
              label: l10n.stepsToday,
              value: '${today.round()} kcal',
              color: tokens.nutrition.accent,
            ),
            StatColumn(
              label: l10n.activitiesWeekTotal,
              value: '${week.round()} kcal',
              color: cs.onSurface,
            ),
            StatColumn(
              label: l10n.activitiesMonthTotal,
              value: '${month.round()} kcal',
              color: cs.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveMinsCard extends StatelessWidget {
  final int todayMins;
  final int weekMins;
  final int weeklyGoal;

  const ActiveMinsCard({
    super.key,
    required this.todayMins,
    required this.weekMins,
    required this.weeklyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.steps;
    final l10n = context.l10n;
    final progress = (weekMins / weeklyGoal).clamp(0.0, 1.0);

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
                  label: l10n.stepsToday,
                  value: '$todayMins ${l10n.goalUnitMins}',
                  color: section.accent,
                ),
                StatColumn(
                  label: l10n.activitiesWeekTotal,
                  value: '$weekMins ${l10n.goalUnitMins}',
                  color: cs.onSurface,
                ),
                StatColumn(
                  label: l10n.stepsGoal,
                  value: '$weeklyGoal ${l10n.goalUnitMins}',
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
          ],
        ),
      ),
    );
  }
}

class WorkoutStatsCard extends StatelessWidget {
  final int weekCount;
  final int monthCount;
  final int weekTotalMins;
  final int monthTotalMins;
  final int weekCalories;
  final int monthCalories;
  final int avgDurationMins;

  const WorkoutStatsCard({
    super.key,
    required this.weekCount,
    required this.monthCount,
    required this.weekTotalMins,
    required this.monthTotalMins,
    required this.weekCalories,
    required this.monthCalories,
    required this.avgDurationMins,
  });

  String _fmtTime(int totalMins) {
    if (totalMins == 0) return '0 min';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasCalories = weekCalories > 0 || monthCalories > 0;

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
                  label: l10n.activitiesWeekTotal,
                  value: '$weekCount',
                  color: cs.secondary,
                ),
                StatColumn(
                  label: l10n.activitiesMonthTotal,
                  value: '$monthCount',
                  color: cs.onSurface,
                ),
                StatColumn(
                  label: l10n.activitiesAvgDuration,
                  value: avgDurationMins > 0 ? _fmtTime(avgDurationMins) : '–',
                  color: cs.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: StatDetailTile(label: l10n.activitiesWeekTotal, value: _fmtTime(weekTotalMins))),
                const SizedBox(width: 8),
                Expanded(child: StatDetailTile(label: l10n.activitiesMonthTotal, value: _fmtTime(monthTotalMins))),
                if (hasCalories) ...[
                  const SizedBox(width: 8),
                  Expanded(child: StatDetailTile(label: l10n.caloriesBurned, value: '$monthCalories kcal')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
