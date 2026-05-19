import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import 'player_achievement_lifecycle.dart';

/// Per-player projection of one Achievement catalog row at a specific
/// evaluation point. Bundles the catalog reference (by id) with the
/// player-side [lifecycle] state and the timestamp the projection
/// was built.
///
/// **Phase 8 mirror of [PlayerQuest].** Same QuestId-keyed deferral
/// pattern: the proposal (`docs/domain_model/proposal.md` §2.4) names
/// this `PlayerAchievement { Achievement achievement; ...}`, but
/// [Achievement] still lives in `lib/features/progression_engine/` and
/// the domain layer cannot import features. [PlayerAchievement] holds
/// a typed [AchievementId] reference; consumers needing the catalog
/// row chrome (title / asset / rewards) resolve via
/// `ProgressionEntryCatalog.definitionForId(id.value)`. When the
/// Achievement type moves into `lib/domain/progression/catalog/` (a
/// later phase), this class will extend to carry the full reference.
///
/// **Immutability.** `const` ctor, value-based equals. [evaluatedAt]
/// participates in equality so consumers can detect stale snapshots
/// without a separate version field — same contract [PlayerQuest]
/// uses in Phase 7.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.4 (PlayerAchievement entity).
///   - `docs/domain_model/migration_plan.md` §Phase 8.
///   - ADR `player-achievement-shelf-projection` in
///     `docs/site/data/decisions.json`.
@immutable
class PlayerAchievement {
  const PlayerAchievement({
    required this.id,
    required this.lifecycle,
    required this.evaluatedAt,
  });

  /// Stable catalog id of the underlying Achievement. Application /
  /// presentation consumers resolve the catalog row via the
  /// progression entry catalog when they need chrome (title / asset /
  /// reward chips).
  final AchievementId id;

  /// Discriminator + payload for the player-side state. The 3 sealed
  /// subtypes (Locked / InProgress / Unlocked) carry the rendering
  /// payload the grid card + detail sheet need — see
  /// `lib/domain/progression/player/player_achievement_lifecycle.dart`.
  final PlayerAchievementLifecycle lifecycle;

  /// Monotonic timestamp at which the engine built this projection.
  /// Equal to `ProgressionEngineProvider.lastEvaluatedAt` for
  /// projections built inside an eval pass.
  final DateTime evaluatedAt;

  PlayerAchievement copyWith({
    AchievementId? id,
    PlayerAchievementLifecycle? lifecycle,
    DateTime? evaluatedAt,
  }) {
    return PlayerAchievement(
      id: id ?? this.id,
      lifecycle: lifecycle ?? this.lifecycle,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerAchievement &&
        other.id == id &&
        other.lifecycle == lifecycle &&
        other.evaluatedAt == evaluatedAt;
  }

  @override
  int get hashCode => Object.hash(id, lifecycle, evaluatedAt);

  @override
  String toString() =>
      'PlayerAchievement(id: $id, lifecycle: $lifecycle, evaluatedAt: $evaluatedAt)';
}
