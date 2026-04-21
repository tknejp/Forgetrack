import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';

class FtProgressBar extends StatelessWidget {
  final double value; // 0.0–1.0 (values >1 are clamped visually)
  final Color color;
  final Color glow;
  final double height;

  const FtProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.glow,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (_, constraints) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(FtTokens.radiusProgress),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: constraints.maxWidth * pct,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FtTokens.radiusProgress),
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              boxShadow: [BoxShadow(color: glow, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}
