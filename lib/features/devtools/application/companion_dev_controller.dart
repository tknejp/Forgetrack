import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/companion_availability_lookup.dart';
import '../../cosmetics/domain/consumed_relics.dart';
import '../../cosmetics/domain/player_cosmetic_lifecycle.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import '../../progression_engine/domain/catalog/granting_achievement_lookup.dart';
import '../../progression_engine/domain/policy/level_policy.dart';

/// DevTools-only target state for the companion matrix. Drives the
/// per-row "Hidden / Partial / Claimable / Claimed" button strip and
/// maps onto a write recipe in [CompanionDevController.applyState].
///
/// This is **not** a domain type. The player-facing lifecycle lives
/// in [PlayerCosmeticLifecycle] (4 sealed states); this enum just
/// names the transitions devtools can drive. Phase 11 deleted the
/// shared `CompanionState` enum; the matrix kept its target-button
/// vocabulary because the transitions remain useful for testing.
enum CompanionDevTarget { hidden, partial, claimable, claimed }

/// Devtools controller for the companion state matrix. Reads the
/// canonical [PlayerCosmeticLifecycle] from [CosmeticsProvider]'s
/// inventory projection so the matrix sees exactly what the inventory
/// grid sees â€” no second source of truth.
///
/// The "write" side composes the existing engine + cosmetics
/// primitives:
///
///   * `cosmetics.debugGrantCosmetic` / `debugRevokeCosmetic`
///   * `progression.devToolsAddXp` / `devToolsForceCompleteNode`
///
/// The engine has no "uncomplete" primitive â€” once a gating
/// achievement is in the ledger it cannot be erased non-destructively.
/// So downward transitions (claimed â†’ partial, claimable â†’ hidden) are
/// best-effort. [detect] re-reads after the call so the matrix always
/// shows the **actual** outcome.
class CompanionDevController {
  CompanionDevController({
    required this.cosmetics,
    required this.progression,
  });

  final CosmeticsProvider cosmetics;
  final ProgressionEngineProvider progression;

  /// Returns every authored `CompanionAvailability`, in catalog
  /// order. Used by the matrix UI to enumerate rows even before any
  /// player state has loaded.
  static List<CompanionAvailability> allCompanions() =>
      allCompanionAvailabilities;

  /// `LevelAtLeast` requirement parsed off the companion's V2 unlock
  /// conditions â€” companions always carry exactly one (see
  /// `companions_content.dart`).
  static int? gateLevelFor(CompanionAvailability node) {
    for (final c in node.unlockConditions) {
      if (c is LevelAtLeast) return c.level;
    }
    return null;
  }

  /// Progression node ids whose completion grants the relic cosmetics
  /// that gate this companion's claim. Walks the companion's
  /// `OwnsCosmetic(relic_id)` unlock conditions (the canonical gate
  /// shape since the Trello #76 phase-A `OwnsCosmetic` refactor, commit
  /// `185971a`) and maps each relic id back to the catalog node whose
  /// reward table produces it via [grantingNodeForCosmetic] (typically
  /// an Achievement granting the relic via its `CosmeticReward`).
  ///
  /// Relics with no catalog-side granting node (devtools-only relics,
  /// shipped pre-unlocked content) drop silently — the matrix's
  /// `claimable` target then can't force-complete them through the
  /// engine, and falls back to leaving the cosmetics inventory as the
  /// only path to "owned" for those entries.
  static List<String> gatingNodeIds(CompanionAvailability node) {
    final out = <String>[];
    for (final c in node.unlockConditions) {
      if (c is! OwnsCosmetic) continue;
      final grantingNode = grantingNodeForCosmetic(c.cosmeticId);
      if (grantingNode != null) out.add(grantingNode);
    }
    return out;
  }

  /// Live snapshot of the companion's lifecycle â€” same projection the
  /// inventory grid uses, no devtools-only branch. Returns
  /// [CosmeticHidden] as a safe fallback when cosmetics state hasn't
  /// bound yet.
  PlayerCosmeticLifecycle detect(CompanionAvailability node) {
    final state = cosmetics.state;
    if (state == null) return const CosmeticHidden();
    final inventory = cosmetics.buildInventory(
      claimableNodeIds: progression.availableNodeIds,
    );
    return inventory.byIdString(node.companionId)?.lifecycle ??
        const CosmeticHidden();
  }

