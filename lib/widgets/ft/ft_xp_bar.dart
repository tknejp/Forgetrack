import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';
import 'ft_progress_bar.dart';

class FtXpBar extends StatelessWidget {
  final int level;
  final String title;
  final int xp;
  final int xpMax;

  const FtXpBar({
    super.key,
    required this.level,
    required this.title,
    required this.xp,
    required this.xpMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FtTokens.accent,
                  FtTokens.accent.withValues(alpha: 0.53),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LEVEL $level · ${title.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: FtTokens.fontSizeMicro,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.accent,
                        letterSpacing: 0.9,
                      ),
                    ),
                    Text(
                      '$xp / $xpMax XP',
                      style: const TextStyle(
                        fontSize: FtTokens.fontSizeMicro,
                        color: FtTokens.onSurfaceFaint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FtProgressBar(
                  value: xp / xpMax,
                  color: FtTokens.accent,
                  glow: FtTokens.accentGlow,
                  height: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
