import 'package:flutter/material.dart';

import '../../domain/cosmetic_models.dart';
import 'companion_claim_reveal.dart';

/// State-machine entry widget for the companion claim flow.
///
/// Owns the four animation phases (`ready → forging → morphing → detail`)
/// that drive the hi-fi claim experience. The surrounding
/// [CosmeticDetailsSheet] renders the sheet shell (handle / badge /
/// title / hint); this widget renders only the interactive stage +
/// CTA, and (in later phases) the fullscreen forging overlay and
/// morphing handoff.
///
/// **C1 scope:** state machine is set up, but only the `ready` phase
/// is active — its body delegates to the existing
/// [CompanionClaimReveal] so the user-visible behavior is unchanged.
/// The forging timeline (C2), morphing handoff (C3) and in-flow
/// detail body (C4) plug in by replacing the placeholder branches.
enum CompanionClaimPhase {
  /// Resting state: silhouette + relic tiles + primary CTA.
  ready,

  /// Fullscreen ritual overlay (Orbita variant, 5.4 s).
  forging,

  /// 1.15 s handoff from overlay center → detail-sheet companion slot.
  morphing,

  /// Final companion details body (title / tags / unlock date /
  /// description / Vybavit CTA).
  detail,
}

class CompanionClaimFlow extends StatefulWidget {
  const CompanionClaimFlow({
    super.key,
    required this.companion,
    required this.relicIds,
    required this.color,
    required this.onClaim,
  });

  /// Companion catalog row — drives the silhouette → real-asset
  /// cross-fade and downstream detail rendering.
  final Cosmetic companion;

  /// Relic ids that gate the companion. Empty is allowed; the
  /// preview falls back to a generic glow ring.
  final List<String> relicIds;

  /// Accent color (typically the companion's rarity color).
  final Color color;

  /// Engine claim hook. Called when the forging timeline reaches the
  /// reveal point. Parent should call `progression.claimNode(...)`.
  final Future<void> Function() onClaim;

  @override
  State<CompanionClaimFlow> createState() => _CompanionClaimFlowState();
}

class _CompanionClaimFlowState extends State<CompanionClaimFlow> {
  // Mutated by phase transitions landing in C2 (forging) /
  // C3 (morphing) / C4 (detail). Kept non-final so those commits
  // don't need to touch this declaration.
  CompanionClaimPhase _phase = CompanionClaimPhase.ready; // ignore: prefer_final_fields

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case CompanionClaimPhase.ready:
        return CompanionClaimReveal(
          companion: widget.companion,
          relicIds: widget.relicIds,
          color: widget.color,
          onClaim: widget.onClaim,
        );
      case CompanionClaimPhase.forging:
      case CompanionClaimPhase.morphing:
      case CompanionClaimPhase.detail:
        // Phases land in C2 / C3 / C4. Until then the parent sheet
        // rebuilds into the regular unlocked layout as soon as the
        // engine grant lands (CosmeticsProvider watch), so the flow
        // widget never actually sits in these phases at runtime.
        return const SizedBox.shrink();
    }
  }
}
