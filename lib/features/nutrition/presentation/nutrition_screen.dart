import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/date_nav.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../../shared/widgets/macro_row.dart';
import '../../../shared/widgets/plain_card.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/tab_pill.dart';
import '../application/kaloricke_tabulky_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  SelectedPeriod _period = SelectedPeriod.today();

  static const _meals = [
    (name: 'BREAKFAST', time: '08:14', kcal: 642, emoji: '\uD83C\uDF73'),
    (name: 'LUNCH', time: '12:48', kcal: 1124, emoji: '\uD83C\uDF5C'),
    (name: 'SNACK', time: '15:30', kcal: 312, emoji: '\uD83C\uDF6A'),
    (name: 'DINNER', time: '19:22', kcal: 1243, emoji: '\uD83C\uDF72'),
  ];

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

  Widget _buildPeriodContent(
    BuildContext context,
    SelectedPeriod period,
    KalorickeTabulkyProvider kt,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final double kcal;
    final double protein;
    final double fat;
    final double carbs;
    if (period.type == PeriodType.day) {
      final day = kt.nutritionForDate(period.start);
      kcal = day?.calories ?? kt.todayCalories;
      protein = day?.protein ?? kt.todayProtein;
      fat = day?.fat ?? kt.todayFat;
      carbs = day?.carbs ?? kt.todayCarbs;
    } else {
      kcal = kt.avgCaloriesForRange(period.start, period.end) ?? 0;
      protein = kt.avgProteinForRange(period.start, period.end) ?? 0;
      fat = kt.avgFatForRange(period.start, period.end) ?? 0;
      carbs = kt.avgCarbsForRange(period.start, period.end) ?? 0;
    }

    final kcalGoal = goals.dailyCalories;
    final kcalDiff = kcal - kcalGoal;
    final kcalProgress = kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final kcalPct = kcalGoal > 0 ? ((kcal / kcalGoal) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kt.syncError != null) ...[
          const SizedBox(height: 2),
          _SyncErrorBanner(
            message: kt.syncError!,
            onRetry: () => kt.refreshRange(period.start, period.end),
          ),
          const SizedBox(height: 10),
        ],
        StatCard(
          icon: '\uD83D\uDD25',
          label: period.type == PeriodType.day
              ? l10n.caloriesTodayTitle
              : l10n.caloriesAvgPerDay,
          domain: Tokens.calories,
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
              label:
                  kcalDiff >= 0 ? l10n.caloriesBurned : l10n.caloriesRemaining,
              unit: 'kcal',
            ),
          ],
          progress: kcalProgress,
          badge: '$kcalPct%',
          children: [
            const SizedBox(height: 10),
            const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
            const SizedBox(height: Tokens.spaceSm),
            MacroRow(
              label: l10n.macroProtein,
              value: protein,
              goal: goals.dailyProtein,
              unit: 'g',
              domain: Tokens.protein,
            ),
            MacroRow(
              label: l10n.macroFat,
              value: fat,
              goal: goals.dailyFat,
              unit: 'g',
              domain: Tokens.fat,
            ),
            MacroRow(
              label: l10n.macroCarbs,
              value: carbs,
              goal: goals.dailyCarbs,
              unit: 'g',
              domain: Tokens.carbs,
              isLast: true,
            ),
          ],
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
                    l10n.ktNutritionTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      fontWeight: FontWeight.w700,
                      color: Color(0x80FFFFFF),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.spaceSm),
              for (int i = 0; i < _meals.length; i++)
                _MealRow(
                  name: _meals[i].name,
                  time: _meals[i].time,
                  kcal: _meals[i].kcal,
                  emoji: _meals[i].emoji,
                  isLast: i == _meals.length - 1,
                ),
            ],
          ),
        ),
      ],
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
                        _buildPeriodContent(context, period, kt, goals),
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
                  const Text('\uD83C\uDF7D', style: TextStyle(fontSize: 48)),
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

class _MealRow extends StatelessWidget {
  final String name;
  final String time;
  final int kcal;
  final String emoji;
  final bool isLast;

  const _MealRow({
    required this.name,
    required this.time,
    required this.kcal,
    required this.emoji,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Tokens.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Tokens.calories.dim,
              borderRadius: BorderRadius.circular(Tokens.radiusIcon),
              border: Border.all(
                color: Tokens.calories.color.withValues(alpha: 0.27),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: Tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xEBFFFFFF),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: Tokens.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text: '$kcal',
              style: TextStyle(
                fontSize: Tokens.fontSizeBody,
                fontWeight: FontWeight.w800,
                color: Tokens.calories.color,
              ),
              children: [
                TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: Tokens.calories.color.withValues(alpha: 0.7),
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
