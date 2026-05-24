import 'package:flutter/foundation.dart';

import '../../../../../shared/widgets/trend_chart.dart';

enum SleepRange { day, week, month }

@immutable
class SleepPeriod {
  const SleepPeriod({
    required this.range,
    required this.referenceDate,
  });

  factory SleepPeriod.current(SleepRange range) {
    final now = DateTime.now();
    return SleepPeriod(
      range: range,
      referenceDate: DateTime(now.year, now.month, now.day),
    );
  }

  final SleepRange range;
  final DateTime referenceDate;

  DateTime get start => switch (range) {
        SleepRange.day => referenceDate,
        SleepRange.week =>
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1)),
        SleepRange.month =>
          DateTime(referenceDate.year, referenceDate.month, 1),
      };

  DateTime get end {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodEnd = switch (range) {
      SleepRange.day => referenceDate,
      SleepRange.week => start.add(const Duration(days: 6)),
      SleepRange.month =>
        DateTime(referenceDate.year, referenceDate.month + 1, 0),
    };
    return periodEnd.isAfter(today) ? today : periodEnd;
  }

  /// Full calendar end for display labels — never capped at today.
  DateTime get displayEnd => switch (range) {
        SleepRange.day => referenceDate,
        SleepRange.week => start.add(const Duration(days: 6)),
        SleepRange.month =>
          DateTime(referenceDate.year, referenceDate.month + 1, 0),
      };

  bool get isCurrentPeriod {
    final current = SleepPeriod.current(range);
    return start == current.start;
  }

  bool get canGoForward => !isCurrentPeriod;

  SleepPeriod withRange(SleepRange nextRange) =>
      SleepPeriod.current(nextRange);

  SleepPeriod backward() => shift(-1);

  SleepPeriod forward() => canGoForward ? shift(1) : this;

  SleepPeriod shift(int amount) => switch (range) {
        SleepRange.day => SleepPeriod(
            range: range,
            referenceDate: referenceDate.add(Duration(days: amount)),
          ),
        SleepRange.week => SleepPeriod(
            range: range,
            referenceDate: referenceDate.add(Duration(days: 7 * amount)),
          ),
        SleepRange.month => SleepPeriod(
            range: range,
            referenceDate: DateTime(
              referenceDate.year,
              referenceDate.month + amount,
              1,
            ),
          ),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepPeriod && range == other.range && start == other.start;

  @override
  int get hashCode => Object.hash(range, start);
}

class SleepPeriodBar {
  const SleepPeriodBar({required this.period, required this.bar});
  final SleepPeriod period;
  final ChartBar bar;
}
