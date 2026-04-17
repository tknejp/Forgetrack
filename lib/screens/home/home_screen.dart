import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../l10n/l10n.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/kaloricke_tabulky_provider.dart';
import '../activities/activities_screen.dart';
import '../body/body_screen.dart';
import '../calories/calories_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/calorie_summary_card.dart';
import 'widgets/sleep_card.dart';
import 'widgets/steps_card.dart';
import 'widgets/weight_card.dart';

// ─── Home shell ───────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    _OverviewTab(),
    ActivitiesScreen(),
    NutritionScreen(),
    BodyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navOverview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_run_outlined),
            selectedIcon: const Icon(Icons.directions_run),
            label: l10n.navActivities,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: l10n.navNutrition,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: l10n.navBody,
          ),
        ],
      ),
    );
  }
}

// ─── Overview period ──────────────────────────────────────────────────────────

enum _Period { today, week, month }

// ─── Shared refresh ───────────────────────────────────────────────────────────

Future<void> _refreshOverview(
  FitnessProvider fitness,
  KalorickeTabulkyProvider kt,
) async {
  await Future.wait([
    fitness.refresh(),
    if (kt.isLoggedIn) kt.refresh(),
  ]);
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  _Period _period = _Period.today;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FitnessProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer2<FitnessProvider, KalorickeTabulkyProvider>(
      builder: (context, fitness, kt, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _OverviewBody(
            fitness: fitness,
            kt: kt,
            period: _period,
            onPeriodChanged: (period) => setState(() => _period = period),
          ),
        );
      },
    );
  }
}

// ─── Overview body ────────────────────────────────────────────────────────────

class _OverviewBody extends StatelessWidget {
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider kt;
  final _Period period;
  final ValueChanged<_Period> onPeriodChanged;

  const _OverviewBody({
    required this.fitness,
    required this.kt,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (fitness.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!fitness.isHealthConnectAvailable) {
      return _HealthUnavailableState(fitness: fitness);
    }

    if (!fitness.hasPermissions) {
      return _PermissionRequiredState(fitness: fitness);
    }

    return _OverviewContent(
      fitness: fitness,
      kt: kt,
      period: period,
      onPeriodChanged: onPeriodChanged,
    );
  }
}

// ─── Overview content ─────────────────────────────────────────────────────────

class _OverviewContent extends StatelessWidget {
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider kt;
  final _Period period;
  final ValueChanged<_Period> onPeriodChanged;

