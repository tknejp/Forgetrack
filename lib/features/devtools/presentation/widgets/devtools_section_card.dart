import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

class DevToolsSectionCard extends StatelessWidget {
  const DevToolsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: Tokens.accent.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 7),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Tokens.accent,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Material (not Container + BoxDecoration) so ListTile descendants
        // — directly here or via SwitchListTile / panels below — find a
        // Material ancestor for their ink splashes + selection chrome,
        // instead of being masked by a wrapping DecoratedBox.
        Material(
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            side: const BorderSide(color: Tokens.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class DevToolsSectionDivider extends StatelessWidget {
  const DevToolsSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Tokens.cardBorder,
    );
  }
}
