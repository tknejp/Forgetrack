import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/fitness_provider.dart';
import '../domain/sleep_record.dart';
import 'sleep/widgets/sleep_metric_trend_card.dart';
import 'widgets/hc_status_indicators.dart';
import 'sleep/widgets/sleep_period.dart';
import 'sleep/widgets/stage_breakdown_card.dart';
import 'sleep/widgets/stage_colors.dart';
import 'sleep/widgets/stage_timeline_card.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  SleepPeriod _trendPeriod = SleepPeriod.current(SleepRange.week);
  final Set<String> _expandedCards = {'stages', 'breakdown', 'duration'};

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _stageLabel(BuildContext context, SleepStage stage) {
    final l10n = context.l10n;
    return switch (stage) {
      SleepStage.deep => l10n.sleepStageDeep,
      SleepStage.light => l10n.sleepStageLight,
      SleepStage.rem => l10n.sleepStageRem,
      SleepStage.awake => l10n.sleepStageAwake,
    };
  }

  String _formatDuration(Duration? d) {
    if (d == null || d == Duration.zero) return '--';
    final h = d.inHours;
    final m = d.inMinutes - h * 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _formatHours(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes - h * 60).round();
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _previousPeriodLabel(BuildContext context, SleepRange range) {
    final l10n = context.l10n;
    return switch (range) {
      SleepRange.day => l10n.weightVsPrevMeasure,
      SleepRange.week => l10n.weightVsPrevWeek,
      SleepRange.month => l10n.weightVsPrevMonth,
    };
  }

  String _rangeLabel(BuildContext context, SleepRange range) {
    final l10n = context.l10n;
    return switch (range) {
      SleepRange.day => l10n.periodDay,
      SleepRange.week => l10n.periodWeek,
      SleepRange.month => l10n.periodMonth,
    };
  }

  String _dateLabel(BuildContext context, SleepPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    return switch (period.range) {
      SleepRange.day => DateFormat('d MMM', locale).format(period.start),
      SleepRange.week =>
        '${DateFormat('d MMM', locale).format(period.start)} – '
            '${DateFormat('d MMM', locale).format(period.displayEnd)}',
      SleepRange.month => DateFormat.yMMMM(locale).format(period.start),
    };
  }

  String _barLabel(String locale, SleepPeriod period) {
    return switch (period.range) {
      SleepRange.day => DateFormat('d.M.', locale).format(period.start),
      SleepRange.week => DateFormat('d.M.', locale).format(period.start),
      SleepRange.month => DateFormat.MMM(locale).format(period.start),
    };
  }

  SleepPeriod _periodForDate(SleepRange range, DateTime date) {
    return SleepPeriod(
      range: range,
      referenceDate: DateTime(date.year, date.month, date.day),
    );
  }

  void _changeRange(String tabLabel) {
    final l10n = context.l10n;
    final next = tabLabel == l10n.periodDay
        ? SleepRange.day
        : tabLabel == l10n.periodWeek
            ? SleepRange.week
            : SleepRange.month;
    setState(() => _trendPeriod = _trendPeriod.withRange(next));
  }

  void _toggleCard(String id) {
    setState(() {
      if (!_expandedCards.add(id)) _expandedCards.remove(id);
    });
  }

  // ─── Aggregation: minutes per period ─────────────────────────────────────

  Iterable<SleepRecord> _recordsInPeriod(
    FitnessProvider fitness,
    SleepPeriod period,
  ) {
    return fitness.sleepHistory.where( // lint-ignore: widget-no-logic — UI date-range slice driven by on-screen period selector
      (r) =>
          !r.wakeTime.isBefore(period.start) &&
          !r.wakeTime.isAfter(_endOfDay(period.end)),
    );
  }

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  double? _avgMinutesForPeriod(
    FitnessProvider fitness,
    SleepPeriod period,
    Duration Function(SleepRecord) selector,
  ) {
    final records = _recordsInPeriod(fitness, period).toList();
    if (records.isEmpty) return null;
    final total = records.fold<int>(0, (s, r) => s + selector(r).inMinutes);
    return total / records.length;
  }

  /// One bar per period that has at least one sleep record. The value is the
  /// extracted stat (minutes), averaged across nights for week / month modes.
  List<SleepPeriodBar> _buildBarsBy(
    BuildContext context,
    FitnessProvider fitness,
    SleepPeriod selected,
    Duration Function(SleepRecord) selector,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final groups = <DateTime, List<int>>{};
    final periodForKey = <DateTime, SleepPeriod>{};

    for (final record in fitness.sleepHistory) {
      final period = _periodForDate(selected.range, record.wakeTime);
      groups.putIfAbsent(period.start, () => []).add(selector(record).inMinutes);
      periodForKey[period.start] = period;
    }

    return groups.entries.map((entry) {
      final period = periodForKey[entry.key]!;
      final values = entry.value;
      final value = selected.range == SleepRange.day
          ? values.last.toDouble()
          : values.fold<int>(0, (s, v) => s + v) / values.length;
      return SleepPeriodBar(
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

  // ─── Stage breakdown for the selected period ─────────────────────────────

  Map<SleepStage, Duration> _stageBreakdownForPeriod(
    FitnessProvider fitness,
    SleepPeriod period,
  ) {
    final records =
        _recordsInPeriod(fitness, period).where((r) => r.hasStageData).toList(); // lint-ignore: widget-no-logic — drops records missing stage telemetry for stage-breakdown chart
    if (records.isEmpty) {
      return const {
        SleepStage.deep: Duration.zero,
        SleepStage.light: Duration.zero,
        SleepStage.rem: Duration.zero,
        SleepStage.awake: Duration.zero,
      };
    }
    int sumFor(SleepStage stage) =>
        records.fold(0, (s, r) => s + r.durationFor(stage).inMinutes);
    final n = records.length;
    return {
      SleepStage.deep: Duration(minutes: sumFor(SleepStage.deep) ~/ n),
      SleepStage.light: Duration(minutes: sumFor(SleepStage.light) ~/ n),
      SleepStage.rem: Duration(minutes: sumFor(SleepStage.rem) ~/ n),
      SleepStage.awake: Duration(minutes: sumFor(SleepStage.awake) ~/ n),
    };
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final lastNight = fitness.todaySleep ??
        (fitness.sleepHistory.isNotEmpty ? fitness.sleepHistory.first : null);

    // ── StatCard data ───────────────────────────────────────────────────────
    final lastDuration = lastNight?.totalDuration;
    final lastBedtime = lastNight != null
        ? DateFormat('HH:mm', locale).format(lastNight.sleepStart)
        : '--:--';
    final lastWake = lastNight != null
        ? DateFormat('HH:mm', locale).format(lastNight.wakeTime)
        : '--:--';
    final goalMinutes = goals.sleepHours * 60;
    final progress = lastDuration != null
        ? (lastDuration.inMinutes / goalMinutes).clamp(0.0, 1.0)
        : 0.0;

    // ── Trend bars ──────────────────────────────────────────────────────────
    final totalBars = _buildBarsBy(
      context,
      fitness,
      _trendPeriod,
      (r) => r.totalDuration,
    );
    final deepBars = _buildBarsBy(
      context,
      fitness,
      _trendPeriod,
      (r) => r.deepDuration,
    );
    final remBars = _buildBarsBy(
      context,
      fitness,
      _trendPeriod,
      (r) => r.remDuration,
    );

    // ── Period averages (current vs previous) ───────────────────────────────
    final avgTotal =
        _avgMinutesForPeriod(fitness, _trendPeriod, (r) => r.totalDuration);
    final prevTotal = _avgMinutesForPeriod(
        fitness, _trendPeriod.backward(), (r) => r.totalDuration);
    final totalChange =
        avgTotal != null && prevTotal != null ? avgTotal - prevTotal : null;

    final avgDeep =
        _avgMinutesForPeriod(fitness, _trendPeriod, (r) => r.deepDuration);
    final prevDeep = _avgMinutesForPeriod(
        fitness, _trendPeriod.backward(), (r) => r.deepDuration);
    final deepChange =
        avgDeep != null && prevDeep != null ? avgDeep - prevDeep : null;

    final avgRem =
        _avgMinutesForPeriod(fitness, _trendPeriod, (r) => r.remDuration);
    final prevRem = _avgMinutesForPeriod(
        fitness, _trendPeriod.backward(), (r) => r.remDuration);
    final remChange = avgRem != null && prevRem != null ? avgRem - prevRem : null;

    final prevLabel = _previousPeriodLabel(context, _trendPeriod.range);

    // ── Stage breakdown for the selected period ─────────────────────────────
    final breakdown = _stageBreakdownForPeriod(fitness, _trendPeriod);
    final hasBreakdownData =
        breakdown.values.any((d) => d > Duration.zero);

    // ── Selected-night data for the timeline (day mode only) ───────────────
    final selectedNight = _trendPeriod.range == SleepRange.day
        ? fitness.sleepForDate(_trendPeriod.referenceDate)
        : null;

    return SwipePeriodGesture(
      onPrev: () => setState(() => _trendPeriod = _trendPeriod.backward()),
      onNext: _trendPeriod.canGoForward
          ? () => setState(() => _trendPeriod = _trendPeriod.forward())
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        StatCard(
          icon: '🌙',
          label: l10n.sleepTitle,
          domain: Tokens.sleep,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.sleep,
          ),
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            StatStat(
              value: _formatDuration(lastDuration),
              label: l10n.sleepDuration,
            ),
            StatStat(value: lastBedtime, label: l10n.sleepFellAsleep),
            StatStat(value: lastWake, label: l10n.sleepWokeUp),
          ],
          progress: progress,
          badge: lastDuration != null ? '${(progress * 100).round()}%' : null,
        ),

        // ── Period navigator + range tabs combined ────────────────────────
        const SizedBox(height: 10),
        PeriodNavigator(
          domain: Tokens.sleep,
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
              : () => setState(
                  () => _trendPeriod = SleepPeriod.current(_trendPeriod.range)),
        ),

        // ── Sleep duration trend (top trend card, drives the period view) ──
        const SizedBox(height: 10),
        SleepMetricTrendCard(
          cardId: 'duration',
          title: l10n.sleepDurationTrend,
          icon: Icons.bedtime_rounded,
          domain: Tokens.sleep,
          expanded: _expandedCards.contains('duration'),
          onToggle: _toggleCard,
          dateLabel: _dateLabel(context, _trendPeriod),
          emptyLabel: l10n.sleepNoData,
          metrics: [
            SleepMetricTileData(
              label: l10n.weightAverage,
              value: avgTotal != null ? _formatHours(avgTotal) : '--',
            ),
            SleepMetricTileData(
              label: prevLabel,
              value: totalChange != null
                  ? '${totalChange >= 0 ? '+' : '-'}'
                      '${_formatHours(totalChange.abs())}'
                  : '--',
              color: totalChange == null
                  ? null
                  : totalChange >= 0
                      ? Tokens.sleep.color
                      : Tokens.danger,
            ),
            SleepMetricTileData(
              label: l10n.weightGoal,
              value: '${goals.sleepHours.toStringAsFixed(1)} h',
            ),
          ],
          bars: [for (final b in totalBars) b.bar],
          referenceValue: goalMinutes.toDouble(),
          referenceLabel: l10n.weightGoal,
          unitFormatter: (v) => _formatHours(v),
          onBarTap: (i) => setState(() => _trendPeriod = totalBars[i].period),
        ),

        // ── Stage timeline (day mode only) ────────────────────────────────
        if (_trendPeriod.range == SleepRange.day) ...[
          const SizedBox(height: 10),
          StageTimelineCard(
            cardId: 'stages',
            expanded: _expandedCards.contains('stages'),
            onToggle: _toggleCard,
            night: selectedNight,
            dateLabel: _dateLabel(context, _trendPeriod),
            stageNameOf: (s) => _stageLabel(context, s),
            emptyLabel: selectedNight == null
                ? l10n.sleepNoData
                : l10n.sleepNoStageData,
          ),
        ],

        // ── Stage breakdown (always visible if any stage data exists) ─────
        const SizedBox(height: 10),
        StageBreakdownCard(
          cardId: 'breakdown',
          expanded: _expandedCards.contains('breakdown'),
          onToggle: _toggleCard,
          dateLabel: _dateLabel(context, _trendPeriod),
          breakdown: breakdown,
          hasData: hasBreakdownData,
          stageNameOf: (s) => _stageLabel(context, s),
          emptyLabel: l10n.sleepNoStageData,
          formatDuration: _formatDuration,
        ),

        if (deepBars.isNotEmpty) ...[
          const SizedBox(height: 10),
          SleepMetricTrendCard(
            cardId: 'deep',
            title: l10n.sleepDeepTrend,
            icon: Icons.dark_mode_rounded,
            domain: Tokens.sleep,
            stageColor: StageColors.deep,
            expanded: _expandedCards.contains('deep'),
            onToggle: _toggleCard,
            dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.sleepNoStageData,
            showEmptyLabel: false,
            metrics: [
              SleepMetricTileData(
                label: l10n.weightAverage,
                value: avgDeep != null ? _formatHours(avgDeep) : '--',
                color: StageColors.deep,
              ),
              SleepMetricTileData(
                label: prevLabel,
                value: deepChange != null
                    ? '${deepChange >= 0 ? '+' : '-'}'
                        '${_formatHours(deepChange.abs())}'
                    : '--',
                color: deepChange == null
                    ? null
                    : deepChange >= 0
                        ? StageColors.deep
                        : Tokens.danger,
              ),
            ],
            bars: [for (final b in deepBars) b.bar],
            unitFormatter: (v) => _formatHours(v),
            onBarTap: (i) => setState(() => _trendPeriod = deepBars[i].period),
          ),
        ],

        if (remBars.isNotEmpty) ...[
          const SizedBox(height: 10),
          SleepMetricTrendCard(
            cardId: 'rem',
            title: l10n.sleepRemTrend,
            icon: Icons.bubble_chart_rounded,
            domain: Tokens.sleep,
            stageColor: StageColors.rem,
            expanded: _expandedCards.contains('rem'),
            onToggle: _toggleCard,
            dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.sleepNoStageData,
            showEmptyLabel: false,
            metrics: [
              SleepMetricTileData(
                label: l10n.weightAverage,
                value: avgRem != null ? _formatHours(avgRem) : '--',
                color: StageColors.rem,
              ),
              SleepMetricTileData(
                label: prevLabel,
                value: remChange != null
                    ? '${remChange >= 0 ? '+' : '-'}'
                        '${_formatHours(remChange.abs())}'
                    : '--',
                color: remChange == null
                    ? null
                    : remChange >= 0
                        ? StageColors.rem
                        : Tokens.danger,
              ),
            ],
            bars: [for (final b in remBars) b.bar],
            unitFormatter: (v) => _formatHours(v),
            onBarTap: (i) => setState(() => _trendPeriod = remBars[i].period),
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
                        title: context.l10n.sleepTitle,
                        leading: Navigator.of(context).canPop()
                            ? const FtBackButton()
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (HcStatusBanner.isActive(fitness))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: HcStatusBanner(fitness: fitness),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  child: _buildContent(context, fitness, goals),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
