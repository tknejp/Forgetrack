import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hc_state_widgets.dart';
import '../../widgets/stat_display.dart';
import '../../widgets/top_level_app_bar.dart';
import 'widgets/activity_cards.dart';
import 'widgets/workout_section.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: TopLevelAppBar(
            title: context.l10n.screenActivities,
            subtitle: buildTopLevelHeaderSubtitle(
              context,
              syncCopy: AppHeaderSyncCopy.health,
              syncedAt: fitness.lastSyncedAt,
            ),
          ),
          body: _buildBody(context, fitness),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FitnessProvider fitness) {
    switch (fitness.accessState) {
      case FitnessAccessState.checking:
        return const Center(child: CircularProgressIndicator());
      case FitnessAccessState.unavailable:
        return HcUnavailableState(fitness: fitness);
      case FitnessAccessState.permissionRequired:
        return HcNoPermissionsState(fitness: fitness);
      case FitnessAccessState.ready:
        break;
    }
    if (fitness.errorMessage != null && fitness.stepsHistory.isEmpty) {
      return _ErrorState(fitness: fitness);
    }
    return RefreshIndicator(
      onRefresh: () => fitness.refresh(),
      child: _ActivitiesContent(fitness: fitness),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final FitnessProvider fitness;
  const _ErrorState({required this.fitness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(l10n.healthSyncFailed,
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => fitness.refresh(),
            child: Text(l10n.healthRetry),
          ),
        ],
      ),
    );
  }
}

// ─── Main content (composition layer) ────────────────────────────────────────

class _ActivitiesContent extends StatelessWidget {
  final FitnessProvider fitness;
  const _ActivitiesContent({required this.fitness});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, goals, _) {
        final locale = Localizations.localeOf(context).toString();
        final tokens = context.tokens;
        final cs = Theme.of(context).colorScheme;
        final l10n = context.l10n;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));

        int todayActiveMins = 0;
        int weekActiveMins = 0;
        int weekWorkoutCount = 0;
        int weekWorkoutTotalMins = 0;
        int weekWorkoutCalories = 0;
        int monthWorkoutTotalMins = 0;
        int monthWorkoutCalories = 0;
        for (final a in fitness.activities) {
          final aDay =
              DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
          final mins = a.duration.inMinutes;
          final cal = a.caloriesBurned ?? 0;
          monthWorkoutTotalMins += mins;
          monthWorkoutCalories += cal;
          if (aDay == today) todayActiveMins += mins;
          if (!aDay.isBefore(weekStart)) {
            weekActiveMins += mins;
            weekWorkoutCount++;
            weekWorkoutTotalMins += mins;
            weekWorkoutCalories += cal;
          }
        }
        final monthWorkoutCount = fitness.activities.length;
        final avgWorkoutMins = monthWorkoutCount > 0
            ? (monthWorkoutTotalMins / monthWorkoutCount).round()
            : 0;

        final chartHistory = fitness.stepsHistory.length >= 7
            ? fitness.stepsHistory.sublist(fitness.stepsHistory.length - 7)
            : fitness.stepsHistory;

        final avgSteps = fitness.stepsHistory.isEmpty
            ? 0
            : (fitness.stepsHistory
                        .map((e) => e.steps)
                        .reduce((a, b) => a + b) /
                    fitness.stepsHistory.length)
                .round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            // ── Steps summary ──────────────────────────────────────────────
            SectionHeader(l10n.stepsTitle,
                icon: Icons.directions_walk, color: tokens.steps.accent),
            const SizedBox(height: 8),
            StepsSummaryCard(
              todaySteps: fitness.todaySteps,
              weekTotal: fitness.stepsWeekTotal,
              monthTotal: fitness.stepsMonthTotal,
              dailyGoal: goals.dailySteps,
              avgPerDay: avgSteps,
            ),

            // ── 7-day trend chart ──────────────────────────────────────────
            if (chartHistory.length > 1) ...[
              const SizedBox(height: 16),
              SectionHeader(l10n.activitiesWeeklyTrend,
                  icon: Icons.show_chart, color: tokens.steps.accent),
              const SizedBox(height: 8),
              StepsTrendCard(history: chartHistory, locale: locale),
            ],

            // ── Active calories ────────────────────────────────────────────
            const SizedBox(height: 16),
            SectionHeader(l10n.activitiesActiveCalories,
                icon: Icons.local_fire_department_outlined,
                color: tokens.nutrition.accent),
            const SizedBox(height: 8),
            ActiveCaloriesCard(
              today: fitness.activeCaloriesBurnedToday,
              week: fitness.activeCaloriesBurnedWeek,
              month: fitness.activeCaloriesBurnedMonth,
            ),

            // ── Active minutes ─────────────────────────────────────────────
            const SizedBox(height: 16),
            SectionHeader(l10n.activitiesActiveMins,
                icon: Icons.timer_outlined, color: tokens.steps.accent),
            const SizedBox(height: 8),
            ActiveMinsCard(
              todayMins: todayActiveMins,
              weekMins: weekActiveMins,
              weeklyGoal: goals.weeklyActivityMins,
            ),

            // ── Workout stats ──────────────────────────────────────────────
            const SizedBox(height: 16),
            SectionHeader(l10n.activitiesWorkouts,
                icon: Icons.fitness_center_outlined, color: cs.secondary),
            const SizedBox(height: 8),
            WorkoutStatsCard(
              weekCount: weekWorkoutCount,
              monthCount: monthWorkoutCount,
              weekTotalMins: weekWorkoutTotalMins,
              monthTotalMins: monthWorkoutTotalMins,
              weekCalories: weekWorkoutCalories,
              monthCalories: monthWorkoutCalories,
              avgDurationMins: avgWorkoutMins,
            ),

            // ── Recent activity list ───────────────────────────────────────
            const SizedBox(height: 16),
            SectionHeader(l10n.activitiesRecentActivity,
                icon: Icons.history, color: cs.secondary),
            const SizedBox(height: 8),
            if (!fitness.workoutPermissionGranted)
              WorkoutPermissionCard(
                  onGrant: () => fitness.requestWorkoutPermission())
            else
              WorkoutList(activities: fitness.activities, locale: locale),
          ],
        );
      },
    );
  }
}
