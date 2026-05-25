import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';

class CosmeticsScreenSectionHead extends StatelessWidget {
  const CosmeticsScreenSectionHead({super.key, required this.label, this.caption});

  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Tokens.accent,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    color: Tokens.onSurfaceFaint,
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CosmeticsScreenEmptyLine extends StatelessWidget {
  const CosmeticsScreenEmptyLine({
    super.key,
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Tokens.onSurface,
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              color: Tokens.onSurfaceMuted,
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CosmeticsScreenEmptyInventory extends StatelessWidget {
  const CosmeticsScreenEmptyInventory({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: CosmeticsScreenEmptyLine(
        title: l10n.cosmeticsEmptyUnlockedTitle,
        caption: l10n.cosmeticsEmptyUnlockedCaption,
      ),
    );
  }
}

class CosmeticsScreenNotSignedIn extends StatelessWidget {
  const CosmeticsScreenNotSignedIn({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CosmeticsScreenEmptyLine(
          title: l10n.cosmeticsNotSignedInTitle,
          caption: l10n.cosmeticsNotSignedInCaption,
        ),
      ),
    );
  }
}
