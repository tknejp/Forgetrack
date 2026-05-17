import '../models/engine_evaluation_input.dart';
import '../models/unlock_condition.dart';
import '../repository/ledger_snapshot.dart';

/// Pure resolver: given a node's unlock conditions plus current
/// engine state (objective outcomes, ledger, input), returns whether
/// the node is eligible.
///
/// `AllOf` / `AnyOf` recurse; an empty condition list is always
/// eligible (the node's own [Objective] outcome decides
/// completion).
///
/// **Lifetime vs period semantics.** Every set this resolver receives
/// — [completedNodesLifetime], [claimedNodesLifetime],
/// [unlockedChapterIds], [availableCompanionIds] — describes "this
/// has happened at least once ever". That matches every current
/// `NodeCompleted` use case in the catalog: chain prereqs point at
/// lifetime-scoped targets (chapter opens, combo steps, side-quest
/// chain steps, achievement gates), so the flat-set check is
/// correct.
///
/// For *period-aware* completion checks ("has X been claimed in its
/// current period?"), callers should query the [ledger] directly via
/// `ledger.hasEventKey(completionEventKey(nodeId, periodKey))`. No
/// catalog node uses that pattern today; if a future condition needs
/// it (e.g. "today's daily protein completed?") add it as a new
/// `NodeCompletedInPeriod(nodeId, periodKey)` sealed case and read
/// the ledger inline.
class UnlockConditionResolver {
  const UnlockConditionResolver();

  bool isEligible({
    required List<UnlockCondition> conditions,
    required Set<String> completedObjectiveIds,
    required Set<String> completedNodesLifetime,
    required Set<String> claimedNodesLifetime,
    required Set<String> unlockedChapterIds,
    required Set<String> availableCompanionIds,
    required EngineEvaluationInput input,
    required LedgerSnapshot ledger,
  }) {
    if (conditions.isEmpty) return true;
    for (final c in conditions) {
      if (!_resolve(
        c,
        completedObjectiveIds: completedObjectiveIds,
        completedNodesLifetime: completedNodesLifetime,
        claimedNodesLifetime: claimedNodesLifetime,
        unlockedChapterIds: unlockedChapterIds,
        availableCompanionIds: availableCompanionIds,
        input: input,
        ledger: ledger,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _resolve(
    UnlockCondition condition, {
    required Set<String> completedObjectiveIds,
    required Set<String> completedNodesLifetime,
    required Set<String> claimedNodesLifetime,
    required Set<String> unlockedChapterIds,
    required Set<String> availableCompanionIds,
    required EngineEvaluationInput input,
    required LedgerSnapshot ledger,
  }) {
    return switch (condition) {
      LevelAtLeast(:final level) => input.level >= level,
      ObjectiveCompleted(:final objectiveId) =>
        completedObjectiveIds.contains(objectiveId),
      // Lifetime semantic: the target has been completed at any point
      // ever, regardless of its scope. Chain prereqs use this.
      NodeCompleted(:final nodeId) =>
        completedNodesLifetime.contains(nodeId),
      NodeCompletedBeforeToday(:final nodeId) => () {
        final todayStart = DateTime(
          input.evaluatedAt.year,
          input.evaluatedAt.month,
          input.evaluatedAt.day,
        );
        for (final e in ledger.nodeCompletions) {
          if (e.nodeId != nodeId) continue;
          if (e.timestamp.toLocal().isBefore(todayStart)) return true;
        }
        return false;
      }(),
      ChapterUnlocked(:final chapterId) =>
        unlockedChapterIds.contains(chapterId),
      // Chapter open/finale are once-and-done lifetime nodes, so the
      // lifetime set is the right read here.
      ChapterActive(:final chapterId) =>
        completedNodesLifetime.contains('${chapterId}_open') &&
            !completedNodesLifetime.contains('${chapterId}_finale'),
      CompanionAvailable(:final companionId) =>
        availableCompanionIds.contains(companionId),
      RpgModeEnabled() => input.rpgModeEnabled,
      AllOf(:final conditions) => conditions.every((c) => _resolve(
            c,
            completedObjectiveIds: completedObjectiveIds,
            completedNodesLifetime: completedNodesLifetime,
            claimedNodesLifetime: claimedNodesLifetime,
            unlockedChapterIds: unlockedChapterIds,
            availableCompanionIds: availableCompanionIds,
            input: input,
            ledger: ledger,
          )),
      AnyOf(:final conditions) => conditions.any((c) => _resolve(
            c,
            completedObjectiveIds: completedObjectiveIds,
            completedNodesLifetime: completedNodesLifetime,
            claimedNodesLifetime: claimedNodesLifetime,
            unlockedChapterIds: unlockedChapterIds,
            availableCompanionIds: availableCompanionIds,
            input: input,
            ledger: ledger,
          )),
    };
  }
}
