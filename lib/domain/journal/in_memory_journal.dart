import '../progression/catalog/ids.dart';
import 'journal.dart';
import 'journal_event.dart';

/// Minimal in-memory [Journal] adapter.
///
/// Phase 16 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 16) plumbs a [Journal] handle through the engine's
/// `evaluate()` signature. The engine itself still reads its ledger
/// via `ProgressionEngineRepository.loadLedger()` (Phase 20 will
/// switch over once `JournalProjection` lands), so this adapter
/// exists so the public arg can be satisfied:
///   - `ProgressionEngineProvider` wraps the loaded ledger events
///     (which it already has) into an [InMemoryJournal] before
///     calling `evaluate(...)`.
///   - Tests construct an [InMemoryJournal.empty()] or with a hand-
///     rolled event list.
///
/// Pure-Dart, no persistence: implementations that need indexed
/// queries (Firestore-backed, Isar-backed) live in `data/`.
class InMemoryJournal implements Journal {
  const InMemoryJournal(this._events);

  factory InMemoryJournal.empty() => const InMemoryJournal(<JournalEvent>[]);

  final List<JournalEvent> _events;

  @override
  Iterable<JournalEvent> get events => _events;

  @override
  Iterable<JournalEvent> eventsForNode(ProgressionEntryId id) {
    return _events.where((event) {
      return switch (event) {
        NodeCompletionEvent(:final nodeId) => nodeId == id.raw,
        NodeAnnouncedEvent(:final nodeId) => nodeId == id.raw,
        NodeClaimEvent(:final nodeId) => nodeId == id.raw,
        RewardGrantEvent(:final nodeId) => nodeId == id.raw,
        QuestOfferedEvent(:final nodeId) => nodeId == id.raw,
        ObjectiveCompletionEvent() => false,
      };
    });
  }

  @override
  Iterable<JournalEvent> eventsForObjective(ObjectiveId id) {
    return _events.where((event) {
      return switch (event) {
        ObjectiveCompletionEvent(:final objectiveId) => objectiveId == id.raw,
        _ => false,
      };
    });
  }

  @override
  Iterable<JournalEvent> eventsInRange(DateTime from, DateTime to) {
    return _events.where((event) =>
        !event.timestamp.isBefore(from) && event.timestamp.isBefore(to));
  }
}
