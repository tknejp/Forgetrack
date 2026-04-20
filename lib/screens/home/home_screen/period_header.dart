part of '../home_screen.dart';

class _PeriodHeader extends StatelessWidget {
  final SelectedPeriod period;
  final String locale;
  final ValueChanged<SelectedPeriod> onPeriodChanged;

  const _PeriodHeader({
    required this.period,
    required this.locale,
    required this.onPeriodChanged,
  });

  String _label() {
    switch (period.type) {
      case PeriodType.day:
        return DateFormat('EEE d. M.', locale).format(period.referenceDate);
      case PeriodType.week:
        return '${DateFormat('d. M.', locale).format(period.start)}'
            ' - '
            '${DateFormat('d. M.', locale).format(period.end)}';
      case PeriodType.month:
        return DateFormat('MMMM yyyy', locale).format(period.referenceDate);
      case PeriodType.custom:
        return '${DateFormat('d. M.', locale).format(period.start)}'
            ' - '
            '${DateFormat('d. M.', locale).format(period.end)}';
    }
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: period.referenceDate,
      firstDate: DateTime(2020),
      lastDate: todayOnly,
    );
    if (picked == null) {
      return;
    }
    onPeriodChanged(SelectedPeriod.forDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDay = period.type == PeriodType.day;
    final isToday = period.isCurrentPeriod;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<PeriodType>(
                segments: [
                  ButtonSegment(
                    value: PeriodType.day,
                    label: Text(l10n.periodDay),
                  ),
                  ButtonSegment(
                    value: PeriodType.week,
                    label: Text(l10n.periodWeek),
                  ),
                  ButtonSegment(
                    value: PeriodType.month,
                    label: Text(l10n.periodMonth),
                  ),
                ],
                selected: {
                  period.type == PeriodType.custom
                      ? PeriodType.day
                      : period.type,
                },
                onSelectionChanged: (selection) =>
                    onPeriodChanged(period.withType(selection.first)),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onPeriodChanged(period.backward()),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: GestureDetector(
                onTap: isDay ? () => _openDatePicker(context) : null,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDay && isToday) ...[
                        Icon(Icons.circle, size: 7, color: cs.primary),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _label(),
                        style: tt.labelLarge?.copyWith(
                          color: isDay && isToday ? cs.primary : cs.onSurface,
                          fontWeight: isDay && isToday ? FontWeight.w600 : null,
                        ),
                      ),
                      if (isDay) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isDay && !isToday)
              SizedBox(
                height: 32,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onPeriodChanged(SelectedPeriod.today()),
                  child: Text(
                    l10n.headerToday,
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: period.canGoForward
                  ? () => onPeriodChanged(period.forward())
                  : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}
