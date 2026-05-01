import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/section_head.dart';

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
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: SectionHead(label: title, accent: Tokens.accent),
        ),
        const SizedBox(height: Tokens.spaceSm),
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}
