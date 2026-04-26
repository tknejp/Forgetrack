import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../domain/weight_card_data.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../../shared/widgets/ft/ft_drag_reveal_pager.dart';
import '../../../shared/widgets/ft/ft_screen_header.dart';
import '../../../shared/widgets/ft/ft_stat_card.dart';
import '../../../shared/widgets/ft/ft_tab_pill.dart';
import '../../../shared/widgets/ft/ft_trend_chart.dart';
import '../application/fitness_provider.dart';
import '../domain/weight_record.dart';

enum _BodyRange {
  week,
  month,
  year,
}

class FtBodyScreen extends StatefulWidget {
  const FtBodyScreen({super.key});

  @override
  State<FtBodyScreen> createState() => _FtBodyScreenState();
}

class _FtBodyScreenState extends State<FtBodyScreen> {
  _BodyRange _range = _BodyRange.month;

  ({double progress, String explanation}) _weightProgressData({
    required double? current,
    required double target,
    required List<WeightRecord> history,
    required String defaultExplanation,
    required String lossExplanation,
    required String gainExplanation,
  }) {
    if (current == null || history.isEmpty) {
      return (progress: 0.0, explanation: defaultExplanation);
    }

    final maxWeight =
        history.map((entry) => entry.weight).reduce((a, b) => a > b ? a : b);
    final minWeight =
        history.map((entry) => entry.weight).reduce((a, b) => a < b ? a : b);

    if (target < current && maxWeight > target) {
      final progress =
          ((maxWeight - current) / (maxWeight - target)).clamp(0.0, 1.0);
      return (progress: progress, explanation: lossExplanation);
    }

    if (target > current && minWeight < target) {
      final progress =
          ((current - minWeight) / (target - minWeight)).clamp(0.0, 1.0);
      return (progress: progress, explanation: gainExplanation);
    }

    final progress = target == current ? 1.0 : 0.0;
    return (progress: progress, explanation: defaultExplanation);
  }

  List<FtChartBar> _buildWeightChart(
    BuildContext context,
    FitnessProvider fitness,
    _BodyRange range,
  ) {
    final locale = Localizations.localeOf(context).toString();
    if (range == _BodyRange.year) {
      final monthly = fitness.monthlyWeightChart(12);
      if (monthly.isEmpty) return [];
      return monthly
          .asMap()
          .entries
          .map(
            (entry) => FtChartBar(
              label: DateFormat.MMM(locale).format(entry.value.date),
              value: entry.value.weight,
              isToday: entry.key == monthly.length - 1,
            ),
          )
          .toList();
    }

    final points = range == _BodyRange.week
        ? fitness.dailyWeightChart(7)
        : fitness.dailyWeightChart(30);
    if (points.isEmpty) return [];

    final sampled = _subsample(points, 7);
    return sampled
        .asMap()
        .entries
        .map(
          (entry) => FtChartBar(
            label: range == _BodyRange.week
                ? _weekdayShort(entry.value.date.weekday)
                : '${entry.value.date.day}',
            value: entry.value.weight,
            isToday: entry.key == sampled.length - 1,
          ),
        )
        .toList();
  }

  List<WeightChartPoint> _subsample(List<WeightChartPoint> points, int max) {
    if (points.length <= max) return points;
    final step = (points.length / max).ceil();
    final result = <WeightChartPoint>[];
    for (int i = 0; i < points.length; i += step) {
      result.add(points[i]);
    }
    if (result.last != points.last) result[result.length - 1] = points.last;
    return result;
  }

