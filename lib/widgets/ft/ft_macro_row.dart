import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';
import 'ft_progress_bar.dart';

class FtMacroRow extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final FtDomain domain;
  final bool isLast;

  const FtMacroRow({
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
    final over = value > goal;
    final barColor = over ? const Color(0xFFF87171) : domain.color;
    final barGlow = over ? const Color(0x4DF87171) : domain.glow;

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: FtTokens.divider)),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xD9FFFFFF),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: over ? barColor : const Color(0x99FFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FtProgressBar(
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
