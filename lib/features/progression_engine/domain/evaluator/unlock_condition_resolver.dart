import '../models/engine_evaluation_input.dart';
import '../models/unlock_condition.dart';
import '../repository/ledger_snapshot.dart';

/// Pure resolver: given a node's unlock conditions plus current
/// engine state (objective outcomes, ledger, input), returns whether
/// the node is eligible.
///
/// `AllOf` / `AnyOf` recurse; an empty condition list is always
/// eligible (the node's own [ObjectiveDefinition] outcome decides
/// completion).
class UnlockConditionResolver {
  const UnlockConditionResolver();

  bool isEligible({
    required List<UnlockCondition> conditions,
    required Set<String> completedObjectiveIds,
    required Set<String> completedNodeIds,
    required Set<String> claimedNodeIds,
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
        completedNodeIds: completedNodeIds,
        claimedNodeIds: claimedNodeIds,
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
    required Set<String> completedNodeIds,
    required Set<String> claimedNodeIds,
    required Set<String> unlockedChapterIds,
    required Set<String> availableCompanionIds,
    required EngineEvaluationInput input,
    required LedgerSnapshot ledger,
  }) {
    return switch (condition) {
      LevelAtLeast(:final level) => input.level >= level,
      ObjectiveCompleted(:final objectiveId) =>
        completedObjectiveIds.contains(objectiveId),
      NodeCompleted(:final nodeId) => completedNodeIds.contains(nodeId),
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
      ChapterActive(:final chapterId) =>
        completedNodeIds.contains('${chapterId}_open') &&
            !completedNodeIds.contains('${chapterId}_finale'),
      CompanionAvailable(:final companionId) =>
        availableCompanionIds.contains(companionId),
      RpgModeEnabled() => input.rpgModeEnabled,
      AllOf(:final conditions) => conditions.every((c) => _resolve(
            c,
            completedObjectiveIds: completedObjectiveIds,
            completedNodeIds: completedNodeIds,
            claimedNodeIds: claimedNodeIds,
            unlockedChapterIds: unlockedChapterIds,
            availableCompanionIds: availableCompanionIds,
            input: input,
            ledger: ledger,
          )),
      AnyOf(:final conditions) => conditions.any((c) => _resolve(
            c,
            completedObjectiveIds: completedObjectiveIds,
            completedNodeIds: completedNodeIds,
            claimedNodeIds: claimedNodeIds,
            unlockedChapterIds: unlockedChapterIds,
            availableCompanionIds: availableCompanionIds,
            input: input,
            ledger: ledger,
          )),
    };
  }
}
