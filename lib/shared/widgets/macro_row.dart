import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'progress_bar.dart';

class MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Domain domain;
  final bool isLast;

  const MacroRow({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.domain,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final over = value > goal;
    final barColor = over ? ft.danger : domain.color;
    final barGlow = over ? ft.danger.withValues(alpha: 0.30) : domain.glow;

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: ft.divider)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ft.onSurface.withValues(alpha: 0.85),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  fontSize: Tokens.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                  color: over ? barColor : ft.onSurfaceMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ProgressBar(
            value: (value / goal).clamp(0.0, 1.3),
            color: barColor,
            glow: barGlow,
            height: 5,
          ),
        ],
      ),
    );
  }
}
