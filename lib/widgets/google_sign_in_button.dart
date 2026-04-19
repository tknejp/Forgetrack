import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'google_logo_icon.dart';

class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? label;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final resolvedLabel = label ?? l10n.profileContinueWithGoogle;
    final backgroundColor = theme.brightness == Brightness.dark
        ? cs.surfaceContainerLow
        : cs.surface;
    final borderColor = theme.brightness == Brightness.dark
        ? cs.outlineVariant.withValues(alpha: 0.9)
        : cs.outlineVariant.withValues(alpha: 0.72);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: cs.onSurface,
          disabledBackgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: cs.primary,
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GoogleLogoIcon(
                      size: 20,
                      semanticsLabel: 'Google logo',
                      fallback: Icon(
                        Icons.login_rounded,
                        size: 19,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      resolvedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
