import 'package:meta/meta.dart';

/// Player-side lifecycle of one Quest catalog row.
///
/// Phase 6 of the domain refactor introduces this sealed hierarchy as
/// the discriminator widgets pattern-match on instead of a bag of
/// booleans (`isCompleted` / `isAvailableForClaim` /
/// `isLockedByConditions`). The 4 states map 1:1 to the proposal's
/// transition diagram (`docs/domain_model/proposal.md` §4.1):
///
///   - [QuestLocked] — unlock conditions or activation policy not met
///     (RPG-mode-gated nodes when RPG is off, level / prereq gates).
///   - [QuestAvailable] — eligible + objective in progress; the
///     progress bar tracks `actual / target`.
///   - [QuestCompletedPendingClaim] — objective satisfied and
///     `ClaimPolicy.manual` requires a player tap before the
///     reward grants land in the ledger; the XP pill turns gold.
///   - [QuestClaimed] — terminal state. The completion event is in the
///     ledger (manual: after the tap; automatic: as part of the same
///     eval cycle that satisfied the objective).
///
/// Bridge from the existing producer:
///   `EngineQuestProgress.lifecycle` derives this from the existing
///   `isCompleted` / `isAvailableForClaim` / `isLockedByConditions`
///   flags. Phase 7 will move authority into
///   `PlayerQuestCatalogService` and the flags drop entirely.
///
/// Payload fidelity (proposal §4.1):
///   - `QuestLocked.remaining: List<UnlockCondition>` is deferred —
///     `UnlockCondition` still lives in `lib/features/progression_engine/`
///     and `lib/domain/` cannot import features. The condition slice
///     lands when UnlockCondition migrates to the domain layer
///     (catalog rename phase). For Phase 6 widgets show the locked
///     row using `EngineQuestProgress.levelGate` / `prereqGateNodeId`
///     which are independent of the sealed type.
///   - `QuestCompletedPendingClaim.completedAt` / `QuestClaimed.claimedAt`
///     are nullable; Phase 6 widgets do not need them yet. Phase 7's
///     `PlayerQuestCatalogService` will source them from the
///     Journal's `NodeCompletionEvent` / `NodeClaimEvent` timestamps.
///   - `QuestClaimed.finalXp` is the level-scaled XP value the player
///     received (matches `EngineQuestProgress.previewXp` for claimed
///     quests by the engine's existing invariant — preview tracks the
///     current level multiplier so the displayed and granted values
///     stay aligned).
@immutable
sealed class PlayerQuestLifecycle {
  const PlayerQuestLifecycle();
}

/// Unlock conditions or activation policy block this quest. The player
/// cannot interact with it; the UI surface renders the locked-row
/// variant (greyed asset, "Reach level X" / "Complete chapter Y" copy).
@immutable
class QuestLocked extends PlayerQuestLifecycle {
  const QuestLocked();

  @override
  bool operator ==(Object other) => other is QuestLocked;

  @override
  int get hashCode => (QuestLocked).hashCode;

  @override
  String toString() => 'QuestLocked()';
}

/// Eligible to claim once the objective hits its target. Holds the
/// live progress numbers so the card's progress row can render
/// `actual / target` and the value-unit-aware bar.
@immutable
class QuestAvailable extends PlayerQuestLifecycle {
  const QuestAvailable({
    required this.actual,
    required this.target,
    required this.progress,
  });

  final double actual;
  final double target;

  /// 0..1, clamped to the bar's display range.
  final double progress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestAvailable &&
        other.actual == actual &&
        other.target == target &&
        other.progress == progress;
  }

  @override
  int get hashCode => Object.hash(QuestAvailable, actual, target, progress);

  @override
  String toString() =>
      'QuestAvailable(actual: $actual, target: $target, progress: $progress)';
}

/// Objective satisfied; `ClaimPolicy.manual` requires the player to
/// tap the gold pill to materialise the completion + reward grants in
/// the ledger. [previewXp] is the level-scaled XP the player will
/// receive — same value the gold pill displays.
@immutable
class QuestCompletedPendingClaim extends PlayerQuestLifecycle {
  const QuestCompletedPendingClaim({
    required this.previewXp,
    this.completedAt,
  });

  final int previewXp;

  /// Timestamp of the underlying `NodeCompletionEvent` (when authored)
  /// — Phase 6 widgets don't render this yet; Phase 7's
  /// PlayerQuestCatalogService will source it from the Journal.
  final DateTime? completedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestCompletedPendingClaim &&
        other.previewXp == previewXp &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode =>
      Object.hash(QuestCompletedPendingClaim, previewXp, completedAt);

  @override
  String toString() => 'QuestCompletedPendingClaim(previewXp: $previewXp, '
      'completedAt: $completedAt)';
}

/// Terminal state. The completion event is in the ledger; the gold
/// pill has greyed to the claimed style, the progress row collapses
/// to a "Splněno" label.
@immutable
class QuestClaimed extends PlayerQuestLifecycle {
  const QuestClaimed({
    required this.finalXp,
    this.claimedAt,
  });

  /// XP credited to the player when the quest was claimed. Matches
  /// `EngineQuestProgress.previewXp` for claimed quests — see the
  /// invariant on `previewXp` in the engine provider.
  final int finalXp;

  /// Timestamp of the underlying `NodeClaimEvent` (when authored). Not
  /// rendered in Phase 6; sourced from the Journal in Phase 7.
  final DateTime? claimedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestClaimed &&
        other.finalXp == finalXp &&
        other.claimedAt == claimedAt;
  }

  @override
  int get hashCode => Object.hash(QuestClaimed, finalXp, claimedAt);

  @override
  String toString() =>
      'QuestClaimed(finalXp: $finalXp, claimedAt: $claimedAt)';
}
