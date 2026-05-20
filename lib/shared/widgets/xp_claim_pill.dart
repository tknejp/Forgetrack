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
    // micro chip when the equipped companion buff applies. Both are
    // wrapped in a Row so the chip sits adjacent (not inside) the
    // headline's rounded shape.
    final Widget child;
    if (data.companionBonus > 0) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          headline,
          const SizedBox(width: 4),
          _CompanionBonusChip(amount: data.companionBonus),
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

/// Small adjacent chip rendered next to the [XpClaimPill] when the
/// equipped companion contributes a buff bonus to the grant. Uses
/// the same XP gold tone as the main pill so they read as a pair
/// (one says "you'll get / got 50 XP", the chip says "and an extra
/// 4 from your companion"). Kept dimmer than the parent pill so the
/// player's eye lands on the headline first.
class _CompanionBonusChip extends StatelessWidget {
  const _CompanionBonusChip({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ft.xp.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: ft.xp.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 9,
            color: ft.xp.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 2),
          Text(
            '+$amount',
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: ft.xp.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
