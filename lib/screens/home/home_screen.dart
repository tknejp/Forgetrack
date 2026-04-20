import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_log.dart';
import '../../l10n/l10n.dart';
import '../../models/activity_record.dart';
import '../../models/selected_period.dart';
import '../../models/sleep_record.dart';
import '../../models/weight_card_data.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/kaloricke_tabulky_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/profile_avatar_action.dart';
import '../../widgets/screen_meta_footer.dart';
import '../activities/activities_screen.dart';
import '../body/body_screen.dart';
import '../calories/calories_screen.dart';
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

  // Per-tab scroll position so the background snaps to the right depth
  // when switching back to a previously-scrolled tab.
  final _tabScrollOffsets = [0.0, 0.0, 0.0, 0.0];
  final _scrollNotifier = ValueNotifier<double>(0.0);

  static const _screens = [
    _OverviewTab(),
    ActivitiesScreen(),
    NutritionScreen(),
    BodyScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    // Immediately restore the stored scroll depth for the incoming tab.
    _scrollNotifier.value = _tabScrollOffsets[index];
  }

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ParallaxBackground(
            tabIndex: _selectedIndex,
            tabCount: _screens.length,
            scrollNotifier: _scrollNotifier,
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final pixels = notification.metrics.pixels;
              _tabScrollOffsets[_selectedIndex] = pixels;
              _scrollNotifier.value = pixels;
              return false; // let the scroll event propagate normally
            },
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: context.tokens.subtleShadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.18
                    : 0.06,
              ),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
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
      ),
    );
  }
}

// ─── Shared refresh ───────────────────────────────────────────────────────────

