import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';

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
                color: FtTokens.accent.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 7),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: FtTokens.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FtTokens.cardBorder),
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
      color: FtTokens.cardBorder,
    );
  }
}
