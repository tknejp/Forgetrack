import 'package:forgetrack/domain/journal/journal_event.dart';
import 'ledger_snapshot.dart';

/// Persistence interface for the new engine. Phase 2 uses an
/// in-memory implementation under data/; Phase 4 swaps in an Isar
/// backing without changing this contract.
///
/// **R.4 (2026-05-19) — stays bare (no [Result] wrap).** Local
/// implementations (in-memory + Isar) never produce a meaningful
/// failure on the happy path: writes are append-only with deterministic
/// dedupe keys and reads return whatever is on disk. The only
/// failure-prone caller is [HybridProgressionEngineRepository], which
/// already classifies its Firestore push/pull through
/// `classifyFirebaseError` (see Phase 18 reference implementation —
/// `_pushSafely`, `_wipeSafely`, `pullEventsClassified`). Forcing the
/// contract into `Future<Result<T, AppError>>` would push a pattern-
/// match boilerplate onto every engine `evaluate()` tick for a failure
/// branch the local implementation cannot reach. The decision matches
/// proposal §4 anti-pattern guidance — `Result` is a boundary concept,
/// not a uniform wrapper.
abstract class ProgressionEngineRepository {
  Future<LedgerSnapshot> loadLedger();

  /// Append a batch of new events. Implementations must dedupe by
  /// [JournalEvent.eventKey] so re-running the engine with no real
  /// changes is a no-op at the repository layer.
  Future<LedgerSnapshot> appendEvents(List<JournalEvent> events);
}

/// Devtools-only extension. Only the local Isar-backed repo
/// implements this; the cloud-overlay repo throws.
abstract class ProgressionEngineLocalRepository
    implements ProgressionEngineRepository {
  Future<void> wipeAll();

  /// Devtools-only: removes every node-keyed event (claim,
  /// completion, announcement, reward grant) for [nodeId] from the
  /// local ledger. Used to reset a single node's state in the
  /// companion-state matrix without nuking the entire ledger via
  /// [wipeAll]. Production code never calls this — the engine has no
  /// "unclaim" primitive in normal flows.
  ///
  /// Cloud mirror is intentionally NOT touched here — the local
  /// clear is enough for the next engine evaluation to surface the
  /// node correctly in `availability`. A subsequent cloud
  /// pull-and-merge will re-introduce the cleared events; that's the
  /// separate "auto-claim on refresh" symptom on Trello #92 (needs
  /// its own architectural fix, options A/B/C/D on the card).
  Future<void> clearEventsForNode(String nodeId);
}
