import 'package:flutter/material.dart';

/// Generic level badge — a coloured square with the level number centred.
///
/// Pure rendering primitive: takes a level number and an accent colour.
/// The caller (social, hero card, journey map, …) computes the accent
/// via [ProgressionDisplayResolver.levelDisplay] and passes it in. This
/// widget knows nothing about progression internals and can be reused by
/// any feature that needs to render a level chip.
///
/// Replaces direct imports of the legacy
/// `progression/presentation/widgets/progression_level_badge.dart` from
/// downstream features.
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    required this.accentColor,
    this.size = 44,
  });

  final int level;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final softFill = accentColor.withValues(alpha: 0.20);
    final strongFill = accentColor.withValues(alpha: 0.82);
    final glow = accentColor.withValues(alpha: 0.34);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [strongFill, softFill],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: size * 0.40,
            offset: Offset(0, size * 0.09),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.39,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}
