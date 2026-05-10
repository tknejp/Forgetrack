import '../domain/models/ledger_event.dart';
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
  final List<RewardGrantEvent> _rewardGrants = [];
  final Set<String> _seenKeys = {};

  @override
  Future<LedgerSnapshot> loadLedger() async => _snapshot();

  @override
  Future<LedgerSnapshot> appendEvents(List<LedgerEvent> events) async {
    for (final e in events) {
      if (!_seenKeys.add(e.eventKey)) continue;
      switch (e) {
        case ObjectiveCompletionEvent():
          _objectiveCompletions.add(e);
        case NodeCompletionEvent():
          _nodeCompletions.add(e);
        case NodeClaimEvent():
          _nodeClaims.add(e);
        case RewardGrantEvent():
          _rewardGrants.add(e);
      }
    }
    return _snapshot();
  }

  @override
  Future<void> wipeAll() async {
    _objectiveCompletions.clear();
    _nodeCompletions.clear();
    _nodeClaims.clear();
    _rewardGrants.clear();
    _seenKeys.clear();
  }

  LedgerSnapshot _snapshot() => LedgerSnapshot(
        objectiveCompletions: List.unmodifiable(_objectiveCompletions),
        nodeCompletions: List.unmodifiable(_nodeCompletions),
        nodeClaims: List.unmodifiable(_nodeClaims),
        rewardGrants: List.unmodifiable(_rewardGrants),
      );
}
