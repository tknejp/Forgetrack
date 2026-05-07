import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression/domain/catalog/rule_catalog.dart';
import '../../progression/domain/progression_models.dart';
import '../../progression/application/progression_provider.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/detail_shortcut_button.dart';
import '../../../shared/widgets/macro_row.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../../shared/widgets/xp_claim_pill.dart';
import '../../../shared/widgets/xp_sparkle_overlay.dart';

class OverviewScreen extends StatefulWidget {
  final PageController outerController;
  final GlobalKey barKey;
  final double topContentInset;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  const OverviewScreen({
    super.key,
    required this.outerController,
    required this.barKey,
    this.topContentInset = 0,
    required this.onOpenActivities,
    required this.onOpenSteps,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  SelectedPeriod _period = SelectedPeriod.today();

  Future<void> _refresh() async {
    final fitness = context.read<FitnessProvider>();
    final kt = context.read<KalorickeTabulkyProvider>();

    final isCurrentDay =
        _period.type == PeriodType.day && _period.isCurrentPeriod;

    final futures = <Future>[
      isCurrentDay
          ? fitness.refresh()
          : fitness.refreshRange(_period.start, _period.end),
    ];

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
                primary: Tokens.accent,
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

  String _fmtSleep(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes - hours * 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  XpClaimPillData? _xpPillData(
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
      return XpClaimPillData.claimable(
        totalXp,
        onTap: (center) {
          _onXpClaimed(center);
          for (final g in pending) {
            progression.claimReward(g.rewardKey);
          }
        },
      );
    }

    final claimed = progression.claimedRewards
        .where(
          (g) => g.domain == domain && progressionDate(g.period.start) == today,
        )
        .toList();

    if (claimed.isNotEmpty) {
      final totalXp = claimed.fold<int>(
        0,
        (sum, g) => sum + g.effectiveXpGranted,
      );
      return XpClaimPillData.claimed(totalXp);
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
      return XpClaimPillData.locked(totalXp);
    }

    return null;
  }

  XpClaimPillData? _xpPillDataForRule(
    BuildContext context,
    ProgressionProvider progression,
    String ruleId,
    SelectedPeriod period,
  ) {
    if (!period.isCurrentPeriod) return null;

    final periodStart = progressionDate(
      ruleId == 'weekly_activity'
          ? SelectedPeriod.currentWeek().start
          : period.start,
    );
    final pending = progression.pendingRewards
        .where(
          (g) =>
              g.ruleId == ruleId &&
              progressionDate(g.period.start) == periodStart,
        )
        .toList();

    if (pending.isNotEmpty) {
      final totalXp = pending.fold<int>(0, (sum, g) => sum + g.xpGranted);
      return XpClaimPillData.claimable(
        totalXp,
        onTap: (center) {
          _onXpClaimed(center);
          for (final g in pending) {
            progression.claimReward(g.rewardKey);
          }
        },
      );
    }

    final claimed = progression.claimedRewards
        .where(
          (g) =>
              g.ruleId == ruleId &&
              progressionDate(g.period.start) == periodStart,
        )
        .toList();

    if (claimed.isNotEmpty) {
      final totalXp = claimed.fold<int>(
        0,
        (sum, g) => sum + g.effectiveXpGranted,
      );
      return XpClaimPillData.claimed(totalXp);
    }

    final locked = progression.evaluations
        .where(
          (e) =>
              e.ruleId == ruleId &&
              !e.achieved &&
              progressionDate(e.period.start) == periodStart,
        )
        .toList();

    if (locked.isNotEmpty) {
      final totalXp = locked.fold<int>(0, (sum, e) => sum + e.rewardXp);
      return XpClaimPillData.locked(totalXp);
    }

    if (_shouldShowRuleFallbackPill(ruleId, period)) {
      final hasGrantForPeriod = progression.rewardGrants.any(
        (g) =>
            g.ruleId == ruleId &&
            progressionDate(g.period.start) == periodStart,
      );
      if (!hasGrantForPeriod) {
        final rewardXp = _fallbackRuleXp(ruleId);
        if (rewardXp != null) {
          return XpClaimPillData.locked(rewardXp);
        }
      }
    }

    return null;
  }

  void _onXpClaimed(Offset from) {
    XpSparkleLauncher.launchToKey(
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

    return EdgePageHandoff(
      controller: widget.outerController,
      currentPage: 0,
      targetPage: 1,
      isEnabled: () => !_period.canGoForward,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: Tokens.accent,
        backgroundColor: Tokens.surface,
        edgeOffset: widget.topContentInset,
        displacement: 16,
        strokeWidth: 2.5,
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
                    PeriodNavigator(
                      domain: Tokens.steps,
                      tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
                      activeTab: tab,
                      onTabChange: _changeTab,
                      dateLabel: _periodDateLabel(context, _period),
                      syncedAt:
                          syncedAt != null ? 'Synced $syncedAt' : null,
                      canGoForward: _period.canGoForward,
                      isCurrentPeriod: _period.isCurrentPeriod,
                      onPrev: () =>
                          setState(() => _period = _period.backward()),
                      onNext: _period.canGoForward
                          ? () => setState(() => _period = _period.forward())
                          : null,
                      onToday: _period.isCurrentPeriod
                          ? null
                          : () => setState(() =>
                              _period = _period.withType(_period.type)),
                      onDateTap: _period.type == PeriodType.day
                          ? _openDatePicker
                          : null,
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
                child: DragRevealPager<SelectedPeriod>(
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
                    ruleXpPillData: (context, progression, ruleId) =>
                        _xpPillDataForRule(
                      context,
                      progression,
                      ruleId,
                      period,
                    ),
                    progression: progression,
                    weightForPeriod: _weightForPeriod(fitness, period),
                    prevWeight: _previousWeightForPeriod(fitness, period),
                    onOpenActivities: widget.onOpenActivities,
                    onOpenSteps: widget.onOpenSteps,
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
    required this.ruleXpPillData,
    required this.progression,
    required this.weightForPeriod,
    required this.prevWeight,
    required this.onOpenActivities,
    required this.onOpenSteps,
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
  final XpClaimPillData? Function(
      BuildContext, ProgressionProvider, ProgressionDomain) xpPillData;
  final XpClaimPillData? Function(
    BuildContext,
    ProgressionProvider,
    String,
  ) ruleXpPillData;
  final ProgressionProvider progression;
  final double? weightForPeriod;
  final double? prevWeight;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
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

    final isCurrentDay =
        period.type == PeriodType.day && period.isCurrentPeriod;

    final dayNutrition = period.type == PeriodType.day
        ? kt.nutritionForDate(period.start)
        : null;

    final nutritionSummary = period.type == PeriodType.day
        ? null
        : kt.nutritionSummaryForRange(period.start, period.end);

    final kcal = period.type == PeriodType.day
        ? (dayNutrition?.calories ?? (isCurrentDay ? kt.todayCalories : 0.0))
        : (nutritionSummary?.calories ?? 0.0);

    final kcalGoal = goals.dailyCalories;
    final kcalProgress = kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final kcalDiff = kcal - kcalGoal;
    final kcalPct = kcalGoal > 0 ? ((kcal / kcalGoal) * 100).round() : 0;

    final protein = period.type == PeriodType.day
        ? (dayNutrition?.protein ?? (isCurrentDay ? kt.todayProtein : 0.0))
        : (nutritionSummary?.protein ?? 0.0);

    final fat = period.type == PeriodType.day
        ? (dayNutrition?.fat ?? (isCurrentDay ? kt.todayFat : 0.0))
        : (nutritionSummary?.fat ?? 0.0);

    final carbs = period.type == PeriodType.day
        ? (dayNutrition?.carbs ?? (isCurrentDay ? kt.todayCarbs : 0.0))
        : (nutritionSummary?.carbs ?? 0.0);

    final fiber = period.type == PeriodType.day
        ? (dayNutrition?.fiber ?? (isCurrentDay ? kt.todayFiber : 0.0))
        : (nutritionSummary?.fiber ?? 0.0);
    final nutritionHasDetails =
        kcal > 0 || protein > 0 || fat > 0 || carbs > 0 || fiber > 0;
    final remainingToTarget = kcalGoal - kcal;

    final weightChange = (weightForPeriod != null && prevWeight != null)
        ? weightForPeriod! - prevWeight!
        : null;

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

    final periodActivities = fitness.activities.where((activity) {
      final day = progressionDate(activity.startTime);
      return !day.isBefore(period.start) && !day.isAfter(period.end);
    }).toList(growable: false);
    final activeMinutes = periodActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.duration.inMinutes,
    );
    final activityGoal = _activityGoalForPeriod(goals, period);
    final activityProgress =
        activityGoal > 0 ? (activeMinutes / activityGoal).clamp(0.0, 1.0) : 0.0;

    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatCard(
          icon: '\uD83E\uDD7E',
          label: l10n.stepsTitle,
          domain: Tokens.steps,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.steps,
          ),
          stats: [
            StatStat(value: fmt.format(steps), label: l10n.stepsTitle),
            StatStat(
              value: fmt.format(stepsGoal),
              label: l10n.stepsGoal,
            ),
            StatStat(
              value:
                  period.type == PeriodType.day ? fmt.format(stepsLeft) : '--',
              label: period.type == PeriodType.day ? l10n.stepsRemaining : '',
            ),
          ],
          progress: stepsProgress,
          badge: '${(stepsProgress * 100).round()}%',
          xpData: xpPillData(context, progression, ProgressionDomain.steps),
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            DetailShortcutButton(
              onTap: onOpenSteps,
              domain: Tokens.steps,
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatCard(
          icon: '\uD83D\uDD25',
          label: period.type == PeriodType.day
              ? l10n.caloriesTodayTitle
              : l10n.caloriesAvgPerDay,
          domain: Tokens.calories,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.nutrition,
          ),
          stats: [
            StatStat(
              value: fmt.format(kcal.round()),
              label: l10n.caloriesConsumed,
              unit: 'kcal',
            ),
            StatStat(
              value: fmt.format(kcalGoal.round()),
              label: l10n.weightGoal,
              unit: 'kcal',
            ),
            StatStat(
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
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            const SizedBox(height: Tokens.spaceMd),
            if (nutritionHasDetails) ...[
              MacroRow(
                label: l10n.macroProtein,
                value: protein,
                goal: goals.dailyProtein,
                unit: 'g',
                domain: Tokens.protein,
              ),
              MacroRow(
                label: l10n.macroCarbs,
                value: carbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: Tokens.carbs,
              ),
              MacroRow(
                label: l10n.macroFat,
                value: fat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: Tokens.fat,
                isLast: true,
              ),
              const SizedBox(height: Tokens.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _NutritionDetailTile(
                      label: 'Fiber',
                      value: '${fiber.toStringAsFixed(0)} g',
                      color: Tokens.calories.color,
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceSm),
                  Expanded(
                    child: _NutritionDetailTile(
                      label: l10n.caloriesRemaining,
                      value: '${remainingToTarget.abs().round()} kcal',
                      color: remainingToTarget >= 0
                          ? Tokens.calories.color
                          : Tokens.danger,
                    ),
                  ),
                ],
              ),
            ],
            DetailShortcutButton(
              onTap: onOpenNutrition,
              domain: Tokens.calories,
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatCard(
          icon: '\u2696',
          label: l10n.weightTitle,
          domain: Tokens.weight,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.weight,
          ),
          stats: [
            StatStat(
              value: weightForPeriod?.toStringAsFixed(1) ?? '--',
              label: period.type == PeriodType.day
                  ? l10n.bodyCurrentWeight
                  : l10n.weightAverage,
              unit: 'kg',
            ),
            StatStat(
              value: weightChange != null
                  ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}'
                  : '--',
              label: period.type == PeriodType.week
                  ? l10n.weightVsPrevWeek
                  : period.type == PeriodType.month
                      ? l10n.weightVsPrevMonth
                      : l10n.weightVsPrevMeasure,
              unit: 'kg',
            ),
          ],
          showProgress: false,
          xpData: ruleXpPillData(
            context,
            progression,
            'daily_weight_log',
          ),
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            DetailShortcutButton(
              onTap: onOpenBody,
              domain: Tokens.weight,
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatCard(
          icon: '\u26A1',
          label: l10n.activitiesActiveMins,
          domain: Tokens.active,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.activity,
          ),
          stats: [
            StatStat(
              value: fmt.format(activeMinutes),
              label: l10n.activitiesActiveMins,
              unit: 'min',
            ),
            StatStat(
              value: fmt.format(activityGoal),
              label: l10n.stepsGoal,
              unit: 'min',
            ),
            StatStat(
              value: fmt.format(periodActivities.length),
              label: l10n.activitiesWorkouts,
            ),
          ],
          progress: activityProgress,
          badge: '${(activityProgress * 100).round()}%',
          xpData: ruleXpPillData(
            context,
            progression,
            'daily_activity',
          ),
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            DetailShortcutButton(
              onTap: onOpenActivities,
              domain: Tokens.active,
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatCard(
          icon: '\uD83C\uDF19',
          label: l10n.sleepTitle,
          domain: Tokens.sleep,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.sleep,
          ),
          stats: [
            StatStat(
              value: fmtSleep(sleepDuration),
              label: l10n.sleepDuration,
            ),
            StatStat(
              value: sleep?.sleepStart != null
                  ? DateFormat('HH:mm', locale).format(sleep!.sleepStart)
                  : '--',
              label: l10n.sleepFellAsleep,
            ),
            StatStat(
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
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            DetailShortcutButton(
              onTap: onOpenSleep,
              domain: Tokens.sleep,
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
        color: context.ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: Tokens.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
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

int _activityGoalForPeriod(GoalsProvider goals, SelectedPeriod period) {
  final weekly = goals.weeklyActivityMins;

  switch (period.type) {
    case PeriodType.day:
      return ProgressionRuleCatalog.dailyActivityTargetMinutes;
    case PeriodType.week:
      if (weekly <= 0) return 0;
      return weekly;
    case PeriodType.month:
    case PeriodType.custom:
      if (weekly <= 0) return 0;
      return weekly * 4;
  }
}

bool _shouldShowRuleFallbackPill(String ruleId, SelectedPeriod period) {
  return period.type == PeriodType.day &&
      period.isCurrentPeriod &&
      (ruleId == 'daily_weight_log' || ruleId == 'daily_activity');
}

int? _fallbackRuleXp(String ruleId) {
  return switch (ruleId) {
    'daily_weight_log' => 20,
    'daily_activity' => 50,
    _ => null,
  };
}

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
          color: Tokens.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_border, size: 16, color: Tokens.accent),
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
