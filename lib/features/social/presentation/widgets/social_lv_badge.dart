import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';

class SocialLvBadge extends StatelessWidget {
  const SocialLvBadge({super.key, required this.level, this.size = 36});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FtTokens.accent, FtTokens.accent.withValues(alpha: 0.55)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
            color: FtTokens.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(color: FtTokens.accentGlow, blurRadius: 12)
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
