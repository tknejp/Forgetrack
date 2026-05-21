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
