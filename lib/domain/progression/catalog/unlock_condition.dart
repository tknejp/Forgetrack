import 'ids.dart';

/// Composable predicate gating whether a node becomes available,
/// active, completable, or claimable.
///
/// Sealed so the resolver gets exhaustive switch checking. Compose
/// with [AllOf] / [AnyOf] when a node needs more than one gate; a node
/// with an empty `unlockConditions` list is always eligible (subject
/// to its [Objective] outcome).
sealed class UnlockCondition {
  const UnlockCondition();
}

class LevelAtLeast extends UnlockCondition {
  const LevelAtLeast(this.level);
  final int level;
}

class ObjectiveCompleted extends UnlockCondition {
  const ObjectiveCompleted(this.objectiveId);
  final ObjectiveId objectiveId;
}

class NodeCompleted extends UnlockCondition {
  const NodeCompleted(this.nodeId);
  final ProgressionEntryId nodeId;
}

/// The named node has a completion event whose timestamp is **strictly
/// before today's local midnight**. Used by combo daily chains where
/// only one step per day may complete — step N+1 stays gated on the
/// same calendar day step N finished, even if today's atoms would
/// satisfy step N+1's objective.
class NodeCompletedBeforeToday extends UnlockCondition {
  const NodeCompletedBeforeToday(this.nodeId);
  final ProgressionEntryId nodeId;
}

class ChapterUnlocked extends UnlockCondition {
  const ChapterUnlocked(this.chapterId);
  final ChapterId chapterId;
}

/// Chapter is **currently active** — the player has cleared the
/// chapter's `open` quest but has not yet completed its `finale`.
/// Used by chapter-themed daily side quests so they only appear
/// while the matching chapter is in play; once the chapter
/// finishes, the side quests retire automatically.
///
/// Convention: open/finale node ids are `<chapterId>_open` and
/// `<chapterId>_finale`. The resolver walks `completedNodeIds` to
/// evaluate; no engine input wiring needed.
class ChapterActive extends UnlockCondition {
  const ChapterActive(this.chapterId);
  final ChapterId chapterId;
}

class CompanionAvailable extends UnlockCondition {
  const CompanionAvailable(this.companionId);
  final CosmeticId companionId;
}

/// True when the player currently owns the named cosmetic (i.e., the
/// cosmetic id is in the cosmetics inventory's `unlocked` map).
///
/// Used by `CompanionAvailability` gates whose semantics are "player
/// owns relic X" (e.g. forest fox requires `relic_moonlit_foxglove` +
/// `relic_ancient_root`). The relic-ownership semantic matches the
/// reveal evaluator's `Cond.ownsCosmetic` so both surfaces (the
/// engine's claim CTA + the reveal UI's partial-progress checklist)
/// read from the same source of truth — the cosmetics inventory.
///
/// The previous condition shape used `NodeCompleted(<achievement_id>)`
/// where the achievement was the one that granted the relic; in normal
/// production flow those two are equivalent (achievement complete →
/// reward grant → bridge unlocks relic), but they diverge whenever
/// the cosmetics inventory gets mutated through a side channel
/// (devtools `debugGrantCosmetic`, "Unlock all cosmetics", a partial
/// cloud-pull merge). `OwnsCosmetic` closes that divergence by
/// reading the inventory directly.
class OwnsCosmetic extends UnlockCondition {
  const OwnsCosmetic(this.cosmeticId);
  final CosmeticId cosmeticId;
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
