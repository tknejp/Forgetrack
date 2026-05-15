import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/models/celebration_event.dart';
import '../../../domain/models/celebration_reward.dart';

/// Square 64×64 icon badge that lives in the topsheet header. The color is
/// driven by [CelebrationType], not rarity — that's the whole point of the
/// type/rarity decoupling. Includes a one-shot pop animation on entry.
class TypeIconSquare extends StatefulWidget {
  const TypeIconSquare({
    super.key,
    required this.type,
    required this.accent,
    this.size = 64,
    this.iconSize = 32,
  });

  final CelebrationType type;

  /// Tint color for the badge background, border, glow and icon. The
  /// glyph is still picked from [type] so the icon language stays
  /// type-driven; only the colour follows the celebration's head rarity
  /// to keep the UI from accidentally reading legendary gold for a
  /// rare-rarity level milestone, etc.
  final Color accent;
  final double size;
  final double iconSize;

  @override
  State<TypeIconSquare> createState() => _TypeIconSquareState();
}

class _TypeIconSquareState extends State<TypeIconSquare>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final icon = _iconForType(widget.type);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Pop curve: scale 0.6 → 1.08 → 1.0, rotate -8° → 2° → 0°.
        final t = _controller.value;
        final scale = t < 0.6
            ? 0.6 + (1.08 - 0.6) * (t / 0.6)
            : 1.08 - (1.08 - 1.0) * ((t - 0.6) / 0.4);
        final rot = t < 0.6
            ? (-8.0 + (2.0 - -8.0) * (t / 0.6))
            : 2.0 - 2.0 * ((t - 0.6) / 0.4);
        return Transform.rotate(
          angle: rot * 3.1415926535 / 180.0,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.20),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.40)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: accent, size: widget.iconSize),
        ),
      ),
    );
  }
}

/// Smaller pill (icon + uppercase label) used at the top-left of fullscreen
/// reward cards.
class TypeBadgePill extends StatelessWidget {
  const TypeBadgePill({
    super.key,
    required this.type,
    required this.label,
  });

  final CelebrationType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = accentForType(type).color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForType(type), color: accent, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-style badge for fullscreen cards. Coloured by the **rarity** so the
/// badge matches the card's accent (instead of inheriting an unrelated
/// celebration-type colour) and labelled by the reward's kind.
class RewardKindBadgePill extends StatelessWidget {
  const RewardKindBadgePill({
    super.key,
    required this.kind,
    required this.label,
    required this.color,
  });

  final CelebrationRewardKind kind;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForRewardKind(kind), color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single source of truth for the glyph representing a [CelebrationRewardKind].
/// Shared between the small kind pill (fullscreen card) and the larger reward
/// thumb (topsheet rows) so both surfaces speak the same visual language.
IconData iconForRewardKind(CelebrationRewardKind kind) {
  switch (kind) {
    case CelebrationRewardKind.sparkle:
      return Icons.auto_awesome_rounded;
    case CelebrationRewardKind.xp:
      return Icons.bolt_rounded;
    case CelebrationRewardKind.title:
      return Icons.military_tech_rounded;
    case CelebrationRewardKind.badge:
      return Icons.shield_rounded;
    case CelebrationRewardKind.flame:
      return Icons.local_fire_department_rounded;
    case CelebrationRewardKind.flag:
      return Icons.flag_rounded;
    case CelebrationRewardKind.location:
      return Icons.place_rounded;
    case CelebrationRewardKind.frame:
      return Icons.crop_square_rounded;
    case CelebrationRewardKind.background:
      return Icons.landscape_rounded;
    case CelebrationRewardKind.companion:
      return Icons.pets_rounded;
    case CelebrationRewardKind.gem:
      return Icons.diamond_rounded;
  }
}

CelebrationTypeAccent accentForType(CelebrationType type) {
  switch (type) {
    case CelebrationType.achievement:
      return CelebrationTypeAccent.achievement;
    case CelebrationType.quest:
      return CelebrationTypeAccent.quest;
    case CelebrationType.level:
      return CelebrationTypeAccent.level;
    case CelebrationType.title:
      return CelebrationTypeAccent.title;
    case CelebrationType.streak:
      return CelebrationTypeAccent.streak;
    case CelebrationType.location:
      return CelebrationTypeAccent.location;
    case CelebrationType.cosmetic:
      return CelebrationTypeAccent.cosmetic;
  }
}

IconData _iconForType(CelebrationType type) {
  switch (type) {
    case CelebrationType.achievement:
      return Icons.workspace_premium_rounded;
    case CelebrationType.quest:
      return Icons.flag_rounded;
    case CelebrationType.level:
      return Icons.bolt_rounded;
    case CelebrationType.title:
      return Icons.military_tech_rounded;
    case CelebrationType.streak:
      return Icons.local_fire_department_rounded;
    case CelebrationType.location:
      return Icons.place_rounded;
    case CelebrationType.cosmetic:
      return Icons.auto_awesome_rounded;
  }
}
