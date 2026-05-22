import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/connectivity_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/domain/activity_record.dart';
import '../../progression_engine/domain/activity_claim/activity_claim_state.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../nutrition/presentation/widgets/kt_sync_error_banner.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/home_card_order_provider.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/domain/progression_domain_chrome.dart';
import '../../progression_engine/presentation/widgets/quest_streak_chip.dart';
import '../../progression_engine/presentation/widgets/quest_streak_info_block.dart';
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

  Future<void> _handleHcAction() async {
    final fitness = context.read<FitnessProvider>();
    if (fitness.accessState == FitnessAccessState.unavailable) {
      await fitness.installHealthConnect();
      return;
    }
    await fitness.requestPermissions();
    if (mounted) {
      await fitness.initialize();
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

  @override
  Widget build(BuildContext context) {
    // Phase 1.2 perf fix: the screen build no longer watches any
    // providers. Provider subscriptions live in the per-card slot
    // widgets and in `Selector`s scoped to layout-decision values
    // (`_PeriodNavigatorBar`, `_HomeOfflineBanner`, `_HomeCardList`).
    // This stops a `FitnessProvider` step tick or a
    // `KalorickeTabulkyProvider` log tick from rebuilding the entire
    // CustomScrollView; only the slot widgets that actually consume
    // the changed data rebuild.
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
                child: _PeriodNavigatorBar(
                  period: _period,
                  dateLabel: _periodDateLabel(context, _period),
                  onTabChange: _changeTab,
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
                    barKey: widget.barKey,
                    showCachedHcAnyway: _showCachedHcAnyway,
                    showCachedKtAnyway: _showCachedKtAnyway,
                    onShowCachedHc: () =>
                        setState(() => _showCachedHcAnyway = true),
                    onShowCachedKt: () =>
                        setState(() => _showCachedKtAnyway = true),
                    onHcAction: () => unawaited(_handleHcAction()),
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

// ── Free helpers (used by per-card slot widgets) ────────────────────────────

/// Per-card XP pill data for [questNodeId], a V2 [QuestNode] id.
///
/// Daily quests are inherently `TodayScope` in V2, so the pill only
/// makes sense when the user is looking at the current period —
/// historic days never have claim state to surface. Matches the V1
/// gating exactly: domain-style pills (today's daily quests) require a
/// day-typed current period, weekly/activity-style pills accept any
/// current period (weekly_activity_today rolls up across the week).
XpClaimPillData? _xpPillForQuest({
  required BuildContext context,
  required ProgressionEngineProvider progression,
  required SelectedPeriod period,
  required String questNodeId,
  required GlobalKey barKey,
  bool dayOnly = true,
}) {
  if (dayOnly && period.type != PeriodType.day) return null;
  if (!period.isCurrentPeriod) return null;

  final quest = _findDailyQuest(progression, questNodeId);
  if (quest == null) return null;
  final preview = quest.previewXp;
  // Every card surfaces the buff bonus on the XP pill — the
  // bonus-XP chip replaces the streak chip that used to sit next
  // to it on main-five cards (the pedagogic streak info now lives
  // inside the expanded card body instead).
  final companionBonus = progression.projectedCompanionBuffBonusFor(quest.node);
  final emblemBonus = progression.projectedEmblemBuffBonusFor(quest.node);

  if (quest.isCompleted) {
    return XpClaimPillData.claimed(
      preview,
      companionBonus: companionBonus,
      emblemBonus: emblemBonus,
    );
  }
  if (quest.isAvailableForClaim) {
    final claimId = quest.nodeId;
    return XpClaimPillData.claimable(
      preview,
      companionBonus: companionBonus,
      emblemBonus: emblemBonus,
      onTap: (center) {
        XpSparkleLauncher.launchToKey(
          context,
          from: center,
          targetKey: barKey,
        );
        unawaited(progression.claimNode(nodeId: claimId));
      },
    );
  }
  if (preview > 0) {
    return XpClaimPillData.locked(
      preview,
      companionBonus: companionBonus,
      emblemBonus: emblemBonus,
    );
  }
  return null;
}

/// Resolves the pedagogic streak info block for a main-five home
/// card. Returns null when:
///   * the period isn't the current day (no live streak preview
///     on historic days),
///   * the node id isn't a tracked daily quest,
///   * the node's rewards don't carry a `streakDomain` (this card
///     isn't a main-five daily goal).
QuestStreakInfoBlock? _streakInfoBlockForQuest({
  required ProgressionEngineProvider progression,
  required SelectedPeriod period,
  required String questNodeId,
}) {
  if (!period.isCurrentPeriod) return null;
  final quest = _findDailyQuest(progression, questNodeId);
  if (quest == null) return null;
  final domain = streakDomainOfRewards(quest.node.rewards);
  if (domain == null) return null;
  final summary = progression.streakForDomain(domain);
  return QuestStreakInfoBlock(
    currentStreak: summary.currentStreak,
    bestStreak: summary.bestStreak,
    accent: domain.color,
    buff: progression.equippedCompanionBuff,
    resolvedPercent: progression.projectedStreakBuffPercentFor(quest.node),
  );
}

EngineQuestProgress? _findDailyQuest(
  ProgressionEngineProvider progression,
  String questNodeId,
) {
  for (final q in progression.allDailyQuests) {
    if (q.nodeId == questNodeId) return q;
  }
  return null;
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

bool _hasCachedHcData(FitnessProvider fitness) {
  return fitness.stepsHistory.isNotEmpty ||
      fitness.weightHistory.isNotEmpty ||
      fitness.sleepHistory.isNotEmpty ||
      fitness.activities.isNotEmpty;
}

String _fmtSleep(Duration? duration) {
  if (duration == null) return '--';
  final hours = duration.inHours;
  final minutes = duration.inMinutes - hours * 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

// ── Period navigator bar ────────────────────────────────────────────────────

/// Thin wrapper around [PeriodNavigator] that scopes its
/// `FitnessProvider` subscription to just the `lastSyncedAt` field via
/// `Selector`. A steps update notify on `FitnessProvider` would
/// otherwise rebuild the whole bar even though only the synced-time
/// label depends on it.
class _PeriodNavigatorBar extends StatelessWidget {
  const _PeriodNavigatorBar({
    required this.period,
    required this.dateLabel,
    required this.onTabChange,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onDateTap,
  });

  final SelectedPeriod period;
  final String dateLabel;
  final ValueChanged<String> onTabChange;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final VoidCallback? onDateTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tab = period.type == PeriodType.week
        ? l10n.periodWeek
        : period.type == PeriodType.month
            ? l10n.periodMonth
            : l10n.periodDay;
    return Selector<FitnessProvider, DateTime?>(
      selector: (_, fitness) => fitness.lastSyncedAt,
      builder: (context, lastSyncedAt, _) {
        final locale = Localizations.localeOf(context).toString();
        final syncedAt = lastSyncedAt != null
            ? DateFormat('HH:mm', locale).format(lastSyncedAt)
            : null;
        return PeriodNavigator(
          domain: Tokens.steps,
          tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
          activeTab: tab,
          onTabChange: onTabChange,
          dateLabel: dateLabel,
          syncedAt: syncedAt != null ? 'Synced $syncedAt' : null,
          canGoForward: period.canGoForward,
          isCurrentPeriod: period.isCurrentPeriod,
          onPrev: onPrev,
          onNext: onNext,
          onToday: onToday,
          onDateTap: onDateTap,
        );
      },
    );
  }
}

// ── Day content orchestrator ────────────────────────────────────────────────

/// Per-period orchestrator. Stateless, keyed by [period] so
/// [DragRevealPager] can swap pages by identity. Does not watch any
/// provider directly — subscriptions are owned by [_HomeOfflineBanner]
/// and [_HomeCardList] (which in turn delegate the data-card watches
/// to each slot widget).
class _DayContent extends StatelessWidget {
  const _DayContent({
    super.key,
    required this.period,
    required this.barKey,
    required this.showCachedHcAnyway,
    required this.showCachedKtAnyway,
    required this.onShowCachedHc,
    required this.onShowCachedKt,
    required this.onHcAction,
    required this.onOpenActivities,
    required this.onOpenSteps,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final bool showCachedHcAnyway;
  final bool showCachedKtAnyway;
  final VoidCallback onShowCachedHc;
  final VoidCallback onShowCachedKt;
  final VoidCallback onHcAction;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HomeOfflineBanner(),
        _HomeCardList(
          period: period,
          barKey: barKey,
          showCachedHcAnyway: showCachedHcAnyway,
          showCachedKtAnyway: showCachedKtAnyway,
          onShowCachedHc: onShowCachedHc,
          onShowCachedKt: onShowCachedKt,
          onHcAction: onHcAction,
          onOpenActivities: onOpenActivities,
          onOpenSteps: onOpenSteps,
          onOpenNutrition: onOpenNutrition,
          onOpenBody: onOpenBody,
          onOpenSleep: onOpenSleep,
        ),
      ],
    );
  }
}

/// Banner above the cards when the device is offline. Scopes its
/// subscription to `ConnectivityProvider.isOnline` only so the rest of
/// the day content stays clean when the provider notifies but the bool
/// hasn't flipped.
class _HomeOfflineBanner extends StatelessWidget {
  const _HomeOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Selector<ConnectivityProvider, bool>(
      selector: (_, c) => c.isOnline,
      builder: (context, isOnline, _) {
        if (isOnline) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OfflineSourceBanner(
            // Tap is a no-op for the system-level offline state — there's
            // nothing the user can do in-app to restore connectivity.
            message: l10n.homeOfflineBanner,
            onTap: () {},
          ),
        );
      },
    );
  }
}

// ── Layout-decision record + card list ──────────────────────────────────────

/// Layout-decision values derived from `FitnessProvider` +
/// `KalorickeTabulkyProvider`. Drives which card slots collapse into
/// prompts vs. render their real content. Using a Dart 3 record gives
/// structural equality for free, so `Selector2` skips rebuilding when
/// the underlying state hasn't changed in a layout-relevant way.
typedef _CardVisibility = ({
  bool showHcPrompt,
  bool showHcOfflineBanner,
  bool hcUnavailable,
  bool showKtPrompt,
  bool showKtOfflineBanner,
  bool ktLoggedIn,
  bool ktSyncError,
  bool hasCachedHcData,
  bool hasCachedKtData,
});

/// Owns the reorderable list of dashboard cards. Subscribes via
/// `Selector2` to the small set of `FitnessProvider` + KT fields that
/// decide layout (HC prompt vs. real card, KT prompt vs. real card,
/// offline banners). Steps/kcal/sleep data ticks don't flip those
/// derived bits, so the `Selector2` builder is skipped — only the
/// individual slot widgets (which `context.watch` their own providers)
/// rebuild.
class _HomeCardList extends StatelessWidget {
  const _HomeCardList({
    required this.period,
    required this.barKey,
    required this.showCachedHcAnyway,
    required this.showCachedKtAnyway,
    required this.onShowCachedHc,
    required this.onShowCachedKt,
    required this.onHcAction,
    required this.onOpenActivities,
    required this.onOpenSteps,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final bool showCachedHcAnyway;
  final bool showCachedKtAnyway;
  final VoidCallback onShowCachedHc;
  final VoidCallback onShowCachedKt;
  final VoidCallback onHcAction;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Selector2<FitnessProvider, KalorickeTabulkyProvider, _CardVisibility>(
      selector: (_, fitness, kt) {
        final hcReady = fitness.accessState == FitnessAccessState.ready;
        final hcChecking = fitness.accessState == FitnessAccessState.checking;
        // Suppress the KT prompt while restoreSession() is still running
        // so the user doesn't see a flash of "sign in to KT" on cold
        // start when they already have stored credentials. Same
        // suppression applies when credentials exist but the network is
        // unreachable — pushing the user to a sign-in flow they can't
        // complete is worse than letting them stay in their
        // connected-but-offline state.
        return (
          showHcPrompt: !hcReady && !hcChecking && !showCachedHcAnyway,
          showHcOfflineBanner:
              !hcReady && !hcChecking && showCachedHcAnyway,
          hcUnavailable:
              fitness.accessState == FitnessAccessState.unavailable,
          showKtPrompt: !kt.isLoggedIn &&
              !kt.isInitializing &&
              !kt.hasStoredCredentials &&
              !showCachedKtAnyway,
          showKtOfflineBanner:
              !kt.isLoggedIn && !kt.isInitializing && showCachedKtAnyway,
          ktLoggedIn: kt.isLoggedIn,
          ktSyncError: kt.syncError != null,
          hasCachedHcData: _hasCachedHcData(fitness),
          hasCachedKtData: kt.hasCachedNutrition,
        );
      },
      builder: (context, viz, _) {
        final cardOrderProvider = context.watch<HomeCardOrderProvider>();
        final cardOrder = cardOrderProvider.order;

        final Widget stepsSlot = viz.showHcPrompt
            ? _DataSourcePromptCard(
                logoAsset: 'assets/icons/hc/health_connect_logo.png',
                accentColor: Tokens.weight.color,
                title: viz.hcUnavailable
                    ? l10n.healthNotAvailable
                    : l10n.healthPermissionRequired,
                body: viz.hcUnavailable
                    ? l10n.healthNotAvailableBody
                    : l10n.healthPermissionBody,
                ctaIcon: viz.hcUnavailable
                    ? Icons.download_rounded
                    : Icons.shield_outlined,
                ctaLabel: viz.hcUnavailable
                    ? l10n.healthInstall
                    : l10n.healthGrantAccess,
                onAction: onHcAction,
                onShowCached: viz.hasCachedHcData ? onShowCachedHc : null,
              )
            : _StepsSlot(
                period: period,
                barKey: barKey,
                showHcOfflineBanner: viz.showHcOfflineBanner,
                onHcAction: onHcAction,
                onOpenSteps: onOpenSteps,
              );

        final Widget caloriesSlot = viz.showKtPrompt
            ? _DataSourcePromptCard(
                logoAsset: 'assets/icons/kt/kaloricke_tabulky.png',
                accentColor: const Color(0xFF7AB342),
                title: l10n.caloriesTodayTitle,
                body: l10n.ktLoginPrompt,
                ctaIcon: Icons.settings_outlined,
                ctaLabel: l10n.ktGoToSettings,
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                onShowCached: viz.hasCachedKtData ? onShowCachedKt : null,
              )
            : _CaloriesSlot(
                period: period,
                barKey: barKey,
                showKtOfflineBanner: viz.showKtOfflineBanner,
                showKtSyncErrorBanner: viz.ktLoggedIn && viz.ktSyncError,
                onOpenNutrition: onOpenNutrition,
              );

        final Widget? weightSlot = viz.showHcPrompt
            ? null
            : _WeightSlot(
                period: period,
                barKey: barKey,
                onOpenBody: onOpenBody,
              );
        final Widget? activitySlot = viz.showHcPrompt
            ? null
            : _ActivitySlot(
                period: period,
                barKey: barKey,
                onOpenActivities: onOpenActivities,
              );
        final Widget? sleepSlot = viz.showHcPrompt
            ? null
            : _SleepSlot(
                period: period,
                barKey: barKey,
                onOpenSleep: onOpenSleep,
              );

        final slots = <HomeCardKind, Widget?>{
          HomeCardKind.steps: stepsSlot,
          HomeCardKind.calories: caloriesSlot,
          HomeCardKind.weight: weightSlot,
          HomeCardKind.activity: activitySlot,
          HomeCardKind.sleep: sleepSlot,
        };

        // Walk the user's stored order; drop slots hidden in the
        // current state but keep their position in the prefs so the
        // cards reappear in their preferred slot once the source
        // becomes available again.
        final visibleKinds = <HomeCardKind>[];
        final visibleWidgets = <Widget>[];
        for (final kind in cardOrder) {
          final w = slots[kind];
          if (w != null) {
            visibleKinds.add(kind);
            visibleWidgets.add(w);
          }
        }

        if (visibleWidgets.isEmpty) return const SizedBox.shrink();

        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Whole-card long-press drag instead of visible side handles.
          buildDefaultDragHandles: false,
          itemCount: visibleWidgets.length,
          itemBuilder: (ctx, i) {
            final isLast = i == visibleWidgets.length - 1;
            return ReorderableDelayedDragStartListener(
              key: ValueKey(visibleKinds[i]),
              index: i,
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: visibleWidgets[i],
              ),
            );
          },
          // Lift the dragged card so the user gets clear feedback.
          proxyDecorator: (child, index, anim) => Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            child: child,
          ),
          onReorder: (oldIndex, newIndex) {
            // ReorderableListView reports newIndex post-removal of the
            // dragged item, so subtract 1 when moving downward.
            var actualNew = newIndex;
            if (newIndex > oldIndex) actualNew -= 1;
            final fromKind = visibleKinds[oldIndex];
            final toKind = visibleKinds[actualNew];
            final fromAbs = cardOrder.indexOf(fromKind);
            final toAbs = cardOrder.indexOf(toKind);
            unawaited(cardOrderProvider.reorder(fromAbs, toAbs));
          },
        );
      },
    );
  }
}

