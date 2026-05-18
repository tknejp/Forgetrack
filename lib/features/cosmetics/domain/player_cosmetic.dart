import 'package:meta/meta.dart';

import 'ids.dart';
import 'player_cosmetic_lifecycle.dart';

/// Per-player projection of one [Cosmetic] catalog row at a specific
/// evaluation point. Bundles a typed [CosmeticId] reference to the
/// catalog row with the player-side [lifecycle] state and the
/// timestamp the projection was built.
///
/// **Catalog reference is by id, not by direct pointer.** Phase 10
/// keeps the same QuestId / AchievementId deferral pattern Phase 7 / 8
/// established: the proposal (`docs/domain_model/proposal.md` §2.4)
/// names this `PlayerCosmetic { Cosmetic cosmetic; ...}`, but holding
/// the full catalog reference here would force a churn whenever the
/// catalog row's fields change. The lifecycle projection is decoupled
/// from chrome on purpose — screens that need both pair `PlayerCosmetic`
/// (lifecycle) with `CosmeticCatalog.byId(id)` (chrome).
///
/// **Immutability.** `const` ctor, value-based equals. [evaluatedAt]
/// participates in equality so consumers can detect stale snapshots
/// without a separate version field — same contract Phase 7 / 8 used.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.4 (PlayerCosmetic entity).
///   - `docs/domain_model/migration_plan.md` §Phase 10.
///   - ADR `player-cosmetic-lifecycle-projection` in
///     `docs/site/data/decisions.json`.
@immutable
class PlayerCosmetic {
  const PlayerCosmetic({
    required this.id,
    required this.lifecycle,
    required this.evaluatedAt,
  });

  /// Stable catalog id of the underlying Cosmetic.
  final CosmeticId id;

  /// Discriminator + payload for the player-side state. The 4 sealed
  /// subtypes (Hidden / Teased / Claimable / Owned) carry the
  /// rendering payload the grid card + detail sheet need — see
  /// `lib/features/cosmetics/domain/player_cosmetic_lifecycle.dart`.
  final PlayerCosmeticLifecycle lifecycle;

  /// Monotonic timestamp at which the lifecycle projection was built.
  final DateTime evaluatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerCosmetic &&
        other.id == id &&
        other.lifecycle == lifecycle &&
        other.evaluatedAt == evaluatedAt;
  }

  @override
  int get hashCode => Object.hash(id, lifecycle, evaluatedAt);

  @override
  String toString() =>
      'PlayerCosmetic(id: $id, lifecycle: $lifecycle, evaluatedAt: $evaluatedAt)';
}
