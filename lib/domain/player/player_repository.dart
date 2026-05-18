import 'player.dart';

/// Domain interface for loading and observing the [Player] aggregate.
///
/// Phase 4 of the domain refactor introduces this interface but does
/// not yet ship a concrete implementation — Phase 4's [Player] is
/// fabricated by `PlayerProvider` from the existing `AuthProvider` and
/// `ProgressionEngineProvider`. A dedicated implementation (likely
/// composing the auth identity store with the Journal-derived
/// level/XP) lands in Phase 5 alongside the source-of-truth migration.
///
/// Per proposal §10 Q5, repository implementations live in
/// `lib/features/<f>/data/` and adapt to existing persistence; this
/// interface stays in `lib/domain/` so application-layer providers
/// program against the contract, not the adapter.
abstract class PlayerRepository {
  /// One-shot read for [uid]. Returns [Player.anonymous] when the uid
  /// is not yet known (e.g. signed-out state surfaced as a value
  /// rather than a missing record).
  Future<Player> load(String uid);

  /// Continuous stream of [Player] snapshots for [uid]. Implementations
  /// emit a fresh snapshot whenever any underlying source (auth
  /// identity, Journal-derived level/XP, settings surface) changes.
  Stream<Player> watch(String uid);
}