  /// Best-effort transition from the companion's current state to
  /// [target].
  ///
  /// Truth lives in three stores (cosmetics repo, engine ledger,
  /// reveal evaluator); the controller writes through the available
  /// primitives only. The engine has no "uncomplete" primitive so
  /// downward transitions may not fully reset.
  Future<void> applyState(
    CompanionAvailability node,
    CompanionDevTarget target,
  ) async {
    final gate = gateLevelFor(node) ?? 1;
    final relicIds = companionRelicGateIds(node.companionId);
    final gatingNodes = gatingNodeIds(node);

    // Always clean-slate the cosmetics side so the reveal
    // evaluator's "satisfied conditions" count reflects the target
    // rather than the previous state. Engine state stays untouched
    // on this pre-pass â€” see the per-target branches below for the
    // narrow engine writes.
    // The companion itself is always revoked first — every target
    // except `claimed` wants the player to NOT own the companion.
    // Relic mutations live inside the per-target switch because
    // each target wants a different inventory shape; with the
    // OwnsCosmetic refactor (Trello #76 phase A) the engine reads
    // relic ownership directly from the cosmetics inventory, so a
    // pre-pass that revoked relics for every target wiped the very
    // condition we were about to verify on the `claimable` path
    // (Trello #92 root cause).
    await cosmetics.debugRevokeCosmetic(node.companionId);

    switch (target) {
      case CompanionDevTarget.hidden:
      case CompanionDevTarget.partial:
        // Revoke all gating relics — Hidden wants zero owned;
        // Partial wants exactly one (granted below).
        for (final relicId in relicIds) {
          await cosmetics.debugRevokeCosmetic(relicId);
        }
        // Cosmetics-only transition. Lowering the engine level is
        // intentionally NOT attempted â€” the only available primitive
        // (`devToolsSetLevel`) wipes the ledger via
        // [devToolsSetTotalXp] and replays every prior celebration
        // on the next refresh, which is far worse UX than letting
        // the reveal evaluator's best effort apply. The evaluator
        // branches on:
        //   â€¢ owned relics â†’ satisfied-count
        //   â€¢ current level vs `gate âˆ’ 10` â†’ hidden vs teaser
        // so at high player levels the requested state may resolve
        // as `partial` even when "Hidden" was selected. [detect]
        // re-reads the actual state after the transition so the
        // UI reflects the real outcome.
        if (target == CompanionDevTarget.partial && relicIds.isNotEmpty) {
          // Grant exactly one gating relic so the reveal evaluator
          // reports `partial` with one tick on the requirements
          // checklist.
          await cosmetics.debugGrantCosmetic(relicIds.first);
        }
      case CompanionDevTarget.claimable:
        // Two requirements for `claimable`:
        //   1. Engine level â‰¥ gate so `LevelAtLeast(gate)` resolves
        //      true. We add XP additively â€” never wipe â€” so existing
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
        // Fallback: when the granting achievement is already in the
        // ledger from prior testing, `simulateClaim` writes an
        // idempotent `ObjectiveCompletionEvent`, the engine sees the
        // existing `NodeCompletionEvent` and emits no new reward
        // grants, the bridge dispatch sees an empty
        // `result.grantedRewards`, and the relic stays absent from
        // the inventory — companion lands in Partial 1/3 (level
        // only) instead of Claimable. Sweep the inventory after the
        // engine-routed path and `debugGrantCosmetic` any relic the
        // dispatch missed. Idempotent on relics that did land
        // naturally.
        final ownedNow =
            cosmetics.state?.unlocked.keys.toSet() ?? const <String>{};
        for (final relicId in relicIds) {
          if (ownedNow.contains(relicId)) continue;
          await cosmetics.debugGrantCosmetic(relicId);
        }
      case CompanionDevTarget.claimed:
        // Bypass the claim animation entirely â€” devtools cares about
        // the resulting state, not the moment. The cosmetic provider
        // marks the companion as unlocked which causes the reveal
        // evaluator to report `unlocked` and `consumedRelicIds` to
        // count the relics as used.
        await cosmetics.debugGrantCosmetic(node.companionId);
    }
  }
}
