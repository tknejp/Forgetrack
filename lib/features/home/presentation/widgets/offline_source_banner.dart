import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Compact tap-to-set-up banner shown above cards rendered with cached
/// data only. Used for both KT (above the calorie card) and HC (above
/// steps/weight/activities/sleep cards) to remind the user they're not
/// fully connected.
class OfflineSourceBanner extends StatelessWidget {
  const OfflineSourceBanner({
    super.key,
    required this.message,
    required this.onTap,
  });

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 14,
              color: ft.onSurfaceMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}
