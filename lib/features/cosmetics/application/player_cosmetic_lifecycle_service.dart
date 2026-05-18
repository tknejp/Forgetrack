import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_state.dart';
import '../domain/ids.dart';
import '../domain/inventory.dart';
import '../domain/player_cosmetic.dart';
import '../domain/player_cosmetic_lifecycle.dart';

/// Builds an [Inventory] read projection from engine primitives
/// (catalog rows + the legacy unlocked map + reveal-evaluator results +
/// engine-surfaced manual-claim node ids).
///
/// **Why primitive inputs, not the engine view-model.** Phase 8 set the
/// precedent: services live in `application/` and take pure primitives
/// so the projection surface stays decoupled from widget-bound chrome
/// (Flutter / l10n / providers). The current cosmetic inputs are
/// already non-widget value classes — `UnlockedCosmetic`,
/// `CosmeticRevealResult`, the available-node id set — so the service
/// reads them directly. When Phase 20 lands the Journal projection
/// rebuild path the inputs swap to `JournalEvent` slices without
/// changing the public API.
///
/// **Precedence (per proposal §4.3, with the spec's CompanionState
/// resolution order folded in).**
///
///   1. **Owned** — `unlocked.containsKey(id)`. Idempotent + terminal.
///   2. **Claimable** — `claimableNodeIds.contains(id)` AND the
///      cosmetic is a [Companion]. Today the only producer of
///      claimables is `CompanionAvailability`; the catalog-side guard
///      keeps non-companion grants from accidentally surfacing as
///      claimable when the engine fires an availability node for a
///      bug-shared id.
///   3. **Teased (partial)** — reveal evaluator says `partial`. The
///      lifecycle carries `satisfied / total / rows` from the
///      evaluator's result.
///   4. **Teased (no progress)** — reveal evaluator says
///      `visibleLocked`. Empty progress chip; companion-teaser rows
///      forwarded when present.
///   5. **Hidden** — fallback. Reveal evaluator said `hidden` or the
///      cosmetic is disabled / not enabled in this build.
///
/// Phase 11 deletes `CompanionState` + `CompanionsRegistry` once every
/// widget switches to pattern-matching on this lifecycle.
class PlayerCosmeticLifecycleService {
  const PlayerCosmeticLifecycleService();

  /// Build an [Inventory] from primitives.
  ///
  ///   - [catalog]: the cosmetics catalog. Only `isEnabled` rows are
  ///     projected; disabled rows resolve to [CosmeticHidden] and stay
  ///     out of the inventory entirely (consistent with the reveal
  ///     evaluator's `catalog.enabled` filter).
  ///   - [unlocked]: keyed by cosmetic id String — typically
  ///     `UserCosmeticsState.unlocked`. Drives the [CosmeticOwned]
  ///     branch.
  ///   - [revealResults]: per-cosmetic reveal state from the reveal
  ///     evaluator. Keyed by cosmetic id String. May be empty before
  ///     the first evaluator run; missing entries collapse to
  ///     [CosmeticHidden] (defensive default — the evaluator emits a
  ///     result for every enabled catalog row).
  ///   - [claimableNodeIds]: node ids the engine has surfaced as
  ///     manually claimable (`ProgressionEngineProvider.availableNodeIds`).
  ///     Only companions cross-reference via id == cosmeticId.
  ///   - [evaluatedAt]: stamped on every projected entry.
  Inventory build({
    required CosmeticCatalog catalog,
    required Map<String, UnlockedCosmetic> unlocked,
    required Map<String, CosmeticRevealResult> revealResults,
    required Set<String> claimableNodeIds,
    required DateTime evaluatedAt,
  }) {
    final entries = <PlayerCosmetic>[];
    for (final def in catalog.enabled) {
      final lifecycle = _resolveLifecycle(
        def: def,
        unlocked: unlocked,
        reveal: revealResults[def.id],
        claimableNodeIds: claimableNodeIds,
      );
      entries.add(
        PlayerCosmetic(
          id: CosmeticId(def.id),
          lifecycle: lifecycle,
          evaluatedAt: evaluatedAt,
        ),
      );
    }
    return Inventory.fromEntries(entries);
  }

  PlayerCosmeticLifecycle _resolveLifecycle({
    required Cosmetic def,
    required Map<String, UnlockedCosmetic> unlocked,
    required CosmeticRevealResult? reveal,
    required Set<String> claimableNodeIds,
  }) {
    final unlock = unlocked[def.id];
    if (unlock != null) {
      return CosmeticOwned(
        unlockedAt: unlock.unlockedAt,
        source: unlock.sourceType,
        sourceId: unlock.sourceId,
      );
    }
    if (def is Companion && claimableNodeIds.contains(def.id)) {
      return CosmeticClaimable(claimVia: def.id);
    }
    if (reveal == null) return const CosmeticHidden();
    switch (reveal.state) {
      case CosmeticRevealState.unlocked:
        // Defensive: the evaluator returns unlocked when ownedIds
        // contains the id. We've already short-circuited on
        // `unlocked[def.id] != null`, so this branch is only reached
        // when the unlocked map and the evaluator's ownedIds set drift
        // — fall back to Hidden rather than synthesising an Owned
        // with no UnlockedCosmetic record.
        return const CosmeticHidden();
      case CosmeticRevealState.partial:
        return CosmeticTeased(
          satisfiedConditions: reveal.satisfiedConditions,
          totalConditions: reveal.totalConditions,
          conditionRows: reveal.conditionRows,
        );
      case CosmeticRevealState.visibleLocked:
        return CosmeticTeased(
          satisfiedConditions: 0,
          totalConditions: 0,
          conditionRows: reveal.conditionRows,
        );
      case CosmeticRevealState.hidden:
        return const CosmeticHidden();
    }
  }
}
