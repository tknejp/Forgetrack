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

enum _SleepRange { day, week, month }

@immutable
class _SleepPeriod {
  const _SleepPeriod({
    required this.range,
    required this.referenceDate,
  });

  factory _SleepPeriod.current(_SleepRange range) {
    final now = DateTime.now();
    return _SleepPeriod(
      range: range,
      referenceDate: DateTime(now.year, now.month, now.day),
    );
  }

  final _SleepRange range;
  final DateTime referenceDate;

  DateTime get start => switch (range) {
        _SleepRange.day => referenceDate,
        _SleepRange.week =>
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1)),
        _SleepRange.month =>
          DateTime(referenceDate.year, referenceDate.month, 1),
      };

  DateTime get end {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodEnd = switch (range) {
      _SleepRange.day => referenceDate,
      _SleepRange.week => start.add(const Duration(days: 6)),
      _SleepRange.month =>
        DateTime(referenceDate.year, referenceDate.month + 1, 0),
    };
    return periodEnd.isAfter(today) ? today : periodEnd;
  }

  /// Full calendar end for display labels — never capped at today.
  DateTime get displayEnd => switch (range) {
        _SleepRange.day => referenceDate,
        _SleepRange.week => start.add(const Duration(days: 6)),
        _SleepRange.month =>
          DateTime(referenceDate.year, referenceDate.month + 1, 0),
      };

  bool get isCurrentPeriod {
    final current = _SleepPeriod.current(range);
    return start == current.start;
  }

  bool get canGoForward => !isCurrentPeriod;

  _SleepPeriod withRange(_SleepRange nextRange) =>
      _SleepPeriod.current(nextRange);

  _SleepPeriod backward() => shift(-1);

  _SleepPeriod forward() => canGoForward ? shift(1) : this;

  _SleepPeriod shift(int amount) => switch (range) {
        _SleepRange.day => _SleepPeriod(
            range: range,
            referenceDate: referenceDate.add(Duration(days: amount)),
          ),
        _SleepRange.week => _SleepPeriod(
            range: range,
            referenceDate: referenceDate.add(Duration(days: 7 * amount)),
          ),
        _SleepRange.month => _SleepPeriod(
            range: range,
            referenceDate: DateTime(
              referenceDate.year,
              referenceDate.month + amount,
              1,
            ),
          ),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SleepPeriod && range == other.range && start == other.start;

  @override
  int get hashCode => Object.hash(range, start);
}

class _SleepPeriodBar {
  const _SleepPeriodBar({required this.period, required this.bar});
  final _SleepPeriod period;
  final ChartBar bar;
}

// ─── Stage colors ───────────────────────────────────────────────────────────
// Picked to read at a glance: deep = dark blue, light = mid, REM = cyan accent,
// awake = warm so it stands out from the cool-toned sleep palette.
class _StageColors {
  static const deep = Color(0xFF1F3F8A);
  static const light = Color(0xFF4F7BD9);
  static const rem = Color(0xFF66C2E0);
  static const awake = Color(0xFFFF8A4C);

