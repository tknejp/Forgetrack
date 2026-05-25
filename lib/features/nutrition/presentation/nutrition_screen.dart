import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/fitness_provider.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/kaloricke_tabulky_provider.dart';
import '../data/kaloricke_tabulky_service.dart';
import 'widgets/balance_card.dart';
import 'widgets/day_mode_only_hint.dart';
import 'widgets/hydration_card.dart';
import 'widgets/kt_sync_error_banner.dart';
import 'widgets/macro_trend_card.dart';
import 'widgets/meals_card.dart';
import 'widgets/not_connected_state.dart';
import 'widgets/today_header_card.dart';
import '../../onboarding/widgets/kt_login_sheet.dart';

/// Default daily hydration goal in liters (used when KT goal isn't pulled).
const _defaultHydrationGoalL = 2.5;

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  SelectedPeriod _period = SelectedPeriod.today();
  final Set<String> _expandedMeals = {};
  MacroAxis _macroAxis = MacroAxis.protein;
  bool _macroTrendExpanded = true;

  // Macro axis helpers

  double _macroGoalOf(GoalsProvider goals, MacroAxis axis) => switch (axis) {
        MacroAxis.protein => goals.dailyProtein,
        MacroAxis.fat => goals.dailyFat,
        MacroAxis.carbs => goals.dailyCarbs,
      };

  Domain _macroDomain(MacroAxis axis) => switch (axis) {
        MacroAxis.protein => Tokens.protein,
        MacroAxis.fat => Tokens.fat,
        MacroAxis.carbs => Tokens.carbs,
      };

  String _macroLabel(BuildContext context, MacroAxis axis) {
    final l10n = context.l10n;
    return switch (axis) {
      MacroAxis.protein => l10n.macroProtein,
      MacroAxis.fat => l10n.macroFat,
      MacroAxis.carbs => l10n.macroCarbs,
    };
  }

  // Period helpers

  String _periodDateLabel(BuildContext context, SelectedPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    switch (period.type) {
      case PeriodType.day:
        return DateFormat('EEE d MMM', locale).format(period.referenceDate);
      case PeriodType.week:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} - '
            '${end.day} ${DateFormat.MMM(locale).format(end)}';
      case PeriodType.month:
        return DateFormat.yMMM(locale).format(period.referenceDate);
      case PeriodType.custom:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} - '
            '${end.day} ${DateFormat.MMM(locale).format(end)}';
    }
  }

  void _changeTab(String tab) {
    final l10n = context.l10n;
    final type = tab == l10n.periodDay
        ? PeriodType.day
        : tab == l10n.periodWeek
            ? PeriodType.week
            : PeriodType.month;
    _setPeriod(_period.withType(type));
  }

  void _setPeriod(SelectedPeriod period) {
    setState(() => _period = period);
    context.read<KalorickeTabulkyProvider>().refreshRange(
          period.start,
          period.end,
        );
    context.read<FitnessProvider>().refreshRange(period.start, period.end);
  }

  String _tab(BuildContext context, SelectedPeriod period) =>
      period.type == PeriodType.week
          ? context.l10n.periodWeek
          : period.type == PeriodType.month
              ? context.l10n.periodMonth
              : context.l10n.periodDay;

  void _toggleMeal(String mealId) {
    setState(() {
      if (!_expandedMeals.add(mealId)) _expandedMeals.remove(mealId);
    });
  }

  String _mealEmoji(String id, String title) {
    switch (id) {
      case '1':
        return '🍳';
      case '2':
        return '🍎';
      case '3':
        return '🍽';
      case '4':
        return '🍫';
      case '5':
        return '🍲';
      case '6':
        return '🌙';
    }
    final lower = title.toLowerCase();
    if (lower.contains('snída')) return '🍳';
    if (lower.contains('oběd')) return '🍽';
    if (lower.contains('večeř')) return '🍲';
    return '🍴';
  }

  double _finite(double value) => value.isFinite ? value : 0.0;

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  /// Returns the list of periods that drive the energy chart, plus a parallel
  /// list of [ChartBar]s. Bar `i` corresponds to date `days[i]` so an
  /// `onBarTap(index)` can navigate to that day/week/month.
  ///
  /// Day mode falls back to the last 14 days so the chart never disappears.
  /// Week/month modes show weekly/monthly averages instead of daily bars,
  /// with the selected day highlighted via [ChartBar.isToday].
  ({List<SelectedPeriod> periods, List<ChartBar> bars}) _buildEnergyBars(
    BuildContext context,
    KalorickeTabulkyProvider kt,
    SelectedPeriod period,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<SelectedPeriod> periods;
    if (period.type == PeriodType.day) {
      periods = List.generate(
        14,
        (i) => SelectedPeriod.forDay(today.subtract(Duration(days: 13 - i))),
      );
    } else if (period.type == PeriodType.week) {
      final selectedStart = SelectedPeriod.currentWeek().start;
      periods = List.generate(
        26,
        (i) => SelectedPeriod.forWeek(
          selectedStart.subtract(Duration(days: 7 * (25 - i))),
        ),
      );
    } else {
      final selectedMonth = _monthStart(DateTime.now());
      periods = List.generate(
        24,
        (i) => SelectedPeriod.forMonth(
          DateTime(selectedMonth.year, selectedMonth.month - (23 - i), 1),
        ),
      );
    }

    final bars = periods.map((p) {
      final value = p.type == PeriodType.day
          ? _finite(kt.nutritionForDate(p.start)?.calories ?? 0)
          : _finite(
              kt.nutritionSummaryForRange(p.start, p.end)?.calories ?? 0,
            );
      final label = switch (p.type) {
        PeriodType.day => DateFormat.E(locale).format(p.start).substring(0, 1),
        PeriodType.week => DateFormat('d/M', locale).format(p.start),
        PeriodType.month => DateFormat.MMM(locale).format(p.start),
        PeriodType.custom => DateFormat.MMMd(locale).format(p.start),
      };
      final isHighlighted = p.start == period.start;
      return ChartBar(
        label: label,
        value: value,
        isToday: isHighlighted,
      );
    }).toList();

    return (periods: periods, bars: bars);
  }

  /// Period bars for the currently-selected macro axis. Same period window as
  /// [_buildEnergyBars] so a bar tap maps cleanly back to a date.
  ({List<SelectedPeriod> periods, List<ChartBar> bars}) _buildMacroBars(
    BuildContext context,
    KalorickeTabulkyProvider kt,
    SelectedPeriod period,
    MacroAxis axis,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<SelectedPeriod> periods;
    if (period.type == PeriodType.day) {
      periods = List.generate(
        14,
        (i) => SelectedPeriod.forDay(today.subtract(Duration(days: 13 - i))),
      );
    } else if (period.type == PeriodType.week) {
      final selectedStart = SelectedPeriod.currentWeek().start;
      periods = List.generate(
        26,
        (i) => SelectedPeriod.forWeek(
          selectedStart.subtract(Duration(days: 7 * (25 - i))),
        ),
      );
    } else {
      final selectedMonth = _monthStart(DateTime.now());
      periods = List.generate(
        24,
        (i) => SelectedPeriod.forMonth(
          DateTime(selectedMonth.year, selectedMonth.month - (23 - i), 1),
        ),
      );
    }

    final bars = periods.map((p) {
      final entry =
          p.type == PeriodType.day ? kt.nutritionForDate(p.start) : null;
      final summary = p.type == PeriodType.day
          ? null
          : kt.nutritionSummaryForRange(p.start, p.end);
      final value = _finite(switch (axis) {
        MacroAxis.protein => p.type == PeriodType.day
            ? (entry?.protein ?? 0)
            : (summary?.protein ?? 0),
        MacroAxis.fat =>
          p.type == PeriodType.day ? (entry?.fat ?? 0) : (summary?.fat ?? 0),
        MacroAxis.carbs => p.type == PeriodType.day
            ? (entry?.carbs ?? 0)
            : (summary?.carbs ?? 0),
      });
      final label = switch (p.type) {
        PeriodType.day => DateFormat.E(locale).format(p.start).substring(0, 1),
        PeriodType.week => DateFormat('d/M', locale).format(p.start),
        PeriodType.month => DateFormat.MMM(locale).format(p.start),
        PeriodType.custom => DateFormat.MMMd(locale).format(p.start),
      };
      final isHighlighted = p.start == period.start;
      return ChartBar(
        label: label,
        value: value,
        isToday: isHighlighted,
      );
    }).toList();

    return (periods: periods, bars: bars);
  }

  // Build

  Widget _buildContent(
    BuildContext context,
    KalorickeTabulkyProvider kt,
    GoalsProvider goals,
    FitnessProvider fitness,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);

    // Today header data
    final todayKcal = kt.todayCalories;
    final todayProtein = kt.todayProtein;
    final todayFat = kt.todayFat;
    final todayCarbs = kt.todayCarbs;
    final kcalGoal = goals.dailyCalories;
    final todayProgress =
        kcalGoal > 0 ? (todayKcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final todayPct = kcalGoal > 0 ? ((todayKcal / kcalGoal) * 100).round() : 0;
    final todayDiff = todayKcal - kcalGoal;

    // Period-driven values
    final isDayMode = _period.type == PeriodType.day;
    final periodNutrition =
        isDayMode ? kt.nutritionForDate(_period.start) : null;
    final periodSummary = isDayMode
        ? null
        : kt.nutritionSummaryForRange(_period.start, _period.end);

    final periodKcal = _finite(isDayMode
        ? (periodNutrition?.calories ?? 0)
        : (periodSummary?.calories ?? 0));
    final periodProtein = _finite(isDayMode
        ? (periodNutrition?.protein ?? 0)
        : (periodSummary?.protein ?? 0));
    final periodFat = _finite(
        isDayMode ? (periodNutrition?.fat ?? 0) : (periodSummary?.fat ?? 0));
    final periodCarbs = _finite(isDayMode
        ? (periodNutrition?.carbs ?? 0)
        : (periodSummary?.carbs ?? 0));
    final periodFiber = _finite(isDayMode
        ? (periodNutrition?.fiber ?? 0)
        : (periodSummary?.fiber ?? 0));
    final periodSugar = _finite(isDayMode
        ? (periodNutrition?.sugar ?? 0)
        : (periodSummary?.sugar ?? 0));
    final periodSatFat = _finite(isDayMode
        ? (periodNutrition?.saturatedFat ?? 0)
        : (periodSummary?.saturatedFat ?? 0));
    final periodSalt = _finite(
        isDayMode ? (periodNutrition?.salt ?? 0) : (periodSummary?.salt ?? 0));
    final periodHydration = _finite(isDayMode
        ? (periodNutrition?.drinkRegime ?? 0)
        : 0.0); // hydration only meaningful per-day

    final meals = isDayMode ? kt.mealsForDate(_period.start) : const <KtMeal>[];

    // Balance card data
    final basal = isDayMode
        ? _finite(fitness.basalCaloriesBurnedForDate(_period.start))
        : _finite(
            fitness.basalCaloriesBurnedAvgForRange(_period.start, _period.end));
    // Active = max(HC active-energy series, summed workout calories) so we
    // get a non-zero value whichever channel the user's HC source writes.
    final activeKcal = isDayMode
        ? _finite(fitness.bestActiveKcalForDate(_period.start))
        : _finite(
            fitness.bestActiveKcalAvgForRange(_period.start, _period.end));
    final output = basal + activeKcal;
    final intake = periodKcal;
    final balanceDelta = intake - output;

    final chart = _buildEnergyBars(context, kt, _period);
    final chartPeriods = chart.periods;
    final chartBars = chart.bars;

    final macroChart = _buildMacroBars(context, kt, _period, _macroAxis);
    final macroPeriods = macroChart.periods;
    final macroBars = macroChart.bars;
    final macroDomain = _macroDomain(_macroAxis);
    final macroGoal = _macroGoalOf(goals, _macroAxis);
    final macroAvg = switch (_macroAxis) {
      MacroAxis.protein => periodProtein,
      MacroAxis.fat => periodFat,
      MacroAxis.carbs => periodCarbs,
    };

    return SwipePeriodGesture(
      onPrev: () => _setPeriod(_period.backward()),
      onNext: _period.canGoForward ? () => _setPeriod(_period.forward()) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (KtSyncStatusBanner.isActive(kt)) ...[
            KtSyncStatusBanner(
              kt: kt,
              onRetry: () => kt.refreshRange(_period.start, _period.end),
            ),
            const SizedBox(height: 10),
          ],

          // Today header data
          TodayHeaderCard(
            kcal: todayKcal,
            kcalGoal: kcalGoal,
            kcalDiff: todayDiff,
            progress: todayProgress,
            progressPct: todayPct,
            protein: todayProtein,
            fat: todayFat,
            carbs: todayCarbs,
          ),

          const SizedBox(height: 10),

          PeriodNavigator(
            domain: Tokens.calories,
            tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
            activeTab: _tab(context, _period),
            onTabChange: _changeTab,
            dateLabel: _periodDateLabel(context, _period),
            canGoForward: _period.canGoForward,
            isCurrentPeriod: _period.isCurrentPeriod,
            onPrev: () => _setPeriod(_period.backward()),
            onNext: _period.canGoForward
                ? () => _setPeriod(_period.forward())
                : null,
            onToday: _period.isCurrentPeriod
                ? null
                : () => _setPeriod(_period.withType(_period.type)),
          ),

          const SizedBox(height: 10),

          HydrationCard(
            litersConsumed: periodHydration,
            goalLiters: _defaultHydrationGoalL,
            isDayMode: isDayMode,
          ),

          const SizedBox(height: 10),

          if (chartBars.isNotEmpty)
            TrendCard(
              domain: Tokens.calories,
              icon: Icons.local_fire_department_rounded,
              title: l10n.nutritionEnergyTrend,
              subtitle: _periodDateLabel(context, _period),
              collapsible: true,
              initiallyExpanded: true,
              metrics: [
                TrendMetric(
                  label: l10n.weightAverage,
                  value: fmt.format(periodKcal.round()),
                ),
                TrendMetric(
                  label: l10n.weightGoal,
                  value: fmt.format(kcalGoal.round()),
                ),
              ],
              bars: chartBars,
              referenceValue: kcalGoal.toDouble(),
              referenceLabel: l10n.weightGoal,
              emptyLabel: l10n.bodyNoData,
              expandable: chartBars.length > 4,
              scrollableMinBarWidth: 34,
              onBarTap: (index) => _setPeriod(chartPeriods[index]),
            ),

          const SizedBox(height: 10),

          MacroTrendCard(
            title: l10n.nutritionMacroTrend,
            subtitle: _periodDateLabel(context, _period),
            axis: _macroAxis,
            domain: macroDomain,
            macroLabel: _macroLabel(context, _macroAxis),
            avg: macroAvg,
            goal: macroGoal,
            bars: macroBars,
            protein: periodProtein,
            fat: periodFat,
            carbs: periodCarbs,
            fiber: periodFiber,
            sugar: periodSugar,
            saturatedFat: periodSatFat,
            salt: periodSalt,
            proteinGoal: goals.dailyProtein,
            fatGoal: goals.dailyFat,
            carbsGoal: goals.dailyCarbs,
            expanded: _macroTrendExpanded,
            onToggleExpanded: () => setState(
              () => _macroTrendExpanded = !_macroTrendExpanded,
            ),
            onAxisChange: (axis) => setState(() => _macroAxis = axis),
            onBarTap: (index) => _setPeriod(macroPeriods[index]),
          ),

          const SizedBox(height: 10),

          BalanceCard(
            basal: basal,
            active: activeKcal,
            output: output,
            intake: intake,
            delta: balanceDelta,
            isAverage: !isDayMode,
          ),

          if (isDayMode) ...[
            const SizedBox(height: 10),
            MealsCard(
              meals: meals,
              expanded: _expandedMeals,
              onToggleMeal: _toggleMeal,
              emojiFor: _mealEmoji,
            ),
          ] else ...[
            const SizedBox(height: 10),
            const DayModeOnlyHint(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();
    final fitness = context.watch<FitnessProvider>();

    // Allow read-only access to cached data while logged out — the
    // offline state surfaces via the inline status banner. Only fall
    // through to the empty NotConnectedState when there's no cache at
    // all (defensive fallback — the home prompt hides the entry point
    // into this screen in that case).
    if (!kt.isLoggedIn && !kt.hasCachedNutrition) {
      return NotConnectedState(
        onConnect: () => KTLoginSheet.show(context),
      );
    }

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => kt.refresh(),
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
                        title: context.l10n.screenNutrition,
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
                  child: _buildContent(context, kt, goals, fitness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
