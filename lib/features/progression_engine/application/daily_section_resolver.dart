import '../domain/models/quest_policies.dart';
import '../domain/repository/ledger_snapshot.dart';
import 'progression_engine_provider.dart' show EngineQuestProgress;

/// Picks the questy that appear in the daily section.
///
/// The provider used to spread this across three getters
/// (`currentDailyQuests`, `currentComboQuests`,
/// `currentChapterSideQuests`) plus an ad-hoc "claimed today"
/// timestamp scan and `_isStepGatedByCompletionToday`. Every flavour
/// of slot-persistence rule had its own bespoke implementation. The
/// resolver consolidates them by reading [SlotPolicy] off the
/// `QuestNode` subtype and dispatching once.
///
/// **Tier order** (defaults to the spec the player has been seeing):
/// 1. `PinClaimedTodayUntilMidnight` — one chapter side quest slot.
///    Prefers a side quest the player claimed today (it stays pinned
///    as "Splněno" until midnight); otherwise picks the first
///    eligible one.
/// 2. `ChainPlaceholderUntilMidnight` — one combo chain slot. Walks
///    each chain's steps in order; if the next step is gated by a
///    same-day cooldown the player just triggered, surfaces the
///    previously-completed step as a placeholder so the slot reads
///    "done for today" instead of going empty.
/// 3. `HashRotationStickyUntilMidnight` + `DailyChallengeHashPick` —
///    the remaining slots are picked by a deterministic FNV-1a hash
///    over the local date, so a given quest stays in its slot all
///    day (claimed cards flip state, they don't rotate out).
///
/// Quests with `Persistent`, `ChapterCardSticky`, or
/// `HiddenFromSections` slot policies never appear here — they have
/// their own surfaces (long-term / chapter / hidden).
class DailySectionResolver {
  const DailySectionResolver({this.slotCount = 2});

  /// How many slots the daily section surfaces. V1 parity: 2.
  final int slotCount;

  List<EngineQuestProgress> resolve({
    required Iterable<EngineQuestProgress> quests,
    required LedgerSnapshot? ledger,
    required DateTime now,
    required Set<String> nodesCompletedTodayIds,
  }) {
    final pinPool = <EngineQuestProgress>[];
    final chainPool = <EngineQuestProgress>[];
    final hashPool = <EngineQuestProgress>[];
    final challengePool = <EngineQuestProgress>[];

    for (final q in quests) {
      switch (q.node.slotPolicy) {
        case PinClaimedTodayUntilMidnight():
          // Drop side quests for finished chapters (`ChapterActive`
          // false → engine resolved to `locked`). Without this guard
          // a retired side quest with a stale `TodayCompletionsAmong`
          // outcome leaks into DENNÍ ÚKOLY as a 2/2 card the player
          // can never claim.
          if (q.isLockedByConditions) continue;
          pinPool.add(q);
        case ChainPlaceholderUntilMidnight():
          // Combo steps locked *today only* by `CooldownDays(1)` (the
          // engine derives `NodeCompletedBeforeToday(prereq)` from
          // the gate) MUST stay in the pool. The chain walker needs
          // to see them to recognise the same-day cooldown and pin
          // the previously-claimed step as "Splněno"; filter them
          // out and `firstUncompleted` collapses to null → the chain
          // vanishes the moment a step is claimed.
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
          // These render elsewhere.
          break;
      }
    }

    final slots = <EngineQuestProgress>[];
    final used = <String>{};

    void take(EngineQuestProgress? q) {
      if (q == null) return;
      if (slots.length >= slotCount) return;
      if (!used.add(q.nodeId)) return;
      slots.add(q);
    }

    take(_pickPinned(pinPool, ledger, now, nodesCompletedTodayIds));
    take(_pickActiveChainStep(chainPool, nodesCompletedTodayIds));

    if (slots.length < slotCount) {
      final rotation = [
        ...hashPool,
        ..._pickChallenge(challengePool, now, nodesCompletedTodayIds),
      ];
      for (final q in _hashPick(
        rotation,
        now,
        count: slotCount - slots.length,
      )) {
        take(q);
      }
    }
    return slots;
  }

