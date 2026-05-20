import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum XpClaimPillState { locked, claimable, claimed }

class XpClaimPillData {
  const XpClaimPillData.locked(this.xp, {this.companionBonus = 0})
      : state = XpClaimPillState.locked,
        onTap = null;

  const XpClaimPillData.claimable(
    this.xp, {
    required this.onTap,
    this.companionBonus = 0,
  }) : state = XpClaimPillState.claimable;

  const XpClaimPillData.claimed(this.xp, {this.companionBonus = 0})
      : state = XpClaimPillState.claimed,
        onTap = null;

  final int xp;
  final XpClaimPillState state;
  final void Function(Offset center)? onTap;

  /// Companion-buff bonus the player will earn (claimable / locked
  /// states project it from the equipped buff) or already earned
  /// (claimed state, read from the journal grant). When `> 0` the
  /// pill renders a small XP-tinted micro chip beside the headline
  /// so the player sees the equipped companion's contribution the
  /// moment they look at the card — no celebration overlay needed.
  /// Zero hides the chip entirely.
  final int companionBonus;

  bool get isClaimable => state == XpClaimPillState.claimable;
  bool get isClaimed => state == XpClaimPillState.claimed;
}

class XpClaimPill extends StatelessWidget {
  const XpClaimPill({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.claimedLabel,
  });

  final XpClaimPillData data;
  final EdgeInsetsGeometry padding;
  final String? claimedLabel;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final appearance = switch (data.state) {
      XpClaimPillState.claimable => (
          color: ft.xp,
          bg: ft.xp.withValues(alpha: 0.18),
          border: ft.xp.withValues(alpha: 0.35),
          icon: Icons.bolt_rounded,
          label: '+${data.xp} XP',
        ),
      XpClaimPillState.locked => (
          color: ft.onSurfaceMuted,
          bg: ft.onSurface.withValues(alpha: 0.09),
          border: ft.onSurface.withValues(alpha: 0.16),
          icon: Icons.lock_outline_rounded,
          label: '${data.xp} XP',
        ),
      XpClaimPillState.claimed => (
          color: ft.onSurfaceMuted,
          bg: ft.onSurface.withValues(alpha: 0.09),
          border: ft.onSurface.withValues(alpha: 0.16),
          icon: Icons.check_rounded,
          label: claimedLabel ?? '+${data.xp} XP',
        ),
    };

    final headline = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: appearance.bg,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: appearance.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, size: 10, color: appearance.color),
          const SizedBox(width: 2),
          Text(
            appearance.label,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: appearance.color,
            ),
          ),
        ],
      ),
    );

    // Compose the headline pill with an optional secondary "+N"
    // companion chip stacked below it. Stacking (vs side-by-side)
    // keeps endgame rows readable — at level 100 the XP headline
    // can read "🔒 7500 XP" and the chip "🐾 +375", both wide enough
    // that side-by-side crowds against the rest of the quest card.
    // Right-aligned so they form a coherent column.
    final Widget child;
    if (data.companionBonus > 0) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          headline,
          const SizedBox(height: 3),
          _CompanionBonusChip(
            amount: data.companionBonus,
            state: data.state,
          ),
        ],
      );
    } else {
      child = headline;
    }

    if (!data.isClaimable || data.onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final box = context.findRenderObject() as RenderBox?;
        final center = box == null
            ? Offset.zero
            : box.localToGlobal(Offset.zero) +
                Offset(box.size.width / 2, box.size.height / 2);
        data.onTap!(center);
      },
      child: child,
    );
  }
}

/// Small chip rendered beneath the [XpClaimPill] when the equipped
/// companion contributes a buff bonus to the grant. Uses a paw icon
/// (companion semantic) and follows the headline's state colour:
/// claimable / locked → XP gold so the chip reads as "and an extra
/// N from your companion"; claimed → muted grey to match the
/// already-greyed main pill (the bonus is banked in the ledger and
/// the player's eye doesn't need pulling back to it).
class _CompanionBonusChip extends StatelessWidget {
  const _CompanionBonusChip({required this.amount, required this.state});

  final int amount;
  final XpClaimPillState state;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final isClaimed = state == XpClaimPillState.claimed;
    final tint = isClaimed ? ft.onSurfaceMuted : ft.xp;
    final fg = isClaimed
        ? ft.onSurfaceMuted
        : ft.xp.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: isClaimed ? 0.09 : 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(
          color: tint.withValues(alpha: isClaimed ? 0.16 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pets_rounded,
            size: 10,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            '+$amount',
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
