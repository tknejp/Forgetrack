import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';

class PartialProgressRow extends StatelessWidget {
  const PartialProgressRow({
    super.key,
    required this.satisfied,
    required this.total,
    required this.l10n,
    required this.color,
  });

  final int satisfied;
  final int total;
  final AppLocalizations l10n;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.incomplete_circle_rounded,
            size: 13, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 5),
        Text(
          l10n.cosmeticPartialProgress(satisfied, total),
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
