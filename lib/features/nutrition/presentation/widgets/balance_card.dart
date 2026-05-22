import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.basal,
    required this.active,
    required this.output,
    required this.intake,
    required this.delta,
    this.isAverage = false,
  });

  final double basal;
  final double active;
  final double output;
  final double intake;
  final double delta;
  final bool isAverage;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.calories;
    final safeBasal = basal.isFinite ? basal : 0.0;
    final safeActive = active.isFinite ? active : 0.0;
    final safeOutput = output.isFinite ? output : safeBasal + safeActive;
    final safeIntake = intake.isFinite ? intake : 0.0;
    final safeDelta = delta.isFinite ? delta : safeIntake - safeOutput;
    final isDeficit = safeDelta < 0;
    final badgeColor = isDeficit ? Tokens.weight.color : Tokens.danger;
    final badgeLabel =
        isDeficit ? l10n.nutritionBalanceDeficit : l10n.nutritionBalanceSurplus;

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
                  child: Icon(
                    Icons.balance_rounded,
                    size: 18,
                    color: domain.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.nutritionBalanceTitle,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeBody,
                      fontWeight: FontWeight.w700,
                      color: ft.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: badgeColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '${safeDelta >= 0 ? '+' : ''}${isAverage ? safeDelta.toStringAsFixed(1) : safeDelta.round()} kcal · $badgeLabel',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceMd),
            _BalanceRow(
              label: l10n.nutritionBalanceBasal,
              value: safeBasal,
              isAverage: isAverage,
            ),
            _BalanceRow(
              label: l10n.nutritionBalanceActive,
              value: safeActive,
              isAverage: isAverage,
            ),
            const Divider(color: Color(0x14FFFFFF), height: 18),
            _BalanceRow(
              label: l10n.nutritionBalanceOutput,
              value: safeOutput,
              isStrong: true,
              isAverage: isAverage,
            ),
            _BalanceRow(
              label: l10n.nutritionBalanceIntake,
              value: safeIntake,
              isStrong: true,
              valueColor: Tokens.calories.color,
              isLast: true,
              isAverage: isAverage,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.isStrong = false,
    this.valueColor,
    this.isLast = false,
    this.isAverage = false,
  });

  final String label;
  final double value;
  final bool isStrong;
  final Color? valueColor;
  final bool isLast;
  final bool isAverage;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final safeValue = value.isFinite ? value : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLast ? 4 : 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
              color: isStrong ? ft.onSurface : ft.onSurfaceMuted,
            ),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              text: isAverage
                  ? safeValue.toStringAsFixed(1)
                  : safeValue.round().toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor ?? ft.onSurface,
              ),
              children: [
                TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (valueColor ?? ft.onSurface).withValues(alpha: 0.7),
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
