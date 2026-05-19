import 'package:forgetrack/domain/journal/journal_event.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';

/// In-memory ledger backing. Intended for tests, devtools demo runs,
/// and the engine's wiring before the Isar-backed repo lands in
/// Phase 4.
///
/// Append is idempotent at the eventKey level — re-appending an
/// event with a key that already exists is silently dropped, which
/// is the same contract the Isar repo will provide via unique
/// indexes.
class InMemoryProgressionEngineRepository
    implements ProgressionEngineLocalRepository {
  final List<ObjectiveCompletionEvent> _objectiveCompletions = [];
  final List<NodeCompletionEvent> _nodeCompletions = [];
  final List<NodeClaimEvent> _nodeClaims = [];
  final List<NodeAnnouncedEvent> _nodeAnnouncements = [];
  final List<RewardGrantEvent> _rewardGrants = [];
  final List<QuestOfferedEvent> _questOfferings = [];
  final Set<String> _seenKeys = {};

  @override
  Future<LedgerSnapshot> loadLedger() async => _snapshot();

  @override
  Future<LedgerSnapshot> appendEvents(List<JournalEvent> events) async {
    for (final e in events) {
      if (!_seenKeys.add(e.eventKey)) continue;
      switch (e) {
        case ObjectiveCompletionEvent():
          _objectiveCompletions.add(e);
        case NodeCompletionEvent():
          _nodeCompletions.add(e);
        case NodeClaimEvent():
          _nodeClaims.add(e);
        case NodeAnnouncedEvent():
          _nodeAnnouncements.add(e);
        case RewardGrantEvent():
          _rewardGrants.add(e);
        case QuestOfferedEvent():
          _questOfferings.add(e);
      }
    }
    return _snapshot();
  }

  @override
  Future<void> wipeAll() async {
    _objectiveCompletions.clear();
    _nodeCompletions.clear();
    _nodeClaims.clear();
    _nodeAnnouncements.clear();
    _rewardGrants.clear();
    _questOfferings.clear();
    _seenKeys.clear();
  }

  @override
  Future<void> clearEventsForNode(String nodeId) async {
    // Drop every node-keyed event for [nodeId]. Also evict their
    // event keys from `_seenKeys` so a later `appendEvents` with
    // the same keys is allowed through (mirrors the Isar side
    // where deleting the row releases the unique-eventKey index).
    void purge<T extends JournalEvent>(
      List<T> list,
      bool Function(T) match,
    ) {
      list.removeWhere((e) {
        if (!match(e)) return false;
        _seenKeys.remove(e.eventKey);
        return true;
      });
    }

    purge<NodeCompletionEvent>(_nodeCompletions, (e) => e.nodeId == nodeId);
    purge<NodeClaimEvent>(_nodeClaims, (e) => e.nodeId == nodeId);
    purge<NodeAnnouncedEvent>(_nodeAnnouncements, (e) => e.nodeId == nodeId);
    purge<RewardGrantEvent>(_rewardGrants, (e) => e.nodeId == nodeId);
    purge<QuestOfferedEvent>(_questOfferings, (e) => e.nodeId == nodeId);
  }

  LedgerSnapshot _snapshot() => LedgerSnapshot(
        objectiveCompletions: List.unmodifiable(_objectiveCompletions),
        nodeCompletions: List.unmodifiable(_nodeCompletions),
        nodeClaims: List.unmodifiable(_nodeClaims),
        nodeAnnouncements: List.unmodifiable(_nodeAnnouncements),
        rewardGrants: List.unmodifiable(_rewardGrants),
        questOfferings: List.unmodifiable(_questOfferings),
      );
}
