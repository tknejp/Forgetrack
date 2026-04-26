import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';

class FtStatCell extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;
  final Color color;
  final bool compact;

  const FtStatCell({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.6,
            ),
            children: unit != null
                ? [
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: FtTokens.fontSizeTiny,
            color: FtTokens.onSurfaceMuted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}
