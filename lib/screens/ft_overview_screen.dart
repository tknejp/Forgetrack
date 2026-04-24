import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../features/health_connect/application/fitness_provider.dart';
import '../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../features/progression/domain/progression_models.dart';
import '../features/progression/presentation/progression_provider.dart';
import '../l10n/l10n.dart';
import '../models/selected_period.dart';
import '../providers/goals_provider.dart';
import '../theme/ft_design_tokens.dart';
import '../widgets/ft/ft_date_nav.dart';
import '../widgets/ft/ft_detail_shortcut_button.dart';
import '../widgets/ft/ft_macro_row.dart';
import '../widgets/ft/ft_stat_card.dart';
import '../widgets/ft/ft_tab_pill.dart';
import '../widgets/ft/ft_drag_reveal_pager.dart';
import '../widgets/ft/ft_xp_claim_pill.dart';
import '../widgets/ft/ft_xp_sparkle_overlay.dart';

class FtOverviewScreen extends StatefulWidget {
  final PageController outerController;
  final GlobalKey barKey;
  final double topContentInset;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  const FtOverviewScreen({
    super.key,
    required this.outerController,
    required this.barKey,
    this.topContentInset = 0,
    required this.onOpenActivities,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  @override
  State<FtOverviewScreen> createState() => _FtOverviewScreenState();
}

class _FtOverviewScreenState extends State<FtOverviewScreen>
    with WidgetsBindingObserver {
  SelectedPeriod _period = SelectedPeriod.today();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FitnessProvider>().initialize(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FitnessProvider>().initialize();
    }
  }

  Future<void> _refresh() async {
    final fitness = context.read<FitnessProvider>();
    final kt = context.read<KalorickeTabulkyProvider>();
    final futures = <Future>[fitness.refresh()];
    if (kt.isLoggedIn) {
      futures.add(kt.refreshRange(_period.start, _period.end));
    }
    await Future.wait(futures);
    if (mounted) {
      await context.read<ProgressionProvider>().refresh();
    }
  }

  Future<void> _openDatePicker() async {
    if (_period.type != PeriodType.day) return;
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _period.referenceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: FtTokens.accent,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _period = SelectedPeriod.forDay(picked));
    }
  }

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

  String _fmtSleep(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes - hours * 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  FtXpClaimPillData? _xpPillData(
    BuildContext context,
    ProgressionProvider progression,
    ProgressionDomain domain,
    SelectedPeriod period,
  ) {
    if (period.type != PeriodType.day || !period.isCurrentPeriod) return null;

    final today = progressionDate(DateTime.now());

    final pending = progression.pendingRewards
        .where(
          (g) => g.domain == domain && progressionDate(g.period.start) == today,
        )
        .toList();

    if (pending.isNotEmpty) {
      final totalXp = pending.fold<int>(0, (sum, g) => sum + g.xpGranted);
      return FtXpClaimPillData.claimable(
        totalXp,
        onTap: (center) {
          _onXpClaimed(center);
          for (final g in pending) {
            progression.claimReward(g.rewardKey);
          }
        },
      );
    }

    final locked = progression.evaluations
        .where(
          (e) =>
              e.domain == domain &&
              !e.achieved &&
              progressionDate(e.period.start) == today,
        )
        .toList();

    if (locked.isNotEmpty) {
      final totalXp = locked.fold<int>(0, (sum, e) => sum + e.rewardXp);
      return FtXpClaimPillData.locked(totalXp);
    }

    return null;
  }

  void _onXpClaimed(Offset from) {
    FtXpSparkleLauncher.launchToKey(
      context,
      from: from,
      targetKey: widget.barKey,
    );
  }

  double? _weightForPeriod(FitnessProvider fitness, SelectedPeriod period) {
    switch (period.type) {
      case PeriodType.day:
        return fitness.weightForDate(period.start)?.weight;
      case PeriodType.week:
        return fitness.weekAvgWeight(period.start);
      case PeriodType.month:
        return fitness.monthAvgWeight(period.referenceDate);
      case PeriodType.custom:
        return fitness.monthAvgWeight(period.referenceDate);
    }
  }

  double? _previousWeightForPeriod(
      FitnessProvider fitness, SelectedPeriod period) {
    switch (period.type) {
      case PeriodType.day:
        return fitness.previousWeightBefore(period.start);
      case PeriodType.week:
        return fitness.weekAvgWeight(
          period.start.subtract(const Duration(days: 7)),
        );
      case PeriodType.month:
        final ref = period.referenceDate;
        return fitness.monthAvgWeight(DateTime(ref.year, ref.month - 1, 1));
      case PeriodType.custom:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fitness = context.watch<FitnessProvider>();
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionProvider>();

    final tab = _period.type == PeriodType.week
        ? l10n.periodWeek
        : _period.type == PeriodType.month
            ? l10n.periodMonth
            : l10n.periodDay;
    final fmt = NumberFormat('#,##0', locale);
    final syncedAt = fitness.lastSyncedAt != null
        ? DateFormat('HH:mm', locale).format(fitness.lastSyncedAt!)
        : null;

    return FtEdgePageHandoff(
      controller: widget.outerController,
      currentPage: 0,
      targetPage: 1,
      isEnabled: () => !_period.canGoForward,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: FtTokens.accent,
        backgroundColor: FtTokens.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FtTabPill(
                      tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
                      active: tab,
                      onChange: _changeTab,
                    ),
                    const SizedBox(height: 10),
                    FtDateNav(
                      date: _period.referenceDate,
                      onPrev: () =>
                          setState(() => _period = _period.backward()),
                      onNext: _period.canGoForward
                          ? () => setState(() => _period = _period.forward())
                          : null,
                      syncedAt: syncedAt,
                      labelOverride: _dateNavOverride(context, _period),
                      onDateTap: _period.type == PeriodType.day
                          ? _openDatePicker
                          : null,
                      showTodayButton: !_period.isCurrentPeriod,
                      onTodayTap: () => setState(
                          () => _period = _period.withType(_period.type)),
                    ),
                    if (fitness.accessState ==
                        FitnessAccessState.permissionRequired) ...[
                      const SizedBox(height: 10),
                      _PermissionBanner(
                          onTap: () => fitness.requestPermissions()),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              sliver: SliverToBoxAdapter(
                child: FtDragRevealPager<SelectedPeriod>(
                  item: _period,
                  pageGap: 16,
                  hasPrevious: (_) => true,
                  hasNext: (period) => period.canGoForward,
                  previousOf: (period) => period.backward(),
                  nextOf: (period) => period.forward(),
                  onCommit: (period) => setState(() => _period = period),
                  builder: (context, period) => _DayContent(
                    key: ValueKey(period),
                    period: period,
                    fitness: fitness,
                    kt: kt,
                    goals: goals,
                    fmt: fmt,
                    l10n: l10n,
                    fmtSleep: _fmtSleep,
                    xpPillData: (context, progression, domain) =>
                        _xpPillData(context, progression, domain, period),
                    progression: progression,
                    weightForPeriod: _weightForPeriod(fitness, period),
                    prevWeight: _previousWeightForPeriod(fitness, period),
                    onOpenActivities: widget.onOpenActivities,
                    onOpenNutrition: widget.onOpenNutrition,
                    onOpenBody: widget.onOpenBody,
                    onOpenSleep: widget.onOpenSleep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day content (animated on day change) ─────────────────────────────────────

class _DayContent extends StatelessWidget {
  const _DayContent({
    super.key,
    required this.period,
    required this.fitness,
    required this.kt,
    required this.goals,
    required this.fmt,
    required this.l10n,
    required this.fmtSleep,
    required this.xpPillData,
    required this.progression,
    required this.weightForPeriod,
    required this.prevWeight,
    required this.onOpenActivities,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider kt;
  final GoalsProvider goals;
  final NumberFormat fmt;
  final dynamic l10n;
  final String Function(Duration?) fmtSleep;
  final FtXpClaimPillData? Function(
      BuildContext, ProgressionProvider, ProgressionDomain) xpPillData;
  final ProgressionProvider progression;
  final double? weightForPeriod;
  final double? prevWeight;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    final steps = period.type == PeriodType.day
        ? fitness.stepsForDate(period.start)
        : fitness.stepsAvgForRange(period.start, period.end);
    final stepsGoal = goals.dailySteps;
    final stepsProgress =
        stepsGoal > 0 ? (steps / stepsGoal).clamp(0.0, 1.0) : 0.0;
    final stepsLeft = (stepsGoal - steps).clamp(0, stepsGoal);

    final dayNutrition = kt.nutritionForDate(period.start);
    final isCurrentDay =
        period.type == PeriodType.day && period.isCurrentPeriod;
    final kcal = period.type == PeriodType.day
        ? (dayNutrition?.calories ?? (isCurrentDay ? kt.todayCalories : 0.0))
        : (kt.avgCaloriesForRange(period.start, period.end) ?? 0.0);
    final kcalGoal = goals.dailyCalories;
    final kcalProgress = kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final kcalDiff = kcal - kcalGoal;
    final kcalPct = kcalGoal > 0 ? ((kcal / kcalGoal) * 100).round() : 0;
    final protein = period.type == PeriodType.day
        ? (dayNutrition?.protein ?? (isCurrentDay ? kt.todayProtein : 0.0))
        : (kt.avgProteinForRange(period.start, period.end) ?? 0.0);
    final fat = period.type == PeriodType.day
        ? (dayNutrition?.fat ?? (isCurrentDay ? kt.todayFat : 0.0))
        : (kt.avgFatForRange(period.start, period.end) ?? 0.0);
    final carbs = period.type == PeriodType.day
        ? (dayNutrition?.carbs ?? (isCurrentDay ? kt.todayCarbs : 0.0))
        : (kt.avgCarbsForRange(period.start, period.end) ?? 0.0);
    final fiber = period.type == PeriodType.day
        ? (dayNutrition?.fiber ?? (isCurrentDay ? kt.todayFiber : 0.0))
        : (kt.avgFiberForRange(period.start, period.end) ?? 0.0);
    final nutritionHasDetails =
        kcal > 0 || protein > 0 || fat > 0 || carbs > 0 || fiber > 0;
    final remainingToTarget = kcalGoal - kcal;

    final weightChange = (weightForPeriod != null && prevWeight != null)
        ? weightForPeriod! - prevWeight!
        : null;
    final targetWeight = goals.targetWeight;
    final weightHistory = fitness.weightHistory;
    final maxWeight = weightHistory.isNotEmpty
        ? weightHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b)
        : null;
    final weightProgress = (weightForPeriod != null &&
            maxWeight != null &&
            maxWeight > targetWeight)
        ? ((maxWeight - weightForPeriod!) / (maxWeight - targetWeight))
            .clamp(0.0, 1.0)
        : 0.0;

    final sleep = period.type == PeriodType.day
        ? fitness.sleepForDate(period.start)
        : null;
    final avgSleep = period.type != PeriodType.day
        ? fitness.avgSleepForRange(period.start, period.end)
        : null;
    final sleepDuration = sleep?.totalDuration ?? avgSleep;
    final sleepGoalMinutes = goals.sleepHours * 60;
    final sleepProgress = sleepDuration != null
        ? (sleepDuration.inMinutes / sleepGoalMinutes).clamp(0.0, 1.0)
        : 0.0;

    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FtStatCard(
          icon: '\uD83E\uDD7E',
          label: l10n.stepsTitle,
          domain: FtTokens.steps,
          stats: [
            FtStatStat(value: fmt.format(steps), label: l10n.stepsTitle),
            FtStatStat(
              value: fmt.format(stepsGoal),
              label: l10n.stepsGoal,
            ),
            FtStatStat(
              value:
                  period.type == PeriodType.day ? fmt.format(stepsLeft) : '--',
              label: period.type == PeriodType.day ? l10n.stepsRemaining : '',
            ),
          ],
          progress: stepsProgress,
          badge: '${(stepsProgress * 100).round()}%',
          xpData: xpPillData(context, progression, ProgressionDomain.steps),
          children: [
            FtDetailShortcutButton(
              onTap: onOpenActivities,
              domain: FtTokens.steps,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FtStatCard(
          icon: '\uD83D\uDD25',
          label: period.type == PeriodType.day
              ? l10n.caloriesTodayTitle
              : l10n.caloriesAvgPerDay,
          domain: FtTokens.calories,
          stats: [
            FtStatStat(
              value: fmt.format(kcal.round()),
              label: l10n.caloriesConsumed,
              unit: 'kcal',
            ),
            FtStatStat(
              value: fmt.format(kcalGoal.round()),
              label: l10n.weightGoal,
              unit: 'kcal',
            ),
            FtStatStat(
              value:
                  '${kcalDiff >= 0 ? '+' : ''}${fmt.format(kcalDiff.round())}',
              label:
                  kcalDiff >= 0 ? l10n.caloriesBurned : l10n.caloriesRemaining,
              unit: 'kcal',
            ),
          ],
          progress: kcalProgress,
          badge: '$kcalPct%',
          xpData: xpPillData(context, progression, ProgressionDomain.nutrition),
          children: [
            const SizedBox(height: 12),
            if (nutritionHasDetails) ...[
              FtMacroRow(
                label: l10n.macroProtein,
                value: protein,
                goal: goals.dailyProtein,
                unit: 'g',
                domain: FtTokens.protein,
              ),
              FtMacroRow(
                label: l10n.macroCarbs,
                value: carbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: FtTokens.carbs,
              ),
              FtMacroRow(
                label: l10n.macroFat,
                value: fat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: FtTokens.fat,
                isLast: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NutritionDetailTile(
                      label: 'Fiber',
                      value: '${fiber.toStringAsFixed(0)} g',
                      color: FtTokens.calories.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NutritionDetailTile(
                      label: l10n.caloriesRemaining,
                      value: '${remainingToTarget.abs().round()} kcal',
                      color: remainingToTarget >= 0
                          ? FtTokens.calories.color
                          : const Color(0xFFF87171),
                    ),
                  ),
                ],
              ),
            ],
            FtDetailShortcutButton(
              onTap: onOpenNutrition,
              domain: FtTokens.calories,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FtStatCard(
          icon: '\u2696',
          label: l10n.weightTitle,
          domain: FtTokens.weight,
          stats: [
            FtStatStat(
              value: weightForPeriod?.toStringAsFixed(1) ?? '--',
              label: period.type == PeriodType.day
                  ? l10n.bodyCurrentWeight
                  : l10n.weightAverage,
              unit: 'kg',
            ),
            FtStatStat(
              value: weightChange != null
                  ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}'
                  : '--',
              label: period.type == PeriodType.week
                  ? l10n.weightVsPrevWeek
                  : period.type == PeriodType.month
                      ? l10n.weightVsPrevMonth
                      : l10n.weightAverage,
              unit: 'kg',
            ),
            FtStatStat(
              value: targetWeight.toStringAsFixed(1),
              label: l10n.weightGoal,
              unit: 'kg',
            ),
          ],
          progress: weightProgress,
          trophy: true,
          xpData: xpPillData(context, progression, ProgressionDomain.body),
          children: [
            FtDetailShortcutButton(
              onTap: onOpenBody,
              domain: FtTokens.weight,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FtStatCard(
          icon: '\uD83C\uDF19',
          label: l10n.sleepTitle,
          domain: FtTokens.sleep,
          stats: [
            FtStatStat(
              value: fmtSleep(sleepDuration),
              label: l10n.sleepDuration,
            ),
            FtStatStat(
              value: sleep?.sleepStart != null
                  ? DateFormat('HH:mm', locale).format(sleep!.sleepStart)
                  : '--',
              label: l10n.sleepFellAsleep,
            ),
            FtStatStat(
              value: sleep?.wakeTime != null
                  ? DateFormat('HH:mm', locale).format(sleep!.wakeTime)
                  : '--',
              label: l10n.sleepWokeUp,
            ),
          ],
          progress: sleepProgress,
          badge: sleepDuration != null
              ? '${(sleepProgress * 100).round()}%'
              : null,
          xpData: xpPillData(context, progression, ProgressionDomain.sleep),
          children: [
            FtDetailShortcutButton(
              onTap: onOpenSleep,
              domain: FtTokens.sleep,
            ),
          ],
        ),
      ],
    );
  }
}

class _NutritionDetailTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionDetailTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: FtTokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: FtTokens.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission banner ───────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FtTokens.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_border, size: 16, color: FtTokens.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.healthPermissionBody,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
