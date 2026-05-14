import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/connectivity_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../nutrition/presentation/widgets/kt_sync_error_banner.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
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

  /// When true, the user has explicitly chosen to view cached HC data
  /// instead of being shown the "set up Health Connect" prompt. Reset on
  /// app restart — once HC becomes ready, this flag stops mattering.
  bool _showCachedHcAnyway = false;

  /// Mirror of [_showCachedHcAnyway] for the Kalorické Tabulky source.
  bool _showCachedKtAnyway = false;

  bool _hasCachedHcData(FitnessProvider fitness) {
    return fitness.stepsHistory.isNotEmpty ||
        fitness.weightHistory.isNotEmpty ||
        fitness.sleepHistory.isNotEmpty ||
        fitness.activities.isNotEmpty;
  }

  /// Routes the prompt/banner action to install or grant based on the
  /// current Health Connect access state.
  Future<void> _handleHcAction(FitnessProvider fitness) async {
    if (fitness.accessState == FitnessAccessState.unavailable) {
      await fitness.installHealthConnect();
      return;
    }
    await fitness.requestPermissions();
    if (mounted) {
      await fitness.initialize();
    }
  }

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
      await context.read<ProgressionEngineProvider>().refresh();
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

  /// Per-card XP pill data for [questNodeId], a V2 [QuestNode] id.
  ///
  /// Daily quests are inherently `TodayScope` in V2, so the pill only
  /// makes sense when the user is looking at the current period —
  /// historic days never have claim state to surface. Matches the V1
  /// gating exactly: domain-style pills (today's daily quests) require a
  /// day-typed current period, weekly/activity-style pills accept any
  /// current period (weekly_activity_today rolls up across the week).
  XpClaimPillData? _xpPillForQuest(
    ProgressionEngineProvider progression,
    String questNodeId,
    SelectedPeriod period, {
    bool dayOnly = true,
  }) {
    if (dayOnly && period.type != PeriodType.day) return null;
    if (!period.isCurrentPeriod) return null;

    EngineQuestProgress? quest;
    for (final q in progression.allDailyQuests) {
      if (q.nodeId == questNodeId) {
        quest = q;
        break;
      }
    }
    if (quest == null) return null;
    final preview = quest.previewXp;

    if (quest.isCompleted) {
      return XpClaimPillData.claimed(preview);
    }
    if (quest.isAvailableForClaim) {
      final claimId = quest.nodeId;
      return XpClaimPillData.claimable(
        preview,
        onTap: (center) {
          _onXpClaimed(center);
          unawaited(progression.claimNode(nodeId: claimId));
        },
      );
    }
    if (preview > 0) {
      return XpClaimPillData.locked(preview);
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
    final progression = context.watch<ProgressionEngineProvider>();
    final connectivity = context.watch<ConnectivityProvider>();

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
                      syncedAt: syncedAt != null ? 'Synced $syncedAt' : null,
                      canGoForward: _period.canGoForward,
                      isCurrentPeriod: _period.isCurrentPeriod,
                      onPrev: () =>
                          setState(() => _period = _period.backward()),
                      onNext: _period.canGoForward
                          ? () => setState(() => _period = _period.forward())
                          : null,
                      onToday: _period.isCurrentPeriod
                          ? null
                          : () => setState(
                              () => _period = _period.withType(_period.type)),
                      onDateTap: _period.type == PeriodType.day
                          ? _openDatePicker
                          : null,
                    ),
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
                    questPillData: (questNodeId, {dayOnly = true}) =>
                        _xpPillForQuest(
                      progression,
                      questNodeId,
                      period,
                      dayOnly: dayOnly,
                    ),
                    progression: progression,
                    weightForPeriod: _weightForPeriod(fitness, period),
                    prevWeight: _previousWeightForPeriod(fitness, period),
                    showCachedHcAnyway: _showCachedHcAnyway,
                    hasCachedHcData: _hasCachedHcData(fitness),
                    onHcAction: () => _handleHcAction(fitness),
                    onShowCachedHc: () =>
                        setState(() => _showCachedHcAnyway = true),
                    showCachedKtAnyway: _showCachedKtAnyway,
                    hasCachedKtData: kt.hasCachedNutrition,
                    onShowCachedKt: () =>
                        setState(() => _showCachedKtAnyway = true),
                    isOnline: connectivity.isOnline,
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

/// Resolves the XP pill data for a stat card backed by V2 [QuestNode].
/// `dayOnly` mirrors the V1 distinction between "domain pill" (only on a
/// day-typed current period) and "rule pill" (any current period).
typedef _QuestPillResolver = XpClaimPillData? Function(
  String questNodeId, {
  bool dayOnly,
});

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
    required this.questPillData,
    required this.progression,
    required this.weightForPeriod,
    required this.prevWeight,
    required this.showCachedHcAnyway,
    required this.hasCachedHcData,
    required this.onHcAction,
    required this.onShowCachedHc,
    required this.showCachedKtAnyway,
    required this.hasCachedKtData,
    required this.onShowCachedKt,
    required this.isOnline,
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
  final _QuestPillResolver questPillData;
  final ProgressionEngineProvider progression;
  final double? weightForPeriod;
  final double? prevWeight;
  final bool showCachedHcAnyway;
  final bool hasCachedHcData;
  final VoidCallback onHcAction;
  final VoidCallback onShowCachedHc;
  final bool showCachedKtAnyway;
  final bool hasCachedKtData;
  final VoidCallback onShowCachedKt;
  final bool isOnline;
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
      final start = activity.startTime;
      final day = DateTime(start.year, start.month, start.day);
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

    // When Health Connect isn't ready and the user hasn't opted into the
    // cached-anyway view, replace the HC-driven cards (steps/weight/activities/
    // sleep) with one prominent prompt card. The KT calorie card is HC-
    // independent so it stays.
    final hcReady = fitness.accessState == FitnessAccessState.ready;
    final hcChecking = fitness.accessState == FitnessAccessState.checking;
    final showHcPrompt = !hcReady && !hcChecking && !showCachedHcAnyway;
    final showHcOfflineBanner =
        !hcReady && !hcChecking && showCachedHcAnyway;
    final hcUnavailable = fitness.accessState == FitnessAccessState.unavailable;
    // Suppress the KT prompt while restoreSession() is still running so
    // the user doesn't see a flash of "sign in to KT" on cold start when
    // they already have stored credentials. Same suppression applies
    // when credentials exist but the network is unreachable — pushing
    // the user to a sign-in flow they can't complete is worse than
    // letting them stay in their connected-but-offline state.
    final showKtPrompt = !kt.isLoggedIn &&
        !kt.isInitializing &&
        !kt.hasStoredCredentials &&
        !showCachedKtAnyway;
    final showKtOfflineBanner =
        !kt.isLoggedIn && !kt.isInitializing && showCachedKtAnyway;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isOnline) ...[
          _OfflineSourceBanner(
            message: l10n.homeOfflineBanner,
            // Tap is a no-op for the system-level offline state — there's
            // nothing the user can do in-app to restore connectivity.
            onTap: () {},
          ),
          const SizedBox(height: 10),
        ],
        if (showHcPrompt)
          _DataSourcePromptCard(
            logoAsset: 'assets/icons/hc/health_connect_logo.png',
            accentColor: Tokens.weight.color,
            title: hcUnavailable
                ? l10n.healthNotAvailable
                : l10n.healthPermissionRequired,
            body: hcUnavailable
                ? l10n.healthNotAvailableBody
                : l10n.healthPermissionBody,
            ctaIcon: hcUnavailable
                ? Icons.download_rounded
                : Icons.shield_outlined,
            ctaLabel:
                hcUnavailable ? l10n.healthInstall : l10n.healthGrantAccess,
            onAction: onHcAction,
            onShowCached: hasCachedHcData ? onShowCachedHc : null,
          )
        else ...[
          if (showHcOfflineBanner) ...[
            _OfflineSourceBanner(
              message: l10n.healthOfflineNotice,
              onTap: onHcAction,
            ),
            const SizedBox(height: 10),
          ],
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
          xpData: questPillData('daily_steps_today'),
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            DetailShortcutButton(
              onTap: onOpenSteps,
              domain: Tokens.steps,
            ),
          ],
        ),
        ],
        const SizedBox(height: 10),
        if (showKtPrompt)
          _DataSourcePromptCard(
            logoAsset: 'assets/icons/kt/kaloricke_tabulky.png',
            // Warm grass-green sampled from the KT logo
            // (assets/icons/kt/kaloricke_tabulky.png) — Material Light
            // Green 600. Tokens.steps emerald is too cool/teal here.
            accentColor: const Color(0xFF7AB342),
            title: l10n.caloriesTodayTitle,
            body: l10n.ktLoginPrompt,
            ctaIcon: Icons.settings_outlined,
            ctaLabel: l10n.ktGoToSettings,
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onShowCached: hasCachedKtData ? onShowCachedKt : null,
          )
        else ...[
          if (showKtOfflineBanner) ...[
            _OfflineSourceBanner(
              message: l10n.ktOfflineNotice,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (kt.isLoggedIn && kt.syncError != null) ...[
            KtSyncErrorBanner(
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
          xpData: questPillData('daily_calories_today'),
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
                xpData: questPillData('daily_protein_today'),
                claimedXpLabel: l10n.progQuestStatusClaimed,
              ),
              MacroRow(
                label: l10n.macroCarbs,
                value: carbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: Tokens.carbs,
                xpData: questPillData('daily_carbs_today'),
                claimedXpLabel: l10n.progQuestStatusClaimed,
              ),
              MacroRow(
                label: l10n.macroFat,
                value: fat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: Tokens.fat,
                xpData: questPillData('daily_fat_today'),
                claimedXpLabel: l10n.progQuestStatusClaimed,
              ),
              MacroRow(
                // Fiber is a daily goal but `GoalsProvider` doesn't yet
                // expose a configurable value — the engine's
                // `EngineGoalSet.dailyFiberGrams` default is 30g and the
                // catalog's `daily_fiber` objective targets that. Keep
                // the home row aligned with what the engine evaluates
                // until the goal becomes user-editable.
                label: 'Fiber',
                value: fiber,
                goal: 30,
                unit: 'g',
                domain: Tokens.calories,
                isLast: true,
                xpData: questPillData('daily_fiber_today'),
                claimedXpLabel: l10n.progQuestStatusClaimed,
              ),
              const SizedBox(height: Tokens.spaceMd),
              _NutritionDetailTile(
                label: l10n.caloriesRemaining,
                value: '${remainingToTarget.abs().round()} kcal',
                color: remainingToTarget >= 0
                    ? Tokens.calories.color
                    : Tokens.danger,
              ),
            ],
            DetailShortcutButton(
              onTap: onOpenNutrition,
              domain: Tokens.calories,
            ),
          ],
        ),
        ],
        if (!showHcPrompt) ...[
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
          xpData: questPillData('daily_weight_log_today', dayOnly: false),
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
          xpData: questPillData('daily_activity_today', dayOnly: false),
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
          xpData: questPillData('daily_sleep_today'),
          claimedXpLabel: l10n.progQuestStatusClaimed,
          children: [
            DetailShortcutButton(
              onTap: onOpenSleep,
              domain: Tokens.sleep,
            ),
          ],
        ),
        ],
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

