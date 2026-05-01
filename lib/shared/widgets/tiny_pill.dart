import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Pill-shaped status label: "Active", "Completed", "Unlocked", etc.
/// Color is fully caller-controlled — use `FtTokens` semantic colors.
class TinyPill extends StatelessWidget {
  const TinyPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
