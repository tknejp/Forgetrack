import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final double bottomSpacing;

  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
    this.bottomSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: title),
        const SizedBox(height: 8),
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
    );
  }
}