  String _weekdayShort(int weekday) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];

  String _chartSubtitle(BuildContext context, _BodyRange range) {
    final l10n = context.l10n;
    switch (range) {
      case _BodyRange.week:
        return l10n.activitiesWeekTotal;
      case _BodyRange.month:
        return l10n.activitiesMonthTotal;
      case _BodyRange.year:
        return l10n.periodMonth;
    }
  }

  _BodyRange _previousRange(_BodyRange range) => switch (range) {
        _BodyRange.week => _BodyRange.week,
        _BodyRange.month => _BodyRange.week,
        _BodyRange.year => _BodyRange.month,
      };

  _BodyRange _nextRange(_BodyRange range) => switch (range) {
        _BodyRange.week => _BodyRange.month,
        _BodyRange.month => _BodyRange.year,
        _BodyRange.year => _BodyRange.year,
      };

  bool _hasPreviousRange(_BodyRange range) => range != _BodyRange.week;

  bool _hasNextRange(_BodyRange range) => range != _BodyRange.year;

  String _activeLabel(BuildContext context, _BodyRange range) {
    final l10n = context.l10n;
    return switch (range) {
      _BodyRange.week => l10n.periodWeek,
      _BodyRange.month => l10n.periodMonth,
      _BodyRange.year => 'Year',
    };
  }

  void _changeRange(String tabLabel) {
    final l10n = context.l10n;
    setState(() {
      _range = tabLabel == l10n.periodWeek
          ? _BodyRange.week
          : tabLabel == l10n.periodMonth
              ? _BodyRange.month
              : _BodyRange.year;
    });
  }

  Widget _buildRangeContent(
    BuildContext context,
    _BodyRange range,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final current = fitness.latestWeight;
    final target = goals.targetWeight;
    final history = fitness.weightHistory;
    final progressData = _weightProgressData(
      current: current,
      target: target,
      history: history,
      defaultExplanation: l10n.weightProgressExplanation,
      lossExplanation: l10n.weightProgressExplanationLoss,
      gainExplanation: l10n.weightProgressExplanationGain,
    );
    final prevWeight =
        history.length >= 2 ? history[history.length - 2].weight : null;
    final weightChange =
        (current != null && prevWeight != null) ? current - prevWeight : null;
    final chartBars = _buildWeightChart(context, fitness, range);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FtStatCard(
          icon: '\u2696',
          label: l10n.weightTitle,
          domain: FtTokens.weight,
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            FtStatStat(
              value: current?.toStringAsFixed(1) ?? '--',
              label: l10n.bodyCurrentWeight,
              unit: 'kg',
            ),
            FtStatStat(
              value: weightChange != null
                  ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}'
                  : '--',
              label: range == _BodyRange.week
                  ? l10n.weightVsPrevWeek
                  : range == _BodyRange.month
                      ? l10n.weightVsPrevMonth
                      : l10n.weightAverage,
              unit: 'kg',
            ),
            FtStatStat(
              value: target.toStringAsFixed(1),
              label: l10n.weightGoal,
              unit: 'kg',
            ),
          ],
          progress: progressData.progress,
          trophy: true,
          children: [
            const SizedBox(height: 10),
            Text(
              progressData.explanation,
              style: const TextStyle(
                fontSize: FtTokens.fontSizeCaption,
                fontWeight: FontWeight.w500,
                color: FtTokens.onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FtTrendCard(
          domain: FtTokens.weight,
          icon: Icons.show_chart,
          title: l10n.bodyWeightTrend,
          subtitle: _chartSubtitle(context, range),
          collapsible: false,
          metrics: [
            FtTrendMetric(
              label: l10n.bodyCurrentWeight,
              value:
                  current != null ? '${current.toStringAsFixed(1)} kg' : '--',
            ),
            FtTrendMetric(
              label: l10n.weightAverage,
              value: weightChange != null
                  ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg'
                  : '--',
            ),
            FtTrendMetric(
              label: l10n.weightGoal,
              value: '${target.toStringAsFixed(1)} kg',
            ),
          ],
          bars: chartBars,
          relativeScale: true,
          referenceValue: target,
          referenceLabel: l10n.weightGoal,
          emptyLabel: l10n.bodyNoData,
          expandable: chartBars.length > 4,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();

    return Scaffold(
      backgroundColor: FtTokens.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => fitness.refresh(),
          color: FtTokens.accent,
          backgroundColor: FtTokens.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      FtScreenHeader(
                        greeting: '',
                        title: context.l10n.screenBody,
                        leading: Navigator.of(context).canPop()
                            ? _BackButton(
                                onTap: () => Navigator.of(context).maybePop(),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      FtTabPill(
                        tabs: [
                          context.l10n.periodWeek,
                          context.l10n.periodMonth,
                          'Year',
                        ],
                        active: _activeLabel(context, _range),
                        onChange: _changeRange,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  child: FtDragRevealPager<_BodyRange>(
                    item: _range,
                    hasPrevious: _hasPreviousRange,
                    hasNext: _hasNextRange,
                    previousOf: _previousRange,
                    nextOf: _nextRange,
                    onCommit: (range) => setState(() => _range = range),
                    builder: (context, range) =>
                        _buildRangeContent(context, range, fitness, goals),
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

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.cardBorder),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
