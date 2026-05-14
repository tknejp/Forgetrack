import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

class HeaderData {
  const HeaderData({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;
}

class ShellHeader extends StatelessWidget {
  const ShellHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w800,
                    color: ft.accent,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeTitle,
                    fontWeight: FontWeight.w900,
                    color: ft.onSurface,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class HeaderScrim extends StatelessWidget {
  const HeaderScrim({super.key});

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Container(
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.55, 1],
          colors: [
            ft.bg,
            ft.bg.withValues(alpha: 0.94),
            ft.bg.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ft.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Icon(
          Icons.settings_rounded,
          size: 18,
          color: ft.onSurfaceMuted,
        ),
      ),
    );
  }
}
