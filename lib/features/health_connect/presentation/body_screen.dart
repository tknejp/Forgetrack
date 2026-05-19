import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../features/health_connect/application/goals_provider.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/fitness_provider.dart';

enum _BodyRange { day, week, month }

@immutable
class _BodyPeriod {
  const _BodyPeriod({
    required this.range,
    required this.referenceDate,
  });

  factory _BodyPeriod.current(_BodyRange range) {
    final now = DateTime.now();
    return _BodyPeriod(
      range: range,
      referenceDate: DateTime(now.year, now.month, now.day),
    );
  }

  final _BodyRange range;
  final DateTime referenceDate;

  DateTime get start {
    return switch (range) {
      _BodyRange.day => referenceDate,
      _BodyRange.week =>
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1)),
      _BodyRange.month => DateTime(referenceDate.year, referenceDate.month, 1),
    };
  }

  DateTime get end {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodEnd = switch (range) {
      _BodyRange.day => referenceDate,
      _BodyRange.week => start.add(const Duration(days: 6)),
      _BodyRange.month =>
        DateTime(referenceDate.year, referenceDate.month + 1, 0),
    };
    return periodEnd.isAfter(today) ? today : periodEnd;
  }

  /// Full calendar end for display labels — never capped at today.
  DateTime get displayEnd => switch (range) {
        _BodyRange.day => referenceDate,
        _BodyRange.week => start.add(const Duration(days: 6)),
        _BodyRange.month =>
          DateTime(referenceDate.year, referenceDate.month + 1, 0),
      };

  bool get isCurrentPeriod {
    final current = _BodyPeriod.current(range);
    return start == current.start;
  }

  bool get canGoForward => !isCurrentPeriod;

  _BodyPeriod withRange(_BodyRange nextRange) => _BodyPeriod.current(nextRange);

  _BodyPeriod backward() => shift(-1);

  _BodyPeriod forward() => canGoForward ? shift(1) : this;

  _BodyPeriod shift(int amount) {
    return switch (range) {
      _BodyRange.day => _BodyPeriod(
          range: range,
          referenceDate: referenceDate.add(Duration(days: amount)),
        ),
      _BodyRange.week => _BodyPeriod(
          range: range,
          referenceDate: referenceDate.add(Duration(days: 7 * amount)),
        ),
      _BodyRange.month => _BodyPeriod(
          range: range,
          referenceDate: DateTime(
            referenceDate.year,
            referenceDate.month + amount,
            1,
          ),
        ),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BodyPeriod && range == other.range && start == other.start;

  @override
  int get hashCode => Object.hash(range, start);
}

class _WeightPeriodBar {
  const _WeightPeriodBar({
    required this.period,
    required this.bar,
  });

  final _BodyPeriod period;
  final ChartBar bar;
}

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  _BodyPeriod _trendPeriod = _BodyPeriod.current(_BodyRange.week);
  final Set<String> _expandedMetricCards = {'weight'};

  double? _averageWeightForPeriod(
    FitnessProvider fitness,
    _BodyPeriod period,
  ) {
    final records = fitness.weightHistoryForRange(period.start, period.end);
    if (records.isEmpty) return null;
    return records.fold<double>(0, (sum, r) => sum + r.weight) / records.length;
  }

  List<_WeightPeriodBar> _buildWeightBars(
    BuildContext context,
    FitnessProvider fitness,
    _BodyPeriod selected,
  ) {
    final locale = Localizations.localeOf(context).toString();

    // Group weights by period start in a single O(n) pass — no per-record
    // calls to weightHistoryForRange which would make this O(n²).
    final groups = <DateTime, List<double>>{};
    final periodForKey = <DateTime, _BodyPeriod>{};
    for (final record in fitness.weightHistory) {
      final period = _periodForDate(selected.range, record.date);
      groups.putIfAbsent(period.start, () => []).add(record.weight);
      periodForKey[period.start] = period;
    }

    return groups.entries.map((entry) {
      final period = periodForKey[entry.key]!;
      final weights = entry.value;
      final value = selected.range == _BodyRange.day
          ? weights.last
          : weights.fold<double>(0, (s, v) => s + v) / weights.length;
      return _WeightPeriodBar(
        period: period,
        bar: ChartBar(
          label: _barLabel(locale, period),
          value: value,
          isToday: period == selected,
        ),
      );
    }).toList()
      ..sort((a, b) => a.period.start.compareTo(b.period.start));
  }

  List<_WeightPeriodBar> _buildBodyFatBars(
    BuildContext context,
    FitnessProvider fitness,
    _BodyPeriod selected,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final grouped = <DateTime, List<double>>{};
    for (final record in fitness.weightHistory) {
      final bodyFat = record.bodyFat;
      if (bodyFat == null) continue;
      final period = _periodForDate(selected.range, record.date);
      grouped.putIfAbsent(period.start, () => []).add(bodyFat);
    }

    return grouped.entries.map((entry) {
      final period =
          _BodyPeriod(range: selected.range, referenceDate: entry.key);
      final average = entry.value.fold<double>(0, (sum, v) => sum + v) /
          entry.value.length;
      return _WeightPeriodBar(
        period: period,
        bar: ChartBar(
          label: _barLabel(locale, period),
          value: average,
          isToday: period == selected,
        ),
      );
    }).toList()
      ..sort((a, b) => a.period.start.compareTo(b.period.start));
  }

  List<_WeightPeriodBar> _buildLeanMassBars(
    BuildContext context,
    FitnessProvider fitness,
    _BodyPeriod selected,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final grouped = <DateTime, List<double>>{};
    for (final record in fitness.weightHistory) {
      final bodyFat = record.bodyFat;
      if (bodyFat == null) continue;
      final period = _periodForDate(selected.range, record.date);
      grouped.putIfAbsent(period.start, () => [])
          .add(record.weight * (1 - bodyFat / 100));
    }

    return grouped.entries.map((entry) {
      final period =
          _BodyPeriod(range: selected.range, referenceDate: entry.key);
      final average = entry.value.fold<double>(0, (sum, v) => sum + v) /
          entry.value.length;
      return _WeightPeriodBar(
        period: period,
        bar: ChartBar(
          label: _barLabel(locale, period),
          value: average,
          isToday: period == selected,
        ),
      );
    }).toList()
      ..sort((a, b) => a.period.start.compareTo(b.period.start));
  }

  List<_WeightPeriodBar> _buildBodyWaterBars(
    BuildContext context,
    FitnessProvider fitness,
    _BodyPeriod selected,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final grouped = <DateTime, List<double>>{};
    for (final record in fitness.weightHistory) {
      final bw = record.bodyWater;
      if (bw == null) continue;
      final period = _periodForDate(selected.range, record.date);
      grouped.putIfAbsent(period.start, () => []).add(bw);
    }

    return grouped.entries.map((entry) {
      final period =
          _BodyPeriod(range: selected.range, referenceDate: entry.key);
      final average = entry.value.fold<double>(0, (sum, v) => sum + v) /
          entry.value.length;
      return _WeightPeriodBar(
        period: period,
        bar: ChartBar(
          label: _barLabel(locale, period),
          value: average,
          isToday: period == selected,
        ),
      );
    }).toList()
      ..sort((a, b) => a.period.start.compareTo(b.period.start));
  }

  double? _averageBodyFatForPeriod(FitnessProvider fitness, _BodyPeriod period) {
    final records = fitness
        .weightHistoryForRange(period.start, period.end)
        .where((r) => r.bodyFat != null) // lint-ignore: widget-no-logic — drops records missing the optional bodyFat column for chart aggregation
        .toList();
    if (records.isEmpty) return null;
    return records.fold<double>(0, (s, r) => s + r.bodyFat!) / records.length;
  }

  double? _averageLeanMassForPeriod(FitnessProvider fitness, _BodyPeriod period) {
    final records = fitness
        .weightHistoryForRange(period.start, period.end)
        .where((r) => r.bodyFat != null) // lint-ignore: widget-no-logic — drops records missing bodyFat (needed for lean-mass formula)
        .toList();
    if (records.isEmpty) return null;
    return records.fold<double>(
          0,
          (s, r) => s + r.weight * (1 - r.bodyFat! / 100),
        ) /
        records.length;
  }

  double? _averageBodyWaterForPeriod(FitnessProvider fitness, _BodyPeriod period) {
    final records = fitness
        .weightHistoryForRange(period.start, period.end)
        .where((r) => r.bodyWater != null) // lint-ignore: widget-no-logic — drops records missing the optional bodyWater column for chart aggregation
        .toList();
    if (records.isEmpty) return null;
    return records.fold<double>(0, (s, r) => s + r.bodyWater!) / records.length;
  }

  _BodyPeriod _periodForDate(_BodyRange range, DateTime date) {
    return _BodyPeriod(
      range: range,
      referenceDate: DateTime(date.year, date.month, date.day),
    );
  }

  String _barLabel(String locale, _BodyPeriod period) {
    return switch (period.range) {
      _BodyRange.day => DateFormat('d.M.', locale).format(period.start),
      _BodyRange.week => DateFormat('d.M.', locale).format(period.start),
      _BodyRange.month => DateFormat.MMM(locale).format(period.start),
    };
  }

  String _dateLabel(BuildContext context, _BodyPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    return switch (period.range) {
      _BodyRange.day => DateFormat('d MMM', locale).format(period.start),
      _BodyRange.week =>
        '${DateFormat('d MMM', locale).format(period.start)} – '
            '${DateFormat('d MMM', locale).format(period.displayEnd)}',
      _BodyRange.month => DateFormat.yMMMM(locale).format(period.start),
    };
  }

  String _rangeLabel(BuildContext context, _BodyRange range) {
    final l10n = context.l10n;
    return switch (range) {
      _BodyRange.day => l10n.periodDay,
      _BodyRange.week => l10n.periodWeek,
      _BodyRange.month => l10n.periodMonth,
    };
  }

  void _changeRange(String tabLabel) {
    final l10n = context.l10n;
    final nextRange = tabLabel == l10n.periodDay
        ? _BodyRange.day
        : tabLabel == l10n.periodWeek
            ? _BodyRange.week
            : _BodyRange.month;
    setState(() => _trendPeriod = _trendPeriod.withRange(nextRange));
  }

  Widget _buildRangeContent(
    BuildContext context,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final current = fitness.latestWeight;
    final target = goals.targetWeight;
    final history = fitness.weightHistory;

    final prevWeight =
        history.length >= 2 ? history[history.length - 2].weight : null;
    final latestChange =
        (current != null && prevWeight != null) ? current - prevWeight : null;
    final periodAverage = _averageWeightForPeriod(fitness, _trendPeriod);
    final previousAverage =
        _averageWeightForPeriod(fitness, _trendPeriod.backward());
    final averageChange = periodAverage != null && previousAverage != null
        ? periodAverage - previousAverage
        : null;
    final chartData = _buildWeightBars(context, fitness, _trendPeriod);
    final latestBodyFat = fitness.latestBodyFat;
    final currentLeanMass = current != null && latestBodyFat != null
        ? current * (1 - latestBodyFat / 100)
        : null;
    final bodyFatData = _buildBodyFatBars(context, fitness, _trendPeriod);
    final leanMassData = _buildLeanMassBars(context, fitness, _trendPeriod);
    final bodyWaterData = _buildBodyWaterBars(context, fitness, _trendPeriod);

    final periodBodyFat = _averageBodyFatForPeriod(fitness, _trendPeriod);
    final prevBodyFat =
        _averageBodyFatForPeriod(fitness, _trendPeriod.backward());
    final bodyFatChange = periodBodyFat != null && prevBodyFat != null
        ? periodBodyFat - prevBodyFat
        : null;

    final periodLeanMass = _averageLeanMassForPeriod(fitness, _trendPeriod);
    final prevLeanMass =
        _averageLeanMassForPeriod(fitness, _trendPeriod.backward());
    final leanMassChange = periodLeanMass != null && prevLeanMass != null
        ? periodLeanMass - prevLeanMass
        : null;

    final periodBodyWater = _averageBodyWaterForPeriod(fitness, _trendPeriod);
    final prevBodyWater =
        _averageBodyWaterForPeriod(fitness, _trendPeriod.backward());
    final bodyWaterChange = periodBodyWater != null && prevBodyWater != null
        ? periodBodyWater - prevBodyWater
        : null;

    final prevLabel = _previousPeriodLabel(context, _trendPeriod.range);

    return SwipePeriodGesture(
      onPrev: () => setState(() => _trendPeriod = _trendPeriod.backward()),
      onNext: _trendPeriod.canGoForward
          ? () => setState(() => _trendPeriod = _trendPeriod.forward())
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        StatCard(
          icon: '\u2696',
          label: l10n.weightTitle,
          domain: Tokens.weight,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.weight,
          ),
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            StatStat(
              value: current?.toStringAsFixed(1) ?? '--',
              label: l10n.bodyCurrentWeight,
              unit: 'kg',
            ),
            StatStat(
              value: latestChange != null
                  ? '${latestChange >= 0 ? '+' : ''}${latestChange.toStringAsFixed(1)}'
                  : '--',
              label: l10n.weightVsPrevMeasure,
              unit: 'kg',
            ),
            StatStat(
              value: target.toStringAsFixed(1),
              label: l10n.weightGoal,
              unit: 'kg',
            ),
          ],
        ),
        const SizedBox(height: 10),
        PeriodNavigator(
          domain: Tokens.weight,
          tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
          activeTab: _rangeLabel(context, _trendPeriod.range),
          onTabChange: _changeRange,
          dateLabel: _dateLabel(context, _trendPeriod),
          canGoForward: _trendPeriod.canGoForward,
          isCurrentPeriod: _trendPeriod.isCurrentPeriod,
          onPrev: () =>
              setState(() => _trendPeriod = _trendPeriod.backward()),
          onNext: _trendPeriod.canGoForward
              ? () => setState(() => _trendPeriod = _trendPeriod.forward())
              : null,
          onToday: _trendPeriod.isCurrentPeriod
              ? null
              : () => setState(() =>
                  _trendPeriod = _BodyPeriod.current(_trendPeriod.range)),
        ),
        const SizedBox(height: 10),
        _BodyMetricTrendCard(
          cardId: 'weight',
          title: l10n.bodyWeightTrend,
          icon: Icons.show_chart,
          domain: Tokens.weight,
          expanded: _expandedMetricCards.contains('weight'),
          onToggle: _toggleMetricCard,
          range: _trendPeriod.range,
          dateLabel: _dateLabel(context, _trendPeriod),
          emptyLabel: l10n.bodyNoData,
          metrics: [
            _MetricTileData(
              label: l10n.weightAverage,
              value: periodAverage != null
                  ? '${periodAverage.toStringAsFixed(1)} kg'
                  : '--',
            ),
            _MetricTileData(
              label: prevLabel,
              value: averageChange != null
                  ? '${averageChange >= 0 ? '+' : ''}${averageChange.toStringAsFixed(1)} kg'
                  : '--',
              color: _trendColor(averageChange, current, target),
            ),
            _MetricTileData(
              label: l10n.weightGoal,
              value: '${target.toStringAsFixed(1)} kg',
            ),
          ],
          bars: [for (final item in chartData) item.bar],
          referenceValue: target,
          referenceLabel: l10n.weightGoal,
          showTrendLine: false,
          onBarTap: (index) {
            setState(() => _trendPeriod = chartData[index].period);
          },
        ),
        if (latestBodyFat != null) ...[
          const SizedBox(height: 10),
          _BodyMetricTrendCard(
            cardId: 'bodyFat',
            title: l10n.weightBodyFat,
            icon: Icons.percent_rounded,
            domain: Tokens.carbs,
            expanded: _expandedMetricCards.contains('bodyFat'),
            onToggle: _toggleMetricCard,
            range: _trendPeriod.range,
              dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.bodyNoData,
            showEmptyLabel: false,
            metrics: [
              _MetricTileData(
                label: l10n.weightAverage,
                value: periodBodyFat != null
                    ? '${periodBodyFat.toStringAsFixed(1)} %'
                    : '--',
                color: Tokens.carbs.color,
              ),
              _MetricTileData(
                label: prevLabel,
                value: bodyFatChange != null
                    ? '${bodyFatChange >= 0 ? '+' : ''}${bodyFatChange.toStringAsFixed(1)} %'
                    : '--',
                color: bodyFatChange != null
                    ? bodyFatChange <= 0
                        ? Tokens.carbs.color
                        : Tokens.danger
                    : null,
              ),
            ],
            bars: [for (final item in bodyFatData) item.bar],
            showTrendLine: false,
            onBarTap: (index) {
              setState(() => _trendPeriod = bodyFatData[index].period);
            },
          ),
        ],
        if (currentLeanMass != null) ...[
          const SizedBox(height: 10),
          _BodyMetricTrendCard(
            cardId: 'leanMass',
            title: l10n.weightLeanMass,
            icon: Icons.fitness_center_rounded,
            domain: Tokens.active,
            expanded: _expandedMetricCards.contains('leanMass'),
            onToggle: _toggleMetricCard,
            range: _trendPeriod.range,
              dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.bodyNoData,
            showEmptyLabel: false,
            metrics: [
              _MetricTileData(
                label: l10n.weightAverage,
                value: periodLeanMass != null
                    ? '${periodLeanMass.toStringAsFixed(1)} kg'
                    : '--',
                color: Tokens.active.color,
              ),
              _MetricTileData(
                label: prevLabel,
                value: leanMassChange != null
                    ? '${leanMassChange >= 0 ? '+' : ''}${leanMassChange.toStringAsFixed(1)} kg'
                    : '--',
                color: leanMassChange != null
                    ? leanMassChange >= 0
                        ? Tokens.active.color
                        : Tokens.danger
                    : null,
              ),
            ],
            bars: [for (final item in leanMassData) item.bar],
            showTrendLine: false,
            onBarTap: (index) {
              setState(() => _trendPeriod = leanMassData[index].period);
            },
          ),
        ],
        if (bodyWaterData.isNotEmpty) ...[
          const SizedBox(height: 10),
          _BodyMetricTrendCard(
            cardId: 'bodyWater',
            title: l10n.weightBodyWater,
            icon: Icons.water_drop_rounded,
            domain: Tokens.sleep,
            expanded: _expandedMetricCards.contains('bodyWater'),
            onToggle: _toggleMetricCard,
            range: _trendPeriod.range,
              dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.bodyNoData,
            showEmptyLabel: false,
            metrics: [
              _MetricTileData(
                label: l10n.weightAverage,
                value: periodBodyWater != null
                    ? '${periodBodyWater.toStringAsFixed(1)} kg'
                    : '--',
                color: Tokens.sleep.color,
              ),
              _MetricTileData(
                label: prevLabel,
                value: bodyWaterChange != null
                    ? '${bodyWaterChange >= 0 ? '+' : ''}${bodyWaterChange.toStringAsFixed(1)} kg'
                    : '--',
                color: bodyWaterChange != null
                    ? bodyWaterChange >= 0
                        ? Tokens.sleep.color
                        : Tokens.danger
                    : null,
              ),
            ],
            bars: [for (final item in bodyWaterData) item.bar],
            showTrendLine: false,
            onBarTap: (index) {
              setState(() => _trendPeriod = bodyWaterData[index].period);
            },
          ),
        ],
        ],
      ),
    );
  }

  void _toggleMetricCard(String cardId) {
    setState(() {
      if (!_expandedMetricCards.add(cardId)) {
        _expandedMetricCards.remove(cardId);
      }
    });
  }

  String _previousPeriodLabel(BuildContext context, _BodyRange range) {
    final l10n = context.l10n;
    return switch (range) {
      _BodyRange.day => l10n.weightVsPrevMeasure,
      _BodyRange.week => l10n.weightVsPrevWeek,
      _BodyRange.month => l10n.weightVsPrevMonth,
    };
  }

  Color? _trendColor(double? change, double? current, double target) {
    if (change == null || current == null) return null;
    final goalingDown = current >= target;
    final isGood = goalingDown ? change <= 0 : change >= 0;
    return isGood ? Tokens.weight.color : Tokens.danger;
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => fitness.refresh(),
          color: Tokens.accent,
          backgroundColor: Tokens.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      ScreenHeader(
                        greeting: '',
                        title: context.l10n.screenBody,
                        leading: Navigator.of(context).canPop()
                            ? const FtBackButton()
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  child: _buildRangeContent(context, fitness, goals),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTileData {
  const _MetricTileData({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;
}

class _BodyMetricTrendCard extends StatelessWidget {
  const _BodyMetricTrendCard({
    required this.cardId,
    required this.title,
    required this.icon,
    required this.domain,
    required this.expanded,
    required this.onToggle,
    required this.range,
    required this.dateLabel,
    required this.emptyLabel,
    this.showEmptyLabel = true,
    required this.metrics,
    required this.bars,
    this.referenceValue,
    this.referenceLabel,
    this.onBarTap,
    this.showTrendLine = false,
  });

  final String cardId;
  final String title;
  final IconData icon;
  final Domain domain;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final _BodyRange range;
  final String dateLabel;
  final String emptyLabel;
  final bool showEmptyLabel;
  final List<_MetricTileData> metrics;
  final List<ChartBar> bars;
  final double? referenceValue;
  final String? referenceLabel;
  final ValueChanged<int>? onBarTap;
  final bool showTrendLine;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return GestureDetector(
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
                    boxShadow: [
                      BoxShadow(
                        color: domain.glow.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: domain.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
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
                child: _ExpandedMetricBody(
                  metrics: metrics,
                  bars: bars,
                  domain: domain,
                  emptyLabel: emptyLabel,
                  showEmptyLabel: showEmptyLabel,
                  referenceValue: referenceValue,
                  referenceLabel: referenceLabel,
                  onBarTap: onBarTap,
                  showTrendLine: showTrendLine,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedMetricBody extends StatefulWidget {
  const _ExpandedMetricBody({
    required this.metrics,
    required this.bars,
    required this.domain,
    required this.emptyLabel,
    required this.showTrendLine,
    this.showEmptyLabel = true,
    this.referenceValue,
    this.referenceLabel,
    this.onBarTap,
  });

  final List<_MetricTileData> metrics;
  final List<ChartBar> bars;
  final Domain domain;
  final String emptyLabel;
  final bool showEmptyLabel;
  final double? referenceValue;
  final String? referenceLabel;
  final ValueChanged<int>? onBarTap;
  final bool showTrendLine;

  @override
  State<_ExpandedMetricBody> createState() => _ExpandedMetricBodyState();
}

class _ExpandedMetricBodyState extends State<_ExpandedMetricBody> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(_ExpandedMetricBody old) {
    super.didUpdateWidget(old);
    if (old.bars.length != widget.bars.length) {
      _scheduleScrollToEnd();
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _scheduleScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients && _sc.position.maxScrollExtent > 0) {
        _sc.jumpTo(_sc.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Tokens.spaceMd),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            for (final metric in widget.metrics)
              _CompositionMetric(
                label: metric.label,
                value: metric.value,
                color: metric.color ?? widget.domain.color,
              ),
          ],
        ),
        const SizedBox(height: Tokens.spaceMd),
        if (widget.bars.isEmpty && widget.showEmptyLabel)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                widget.emptyLabel,
                style: TextStyle(fontSize: 13, color: ft.onSurfaceMuted),
              ),
            ),
          )
        else if (widget.bars.isNotEmpty) ...[
          LayoutBuilder(
            builder: (ctx, constraints) {
              const minBarW = 34.0;
              const gapW = 5.0;
              final n = widget.bars.length;
              final naturalW = n * minBarW + (n - 1) * gapW;
              final chartW = naturalW > constraints.maxWidth
                  ? naturalW
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _sc,
                child: SizedBox(
                  width: chartW,
                  child: TrendChart(
                    bars: widget.bars,
                    domain: widget.domain,
                    height: 188,
                    relativeScale: true,
                    referenceValue: widget.referenceValue,
                    onBarTap: widget.onBarTap,
                    showTrendLine: widget.showTrendLine,
                  ),
                ),
              );
            },
          ),
          if (widget.referenceValue != null &&
              widget.referenceLabel != null) ...[
            const SizedBox(height: 10),
            _WeightReferencePill(
              label:
                  '${widget.referenceLabel} ${_formatMetricValue(widget.referenceValue!)}',
              color: widget.domain.color,
            ),
          ],
        ],
      ],
    );
  }

  String _formatMetricValue(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _CompositionMetric extends StatelessWidget {
  const _CompositionMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: ft.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color ?? Tokens.weight.color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightReferencePill extends StatelessWidget {
  const _WeightReferencePill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 2,
            color: color.withValues(alpha: 0.45),
          ),
          const SizedBox(width: Tokens.spaceSm),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w600,
              color: ft.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
