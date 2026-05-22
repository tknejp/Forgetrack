import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

class HydrationCard extends StatelessWidget {
  const HydrationCard({
    super.key,
    required this.litersConsumed,
    required this.goalLiters,
    required this.isDayMode,
  });

  final double litersConsumed;
  final double goalLiters;
  final bool isDayMode;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.sleep; // water-blue
    final safeLiters = litersConsumed.isFinite ? litersConsumed : 0.0;
    final safeGoal = goalLiters.isFinite ? goalLiters : 0.0;
    final progress =
        safeGoal > 0 ? (safeLiters / safeGoal).clamp(0.0, 1.0) : 0.0;
    final pct = safeGoal > 0 ? ((safeLiters / safeGoal) * 100).round() : 0;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: domain.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: domain.dim,
                    borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                    border: Border.all(
                      color: domain.color.withValues(alpha: 0.27),
                    ),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color: Color(0xFF66C2E0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.nutritionHydrationTitle,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeBody,
                          fontWeight: FontWeight.w700,
                          color: ft.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDayMode
                            ? '${safeLiters.toStringAsFixed(2)} l / '
                                '${safeGoal.toStringAsFixed(1)} l'
                            : l10n.nutritionMealsOnlyDayMode,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w500,
                          color: ft.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDayMode)
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: Tokens.fontSizeBody,
                      fontWeight: FontWeight.w800,
                      color: domain.color,
                    ),
                  ),
              ],
            ),
            if (isDayMode) ...[
              const SizedBox(height: Tokens.spaceMd),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: ft.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(domain.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
