import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/fitness_provider.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/ft_expand_chevron.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/kaloricke_tabulky_provider.dart';
import '../data/kaloricke_tabulky_service.dart';
import 'widgets/kt_sync_error_banner.dart';

/// Default daily hydration goal in liters (used when KT goal isn't pulled).
const _defaultHydrationGoalL = 2.5;

enum _MacroAxis { protein, fat, carbs }

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  SelectedPeriod _period = SelectedPeriod.today();
  final Set<String> _expandedMeals = {};
  _MacroAxis _macroAxis = _MacroAxis.protein;
  bool _macroTrendExpanded = true;

  // Macro axis helpers

  double _macroGoalOf(GoalsProvider goals, _MacroAxis axis) => switch (axis) {
        _MacroAxis.protein => goals.dailyProtein,
        _MacroAxis.fat => goals.dailyFat,
        _MacroAxis.carbs => goals.dailyCarbs,
      };

  Domain _macroDomain(_MacroAxis axis) => switch (axis) {
        _MacroAxis.protein => Tokens.protein,
        _MacroAxis.fat => Tokens.fat,
        _MacroAxis.carbs => Tokens.carbs,
      };

  String _macroLabel(BuildContext context, _MacroAxis axis) {
    final l10n = context.l10n;
    return switch (axis) {
      _MacroAxis.protein => l10n.macroProtein,
      _MacroAxis.fat => l10n.macroFat,
      _MacroAxis.carbs => l10n.macroCarbs,
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
    _MacroAxis axis,
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
        _MacroAxis.protein => p.type == PeriodType.day
            ? (entry?.protein ?? 0)
            : (summary?.protein ?? 0),
        _MacroAxis.fat =>
          p.type == PeriodType.day ? (entry?.fat ?? 0) : (summary?.fat ?? 0),
        _MacroAxis.carbs => p.type == PeriodType.day
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
        : _finite(fitness.basalCaloriesBurnedAvgForRange(_period.start, _period.end));
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
      _MacroAxis.protein => periodProtein,
      _MacroAxis.fat => periodFat,
      _MacroAxis.carbs => periodCarbs,
    };

    return SwipePeriodGesture(
      onPrev: () => _setPeriod(_period.backward()),
      onNext: _period.canGoForward ? () => _setPeriod(_period.forward()) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kt.syncError != null) ...[
            KtSyncErrorBanner(
              onRetry: () => kt.refreshRange(_period.start, _period.end),
            ),
            const SizedBox(height: 10),
          ],

          // Today header data
          _TodayHeaderCard(
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

          _HydrationCard(
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

          _MacroTrendCard(
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

          _BalanceCard(
            basal: basal,
            active: activeKcal,
            output: output,
            intake: intake,
            delta: balanceDelta,
            isAverage: !isDayMode,
          ),

          if (isDayMode) ...[
            const SizedBox(height: 10),
            _MealsCard(
              meals: meals,
              expanded: _expandedMeals,
              onToggleMeal: _toggleMeal,
              emojiFor: _mealEmoji,
            ),
          ] else ...[
            const SizedBox(height: 10),
            _DayModeOnlyHint(),
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

    if (!kt.isLoggedIn) {
      return _NotConnectedState(
        onConnect: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
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

// Today header data

class _TodayHeaderCard extends StatelessWidget {
  const _TodayHeaderCard({
    required this.kcal,
    required this.kcalGoal,
    required this.kcalDiff,
    required this.progress,
    required this.progressPct,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final double kcal;
  final double kcalGoal;
  final double kcalDiff;
  final double progress;
  final int progressPct;
  final double protein;
  final double fat;
  final double carbs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatCard(
      icon: '🔥',
      label: '${l10n.caloriesTodayTitle} · ${l10n.headerToday}',
      domain: Tokens.calories,
      visualAssets: DashboardCardAssetResolver.forKind(
        DashboardCardKind.nutrition,
      ),
      initiallyExpanded: true,
      collapsible: false,
      stats: [
        StatStat(
          value: kcal.round().toString(),
          label: l10n.caloriesConsumed,
          unit: 'kcal',
        ),
        StatStat(
          value: kcalGoal.round().toString(),
          label: l10n.weightGoal,
          unit: 'kcal',
        ),
        StatStat(
          value: '${kcalDiff >= 0 ? '+' : ''}${kcalDiff.round()}',
          label: kcalDiff >= 0 ? l10n.caloriesBurned : l10n.caloriesRemaining,
          unit: 'kcal',
        ),
      ],
      progress: progress,
      badge: '$progressPct%',
      children: [
        const SizedBox(height: 10),
        const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
        const SizedBox(height: Tokens.spaceSm),
        Row(
          children: [
            Expanded(
              child: _MacroChip(
                label: l10n.macroProtein,
                value: protein,
                color: Tokens.protein.color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MacroChip(
                label: l10n.macroFat,
                value: fat,
                color: Tokens.fat.color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MacroChip(
                label: l10n.macroCarbs,
                value: carbs,
                color: Tokens.carbs.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w600,
            color: ft.onSurfaceMuted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: value.round().toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0,
            ),
            children: [
              TextSpan(
                text: ' g',
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({
    required this.litersConsumed,
    required this.goalLiters,
    required this.isDayMode,
  });

  final double litersConsumed;
  final double goalLiters;
  final bool isDayMode;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.sleep; // water-blue
    final safeLiters = litersConsumed.isFinite ? litersConsumed : 0.0;
    final safeGoal = goalLiters.isFinite ? goalLiters : 0.0;
    final progress =
        safeGoal > 0 ? (safeLiters / safeGoal).clamp(0.0, 1.0) : 0.0;
    final pct = safeGoal > 0 ? ((safeLiters / safeGoal) * 100).round() : 0;

    return Container(
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
                child: const Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: Color(0xFF66C2E0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.nutritionHydrationTitle,
                      style: TextStyle(
                        fontSize: Tokens.fontSizeBody,
                        fontWeight: FontWeight.w700,
                        color: ft.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDayMode
                          ? '${safeLiters.toStringAsFixed(2)} l / '
                              '${safeGoal.toStringAsFixed(1)} l'
                          : l10n.nutritionMealsOnlyDayMode,
                      style: TextStyle(
                        fontSize: Tokens.fontSizeCaption,
                        fontWeight: FontWeight.w500,
                        color: ft.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDayMode)
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: Tokens.fontSizeBody,
                    fontWeight: FontWeight.w800,
                    color: domain.color,
                  ),
                ),
            ],
          ),
          if (isDayMode) ...[
            const SizedBox(height: Tokens.spaceMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: ft.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(domain.color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroDetailRow extends StatelessWidget {
  const _MacroDetailRow({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    this.isLast = false,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final safeValue = value.isFinite ? value : 0.0;
    final safeGoal = goal.isFinite ? goal : 0.0;
    final hasGoal = safeGoal > 0;
    final pct = hasGoal ? ((safeValue / safeGoal) * 100).round() : null;
    final pctColor = pct == null
        ? ft.onSurfaceMuted
        : pct < 70
            ? Tokens.danger.withValues(alpha: 0.85)
            : pct > 110
                ? Tokens.danger.withValues(alpha: 0.85)
                : color;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: ft.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ft.onSurface,
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              text: _fmtAmount(safeValue),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ft.onSurface,
              ),
              children: [
                if (hasGoal)
                  TextSpan(
                    text: ' / ${_fmtAmount(safeGoal)} $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ft.onSurfaceMuted,
                    ),
                  )
                else
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ft.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (pct != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pctColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: pctColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pctColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtAmount(double v) {
    if (v >= 100) return v.round().toString();
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

// Meals card

class _MealsCard extends StatelessWidget {
  const _MealsCard({
    required this.meals,
    required this.expanded,
    required this.onToggleMeal,
    required this.emojiFor,
  });

  final List<KtMeal> meals;
  final Set<String> expanded;
  final ValueChanged<String> onToggleMeal;
  final String Function(String id, String title) emojiFor;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.calories;
    final loggedMeals = meals.where((m) => m.hasFood).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
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
                child: Icon(Icons.restaurant_rounded,
                    size: 18, color: domain.color),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.nutritionMealsTitle,
                style: TextStyle(
                  fontSize: Tokens.fontSizeBody,
                  fontWeight: FontWeight.w700,
                  color: ft.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          if (loggedMeals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                l10n.nutritionMealsEmpty,
                style: TextStyle(fontSize: 13, color: ft.onSurfaceMuted),
              ),
            )
          else
            for (int i = 0; i < loggedMeals.length; i++)
              _MealRow(
                meal: loggedMeals[i],
                emoji: emojiFor(loggedMeals[i].id, loggedMeals[i].title),
                expanded: expanded.contains(loggedMeals[i].id),
                onTap: () => onToggleMeal(loggedMeals[i].id),
                isLast: i == loggedMeals.length - 1,
              ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.emoji,
    required this.expanded,
    required this.onTap,
    required this.isLast,
  });

  final KtMeal meal;
  final String emoji;
  final bool expanded;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final color = Tokens.calories.color;

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: ft.divider)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: Tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meal.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ft.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.nutritionFoodItems(meal.foodstuff.length),
                          style: TextStyle(
                            fontSize: Tokens.fontSizeMicro,
                            color: ft.onSurfaceMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: meal.energyTotal.round().toString(),
                      style: TextStyle(
                        fontSize: Tokens.fontSizeBody,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                      children: [
                        TextSpan(
                          text: ' kcal',
                          style: TextStyle(
                            fontSize: Tokens.fontSizeMicro,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ft.onSurfaceMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              heightFactor: expanded ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, Tokens.spaceSm),
                child: Column(
                  children: [
                    for (final f in meal.foodstuff) _FoodstuffRow(food: f),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodstuffRow extends StatelessWidget {
  const _FoodstuffRow({required this.food});

  final KtFoodstuff food;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  food.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ft.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${food.energy.round()} kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Tokens.calories.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              if (food.unit.isNotEmpty)
                Text(
                  food.unit,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: ft.onSurfaceMuted,
                  ),
                ),
              const Spacer(),
              _FoodMacroDot(
                value: food.protein,
                color: Tokens.protein.color,
                label: 'P',
              ),
              const SizedBox(width: 8),
              _FoodMacroDot(
                value: food.fat,
                color: Tokens.fat.color,
                label: 'F',
              ),
              const SizedBox(width: 8),
              _FoodMacroDot(
                value: food.carbs,
                color: Tokens.carbs.color,
                label: 'C',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodMacroDot extends StatelessWidget {
  const _FoodMacroDot({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        children: [
          TextSpan(
            text: '${value.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Balance card

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.basal,
    required this.active,
    required this.output,
    required this.intake,
    required this.delta,
    this.isAverage = false,
  });

  final double basal;
  final double active;
  final double output;
  final double intake;
  final double delta;
  final bool isAverage;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.calories;
    final safeBasal = basal.isFinite ? basal : 0.0;
    final safeActive = active.isFinite ? active : 0.0;
    final safeOutput = output.isFinite ? output : safeBasal + safeActive;
    final safeIntake = intake.isFinite ? intake : 0.0;
    final safeDelta = delta.isFinite ? delta : safeIntake - safeOutput;
    final isDeficit = safeDelta < 0;
    final badgeColor = isDeficit ? Tokens.weight.color : Tokens.danger;
    final badgeLabel =
        isDeficit ? l10n.nutritionBalanceDeficit : l10n.nutritionBalanceSurplus;

    return Container(
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
                child: Icon(
                  Icons.balance_rounded,
                  size: 18,
                  color: domain.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.nutritionBalanceTitle,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeBody,
                    fontWeight: FontWeight.w700,
                    color: ft.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${safeDelta >= 0 ? '+' : ''}${isAverage ? safeDelta.toStringAsFixed(1) : safeDelta.round()} kcal · $badgeLabel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          _BalanceRow(
            label: l10n.nutritionBalanceBasal,
            value: safeBasal,
            isAverage: isAverage,
          ),
          _BalanceRow(
            label: l10n.nutritionBalanceActive,
            value: safeActive,
            isAverage: isAverage,
          ),
          const Divider(color: Color(0x14FFFFFF), height: 18),
          _BalanceRow(
            label: l10n.nutritionBalanceOutput,
            value: safeOutput,
            isStrong: true,
            isAverage: isAverage,
          ),
          _BalanceRow(
            label: l10n.nutritionBalanceIntake,
            value: safeIntake,
            isStrong: true,
            valueColor: Tokens.calories.color,
            isLast: true,
            isAverage: isAverage,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.isStrong = false,
    this.valueColor,
    this.isLast = false,
    this.isAverage = false,
  });

  final String label;
  final double value;
  final bool isStrong;
  final Color? valueColor;
  final bool isLast;
  final bool isAverage;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final safeValue = value.isFinite ? value : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLast ? 4 : 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
              color: isStrong ? ft.onSurface : ft.onSurfaceMuted,
            ),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              text: isAverage ? safeValue.toStringAsFixed(1) : safeValue.round().toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor ?? ft.onSurface,
              ),
              children: [
                TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (valueColor ?? ft.onSurface).withValues(alpha: 0.7),
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

// Macro trend card
//
// Wraps a [TrendCard] with a P/F/C toggle row above the chart so the same
// card slot doubles as three "macro-axis" trends. Tap-to-bar maps back to a
// date via [onBarTap]; horizontal scrolling is enabled so month-mode
// (~30 bars) stays readable.

class _MacroTrendCard extends StatelessWidget {
  const _MacroTrendCard({
    required this.title,
    required this.subtitle,
    required this.axis,
    required this.domain,
    required this.macroLabel,
    required this.avg,
    required this.goal,
    required this.bars,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.saturatedFat,
    required this.salt,
    required this.proteinGoal,
    required this.fatGoal,
    required this.carbsGoal,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onAxisChange,
    required this.onBarTap,
  });

  final String title;
  final String subtitle;
  final _MacroAxis axis;
  final Domain domain;
  final String macroLabel;
  final double avg;
  final double goal;
  final List<ChartBar> bars;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double saturatedFat;
  final double salt;
  final double proteinGoal;
  final double fatGoal;
  final double carbsGoal;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<_MacroAxis> onAxisChange;
  final ValueChanged<int> onBarTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final safeAvg = avg.isFinite ? avg : 0.0;
    final safeGoal = goal.isFinite ? goal : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: domain.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleExpanded,
            child: Row(
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
                  child: Icon(
                    Icons.show_chart_rounded,
                    size: 18,
                    color: domain.color,
                  ),
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
                        '$macroLabel · $subtitle',
                        style: TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w500,
                          color: ft.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ExpandChevron(expanded: expanded),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Tokens.spaceMd),
                      Row(
                        children: [
                          for (final option in _MacroAxis.values) ...[
                            Expanded(
                              child: _MacroAxisChip(
                                axis: option,
                                selected: option == axis,
                                onTap: () => onAxisChange(option),
                              ),
                            ),
                            if (option != _MacroAxis.values.last)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      const SizedBox(height: Tokens.spaceMd),
                      TrendChartHelper(
                        bars: bars,
                        domain: domain,
                        referenceValue: safeGoal > 0 ? safeGoal : null,
                        onBarTap: onBarTap,
                        scrollableMinBarWidth: 34,
                      ),
                      if (safeGoal > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MacroLegend(
                              label: l10n.weightAverage,
                              value: '${safeAvg.round()} g',
                              color: domain.color,
                            ),
                            const SizedBox(width: 16),
                            _MacroLegend(
                              label: l10n.weightGoal,
                              value: '${safeGoal.round()} g',
                              color: ft.onSurfaceMuted,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: Tokens.spaceMd),
                      Divider(color: ft.divider, height: 1),
                      const SizedBox(height: Tokens.spaceXs),
                      _MacroDetailRow(
                        label: l10n.macroProtein,
                        value: protein,
                        goal: proteinGoal,
                        unit: 'g',
                        color: Tokens.protein.color,
                      ),
                      _MacroDetailRow(
                        label: l10n.macroFat,
                        value: fat,
                        goal: fatGoal,
                        unit: 'g',
                        color: Tokens.fat.color,
                      ),
                      _MacroDetailRow(
                        label: l10n.macroCarbs,
                        value: carbs,
                        goal: carbsGoal,
                        unit: 'g',
                        color: Tokens.carbs.color,
                      ),
                      _MacroDetailRow(
                        label: l10n.macroFiber,
                        value: fiber,
                        goal: 0,
                        unit: 'g',
                        color: ft.onSurfaceMuted,
                      ),
                      _MacroDetailRow(
                        label: l10n.macroSugar,
                        value: sugar,
                        goal: 0,
                        unit: 'g',
                        color: ft.onSurfaceMuted,
                      ),
                      _MacroDetailRow(
                        label: l10n.macroSaturatedFat,
                        value: saturatedFat,
                        goal: 0,
                        unit: 'g',
                        color: ft.onSurfaceMuted,
                      ),
                      _MacroDetailRow(
                        label: l10n.macroSalt,
                        value: salt,
                        goal: 0,
                        unit: 'g',
                        color: ft.onSurfaceMuted,
                        isLast: true,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MacroAxisChip extends StatelessWidget {
  const _MacroAxisChip({
    required this.axis,
    required this.selected,
    required this.onTap,
  });

  final _MacroAxis axis;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = switch (axis) {
      _MacroAxis.protein => Tokens.protein,
      _MacroAxis.fat => Tokens.fat,
      _MacroAxis.carbs => Tokens.carbs,
    };
    final label = switch (axis) {
      _MacroAxis.protein => l10n.macroProtein,
      _MacroAxis.fat => l10n.macroFat,
      _MacroAxis.carbs => l10n.macroCarbs,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? domain.dim : ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? domain.color.withValues(alpha: 0.55) : ft.cardBorder,
          ),
          boxShadow: selected
              ? [BoxShadow(color: domain.glow, blurRadius: Tokens.glowSm)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? domain.color : ft.onSurfaceMuted,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  const _MacroLegend({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w600,
            color: ft.onSurfaceMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: ft.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Thin wrapper that gives the bare [TrendChart] the same scroll-to-end
/// behavior the [TrendCard] uses for `scrollableMinBarWidth`. Lets us drop
/// a chart anywhere (not just inside `TrendCard`) without re-implementing
/// the controller plumbing.
class TrendChartHelper extends StatefulWidget {
  const TrendChartHelper({
    super.key,
    required this.bars,
    required this.domain,
    this.referenceValue,
    this.onBarTap,
    this.scrollableMinBarWidth,
    this.height = 188,
  });

  final List<ChartBar> bars;
  final Domain domain;
  final double? referenceValue;
  final ValueChanged<int>? onBarTap;
  final double? scrollableMinBarWidth;
  final double height;

  @override
  State<TrendChartHelper> createState() => _TrendChartHelperState();
}

class _TrendChartHelperState extends State<TrendChartHelper> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(covariant TrendChartHelper old) {
    super.didUpdateWidget(old);
    if (old.bars.length != widget.bars.length) _scheduleScrollToEnd();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _scheduleScrollToEnd() {
    if (widget.scrollableMinBarWidth == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_sc.hasClients && _sc.position.maxScrollExtent > 0) {
        _sc.jumpTo(_sc.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chart = TrendChart(
      bars: widget.bars,
      domain: widget.domain,
      height: widget.height,
      referenceValue: widget.referenceValue,
      onBarTap: widget.onBarTap,
    );
    if (widget.scrollableMinBarWidth == null) return chart;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const gapW = 5.0;
        final n = widget.bars.length;
        final naturalW = n * widget.scrollableMinBarWidth! + (n - 1) * gapW;
        final chartW =
            naturalW > constraints.maxWidth ? naturalW : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _sc,
          child: SizedBox(width: chartW, child: chart),
        );
      },
    );
  }
}

class _DayModeOnlyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: ft.onSurfaceMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.nutritionMealsOnlyDayMode,
              style: TextStyle(
                fontSize: 12,
                color: ft.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Not-connected state

class _NotConnectedState extends StatelessWidget {
  final VoidCallback onConnect;

  const _NotConnectedState({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Tokens.bg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(greeting: '', title: l10n.screenNutrition),
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  const Text('🍽', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: Tokens.spaceLg),
                  Text(
                    l10n.ktLoginPrompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Tokens.onSurfaceMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Tokens.space2xl),
                  GestureDetector(
                    onTap: onConnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Tokens.accent,
                        borderRadius: BorderRadius.circular(Tokens.radiusInner),
                      ),
                      child: Text(
                        l10n.ktGoToSettings,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeBody,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
