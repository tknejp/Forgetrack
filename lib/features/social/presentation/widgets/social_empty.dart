import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

class SocialEmpty extends StatelessWidget {
  const SocialEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Tokens.onSurfaceFaint),
          const SizedBox(height: Tokens.spaceMd),
          Text(
            title,
            style: const TextStyle(
                fontSize: Tokens.fontSizeBody,
                fontWeight: FontWeight.w700,
                color: Tokens.onSurfaceMuted),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Text(
            subtitle,
            style:
                const TextStyle(fontSize: Tokens.fontSizeSmall, color: Tokens.onSurfaceFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
