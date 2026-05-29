import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/design_tokens.dart';
import 'tab_pill.dart';

/// Compact period navigator — a domain-tinted card that shows the currently
/// viewed day / week / month with prev / next arrows and an optional "Today"
/// pill that snaps back to the current period.
///
/// Optionally renders the range tabs (Day / Week / Month) on a top row of the
/// same card when [tabs] are supplied — combining the range selector and the
/// period navigator into a single header card.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.domain,
    required this.dateLabel,
    required this.canGoForward,
    required this.isCurrentPeriod,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    this.rangeLabel,
    this.syncedAt,
    this.onDateTap,
    this.tabs,
    this.activeTab,
    this.onTabChange,
    this.action,
  });

  /// Domain that drives card decoration + accent colors (chevrons, "Today"
  /// pill, active tab). Use the same domain as the rest of the screen.
  final Domain domain;

  /// Centered, primary label — e.g. "6. května" or "1. – 7. května".
  final String dateLabel;

  /// Optional small caption rendered under [dateLabel]. Usually omitted when
  /// [tabs] are visible since the active tab already conveys the range.
  final String? rangeLabel;

  /// Optional sync timestamp shown beneath the date label (e.g. "Synced 14:32").
  final String? syncedAt;

  /// Whether the next arrow is enabled. Disable when the current period is
  /// already the latest one.
  final bool canGoForward;

  /// Whether the navigator is currently on the present period — drives
  /// visibility of the "Today" pill.
  final bool isCurrentPeriod;

  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  /// When non-null, the date label becomes tappable (used by overview to open
  /// a date picker) and a small dropdown chevron is rendered next to it.
  final VoidCallback? onDateTap;

  /// Optional range tabs rendered above the navigator row inside the same
  /// card. All three of [tabs], [activeTab], [onTabChange] must be provided
  /// together. When null, only the navigator row is shown.
  final List<String>? tabs;
  final String? activeTab;
  final ValueChanged<String>? onTabChange;

  /// Optional trailing action (e.g. a quick-export icon button). When [tabs]
  /// are shown it sits at the top-right of the tab header row; otherwise it is
  /// appended to the navigator row after the next-period arrow. The widget may
  /// render nothing (e.g. `SizedBox.shrink`) to opt out reactively.
  final Widget? action;

  bool get _hasTabs =>
      tabs != null && activeTab != null && onTabChange != null;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    final navRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            color: domain.color,
            tooltip: '–1',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
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
                      Flexible(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeBody,
                            fontWeight: FontWeight.w700,
                            color: ft.onSurface,
                          ),
                        ),
                      ),
                      if (onDateTap != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: ft.onSurfaceMuted,
                        ),
                      ],
                    ],
                  ),
                  if (rangeLabel != null)
                    Text(
                      rangeLabel!.toUpperCase(),
                      style: TextStyle(
                        fontSize: Tokens.fontSizeMicro,
                        fontWeight: FontWeight.w600,
                        color: ft.onSurfaceMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  if (syncedAt != null)
                    Text(
                      syncedAt!,
                      style: TextStyle(
                        fontSize: Tokens.fontSizeMicro,
                        fontWeight: FontWeight.w500,
                        color: ft.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isCurrentPeriod && onToday != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: onToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: domain.dim,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: domain.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    context.l10n.periodToday,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      fontWeight: FontWeight.w700,
                      color: domain.color,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: canGoForward ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            color: domain.color,
            disabledColor: ft.onSurfaceFaint,
            tooltip: '+1',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Without tabs the navigator row is the top row, so the trailing
          // action lives here. With tabs it moves to the tab header below.
          if (action != null && !_hasTabs) action!,
        ],
      ),
    );

    if (!_hasTabs) {
      return Container(
        decoration: domain.cardDecoration(),
        child: navRow,
      );
    }

    return Container(
      decoration: domain.cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TabPill(
                    domain: domain,
                    tabs: tabs!,
                    active: activeTab!,
                    onChange: onTabChange!,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 4),
                  action!,
                ],
              ],
            ),
          ),
          navRow,
        ],
      ),
    );
  }
}
