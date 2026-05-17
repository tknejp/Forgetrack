import 'package:forgetrack/domain/journal/journal_event.dart';
import '../domain/models/quest_display_bucket.dart';
import '../domain/models/quest_policies.dart';
import '../domain/repository/ledger_snapshot.dart';
import 'progression_engine_provider.dart' show EngineQuestProgress;

/// Output of [DailySectionResolver.resolve]. Carries the picks plus any
/// freshly-planned [QuestOfferedEvent]s the caller should persist —
/// the resolver itself stays pure / read-only so it's safe to call on
/// every UI rebuild.
class DailySectionResolution {
  const DailySectionResolution({
    required this.slots,
    required this.plannedOfferings,
  });

  /// Quest progress entries surfaced in the "DENNÍ ÚKOLY" section,
  /// in display order.
  final List<EngineQuestProgress> slots;

  /// `QuestOfferedEvent`s the resolver decided to record for today.
  /// May overlap with events already in the ledger — the provider
  /// diffs by eventKey before appending. Empty when the ledger
  /// already covers every slot for today.
  final List<QuestOfferedEvent> plannedOfferings;
}

/// Picks the quests that appear in the quests-tab "DENNÍ ÚKOLY"
/// section — the **bonus** daily quests layered on top of the
/// per-metric daily goals.
///
/// Scope: combo chain steps, daily challenges, and chapter side
/// quests. Per-metric daily-goal atoms (`QuestDisplayBucket.daily` —
/// steps / calories / macros / sleep / activity / weight) are
/// filtered out at the top of [resolve] because they have their own
/// per-metric claim affordances on the home screen's stat cards (see
/// `_xpPillForQuest` in `overview_screen`).
///
/// **Universal rotation rule**: once a quest is recorded as offered
/// on a given calendar day (via [QuestOfferedEvent]), the slot stays
/// locked to that quest for the rest of the day. Completion + claim
/// updates the visible pill state but does NOT free the slot;
/// rotation only happens after midnight. The resolver reads today's
/// offerings on every call to keep picks idempotent across UI
/// rebuilds.
///
/// **Tier order** (the order in which empty slots are filled):
/// 1. *Pinned chapter side quest* — first eligible (un-claimed,
///    ungated) side quest from the active chapter.
/// 2. *Active combo chain step* — first ungated step across all
///    active chains. Falls back to the just-completed step when the
///    chain's next step is gated by a same-day cooldown the player
///    only just cleared, so the slot reads "done for today" instead
///    of going empty.
/// 3. *Daily challenge / hash-rotation pick* — pulls from the daily
///    challenge pool, filtered by [offeredCooldownDays] so a
///    challenge that was offered in the last N days doesn't repeat
///    back-to-back.
///
/// Quests with `Persistent`, `ChapterCardSticky`, or
/// `HiddenFromSections` slot policies never appear here — they have
/// their own surfaces (long-term / chapter / hidden).
class DailySectionResolver {
  const DailySectionResolver({
    this.slotCount = 2,
    this.offeredCooldownDays = 2,
  });

  /// How many slots the daily section surfaces. V1 parity: 2.
  final int slotCount;

  /// Anti-repeat window for tier-3 picks. A daily challenge with a
  /// [QuestOfferedEvent] in the last `offeredCooldownDays` calendar
  /// days (excluding today) is filtered out of the pool. Defaults to
  /// 2 — challenge can't appear the day after today, but is eligible
  /// again two days out.
  final int offeredCooldownDays;