// ── Shared data-source prompt card ──────────────────────────────────────────

/// Unified "you need to set up X" card used by both Health Connect and
/// Kalorické Tabulky on the home overview. Same visual structure: bare
/// logo, title, body, primary CTA pill, optional ghost-pill "Show saved
/// data" tertiary action. Background is a neutral info-card surface with
/// a subtle [accentColor] tint so the card reads as a soft prompt rather
/// than a brightly themed dashboard tile.
class _DataSourcePromptCard extends StatelessWidget {
  final String logoAsset;
  final Color accentColor;
  final String title;
  final String body;
  final IconData ctaIcon;
  final String ctaLabel;
  final VoidCallback onAction;

  /// When non-null, renders the secondary "Show saved data" pill that
  /// lets the user view previously cached data without setting up the
  /// source. Null when there's no cache to show.
  final VoidCallback? onShowCached;

  const _DataSourcePromptCard({
    required this.logoAsset,
    required this.accentColor,
    required this.title,
    required this.body,
    required this.ctaIcon,
    required this.ctaLabel,
    required this.onAction,
    required this.onShowCached,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ft = context.ft;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Image.asset(logoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeBody,
                    fontWeight: FontWeight.w800,
                    color: ft.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ft.onSurfaceMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Vertical full-width pills so HC and KT cards always lay out
          // the same way, regardless of how long the localized labels are.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(Tokens.radiusInner),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ctaIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        ctaLabel,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeSmall,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onShowCached != null) ...[
                const SizedBox(height: Tokens.spaceSm),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onShowCached,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(Tokens.radiusInner),
                      border: Border.all(color: ft.cardBorder),
                    ),
                    child: Text(
                      l10n.healthShowCachedData,
                      style: TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        fontWeight: FontWeight.w700,
                        color: ft.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact tap-to-set-up banner shown above cards rendered with cached
/// data only. Used for both KT (above the calorie card) and HC (above
/// steps/weight/activities/sleep cards) to remind the user they're not
/// fully connected.
class _OfflineSourceBanner extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _OfflineSourceBanner({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 14,
              color: ft.onSurfaceMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permission banner ───────────────────────────────────────────────────────

int _activityGoalForPeriod(GoalsProvider goals, SelectedPeriod period) {
  final weekly = goals.weeklyActivityMins;

  switch (period.type) {
    case PeriodType.day:
      // Matches `_dailyActivityTargetMinutes` in
      // progression_engine/.../activity_content.dart — the V2 catalog
      // owns the canonical value, this is the day-view UI default.
      return 30;
    case PeriodType.week:
      if (weekly <= 0) return 0;
      return weekly;
    case PeriodType.month:
    case PeriodType.custom:
      if (weekly <= 0) return 0;
      return weekly * 4;
  }
}

