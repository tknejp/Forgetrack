import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';

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
          Icon(icon, size: 36, color: FtTokens.onSurfaceFaint),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FtTokens.onSurfaceMuted),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style:
                const TextStyle(fontSize: 12, color: FtTokens.onSurfaceFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
