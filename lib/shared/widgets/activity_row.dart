import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum ActivityType { walking, strength }

class ActivityRow extends StatelessWidget {
  final ActivityType type;
  final String? typeLabel;
  final String? typeEmoji;
  final String date;
  final String duration;
  final String kcal;
  final int xp;
  final bool isLast;

  /// When non-null, the row becomes tappable (e.g. to open an activity detail
  /// screen). Hit-test stays opaque across the whole row.
  final VoidCallback? onTap;

  const ActivityRow({
    super.key,
    required this.type,
    this.typeLabel,
    this.typeEmoji,
    required this.date,
    required this.duration,
    required this.kcal,
    required this.xp,
    this.isLast = false,
    this.onTap,
  });

  String get _displayEmoji =>
      typeEmoji ?? (type == ActivityType.walking ? '\uD83D\uDEB6' : '\u2694');

  String get _displayLabel =>
      typeLabel ?? (type == ActivityType.walking ? 'WALKING' : 'STRENGTH');

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final domain = type == ActivityType.walking ? ft.steps : ft.active;

    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: ft.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: domain.dim,
              borderRadius: BorderRadius.circular(Tokens.radiusIcon),
              border: Border.all(color: domain.color.withValues(alpha: 0.27)),
            ),
            child: Center(
              child: Text(_displayEmoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: Tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ft.onSurface.withValues(alpha: 0.92),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: ft.onSurfaceMuted,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ft.onSurface.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 1),
              Text.rich(
                TextSpan(
                  text: '$kcal | ',
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: ft.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '+$xp XP',
                      style: TextStyle(color: ft.sleep.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}
