import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/activity_row.dart';
import '../../../shared/widgets/date_nav.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../../shared/widgets/plain_card.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/tab_pill.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/fitness_provider.dart';
import '../domain/activity_record.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  SelectedPeriod _period = SelectedPeriod.currentWeek();

  String? _dateNavOverride(BuildContext context, SelectedPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    switch (period.type) {
      case PeriodType.day:
        return null;
      case PeriodType.week:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} - ${end.day} ${DateFormat.MMM(locale).format(end)}';
      case PeriodType.month:
        return DateFormat.yMMM(locale).format(period.referenceDate);
      case PeriodType.custom:
        return null;
    }
  }

  void _changeTab(String tab) {
    final l10n = context.l10n;
    final type = tab == l10n.periodDay
        ? PeriodType.day
        : tab == l10n.periodWeek
            ? PeriodType.week
            : PeriodType.month;
    setState(() => _period = _period.withType(type));
  }

  String _tab(BuildContext context, SelectedPeriod period) =>
      period.type == PeriodType.week
          ? context.l10n.periodWeek
          : period.type == PeriodType.month
              ? context.l10n.periodMonth
              : context.l10n.periodDay;

  ({ActivityType type, String emoji}) _mapActivity(String hcType) {
    final type = hcType.toUpperCase();
    if (type.contains('WALK')) {
      return (type: ActivityType.walking, emoji: '\uD83D\uDEB6');
    }
    if (type.contains('RUN') || type.contains('JOG')) {
      return (type: ActivityType.walking, emoji: '\uD83C\uDFC3');
    }
    if (type.contains('CYCL') || type.contains('BIKE')) {
      return (type: ActivityType.walking, emoji: '\uD83D\uDEB4');
    }
    if (type.contains('SWIM')) {
      return (type: ActivityType.walking, emoji: '\uD83C\uDFCA');
    }
    if (type.contains('HIKE') || type.contains('TRAIL')) {
      return (type: ActivityType.walking, emoji: '\uD83E\uDD7E');
    }
    if (type.contains('YOGA') || type.contains('MEDIT')) {
      return (type: ActivityType.strength, emoji: '\uD83E\uDDD8');
    }
    return (type: ActivityType.strength, emoji: '\u2694');
  }

  String _formatActivityType(String hcType) => hcType
      .split('_')
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = duration.inHours;
    final remainingMinutes = minutes - hours * 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  String _activityDateLabel(BuildContext context, DateTime dateTime) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = DateFormat('HH:mm', locale).format(dateTime);
    if (activityDay == today) return '${l10n.headerToday} | $time';
    return '${DateFormat.E(locale).format(dateTime)} ${dateTime.day} | $time';
  }

  List<ChartBar> _buildStepsChart(List<StepsRecord> history) {
    if (history.isEmpty) return [];
    final slice =
        history.length > 7 ? history.sublist(history.length - 7) : history;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return slice
        .map(
          (record) => ChartBar(
            label: days[record.date.weekday - 1],
            value: record.steps.toDouble(),
            isToday: record.date == today,
          ),
        )
        .toList();
  }

  Widget _buildActivityRow(
    BuildContext context,
    ActivityRecord activity,
    bool isLast,
  ) {
    final mapped = _mapActivity(activity.type);
    return ActivityRow(
      type: mapped.type,
      typeLabel: _formatActivityType(activity.type).toUpperCase(),
      typeEmoji: mapped.emoji,
      date: _activityDateLabel(context, activity.startTime),
      duration: _formatDuration(activity.duration),
      kcal: activity.caloriesBurned != null
          ? '${activity.caloriesBurned} kcal'
          : '-- kcal',
      xp: (activity.duration.inMinutes * 2).clamp(10, 200),
      isLast: isLast,
    );
  }

  Widget _buildPeriodContent(
    BuildContext context,
    SelectedPeriod period,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final tab = _tab(context, period);
    final stepsFmt = NumberFormat('#,##0', locale);

    final chartBars = _buildStepsChart(fitness.stepsHistory);
    final chartAvg = chartBars.isNotEmpty
        ? chartBars.map((bar) => bar.value).reduce((a, b) => a + b) /
            chartBars.length
        : 0.0;
    final periodSteps = period.type == PeriodType.day
        ? fitness.stepsForDate(period.start)
        : fitness.stepsAvgForRange(period.start, period.end);
    final stepsGoal = goals.dailySteps;
    final stepsProgress =
        stepsGoal > 0 ? (periodSteps / stepsGoal).clamp(0.0, 1.0) : 0.0;
    final stepsLeft = (stepsGoal - periodSteps).clamp(0, stepsGoal);

    final periodActivities = fitness.activities.where((activity) {
      final day = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );
      return !day.isBefore(period.start) && !day.isAfter(period.end);
    }).toList();
    final activeMinutes = periodActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.duration.inMinutes,
    );
    final goalMinutes = goals.weeklyActivityMins;
    final progress =
        goalMinutes > 0 ? (activeMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;

    final recentActivities = [...fitness.activities]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final displayActivities = recentActivities.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!fitness.workoutPermissionGranted &&
            fitness.accessState == FitnessAccessState.ready) ...[
          const SizedBox(height: 2),
          _WorkoutPermissionBanner(
            onTap: () => fitness.requestWorkoutPermission(),
          ),
          const SizedBox(height: 10),
        ],
        StatCard(
          icon: '\uD83E\uDD7E',
          label: l10n.stepsTitle,
          domain: Tokens.steps,
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            StatStat(
              value: stepsFmt.format(periodSteps),
              label: l10n.stepsTitle,
            ),
            StatStat(
              value: stepsFmt.format(stepsGoal),
              label: l10n.stepsGoal,
            ),
            StatStat(
              value: period.type == PeriodType.day
                  ? stepsFmt.format(stepsLeft)
                  : '--',
              label: period.type == PeriodType.day ? l10n.stepsRemaining : '',
            ),
          ],
          progress: stepsProgress,
          badge: '${(stepsProgress * 100).round()}%',
        ),
        const SizedBox(height: 10),
        TrendCard(
          domain: Tokens.steps,
          icon: Icons.bar_chart,
          title: l10n.activitiesWeeklyTrend,
          subtitle: l10n.activitiesWeekTotal,
          collapsible: false,
          metrics: [
            TrendMetric(
              label: l10n.headerToday,
              value: NumberFormat.decimalPattern().format(fitness.todaySteps),
            ),
            TrendMetric(
              label: l10n.stepsAverage,
              value: NumberFormat.decimalPattern().format(chartAvg.round()),
            ),
            TrendMetric(
              label: l10n.stepsGoal,
              value: NumberFormat.decimalPattern().format(goals.dailySteps),
            ),
          ],
          bars: chartBars,
          referenceValue: goals.dailySteps.toDouble(),
          referenceLabel: l10n.stepsGoal,
          emptyLabel: l10n.activitiesNoWorkouts,
          expandable: chartBars.length > 4,
        ),
        const SizedBox(height: 10),
        StatCard(
          icon: '\u26A1',
          label: '${l10n.activitiesActiveMins} · ${tab.toLowerCase()}',
          domain: Tokens.active,
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            StatStat(
              value: '$activeMinutes',
              label: l10n.activitiesActiveMins,
              unit: 'min',
            ),
            StatStat(
              value: '$goalMinutes',
              label: l10n.stepsGoal,
              unit: 'min',
            ),
            StatStat(
              value: '${periodActivities.length}',
              label: l10n.activitiesWorkouts,
            ),
          ],
          progress: progress,
          badge: '${(progress * 100).round()}%',
          xp: '+${periodActivities.length * 60} XP',
        ),
        const SizedBox(height: 10),
        PlainCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    l10n.activitiesRecentActivity.toUpperCase(),
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      fontWeight: FontWeight.w700,
                      color: Color(0x80FFFFFF),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (displayActivities.isNotEmpty)
                    Text(
                      '${displayActivities.length} total →',
                      style: TextStyle(
                        fontSize: Tokens.fontSizeCaption,
                        fontWeight: FontWeight.w600,
                        color: Tokens.accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Tokens.spaceXs),
              if (displayActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    fitness.workoutPermissionGranted
                        ? l10n.activitiesNoWorkouts
                        : l10n.activitiesWorkoutPermissionBody,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Tokens.onSurfaceMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (int i = 0; i < displayActivities.length; i++)
                  _buildActivityRow(
                    context,
                    displayActivities[i],
                    i == displayActivities.length - 1,
                  ),
            ],
          ),
        ),
      ],
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
                        title: context.l10n.screenActivities,
                        leading: Navigator.of(context).canPop()
                            ? const FtBackButton()
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TabPill(
                        tabs: [
                          context.l10n.periodDay,
                          context.l10n.periodWeek,
                          context.l10n.periodMonth,
                        ],
                        active: _tab(context, _period),
                        onChange: _changeTab,
                      ),
                      const SizedBox(height: 10),
                      DateNav(
                        date: _period.referenceDate,
                        onPrev: () =>
                            setState(() => _period = _period.backward()),
                        onNext: _period.canGoForward
                            ? () => setState(() => _period = _period.forward())
                            : null,
                        labelOverride: _dateNavOverride(context, _period),
                        showTodayButton: !_period.isCurrentPeriod,
                        onTodayTap: () => setState(
                            () => _period = _period.withType(_period.type)),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  child: DragRevealPager<SelectedPeriod>(
                    item: _period,
                    hasPrevious: (_) => true,
                    hasNext: (period) => period.canGoForward,
                    previousOf: (period) => period.backward(),
                    nextOf: (period) => period.forward(),
                    onCommit: (period) => setState(() => _period = period),
                    builder: (context, period) =>
                        _buildPeriodContent(context, period, fitness, goals),
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

class _WorkoutPermissionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _WorkoutPermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Tokens.active.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: Tokens.active.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Text('\u26A1', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.activitiesWorkoutPermissionBody,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
