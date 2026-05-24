import 'package:flutter/foundation.dart';

import '../../../../../shared/widgets/trend_chart.dart';

enum BodyRange { day, week, month }

@immutable
class BodyPeriod {
  const BodyPeriod({
    required this.range,
    required this.referenceDate,
  });

  factory BodyPeriod.current(BodyRange range) {
    final now = DateTime.now();
    return BodyPeriod(
      range: range,
      referenceDate: DateTime(now.year, now.month, now.day),
    );
  }

  final BodyRange range;
  final DateTime referenceDate;

  DateTime get start {
    return switch (range) {
      BodyRange.day => referenceDate,
      BodyRange.week =>
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1)),
      BodyRange.month => DateTime(referenceDate.year, referenceDate.month, 1),
    };
  }

  DateTime get end {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodEnd = switch (range) {
      BodyRange.day => referenceDate,
      BodyRange.week => start.add(const Duration(days: 6)),
      BodyRange.month =>
        DateTime(referenceDate.year, referenceDate.month + 1, 0),
    };
    return periodEnd.isAfter(today) ? today : periodEnd;
  }

  /// Full calendar end for display labels — never capped at today.
  DateTime get displayEnd => switch (range) {
        BodyRange.day => referenceDate,
        BodyRange.week => start.add(const Duration(days: 6)),
        BodyRange.month =>
          DateTime(referenceDate.year, referenceDate.month + 1, 0),
      };

  bool get isCurrentPeriod {
    final current = BodyPeriod.current(range);
    return start == current.start;
  }

  bool get canGoForward => !isCurrentPeriod;

  BodyPeriod withRange(BodyRange nextRange) => BodyPeriod.current(nextRange);

  BodyPeriod backward() => shift(-1);

  BodyPeriod forward() => canGoForward ? shift(1) : this;

  BodyPeriod shift(int amount) {
    return switch (range) {
      BodyRange.day => BodyPeriod(
          range: range,
          referenceDate: referenceDate.add(Duration(days: amount)),
        ),
      BodyRange.week => BodyPeriod(
          range: range,
          referenceDate: referenceDate.add(Duration(days: 7 * amount)),
        ),
      BodyRange.month => BodyPeriod(
          range: range,
          referenceDate: DateTime(
            referenceDate.year,
            referenceDate.month + amount,
            1,
          ),
        ),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyPeriod && range == other.range && start == other.start;

  @override
  int get hashCode => Object.hash(range, start);
}

class WeightPeriodBar {
  const WeightPeriodBar({
    required this.period,
    required this.bar,
  });

  final BodyPeriod period;
  final ChartBar bar;
}