  DailySectionResolution resolve({
    required Iterable<EngineQuestProgress> quests,
    required LedgerSnapshot? ledger,
    required DateTime now,
    required Set<String> nodesCompletedTodayIds,
  }) {
    final todayKey = _dateKey(now);
    final todayOfferedNodeIds = <String>{};
    final cooldownNodeIds = <String>{};

    if (ledger != null && offeredCooldownDays > 0) {
      // Calendar window: `(today - offeredCooldownDays) .. (today - 1)`
      // inclusive. Today itself is tracked separately so the slot
      // pinning logic can reuse it.
      final earliestCooldown = _dateKey(
        now.subtract(Duration(days: offeredCooldownDays)),
      );
      for (final e in ledger.questOfferings) {
        if (e.dayKey == todayKey) {
          todayOfferedNodeIds.add(e.nodeId);
        } else if (e.dayKey.compareTo(earliestCooldown) >= 0 &&
            e.dayKey.compareTo(todayKey) < 0) {
          cooldownNodeIds.add(e.nodeId);
        }
      }
    }

    final byNodeId = <String, EngineQuestProgress>{
      for (final q in quests) q.nodeId: q,
    };

    final pinPool = <EngineQuestProgress>[];
    final chainPool = <EngineQuestProgress>[];
    final hashPool = <EngineQuestProgress>[];
    final challengePool = <EngineQuestProgress>[];

    for (final q in quests) {
      if (q.node.displayBucket == QuestDisplayBucket.daily) continue;
      switch (q.node.slotPolicy) {
        case PinClaimedTodayUntilMidnight():
          if (q.isLockedByConditions) continue;
          pinPool.add(q);
        case ChainPlaceholderUntilMidnight():
          chainPool.add(q);
        case HashRotationStickyUntilMidnight():
          if (q.levelGate == null && !q.isLockedByConditions) {
            hashPool.add(q);
          }
        case DailyChallengeHashPick():
          if (q.isLockedByConditions) continue;
          challengePool.add(q);
        case ChapterCardSticky():
        case Persistent():
        case HiddenFromSections():
          break;
      }
    }

    final slots = <EngineQuestProgress>[];
    final used = <String>{};
    final plannedOfferings = <QuestOfferedEvent>[];

    void takeFresh(EngineQuestProgress? q) {
      if (q == null) return;
      if (slots.length >= slotCount) return;
      if (!used.add(q.nodeId)) return;
      slots.add(q);
      plannedOfferings.add(_offering(q.nodeId, now, todayKey));
    }

    // ── Step 1: honour today's existing offerings ──────────────────
    // Iterate the canonical tier order to keep display order stable
    // even when the ledger returns offerings in insertion order. A
    // node that's already on the ledger gets the slot it would have
    // claimed during a fresh pick.
    for (final tier in <List<EngineQuestProgress>>[
      pinPool,
      chainPool,
      hashPool,
      challengePool,
    ]) {
      for (final q in tier) {
        if (slots.length >= slotCount) break;
        if (!todayOfferedNodeIds.contains(q.nodeId)) continue;
        if (!used.add(q.nodeId)) continue;
        slots.add(q);
      }
    }

    // ── Step 2: fill remaining slots with fresh picks ──────────────
    if (slots.length < slotCount) {
      // Tier 1: chapter side quest. Skip any node already locked in
      // via today's offering (above) so it doesn't double-fire a
      // planned offering event.
      takeFresh(_pickPinnedFresh(pinPool, nodesCompletedTodayIds, used));

      // Tier 2: active combo chain step.
      if (slots.length < slotCount) {
        takeFresh(_pickActiveChainStep(chainPool, nodesCompletedTodayIds));
      }

      // Tier 3: hash-rotation pool. Cooldown filter excludes daily
      // challenges (and hypothetical hash-pool entries) offered in
      // the last [offeredCooldownDays] days. Pinned chapter side
      // quests + chain steps deliberately bypass this — their own
      // gating handles rotation.
      if (slots.length < slotCount) {
        final remaining = slotCount - slots.length;
        final filteredHash = [
          for (final q in hashPool)
            if (!cooldownNodeIds.contains(q.nodeId)) q,
        ];
        final filteredChallenge = _pickChallengeFresh(
          challengePool,
          now,
          cooldownNodeIds,
        );
        final rotation = [...filteredHash, ...filteredChallenge];
        for (final q in _hashPick(rotation, now, count: remaining)) {
          takeFresh(q);
        }
      }
    }

    // Sanity guard: should never happen, but if a node id resolved to
    // a slot that no longer exists in the catalog (catalog drift mid-
    // refactor), drop the stale entry before returning.
    final filtered = [
      for (final s in slots) if (byNodeId.containsKey(s.nodeId)) s,
    ];

    return DailySectionResolution(
      slots: filtered,
      plannedOfferings: plannedOfferings,
    );
  }

  QuestOfferedEvent _offering(String nodeId, DateTime now, String dayKey) =>
      QuestOfferedEvent(
        eventKey: 'offered|$nodeId|$dayKey',
        timestamp: now,
        nodeId: nodeId,
        dayKey: dayKey,
      );

  // ── Tier 1: Fresh-pick chapter side quest ─────────────────────────
  //
  // Returns the first eligible un-claimed side quest. The
  // "claimed today sticky" rule from before is no longer needed
  // here — today's QuestOfferedEvent (read in Step 1 above) pins the
  // slot regardless of completion state. We only fall through to
  // this branch when no offering covers today yet.
  EngineQuestProgress? _pickPinnedFresh(
    List<EngineQuestProgress> pool,
    Set<String> nodesCompletedTodayIds,
    Set<String> alreadyUsed,
  ) {
    if (pool.isEmpty) return null;
    for (final q in pool) {
      if (alreadyUsed.contains(q.nodeId)) continue;
      if (q.isCompleted) continue;
      if (q.levelGate != null) continue;
      if (q.prereqGateNodeId != null) continue;
      // Same-day cooldown check — the engine derives a
      // NodeCompletedBeforeToday gate from `gatePolicy +
      // prerequisiteNodeIds`. We re-check here so a side quest whose
      // gating chapter step was just claimed today doesn't pop into
      // the slot as immediately-locked.
      if (_isGatedByCompletionToday(q, nodesCompletedTodayIds)) continue;
      return q;
    }
    return null;
  }

