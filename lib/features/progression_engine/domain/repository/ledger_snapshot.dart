import 'package:flutter/foundation.dart';

import '../models/ledger_event.dart';

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
    this.rewardGrants = const [],
  });

  final List<ObjectiveCompletionEvent> objectiveCompletions;
  final List<NodeCompletionEvent> nodeCompletions;
  final List<NodeClaimEvent> nodeClaims;
  final List<RewardGrantEvent> rewardGrants;

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
    for (final e in rewardGrants) {
      if (e.eventKey == key) return true;
    }
    return false;
  }

  Iterable<LedgerEvent> get all sync* {
    yield* objectiveCompletions;
    yield* nodeCompletions;
    yield* nodeClaims;
    yield* rewardGrants;
  }
}
