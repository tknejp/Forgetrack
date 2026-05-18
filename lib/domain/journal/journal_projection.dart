import 'journal_event.dart';

/// Why a cache rebuild from the journal is being requested.
///
/// Cache rebuild paths are intentionally rare in this codebase — the
/// hot path is incremental update via the canonical pipelines
/// (`engine.evaluate()` → `CosmeticUnlockBridge.dispatch`,
/// `SocialProvider._syncProfileIfNeeded` after signature change).
/// Bulk replay from the journal is reserved for these scenarios:
///
/// * [factoryReset] — fresh install or "wipe local ledger" devtool.
///   Local caches are empty; journal events recreate them from
///   scratch.
/// * [pullAndMerge] — second device / re-install: the engine pulled a
///   merged ledger from Firestore and now needs every cache that
///   denormalises journal state to catch up before the next render.
/// * [devToolsWipe] — devtools "rebuild cache" affordance triggered
///   manually without resetting the journal.
/// * [periodicResync] — future opportunistic reconciliation (not
///   wired yet); reserved so projection implementations don't have
///   to grow a new enum case the first time we add one.
///
/// Implementations may use the reason for logging or to skip
/// expensive validations on the trusted-source [factoryReset] path.
enum RebuildFromJournalReason {
  factoryReset,
  pullAndMerge,
  devToolsWipe,
  periodicResync,
}

/// Contract for a denormalised cache that can be rebuilt from the
/// player's journal.
///
/// The codebase has two such caches today (Phase 20 of the domain
/// refactor — `docs/domain_model/migration_plan.md` §Phase 20):
///
/// 1. **Cosmetics inventory** — `CosmeticUnlockBridge` replays
///    [RewardGrantEvent]s to repopulate the cosmetics inventory after
///    a cloud pull or factory reset.
/// 2. **Social profile snapshot** — `SocialProfileProjection`
///    rebuilds the Firestore `SocialUserProfile` row from Player +
///    Journal so friends' tabs render fast without paying the full
///    ledger read cost.
///
/// **Why an interface.** Before Phase 20 these two cache-rebuild
/// paths were ad-hoc methods on disparate classes with no shared
/// contract. Promoting them to [JournalProjection] makes the rebuild
/// triggers explicit (every implementation accepts a typed
/// [RebuildFromJournalReason]), groups them in a single grep, and
/// gives future caches a documented landing pattern.
///
/// **Idempotency.** Every implementation MUST be idempotent — calling
/// [rebuildFromJournal] twice with the same events produces the same
/// cache state. This is what lets the engine call the cosmetic
/// projection after every pull-and-merge without worrying about
/// double-unlocks, and lets devtools "rebuild cache" affordances be
/// retried freely.
///
/// **Append semantics live elsewhere.** Projections are read-side
/// only — they consume [JournalEvent]s and update their cache. They
/// never append to the journal. Mutations flow through the usual
/// repository write paths.
///
/// **Type parameter [T].** Whatever the rebuild produces. The
/// cosmetic projection returns the number of unlocks applied (useful
/// for logging + tests); the social profile projection returns the
/// payload it pushed (or null when there's nothing to publish).
abstract class JournalProjection<T> {
  /// Rebuild this projection's cache from [events].
  ///
  /// [events] is the full event stream the projection should consider
  /// (typically `ledger.all` or `journal.events`). Implementations
  /// filter by event subtype as needed.
  ///
  /// [reason] is the trigger that prompted the rebuild — see
  /// [RebuildFromJournalReason] for the catalogue.
  ///
  /// Must be idempotent: same inputs → same cache state.
  Future<T> rebuildFromJournal({
    required Iterable<JournalEvent> events,
    required RebuildFromJournalReason reason,
  });
}
