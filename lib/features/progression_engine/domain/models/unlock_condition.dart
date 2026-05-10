/// Composable predicate gating whether a node becomes available,
/// active, completable, or claimable.
///
/// Sealed so the resolver gets exhaustive switch checking. Compose
/// with [AllOf] / [AnyOf] when a node needs more than one gate; a node
/// with an empty `unlockConditions` list is always eligible (subject
/// to its [ObjectiveDefinition] outcome).
sealed class UnlockCondition {
  const UnlockCondition();
}

class LevelAtLeast extends UnlockCondition {
  const LevelAtLeast(this.level);
  final int level;
}

class ObjectiveCompleted extends UnlockCondition {
  const ObjectiveCompleted(this.objectiveId);
  final String objectiveId;
}

class NodeCompleted extends UnlockCondition {
  const NodeCompleted(this.nodeId);
  final String nodeId;
}

class ChapterUnlocked extends UnlockCondition {
  const ChapterUnlocked(this.chapterId);
  final String chapterId;
}

class CompanionAvailable extends UnlockCondition {
  const CompanionAvailable(this.companionId);
  final String companionId;
}

/// True when the player has RPG mode enabled. Lets RPG-only nodes
/// declare the dependency explicitly, in addition to (or instead of)
/// the [ActivationPolicy] axis on the node itself.
class RpgModeEnabled extends UnlockCondition {
  const RpgModeEnabled();
}

class AllOf extends UnlockCondition {
  const AllOf(this.conditions);
  final List<UnlockCondition> conditions;
}

class AnyOf extends UnlockCondition {
  const AnyOf(this.conditions);
  final List<UnlockCondition> conditions;
}
