import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../features/auth/application/auth_provider.dart';
import '../../../../features/health_connect/application/goals_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/section_head.dart';
import '../../../../shared/widgets/top_level_app_bar.dart';
import '../../application/fitness_provider.dart';
import '../hc_state_widgets.dart';
import 'widgets/activity_cards.dart';
import 'widgets/workout_section.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
            isSignedIn: auth.isSignedIn,
            photoUrl: auth.user?.photoUrl,
            displayName: auth.user?.displayName,
            email: auth.user?.email,
            sessionStateKey: auth.sessionState.name,
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
        final monthStart = today.subtract(const Duration(days: 29));
        final monthStepsHistory =
            fitness.stepsHistoryForRange(monthStart, today);
        final monthActivities = fitness.activities.where((activity) { // lint-ignore: widget-no-logic — UI period slice (month) for chart rendering
          final day = DateTime(
            activity.startTime.year,
            activity.startTime.month,
            activity.startTime.day,
          );
          return !day.isBefore(monthStart) && !day.isAfter(today);
        }).toList();

        int todayActiveMins = 0;
        int weekActiveMins = 0;
        int weekWorkoutCount = 0;
        int weekWorkoutTotalMins = 0;
        int weekWorkoutCalories = 0;
        int monthWorkoutTotalMins = 0;
        int monthWorkoutCalories = 0;
        for (final a in monthActivities) {
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
        final monthWorkoutCount = monthActivities.length;
        final avgWorkoutMins = monthWorkoutCount > 0
            ? (monthWorkoutTotalMins / monthWorkoutCount).round()
            : 0;

        final chartHistory = fitness.stepsHistory.length >= 7
            ? fitness.stepsHistory.sublist(fitness.stepsHistory.length - 7)
            : fitness.stepsHistory;

        final avgSteps = monthStepsHistory.isEmpty
            ? 0
            : (monthStepsHistory.map((e) => e.steps).reduce((a, b) => a + b) /
                    monthStepsHistory.length)
                .round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            // ── Steps summary ──────────────────────────────────────────────
            SectionHead(label: l10n.stepsTitle, accent: tokens.steps.accent),
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
              SectionHead(label: l10n.activitiesWeeklyTrend, accent: tokens.steps.accent),
              const SizedBox(height: 8),
              StepsTrendCard(history: chartHistory, locale: locale),
            ],

            // ── Active calories ────────────────────────────────────────────
            const SizedBox(height: 16),
            SectionHead(label: l10n.activitiesActiveCalories, accent: tokens.nutrition.accent),
            const SizedBox(height: 8),
            ActiveCaloriesCard(
              today: fitness.activeCaloriesBurnedToday,
              week: fitness.activeCaloriesBurnedWeek,
              month: fitness.activeCaloriesBurnedMonth,
            ),

            // ── Active minutes ─────────────────────────────────────────────
            const SizedBox(height: 16),
            SectionHead(label: l10n.activitiesActiveMins, accent: tokens.steps.accent),
            const SizedBox(height: 8),
            ActiveMinsCard(
              todayMins: todayActiveMins,
              weekMins: weekActiveMins,
              weeklyGoal: goals.weeklyActivityMins,
            ),

            // ── Workout stats ──────────────────────────────────────────────
            const SizedBox(height: 16),
            SectionHead(label: l10n.activitiesWorkouts, accent: cs.secondary),
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
            SectionHead(label: l10n.activitiesRecentActivity, accent: cs.secondary),
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
