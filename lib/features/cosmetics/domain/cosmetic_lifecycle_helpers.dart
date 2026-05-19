import 'cosmetic_models.dart';
import 'player_cosmetic_lifecycle.dart';

/// Per-spec helper from `docs/domain_model/proposal.md` §4.3.
///
/// Companion artwork + name must stay concealed until the player has
/// claimed the cosmetic — the reveal moment lands inside the claim
/// flow. The rule is **not** a lifecycle state: it is a pattern-match
/// over `(catalog subtype, lifecycle subtype)`. Phase 10 + Phase 11
/// move every consumer onto this helper so the legacy
/// `CompanionState.hidesIdentity` boolean and its sibling enum can
/// retire.
///
/// Returns true when the widget should render a mystery silhouette
/// instead of the real cosmetic asset / name. Today only applies to
/// `Companion` cosmetics; non-companion subtypes show their identity
/// in every state.
///
/// **Why a top-level function, not a method.** Widgets pass both the
/// catalog row and the lifecycle slice they already have on hand;
/// adding a `hidesIdentity` getter to either type would force a
/// reverse dependency (lifecycle → catalog or vice versa). The pair
/// is the natural operand, so a free function keeps the surface
/// minimal.
bool hidesIdentity(Cosmetic catalog, PlayerCosmeticLifecycle lifecycle) {
  if (catalog is! Companion) return false;
  return lifecycle is! CosmeticOwned;
}

/// Per-spec helper from `docs/domain_model/proposal.md` §4.3.
///
/// True for any lifecycle where the requirements checklist makes sense
/// to render — i.e. anything except the mystery / silhouette state.
/// Companion cards lean on this to decide whether to surface the
/// progress chip + condition rows in the details sheet.
bool showsChecklist(PlayerCosmeticLifecycle lifecycle) => switch (lifecycle) {
      CosmeticHidden() => false,
      CosmeticTeased() ||
      CosmeticClaimable() ||
      CosmeticOwned() =>
        true,
    };
