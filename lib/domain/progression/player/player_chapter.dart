import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import 'chapter_lifecycle.dart';

/// Per-player projection of one Chapter catalog row at a specific
/// evaluation point. Bundles a typed [ChapterId] reference to the
/// chapter wrapper with the player-side [lifecycle] state and the
/// timestamp the projection was built.
///
/// **Catalog reference is by id, not by direct pointer.** Phase 13
/// follows the same QuestId / AchievementId deferral pattern Phase 7
/// / 8 / 10 established: the proposal (`docs/domain_model/proposal.md`
/// §2.4) names this `PlayerChapter { Chapter chapter; ... }`, but
/// holding the full catalog reference would couple the lifecycle
/// projection to chrome (chain ordering, side-quest list, finale
/// emblem id). The lifecycle projection is decoupled on purpose —
/// screens that need both pair `PlayerChapter` (lifecycle) with
/// `ChapterCatalog.byId(id)` (chain shape) when they need both.
///
/// **Immutability.** `const` ctor, value-based equals. [evaluatedAt]
/// participates in equality so consumers can detect stale snapshots
/// without a separate version field — same contract Phase 7 / 8 / 10
/// established.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.4 (PlayerChapter entity).
///   - `docs/domain_model/migration_plan.md` §Phase 13.
///   - ADR `player-chapter-progress-projection` in
///     `docs/site/data/decisions.json`.
@immutable
class PlayerChapter {
  const PlayerChapter({
    required this.id,
    required this.lifecycle,
    required this.evaluatedAt,
  });

  /// Stable catalog id of the underlying Chapter wrapper.
  final ChapterId id;

  /// Discriminator + payload for the player-side state. The 4 sealed
  /// subtypes (Locked / UnlockedNotStarted / InProgress / Completed)
  /// carry the rendering payload the chapter card + journey map need
  /// — see `lib/domain/progression/player/chapter_lifecycle.dart`.
  final ChapterLifecycle lifecycle;

  /// Monotonic timestamp at which the lifecycle projection was built.
  /// Equal to `ProgressionEngineProvider.lastEvaluatedAt` for
  /// projections built inside an eval pass.
  final DateTime evaluatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerChapter &&
        other.id == id &&
        other.lifecycle == lifecycle &&
        other.evaluatedAt == evaluatedAt;
  }

  @override
  int get hashCode => Object.hash(id, lifecycle, evaluatedAt);

  @override
  String toString() =>
      'PlayerChapter(id: $id, lifecycle: $lifecycle, evaluatedAt: $evaluatedAt)';
}
