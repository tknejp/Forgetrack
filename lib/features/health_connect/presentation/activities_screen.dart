import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/activity_row.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/period_navigator.dart';
import '../../../shared/widgets/plain_card.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/screen_link_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/swipe_period_gesture.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../../../shared/widgets/xp_claim_pill.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../application/fitness_provider.dart';
import '../domain/activity_record.dart';
import 'activity_detail_screen.dart';
import 'steps_screen.dart';

/// Workout-focused detail screen. Today header → period navigator with tabs →
/// period stats → activity-type breakdown chart → recent activities list.
/// Cross-links to the Steps screen at the bottom.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  SelectedPeriod _period = SelectedPeriod.currentWeek();

  /// True while the section-header bulk-claim is iterating. Disables
  /// the pill to prevent double-fires and surfaces a spinner so the
  /// user knows work is in flight. Retroactive cross-period claim
  /// lives in the quest-screen backfill section; this screen only
  /// claims what's visible in the currently-selected period.
  bool _isClaimingAll = false;

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

  ({ActivityType type, String emoji}) _mapActivity(String hcType) {
    final type = hcType.toUpperCase();
    if (type.contains('WALK')) {
      return (type: ActivityType.walking, emoji: '🚶');
    }
    if (type.contains('RUN') || type.contains('JOG')) {
      return (type: ActivityType.walking, emoji: '🏃');
    }
    if (type.contains('CYCL') || type.contains('BIKE')) {
      return (type: ActivityType.walking, emoji: '🚴');
    }
    if (type.contains('SWIM')) {
      return (type: ActivityType.walking, emoji: '🏊');
    }
    if (type.contains('HIKE') || type.contains('TRAIL')) {
      return (type: ActivityType.walking, emoji: '🥾');
    }
    if (type.contains('YOGA') || type.contains('MEDIT')) {
      return (type: ActivityType.strength, emoji: '🧘');
    }
    return (type: ActivityType.strength, emoji: '⚔');
  }

  String _formatActivityType(String hcType) => hcType
      .split('_')
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = duration.inHours;
    final remainingMinutes = minutes - hours * 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  String _activityDateLabel(BuildContext context, DateTime dateTime) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = DateFormat('HH:mm', locale).format(dateTime);
    if (activityDay == today) return '${l10n.headerToday} | $time';
    return '${DateFormat.E(locale).format(dateTime)} ${dateTime.day} | $time';
  }

  /// Aggregates a list of activities into one ChartBar per HC type, value =
  /// total minutes. Sorted by minutes descending so the dominant type sits
  /// at the left of the chart.
  List<ChartBar> _buildTypeBreakdownBars(List<ActivityRecord> activities) {
    if (activities.isEmpty) return const [];
    final byType = <String, int>{};
    for (final a in activities) {
      final key = a.type.toUpperCase();
      byType[key] = (byType[key] ?? 0) + a.duration.inMinutes;
    }
    final entries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        ChartBar(
          label: _formatActivityType(e.key),
          value: e.value.toDouble(),
        ),
    ];
  }

  /// Iterates every claimable workout in the engine's retroactive
  /// window and claims them sequentially. `claimActivity` internally
  /// guards on `_isEvaluating`, so awaiting each call serialises the
  /// loop without bypassing the engine's concurrency lock.
  ///
  /// On success: surfaces a snackbar with the total XP granted and
  /// exits claim mode since the list would otherwise be empty.
  Future<void> _claimAllBackfill(
    BuildContext context,
    List<ActivityRecord> claimable,
  ) async {
    if (_isClaimingAll || claimable.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final provider = context.read<ProgressionEngineProvider>();

    // Snapshot the preview total before claims fire — once each
    // grant lands, `activityClaim(record).previewXp` switches to the
    // claimed-amount path which would re-read the same number, but
    // capturing up-front sidesteps any race on the iterator.
    final totalXp = claimable.fold<int>(
      0,
      (sum, a) => sum + provider.activityClaim(a).previewXp,
    );

    setState(() => _isClaimingAll = true);
    var claimed = 0;
    try {
      for (final a in claimable) {
        await provider.claimActivity(a);
        claimed += 1;
      }
    } finally {
      if (mounted) setState(() => _isClaimingAll = false);
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.activitiesBackfillClaimedToast(claimed, totalXp),
        ),
      ),
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    ActivityRecord activity,
    bool isLast,
  ) {
    final mapped = _mapActivity(activity.type);
    final progression = context.watch<ProgressionEngineProvider>();
    final claim = progression.activityClaim(activity);

    XpClaimPillData pillData;
    if (claim.isClaimed) {
      pillData = XpClaimPillData.claimed(claim.previewXp);
    } else if (claim.isClaimable) {
      pillData = XpClaimPillData.claimable(
        claim.previewXp,
        // Sub-screen has no anchor for the XP-to-AppBar sparkle —
        // pill's own state-change is sufficient feedback here.
        onTap: (_) => progression.claimActivity(activity),
      );
    } else {
      pillData = XpClaimPillData.locked(claim.previewXp);
    }

    return ActivityRow(
      type: mapped.type,
      typeLabel: _formatActivityType(activity.type).toUpperCase(),
      typeEmoji: mapped.emoji,
      date: _activityDateLabel(context, activity.startTime),
      duration: _formatDuration(activity.duration),
      kcal: activity.caloriesBurned != null
          ? '${activity.caloriesBurned} kcal'
          : '-- kcal',
      xpData: pillData,
      isLast: isLast,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activity: activity),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionEngineProvider>();
    final tab = _tab(context, _period);

    // ── Today (period-independent) ──────────────────────────────────────
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayActivities = fitness.activities.where((a) {
      final day =
          DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
      return day == today;
    }).toList();
    final todayActiveMinutes =
        todayActivities.fold<int>(0, (sum, a) => sum + a.duration.inMinutes);
    final todayKcal = todayActivities.fold<int>(
      0,
      (sum, a) => sum + (a.caloriesBurned ?? 0),
    );

    // ── Period-driven aggregates ────────────────────────────────────────
    final periodActivities = fitness.activities.where((a) {
      final day =
          DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
      return !day.isBefore(_period.start) && !day.isAfter(_period.end);
    }).toList();
    final periodActiveMinutes = periodActivities.fold<int>(
      0,
      (sum, a) => sum + a.duration.inMinutes,
    );
    final periodKcal = periodActivities.fold<int>(
      0,
      (sum, a) => sum + (a.caloriesBurned ?? 0),
    );
    final goalMinutes = goals.weeklyActivityMins;
    final activeMinsProgress = goalMinutes > 0
        ? (periodActiveMinutes / goalMinutes).clamp(0.0, 1.0)
        : 0.0;
    final typeBars = _buildTypeBreakdownBars(periodActivities);

    final recentActivities = [...periodActivities]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    // Claimables in the period-filtered list — the section-header
    // bulk-claim pill claims exactly what the player is looking at.
    // Cross-period retroactive claim lives in the quest-screen
    // backfill section, so this screen doesn't need its own window
    // computation anymore.
    final listClaimable = recentActivities
        .where((a) => progression.activityClaim(a).isClaimable)
        .toList();
    final listTotalXp = listClaimable.fold<int>(
      0,
      (sum, a) => sum + progression.activityClaim(a).previewXp,
    );

    return SwipePeriodGesture(
      onPrev: () => setState(() => _period = _period.backward()),
      onNext: _period.canGoForward
          ? () => setState(() => _period = _period.forward())
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!fitness.workoutPermissionGranted &&
              fitness.accessState == FitnessAccessState.ready) ...[
            _WorkoutPermissionBanner(
              onTap: () => fitness.requestWorkoutPermission(),
            ),
            const SizedBox(height: 10),
          ],

          // ── Today header ────────────────────────────────────────────
          StatCard(
            icon: '⚡',
            label: '${l10n.activitiesActiveMins} · ${l10n.headerToday}',
            domain: Tokens.active,
            visualAssets: DashboardCardAssetResolver.forKind(
              DashboardCardKind.activity,
            ),
            initiallyExpanded: true,
            collapsible: false,
            stats: [
              StatStat(
                value: '$todayActiveMinutes',
                label: l10n.activitiesActiveMins,
                unit: 'min',
              ),
              StatStat(
                value: '${todayActivities.length}',
                label: l10n.activitiesWorkouts,
              ),
              StatStat(
                value: todayKcal > 0 ? '$todayKcal' : '--',
                label: l10n.activitiesActiveCalories,
                unit: 'kcal',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Period navigator + tabs ─────────────────────────────────
          PeriodNavigator(
            domain: Tokens.active,
            tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
            activeTab: tab,
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

          // ── Period stats ───────────────────────────────────────────
          StatCard(
            icon: '🏋',
            label: '${l10n.activitiesActiveMins} · ${tab.toLowerCase()}',
            domain: Tokens.active,
            visualAssets: DashboardCardAssetResolver.forKind(
              DashboardCardKind.activity,
            ),
            initiallyExpanded: true,
            collapsible: false,
            stats: [
              StatStat(
                value: '$periodActiveMinutes',
                label: l10n.activitiesActiveMins,
                unit: 'min',
              ),
              StatStat(
                value: '${periodActivities.length}',
                label: l10n.activitiesWorkouts,
              ),
              StatStat(
                value: periodKcal > 0 ? '$periodKcal' : '--',
                label: l10n.activitiesActiveCalories,
                unit: 'kcal',
              ),
            ],
            progress: activeMinsProgress,
            badge: '${(activeMinsProgress * 100).round()}%',
          ),

          const SizedBox(height: 10),

          // ── Activity-type breakdown ────────────────────────────────
          if (typeBars.length >= 2) ...[
            TrendCard(
              domain: Tokens.active,
              icon: Icons.donut_small_rounded,
              title: l10n.activitiesByType,
              subtitle: _periodDateLabel(context, _period),
              collapsible: false,
              metrics: const [],
              bars: typeBars,
              relativeScale: false,
              emptyLabel: l10n.activitiesNoWorkouts,
              expandable: typeBars.length > 4,
            ),
            const SizedBox(height: 10),
          ],

          // ── Recent activities (period-filtered) ────────────────────
          PlainCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.activitiesRecentActivity.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w700,
                          color: Color(0x80FFFFFF),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (listClaimable.isNotEmpty)
                      _ClaimAllPill(
                        label:
                            l10n.activitiesBackfillClaimAll(listTotalXp),
                        isLoading: _isClaimingAll,
                        onTap: _isClaimingAll
                            ? null
                            : () => _claimAllBackfill(
                                  context,
                                  listClaimable,
                                ),
                        accent: context.ft.xp,
                      ),
                  ],
                ),
                const SizedBox(height: Tokens.spaceXs),
                if (recentActivities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      fitness.workoutPermissionGranted
                          ? l10n.activitiesNoWorkouts
                          : l10n.activitiesWorkoutPermissionBody,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Tokens.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (int i = 0; i < recentActivities.length; i++)
                    _buildActivityRow(
                      context,
                      recentActivities[i],
                      i == recentActivities.length - 1,
                    ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Cross-link: jump to Steps ──────────────────────────────
          ScreenLinkCard(
            title: l10n.screenSteps,
            subtitle: l10n.stepsLinkSubtitle,
            icon: Icons.directions_walk_rounded,
            domain: Tokens.steps,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StepsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => fitness.refresh(),
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
                        title: context.l10n.screenActivities,
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
                  child: _buildContent(context, fitness, goals),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutPermissionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _WorkoutPermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Tokens.active.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: Tokens.active.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.activitiesWorkoutPermissionBody,
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

/// Subtle pill used by the section-header bulk-claim affordance.
/// Visual style mirrors the per-row [XpClaimPill] in its claimable
/// state — accent tint background + border + accent text — so the
/// section action reads as "a pill that claims many things" rather
/// than a CTA that competes with the page hero. Disabled or
/// in-flight: faded contents, same surface so layout doesn't reflow.
class _ClaimAllPill extends StatelessWidget {
  const _ClaimAllPill({
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    final contentOpacity = enabled ? 1.0 : 0.55;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Opacity(
          opacity: contentOpacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                )
              else
                Icon(Icons.bolt_rounded, size: 11, color: accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
