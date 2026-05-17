import '../models/ledger_event.dart';
import 'ledger_snapshot.dart';

/// Persistence interface for the new engine. Phase 2 uses an
/// in-memory implementation under data/; Phase 4 swaps in an Isar
/// backing without changing this contract.
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
}
