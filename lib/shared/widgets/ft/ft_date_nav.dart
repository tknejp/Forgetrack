import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';

class FtDateNav extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback? onNext; // null = at current period, arrow disabled
  final String? syncedAt;
  final String? labelOverride; // overrides the computed day label for week/month views
  final VoidCallback? onDateTap; // opens date picker or custom action
  final bool showTodayButton; // shows "Today" chip when at a past period
  final VoidCallback? onTodayTap; // called when "Today" chip is tapped

  const FtDateNav({
    super.key,
    required this.date,
    required this.onPrev,
    this.onNext,
    this.syncedAt,
    this.labelOverride,
    this.onDateTap,
    this.showTodayButton = false,
    this.onTodayTap,
  });

  String _dayLabel() {
    if (labelOverride != null) return labelOverride!;
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavArrow(onTap: onPrev, isLeft: true, enabled: true),
        Expanded(
          child: GestureDetector(
            onTap: onDateTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dayLabel(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (onDateTap != null) ...[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: Color(0x66FFFFFF),
                      ),
                    ],
                    if (showTodayButton && onTodayTap != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onTodayTap,
                        child: const Text(
                          '· Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FtTokens.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (syncedAt != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    'Synced $syncedAt',
                    style: const TextStyle(
                      fontSize: FtTokens.fontSizeMicro,
                      color: FtTokens.onSurfaceMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _NavArrow(onTap: onNext, isLeft: false, enabled: onNext != null),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLeft;
  final bool enabled;

  const _NavArrow({
    required this.onTap,
    required this.isLeft,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isLeft ? Icons.chevron_left : Icons.chevron_right,
          color: enabled
              ? const Color(0xB3FFFFFF)
              : const Color(0x33FFFFFF),
          size: 20,
        ),
      ),
    );
  }
}
