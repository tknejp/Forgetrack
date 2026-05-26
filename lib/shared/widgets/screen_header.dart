import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class ScreenHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final Widget? leading;
  final Widget? trailing;

  /// Optional inline strip rendered immediately below [title]. Used by
  /// the profile screen to surface the @handle / friends-count row
  /// underneath the player's display name, but generic enough for any
  /// per-screen subtitle (metadata chips, etc.).
  final Widget? subtitle;
  final VoidCallback? onAvatarTap;

  const ScreenHeader({
    super.key,
    required this.greeting,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: Tokens.spaceMd),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (greeting.isNotEmpty)
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeSmall,
                      color: ft.onSurfaceMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (greeting.isNotEmpty) const SizedBox(height: 1),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeTitle,
                    fontWeight: FontWeight.w800,
                    color: ft.onSurface,
                    letterSpacing: -0.6,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onAvatarTap != null)
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ft.accent.withValues(alpha: 0.33),
                      ft.accent.withValues(alpha: 0.13),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Tokens.radiusInner),
                  border: Border.all(
                    color: ft.accent.withValues(alpha: 0.27),
                  ),
                  boxShadow: [
                    BoxShadow(color: ft.accentGlow, blurRadius: Tokens.glowLg),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: ft.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
