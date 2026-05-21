import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import 'package:forgetrack/domain/progression/catalog/quest_policies.dart';
import '../domain/repository/ledger_snapshot.dart';
import 'progression_engine_provider.dart' show EngineQuestProgress;

/// Output of [WeeklySectionResolver.resolve]. Mirrors
/// `DailySectionResolution` — pure result + the offering events the
/// caller should persist so subsequent runs find the slot already
/// pinned.
class WeeklySectionResolution {
  const WeeklySectionResolution({
    required this.slots,
    required this.plannedOfferings,
  });

  /// Quest progress entries surfaced in the "TÝDENNÍ" section, in
  /// display order.
  final List<EngineQuestProgress> slots;

  /// `QuestOfferedEvent`s the resolver decided to record for this
  /// ISO week. `dayKey` is the week's Monday (`yyyy-MM-dd`); the
  /// daily resolver ignores these because the weekly bucket isn't in
  /// its input pool, and `dayKey == todayKey` matches against the
  /// daily key shape only.
  final List<QuestOfferedEvent> plannedOfferings;
}

/// Picks the (small) subset of weekly-bucket quests that surface in
/// the quests-tab "TÝDENNÍ" section.
///
/// Rotation rule (mirrors the daily-section pattern): once a quest
/// is offered on a given ISO-week-Monday, the slot stays locked to
/// that quest until the next Monday rolls in. Completion + claim
/// flip the visible pill state but do NOT free the slot — `DOKONČENÉ`
/// keeps the claimed card visible until the period key changes.
///
/// Only `Persistent`-slot-policy quests in [QuestDisplayBucket.weekly]
/// participate; weekly quests with bespoke slot policies (none today,
/// reserved for future evergreen weeklies) are passed through
/// unchanged.
class WeeklySectionResolver {
  const WeeklySectionResolver({this.slotCount = 1});

  /// How many weekly quests the rotation surfaces per ISO week.
  /// Defaults to 1 — the player sees exactly one weekly objective
  /// at a time, picked deterministically from the catalog pool.
  final int slotCount;

  WeeklySectionResolution resolve({
    required Iterable<EngineQuestProgress> quests,
    required LedgerSnapshot? ledger,
    required DateTime now,
  }) {
    final weekKey = _weekKey(now);
    final thisWeekOfferedNodeIds = <String>{};

    if (ledger != null) {
      for (final e in ledger.questOfferings) {
        if (e.dayKey == weekKey) thisWeekOfferedNodeIds.add(e.nodeId);
      }
    }

    final pool = <EngineQuestProgress>[];
    final passthrough = <EngineQuestProgress>[];
    for (final q in quests) {
      if (q.node.displayBucket != QuestDisplayBucket.weekly) continue;
      if (q.node.slotPolicy is! Persistent) {
        // Future-proofing: a weekly with a non-Persistent policy opts
        // out of the rotation and renders unconditionally.
        passthrough.add(q);
        continue;
      }
      if (q.isLockedByConditions) continue;
      pool.add(q);
    }

    final slots = <EngineQuestProgress>[];
    final planned = <QuestOfferedEvent>[];
    final used = <String>{};

    // Step 1: honour offerings already recorded for this week. Sort
    // the pool by id so the existing-offering walk matches the
    // deterministic order a fresh pick would produce — keeps display
    // order stable regardless of ledger insertion order.
    final byNodeId = <String, EngineQuestProgress>{
      for (final q in pool) q.nodeId: q,
    };
    final sortedIds = thisWeekOfferedNodeIds.toList()..sort();
    for (final nodeId in sortedIds) {
      if (slots.length >= slotCount) break;
      final q = byNodeId[nodeId];
      if (q == null) continue;
      if (!used.add(nodeId)) continue;
      slots.add(q);
    }

    // Step 2: fresh hash-pick for any unfilled slots. FNV-1a of
    // `weekKey | nodeId` ranks the pool; the lowest-scored N take
    // the slots. Tie-break by id for stability.
    if (slots.length < slotCount && pool.isNotEmpty) {
      final remaining = slotCount - slots.length;
      final candidates = [
        for (final q in pool) if (!used.contains(q.nodeId)) q,
      ];
      candidates.sort((a, b) {
        final byScore = _fnvHash('$weekKey|${a.nodeId}')
            .compareTo(_fnvHash('$weekKey|${b.nodeId}'));
        if (byScore != 0) return byScore;
        return a.nodeId.compareTo(b.nodeId);
      });
      for (final q in candidates.take(remaining)) {
        slots.add(q);
        used.add(q.nodeId);
        planned.add(QuestOfferedEvent(
          eventKey: 'offered|${q.nodeId}|$weekKey',
          timestamp: now,
          nodeId: q.nodeId,
          dayKey: weekKey,
        ));
      }
    }

    return WeeklySectionResolution(
      slots: [...slots, ...passthrough],
      plannedOfferings: planned,
    );
  }

  /// `yyyy-MM-dd` of the ISO-week Monday containing [now]. The same
  /// string the engine evaluator embeds in weekly periodKeys
  /// (`w-<this string>`), so a weekly objective's completion and the
  /// week's offering line up on the same anchor date.
  String _weekKey(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }

  int _fnvHash(String s) {
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
