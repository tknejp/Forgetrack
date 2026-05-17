/// Declarative policies that hang on a [QuestNode] subtype and tell
/// the rest of the engine how it should behave. The point of moving
/// these onto the type is to *eliminate* ad-hoc branching:
///
/// - The provider used to ask "is this displayBucket daily? then
///   keep claimed cards in the slot until midnight" in one place,
///   "is this combo and gated by NodeCompletedBeforeToday? then
///   show the prior step as placeholder" in another, and "is this
///   a side quest claimed today? then pin it" in a third. All
///   three say the same thing — *something* stays pinned until
///   midnight. [SlotPolicy] makes that one declared property on
///   the subtype.
/// - The catalog used to spell out `NodeCompletedBeforeToday(prev)`
///   on every combo step + every chapter side quest, plus the
///   provider had its own `_isStepGatedByCompletionToday` helper.
///   [GatePolicy] makes "wait at least one day after the prereq
///   landed" intrinsic to combo / side-quest subtypes.
/// - The celebration adapter has eight nested branches deciding
///   when to fire silently vs fullscreen, with chapter icon vs
///   without, folded into a goal bucket vs solo. [CelebrationPolicy]
///   makes that a single property the adapter consults.
///
/// Phase 2 (this file) just *declares* the policies and wires them
/// into subtype defaults; only [GatePolicy] is consumed by the
/// engine right now (it derives `NodeCompletedBeforeToday` from the
/// cooldown so catalog content can drop the explicit conditions).
/// [SlotPolicy] and [CelebrationPolicy] are read by the provider /
/// adapter in Phase 3 and 4.
library;

/// How a quest behaves inside the screen surfaces that pick what to
/// show today.
sealed class SlotPolicy {
  const SlotPolicy();
}

/// Daily-quest pattern. A deterministic hash over the local date
/// rotates a fixed-size pool of candidate quests; the same quest stays
/// in its slot all day, and a claimed card simply flips to its done
/// state until midnight rolls the rotation.
class HashRotationStickyUntilMidnight extends SlotPolicy {
  const HashRotationStickyUntilMidnight();
}

/// Chapter side-quest pattern. One slot, one quest. While the player
/// has a side quest *claimed today*, it stays pinned to the slot
/// (reads as "Splněno") until midnight; otherwise the slot looks for
/// a new eligible side quest. Replaces the ad-hoc "claimed today"
/// timestamp scan in the provider.
class PinClaimedTodayUntilMidnight extends SlotPolicy {
  const PinClaimedTodayUntilMidnight();
}

/// Combo-chain pattern. The chain walks left-to-right; when the next
/// step is gated by [GatePolicy] *for today*, the section surfaces
/// the previous (already-completed) step as a "done for today"
/// placeholder instead of an empty slot. Tomorrow's evaluation flips
/// the gate open and the chain advances.
class ChainPlaceholderUntilMidnight extends SlotPolicy {
  const ChainPlaceholderUntilMidnight();
}

/// Chapter chain step. Renders on the chapter card itself (including
/// the "Vyzvednout XP" pill on the claimable state) instead of in a
/// generic daily / weekly slot. The chapter section owns the
/// presentation; no rotation, no pinning.
class ChapterCardSticky extends SlotPolicy {
  const ChapterCardSticky();
}

/// Always visible until the quest's own scope retires it. Weekly
/// activity stays put for a week, long-term chain steps stay put
/// until claimed — no rotation, no time-of-day rules.
class Persistent extends SlotPolicy {
  const Persistent();
}

/// Daily-challenge template pool. One template per day, picked by a
/// deterministic hash over (date, pool members). Once claimed a
/// template is permanently retired (the objective uses
/// `LifetimeScope`).
class DailyChallengeHashPick extends SlotPolicy {
  const DailyChallengeHashPick();
}

/// Doesn't surface in any daily-section pool. Used by quest subtypes
/// the player never sees directly (e.g. cosmetic-only nodes that
/// exist purely as objective hosts).
class HiddenFromSections extends SlotPolicy {
  const HiddenFromSections();
}

// ── GatePolicy ──────────────────────────────────────────────────────

/// Time-based cooldown on top of regular prerequisites.
///
/// Today only [CooldownDays(1)] is concrete — it instructs the engine
/// to derive a `NodeCompletedBeforeToday(prereq)` for every
/// `prerequisiteNodeIds` entry the node carries, on top of the
/// implicit `NodeCompleted(prereq)`. Catalog content can therefore
/// drop the explicit `NodeCompletedBeforeToday` spellings — the
/// subtype declares "this is the kind of thing that paces one step
/// per day" and the engine wires the gate.
sealed class GatePolicy {
  const GatePolicy();
}

/// Default — no extra time gating beyond the explicit unlock
/// conditions the catalog author writes.
class NoCooldown extends GatePolicy {
  const NoCooldown();
}

/// The node's prerequisites must have completed at least [days]
/// before today's local midnight before the node becomes eligible.
/// Implements the "one combo step per day", "side quest unlocks the
/// day after the chapter step lands" semantics.
class CooldownDays extends GatePolicy {
  const CooldownDays(this.days)
      : assert(days >= 1, 'CooldownDays must be >= 1');
  final int days;
}

// ── CelebrationPolicy ───────────────────────────────────────────────

/// How a quest claim / completion should be announced. The adapter
/// reads this in Phase 4 to replace its current branchy fold passes
/// with a single declarative dispatch.
sealed class CelebrationPolicy {
  const CelebrationPolicy();
}

/// No celebration overlay. The card's XP-pill state flip is the
/// only feedback the player gets. Default for daily / weekly /
/// long-term / combo / side-quest claims — the user explicitly
/// asked for these to be quiet.
class SilentCelebration extends CelebrationPolicy {
  const SilentCelebration();
}

/// Fullscreen "Nová kapitola otevřena" celebration with the chapter
/// icon as the headliner card. Reserved for [ChapterOpener].
class ChapterOpenedCelebration extends CelebrationPolicy {
  const ChapterOpenedCelebration();
}

/// Fullscreen "Kapitola dokončena" celebration with the chapter
/// icon plus any finale cosmetic rewards. Reserved for
/// [ChapterFinale].
class ChapterCompletedCelebration extends CelebrationPolicy {
  const ChapterCompletedCelebration();
}