// ── Per-card slot widgets ───────────────────────────────────────────────────
//
// Each slot owns its own provider subscription via `context.watch` so
// a notify on a provider only rebuilds the cards that actually read it.
// A KalorickeTabulkyProvider food-log notify rebuilds `_CaloriesSlot`
// alone; steps / weight / activity / sleep stay cached. A
// FitnessProvider step tick rebuilds the four HC-driven slots; the
// calorie slot stays cached.
//
// The list-level layout decisions (showHcPrompt / showKtPrompt) are
// owned by `_HomeCardList`'s `Selector2` so a steps tick doesn't flip
// the visible-slot set and the slot widgets keep their elements.

class _StepsSlot extends StatelessWidget {
  const _StepsSlot({
    required this.period,
    required this.barKey,
    required this.showHcOfflineBanner,
    required this.onHcAction,
    required this.onOpenSteps,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final bool showHcOfflineBanner;
  final VoidCallback onHcAction;
  final VoidCallback onOpenSteps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final steps = period.type == PeriodType.day
        ? fitness.stepsForDate(period.start)
        : fitness.stepsAvgForRange(period.start, period.end);
    final stepsGoal = goals.dailySteps;
    final stepsProgress =
        stepsGoal > 0 ? (steps / stepsGoal).clamp(0.0, 1.0) : 0.0;
    final stepsLeft = (stepsGoal - steps).clamp(0, stepsGoal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHcOfflineBanner) ...[
          _OfflineSourceBanner(
            message: l10n.healthOfflineNotice,
            onTap: onHcAction,
          ),
          const SizedBox(height: 10),
        ],
        StatCard(
          icon: '🥾',
          label: l10n.stepsTitle,
          domain: Tokens.steps,
          visualAssets:
              DashboardCardAssetResolver.forKind(DashboardCardKind.steps),
          stats: [
            StatStat(value: fmt.format(steps), label: l10n.stepsTitle),
            StatStat(value: fmt.format(stepsGoal), label: l10n.stepsGoal),
            StatStat(
              value:
                  period.type == PeriodType.day ? fmt.format(stepsLeft) : '--',
              label: period.type == PeriodType.day ? l10n.stepsRemaining : '',
            ),
          ],
          progress: stepsProgress,
          badge: '${(stepsProgress * 100).round()}%',
          xpData: _xpPillForQuest(
            context: context,
            progression: progression,
            period: period,
            questNodeId: 'daily_steps_today',
            barKey: barKey,
          ),
          children: [
            if (_streakInfoBlockForQuest(
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_steps_today',
                )
                case final block?) ...[
              const SizedBox(height: Tokens.spaceMd),
              block,
              const SizedBox(height: Tokens.spaceXs),
            ],
            DetailShortcutButton(onTap: onOpenSteps, domain: Tokens.steps),
          ],
        ),
      ],
    );
  }
}

