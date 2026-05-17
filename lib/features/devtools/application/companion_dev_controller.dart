import '../../cosmetics/application/companions_registry.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/companion_state.dart';
import '../../cosmetics/domain/consumed_relics.dart';
import '../../cosmetics/domain/cosmetic_unlock_rules.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/domain/models/progression_node_definition.dart';
import '../../progression_engine/domain/models/unlock_condition.dart';
import '../../progression_engine/domain/policy/level_policy.dart';

/// Devtools shim around [Companion] for the state matrix. Reuses the
/// canonical [CompanionState] (hidden / partial / claimable / claimed)
/// — devtools just adds the transition machinery on top.
///
/// Detection composes [CompanionsRegistry.byId] so the matrix sees
/// **exactly** what the inventory grid sees. There is no second source
/// of truth here; the matrix only differs from the player-facing UI in
/// that it can drive state changes through engine + cosmetics
/// primitives.
class CompanionDevController {
  CompanionDevController({
    required this.cosmetics,
    required this.progression,
  });

  final CosmeticsProvider cosmetics;
  final ProgressionEngineProvider progression;

  /// Returns every authored `CompanionAvailabilityNode`, in catalog
  /// order. Used by the matrix UI to enumerate rows even before any
  /// player state has loaded — see [CompanionsRegistry.allNodes].
  static List<CompanionAvailabilityNode> allCompanions() =>
      CompanionsRegistry.allNodes;

  /// `LevelAtLeast` requirement parsed off the companion's V2 unlock
  /// conditions — companions always carry exactly one (see
  /// `companions_content.dart`).
  static int? gateLevelFor(CompanionAvailabilityNode node) {
    for (final c in node.unlockConditions) {
      if (c is LevelAtLeast) return c.level;
    }
    return null;
  }

  /// Achievement node ids that gate the companion (each grants one
  /// of the relic cosmetics through its reward table).
  static List<String> gatingNodeIds(CompanionAvailabilityNode node) {
    return [
      for (final c in node.unlockConditions)
        if (c is NodeCompleted) c.nodeId,
    ];
  }

  /// Live snapshot of the companion's lifecycle state — same
  /// resolution path the inventory grid uses, no devtools-only
  /// branch. Returns [CompanionState.hidden] as a safe fallback
  /// when cosmetics state hasn't bound yet.
  CompanionState detect(CompanionAvailabilityNode node) {
    final state = cosmetics.state;
    if (state == null) return CompanionState.hidden;
    final revealResults =
        cosmetics.computeRevealResults(kCosmeticUnlockRules);
    final companion = const CompanionsRegistry().byId(
      node.companionId,
      unlockedCosmeticIds: state.unlocked.keys.toSet(),
      availableNodeIds: progression.availableNodeIds,
      revealResults: revealResults,
    );
    return companion?.state ?? CompanionState.hidden;
  }

  /// Best-effort transition from the companion's current state to
  /// [target].
  ///
  /// Truth lives in three stores (cosmetics repo, engine ledger,
  /// reveal evaluator); the controller can only write through the
  /// available primitives:
  ///
  ///   * `cosmetics.debugGrantCosmetic` / `debugRevokeCosmetic`
  ///   * `progression.devToolsAddXp` / `devToolsForceCompleteNode`
  ///
  /// The engine has no "uncomplete" primitive — once a gating
  /// achievement is in the ledger it cannot be erased non-
  /// destructively. So downward transitions (claimed → partial,
  /// claimable → hidden) are best-effort: the cosmetics side is
  /// reset cleanly, the engine side may keep the companion in
  /// `available`. [detect] re-reads after the call so the matrix
  /// always shows the **actual** outcome — never the requested
  /// target unless they coincide.
  Future<void> applyState(
    CompanionAvailabilityNode node,
    CompanionState target,
  ) async {
    final gate = gateLevelFor(node) ?? 1;
    final relicIds = companionRelicGateIds(node.companionId);
    final gatingNodes = gatingNodeIds(node);

    // Always clean-slate the cosmetics side so the reveal
    // evaluator's "satisfied conditions" count reflects the target
    // rather than the previous state. Engine state stays untouched
    // on this pre-pass — see the per-target branches below for the
    // narrow engine writes.
    await cosmetics.debugRevokeCosmetic(node.companionId);
    for (final relicId in relicIds) {
      await cosmetics.debugRevokeCosmetic(relicId);
    }

    switch (target) {
      case CompanionState.hidden:
      case CompanionState.partial:
        // Cosmetics-only transition. Lowering the engine level is
        // intentionally NOT attempted — the only available primitive
        // (`devToolsSetLevel`) wipes the ledger via
        // [devToolsSetTotalXp] and replays every prior celebration
        // on the next refresh, which is far worse UX than letting
        // the reveal evaluator's best effort apply. The evaluator
        // branches on:
        //   • owned relics → satisfied-count
        //   • current level vs `gate − 10` → hidden vs teaser
        // so at high player levels the requested state may resolve
        // as `partial` even when "Hidden" was selected. [detect]
        // re-reads the actual state after the transition so the
        // UI reflects the real outcome.
        if (target == CompanionState.partial && relicIds.isNotEmpty) {
          // Grant exactly one gating relic so the reveal evaluator
          // reports `partial` with one tick on the requirements
          // checklist.
          await cosmetics.debugGrantCosmetic(relicIds.first);
        }
      case CompanionState.claimable:
        // Two requirements for `claimable`:
        //   1. Engine level ≥ gate so `LevelAtLeast(gate)` resolves
        //      true. We add XP additively — never wipe — so existing
        //      pending celebrations / completion history stay intact.
        //   2. Both gating achievement nodes completed. Only force-
        //      complete the ones the player hasn't already cleared
        //      organically; force-completing an already-completed
        //      node is a no-op at the engine layer but still costs
        //      a refresh, and we'd rather skip the churn.
        if (progression.level < gate) {
          const policy = ProgressionLevelPolicy();
          final targetXp = policy.xpRequiredForLevel(gate);
          final delta = targetXp - progression.totalXp;
          if (delta > 0) {
            await progression.devToolsAddXp(delta);
          }
        }
        final completedIds = progression.completedNodeIds;
        for (final nodeId in gatingNodes) {
          if (completedIds.contains(nodeId)) continue;
          await progression.devToolsForceCompleteNode(nodeId);
        }
      case CompanionState.claimed:
        // Bypass the claim animation entirely — devtools cares about
        // the resulting state, not the moment. The cosmetic provider
        // marks the companion as unlocked which causes the reveal
        // evaluator to report `unlocked` and `consumedRelicIds` to
        // count the relics as used.
        await cosmetics.debugGrantCosmetic(node.companionId);
    }
  }
}
