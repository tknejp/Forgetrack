import 'package:forgetrack/domain/progression/catalog/chapter.dart';
import 'package:forgetrack/domain/progression/player/chapter_lifecycle.dart';
import 'package:forgetrack/domain/progression/player/player_chapter.dart';
import 'package:forgetrack/domain/progression/player/player_chapter_progress.dart';

/// Builds a [PlayerChapterProgress] read projection from engine
/// primitives (chapter catalog + completed-node id set + locked-node
/// id set + earliest-completion-timestamp lookup).
///
/// **Why primitive inputs.** Phase 8 / 10 set the precedent: services
/// live in `application/` and take pure-domain primitives so the
/// projection surface stays decoupled from widget-bound chrome
/// (Flutter / l10n / providers). The inputs here are the same
/// engine state the chapter widgets used to consume via
/// `EngineQuestProgress.state` reads — minus the localised display
/// strings.
///
/// **Precedence (per proposal §4.4).**
///
///   1. **Completed** — the chapter's `completion` node id (or, when
///      no completion node exists, the finale id) lives in
///      `completedNodeIds`. Carries the earliest-completion
///      timestamp from the ledger.
///   2. **InProgress** — at least the opener is completed AND not
///      every chain step is completed. Carries
///      `(currentChainNodeId, stepsCompleted, stepsTotal)`. The
///      current chain node is the lowest-sortOrder uncompleted step,
///      falling back to the finale once every step is done.
///   3. **UnlockedNotStarted** — the opener is completed but no step
///      is. Pairs with the opener's earliest completion timestamp.
///   4. **Locked** — the opener is not completed AND it lives in
///      `lockedNodeIds` (the resolver classified it as
///      `NodeState.locked`).
///   5. **Default** — neither completed nor locked: treat as Locked
///      (defensive — the resolver always returns a classification
///      for every node, but we don't synthesise a fallthrough state
///      that the proposal didn't reserve).
///
/// **Phase 13 mirror of [PlayerAchievementShelfService] /
/// [PlayerCosmeticLifecycleService].** Same statelessness contract;
/// same `const` ctor; same Phase 16+ retirement pathway (the service
/// goes away when the engine evaluator produces
/// [PlayerChapter] directly).
class PlayerChapterProgressService {
  const PlayerChapterProgressService();

  /// Build a [PlayerChapterProgress] from engine primitives.
  ///
  ///   - [chapters]: the chapter catalog (typically
  ///     `ChapterCatalogBuilder.build()`). Insertion order is
  ///     preserved.
  ///   - [completedNodeIds]: node ids with a `NodeCompletionEvent`
  ///     in the ledger. Drives the chain-step counter and the
  ///     Completed branch.
  ///   - [lockedNodeIds]: node ids the resolver classified as
  ///     `NodeState.locked`. Drives the Locked branch.
  ///   - [earliestCompletionAt]: closure returning the earliest
  ///     ledger completion timestamp for a node id, or null when
  ///     the node has no completion event yet. Stamped on
  ///     [ChapterUnlockedNotStarted.unlockedAt] (opener) and
  ///     [ChapterCompleted.completedAt] (completion node or finale).
  ///   - [evaluatedAt]: stamped on every projected entry.
  PlayerChapterProgress build({
    required ChapterCatalog chapters,
    required Set<String> completedNodeIds,
    required Set<String> lockedNodeIds,
    required DateTime? Function(String nodeId) earliestCompletionAt,
    required DateTime evaluatedAt,
  }) {
    final entries = <PlayerChapter>[
      for (final chapter in chapters.all)
        PlayerChapter(
          id: chapter.id,
          lifecycle: _resolveLifecycle(
            chapter: chapter,
            completedNodeIds: completedNodeIds,
            lockedNodeIds: lockedNodeIds,
            earliestCompletionAt: earliestCompletionAt,
          ),
          evaluatedAt: evaluatedAt,
        ),
    ];
    return PlayerChapterProgress.fromEntries(entries);
  }

  ChapterLifecycle _resolveLifecycle({
    required Chapter chapter,
    required Set<String> completedNodeIds,
    required Set<String> lockedNodeIds,
    required DateTime? Function(String nodeId) earliestCompletionAt,
  }) {
    // 1. Completed — completion node fired (or, when no completion
    //    node, the finale fired).
    final terminalNodeId =
        chapter.completion?.value ?? chapter.finale.value;
    if (completedNodeIds.contains(terminalNodeId)) {
      return ChapterCompleted(
        completedAt: earliestCompletionAt(terminalNodeId),
      );
    }

    // 2. Opener completion sets the InProgress / UnlockedNotStarted
    //    branch. Without an opener completion we're either Locked
    //    (resolver says so) or defensive-Locked (no classification).
    final openerCompleted = completedNodeIds.contains(chapter.opener.value);
    if (!openerCompleted) {
      // Locked: the opener is the chapter's gateway. If it's locked
      // by conditions, the chapter is locked.
      return const ChapterLocked();
    }

    final stepsCompleted = [
      for (final step in chapter.steps)
        if (completedNodeIds.contains(step.value)) step,
    ].length;
    final stepsTotal = chapter.steps.length;

    if (stepsCompleted == 0 && stepsTotal > 0) {
      return ChapterUnlockedNotStarted(
        unlockedAt: earliestCompletionAt(chapter.opener.value),
      );
    }

    // InProgress: at least one step done OR chapter has no steps
    // (opener → finale). currentChainNode = first uncompleted step,
    // falling back to finale once every step is done.
    final currentChainNode = chapter.steps.firstWhere(
      (id) => !completedNodeIds.contains(id.value),
      orElse: () => chapter.finale,
    );

    // Chapter with no steps and opener-only completion is also
    // UnlockedNotStarted from a player POV — the finale is the next
    // (and only) thing to do.
    if (stepsTotal == 0 && !completedNodeIds.contains(chapter.finale.value)) {
      return ChapterUnlockedNotStarted(
        unlockedAt: earliestCompletionAt(chapter.opener.value),
      );
    }

    return ChapterInProgress(
      currentChainNodeId: currentChainNode,
      stepsCompleted: stepsCompleted,
      stepsTotal: stepsTotal,
    );
  }
}
