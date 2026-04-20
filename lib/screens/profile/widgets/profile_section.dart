import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;
  final double bottomSpacing;

  const ProfileSection({
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
        ProfileSectionHeader(title: title),
        const SizedBox(height: 8),
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class ProfileSectionHeader extends StatelessWidget {
  final String title;

  const ProfileSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}
