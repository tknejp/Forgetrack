import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

/// Unified "you need to set up X" card used by both Health Connect and
/// Kalorické Tabulky on the home overview. Same visual structure: bare
/// logo, title, body, primary CTA pill, optional ghost-pill "Show saved
/// data" tertiary action.
class DataSourcePromptCard extends StatelessWidget {
  const DataSourcePromptCard({
    super.key,
    required this.logoAsset,
    required this.accentColor,
    required this.title,
    required this.body,
    required this.ctaIcon,
    required this.ctaLabel,
    required this.onAction,
    required this.onShowCached,
  });

  final String logoAsset;
  final Color accentColor;
  final String title;
  final String body;
  final IconData ctaIcon;
  final String ctaLabel;
  final VoidCallback onAction;

  /// When non-null, renders the secondary "Show saved data" pill that
  /// lets the user view previously cached data without setting up the
  /// source. Null when there's no cache to show.
  final VoidCallback? onShowCached;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ft = context.ft;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.asset(logoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeBody,
                      fontWeight: FontWeight.w800,
                      color: ft.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceMd),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ft.onSurfaceMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: Tokens.spaceLg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(Tokens.radiusInner),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ctaIcon, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          ctaLabel,
                          style: const TextStyle(
                            fontSize: Tokens.fontSizeSmall,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onShowCached != null) ...[
                  const SizedBox(height: Tokens.spaceSm),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onShowCached,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(Tokens.radiusInner),
                        border: Border.all(color: ft.cardBorder),
                      ),
                      child: Text(
                        l10n.healthShowCachedData,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeSmall,
                          fontWeight: FontWeight.w700,
                          color: ft.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
