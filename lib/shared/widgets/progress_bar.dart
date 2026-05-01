import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0–1.0 (values >1 are clamped visually)
  final Color color;
  final Color glow;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.glow,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final pct = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (_, constraints) => Container(
        height: height,
        decoration: BoxDecoration(
          color: ft.cardBorder,
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: constraints.maxWidth * pct,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              boxShadow: [BoxShadow(color: glow, blurRadius: Tokens.glowSm)],
            ),
          ),
        ),
      ),
    );
  }
}
