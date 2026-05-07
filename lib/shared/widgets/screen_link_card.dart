import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Compact "go to related screen" card placed at the bottom of detail screens
/// to cross-link companion views (Steps ↔ Activities, etc.). Domain-tinted to
/// match the target screen's palette so the link reads as a preview of where
/// you're going.
class ScreenLinkCard extends StatelessWidget {
  const ScreenLinkCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.domain,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Domain domain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: domain.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: domain.dim,
                borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                border: Border.all(
                  color: domain.color.withValues(alpha: 0.27),
                ),
              ),
              child: Icon(icon, size: 18, color: domain.color),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeBody,
                      fontWeight: FontWeight.w700,
                      color: ft.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      fontWeight: FontWeight.w500,
                      color: ft.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: domain.color,
            ),
          ],
        ),
      ),
    );
  }
}
