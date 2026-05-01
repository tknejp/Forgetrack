import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Section divider header used throughout the app.
/// Shows a small accent star icon, uppercase label, and optional caption line.
class SectionHead extends StatelessWidget {
  final String label;
  final Color accent;
  final String? caption;

  const SectionHead({
    super.key,
    required this.label,
    required this.accent,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 1.1,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    color: Tokens.onSurfaceFaint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
