import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import 'player_quest_lifecycle.dart';

/// Per-player snapshot of one Quest catalog row.
///
/// Phase 7 of the domain refactor introduces this value class as the
/// projection unit inside [PlayerQuestCatalog]. It binds three pieces:
///
///   - [id]: typed quest identifier; matches the Quest catalog row's
///     id (upcast to [QuestId] at the service boundary).
///   - [lifecycle]: sealed discriminator carrying the Phase 6 four
///     states (Locked / Available / CompletedPendingClaim / Claimed).
///   - [evaluatedAt]: timestamp of the engine evaluation that produced
///     this snapshot. Useful for staleness checks and the Phase 7+
///     `completedAt` / `claimedAt` enrichment work.
///
/// **Why no Quest reference field.** The proposal (§2.4) names this
/// `PlayerQuest { Quest quest; PlayerQuestLifecycle lifecycle; … }`,
/// but [Quest] itself still lives in
/// `lib/features/progression_engine/domain/models/` and
/// `lib/domain/` cannot import features (architecture rule §3 — domain
/// purity guard). The narrower [QuestId] is the proposal-aligned
/// substitute today; application-layer consumers resolve the full
/// Quest catalog row via `ProgressionEntryCatalog.definitionForId(...)`.
/// The shape will fully match the proposal once the catalog rename
/// lands the Quest class in `lib/domain/progression/catalog/`.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.4 (PlayerQuest).
///   - `docs/domain_model/migration_plan.md` §Phase 7.
///   - ADR `player-quest-catalog-projection` in
///     `docs/site/data/decisions.json`.
@immutable
class PlayerQuest {
  const PlayerQuest({
    required this.id,
    required this.lifecycle,
    required this.evaluatedAt,
  });

  final QuestId id;
  final PlayerQuestLifecycle lifecycle;
  final DateTime evaluatedAt;

  PlayerQuest copyWith({
    QuestId? id,
    PlayerQuestLifecycle? lifecycle,
    DateTime? evaluatedAt,
  }) {
    return PlayerQuest(
      id: id ?? this.id,
      lifecycle: lifecycle ?? this.lifecycle,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerQuest &&
        other.id == id &&
        other.lifecycle == lifecycle &&
        other.evaluatedAt == evaluatedAt;
  }

  @override
  int get hashCode => Object.hash(id, lifecycle, evaluatedAt);

  @override
  String toString() =>
      'PlayerQuest(id: $id, lifecycle: $lifecycle, evaluatedAt: $evaluatedAt)';
}
