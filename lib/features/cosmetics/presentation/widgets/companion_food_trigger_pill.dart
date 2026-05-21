import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/food_trigger_service.dart';

/// Claim pill for a companion's [FoodTriggerReward]. Renders only the
/// **claimable** state per the product call — locked and claimed
/// states stay hidden. The caller is expected to gate visibility on
/// `snapshot.hasClaimable`; the pill is opinionated about its own
/// presence (no "0 XP" fallback) so a misuse is loud, not silent.
///
/// Visual: short XP-gold pill with a subtle pulse on the leading
/// icon so the player notices the new affordance without it shouting
/// like a quest reward. Matches the muted-ambient style the rest of
/// the hero header uses (`Tokens.xp` over a low-alpha surface, no
/// rarity tint — this is XP gain, not rarity flex).
class CompanionFoodTriggerPill extends StatelessWidget {
  const CompanionFoodTriggerPill({
    super.key,
    required this.snapshot,
    required this.onClaim,
    this.isBusy = false,
  });

  /// Snapshot to render. Must have `hasClaimable == true` — callers
  /// that pass a zero-claimable snapshot will see an assertion in
  /// debug.
  final FoodTriggerSnapshot snapshot;

  /// Invoked when the user taps the pill. Disabled (visually muted)
  /// when [isBusy] is true so a double-tap during the engine append
  /// can't fire a duplicate claim.
  final VoidCallback onClaim;

  /// Set by the parent while the food-trigger provider is mid-claim.
  /// Decouples the pill from any specific async state machine.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    assert(snapshot.hasClaimable,
        'CompanionFoodTriggerPill is claim-only — hide when claimableXp == 0');
    final l10n = context.l10n;
    final label = _label(l10n);

    return Opacity(
      opacity: isBusy ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onClaim,
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Tokens.xp.withValues(alpha: 0.16),
              borderRadius:
                  BorderRadius.circular(Tokens.radiusProgress),
              border: Border.all(
                color: Tokens.xp.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Tokens.xpGlow,
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: Tokens.xp,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Tokens.xp,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n) {
    return l10n.companionFoodTriggerPillLabel(snapshot.claimableXp);
  }
}

/// Settled / claimed-today variant of [CompanionFoodTriggerPill].
/// Renders once the player has drained every claim for the day (no
/// new matching entries since the last claim) so the surface still
/// communicates "you got XP for that meal" instead of vanishing
/// silently. Mirrors the check-circle + amount shape that quest
/// cards use for their `QuestClaimed` state.
///
/// Static (no tap, no glow, no busy state) — same accent as the
/// claimable pill but at reduced intensity so the eye reads it as
/// settled rather than asking for action.
class CompanionFoodTriggerClaimedPill extends StatelessWidget {
  const CompanionFoodTriggerClaimedPill({super.key, required this.claimedXp});

  /// Total XP claimed today via this companion's food trigger.
  /// Must be positive; callers gate visibility on
  /// `snapshot.alreadyClaimedXp > 0`.
  final int claimedXp;

  @override
  Widget build(BuildContext context) {
    assert(claimedXp > 0,
        'CompanionFoodTriggerClaimedPill renders the claimed-today state — '
        'hide when alreadyClaimedXp == 0');
    final l10n = context.l10n;
    final label = l10n.companionFoodTriggerPillClaimedLabel(claimedXp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Tokens.xp.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(
          color: Tokens.xp.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: Tokens.xp.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Tokens.xp.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
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
