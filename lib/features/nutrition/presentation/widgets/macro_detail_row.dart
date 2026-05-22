import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

class MacroDetailRow extends StatelessWidget {
  const MacroDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    this.isLast = false,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final safeValue = value.isFinite ? value : 0.0;
    final safeGoal = goal.isFinite ? goal : 0.0;
    final hasGoal = safeGoal > 0;
    final pct = hasGoal ? ((safeValue / safeGoal) * 100).round() : null;
    final pctColor = pct == null
        ? ft.onSurfaceMuted
        : pct < 70
            ? Tokens.danger.withValues(alpha: 0.85)
            : pct > 110
                ? Tokens.danger.withValues(alpha: 0.85)
                : color;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: ft.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ft.onSurface,
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              text: _fmtAmount(safeValue),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ft.onSurface,
              ),
              children: [
                if (hasGoal)
                  TextSpan(
                    text: ' / ${_fmtAmount(safeGoal)} $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ft.onSurfaceMuted,
                    ),
                  )
                else
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ft.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (pct != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pctColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: pctColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pctColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtAmount(double v) {
    if (v >= 100) return v.round().toString();
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
