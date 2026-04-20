import 'dart:async';
import 'dart:ui';

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
import '../../widgets/parallax_background.dart';
import '../../widgets/top_level_app_bar.dart';
import '../activities/activities_screen.dart';
import '../body/body_screen.dart';
import '../calories/calories_screen.dart';
import 'widgets/calorie_summary_card.dart';
import 'widgets/sleep_card.dart';
import 'widgets/steps_card.dart';
import 'widgets/weight_card.dart';

part 'home_screen/home_navigation_bar.dart';
part 'home_screen/overview_sections.dart';
part 'home_screen/overview_states.dart';
part 'home_screen/period_header.dart';

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
    _scrollNotifier.value = _tabScrollOffsets[index];
  }

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
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
              return false;
            },
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _HomeNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
      ),
    );
  }
}

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
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }
      context.read<FitnessProvider>().initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
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
          appBar: TopLevelAppBar(
            title: 'FORGETRACK',
            subtitle: buildTopLevelHeaderSubtitle(
              context,
              syncCopy: AppHeaderSyncCopy.health,
              syncedAt: fitness.lastSyncedAt,
            ),
            emphasizeTitle: true,
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

        return _OverviewScrollableContent(
          fitness: fitness,
          kt: kt,
          period: period,
          onPeriodChanged: onPeriodChanged,
          metrics: metrics,
          dailyCaloriesGoal: goals.dailyCalories,
          dailyProteinGoal: goals.dailyProtein,
          dailyFatGoal: goals.dailyFat,
          dailyCarbsGoal: goals.dailyCarbs,
        );
      },
    );
  }
}

class _ResolvedOverviewMetrics {
  final int stepsValue;
  final int stepsGoal;
  final List<StepsRecord> stepsChartHistory;
  final double caloriesBurned;
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
    FitnessProvider fitness,
    DateTime date,
    double targetWeight,
  ) {
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
    FitnessProvider fitness,
    DateTime weekStart,
    double targetWeight,
  ) {
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
    FitnessProvider fitness,
    DateTime monthRef,
    double targetWeight,
  ) {
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
    final history = fitness.stepsHistory;
    return history.length >= 7
        ? history.sublist(history.length - 7)
        : history;
  }
}
