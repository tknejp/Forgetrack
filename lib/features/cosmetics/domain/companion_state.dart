import 'cosmetic_reveal_state.dart';

/// Player-facing lifecycle of a companion cosmetic. The wider cosmetics
/// reveal evaluator returns four general states (`hidden` / `partial` /
/// `visibleLocked` / `unlocked`) that work well for frames, relics,
/// backgrounds — items where the asset and name are part of the
/// progression signal. Companions need a stricter contract: their
/// identity (artwork + localised name) must never appear until the
/// player consciously claims them. The four reveal-evaluator states
/// don't model that distinction cleanly — `visibleLocked` and `partial`
/// both leak identity by design — so the companion layer keeps its
/// own enum that the resolver derives from cosmetics + progression.
///
/// State semantics (matches the design spec):
///
/// * [hidden]: no prerequisite has been met yet. Card + sheet show
///   a silhouette, no name, no checklist (or a single mystery hint).
/// * [partial]: at least one but not all prerequisites met. Identity
///   stays hidden; the requirements checklist surfaces so the player
///   can see how to keep progressing.
/// * [claimable]: every prerequisite met and the engine has surfaced
///   the `CompanionAvailabilityNode` as `available`. Identity stays
///   hidden — the player triggers the reveal by claiming inside the
///   details sheet.
/// * [claimed]: the cosmetic is unlocked. Real artwork + name +
///   description + equipped controls show; the checklist appears
///   fully ticked as a memento of the unlock chain.
enum CompanionState {
  hidden,
  partial,
  claimable,
  claimed;

  /// Convenience matchers used by widgets to branch.
  bool get isClaimed => this == CompanionState.claimed;
  bool get isClaimable => this == CompanionState.claimable;
  bool get isPartial => this == CompanionState.partial;

  /// Identity (asset + localised name) is rendered only in `claimed`.
  /// Every other state masks the card / sheet with the mystery
  /// silhouette so the reveal moment lands inside the claim flow.
  bool get hidesIdentity => this != CompanionState.claimed;

  /// True for any state where the requirements checklist makes sense
  /// to show. `hidden` skips it (mystery state); `partial` shows live
  /// progress; `claimable` and `claimed` show every row ticked.
  bool get showsChecklist =>
      this == CompanionState.partial ||
      this == CompanionState.claimable ||
      this == CompanionState.claimed;
}

/// Pure resolver — does not touch providers directly so it stays
/// trivially unit-testable. Call sites read the inputs once per build
/// and pass them in.
///
/// Resolution order matters and is intentional:
///
/// 1. `claimed` always wins — the cosmetic is in `unlocked`, identity
///    is no longer a secret.
/// 2. `claimable` next — the engine's manual-claim node sits in
///    `availableNodes`. This branch trumps the reveal evaluator's
///    `partial` state for the "all conditions met but not claimed"
///    window so the UI shows the claim CTA instead of a "3/3
///    podmínek splněno" badge that has no action attached.
/// 3. `partial` — the evaluator reports `partial`. Note that the
///    evaluator's `visibleLocked` companion-teaser is collapsed into
///    `hidden` here on purpose: the teaser was designed to surface
///    the companion name + checklist near the level gate, which this
///    feature explicitly rejects. The checklist still appears once
///    progress lands; until then the card stays a mystery.
/// 4. `hidden` — the default fallback.
CompanionState resolveCompanionState({
  required String companionId,
  required Set<String> unlockedCosmeticIds,
  required Set<String> availableNodeIds,
  CosmeticRevealResult? revealResult,
}) {
  if (unlockedCosmeticIds.contains(companionId)) {
    return CompanionState.claimed;
  }
  if (availableNodeIds.contains(companionId)) {
    return CompanionState.claimable;
  }
  if (revealResult?.state == CosmeticRevealState.partial) {
    return CompanionState.partial;
  }
  return CompanionState.hidden;
}