Future<void> _refreshOverview(
  FitnessProvider fitness,
  KalorickeTabulkyProvider kt,
  SelectedPeriod period,
) async {
  await Future.wait([
    fitness.refresh(),
    if (kt.isLoggedIn) kt.refreshRange(period.start, period.end),
  ]);
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab>
    with WidgetsBindingObserver {
  SelectedPeriod _period = SelectedPeriod.today();
  Timer? _refreshDebounce;

  void _onPeriodChanged(SelectedPeriod period) {
    setState(() => _period = period);
    // Fetch fresh API data for the newly selected day — debounced to avoid
    // firing on every frame during a fast swipe.
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final kt = context.read<KalorickeTabulkyProvider>();
      if (kt.isLoggedIn && !kt.isRefreshing) {
        kt.refreshRange(period.start, period.end);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FitnessProvider>().initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(context.read<FitnessProvider>().initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FitnessProvider, KalorickeTabulkyProvider>(
      builder: (context, fitness, kt, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const AppBrandLockup(
              iconSize: 30,
              wordmarkHeight: 19,
              gap: 10,
            ),
            actions: [
              const ProfileAvatarAction(),
            ],
          ),
          body: _OverviewBody(
            fitness: fitness,
            kt: kt,
            period: _period,
            onPeriodChanged: _onPeriodChanged,
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
  final SelectedPeriod period;
  final ValueChanged<SelectedPeriod> onPeriodChanged;

  const _OverviewBody({
    required this.fitness,
    required this.kt,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (fitness.accessState) {
      case FitnessAccessState.checking:
        return const Center(child: CircularProgressIndicator());
      case FitnessAccessState.unavailable:
        return _HealthUnavailableState(fitness: fitness);
      case FitnessAccessState.permissionRequired:
        return _PermissionRequiredState(fitness: fitness);
      case FitnessAccessState.ready:
        break;
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
  final SelectedPeriod period;
  final ValueChanged<SelectedPeriod> onPeriodChanged;

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
    final isDay = period.type == PeriodType.day;

    return Consumer2<CalorieProvider, GoalsProvider>(
      builder: (context, calorie, goals, _) {
        final metrics = _ResolvedOverviewMetrics.resolve(
          fitness: fitness,
          kt: kt,
          calorie: calorie,
          period: period,
          dailyStepGoal: goals.dailySteps,
          targetWeight: goals.targetWeight,
        );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v.abs() < 300) return;
              // swipe right = previous, swipe left = next
              final updated = v > 0 ? period.backward() : period.forward();
              if (updated != period) onPeriodChanged(updated);
            },
            child: RefreshIndicator(
              key: ValueKey(period),
              onRefresh: () => _refreshOverview(fitness, kt, period),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 16),
                  _PeriodHeader(
                    period: period,
                    locale: locale,
                    onPeriodChanged: onPeriodChanged,
                  ),
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
                      onRetry: () => kt.refreshRange(period.start, period.end),
                    ),
                  ],
                  const SizedBox(height: 16),
                  StepsCard(
                    todaySteps: metrics.stepsValue,
                    goal: metrics.stepsGoal,
                    history: metrics.stepsChartHistory,
                    mainLabel: period.type == PeriodType.day
                        ? l10n.stepsCurrent
                        : l10n.stepsAverage,
                  ),
                  const SizedBox(height: 12),
                  CalorieSummaryCard(
                    consumed: metrics.consumedCalories,
                    burned: metrics.caloriesBurned,
                    goal: goals.dailyCalories,
                    protein: metrics.protein ?? 0,
                    fat: metrics.fat ?? 0,
                    carbs: metrics.carbs ?? 0,
                    fiber: metrics.fiber ?? 0,
                    proteinGoal: goals.dailyProtein,
                    fatGoal: goals.dailyFat,
                    carbsGoal: goals.dailyCarbs,
                    title: isDay ? null : l10n.caloriesAvgPerDay,
                  ),
                  const SizedBox(height: 12),
                  WeightCard(data: metrics.weightCard),
                  const SizedBox(height: 12),
                  if (metrics.sleep != null)
                    SleepCard(sleep: metrics.sleep)
                  else if (metrics.avgSleep != null)
                    SleepCard(avgDuration: metrics.avgSleep)
                  else
                    const _NoSleepDataCard(),
                  if (fitness.lastSyncedAt != null) ...[
                    const SizedBox(height: 14),
                    ScreenMetaFooter(
                      text: l10n.healthLastSynced(
                        DateFormat('HH:mm', locale)
                            .format(fitness.lastSyncedAt!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Resolved overview metrics ────────────────────────────────────────────────

class _ResolvedOverviewMetrics {
  final int stepsValue;
  final int stepsGoal;
  final List<StepsRecord> stepsChartHistory;
  final double caloriesBurned;

  /// Consumed kcal — null when historical data is unavailable (week/month).
  final double? consumedCalories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? fiber;

  final SleepRecord? sleep;
  final Duration? avgSleep;

  final WeightCardData weightCard;

  const _ResolvedOverviewMetrics({
    required this.stepsValue,
    required this.stepsGoal,
    required this.stepsChartHistory,
    required this.caloriesBurned,
    required this.consumedCalories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sleep,
    required this.avgSleep,
    required this.weightCard,
  });

  factory _ResolvedOverviewMetrics.resolve({
    required FitnessProvider fitness,
    required KalorickeTabulkyProvider kt,
    required CalorieProvider calorie,
    required SelectedPeriod period,
    required int dailyStepGoal,
    required double targetWeight,
  }) {
    final start = period.start;
    final end = period.end;

    AppLog.ktUi.debug(
      'resolve() period=${period.type.name} '
      'ktLoggedIn=${kt.isLoggedIn} ktToday=${kt.hasTodayData} '
      'ktSynced=${kt.lastSyncedAt?.toIso8601String() ?? "never"}',
    );

    switch (period.type) {
      case PeriodType.day:
        final isToday = period.isCurrentPeriod;
        final dayNutrition = kt.nutritionForDate(start);
        final consumed = dayNutrition != null
            ? dayNutrition.calories
            : (isToday ? calorie.todayKcal : null);
        AppLog.ktUi.debug(
          'Day card data source=${dayNutrition != null ? "KT" : (isToday ? "calorie-fallback" : "null")}',
          payload: 'consumed=$consumed, P=${dayNutrition?.protein}, '
              'F=${dayNutrition?.fat}, C=${dayNutrition?.carbs}, '
              'fiber=${dayNutrition?.fiber}',
        );
        return _ResolvedOverviewMetrics(
          stepsValue: fitness.stepsForDate(start),
          stepsGoal: dailyStepGoal,
          stepsChartHistory: _last7Steps(fitness),
          caloriesBurned: fitness.activeCaloriesBurnedForDate(start),
          consumedCalories: consumed,
          protein: dayNutrition?.protein,
          fat: dayNutrition?.fat,
          carbs: dayNutrition?.carbs,
          fiber: dayNutrition?.fiber,
          sleep: fitness.sleepForDate(start),
          avgSleep: null,
          weightCard: _buildDayWeight(fitness, start, targetWeight),
        );

      case PeriodType.week:
        final avgKcal = kt.avgCaloriesForRange(start, end);
        AppLog.ktUi.debug(
          'Week card avg nutrition',
          payload: 'kcal=$avgKcal, P=${kt.avgProteinForRange(start, end)}, '
              'F=${kt.avgFatForRange(start, end)}, C=${kt.avgCarbsForRange(start, end)}, '
              'fiber=${kt.avgFiberForRange(start, end)}',
        );
        return _ResolvedOverviewMetrics(
          stepsValue: fitness.stepsAvgForRange(start, end),
          stepsGoal: dailyStepGoal,
          stepsChartHistory: fitness.stepsHistoryForRange(start, end),
          caloriesBurned: fitness.activeCaloriesBurnedAvgForRange(start, end),
          consumedCalories: avgKcal,
          protein: kt.avgProteinForRange(start, end),
          fat: kt.avgFatForRange(start, end),
          carbs: kt.avgCarbsForRange(start, end),
          fiber: kt.avgFiberForRange(start, end),
          sleep: null,
          avgSleep: fitness.avgSleepForRange(start, end),
          weightCard: _buildWeekWeight(fitness, start, targetWeight),
        );

      case PeriodType.month:
      case PeriodType.custom:
        final avgKcal = kt.avgCaloriesForRange(start, end);
        AppLog.ktUi.debug(
          'Month/custom card avg nutrition',
          payload: 'kcal=$avgKcal, P=${kt.avgProteinForRange(start, end)}, '
              'F=${kt.avgFatForRange(start, end)}, C=${kt.avgCarbsForRange(start, end)}, '
              'fiber=${kt.avgFiberForRange(start, end)}',
        );
        return _ResolvedOverviewMetrics(
          stepsValue: fitness.stepsAvgForRange(start, end),
          stepsGoal: dailyStepGoal,
          stepsChartHistory: fitness.stepsHistoryForRange(start, end),
          caloriesBurned: fitness.activeCaloriesBurnedAvgForRange(start, end),
          consumedCalories: avgKcal,
          protein: kt.avgProteinForRange(start, end),
          fat: kt.avgFatForRange(start, end),
          carbs: kt.avgCarbsForRange(start, end),
          fiber: kt.avgFiberForRange(start, end),
          sleep: null,
          avgSleep: fitness.avgSleepForRange(start, end),
          weightCard: _buildMonthWeight(fitness, start, targetWeight),
        );
    }
  }

  static WeightCardData _buildDayWeight(
      FitnessProvider fitness, DateTime date, double targetWeight) {
    final records = fitness.weightHistoryForRange(date, date);
    final measurement = records.isNotEmpty ? records.last : null;
    final mainValue = measurement?.weight;
    final bodyFat = measurement?.bodyFat ?? fitness.latestBodyFat;
    final prev = fitness.previousWeightBefore(date);
    final trend = mainValue != null && prev != null ? mainValue - prev : null;
    return WeightCardData(
      periodType: PeriodType.day,
      mainValue: mainValue,
      trendValue: trend,
      goalWeight: targetWeight,
      bodyFatPercent: bodyFat,
      chartPoints: fitness.dailyWeightChart(14),
      chartMode: WeightChartMode.daily,
    );
  }

  static WeightCardData _buildWeekWeight(
      FitnessProvider fitness, DateTime weekStart, double targetWeight) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final avg = fitness.weekAvgWeight(weekStart);
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevAvg = fitness.weekAvgWeight(prevWeekStart);
    final trend = avg != null && prevAvg != null ? avg - prevAvg : null;
    final records = fitness.weightHistoryForRange(weekStart, weekEnd);
    final min = records.isEmpty
        ? null
        : records.map((r) => r.weight).reduce((a, b) => a < b ? a : b);
    final max = records.isEmpty
        ? null
        : records.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
    return WeightCardData(
      periodType: PeriodType.week,
      mainValue: avg,
      trendValue: trend,
      goalWeight: targetWeight,
      periodMin: min,
      periodMax: max,
      chartPoints: fitness.weightChartForRange(weekStart, weekEnd),
      chartMode: WeightChartMode.weekly,
    );
  }

  static WeightCardData _buildMonthWeight(
      FitnessProvider fitness, DateTime monthRef, double targetWeight) {
    final monthStart = DateTime(monthRef.year, monthRef.month, 1);
    final monthEnd = DateTime(monthRef.year, monthRef.month + 1, 0);
    final avg = fitness.monthAvgWeight(monthRef);
    final prevMonthRef = DateTime(monthRef.year, monthRef.month - 1, 1);
    final prevAvg = fitness.monthAvgWeight(prevMonthRef);
    final trend = avg != null && prevAvg != null ? avg - prevAvg : null;
    final records = fitness.weightHistoryForRange(monthStart, monthEnd);
    final min = records.isEmpty
        ? null
        : records.map((r) => r.weight).reduce((a, b) => a < b ? a : b);
    final max = records.isEmpty
        ? null
        : records.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
    return WeightCardData(
      periodType: PeriodType.month,
      mainValue: avg,
      trendValue: trend,
      goalWeight: targetWeight,
      periodMin: min,
      periodMax: max,
      chartPoints: fitness.weightChartForRange(monthStart, monthEnd),
      chartMode: WeightChartMode.monthly,
    );
  }

  static List<StepsRecord> _last7Steps(FitnessProvider fitness) {
    final h = fitness.stepsHistory;
    return h.length >= 7 ? h.sublist(h.length - 7) : h;
  }
}

// ─── Period header ────────────────────────────────────────────────────────────

class _PeriodHeader extends StatelessWidget {
  final SelectedPeriod period;
  final String locale;
  final ValueChanged<SelectedPeriod> onPeriodChanged;

  const _PeriodHeader({
    required this.period,
    required this.locale,
    required this.onPeriodChanged,
  });

  String _label(BuildContext context) {
    switch (period.type) {
      case PeriodType.day:
        return DateFormat('EEE d. M.', locale).format(period.referenceDate);
      case PeriodType.week:
        return '${DateFormat('d. M.', locale).format(period.start)}'
            ' – '
            '${DateFormat('d. M.', locale).format(period.end)}';
      case PeriodType.month:
        return DateFormat('MMMM yyyy', locale).format(period.referenceDate);
      case PeriodType.custom:
        return '${DateFormat('d. M.', locale).format(period.start)}'
            ' – '
            '${DateFormat('d. M.', locale).format(period.end)}';
    }
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: period.referenceDate,
      firstDate: DateTime(2020),
      lastDate: todayOnly,
    );
    if (picked == null) return;
    onPeriodChanged(SelectedPeriod.forDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDay = period.type == PeriodType.day;
    final isToday = period.isCurrentPeriod;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<PeriodType>(
                segments: [
                  ButtonSegment(
                    value: PeriodType.day,
                    label: Text(l10n.periodDay),
                  ),
                  ButtonSegment(
                    value: PeriodType.week,
                    label: Text(l10n.periodWeek),
                  ),
                  ButtonSegment(
                    value: PeriodType.month,
                    label: Text(l10n.periodMonth),
                  ),
                ],
                selected: {
                  period.type == PeriodType.custom
                      ? PeriodType.day
                      : period.type
                },
                onSelectionChanged: (s) =>
                    onPeriodChanged(period.withType(s.first)),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onPeriodChanged(period.backward()),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: GestureDetector(
                onTap: isDay ? () => _openDatePicker(context) : null,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDay && isToday) ...[
                        Icon(Icons.circle, size: 7, color: cs.primary),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _label(context),
                        style: tt.labelLarge?.copyWith(
                          color: isDay && isToday ? cs.primary : cs.onSurface,
                          fontWeight: isDay && isToday ? FontWeight.w600 : null,
                        ),
                      ),
                      if (isDay) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isDay && !isToday)
              SizedBox(
                height: 32,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onPeriodChanged(SelectedPeriod.today()),
                  child: Text(
                    l10n.headerToday,
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: period.canGoForward
                  ? () => onPeriodChanged(period.forward())
                  : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.18)),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.tokens.sleep.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bedtime_outlined,
                color: context.tokens.sleep.accent,
              ),
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
