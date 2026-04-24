import 'package:flutter/material.dart';

import '../../theme/ft_design_tokens.dart';

enum FtActivityType { walking, strength }

class FtActivityRow extends StatelessWidget {
  final FtActivityType type;
  final String? typeLabel;
  final String? typeEmoji;
  final String date;
  final String duration;
  final String kcal;
  final int xp;
  final bool isLast;

  const FtActivityRow({
    super.key,
    required this.type,
    this.typeLabel,
    this.typeEmoji,
    required this.date,
    required this.duration,
    required this.kcal,
    required this.xp,
    this.isLast = false,
  });

  String get _displayEmoji =>
      typeEmoji ?? (type == FtActivityType.walking ? '\uD83D\uDEB6' : '\u2694');

  String get _displayLabel =>
      typeLabel ?? (type == FtActivityType.walking ? 'WALKING' : 'STRENGTH');

  FtDomain get _domain =>
      type == FtActivityType.walking ? FtTokens.steps : FtTokens.active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: FtTokens.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _domain.dim,
              borderRadius: BorderRadius.circular(FtTokens.radiusIcon),
              border: Border.all(color: _domain.color.withValues(alpha: 0.27)),
            ),
            child: Center(
              child: Text(_displayEmoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xEBFFFFFF),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeMicro,
                    color: FtTokens.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xE0FFFFFF),
                ),
              ),
              const SizedBox(height: 1),
              Text.rich(
                TextSpan(
                  text: '$kcal | ',
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeMicro,
                    color: FtTokens.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '+$xp XP',
                      style: const TextStyle(color: Color(0xFFA89BFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
