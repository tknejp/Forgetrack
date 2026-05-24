import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/xp_sparkle_overlay.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/backfill/backfill_config.dart';
import '../../domain/backfill/daily_backfill_models.dart';
import 'backfill/backfill_chrome.dart';
import 'backfill/backfill_rows.dart';
import 'engine_quest_section.dart';

/// Quest-screen section that lists past days as expandable cards.
/// Each card surfaces every daily-goal claim + per-activity claim for
/// that day, so the player has one place to retroactively claim
/// rewards they forgot about during the day. Doubles as an audit log
/// — already-claimed pills stay visible in the [claimed] visual state
/// showing the XP that was credited.
///
/// Default window = 14 days back from today (matching
/// [makeHistoricalClaimWindow]'s default `lookbackDays`). "Show more"
/// extends the listed range in 14-day chunks, clamped to the player's
/// join date so days that predate the install never render.
class EngineBackfillSection extends StatefulWidget {
  const EngineBackfillSection({
    super.key,
    required this.barKey,
    required this.l10n,
  });

  /// Sparkle target — the progression bar in the shell header. Forwarded
  /// to [XpSparkleLauncher.launchToKey] when the player taps a pill so
  /// the XP animation lands on the bar rather than disappearing in
  /// place.
  final GlobalKey barKey;
  final AppLocalizations l10n;

  @override
  State<EngineBackfillSection> createState() =>
      _EngineBackfillSectionState();
}

class _EngineBackfillSectionState extends State<EngineBackfillSection> {
  /// How many calendar days the section currently shows, including
  /// today. Bumped by the "Show more" footer; clamped at runtime to
  /// `today - joinedAt + 1` so the user can't ask for days the engine
  /// has nothing about.
  int _maxDays = kBackfillVisibleInitialDays;

  /// One day card is expandable at a time (matches the V2 quests
  /// screen's per-card pattern). Null = everything collapsed.
  String? _expandedDayKey;

  /// True while a [_claimAllForDay] iteration is in flight. Disables
  /// the day's claim-all pill so a double tap can't fire two parallel
  /// claim loops.
  bool _isClaimingAll = false;

  /// GlobalKey per (nodeId, dayKey) so the sparkle launcher can read
  /// each pill's screen position. Lazily allocated on first use; the
  /// map persists across rebuilds because per-key reuse keeps the
  /// targets stable while the list animates open/closed.
  final Map<String, GlobalKey> _pillKeys = {};

  GlobalKey _pillKeyFor(String composite) =>
      _pillKeys.putIfAbsent(composite, () => GlobalKey(debugLabel: composite));

