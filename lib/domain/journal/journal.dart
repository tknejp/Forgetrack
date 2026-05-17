import 'journal_event.dart';

/// Read-only view of the player's event-sourced history.
///
/// [Journal] is the domain-layer abstraction over the append-only
/// ledger that lives in Isar (local) and Firestore (cloud mirror).
/// The data layer's [ProgressionEngineRepository] implementations
/// expose a [Journal] facade so application-layer code (providers,
/// derivations, projections) reads through this interface instead of
/// reaching into repository-specific query methods.
///
/// **Append semantics live elsewhere.** This interface is intentionally
/// read-only: appending an event is a repository concern (idempotency
/// dedup, cloud push, transactional batching). UI / providers observe
/// the journal; they never write to it directly.
///
/// **Query API design** (per migration plan §Phase 2):
///   - [events] — full history, in insertion order. Cheap for small
///     ledgers; use a query method for large ones.
///   - [eventsForNode] — filter by progression entry id (matches any
///     event subtype that references the node).
///   - [eventsInRange] — filter by timestamp window. Inclusive [from],
///     exclusive [to] per the project's standard HC range convention.
///
/// Implementations are free to add indexed-query specialisations for
/// hot paths (e.g. `eventsByPeriodKey`); consumers should prefer the
/// generic methods unless a profiler indicates otherwise. See
/// docs/domain_model/migration_plan.md Phase 2 for the consumer
/// migration strategy.
abstract class Journal {
  /// All recorded events, in insertion (timestamp) order. Iterables
  /// are lazy so a 10k-event ledger doesn't materialise a 10k-element
  /// list on every read.
  Iterable<JournalEvent> get events;

  /// Events that reference [nodeId] in their primary node field.
  /// Matches: [NodeCompletionEvent], [NodeAnnouncedEvent],
  /// [NodeClaimEvent], [RewardGrantEvent], [QuestOfferedEvent].
  /// Does NOT match: [ObjectiveCompletionEvent] (keyed by objectiveId
  /// — use [eventsForObjective]).
  Iterable<JournalEvent> eventsForNode(String nodeId);

  /// Events that reference [objectiveId] in their primary objective
  /// field. Matches: [ObjectiveCompletionEvent].
  Iterable<JournalEvent> eventsForObjective(String objectiveId);

  /// Events whose [JournalEvent.timestamp] satisfies
  /// `from <= timestamp < to`. Inclusive lower bound, exclusive upper
  /// bound per the project's standard range convention.
  Iterable<JournalEvent> eventsInRange(DateTime from, DateTime to);
}
