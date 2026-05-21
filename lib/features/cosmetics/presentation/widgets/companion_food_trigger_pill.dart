import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../../../shared/widgets/xp_sparkle_overlay.dart';
import '../../application/food_trigger_service.dart';

/// Hero-header surface for a companion's [FoodTriggerReward].
/// Thin wrapper over the shared [XpClaimPill] so the food-trigger
/// states render in lockstep with quest / chapter / long-term card
/// pills (same colors, same shape, same icons, same "+N XP" label).
///
/// Snapshot-driven state pick:
///   * `claimableXp > 0`            → [XpClaimPillData.claimable]
///   * `alreadyClaimedXp > 0`       → [XpClaimPillData.claimed]
///   * both zero                    → renders nothing
/// Locked state is intentionally never rendered — the player only
/// hears about the trigger once they've earned it.
///
/// `isBusy` swallows the tap during the engine append so a double-
/// click can't fire a duplicate claim; the visual cue lives in the
/// pill's own claimable styling, not in a separate spinner.
class CompanionFoodTriggerPill extends StatelessWidget {
  const CompanionFoodTriggerPill({
    super.key,
    required this.snapshot,
    required this.onClaim,
    this.sparkleTargetKey,
    this.isBusy = false,
  });

  final FoodTriggerSnapshot snapshot;
  final VoidCallback onClaim;

  /// XP-bar key the sparkle animation should fly toward when the
  /// player taps the claimable pill — same target the quest /
  /// chapter / long-term pills use on their respective screens. Null
  /// disables the sparkle (the claim still runs); kept optional so
  /// the widget remains usable on surfaces without a visible XP bar.
  final GlobalKey? sparkleTargetKey;

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final claimable = snapshot.claimableXp;
    final claimed = snapshot.alreadyClaimedXp;
    if (claimable <= 0 && claimed <= 0) {
      return const SizedBox.shrink();
    }

    final data = claimable > 0
        ? XpClaimPillData.claimable(
            claimable,
            // XpClaimPill hands back the pill's center offset so we
            // can launch the XP sparkle from the same spot every
            // other claim pill in the app does. Launch first, then
            // fire the claim — the sparkle runs against pre-claim
            // state but visually meets the bar just as the engine
            // append lands, matching `_claimQuest` on quests_screen.
            onTap: isBusy
                ? (_) {}
                : (center) {
                    final target = sparkleTargetKey;
                    if (target != null) {
                      XpSparkleLauncher.launchToKey(
                        context,
                        from: center,
                        targetKey: target,
                      );
                    }
                    onClaim();
                  },
          )
        : XpClaimPillData.claimed(claimed);

    return Opacity(
      opacity: isBusy && claimable > 0 ? 0.55 : 1.0,
      child: XpClaimPill(data: data),
    );
  }
}

/// Tiny gold dot rendered next to the expand chevron when the hero
/// header is collapsed and there is something to claim. Pulses gently
/// to draw the eye without becoming a notification badge.
///
/// Visibility is the caller's responsibility — the dot has no own
/// "show / hide" logic so it stays a dumb visual.
class CompanionFoodTriggerDot extends StatefulWidget {
  const CompanionFoodTriggerDot({super.key, this.size = 7});

  final double size;

  @override
  State<CompanionFoodTriggerDot> createState() =>
      _CompanionFoodTriggerDotState();
}

class _CompanionFoodTriggerDotState extends State<CompanionFoodTriggerDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final glow = 0.45 + 0.35 * t;
        final scale = 0.92 + 0.18 * t;
        return SizedBox(
          width: widget.size + 6,
          height: widget.size + 6,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Tokens.xp,
                  boxShadow: [
                    BoxShadow(
                      color: Tokens.xp.withValues(alpha: glow),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