  static Color of(SleepStage stage) => switch (stage) {
        SleepStage.deep => deep,
        SleepStage.light => light,
        SleepStage.rem => rem,
        SleepStage.awake => awake,
      };
}

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  _SleepPeriod _trendPeriod = _SleepPeriod.current(_SleepRange.week);
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

  String _previousPeriodLabel(BuildContext context, _SleepRange range) {
    final l10n = context.l10n;
    return switch (range) {
      _SleepRange.day => l10n.weightVsPrevMeasure,
      _SleepRange.week => l10n.weightVsPrevWeek,
      _SleepRange.month => l10n.weightVsPrevMonth,
    };
  }

  String _rangeLabel(BuildContext context, _SleepRange range) {
    final l10n = context.l10n;
    return switch (range) {
      _SleepRange.day => l10n.periodDay,
      _SleepRange.week => l10n.periodWeek,
      _SleepRange.month => l10n.periodMonth,
    };
  }

  String _dateLabel(BuildContext context, _SleepPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    return switch (period.range) {
      _SleepRange.day => DateFormat('d MMM', locale).format(period.start),
      _SleepRange.week =>
        '${DateFormat('d MMM', locale).format(period.start)} – '
            '${DateFormat('d MMM', locale).format(period.displayEnd)}',
      _SleepRange.month => DateFormat.yMMMM(locale).format(period.start),
    };
  }

  String _barLabel(String locale, _SleepPeriod period) {
    return switch (period.range) {
      _SleepRange.day => DateFormat('d.M.', locale).format(period.start),
      _SleepRange.week => DateFormat('d.M.', locale).format(period.start),
      _SleepRange.month => DateFormat.MMM(locale).format(period.start),
    };
  }

  _SleepPeriod _periodForDate(_SleepRange range, DateTime date) {
    return _SleepPeriod(
      range: range,
      referenceDate: DateTime(date.year, date.month, date.day),
    );
  }

  void _changeRange(String tabLabel) {
    final l10n = context.l10n;
    final next = tabLabel == l10n.periodDay
        ? _SleepRange.day
        : tabLabel == l10n.periodWeek
            ? _SleepRange.week
            : _SleepRange.month;
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
    _SleepPeriod period,
  ) {
    return fitness.sleepHistory.where(
      (r) =>
          !r.wakeTime.isBefore(period.start) &&
          !r.wakeTime.isAfter(_endOfDay(period.end)),
    );
  }

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  double? _avgMinutesForPeriod(
    FitnessProvider fitness,
    _SleepPeriod period,
    Duration Function(SleepRecord) selector,
  ) {
    final records = _recordsInPeriod(fitness, period).toList();
    if (records.isEmpty) return null;
    final total = records.fold<int>(0, (s, r) => s + selector(r).inMinutes);
    return total / records.length;
  }

  /// One bar per period that has at least one sleep record. The value is the
  /// extracted stat (minutes), averaged across nights for week / month modes.
  List<_SleepPeriodBar> _buildBarsBy(
    BuildContext context,
    FitnessProvider fitness,
    _SleepPeriod selected,
    Duration Function(SleepRecord) selector,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final groups = <DateTime, List<int>>{};
    final periodForKey = <DateTime, _SleepPeriod>{};

    for (final record in fitness.sleepHistory) {
      final period = _periodForDate(selected.range, record.wakeTime);
      groups.putIfAbsent(period.start, () => []).add(selector(record).inMinutes);
      periodForKey[period.start] = period;
    }

    return groups.entries.map((entry) {
      final period = periodForKey[entry.key]!;
      final values = entry.value;
      final value = selected.range == _SleepRange.day
          ? values.last.toDouble()
          : values.fold<int>(0, (s, v) => s + v) / values.length;
      return _SleepPeriodBar(
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
    _SleepPeriod period,
  ) {
    final records =
        _recordsInPeriod(fitness, period).where((r) => r.hasStageData).toList();
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
    final selectedNight = _trendPeriod.range == _SleepRange.day
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
                  () => _trendPeriod = _SleepPeriod.current(_trendPeriod.range)),
        ),

        // ── Sleep duration trend (top trend card, drives the period view) ──
        const SizedBox(height: 10),
        _SleepMetricTrendCard(
          cardId: 'duration',
          title: l10n.sleepDurationTrend,
          icon: Icons.bedtime_rounded,
          domain: Tokens.sleep,
          expanded: _expandedCards.contains('duration'),
          onToggle: _toggleCard,
          range: _trendPeriod.range,
          dateLabel: _dateLabel(context, _trendPeriod),
          emptyLabel: l10n.sleepNoData,
          metrics: [
            _MetricTileData(
              label: l10n.weightAverage,
              value: avgTotal != null ? _formatHours(avgTotal) : '--',
            ),
            _MetricTileData(
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
            _MetricTileData(
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
        if (_trendPeriod.range == _SleepRange.day) ...[
          const SizedBox(height: 10),
          _StageTimelineCard(
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
        _StageBreakdownCard(
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
          _SleepMetricTrendCard(
            cardId: 'deep',
            title: l10n.sleepDeepTrend,
            icon: Icons.dark_mode_rounded,
            domain: Tokens.sleep,
            stageColor: _StageColors.deep,
            expanded: _expandedCards.contains('deep'),
            onToggle: _toggleCard,
            range: _trendPeriod.range,
            dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.sleepNoStageData,
            showEmptyLabel: false,
            metrics: [
              _MetricTileData(
                label: l10n.weightAverage,
                value: avgDeep != null ? _formatHours(avgDeep) : '--',
                color: _StageColors.deep,
              ),
              _MetricTileData(
                label: prevLabel,
                value: deepChange != null
                    ? '${deepChange >= 0 ? '+' : '-'}'
                        '${_formatHours(deepChange.abs())}'
                    : '--',
                color: deepChange == null
                    ? null
                    : deepChange >= 0
                        ? _StageColors.deep
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
          _SleepMetricTrendCard(
            cardId: 'rem',
            title: l10n.sleepRemTrend,
            icon: Icons.bubble_chart_rounded,
            domain: Tokens.sleep,
            stageColor: _StageColors.rem,
            expanded: _expandedCards.contains('rem'),
            onToggle: _toggleCard,
            range: _trendPeriod.range,
            dateLabel: _dateLabel(context, _trendPeriod),
            emptyLabel: l10n.sleepNoStageData,
            showEmptyLabel: false,
            metrics: [
              _MetricTileData(
                label: l10n.weightAverage,
                value: avgRem != null ? _formatHours(avgRem) : '--',
                color: _StageColors.rem,
              ),
              _MetricTileData(
                label: prevLabel,
                value: remChange != null
                    ? '${remChange >= 0 ? '+' : '-'}'
                        '${_formatHours(remChange.abs())}'
                    : '--',
                color: remChange == null
                    ? null
                    : remChange >= 0
                        ? _StageColors.rem
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

class _MetricTileData {
  const _MetricTileData({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
}

// ─── Trend card (mirrors body_screen's _BodyMetricTrendCard) ────────────────

class _SleepMetricTrendCard extends StatelessWidget {
  const _SleepMetricTrendCard({
    required this.cardId,
    required this.title,
    required this.icon,
    required this.domain,
    required this.expanded,
    required this.onToggle,
    required this.range,
    required this.dateLabel,
    required this.emptyLabel,
    required this.metrics,
    required this.bars,
    this.stageColor,
    this.showEmptyLabel = true,
    this.referenceValue,
    this.referenceLabel,
    this.onBarTap,
    this.unitFormatter,
  });

  final String cardId;
  final String title;
  final IconData icon;
  final Domain domain;
  final Color? stageColor;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final _SleepRange range;
  final String dateLabel;
  final String emptyLabel;
  final bool showEmptyLabel;
  final List<_MetricTileData> metrics;
  final List<ChartBar> bars;
  final double? referenceValue;
  final String? referenceLabel;
  final ValueChanged<int>? onBarTap;
  final String Function(double)? unitFormatter;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final accent = stageColor ?? domain.color;

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
                      color: accent.withValues(alpha: 0.27),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: domain.glow.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: accent),
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
                child: _ExpandedSleepBody(
                  range: range,
                  metrics: metrics,
                  bars: bars,
                  domain: domain,
                  accent: accent,
                  emptyLabel: emptyLabel,
                  showEmptyLabel: showEmptyLabel,
                  referenceValue: referenceValue,
                  referenceLabel: referenceLabel,
                  onBarTap: onBarTap,
                  unitFormatter: unitFormatter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedSleepBody extends StatefulWidget {
  const _ExpandedSleepBody({
    required this.range,
    required this.metrics,
    required this.bars,
    required this.domain,
    required this.accent,
    required this.emptyLabel,
    this.showEmptyLabel = true,
    this.referenceValue,
    this.referenceLabel,
    this.onBarTap,
    this.unitFormatter,
  });

  final _SleepRange range;
  final List<_MetricTileData> metrics;
  final List<ChartBar> bars;
  final Domain domain;
  final Color accent;
  final String emptyLabel;
  final bool showEmptyLabel;
  final double? referenceValue;
  final String? referenceLabel;
  final ValueChanged<int>? onBarTap;
  final String Function(double)? unitFormatter;

  @override
  State<_ExpandedSleepBody> createState() => _ExpandedSleepBodyState();
}

class _ExpandedSleepBodyState extends State<_ExpandedSleepBody> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(_ExpandedSleepBody old) {
    super.didUpdateWidget(old);
    if (old.bars.length != widget.bars.length) _scheduleScrollToEnd();
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
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            for (final m in widget.metrics)
              _MetricTile(
                label: m.label,
                value: m.value,
                color: m.color ?? widget.accent,
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
                    relativeScale: false,
                    referenceValue: widget.referenceValue,
                    onBarTap: widget.onBarTap,
                    showTrendLine: false,
                  ),
                ),
              );
            },
          ),
          if (widget.referenceValue != null &&
              widget.referenceLabel != null) ...[
            const SizedBox(height: 10),
            _ReferencePill(
              label: '${widget.referenceLabel} '
                  '${widget.unitFormatter?.call(widget.referenceValue!) ?? widget.referenceValue!.toStringAsFixed(0)}',
              color: widget.accent,
            ),
          ],
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
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
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferencePill extends StatelessWidget {
  const _ReferencePill({required this.label, required this.color});
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

// ─── Stage breakdown card ───────────────────────────────────────────────────

class _StageBreakdownCard extends StatelessWidget {
  const _StageBreakdownCard({
    required this.cardId,
    required this.expanded,
    required this.onToggle,
    required this.dateLabel,
    required this.breakdown,
    required this.hasData,
    required this.stageNameOf,
    required this.emptyLabel,
    required this.formatDuration,
  });

  final String cardId;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final String dateLabel;
  final Map<SleepStage, Duration> breakdown;
  final bool hasData;
  final String Function(SleepStage) stageNameOf;
  final String emptyLabel;
  final String Function(Duration?) formatDuration;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.sleep;

    final totalMin = breakdown.values
        .fold<int>(0, (s, d) => s + d.inMinutes);

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
                  ),
                  child: Icon(Icons.donut_small_rounded,
                      size: 18, color: domain.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.sleepStagesBreakdown,
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
                child: Padding(
                  padding: const EdgeInsets.only(top: Tokens.spaceMd),
                  child: !hasData
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              emptyLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: ft.onSurfaceMuted,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Stacked horizontal bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 10,
                                child: Row(
                                  children: [
                                    for (final stage in const [
                                      SleepStage.deep,
                                      SleepStage.light,
                                      SleepStage.rem,
                                      SleepStage.awake,
                                    ])
                                      if ((breakdown[stage] ?? Duration.zero)
                                              .inMinutes >
                                          0)
                                        Expanded(
                                          flex: breakdown[stage]!.inMinutes,
                                          child: Container(
                                            color: _StageColors.of(stage),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: Tokens.spaceMd),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 2.1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              children: [
                                for (final stage in const [
                                  SleepStage.deep,
                                  SleepStage.light,
                                  SleepStage.rem,
                                  SleepStage.awake,
                                ])
                                  _StageChip(
                                    label: stageNameOf(stage),
                                    color: _StageColors.of(stage),
                                    duration:
                                        breakdown[stage] ?? Duration.zero,
                                    totalMinutes: totalMin,
                                    formatDuration: formatDuration,
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.color,
    required this.duration,
    required this.totalMinutes,
    required this.formatDuration,
  });

  final String label;
  final Color color;
  final Duration duration;
  final int totalMinutes;
  final String Function(Duration?) formatDuration;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final pct =
        totalMinutes > 0 ? (duration.inMinutes / totalMinutes * 100) : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: ft.onSurfaceMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  formatDuration(duration),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                    color: ft.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage timeline card (custom painter) ───────────────────────────────────

class _StageTimelineCard extends StatelessWidget {
  const _StageTimelineCard({
    required this.cardId,
    required this.expanded,
    required this.onToggle,
    required this.night,
    required this.dateLabel,
    required this.stageNameOf,
    required this.emptyLabel,
  });

  final String cardId;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final SleepRecord? night;
  final String dateLabel;
  final String Function(SleepStage) stageNameOf;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.sleep;
    final hasSegments = night != null && night!.hasStageData;

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
                  ),
                  child: Icon(Icons.timeline_rounded,
                      size: 18, color: domain.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.sleepStagesTitle,
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
                child: Padding(
                  padding: const EdgeInsets.only(top: Tokens.spaceMd),
                  child: !hasSegments
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              emptyLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: ft.onSurfaceMuted,
                              ),
                            ),
                          ),
                        )
                      : _StageTimeline(
                          night: night!,
                          stageNameOf: stageNameOf,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.night, required this.stageNameOf});

  final SleepRecord night;
  final String Function(SleepStage) stageNameOf;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage row legend (Awake → REM → Light → Deep, top to bottom)
        Row(
          children: [
            for (final stage in const [
              SleepStage.deep,
              SleepStage.rem,
              SleepStage.light,
              SleepStage.awake,
            ]) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _StageColors.of(stage),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                stageNameOf(stage),
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: ft.onSurfaceMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: Tokens.spaceMd),
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _StageTimelinePainter(
              segments: night.segments,
              start: night.sleepStart,
              end: night.wakeTime,
              trackLineColor: ft.cardBorder,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Time axis labels: bedtime, midpoint, wake
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('HH:mm', locale).format(night.sleepStart),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                color: ft.onSurfaceFaint,
              ),
            ),
            Text(
              DateFormat('HH:mm', locale).format(
                DateTime.fromMillisecondsSinceEpoch(
                  (night.sleepStart.millisecondsSinceEpoch +
                          night.wakeTime.millisecondsSinceEpoch) ~/
                      2,
                ),
              ),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                color: ft.onSurfaceFaint,
              ),
            ),
            Text(
              DateFormat('HH:mm', locale).format(night.wakeTime),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                color: ft.onSurfaceFaint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StageTimelinePainter extends CustomPainter {
  const _StageTimelinePainter({
    required this.segments,
    required this.start,
    required this.end,
    required this.trackLineColor,
  });

  final List<SleepSegment> segments;
  final DateTime start;
  final DateTime end;
  final Color trackLineColor;

  // Track order (top → bottom): Awake, REM, Light, Deep.
  // Visually maps "more awake" = higher on the chart, "deeper" = lower.
  static const _trackOrder = <SleepStage>[
    SleepStage.awake,
    SleepStage.rem,
    SleepStage.light,
    SleepStage.deep,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final spanMs = end.difference(start).inMilliseconds;
    if (spanMs <= 0) return;

    final tracks = _trackOrder.length;
    final trackHeight = size.height / tracks;

    // Subtle baseline per track for empty-stage readability.
    final linePaint = Paint()
      ..color = trackLineColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (int i = 0; i < tracks; i++) {
      final y = trackHeight * (i + 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    double xFor(DateTime t) {
      final clamped = t.isBefore(start)
          ? 0
          : t.isAfter(end)
              ? spanMs
              : t.difference(start).inMilliseconds;
      return (clamped / spanMs) * size.width;
    }

    final barH = trackHeight * 0.72;
    for (final seg in segments) {
      final trackIdx = _trackOrder.indexOf(seg.stage);
      if (trackIdx < 0) continue;
      final x1 = xFor(seg.start);
      final x2 = xFor(seg.end);
      final w = (x2 - x1).clamp(1.5, size.width).toDouble();
      final yCenter = trackHeight * (trackIdx + 0.5);
      final rect = Rect.fromLTWH(x1, yCenter - barH / 2, w, barH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      final paint = Paint()..color = _StageColors.of(seg.stage);
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StageTimelinePainter old) {
    return old.segments != segments ||
        old.start != start ||
        old.end != end ||
        old.trackLineColor != trackLineColor;
  }
}
