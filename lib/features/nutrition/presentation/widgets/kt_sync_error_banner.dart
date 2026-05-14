import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

/// Inline banner shown above nutrition content when KT sync fails.
/// Message is the localized "couldn't sync nutrition data" — the raw
/// exception stays in `AppLog.ktApi`.
class KtSyncErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const KtSyncErrorBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border:
            Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFF87171),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.ktSyncError,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              l10n.ktRetry,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF87171),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
