import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/design_tokens.dart';

class DetailShortcutButton extends StatelessWidget {
  final VoidCallback onTap;
  final Domain domain;

  const DetailShortcutButton({
    super.key,
    required this.onTap,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: BorderSide(color: domain.color.withValues(alpha: 0.30)),
            backgroundColor: domain.dim.withValues(alpha: 0.28),
            foregroundColor: domain.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Tokens.radiusTile),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(context.l10n.homeOpenDetailCta),
        ),
      ),
    );
  }
}
