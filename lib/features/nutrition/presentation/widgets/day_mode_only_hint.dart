import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

class DayModeOnlyHint extends StatelessWidget {
  const DayModeOnlyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: ft.onSurfaceMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.nutritionMealsOnlyDayMode,
              style: TextStyle(
                fontSize: 12,
                color: ft.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
