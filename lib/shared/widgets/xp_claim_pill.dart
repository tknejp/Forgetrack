import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum XpClaimPillState { locked, claimable, claimed }

class XpClaimPillData {
  const XpClaimPillData.locked(this.xp)
      : state = XpClaimPillState.locked,
        onTap = null;

  const XpClaimPillData.claimable(this.xp, {required this.onTap})
      : state = XpClaimPillState.claimable;

  const XpClaimPillData.claimed(this.xp)
      : state = XpClaimPillState.claimed,
        onTap = null;

  final int xp;
  final XpClaimPillState state;
  final void Function(Offset center)? onTap;

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
          color: ft.sleep.color,
          bg: ft.accent.withValues(alpha: 0.18),
          border: ft.accent.withValues(alpha: 0.35),
          icon: Icons.check_rounded,
          label: claimedLabel ?? '+${data.xp} XP',
        ),
    };

    final child = Container(
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
