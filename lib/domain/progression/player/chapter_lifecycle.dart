import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import '../catalog/unlock_condition.dart';

/// Player-side lifecycle of one Chapter catalog row.
///
/// Phase 13 of the domain refactor introduces this sealed hierarchy
/// as the discriminator widgets pattern-match on instead of indirect
/// reads off the engine's [NodeResolution] / [EngineQuestProgress]
/// state for individual chain entries. The 4 states map 1:1 to the
/// proposal's transition diagram (`docs/domain_model/proposal.md`
/// §4.4):
///
///   - [ChapterLocked] — the chapter's gating unlock conditions
///     (typically the previous chapter's finale + a `LevelAtLeast`
///     gate on the opener) have not been satisfied yet. The chapter
///     screen renders a "Zamčeno" card with a hint.
///   - [ChapterUnlockedNotStarted] — the opener is auto-claimable
///     but the player hasn't progressed past it. The screen shows
///     the chapter intro + the first chain step.
///   - [ChapterInProgress] — at least the opener is completed and
///     some (but not all) chain steps are done. Carries the live
///     `stepsCompleted / stepsTotal` counters for the progress bar
///     and the `currentChainNodeId` so the screen can scroll the
///     active step into view.
///   - [ChapterCompleted] — the chapter's `ChapterCompletion` node
///     has fired in the ledger. The screen renders a "Splněno" badge
///     and the finale rewards.
///
/// **Sealed contract.** Patterns over [ChapterLifecycle] are
/// exhaustive with the 4 subtypes; the compiler enforces coverage so
/// a future 5th state (e.g. `ChapterArchived` for legacy content)
/// fails every consumer at compile time.
///
/// **Payload fidelity (proposal §4.4).**
///   - `ChapterLocked.gate: UnlockCondition` is **deferred** in the
///     same way Phase 6 deferred `QuestLocked.remaining` and Phase 8
///     deferred `AchievementLocked.remaining`: [UnlockCondition]
///     still lives in `lib/features/progression_engine/` and the
///     domain layer cannot import features. When `UnlockCondition`
///     migrates to the domain catalog (a later phase), this type
///     will gain the field.
///   - [ChapterUnlockedNotStarted.unlockedAt] sources from the
///     earliest `NodeCompletionEvent` for the chapter's opener id in
///     the ledger.
///   - [ChapterInProgress.stepsCompleted / .stepsTotal] count chain
///     entries (`ChapterStep` rows) only — the opener and finale are
///     excluded from the ratio so the progress bar's 100% mark lines
///     up with completing the last step (the finale fires the
///     transition to [ChapterCompleted]).
///   - [ChapterCompleted.completedAt] sources from the earliest
///     completion event of the chapter's `ChapterCompletion` node.
@immutable
sealed class ChapterLifecycle {
  const ChapterLifecycle();
}

/// Gating unlock conditions not yet satisfied. The chapter is hidden
/// or shown with a "Zamčeno" hint on the journey map.
///
/// **[gate]** carries the catalog [UnlockCondition] that still
/// evaluates to `false` for this player — typically a
/// [NodeCompleted] on the previous chapter's finale or a
/// [LevelAtLeast] on the chapter opener. R.1 wired this in per
/// proposal §4.4. Producer: `PlayerChapterProgressService`.
/// When a chapter declares multiple gating conditions the service
/// wraps them in an [AllOf] so [gate] stays a single value.
@immutable
class ChapterLocked extends ChapterLifecycle {
  const ChapterLocked({this.gate});

  /// Catalog condition still unsatisfied. Nullable when the chapter
  /// is locked by [ActivationPolicy] (e.g. RPG mode off) or by an
  /// implicit gate the service does not surface — the screen falls
  /// back to a generic "Zamčeno" message in that case.
  final UnlockCondition? gate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterLocked && other.gate == gate;
  }

  @override
  int get hashCode => Object.hash(ChapterLocked, gate);

  @override
  String toString() => 'ChapterLocked(gate: $gate)';
}

/// Opener is auto-claimable but no chain step has been completed yet.
/// The screen displays the chapter intro + first step prompt.
@immutable
class ChapterUnlockedNotStarted extends ChapterLifecycle {
  const ChapterUnlockedNotStarted({this.unlockedAt});

  /// Timestamp the opener fired into the ledger. Nullable when the
  /// ledger row is missing (e.g. engine reset).
  final DateTime? unlockedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterUnlockedNotStarted &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode => Object.hash(ChapterUnlockedNotStarted, unlockedAt);

  @override
  String toString() => 'ChapterUnlockedNotStarted(at: $unlockedAt)';
}

/// At least one chain step is completed but the chapter isn't
/// finalised yet. Carries the live progress counters + a pointer to
/// the active chain entry so the screen can scroll it into view.
@immutable
class ChapterInProgress extends ChapterLifecycle {
  const ChapterInProgress({
    required this.currentChainNodeId,
    required this.stepsCompleted,
    required this.stepsTotal,
  });

  /// Id of the chapter chain entry that's currently the focus
  /// (typically the lowest-sortOrder uncompleted step, or the finale
  /// once every step is done). Drives the progress card's "active
  /// step" highlight.
  final ProgressionEntryId currentChainNodeId;

  /// Number of chain steps (`ChapterStep` rows) already completed.
  /// Excludes opener + finale per proposal §4.4.
  final int stepsCompleted;

  /// Total chain steps (`ChapterStep` rows) in this chapter.
  final int stepsTotal;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterInProgress &&
        other.currentChainNodeId == currentChainNodeId &&
        other.stepsCompleted == stepsCompleted &&
        other.stepsTotal == stepsTotal;
  }

  @override
  int get hashCode => Object.hash(
        ChapterInProgress,
        currentChainNodeId,
        stepsCompleted,
        stepsTotal,
      );

  @override
  String toString() =>
      'ChapterInProgress(current: $currentChainNodeId, '
      '$stepsCompleted/$stepsTotal)';
}

/// Terminal state — the chapter's [ChapterCompletion] node has fired
/// in the ledger. Idempotent; once completed, chapters never re-lock.
@immutable
class ChapterCompleted extends ChapterLifecycle {
  const ChapterCompleted({this.completedAt});

  /// Timestamp of the earliest `NodeCompletionEvent` for the
  /// chapter's `ChapterCompletion` row in the ledger.
  final DateTime? completedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterCompleted && other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(ChapterCompleted, completedAt);

  @override
  String toString() => 'ChapterCompleted(at: $completedAt)';
}