  // ── Tier 1: Pin-claimed-today (chapter side quest) ────────────────
  //
  // A side quest claimed today stays pinned to the surprise slot until
  // midnight, mirroring how daily-quest hash picks stay in place after
  // a claim. If no side quest is claimed today, fall back to the first
  // eligible (un-claimed, surfaced-by-engine) one — that's the
  // "discover a new bonus" affordance.
  EngineQuestProgress? _pickPinned(
    List<EngineQuestProgress> pool,
    LedgerSnapshot? ledger,
    DateTime now,
    Set<String> nodesCompletedTodayIds,
  ) {
    if (pool.isEmpty) return null;
    for (final q in pool) {
      if (!q.isCompleted) continue;
      if (_wasClaimedOnDate(ledger, q.nodeId, now)) return q;
    }
    for (final q in pool) {
      if (q.isCompleted) continue;
      if (q.levelGate != null) continue;
      if (q.prereqGateNodeId != null) continue;
      // Cooldown-gated candidates (e.g. a side quest whose gating
      // chapter step was just claimed today) read as "ungated" via
      // the EngineQuestProgress flags above — `levelGate` /
      // `prereqGateNodeId` are null because the prereq node has a
      // completion event. The actual gate (`NodeCompletedBeforeToday`)
      // is derived by the engine from `gatePolicy + prerequisiteNodeIds`,
      // so we re-check it here to avoid surfacing a quest the
      // resolver knows is locked-for-today. Without this guard the
      // side-quest slot would jump to a locked card the moment the
      // player claims the chapter step that gates it.
      if (_isGatedByCompletionToday(q, nodesCompletedTodayIds)) continue;
      return q;
    }
    return null;
  }

  bool _wasClaimedOnDate(
    LedgerSnapshot? ledger,
    String nodeId,
    DateTime now,
  ) {
    if (ledger == null) return false;
    for (final e in ledger.nodeClaims) {
      if (e.nodeId != nodeId) continue;
      final t = e.timestamp.toLocal();
      if (t.year == now.year && t.month == now.month && t.day == now.day) {
        return true;
      }
    }
    return false;
  }

  // ── Tier 2: Active chain step (combo) ─────────────────────────────
  //
  // Walks each chain by `chainOrder`. The active slot is the first
  // step that is neither completed nor blocked by an unmet gate
  // (level / prereq / cross-chain). If the next step's gate is the
  // *same-day cooldown* that the player just triggered (their last
  // claim is in `nodesCompletedTodayIds`), surface the prior
  // completed step as a placeholder so the slot reads as "done for
  // today" instead of jumping to the next chain.
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
      if (firstUncompleted == null) continue;
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

  /// True if the node carries a `NodeCompletedBeforeToday(targetId)`
  /// gate where `targetId` was completed earlier today — i.e. the
  /// gate clears only after midnight. The condition is derived from
  /// `gatePolicy + prerequisiteNodeIds` by the engine; we read it
  /// back off the QuestNode's prereqs + policy instead of scanning
  /// unlock conditions, so the rule lives in one place.
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

  // ── Tier 3: Hash rotation (daily + daily challenge) ───────────────

  /// Daily challenge pool — at most one quest per day. If a challenge
  /// was already claimed today, keep showing it; otherwise pick a
  /// deterministic one from the un-finished templates.
  List<EngineQuestProgress> _pickChallenge(
    List<EngineQuestProgress> pool,
    DateTime now,
    Set<String> nodesCompletedTodayIds,
  ) {
    if (pool.isEmpty) return const [];
    for (final q in pool) {
      if (nodesCompletedTodayIds.contains(q.nodeId)) return [q];
    }
    final unfinished = [for (final q in pool) if (!q.isCompleted) q];
    if (unfinished.isEmpty) return const [];
    final score = _fnvHash(_dateKey(now));
    return [unfinished[score % unfinished.length]];
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
