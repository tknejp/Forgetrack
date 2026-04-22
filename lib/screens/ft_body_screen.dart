import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_card_data.dart';
import '../providers/fitness_provider.dart';
import '../providers/goals_provider.dart';
import '../theme/ft_design_tokens.dart';
import '../widgets/ft/ft_plain_card.dart';
import '../widgets/ft/ft_screen_header.dart';
import '../widgets/ft/ft_stat_card.dart';
import '../widgets/ft/ft_tab_pill.dart';
import '../widgets/ft/ft_trend_chart.dart';

class FtBodyScreen extends StatefulWidget {
  const FtBodyScreen({super.key});

  @override
  State<FtBodyScreen> createState() => _FtBodyScreenState();
}

class _FtBodyScreenState extends State<FtBodyScreen> {
  String _tab = 'Month';

  List<FtChartBar> _buildWeightChart(FitnessProvider fitness, String tab) {
    if (tab == 'Year') {
      final monthly = fitness.monthlyWeightChart(12);
      if (monthly.isEmpty) return [];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return monthly
          .asMap()
          .entries
          .map((e) => FtChartBar(
                label: months[e.value.date.month - 1],
                value: e.value.weight,
                isToday: e.key == monthly.length - 1,
              ))
          .toList();
    }

    final points = tab == 'Week'
        ? fitness.dailyWeightChart(7)
        : fitness.dailyWeightChart(30);
    if (points.isEmpty) return [];

    final sampled = _subsample(points, 7);
    return sampled
        .asMap()
        .entries
        .map((e) => FtChartBar(
              label: tab == 'Week'
                  ? _weekdayShort(e.value.date.weekday)
                  : '${e.value.date.day}',
              value: e.value.weight,
              isToday: e.key == sampled.length - 1,
            ))
        .toList();
  }

  List<WeightChartPoint> _subsample(List<WeightChartPoint> pts, int max) {
    if (pts.length <= max) return pts;
    final step = (pts.length / max).ceil();
    final result = <WeightChartPoint>[];
    for (int i = 0; i < pts.length; i += step) {
      result.add(pts[i]);
    }
    if (result.last != pts.last) result[result.length - 1] = pts.last;
    return result;
  }

  String _weekdayShort(int weekday) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes - h * 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _chartSubtitle(String tab) {
    switch (tab) {
      case 'Week':
        return 'Last 7 days';
      case 'Month':
        return 'Last 30 days';
      default:
        return 'Last 12 months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();

    // ── Weight ────────────────────────────────────────────────────────────────
    final current = fitness.latestWeight;
    final target = goals.targetWeight;
    final wHistory = fitness.weightHistory;
    final wMax = wHistory.isNotEmpty
        ? wHistory.map((w) => w.weight).reduce((a, b) => a > b ? a : b)
        : null;
    final wProgress = (current != null && wMax != null && wMax > target)
        ? ((wMax - current) / (wMax - target)).clamp(0.0, 1.0)
        : 0.0;
    final prevWeight =
        wHistory.length >= 2 ? wHistory[wHistory.length - 2].weight : null;
    final weightChange =
        (current != null && prevWeight != null) ? current - prevWeight : null;

    final chartBars = _buildWeightChart(fitness, _tab);

    // ── Sleep ─────────────────────────────────────────────────────────────────
    final sleep = fitness.todaySleep;
    final sleepDuration =
        sleep != null ? _formatDuration(sleep.totalDuration) : '--';
    final bedtime = sleep != null
        ? DateFormat('HH:mm').format(sleep.sleepStart)
        : '--:--';
    final wakeTime = sleep != null
        ? DateFormat('HH:mm').format(sleep.wakeTime)
        : '--:--';
    final sleepGoalMins = goals.sleepHours * 60;
    final sleepProgress = sleep != null
        ? (sleep.totalDuration.inMinutes / sleepGoalMins).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      onRefresh: () => fitness.refresh(),
      color: FtTokens.accent,
      backgroundColor: FtTokens.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          const FtScreenHeader(greeting: 'The long game ✦', title: 'Body'),
          const SizedBox(height: 10),
          FtTabPill(
            tabs: const ['Week', 'Month', 'Year'],
            active: _tab,
            onChange: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: 10),
          FtStatCard(
            icon: '⚖️',
            label: 'Weight',
            domain: FtTokens.weight,
            stats: [
              FtStatStat(
                value: current?.toStringAsFixed(1) ?? '--',
                label: 'Current',
                unit: 'kg',
              ),
              FtStatStat(
                value: weightChange != null
                    ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}'
                    : '--',
                label: 'Change',
                unit: 'kg',
              ),
              FtStatStat(
                value: target.toStringAsFixed(1),
                label: 'Goal',
                unit: 'kg',
              ),
            ],
            progress: wProgress,
            trophy: true,
          ),
          const SizedBox(height: 10),
          FtTrendCard(
            domain: FtTokens.weight,
            icon: Icons.show_chart,
            title: 'Weight trend',
            subtitle: _chartSubtitle(_tab),
            metrics: [
              FtTrendMetric(
                label: 'Current',
                value: current != null ? '${current.toStringAsFixed(1)} kg' : '--',
              ),
              FtTrendMetric(
                label: 'Change',
                value: weightChange != null
                    ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg'
                    : '--',
                color: weightChange == null
                    ? null
                    : (weightChange <= 0
                        ? FtTokens.weight.color
                        : const Color(0xFFFCA5A5)),
              ),
              FtTrendMetric(
                label: 'Goal',
                value: '${target.toStringAsFixed(1)} kg',
              ),
            ],
            bars: chartBars,
            relativeScale: true,
            referenceValue: target,
            referenceLabel: 'Goal',
            emptyLabel: 'No weight data yet',
            expandable: chartBars.length > 4,
          ),
          const SizedBox(height: 10),
          FtStatCard(
            icon: '🌙',
            label: 'Sleep · last night',
            domain: FtTokens.sleep,
            stats: [
              FtStatStat(value: sleepDuration, label: 'Duration'),
              FtStatStat(value: bedtime, label: 'Bedtime'),
              FtStatStat(value: wakeTime, label: 'Wake'),
            ],
            progress: sleepProgress,
            badge: sleep != null ? '${(sleepProgress * 100).round()}%' : null,
            // TODO: no sleep score in SleepRecord — needs dedicated scoring model
          ),
        ],
      ),
    );
  }
}
