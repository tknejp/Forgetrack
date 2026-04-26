import 'package:flutter/material.dart';

import '../../theme/ft_design_tokens.dart';

enum FtXpClaimPillState { locked, claimable, claimed }

class FtXpClaimPillData {
  const FtXpClaimPillData.locked(this.xp)
      : state = FtXpClaimPillState.locked,
        onTap = null;

  const FtXpClaimPillData.claimable(this.xp, {required this.onTap})
      : state = FtXpClaimPillState.claimable;

  const FtXpClaimPillData.claimed(this.xp)
      : state = FtXpClaimPillState.claimed,
        onTap = null;

  final int xp;
  final FtXpClaimPillState state;
  final void Function(Offset center)? onTap;

  bool get isClaimable => state == FtXpClaimPillState.claimable;
  bool get isClaimed => state == FtXpClaimPillState.claimed;
}

class FtXpClaimPill extends StatelessWidget {
  const FtXpClaimPill({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.claimedLabel,
  });

  final FtXpClaimPillData data;
  final EdgeInsetsGeometry padding;
  final String? claimedLabel;

  static const _goldColor = Color(0xFFFFBD2E);
  static const _goldBg = Color(0x2FFFBD2E);
  static const _goldBorder = Color(0x59FFBD2E);
  static const _greyColor = Color(0xFF8E8E9A);
  static const _greyBg = Color(0x18FFFFFF);
  static const _greyBorder = Color(0x28FFFFFF);
  static const _claimedColor = Color(0xFFA89BFF);
  static const _claimedBg = Color(0x2E7C6FFF);
  static const _claimedBorder = Color(0x597C6FFF);

  @override
  Widget build(BuildContext context) {
    final appearance = switch (data.state) {
      FtXpClaimPillState.claimable => (
          color: _goldColor,
          bg: _goldBg,
          border: _goldBorder,
          icon: Icons.bolt_rounded,
          label: '+${data.xp} XP',
        ),
      FtXpClaimPillState.locked => (
          color: _greyColor,
          bg: _greyBg,
          border: _greyBorder,
          icon: Icons.lock_outline_rounded,
          label: '${data.xp} XP',
        ),
      FtXpClaimPillState.claimed => (
          color: _claimedColor,
          bg: _claimedBg,
          border: _claimedBorder,
          icon: Icons.check_rounded,
          label: claimedLabel ?? '+${data.xp} XP',
        ),
    };

    final child = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: appearance.bg,
        borderRadius: BorderRadius.circular(99),
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
              fontSize: FtTokens.fontSizeMicro,
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
