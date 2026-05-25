import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/screen_link_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/fitness_provider.dart';
import '../domain/activity_record.dart';
import 'activities_screen.dart';
import 'widgets/hc_status_indicators.dart';

/// Steps-focused detail screen. Today header → period navigator with tabs →
/// period stats → trend chart. Cross-links to the Activities screen at the
/// bottom for jumping to workouts.
class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  SelectedPeriod _period = SelectedPeriod.today();

  String _periodDateLabel(BuildContext context, SelectedPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    switch (period.type) {
      case PeriodType.day:
        return DateFormat('EEE d MMM', locale).format(period.referenceDate);
      case PeriodType.week:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} – '
            '${end.day} ${DateFormat.MMM(locale).format(end)}';
      case PeriodType.month:
        return DateFormat.yMMM(locale).format(period.referenceDate);
      case PeriodType.custom:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} – '
            '${end.day} ${DateFormat.MMM(locale).format(end)}';
    }
  }

  String _tab(BuildContext context, SelectedPeriod period) =>
      period.type == PeriodType.week
          ? context.l10n.periodWeek
          : period.type == PeriodType.month
              ? context.l10n.periodMonth
              : context.l10n.periodDay;

  void _changeTab(String tab) {
    final l10n = context.l10n;
    final type = tab == l10n.periodDay
        ? PeriodType.day
        : tab == l10n.periodWeek
            ? PeriodType.week
            : PeriodType.month;
    setState(() => _period = _period.withType(type));
  }

  /// Consecutive prior days (excluding today) where steps ≥ goal. Today is
  /// intentionally excluded so the streak doesn't reset mid-day before the
  /// user has had a chance to hit their goal.
  int _computeGoalStreak(List<StepsRecord> history, int goal) {
    if (history.isEmpty || goal <= 0) return 0;
    final byDate = <DateTime, int>{
      for (final r in history)
        DateTime(r.date.year, r.date.month, r.date.day): r.steps,
    };
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    var streak = 0;
    while (true) {
      final steps = byDate[day];
      if (steps == null || steps < goal) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Builds bars for the steps chart. Shows period-bounded bars for week /
  /// month modes; in day mode falls back to the most-recent 14 days for
  /// context (so the user always sees a chart, with the selected day
  /// highlighted via [ChartBar.isToday]).
  List<ChartBar> _buildStepsBars(
    BuildContext context,
    FitnessProvider fitness,
    SelectedPeriod period,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final List<StepsRecord> records;
    if (period.type == PeriodType.day) {
      final all = fitness.stepsHistory;
      records = all.length > 14 ? all.sublist(all.length - 14) : List.of(all);
    } else {
      records = fitness.stepsHistory.where((r) { // lint-ignore: widget-no-logic — UI period range slice for the steps chart
        final day = DateTime(r.date.year, r.date.month, r.date.day);
        return !day.isBefore(period.start) && !day.isAfter(period.end);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    }

    final selectedDay = period.type == PeriodType.day
        ? DateTime(period.referenceDate.year, period.referenceDate.month,
            period.referenceDate.day)
        : null;

    return records.map((r) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      final label = period.type == PeriodType.month
          ? DateFormat('d', locale).format(r.date)
          : DateFormat.E(locale).format(r.date).substring(0, 1);
      final isHighlighted = period.type == PeriodType.day
          ? day == selectedDay
          : (period.type == PeriodType.week || period.type == PeriodType.month)
              ? day == _today()
              : false;
      return ChartBar(
        label: label,
        value: r.steps.toDouble(),
        isToday: isHighlighted,
      );
    }).toList();
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Widget _buildContent(
    BuildContext context,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);

    // ── Today (period-independent) ──────────────────────────────────────
    final todaySteps = fitness.todaySteps;
    final goal = goals.dailySteps;
    final todayProgress = goal > 0 ? (todaySteps / goal).clamp(0.0, 1.0) : 0.0;
    final streak = _computeGoalStreak(fitness.stepsHistory, goal);

    // ── Period-driven aggregates ────────────────────────────────────────
    final periodRecords = fitness.stepsHistoryForRange(
      _period.start,
      _period.end,
    );
    final periodTotal =
        periodRecords.fold<int>(0, (sum, r) => sum + r.steps);
    final periodAvg = _period.type == PeriodType.day
        ? fitness.stepsForDate(_period.start)
        : (periodRecords.isEmpty
            ? 0
            : (periodTotal / periodRecords.length).round());
    final bestDay = periodRecords.isEmpty
        ? null
        : periodRecords.reduce((a, b) => a.steps >= b.steps ? a : b);

    final bars = _buildStepsBars(context, fitness, _period);

    return SwipePeriodGesture(
      onPrev: () => setState(() => _period = _period.backward()),
      onNext: _period.canGoForward
          ? () => setState(() => _period = _period.forward())
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Today header ─────────────────────────────────────────────
          StatCard(
            icon: '🥾',
            label: '${l10n.stepsTitle} · ${l10n.headerToday}',
            domain: Tokens.steps,
            visualAssets: DashboardCardAssetResolver.forKind(
              DashboardCardKind.steps,
            ),
            initiallyExpanded: true,
            collapsible: false,
            stats: [
              StatStat(
                value: fmt.format(todaySteps),
                label: l10n.stepsTitle,
              ),
              StatStat(
                value: fmt.format(goal),
                label: l10n.stepsGoal,
              ),
              StatStat(
                value: '$streak',
                label: l10n.stepsCurrentStreak,
                unit: streak == 1 ? 'd' : 'd',
              ),
            ],
            progress: todayProgress,
            badge: '${(todayProgress * 100).round()}%',
          ),

          const SizedBox(height: 10),

          // ── Period navigator + tabs ──────────────────────────────────
          PeriodNavigator(
            domain: Tokens.steps,
            tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
            activeTab: _tab(context, _period),
            onTabChange: _changeTab,
            dateLabel: _periodDateLabel(context, _period),
            canGoForward: _period.canGoForward,
            isCurrentPeriod: _period.isCurrentPeriod,
            onPrev: () => setState(() => _period = _period.backward()),
            onNext: _period.canGoForward
                ? () => setState(() => _period = _period.forward())
                : null,
            onToday: _period.isCurrentPeriod
                ? null
                : () => setState(
                    () => _period = _period.withType(_period.type)),
          ),

          const SizedBox(height: 10),

          // ── Period stats — total / avg / best day ────────────────────
          StatCard(
            icon: '📈',
            label: '${l10n.stepsTitle} · ${_tab(context, _period).toLowerCase()}',
            domain: Tokens.steps,
            visualAssets: DashboardCardAssetResolver.forKind(
              DashboardCardKind.steps,
            ),
            initiallyExpanded: true,
            collapsible: false,
            stats: [
              StatStat(
                value: fmt.format(periodAvg),
                label: _period.type == PeriodType.day
                    ? l10n.stepsTitle
                    : l10n.stepsAverage,
              ),
              StatStat(
                value: fmt.format(periodTotal),
                label: l10n.activitiesWeekTotal,
              ),
              StatStat(
                value: bestDay != null ? fmt.format(bestDay.steps) : '--',
                label: l10n.stepsBestDay,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Steps trend chart ───────────────────────────────────────
          if (bars.isNotEmpty)
            TrendCard(
              domain: Tokens.steps,
              icon: Icons.bar_chart_rounded,
              title: l10n.activitiesWeeklyTrend,
              subtitle: _periodDateLabel(context, _period),
              collapsible: false,
              metrics: [
                TrendMetric(
                  label: l10n.stepsAverage,
                  value: fmt.format(periodAvg),
                ),
                TrendMetric(
                  label: l10n.stepsGoal,
                  value: fmt.format(goal),
                ),
              ],
              bars: bars,
              referenceValue: goal.toDouble(),
              referenceLabel: l10n.stepsGoal,
              emptyLabel: l10n.activitiesNoWorkouts,
              expandable: bars.length > 4,
            ),

          const SizedBox(height: 14),

          // ── Cross-link: jump to Activities ──────────────────────────
          ScreenLinkCard(
            title: l10n.screenActivities,
            subtitle: l10n.activitiesLinkSubtitle,
            icon: Icons.fitness_center_rounded,
            domain: Tokens.active,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActivitiesScreen(),
              ),
            ),
          ),
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
                        title: context.l10n.screenSteps,
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
