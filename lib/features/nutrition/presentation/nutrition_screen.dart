import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/macro_row.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../application/kaloricke_tabulky_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
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

  Widget _buildContent(
    BuildContext context,
    KalorickeTabulkyProvider kt,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;

    // ── Today (always-today data) ────────────────────────────────────────
    final todayKcal = kt.todayCalories;
    final todayProtein = kt.todayProtein;
    final todayFat = kt.todayFat;
    final todayCarbs = kt.todayCarbs;
    final kcalGoal = goals.dailyCalories;
    final todayDiff = todayKcal - kcalGoal;
    final todayProgress =
        kcalGoal > 0 ? (todayKcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final todayPct = kcalGoal > 0 ? ((todayKcal / kcalGoal) * 100).round() : 0;

    // ── Period-driven values ─────────────────────────────────────────────
    final double periodKcal;
    final double periodProtein;
    final double periodFat;
    final double periodCarbs;
    if (_period.type == PeriodType.day) {
      final day = kt.nutritionForDate(_period.start);
      periodKcal = day?.calories ?? 0;
      periodProtein = day?.protein ?? 0;
      periodFat = day?.fat ?? 0;
      periodCarbs = day?.carbs ?? 0;
    } else {
      periodKcal = kt.avgCaloriesForRange(_period.start, _period.end) ?? 0;
      periodProtein = kt.avgProteinForRange(_period.start, _period.end) ?? 0;
      periodFat = kt.avgFatForRange(_period.start, _period.end) ?? 0;
      periodCarbs = kt.avgCarbsForRange(_period.start, _period.end) ?? 0;
    }
    final periodDiff = periodKcal - kcalGoal;
    final periodProgress =
        kcalGoal > 0 ? (periodKcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final periodPct =
        kcalGoal > 0 ? ((periodKcal / kcalGoal) * 100).round() : 0;

    return SwipePeriodGesture(
      onPrev: () => setState(() => _period = _period.backward()),
      onNext: _period.canGoForward
          ? () => setState(() => _period = _period.forward())
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kt.syncError != null) ...[
            _SyncErrorBanner(
              message: kt.syncError!,
              onRetry: () => kt.refreshRange(_period.start, _period.end),
            ),
            const SizedBox(height: 10),
          ],

          // ── Today header — always today's totals + macros ──────────────
          StatCard(
            icon: '🔥',
            label: l10n.caloriesTodayTitle,
            domain: Tokens.calories,
            visualAssets: DashboardCardAssetResolver.forKind(
              DashboardCardKind.nutrition,
            ),
            initiallyExpanded: true,
            collapsible: false,
            stats: [
              StatStat(
                value: todayKcal.round().toString(),
                label: l10n.caloriesConsumed,
                unit: 'kcal',
              ),
              StatStat(
                value: kcalGoal.round().toString(),
                label: l10n.weightGoal,
                unit: 'kcal',
              ),
              StatStat(
                value: '${todayDiff >= 0 ? '+' : ''}${todayDiff.round()}',
                label: todayDiff >= 0
                    ? l10n.caloriesBurned
                    : l10n.caloriesRemaining,
                unit: 'kcal',
              ),
            ],
            progress: todayProgress,
            badge: '$todayPct%',
            children: [
              const SizedBox(height: 10),
              const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
              const SizedBox(height: Tokens.spaceSm),
              MacroRow(
                label: l10n.macroProtein,
                value: todayProtein,
                goal: goals.dailyProtein,
                unit: 'g',
                domain: Tokens.protein,
              ),
              MacroRow(
                label: l10n.macroFat,
                value: todayFat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: Tokens.fat,
              ),
              MacroRow(
                label: l10n.macroCarbs,
                value: todayCarbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: Tokens.carbs,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Period navigator + range tabs ──────────────────────────────
          PeriodNavigator(
            domain: Tokens.calories,
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

          // ── Period card — calories + macros for the active selection ──
          StatCard(
            icon: '📊',
            label: _period.type == PeriodType.day
                ? l10n.caloriesTodayTitle
                : l10n.caloriesAvgPerDay,
            domain: Tokens.calories,
            visualAssets: DashboardCardAssetResolver.forKind(
              DashboardCardKind.nutrition,
            ),
            initiallyExpanded: true,
            collapsible: false,
            stats: [
              StatStat(
                value: periodKcal.round().toString(),
                label: l10n.caloriesConsumed,
                unit: 'kcal',
              ),
              StatStat(
                value: kcalGoal.round().toString(),
                label: l10n.weightGoal,
                unit: 'kcal',
              ),
              StatStat(
                value: '${periodDiff >= 0 ? '+' : ''}${periodDiff.round()}',
                label: periodDiff >= 0
                    ? l10n.caloriesBurned
                    : l10n.caloriesRemaining,
                unit: 'kcal',
              ),
            ],
            progress: periodProgress,
            badge: '$periodPct%',
            children: [
              const SizedBox(height: 10),
              const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
              const SizedBox(height: Tokens.spaceSm),
              MacroRow(
                label: l10n.macroProtein,
                value: periodProtein,
                goal: goals.dailyProtein,
                unit: 'g',
                domain: Tokens.protein,
              ),
              MacroRow(
                label: l10n.macroFat,
                value: periodFat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: Tokens.fat,
              ),
              MacroRow(
                label: l10n.macroCarbs,
                value: periodCarbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: Tokens.carbs,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();

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
                  child: _buildContent(context, kt, goals),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SyncErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border:
            Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFF87171)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              context.l10n.healthRetry,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF87171),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