class _CaloriesSlot extends StatelessWidget {
  const _CaloriesSlot({
    required this.period,
    required this.barKey,
    required this.showKtOfflineBanner,
    required this.showKtSyncErrorBanner,
    required this.onOpenNutrition,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final bool showKtOfflineBanner;
  final bool showKtSyncErrorBanner;
  final VoidCallback onOpenNutrition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        if (showKtSyncErrorBanner) ...[
          KtSyncErrorBanner(
            onRetry: () => kt.refreshRange(period.start, period.end),
          ),
          const SizedBox(height: 10),
        ],
        StatCard(
          icon: '🔥',
          label: period.type == PeriodType.day
              ? l10n.caloriesTodayTitle
              : l10n.caloriesAvgPerDay,
          domain: Tokens.calories,
          visualAssets:
              DashboardCardAssetResolver.forKind(DashboardCardKind.nutrition),
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
          xpData: _xpPillForQuest(
            context: context,
            progression: progression,
            period: period,
            questNodeId: 'daily_calories_today',
            barKey: barKey,
          ),
          children: [
            if (_streakInfoBlockForQuest(
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_calories_today',
                )
                case final block?) ...[
              const SizedBox(height: Tokens.spaceMd),
              block,
              const SizedBox(height: Tokens.spaceXs),
            ],
            const SizedBox(height: Tokens.spaceMd),
            if (nutritionHasDetails) ...[
              MacroRow(
                label: l10n.macroProtein,
                value: protein,
                goal: goals.dailyProtein,
                unit: 'g',
                domain: Tokens.protein,
                xpData: _xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_protein_today',
                  barKey: barKey,
                ),
              ),
              MacroRow(
                label: l10n.macroCarbs,
                value: carbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: Tokens.carbs,
                xpData: _xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_carbs_today',
                  barKey: barKey,
                ),
              ),
              MacroRow(
                label: l10n.macroFat,
                value: fat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: Tokens.fat,
                xpData: _xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_fat_today',
                  barKey: barKey,
                ),
              ),
              MacroRow(
                label: 'Fiber',
                value: fiber,
                goal: goals.dailyFiber,
                unit: 'g',
                domain: Tokens.calories,
                isLast: true,
                xpData: _xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_fiber_today',
                  barKey: barKey,
                ),
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
    );
  }
}

