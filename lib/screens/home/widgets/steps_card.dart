import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/activity_record.dart';

class StepsCard extends StatelessWidget {
  final int todaySteps;
  final List<StepsRecord> history;
  final int goal;

  const StepsCard({
    super.key,
    required this.todaySteps,
    required this.history,
    this.goal = 10000,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (todaySteps / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: cs.primary),
                const SizedBox(width: 8),
                Text('Kroky', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  NumberFormat('#,###').format(todaySteps),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text(
              'Cíl: ${NumberFormat('#,###').format(goal)} kroků',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (history.length > 1) ...[
              const SizedBox(height: 16),
              SizedBox(height: 80, child: _StepsBarChart(history: history)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepsBarChart extends StatelessWidget {
  final List<StepsRecord> history;

  const _StepsBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxSteps =
        history.map((e) => e.steps).reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxSteps == 0 ? 1 : maxSteps * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= history.length) return const SizedBox();
                return Text(
                  DateFormat('E').format(history[idx].date),
                  style: const TextStyle(fontSize: 10),
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
                      ? cs.primary
                      : cs.primary.withAlpha(100),
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
