import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum XpClaimPillState { locked, claimable, claimed }

class XpClaimPillData {
  const XpClaimPillData.locked(
    this.xp, {
    this.companionBonus = 0,
    this.emblemBonus = 0,
  })  : state = XpClaimPillState.locked,
        onTap = null;

  const XpClaimPillData.claimable(
    this.xp, {
    required this.onTap,
    this.companionBonus = 0,
    this.emblemBonus = 0,
  }) : state = XpClaimPillState.claimable;

  const XpClaimPillData.claimed(
    this.xp, {
    this.companionBonus = 0,
    this.emblemBonus = 0,
  })  : state = XpClaimPillState.claimed,
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

  /// Emblem-buff bonus, additive sibling of [companionBonus]. Rendered
  /// as a second micro chip (shield icon) under the headline whenever
  /// `> 0`, mirroring the companion chrome 1:1 so a claim that fires
  /// both buffs shows both sub-lines at once. See
  /// `docs/emblem_buffs/archive/plan.md` Phase 3.
  final int emblemBonus;

  bool get isClaimable => state == XpClaimPillState.claimable;
  bool get isClaimed => state == XpClaimPillState.claimed;
}

class XpClaimPill extends StatelessWidget {
  const XpClaimPill({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.claimedLabel,
    this.inline = false,
  });

  final XpClaimPillData data;
  final EdgeInsetsGeometry padding;
  final String? claimedLabel;

  /// When true, the companion-bonus chip is rendered to the LEFT of the
  /// headline pill on a single row instead of stacked below it. Used by
  /// dense list rows (e.g. the per-activity rows inside the home
  /// activity card) where vertical space is tight and the chip + pill
  /// together still fit horizontally.
  final bool inline;

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
    final hasCompanion = data.companionBonus > 0;
    final hasEmblem = data.emblemBonus > 0;
    if (hasCompanion || hasEmblem) {
      final chips = <Widget>[
        if (hasCompanion)
          _BuffBonusChip(
            amount: data.companionBonus,
            state: data.state,
            icon: Icons.pets_rounded,
          ),
        if (hasEmblem)
          _BuffBonusChip(
            amount: data.emblemBonus,
            state: data.state,
            icon: Icons.shield_rounded,
          ),
      ];
      if (inline) {
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final chip in chips) ...[
              chip,
              const SizedBox(width: 4),
            ],
            headline,
          ],
        );
      } else {
        child = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            headline,
            for (final chip in chips) ...[
              const SizedBox(height: 3),
              chip,
            ],
          ],
        );
      }
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
/// (companion semantic) and mirrors the headline pill's state
/// colour rules 1:1 — gold for claimable, muted for locked + claimed.
/// Keeping the colours in lockstep means the pair always reads as
/// one unit: when the headline says "you'll get this", the chip
/// says "and an extra N"; when the headline says "locked", the chip
/// says "and you'd get an extra N"; when the headline says "claimed",
/// the chip recedes in matching grey.
class _BuffBonusChip extends StatelessWidget {
  const _BuffBonusChip({
    required this.amount,
    required this.state,
    required this.icon,
  });

  final int amount;
  final XpClaimPillState state;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    // Tint matches the headline pill's appearance for the same
    // state — see the `appearance` switch in [XpClaimPill.build].
    // [tint] is applied to the foreground (icon + text) verbatim so
    // baked-in alpha on tokens like `onSurfaceMuted` (40 % white)
    // survives — modulating with `withValues(alpha: 1.0)` would
    // promote the muted grey to full-opacity white. Background and
    // border get their own alphas applied on top.
    final (Color tint, double bgAlpha, double borderAlpha) = switch (state) {
      XpClaimPillState.claimable => (ft.xp, 0.18, 0.35),
      XpClaimPillState.locked || XpClaimPillState.claimed => (
          ft.onSurfaceMuted,
          0.09,
          0.16,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: tint.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: tint,
          ),
          const SizedBox(width: 3),
          Text(
            '+$amount',
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}
