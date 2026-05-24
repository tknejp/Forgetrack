import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Lock-icon placeholder badge used for hidden (???) cosmetics in the
/// grid card. Distinct from `HiddenBadgeLarge` (details-sheet variant).
class CardHiddenBadge extends StatelessWidget {
  const CardHiddenBadge({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: size * 0.5,
          color: color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

/// Small "{satisfied}/{total}" chip overlaid on partial cards.
class CardProgressChip extends StatelessWidget {
  const CardProgressChip({
    super.key,
    required this.satisfied,
    required this.total,
    required this.color,
  });

  final int satisfied;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$satisfied/$total',
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Pulsing "PŘIPRAVEN" pill for a claimable companion card. Uses the
/// companion's rarity color so the pill reads as belonging to *this*
/// companion — matches the rarity-tinted border + glow pulse on the
/// surrounding card. Runs its own 1400 ms reverse-repeat controller in
/// lockstep with the parent card's pulse controller.
class CardReadyPill extends StatefulWidget {
  const CardReadyPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  State<CardReadyPill> createState() => _CardReadyPillState();
}

class _CardReadyPillState extends State<CardReadyPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

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
        final t = _ctrl.value;
        final color = widget.color;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18 + 0.18 * t),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withValues(alpha: 0.5 + 0.3 * t),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.4 * t),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CardConsumedPill extends StatelessWidget {
  const CardConsumedPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Tokens.onSurfaceMuted,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