  // ── Tier 2: Active chain step (combo) ─────────────────────────────
  //
  // Walks each chain by `chainOrder`. The active slot is the first
  // step that's neither completed nor blocked by an unmet gate
  // (level / prereq / cross-chain). If the next step's gate is the
  // *same-day cooldown* the player just triggered (their last claim
  // is in `nodesCompletedTodayIds`), surface the prior completed
  // step as a placeholder so the slot reads as "done for today"
  // instead of jumping to the next chain.
  EngineQuestProgress? _pickActiveChainStep(
    List<EngineQuestProgress> pool,
    Set<String> nodesCompletedTodayIds,
  ) {
    if (pool.isEmpty) return null;

    final byChain = <String, List<EngineQuestProgress>>{};
    for (final q in pool) {
      final chainId = q.node.chainId;
      if (chainId == null) continue;
      byChain.putIfAbsent(chainId, () => []).add(q);
    }
    if (byChain.isEmpty) return null;

    final picks = <EngineQuestProgress>[];
    for (final chain in byChain.values) {
      final ordered = [...chain]..sort((a, b) =>
          (a.node.chainOrder ?? 0).compareTo(b.node.chainOrder ?? 0));

      EngineQuestProgress? lastCompleted;
      EngineQuestProgress? firstUncompleted;
      for (final q in ordered) {
        if (q.isCompleted) {
          lastCompleted = q;
        } else {
          firstUncompleted = q;
          break;
        }
      }
      if (firstUncompleted == null) {
        if (lastCompleted != null &&
            nodesCompletedTodayIds.contains(lastCompleted.nodeId)) {
          picks.add(lastCompleted);
        }
        continue;
      }
      if (firstUncompleted.levelGate != null) continue;
      if (firstUncompleted.prereqGateNodeId != null) continue;

      final gatedByToday = _isGatedByCompletionToday(
        firstUncompleted,
        nodesCompletedTodayIds,
      );
      if (gatedByToday) {
        if (lastCompleted != null) picks.add(lastCompleted);
        continue;
      }
      picks.add(firstUncompleted);
    }
    if (picks.isEmpty) return null;
    picks.sort((a, b) => a.node.sortOrder.compareTo(b.node.sortOrder));
    return picks.first;
  }

  bool _isGatedByCompletionToday(
    EngineQuestProgress quest,
    Set<String> nodesCompletedTodayIds,
  ) {
    final node = quest.node;
    if (node.gatePolicy is! CooldownDays) return false;
    for (final pid in node.prerequisiteNodeIds) {
      if (nodesCompletedTodayIds.contains(pid)) return true;
    }
    return false;
  }

  // ── Tier 3: Hash rotation (daily challenge) ───────────────────────

  /// Daily-challenge fresh pick. Cooldown filter removes any
  /// challenge offered in the last [offeredCooldownDays] days. The
  /// "completed today sticky" rule from before is gone — today's
  /// QuestOfferedEvent already pins the slot in Step 1.
  List<EngineQuestProgress> _pickChallengeFresh(
    List<EngineQuestProgress> pool,
    DateTime now,
    Set<String> cooldownNodeIds,
  ) {
    if (pool.isEmpty) return const [];
    final eligible = [
      for (final q in pool) if (!cooldownNodeIds.contains(q.nodeId)) q,
    ];
    if (eligible.isEmpty) return const [];
    final score = _fnvHash(_dateKey(now));
    return [eligible[score % eligible.length]];
  }

  /// Deterministic top-N pick. Sort by FNV-1a hash of (date | id) so
  /// the same N show up all day, then break ties by id for stable
  /// ordering. Matches the V1 selection algorithm.
  List<EngineQuestProgress> _hashPick(
    List<EngineQuestProgress> all,
    DateTime now, {
    required int count,
  }) {
    if (count <= 0 || all.isEmpty) return const [];
    if (all.length <= count) return all;
    final dayKey = _dateKey(now);
    final ranked = [...all]..sort((a, b) {
        final byScore = _fnvHash('$dayKey|${a.nodeId}')
            .compareTo(_fnvHash('$dayKey|${b.nodeId}'));
        if (byScore != 0) return byScore;
        return a.nodeId.compareTo(b.nodeId);
      });
    return ranked.take(count).toList(growable: false);
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  int _fnvHash(String s) {
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
