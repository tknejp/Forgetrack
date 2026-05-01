import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Animated expand/collapse chevron.
/// Rotates 180° between collapsed (pointing down) and expanded (pointing up).
class ExpandChevron extends StatelessWidget {
  final bool expanded;

  /// Icon color. Defaults to [ThemeTokens.onSurfaceMuted].
  final Color? color;

  /// Icon size. Defaults to 18.
  final double size;

  const ExpandChevron({
    super.key,
    required this.expanded,
    this.color,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: size,
        color: color ?? context.ft.onSurfaceMuted,
      ),
    );
  }
}
