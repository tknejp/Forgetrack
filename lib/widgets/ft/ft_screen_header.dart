import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';

class FtScreenHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final VoidCallback? onAvatarTap;

  const FtScreenHeader({
    super.key,
    required this.greeting,
    required this.title,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FtTokens.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeTitle,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FtTokens.accent.withValues(alpha: 0.33),
                    FtTokens.accent.withValues(alpha: 0.13),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FtTokens.accent.withValues(alpha: 0.27),
                ),
                boxShadow: [
                  BoxShadow(color: FtTokens.accentGlow, blurRadius: 16),
                ],
              ),
              child: const Center(
                child: Text('⚔️', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
