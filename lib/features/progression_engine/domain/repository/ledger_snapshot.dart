import 'package:meta/meta.dart';

import 'package:forgetrack/domain/journal/journal_event.dart';

/// Immutable view of the engine's ledger at one point in time.
///
/// The repository hands one of these to the engine on every load /
/// sync. Indexed lookups (by event key, by node id) are computed
/// lazily — Phase 2 keeps it as plain lists since the in-memory
/// repository is small; the Isar-backed repo (Phase 4) will preload
/// indexed maps inside this snapshot if profiling shows we need it.
@immutable
class LedgerSnapshot {
  const LedgerSnapshot({
    this.objectiveCompletions = const [],
    this.nodeCompletions = const [],
    this.nodeClaims = const [],
    this.nodeAnnouncements = const [],
    this.rewardGrants = const [],
    this.questOfferings = const [],
  });

  final List<ObjectiveCompletionEvent> objectiveCompletions;
  final List<NodeCompletionEvent> nodeCompletions;
  final List<NodeClaimEvent> nodeClaims;
  final List<NodeAnnouncedEvent> nodeAnnouncements;
  final List<RewardGrantEvent> rewardGrants;
  final List<QuestOfferedEvent> questOfferings;

  bool hasEventKey(String key) {
    for (final e in objectiveCompletions) {
      if (e.eventKey == key) return true;
    }
    for (final e in nodeCompletions) {
      if (e.eventKey == key) return true;
    }
    for (final e in nodeClaims) {
      if (e.eventKey == key) return true;
    }
    for (final e in nodeAnnouncements) {
      if (e.eventKey == key) return true;
    }
    for (final e in rewardGrants) {
      if (e.eventKey == key) return true;
    }
    for (final e in questOfferings) {
      if (e.eventKey == key) return true;
    }
    return false;
  }

  Iterable<JournalEvent> get all sync* {
    yield* objectiveCompletions;
    yield* nodeCompletions;
    yield* nodeClaims;
    yield* nodeAnnouncements;
    yield* rewardGrants;
    yield* questOfferings;
  }
}
