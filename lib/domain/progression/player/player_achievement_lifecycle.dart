import 'package:meta/meta.dart';

import '../catalog/unlock_condition.dart';

/// Player-side lifecycle of one Achievement catalog row.
///
/// Phase 8 of the domain refactor introduces this sealed hierarchy as
/// the discriminator widgets pattern-match on instead of a single
/// `unlocked: bool` flag on `EngineAchievementView`. The 3 states map
/// 1:1 to the proposal's transition diagram
/// (`docs/domain_model/proposal.md` §4.2):
///
///   - [AchievementLocked] — unlock conditions not met (engine resolved
///     the node to `NodeState.locked`). The achievement is hidden /
///     greyed in the catalog grid.
///   - [AchievementInProgress] — eligible (conditions met), the bound
///     objective tracks `actual / target` toward unlock. Progress bar
///     renders the ratio.
///   - [AchievementUnlocked] — terminal state. The engine resolver has
///     materialised a node completion + reward grant in the ledger
///     (achievements are `ClaimPolicy.automatic`, so this is atomic
///     with the objective firing — there is **no** `PendingClaim`
///     state, per proposal §4.2).
///
/// **No PendingClaim.** Quests can sit in `QuestCompletedPendingClaim`
/// because manual claim policy requires a player tap. Achievements
/// don't — the moment the objective fires, the completion event lands
/// in the ledger and the lifecycle steps straight to [AchievementUnlocked].
/// Adding a `PendingClaim` subtype here would mirror the quest shape
/// but never instantiate.
///
/// **Bridge from the existing producer.** Phase 8 ships
/// `EngineAchievementView.lifecycle` which derives this sealed
/// discriminator from the view's flags (`unlocked`, `isLockedByConditions`).
/// Same bridge pattern Phase 6 used for `EngineQuestProgress.lifecycle`.
/// `PlayerAchievementShelfService` reads through that bridge. When
/// Phase 16+ reworks the engine signature, the bridge moves there
/// without changing the sealed API.
///
/// **Payload fidelity (proposal §4.2).**
///   - `AchievementLocked.remaining: List<UnlockCondition>` is
///     deferred — `UnlockCondition` still lives in
///     `lib/features/progression_engine/` and the domain layer cannot
///     import features. Phase 6 made the same deferral for
///     `QuestLocked.remaining`; the full condition slice lands when
///     `UnlockCondition` migrates to the domain catalog.
///   - `AchievementUnlocked.unlockedAt` matches the engine's
///     `EngineAchievementView.unlockedAt` (sourced from the earliest
///     `NodeCompletionEvent` for the node in the ledger).
///   - `AchievementUnlocked.finalXp` is the level-scaled XP value the
///     player received at unlock time. The engine view exposes a
///     `previewXp` mirror that tracks the catalog reward XP through
///     `ProgressionLevelPolicy.scaledRewardXp`; for already-unlocked
///     achievements this matches the granted amount by the same
///     invariant Phase 6 documented for `QuestClaimed.finalXp`.
///
/// **Switch contract.** Patterns over `PlayerAchievementLifecycle` are
/// exhaustive with the 3 subtypes; the compiler enforces coverage so a
/// future 4th state (e.g. `AchievementHidden` for content-gated rows)
/// fails every consumer at compile time.
@immutable
sealed class PlayerAchievementLifecycle {
  const PlayerAchievementLifecycle();
}

/// Unlock conditions failed. The achievement is hidden / greyed in the
/// grid; the player cannot make progress toward it until the gating
/// node fires.
///
/// **[remaining]** carries the catalog [UnlockCondition]s that haven't
/// evaluated to `true` for this player. R.1 wired this in per
/// proposal §4.2: an empty list means the achievement is locked by
/// `ActivationPolicy` alone (e.g. RPG mode off) rather than an
/// explicit condition. Producer: `PlayerAchievementShelfService`.
@immutable
class AchievementLocked extends PlayerAchievementLifecycle {
  const AchievementLocked({this.remaining = const []});

  final List<UnlockCondition> remaining;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AchievementLocked) return false;
    if (other.remaining.length != remaining.length) return false;
    for (var i = 0; i < remaining.length; i++) {
      if (other.remaining[i] != remaining[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([AchievementLocked, ...remaining]);

  @override
  String toString() => 'AchievementLocked(remaining: $remaining)';
}

/// Eligible (conditions met); the bound objective is in progress.
/// Holds the live progress numbers so the grid card / detail sheet can
/// render `actual / target` and a progress bar.
@immutable
class AchievementInProgress extends PlayerAchievementLifecycle {
  const AchievementInProgress({
    required this.actual,
    required this.target,
  });

  /// Current measured value for the bound objective.
  final double actual;

  /// Target value for the bound objective. `0` for condition-only
  /// achievements that have no measurable progress (they spend their
  /// entire pre-unlock life in [AchievementLocked]; this fallback
  /// keeps the type total).
  final double target;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementInProgress &&
        other.actual == actual &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(AchievementInProgress, actual, target);

  @override
  String toString() => 'AchievementInProgress(actual: $actual, target: $target)';
}

/// Terminal state. The ledger has the achievement's completion event;
/// the catalog grid renders the unlocked artwork + a "Splněno
/// dd.mm.yyyy" caption. Idempotent — once unlocked, the achievement
/// never re-locks (achievements don't have a re-lock pathway in V2).
@immutable
class AchievementUnlocked extends PlayerAchievementLifecycle {
  const AchievementUnlocked({
    required this.finalXp,
    this.unlockedAt,
  });

  /// XP credited to the player when the achievement unlocked. Sourced
  /// from `EngineAchievementView.previewXp` at the bridge — same
  /// invariant Phase 6 documented for `QuestClaimed.finalXp` (preview
  /// XP tracks the current level multiplier, so for already-claimed
  /// rows the displayed and granted values stay aligned).
  final int finalXp;

  /// Timestamp of the earliest `NodeCompletionEvent` for this
  /// achievement in the ledger. Nullable: the engine view returns null
  /// when the ledger is still loading or the event was lost to a
  /// devtools reset; consumers fall back to "today" or hide the date
  /// caption.
  final DateTime? unlockedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementUnlocked &&
        other.finalXp == finalXp &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode => Object.hash(AchievementUnlocked, finalXp, unlockedAt);

  @override
  String toString() =>
      'AchievementUnlocked(finalXp: $finalXp, unlockedAt: $unlockedAt)';
}
