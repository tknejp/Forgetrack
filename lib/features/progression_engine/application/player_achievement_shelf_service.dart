import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_achievement.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_lifecycle.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_shelf.dart';

import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';

/// Builds [PlayerAchievementShelf] read projections from engine
/// primitives (catalog rows + completed/locked sets + objective
/// outcome lookups + XP scaling closure).
///
/// **Why primitive inputs instead of EngineAchievementView.** Phase 7
/// modelled `PlayerQuestCatalogService` taking `EngineQuestProgress`
/// directly because that view-model is a value class with no Flutter
/// dependencies. The achievement equivalent (`EngineAchievementView`)
/// carries `NodeDisplay` (localised title/description) which requires
/// `AppLocalizations` — a widget-bound dependency. The provider has
/// no access to `AppLocalizations`, so building a shelf via the view
/// model would force the shelf API into a presentation-tier surface.
///
/// Solution: the service takes pure-domain primitives — the same
/// engine state the view-model adapter would read, minus the
/// localised display strings. The shelf is lifecycle state, not
/// display data; the two concerns split cleanly here. Widget
/// consumers that need both can pair shelf entries (lifecycle) with
/// `EngineAchievementView` entries (chrome) by AchievementId.
///
/// **Phase 8 mirror of [PlayerQuestCatalogService].** Same statelessness
/// contract; same `const` ctor; same Phase 16+ retirement pathway (the
/// service goes away when the evaluator produces `PlayerAchievement`
/// directly).
class PlayerAchievementShelfService {
  const PlayerAchievementShelfService();

  /// Build a [PlayerAchievementShelf] from engine primitives.
  ///
  ///   - [achievements]: the catalog rows to project. Insertion order
  ///     is preserved.
  ///   - [completedNodeIds]: node ids with a `NodeCompletionEvent` in
  ///     the ledger. Backs the [AchievementUnlocked] branch.
  ///   - [lockedNodeIds]: node ids the resolver classified as
  ///     locked (unlock conditions failed). Backs the
  ///     [AchievementLocked] branch.
  ///   - [earliestCompletionAt]: closure returning the earliest ledger
  ///     completion timestamp for a node id, or null when not yet
  ///     completed. Stamped on [AchievementUnlocked.unlockedAt].
  ///   - [objectiveActual] / [objectiveTarget]: closures returning the
  ///     current / target value for an objective id. Drive the
  ///     [AchievementInProgress] payload. Pass `0.0` for unknown ids.
  ///   - [scaledRewardXp]: closure returning level-scaled XP for a
  ///     given catalog base XP. Stamped on [AchievementUnlocked.finalXp]
  ///     and tracks the player's current level so the displayed +
  ///     granted values stay aligned (same invariant Phase 6
  ///     documented for QuestClaimed).
  ///   - [evaluatedAt]: stamped on every projected entry.
  ///
  /// Precedence inside the lifecycle bridge:
  ///
  ///   - `completedNodeIds.contains(id)` wins (idempotent unlock,
  ///     achievements never re-lock).
  ///   - else `lockedNodeIds.contains(id)` → [AchievementLocked].
  ///   - else → [AchievementInProgress] with the objective's actual /
  ///     target.
  ///
  /// Duplicate ids in [achievements] are not expected — the catalog
  /// emits each row once. The defensive
  /// [PlayerAchievementShelf.fromEntries] last-wins semantics handle
  /// the edge case without throwing.
  PlayerAchievementShelf build({
    required Iterable<Achievement> achievements,
    required Set<String> completedNodeIds,
    required Set<String> lockedNodeIds,
    required DateTime? Function(String nodeId) earliestCompletionAt,
    required double Function(String? objectiveId) objectiveActual,
    required double Function(String? objectiveId) objectiveTarget,
    required int Function(int baseXp) scaledRewardXp,
    required DateTime evaluatedAt,
  }) {
    final entries = <PlayerAchievement>[
      for (final node in achievements)
        PlayerAchievement(
          id: AchievementId(node.id.value),
          lifecycle: _resolveLifecycle(
            node: node,
            completed: completedNodeIds.contains(node.id),
            locked: lockedNodeIds.contains(node.id),
            unlockedAt: earliestCompletionAt(node.id),
            actual: objectiveActual(node.objectiveId),
            target: objectiveTarget(node.objectiveId),
            scaledRewardXp: scaledRewardXp,
          ),
          evaluatedAt: evaluatedAt,
        ),
    ];
    return PlayerAchievementShelf.fromEntries(entries);
  }

  PlayerAchievementLifecycle _resolveLifecycle({
    required Achievement node,
    required bool completed,
    required bool locked,
    required DateTime? unlockedAt,
    required double actual,
    required double target,
    required int Function(int baseXp) scaledRewardXp,
  }) {
    if (completed) {
      final baseXp = node.rewards
          .whereType<XpReward>()
          .fold<int>(0, (sum, r) => sum + r.amount);
      return AchievementUnlocked(
        finalXp: scaledRewardXp(baseXp),
        unlockedAt: unlockedAt,
      );
    }
    if (locked) return const AchievementLocked();
    return AchievementInProgress(actual: actual, target: target);
  }
}