class _WeightSlot extends StatelessWidget {
  const _WeightSlot({
    required this.period,
    required this.barKey,
    required this.onOpenBody,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenBody;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fitness = context.watch<FitnessProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final weightForPeriod = _weightForPeriod(fitness, period);
    final prevWeight = _previousWeightForPeriod(fitness, period);
    final weightChange = (weightForPeriod != null && prevWeight != null)
        ? weightForPeriod - prevWeight
        : null;

    return StatCard(
      icon: '⚖',
      label: l10n.weightTitle,
      domain: Tokens.weight,
      visualAssets:
          DashboardCardAssetResolver.forKind(DashboardCardKind.weight),
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
      xpData: _xpPillForQuest(
        context: context,
        progression: progression,
        period: period,
        questNodeId: 'daily_weight_log_today',
        barKey: barKey,
        dayOnly: false,
      ),
      children: [
        if (_streakInfoBlockForQuest(
              progression: progression,
              period: period,
              questNodeId: 'daily_weight_log_today',
            )
            case final block?) ...[
          const SizedBox(height: Tokens.spaceMd),
          block,
          const SizedBox(height: Tokens.spaceXs),
        ],
        DetailShortcutButton(onTap: onOpenBody, domain: Tokens.weight),
      ],
    );
  }
}

class _ActivitySlot extends StatelessWidget {
  const _ActivitySlot({
    required this.period,
    required this.barKey,
    required this.onOpenActivities,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenActivities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final periodActivities = fitness.activities.where((activity) { // lint-ignore: widget-no-logic — UI period slice for overview chart aggregates
      final start = activity.startTime;
      final day = DateTime(start.year, start.month, start.day);
      return !day.isBefore(period.start) && !day.isAfter(period.end);
    }).toList(growable: false);
    final activeMinutes = periodActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.duration.inMinutes,
    );
    final activityGoal = _activityGoalForPeriod(goals, period);
    final activityProgress = activityGoal > 0
        ? (activeMinutes / activityGoal).clamp(0.0, 1.0)
        : 0.0;

    return StatCard(
      icon: '⚡',
      label: l10n.activitiesActiveMins,
      // Home-only crimson override; the rest of the activity domain
      // (progression pills, quests, journey) keeps the standard teal
      // via Tokens.active.
      domain: Tokens.activityCard,
      visualAssets:
          DashboardCardAssetResolver.forKind(DashboardCardKind.activity),
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
      xpData: _xpPillForQuest(
        context: context,
        progression: progression,
        period: period,
        questNodeId: 'daily_activity_today',
        barKey: barKey,
        dayOnly: false,
      ),
      children: [
        if (_streakInfoBlockForQuest(
              progression: progression,
              period: period,
              questNodeId: 'daily_activity_today',
            )
            case final block?) ...[
          const SizedBox(height: Tokens.spaceMd),
          block,
          const SizedBox(height: Tokens.spaceXs),
        ],
        if (period.type == PeriodType.day) ...[
          _ActivityClaimsList(
            claims: progression.activityClaimsForDate(
              date: period.start,
              activities: periodActivities,
            ),
            header: l10n.homeActivityClaimsHeader,
            onClaim: (record, center) {
              XpSparkleLauncher.launchToKey(
                context,
                from: center,
                targetKey: barKey,
              );
              unawaited(progression.claimActivity(record));
            },
          ),
        ],
        DetailShortcutButton(
          onTap: onOpenActivities,
          domain: Tokens.activityCard,
        ),
      ],
    );
  }
}

class _SleepSlot extends StatelessWidget {
  const _SleepSlot({
    required this.period,
    required this.barKey,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

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

    return StatCard(
      icon: '🌙',
      label: l10n.sleepTitle,
      domain: Tokens.sleep,
      visualAssets:
          DashboardCardAssetResolver.forKind(DashboardCardKind.sleep),
      stats: [
        StatStat(value: _fmtSleep(sleepDuration), label: l10n.sleepDuration),
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
      badge:
          sleepDuration != null ? '${(sleepProgress * 100).round()}%' : null,
      xpData: _xpPillForQuest(
        context: context,
        progression: progression,
        period: period,
        questNodeId: 'daily_sleep_today',
        barKey: barKey,
      ),
      children: [
        if (_streakInfoBlockForQuest(
              progression: progression,
              period: period,
              questNodeId: 'daily_sleep_today',
            )
            case final block?) ...[
          const SizedBox(height: Tokens.spaceMd),
          block,
          const SizedBox(height: Tokens.spaceXs),
        ],
        DetailShortcutButton(onTap: onOpenSleep, domain: Tokens.sleep),
      ],
    );
  }
}

// ── Shared / helper widgets (unchanged below) ───────────────────────────────

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
      return goals.dailyActivityMins;
    case PeriodType.week:
      if (weekly <= 0) return 0;
      return weekly;
    case PeriodType.month:
    case PeriodType.custom:
      if (weekly <= 0) return 0;
      return weekly * 4;
  }
}

// ── Per-activity claim list (expanded activity card) ────────────────────────

typedef _ActivityClaimTap = void Function(ActivityRecord record, Offset center);

/// Compact list of per-workout claim pills rendered inside the home
/// activity card's expanded body. One row per activity for the
/// selected day; each row carries an [XpClaimPill] reflecting the
/// engine's per-activity claim state (locked / claimable / claimed).
class _ActivityClaimsList extends StatelessWidget {
  const _ActivityClaimsList({
    required this.claims,
    required this.header,
    required this.onClaim,
  });

