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
import '../application/fitness_provider.dart';
import 'body/widgets/body_metric_helpers.dart';
import 'body/widgets/body_metric_trend_card.dart';
import 'body/widgets/body_period.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  BodyPeriod _trendPeriod = BodyPeriod.current(BodyRange.week);
  final Set<String> _expandedMetricCards = {'weight'};

  String _dateLabel(BuildContext context, BodyPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    return switch (period.range) {
      BodyRange.day => DateFormat('d MMM', locale).format(period.start),
      BodyRange.week =>
        '${DateFormat('d MMM', locale).format(period.start)} – '
            '${DateFormat('d MMM', locale).format(period.displayEnd)}',
      BodyRange.month => DateFormat.yMMMM(locale).format(period.start),
    };
  }

  String _rangeLabel(BuildContext context, BodyRange range) {
    final l10n = context.l10n;
    return switch (range) {
      BodyRange.day => l10n.periodDay,
      BodyRange.week => l10n.periodWeek,
      BodyRange.month => l10n.periodMonth,
    };
  }

  void _changeRange(String tabLabel) {
    final l10n = context.l10n;
    final nextRange = tabLabel == l10n.periodDay
        ? BodyRange.day
        : tabLabel == l10n.periodWeek
            ? BodyRange.week
            : BodyRange.month;
    setState(() => _trendPeriod = _trendPeriod.withRange(nextRange));
  }

  void _toggleMetricCard(String cardId) {
    setState(() {
      if (!_expandedMetricCards.add(cardId)) {
        _expandedMetricCards.remove(cardId);
      }
    });
  }

  String _previousPeriodLabel(BuildContext context, BodyRange range) {
    final l10n = context.l10n;
    return switch (range) {
      BodyRange.day => l10n.weightVsPrevMeasure,
      BodyRange.week => l10n.weightVsPrevWeek,
      BodyRange.month => l10n.weightVsPrevMonth,
    };
  }

  Color? _trendColor(double? change, double? current, double target) {
    if (change == null || current == null) return null;
    final goalingDown = current >= target;
    final isGood = goalingDown ? change <= 0 : change >= 0;
    return isGood ? Tokens.weight.color : Tokens.danger;
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
    final periodAverage = averageWeightForPeriod(fitness, _trendPeriod);
    final previousAverage =
        averageWeightForPeriod(fitness, _trendPeriod.backward());
    final averageChange = periodAverage != null && previousAverage != null
        ? periodAverage - previousAverage
        : null;
    final chartData = buildWeightBars(context, fitness, _trendPeriod);
    final latestBodyFat = fitness.latestBodyFat;
    final currentLeanMass = current != null && latestBodyFat != null
        ? current * (1 - latestBodyFat / 100)
        : null;
    final bodyFatData = buildBodyFatBars(context, fitness, _trendPeriod);
    final leanMassData = buildLeanMassBars(context, fitness, _trendPeriod);
    final bodyWaterData = buildBodyWaterBars(context, fitness, _trendPeriod);

    final periodBodyFat = averageBodyFatForPeriod(fitness, _trendPeriod);
    final prevBodyFat =
        averageBodyFatForPeriod(fitness, _trendPeriod.backward());
    final bodyFatChange = periodBodyFat != null && prevBodyFat != null
        ? periodBodyFat - prevBodyFat
        : null;

    final periodLeanMass = averageLeanMassForPeriod(fitness, _trendPeriod);
    final prevLeanMass =
        averageLeanMassForPeriod(fitness, _trendPeriod.backward());
    final leanMassChange = periodLeanMass != null && prevLeanMass != null
        ? periodLeanMass - prevLeanMass
        : null;

    final periodBodyWater = averageBodyWaterForPeriod(fitness, _trendPeriod);
    final prevBodyWater =
        averageBodyWaterForPeriod(fitness, _trendPeriod.backward());
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
            icon: '⚖',
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
                    _trendPeriod = BodyPeriod.current(_trendPeriod.range)),
          ),
          const SizedBox(height: 10),
          BodyMetricTrendCard(
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
              BodyMetricTileData(
                label: l10n.weightAverage,
                value: periodAverage != null
                    ? '${periodAverage.toStringAsFixed(1)} kg'
                    : '--',
              ),
              BodyMetricTileData(
                label: prevLabel,
                value: averageChange != null
                    ? '${averageChange >= 0 ? '+' : ''}${averageChange.toStringAsFixed(1)} kg'
                    : '--',
                color: _trendColor(averageChange, current, target),
              ),
              BodyMetricTileData(
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
            BodyMetricTrendCard(
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
                BodyMetricTileData(
                  label: l10n.weightAverage,
                  value: periodBodyFat != null
                      ? '${periodBodyFat.toStringAsFixed(1)} %'
                      : '--',
                  color: Tokens.carbs.color,
                ),
                BodyMetricTileData(
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
            BodyMetricTrendCard(
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
                BodyMetricTileData(
                  label: l10n.weightAverage,
                  value: periodLeanMass != null
                      ? '${periodLeanMass.toStringAsFixed(1)} kg'
                      : '--',
                  color: Tokens.active.color,
                ),
                BodyMetricTileData(
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
            BodyMetricTrendCard(
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
                BodyMetricTileData(
                  label: l10n.weightAverage,
                  value: periodBodyWater != null
                      ? '${periodBodyWater.toStringAsFixed(1)} kg'
                      : '--',
                  color: Tokens.sleep.color,
                ),
                BodyMetricTileData(
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