  Offset? _centerOfKey(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) +
        Offset(box.size.width / 2, box.size.height / 2);
  }

  String _dayKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  void _toggleExpanded(String dayKey) {
    setState(() {
      _expandedDayKey = _expandedDayKey == dayKey ? null : dayKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final provider = context.watch<ProgressionEngineProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final join = DateTime(
      provider.joinedAt.year,
      provider.joinedAt.month,
      provider.joinedAt.day,
    );

    final totalAvailableDays = today.difference(join).inDays + 1;
    final shownDays = _maxDays.clamp(1, totalAvailableDays);
    final startDay = today.subtract(Duration(days: shownDays - 1));

    final entries = provider
        .dailyBackfillForRange(startDay: startDay, endDay: today)
        .where((e) => e.hasAnyContent) // lint-ignore: widget-no-logic — drop empty days from the provider-built backfill range
        .toList(growable: false);

    final totalPending = entries.fold<int>(0, (sum, e) => sum + e.pendingCount);
    final hasMore = shownDays < totalAvailableDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EngineQuestSection(
          label: l10n.progBackfillSectionLabel,
          color: Tokens.calories.color,
          countLabel: totalPending == 0
              ? null
              : l10n.progBackfillPendingChip(totalPending),
          isEmpty: true,
          children: const [],
        ),
        if (entries.isEmpty)
          EngineQuestEmptyLine(
            title: l10n.progBackfillEmptyTitle,
            caption: l10n.progBackfillEmptyCaption,
          )
        else
          BackfillList(
            entries: entries,
            today: today,
            l10n: l10n,
            expandedDayKey: _expandedDayKey,
            onToggle: _toggleExpanded,
            onClaimGoal: _claimGoal,
            onClaimQuest: _claimQuest,
            onClaimActivity: _claimActivity,
            onClaimAllDay: _claimAllForDay,
            isClaimingAll: _isClaimingAll,
            pillKeyFor: _pillKeyFor,
            dayKeyOf: _dayKey,
          ),
        if (hasMore) ...[
          const SizedBox(height: Tokens.spaceMd),
          BackfillShowMoreButton(
            label: _showMoreLabel(
              totalAvailableDays: totalAvailableDays,
              shownDays: shownDays,
              join: join,
              l10n: l10n,
            ),
            onTap: () => setState(() {
              _maxDays = (shownDays + kBackfillVisibleIncrementDays)
                  .clamp(1, totalAvailableDays);
            }),
          ),
        ],
      ],
    );
  }

  String _showMoreLabel({
    required int totalAvailableDays,
    required int shownDays,
    required DateTime join,
    required AppLocalizations l10n,
  }) {
    final remaining = totalAvailableDays - shownDays;
    // When the next "show more" chunk would already cover everything,
    // promote the label to the explicit "since {date}" form so the
    // player sees how far back the list will jump.
    if (remaining <= kBackfillVisibleIncrementDays) {
      final locale = Localizations.localeOf(context).toString();
      final dateStr = DateFormat('d. MMMM', locale).format(join);
      return l10n.progBackfillShowAllSinceJoin(dateStr);
    }
    return l10n.progBackfillShowMore(kBackfillVisibleIncrementDays);
  }

  // ── Claim handlers ──────────────────────────────────────────────

  Future<void> _claimGoal(
    DailyGoalClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) async {
    final provider = context.read<ProgressionEngineProvider>();
    if (sparkleFrom != null) {
      XpSparkleLauncher.launchToKey(
        context,
        from: sparkleFrom,
        targetKey: widget.barKey,
      );
    }
    await provider.claimDailyGoal(nodeId: item.nodeId, day: day);
  }

  Future<void> _claimQuest(
    DailyQuestClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) async {
    final provider = context.read<ProgressionEngineProvider>();
    if (sparkleFrom != null) {
      XpSparkleLauncher.launchToKey(
        context,
        from: sparkleFrom,
        targetKey: widget.barKey,
      );
    }
    await provider.claimDailyQuest(nodeId: item.nodeId, day: day);
  }

  Future<void> _claimActivity(
    ActivityClaimRef ref,
    Offset? sparkleFrom,
  ) async {
    final provider = context.read<ProgressionEngineProvider>();
    if (sparkleFrom != null) {
      XpSparkleLauncher.launchToKey(
        context,
        from: sparkleFrom,
        targetKey: widget.barKey,
      );
    }
    await provider.claimActivity(ref.record);
  }

  Future<void> _claimAllForDay(DailyBackfillEntry entry) async {
    if (_isClaimingAll) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = widget.l10n;
    final provider = context.read<ProgressionEngineProvider>();

    // Snapshot what's about to be claimed and the preview XP up front
    // — once each grant lands the live `previewXp` switches to the
    // claimed-amount path, so collecting after the fact would
    // double-count.
    final goalTargets = [
      for (final g in entry.dailyGoals)
        if (g.isClaimable) g,
    ];
    final questTargets = [
      for (final q in entry.dailyQuests)
        if (q.isClaimable) q,
    ];
    final activityTargets = [
      for (final a in entry.activities)
        if (a.isClaimable) a.record,
    ];
    final totalXp = entry.claimableXp;
    final pendingCount =
        goalTargets.length + questTargets.length + activityTargets.length;
    if (pendingCount == 0) return;

    // Launch a single sparkle burst per pill so the visual reads as
    // "everything I just claimed flew up".
    final origins = <Offset>[];
    for (final g in goalTargets) {
      final c = _centerOfKey(
        _pillKeyFor('goal|${g.nodeId}|${_dayKey(entry.date)}'),
      );
      if (c != null) origins.add(c);
    }
    for (final q in questTargets) {
      final c = _centerOfKey(
        _pillKeyFor('quest|${q.nodeId}|${_dayKey(entry.date)}'),
      );
      if (c != null) origins.add(c);
    }
    for (final a in activityTargets) {
      final c = _centerOfKey(
        _pillKeyFor('act|${a.startTime.millisecondsSinceEpoch}'),
      );
      if (c != null) origins.add(c);
    }
    if (origins.isNotEmpty) {
      XpSparkleLauncher.launchManyToKey(
        context,
        fromPoints: origins,
        targetKey: widget.barKey,
      );
    }

    setState(() => _isClaimingAll = true);
    try {
      for (final g in goalTargets) {
        await provider.claimDailyGoal(nodeId: g.nodeId, day: entry.date);
      }
      for (final q in questTargets) {
        await provider.claimDailyQuest(nodeId: q.nodeId, day: entry.date);
      }
      for (final r in activityTargets) {
        await provider.claimActivity(r);
      }
    } finally {
      if (mounted) setState(() => _isClaimingAll = false);
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.progBackfillClaimedToast(pendingCount, totalXp),
        ),
      ),
    );
  }
}