  final List<ActivityClaimState> claims;
  final String header;
  final _ActivityClaimTap onClaim;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) return const SizedBox.shrink();
    final ft = context.ft;
    return Padding(
      padding: const EdgeInsets.only(top: Tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            header.toUpperCase(),
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: ft.onSurfaceMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: Tokens.spaceSm),
          for (int i = 0; i < claims.length; i++)
            _ActivityClaimRow(
              key: ValueKey(claims[i].claimKey),
              state: claims[i],
              isLast: i == claims.length - 1,
              onClaim: onClaim,
            ),
        ],
      ),
    );
  }
}

class _ActivityClaimRow extends StatelessWidget {
  const _ActivityClaimRow({
    super.key,
    required this.state,
    required this.isLast,
    required this.onClaim,
  });

  final ActivityClaimState state;
  final bool isLast;
  final _ActivityClaimTap onClaim;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final record = state.record;
    final emoji = _emojiFor(record.type);
    final label = _formatType(record.type);
    final duration = _formatDuration(record.duration);
    final time = _formatStartTime(context, record.startTime);

    // Per-activity buff bonus mirrors the card-level pill so the
    // player sees the equipped companion's contribution on each row,
    // not only on the rolled-up card total above. Inline layout keeps
    // the bonus chip + headline on a single row — vertical space here
    // is tighter than on the main quest cards.
    final progression = context.read<ProgressionEngineProvider>();
    final companionBonus =
        progression.projectedCompanionBuffBonusForActivityClaim(state.previewXp);

