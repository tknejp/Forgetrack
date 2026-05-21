import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/emblem_buff.dart';
import '../emblem_buff_label.dart';

/// Full-width, "headline + subtitle" banner advertising an [EmblemBuff].
/// Mirrors the companion-side [`CompanionBuffBanner`] 1:1 so that
/// player-facing surfaces (cosmetic details sheet, emblem-slot sheet)
/// read consistently across both cosmetic types — same neutral fill,
/// same XP-tinted icon + headline, same secondary "while equipped"
/// subtitle line.
class EmblemBuffBanner extends StatelessWidget {
  const EmblemBuffBanner({super.key, required this.buff});

  final EmblemBuff buff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headline = emblemBuffLabel(buff, l10n);
    if (headline == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_rounded,
            size: 16,
            color: Tokens.xp.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: Tokens.xp.withValues(alpha: 0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.emblemBuffBannerSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