  const _OverviewContent({
    required this.fitness,
    required this.kt,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final metrics = _ResolvedOverviewMetrics.fromFitness(
      fitness: fitness,
      period: period,
    );

    final stepsChartHistory = fitness.stepsHistory.length >= 7
        ? fitness.stepsHistory.sublist(fitness.stepsHistory.length - 7)
        : fitness.stepsHistory;

    return Consumer<CalorieProvider>(
      builder: (context, calorie, _) {
        final useKt = kt.isLoggedIn && kt.hasLoadedToday && kt.syncError == null;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: RefreshIndicator(
            key: ValueKey(period),
            onRefresh: () => _refreshOverview(fitness, kt),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),

                _PeriodSelector(
                  period: period,
                  onChanged: onPeriodChanged,
                ),

                if (fitness.lastSyncedAt != null) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      l10n.healthLastSynced(
                        DateFormat('HH:mm', locale).format(fitness.lastSyncedAt!),
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],

                if (fitness.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  _InlineErrorBanner(
                    icon: Icons.error_outline,
                    message: l10n.healthSyncFailed,
                    onRetry: fitness.refresh,
                  ),
                ],

                if (kt.isLoggedIn && kt.syncError != null) ...[
                  const SizedBox(height: 10),
                  _InlineErrorBanner(
                    icon: Icons.restaurant_menu,
                    message: kt.syncError!,
                    onRetry: kt.refresh,
                  ),
                ],

                const SizedBox(height: 16),

                StepsCard(
                  todaySteps: metrics.stepsValue,
                  goal: metrics.stepsGoal,
                  history: stepsChartHistory,
                ),
                const SizedBox(height: 12),

                CalorieSummaryCard(
                  consumed: useKt ? kt.todayCalories : calorie.todayKcal,
                  burned: metrics.caloriesBurned,
                  goal: AppConstants.defaultCalorieGoal,
                  protein: useKt ? kt.todayProtein : 0,
                  fat: useKt ? kt.todayFat : 0,
                  carbs: useKt ? kt.todayCarbs : 0,
                  fiber: useKt ? kt.todayFiber : 0,
                ),
                const SizedBox(height: 12),

                if (fitness.latestWeight != null)
                  WeightCard(
                    currentWeight: fitness.latestWeight!,
                    goalWeight: AppConstants.defaultWeightGoal,
                    bodyFatPercent: fitness.latestBodyFat,
                    history: fitness.weightHistory,
                  )
                else
                  const _NoWeightDataCard(),
                const SizedBox(height: 12),

                if (fitness.todaySleep != null)
                  SleepCard(sleep: fitness.todaySleep!)
                else
                  const _NoSleepDataCard(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Derived metrics ──────────────────────────────────────────────────────────

class _ResolvedOverviewMetrics {
  final int stepsValue;
  final int stepsGoal;
  final double caloriesBurned;

  const _ResolvedOverviewMetrics({
    required this.stepsValue,
    required this.stepsGoal,
    required this.caloriesBurned,
  });

  factory _ResolvedOverviewMetrics.fromFitness({
    required FitnessProvider fitness,
    required _Period period,
  }) {
    switch (period) {
      case _Period.today:
        return _ResolvedOverviewMetrics(
          stepsValue: fitness.todaySteps,
          stepsGoal: AppConstants.dailyStepGoal,
          caloriesBurned: fitness.activeCaloriesBurnedToday,
        );
      case _Period.week:
        return _ResolvedOverviewMetrics(
          stepsValue: fitness.stepsWeekTotal,
          stepsGoal: AppConstants.weeklyStepGoal,
          caloriesBurned: fitness.activeCaloriesBurnedWeek,
        );
      case _Period.month:
        return _ResolvedOverviewMetrics(
          stepsValue: fitness.stepsMonthTotal,
          stepsGoal: AppConstants.monthlyStepGoal,
          caloriesBurned: fitness.activeCaloriesBurnedMonth,
        );
    }
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({
    required this.period,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SegmentedButton<_Period>(
      segments: [
        ButtonSegment(
          value: _Period.today,
          label: Text(l10n.periodToday),
        ),
        ButtonSegment(
          value: _Period.week,
          label: Text(l10n.periodWeek),
        ),
        ButtonSegment(
          value: _Period.month,
          label: Text(l10n.periodMonth),
        ),
      ],
      selected: {period},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

// ─── Health Connect unavailable ───────────────────────────────────────────────

class _HealthUnavailableState extends StatelessWidget {
  final FitnessProvider fitness;

  const _HealthUnavailableState({required this.fitness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.healthNotAvailable,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.healthNotAvailableBody,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.healthInstall),
              onPressed: fitness.installHealthConnect,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: fitness.initialize,
              child: Text(l10n.healthRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permission required ──────────────────────────────────────────────────────

class _PermissionRequiredState extends StatelessWidget {
  final FitnessProvider fitness;

  const _PermissionRequiredState({required this.fitness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 72,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.healthPermissionRequired,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.healthPermissionBody,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.healthGrantAccess),
              onPressed: fitness.requestPermissions,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared inline error banner ───────────────────────────────────────────────

class _InlineErrorBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorBanner({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: cs.onErrorContainer,
            ),
            onPressed: onRetry,
            child: Text(l10n.healthRetry),
          ),
        ],
      ),
    );
  }
}

// ─── No weight placeholder ────────────────────────────────────────────────────

class _NoWeightDataCard extends StatelessWidget {
  const _NoWeightDataCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weightTitle,
                  style: tt.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.emptyNoData,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No sleep placeholder ─────────────────────────────────────────────────────

class _NoSleepDataCard extends StatelessWidget {
  const _NoSleepDataCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.bedtime_outlined,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sleepTitle,
                  style: tt.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.sleepNoData,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}