    final XpClaimPillData pillData;
    if (state.isClaimed) {
      pillData = XpClaimPillData.claimed(
        state.previewXp,
        companionBonus: companionBonus,
      );
    } else if (state.isClaimable) {
      pillData = XpClaimPillData.claimable(
        state.previewXp,
        onTap: (center) => onClaim(record, center),
        companionBonus: companionBonus,
      );
    } else {
      pillData = XpClaimPillData.locked(
        state.previewXp,
        companionBonus: companionBonus,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: ft.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ft.active.dim,
                borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                border: Border.all(
                  color: ft.active.color.withValues(alpha: 0.25),
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ft.onSurface.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$time · $duration',
                    style: TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      color: ft.onSurfaceMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            XpClaimPill(data: pillData, inline: true),
          ],
        ),
      ),
    );
  }

  String _formatType(String hcType) => hcType
      .split('_')
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}m';
    final h = d.inHours;
    final rest = m - h * 60;
    return '${h}h ${rest.toString().padLeft(2, '0')}m';
  }

  String _formatStartTime(BuildContext context, DateTime t) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('HH:mm', locale).format(t);
  }

  String _emojiFor(String hcType) {
    final t = hcType.toUpperCase();
    if (t.contains('HIKE') || t.contains('TRAIL')) return '🥾';
    if (t.contains('RUN') || t.contains('JOG')) return '🏃';
    if (t.contains('CYCL') || t.contains('BIKE')) return '🚴';
    if (t.contains('SWIM')) return '🏊';
    if (t.contains('WALK')) return '🚶';
    if (t.contains('YOGA') || t.contains('MEDIT') || t.contains('STRETCH')) {
      return '🧘';
    }
    if (t.contains('STRENGTH') || t.contains('WEIGHT')) return '🏋';
    return '⚔';
  }
}
