import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_record.dart';
import '../models/selected_period.dart';
import '../providers/fitness_provider.dart';
import '../providers/goals_provider.dart';
import '../theme/ft_design_tokens.dart';
import '../widgets/ft/ft_activity_row.dart';
import '../widgets/ft/ft_date_nav.dart';
import '../widgets/ft/ft_plain_card.dart';
import '../widgets/ft/ft_screen_header.dart';
import '../widgets/ft/ft_stat_card.dart';
import '../widgets/ft/ft_tab_pill.dart';
import '../widgets/ft/ft_trend_chart.dart';

class FtActivitiesScreen extends StatefulWidget {
  const FtActivitiesScreen({super.key});

  @override
  State<FtActivitiesScreen> createState() => _FtActivitiesScreenState();
}

class _FtActivitiesScreenState extends State<FtActivitiesScreen> {
  SelectedPeriod _period = SelectedPeriod.currentWeek();

  String _monthShort(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  String? _dateNavOverride() {
    switch (_period.type) {
      case PeriodType.day:
        return null;
      case PeriodType.week:
        final s = _period.start;
        final e = _period.end;
        return '${s.day} ${_monthShort(s.month)} – ${e.day} ${_monthShort(e.month)}';
      case PeriodType.month:
        return '${_monthShort(_period.referenceDate.month)} ${_period.referenceDate.year}';
      case PeriodType.custom:
        return null;
    }
  }

  void _changeTab(String tab) {
    final type = tab == 'Day'
        ? PeriodType.day
        : tab == 'Week'
            ? PeriodType.week
            : PeriodType.month;
    setState(() => _period = _period.withType(type));
  }

  void _onSwipe(double velocity) {
    if (velocity.abs() < 300) return;
    setState(() {
      if (velocity > 0) {
        _period = _period.backward();
      } else if (_period.canGoForward) {
        _period = _period.forward();
      }
    });
  }

  String _tab() => _period.type == PeriodType.week
      ? 'Week'
      : _period.type == PeriodType.month
          ? 'Month'
          : 'Day';

  ({FtActivityType type, String emoji}) _mapActivity(String hcType) {
    final t = hcType.toUpperCase();
    if (t.contains('WALK')) return (type: FtActivityType.walking, emoji: '🥾');
    if (t.contains('RUN') || t.contains('JOG')) {
      return (type: FtActivityType.walking, emoji: '🏃');
    }
    if (t.contains('CYCL') || t.contains('BIKE')) {
      return (type: FtActivityType.walking, emoji: '🚴');
    }
    if (t.contains('SWIM')) return (type: FtActivityType.walking, emoji: '🏊');
    if (t.contains('HIKE') || t.contains('TRAIL')) {
      return (type: FtActivityType.walking, emoji: '⛰️');
    }
    if (t.contains('YOGA') || t.contains('MEDIT')) {
      return (type: FtActivityType.strength, emoji: '🧘');
    }
    return (type: FtActivityType.strength, emoji: '⚔️');
  }

  String _formatActivityType(String hcType) => hcType
      .split('_')
      .map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    if (mins < 60) return '$mins min';
    final h = d.inHours;
    final m = mins - h * 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _activityDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actDay = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('HH:mm').format(dt);
    if (actDay == today) return 'Today · $time';
    if (actDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · $time';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]} ${dt.day} · $time';
  }

  List<FtChartBar> _buildStepsChart(List<StepsRecord> history) {
    if (history.isEmpty) return [];
    final slice =
        history.length > 7 ? history.sublist(history.length - 7) : history;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return slice
        .map((r) => FtChartBar(
              label: days[r.date.weekday - 1],
              value: r.steps.toDouble(),
              isToday: r.date == today,
            ))
        .toList();
  }

  Widget _buildActivityRow(ActivityRecord a, bool isLast) {
    final mapped = _mapActivity(a.type);
    return FtActivityRow(
      type: mapped.type,
      typeLabel: _formatActivityType(a.type).toUpperCase(),
      typeEmoji: mapped.emoji,
      date: _activityDateLabel(a.startTime),
      duration: _formatDuration(a.duration),
      kcal: a.caloriesBurned != null ? '${a.caloriesBurned} kcal' : '-- kcal',
      xp: (a.duration.inMinutes * 2).clamp(10, 200), // TODO: real XP
      isLast: isLast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final tab = _tab();

    final chartBars = _buildStepsChart(fitness.stepsHistory);
    final chartAvg = chartBars.isNotEmpty
        ? chartBars.map((b) => b.value).reduce((a, b) => a + b) /
            chartBars.length
        : 0.0;

    final periodActivities = fitness.activities.where((a) {
      final d = DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
      return !d.isBefore(_period.start) && !d.isAfter(_period.end);
    }).toList();
    final activeMins = periodActivities.fold<int>(
      0,
      (sum, a) => sum + a.duration.inMinutes,
    );
    final actMinsGoal = goals.weeklyActivityMins;
    final actProgress =
        actMinsGoal > 0 ? (activeMins / actMinsGoal).clamp(0.0, 1.0) : 0.0;

    final recentActivities = [...fitness.activities]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final displayActivities = recentActivities.take(20).toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) => _onSwipe(d.primaryVelocity ?? 0),
      child: RefreshIndicator(
        onRefresh: () => fitness.refresh(),
        color: FtTokens.accent,
        backgroundColor: FtTokens.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            const FtScreenHeader(greeting: 'Keep moving ✦', title: 'Activities'),
            const SizedBox(height: 10),
            FtTabPill(
              tabs: const ['Day', 'Week', 'Month'],
              active: tab,
              onChange: _changeTab,
            ),
            const SizedBox(height: 10),
            FtDateNav(
              date: _period.referenceDate,
              onPrev: () => setState(() => _period = _period.backward()),
              onNext: _period.canGoForward
                  ? () => setState(() => _period = _period.forward())
                  : null,
              labelOverride: _dateNavOverride(),
              showTodayButton: !_period.isCurrentPeriod,
              onTodayTap: () =>
                  setState(() => _period = _period.withType(_period.type)),
            ),
            if (!fitness.workoutPermissionGranted &&
                fitness.accessState == FitnessAccessState.ready) ...[
              const SizedBox(height: 10),
              _WorkoutPermissionBanner(
                onTap: () => fitness.requestWorkoutPermission(),
              ),
            ],
            const SizedBox(height: 10),
            FtStatCard(
              icon: '⚡',
              label: tab == 'Day'
                  ? 'Active minutes · today'
                  : tab == 'Week'
                      ? 'Active minutes · week'
                      : 'Active minutes · month',
              domain: FtTokens.active,
              stats: [
                FtStatStat(value: '$activeMins', label: 'Active', unit: 'min'),
                FtStatStat(value: '$actMinsGoal', label: 'Goal', unit: 'min'),
                FtStatStat(
                  value: '${periodActivities.length}',
                  label: 'Workouts',
                ),
              ],
              progress: actProgress,
              badge: '${(actProgress * 100).round()}%',
              xp: '+${periodActivities.length * 60} XP', // TODO: real XP
            ),
            const SizedBox(height: 10),
            FtTrendCard(
              domain: FtTokens.steps,
              icon: Icons.bar_chart,
              title: 'Steps trend',
              subtitle: 'Last 7 days',
              metrics: [
                FtTrendMetric(
                  label: 'Today',
                  value: NumberFormat.decimalPattern().format(fitness.todaySteps),
                ),
                FtTrendMetric(
                  label: 'Average',
                  value: NumberFormat.decimalPattern().format(chartAvg.round()),
                ),
                FtTrendMetric(
                  label: 'Goal',
                  value: NumberFormat.decimalPattern().format(goals.dailySteps),
                ),
              ],
              bars: chartBars,
              referenceValue: goals.dailySteps.toDouble(),
              referenceLabel: 'Goal',
              emptyLabel: 'No step data yet',
              expandable: chartBars.length > 4,
            ),
            const SizedBox(height: 10),
            FtPlainCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'RECENT QUESTS',
                        style: TextStyle(
                          fontSize: FtTokens.fontSizeCaption,
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
                            fontSize: FtTokens.fontSizeCaption,
                            fontWeight: FontWeight.w600,
                            color: FtTokens.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (displayActivities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        fitness.workoutPermissionGranted
                            ? 'No recent activities'
                            : 'Grant workout permission to see activities',
                        style: const TextStyle(
                          fontSize: 13,
                          color: FtTokens.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (int i = 0; i < displayActivities.length; i++)
                      _buildActivityRow(
                          displayActivities[i], i == displayActivities.length - 1),
                ],
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FtTokens.active.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FtTokens.active.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Allow workout access to see your activity history',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
            Text(
              'Allow →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FtTokens.active.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
