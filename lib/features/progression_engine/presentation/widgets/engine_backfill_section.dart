import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../../../shared/widgets/xp_sparkle_overlay.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/backfill/backfill_config.dart';
import '../../domain/backfill/daily_backfill_models.dart';
import 'engine_quest_section.dart';
import 'progression_primitives.dart';

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
        .where((e) => e.hasAnyContent)
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
          _BuildList(
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
          _ShowMoreButton(
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

/// Small typed wrapper so the row's claim handler doesn't have to
/// thread the whole [ActivityClaimState] all the way through —
/// callers only need the underlying record + identity for the sparkle
/// key.
class ActivityClaimRef {
  ActivityClaimRef(this.record);
  final dynamic record;
}

class _BuildList extends StatelessWidget {
  const _BuildList({
    required this.entries,
    required this.today,
    required this.l10n,
    required this.expandedDayKey,
    required this.onToggle,
    required this.onClaimGoal,
    required this.onClaimQuest,
    required this.onClaimActivity,
    required this.onClaimAllDay,
    required this.isClaimingAll,
    required this.pillKeyFor,
    required this.dayKeyOf,
  });

  final List<DailyBackfillEntry> entries;
  final DateTime today;
  final AppLocalizations l10n;
  final String? expandedDayKey;
  final void Function(String dayKey) onToggle;
  final Future<void> Function(
    DailyGoalClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaimGoal;
  final Future<void> Function(
    DailyQuestClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaimQuest;
  final Future<void> Function(ActivityClaimRef ref, Offset? sparkleFrom)
      onClaimActivity;
  final Future<void> Function(DailyBackfillEntry entry) onClaimAllDay;
  final bool isClaimingAll;
  final GlobalKey Function(String composite) pillKeyFor;
  final String Function(DateTime day) dayKeyOf;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    int? lastWeekIndex;
    for (final e in entries) {
      final weekIdx = _weeksAgo(e.date, today);
      if (weekIdx != lastWeekIndex) {
        tiles.add(_WeekGroupHeader(
          label: _groupLabel(weekIdx, l10n),
        ));
        lastWeekIndex = weekIdx;
      }
      final dKey = dayKeyOf(e.date);
      tiles.add(
        _BackfillDayCard(
          entry: e,
          today: today,
          dayKey: dKey,
          isExpanded: expandedDayKey == dKey,
          onToggle: () => onToggle(dKey),
          l10n: l10n,
          onClaimGoal: onClaimGoal,
          onClaimQuest: onClaimQuest,
          onClaimActivity: onClaimActivity,
          onClaimAllDay: onClaimAllDay,
          isClaimingAll: isClaimingAll,
          pillKeyFor: pillKeyFor,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          tiles[i],
        ],
      ],
    );
  }

  String _groupLabel(int weeksAgo, AppLocalizations l10n) {
    if (weeksAgo == 0) return l10n.progBackfillGroupThisWeek;
    if (weeksAgo == 1) return l10n.progBackfillGroupLastWeek;
    if (weeksAgo < 4) return l10n.progBackfillGroupWeeksAgo(weeksAgo);
    final monthsAgo = (weeksAgo / 4).floor();
    if (monthsAgo == 1) return l10n.progBackfillGroupMonthAgo;
    return l10n.progBackfillGroupMonthsAgo(monthsAgo);
  }

  /// Number of full calendar weeks between [day] and [today] when
  /// weeks anchor on Monday (Czech convention). Used to decide which
  /// group header a day card lives under.
  int _weeksAgo(DateTime day, DateTime today) {
    final mondayOfToday =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final mondayOfDay =
        day.subtract(Duration(days: day.weekday - DateTime.monday));
    return mondayOfToday.difference(mondayOfDay).inDays ~/ 7;
  }
}

class _WeekGroupHeader extends StatelessWidget {
  const _WeekGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, Tokens.spaceMd, 4, Tokens.spaceXs),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: Tokens.onSurfaceMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _BackfillDayCard extends StatelessWidget {
  const _BackfillDayCard({
    required this.entry,
    required this.today,
    required this.dayKey,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
    required this.onClaimGoal,
    required this.onClaimQuest,
    required this.onClaimActivity,
    required this.onClaimAllDay,
    required this.isClaimingAll,
    required this.pillKeyFor,
  });

  final DailyBackfillEntry entry;
  final DateTime today;
  final String dayKey;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
  final Future<void> Function(
    DailyGoalClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaimGoal;
  final Future<void> Function(
    DailyQuestClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaimQuest;
  final Future<void> Function(ActivityClaimRef ref, Offset? sparkleFrom)
      onClaimActivity;
  final Future<void> Function(DailyBackfillEntry entry) onClaimAllDay;
  final bool isClaimingAll;
  final GlobalKey Function(String composite) pillKeyFor;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final pending = entry.pendingCount;
    final claimable = entry.claimableXp;
    final claimed = entry.claimedXp;
    final hasAnyXp = claimed + claimable > 0;
    final dateLabel = _relativeDateLabel(context, entry.date, today, l10n);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: pending > 0
                ? ft.xp.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            // Header row.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (hasAnyXp) ...[
                          const SizedBox(height: 2),
                          Text(
                            _summaryLabel(claimed, claimable),
                            style: TextStyle(
                              fontSize: Tokens.fontSizeMicro,
                              fontWeight: FontWeight.w600,
                              color: pending > 0
                                  ? ft.xp
                                  : Tokens.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (pending > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ft.xp.withValues(alpha: 0.16),
                        borderRadius:
                            BorderRadius.circular(Tokens.radiusProgress),
                        border: Border.all(
                          color: ft.xp.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Text(
                        l10n.progBackfillPendingChip(pending),
                        style: TextStyle(
                          fontSize: Tokens.fontSizeMicro,
                          fontWeight: FontWeight.w700,
                          color: ft.xp,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Tokens.onSurfaceMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x14FFFFFF),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final g in entry.dailyGoals)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _DailyGoalRow(
                          item: g,
                          day: entry.date,
                          pillKey: pillKeyFor(
                            'goal|${g.nodeId}|$dayKey',
                          ),
                          onClaim: onClaimGoal,
                          l10n: l10n,
                        ),
                      ),
                    if (entry.dailyGoals.isNotEmpty &&
                        entry.dailyQuests.isNotEmpty)
                      const SizedBox(height: 4),
                    for (final q in entry.dailyQuests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _DailyQuestRow(
                          item: q,
                          day: entry.date,
                          pillKey: pillKeyFor(
                            'quest|${q.nodeId}|$dayKey',
                          ),
                          onClaim: onClaimQuest,
                          l10n: l10n,
                        ),
                      ),
                    if ((entry.dailyGoals.isNotEmpty ||
                            entry.dailyQuests.isNotEmpty) &&
                        entry.activities.isNotEmpty)
                      const SizedBox(height: 4),
                    for (final a in entry.activities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ActivityClaimRowSimple(
                          state: a,
                          pillKey: pillKeyFor(
                            'act|${a.record.startTime.millisecondsSinceEpoch}',
                          ),
                          onClaim: onClaimActivity,
                        ),
                      ),
                    if (claimable > 0) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ClaimAllPill(
                          label: l10n.progBackfillClaimAllDay(claimable),
                          isLoading: isClaimingAll,
                          onTap: isClaimingAll
                              ? null
                              : () => onClaimAllDay(entry),
                          accent: ft.xp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _summaryLabel(int claimed, int claimable) {
    if (claimable == 0) return '+$claimed XP';
    if (claimed == 0) return '+$claimable XP k vyzvednutí';
    return '+$claimed XP · +$claimable XP k vyzvednutí';
  }

  String _relativeDateLabel(
    BuildContext context,
    DateTime day,
    DateTime today,
    AppLocalizations l10n,
  ) {
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.progBackfillDayHeaderToday;
    if (diff == 1) return l10n.progBackfillDayHeaderYesterday;
    final locale = Localizations.localeOf(context).toString();
    if (diff < 7) {
      // Capitalise the weekday — DateFormat.EEEE returns lowercase in
      // some locales.
      final label = DateFormat.EEEE(locale).format(day);
      return label.isEmpty
          ? label
          : '${label[0].toUpperCase()}${label.substring(1)}';
    }
    return DateFormat('d. MMMM', locale).format(day);
  }
}

/// Compact backfill row for a daily-section quest offered on this
/// day. Smaller than [_DailyGoalRow] — no value / target column, just
/// quest icon + title + pill — so the day card stays readable when
/// many goals + quests + activities stack up.
class _DailyQuestRow extends StatelessWidget {
  const _DailyQuestRow({
    required this.item,
    required this.day,
    required this.pillKey,
    required this.onClaim,
    required this.l10n,
  });

  final DailyQuestClaimItem item;
  final DateTime day;
  final GlobalKey pillKey;
  final Future<void> Function(
    DailyQuestClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaim;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = item.node.titleKey(l10n);

    return Row(
      children: [
        ProgDomIco(domain: item.domain, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 6),
        KeyedSubtree(
          key: pillKey,
          child: XpClaimPill(
            data: item.isClaimed
                ? XpClaimPillData.claimed(item.previewXp)
                : item.isClaimable
                    ? XpClaimPillData.claimable(
                        item.previewXp,
                        onTap: (center) => onClaim(item, day, center),
                      )
                    : XpClaimPillData.locked(item.previewXp),
          ),
        ),
      ],
    );
  }
}

class _DailyGoalRow extends StatelessWidget {
  const _DailyGoalRow({
    required this.item,
    required this.day,
    required this.pillKey,
    required this.onClaim,
    required this.l10n,
  });

  final DailyGoalClaimItem item;
  final DateTime day;
  final GlobalKey pillKey;
  final Future<void> Function(
    DailyGoalClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaim;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final title = item.node.titleKey(l10n);

    return Row(
      children: [
        ProgDomIco(domain: item.domain, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _valueLabel(item, l10n),
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w500,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _rowPill(context),
      ],
    );
  }

  Widget _rowPill(BuildContext context) {
    // No data at all on this day — surface a quiet "Bez záznamu" hint
    // instead of a misleading "0 / 10000" claim row.
    if (!item.hasData && !item.isClaimed) {
      return _MutedHintPill(text: l10n.progBackfillGoalNoData);
    }
    if (item.isClaimed) {
      return KeyedSubtree(
        key: pillKey,
        child: XpClaimPill(data: XpClaimPillData.claimed(item.previewXp)),
      );
    }
    if (item.isClaimable) {
      return KeyedSubtree(
        key: pillKey,
        child: XpClaimPill(
          data: XpClaimPillData.claimable(
            item.previewXp,
            onTap: (center) {
              onClaim(item, day, center);
            },
          ),
        ),
      );
    }
    // Met but outside window OR not met.
    if (!item.isMet) {
      return _MutedHintPill(text: l10n.progBackfillGoalUnmet);
    }
    // Met but window closed — show the XP value greyed out.
    return KeyedSubtree(
      key: pillKey,
      child: XpClaimPill(data: XpClaimPillData.locked(item.previewXp)),
    );
  }

  String _valueLabel(DailyGoalClaimItem item, AppLocalizations l10n) {
    switch (item.valueUnit) {
      case DailyGoalValueUnit.count:
        final actualStr = _formatNumber(item.actualValue);
        final targetStr = _formatNumber(item.targetValue);
        return '$actualStr / $targetStr';
      case DailyGoalValueUnit.minutes:
        return '${_formatMinutes(item.actualValue)} / '
            '${_formatMinutes(item.targetValue)}';
      case DailyGoalValueUnit.flag:
        // Weight log etc. — value/target carries no extra info beyond
        // "logged" vs "not". The pill already tells the player.
        return '';
    }
  }

  String _formatNumber(double value) {
    final rounded = value.round();
    return rounded.toString();
  }

  String _formatMinutes(double minutes) {
    final total = minutes.round();
    if (total < 60) return '${total}m';
    final h = total ~/ 60;
    final rest = total - h * 60;
    return '${h}h ${rest.toString().padLeft(2, '0')}m';
  }
}

class _ActivityClaimRowSimple extends StatelessWidget {
  const _ActivityClaimRowSimple({
    required this.state,
    required this.pillKey,
    required this.onClaim,
  });

  final dynamic state; // ActivityClaimState — kept dynamic to avoid extra import
  final GlobalKey pillKey;
  final Future<void> Function(ActivityClaimRef ref, Offset? sparkleFrom)
      onClaim;

  @override
  Widget build(BuildContext context) {
    final record = state.record;
    final ft = context.ft;
    final time = _formatStartTime(context, record.startTime);
    final duration = _formatDuration(record.duration);
    final label = _formatType(record.type);
    final emoji = _emojiFor(record.type);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ft.active.dim,
            borderRadius: BorderRadius.circular(Tokens.radiusIcon),
            border: Border.all(
              color: ft.active.color.withValues(alpha: 0.25),
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$time · $duration',
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w500,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        KeyedSubtree(
          key: pillKey,
          child: XpClaimPill(
            data: state.isClaimed
                ? XpClaimPillData.claimed(state.previewXp)
                : state.isClaimable
                    ? XpClaimPillData.claimable(
                        state.previewXp,
                        onTap: (center) =>
                            onClaim(ActivityClaimRef(record), center),
                      )
                    : XpClaimPillData.locked(state.previewXp),
          ),
        ),
      ],
    );
  }

  String _formatType(String hcType) => hcType
      .split('_')
      .map(
        (w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
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

class _MutedHintPill extends StatelessWidget {
  const _MutedHintPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w600,
          color: Tokens.onSurfaceFaint,
        ),
      ),
    );
  }
}

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
          opacity: enabled ? 1.0 : 0.55,
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

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          '$label →',
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w700,
            color: Tokens.accent,
          ),
        ),
      ),
    );
  }
}
