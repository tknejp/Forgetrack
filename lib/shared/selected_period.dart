import 'package:flutter/foundation.dart';

enum PeriodType { day, week, month, custom }

@immutable
class SelectedPeriod {
  final PeriodType type;
  final DateTime referenceDate;

  // Only populated when type == PeriodType.custom (future feature).
  final DateTime? customStart;
  final DateTime? customEnd;

  const SelectedPeriod._({
    required this.type,
    required this.referenceDate,
    this.customStart,
    this.customEnd,
  });

  factory SelectedPeriod.today() =>
      SelectedPeriod._(type: PeriodType.day, referenceDate: _today());

  factory SelectedPeriod.forDay(DateTime date) => SelectedPeriod._(
      type: PeriodType.day,
      referenceDate: DateTime(date.year, date.month, date.day));

  factory SelectedPeriod.currentWeek() =>
      SelectedPeriod._(type: PeriodType.week, referenceDate: _today());

  factory SelectedPeriod.currentMonth() =>
      SelectedPeriod._(type: PeriodType.month, referenceDate: _today());

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // Inclusive start of the period (date-only, no time).
  DateTime get start {
    switch (type) {
      case PeriodType.day:
        return referenceDate;
      case PeriodType.week:
        return referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
      case PeriodType.month:
        return DateTime(referenceDate.year, referenceDate.month, 1);
      case PeriodType.custom:
        return customStart!;
    }
  }

  // Inclusive end of the period (date-only, no time).
  DateTime get end {
    switch (type) {
      case PeriodType.day:
        return referenceDate;
      case PeriodType.week:
        return start.add(const Duration(days: 6));
      case PeriodType.month:
        // Day 0 of next month = last day of this month.
        return DateTime(referenceDate.year, referenceDate.month + 1, 0);
      case PeriodType.custom:
        return customEnd!;
    }
  }

  bool get isCurrentPeriod {
    final t = _today();
    switch (type) {
      case PeriodType.day:
        return referenceDate == t;
      case PeriodType.week:
        return start == SelectedPeriod.currentWeek().start;
      case PeriodType.month:
        return referenceDate.year == t.year && referenceDate.month == t.month;
      case PeriodType.custom:
        return false;
    }
  }

  bool get canGoForward => !isCurrentPeriod;

  SelectedPeriod forward() {
    if (!canGoForward) return this;
    switch (type) {
      case PeriodType.day:
        return SelectedPeriod._(
            type: type,
            referenceDate: referenceDate.add(const Duration(days: 1)));
      case PeriodType.week:
        return SelectedPeriod._(
            type: type,
            referenceDate: referenceDate.add(const Duration(days: 7)));
      case PeriodType.month:
        return SelectedPeriod._(
            type: type,
            referenceDate:
                DateTime(referenceDate.year, referenceDate.month + 1));
      case PeriodType.custom:
        return this;
    }
  }

  SelectedPeriod backward() {
    switch (type) {
      case PeriodType.day:
        return SelectedPeriod._(
            type: type,
            referenceDate: referenceDate.subtract(const Duration(days: 1)));
      case PeriodType.week:
        return SelectedPeriod._(
            type: type,
            referenceDate: referenceDate.subtract(const Duration(days: 7)));
      case PeriodType.month:
        return SelectedPeriod._(
            type: type,
            referenceDate:
                DateTime(referenceDate.year, referenceDate.month - 1));
      case PeriodType.custom:
        return this;
    }
  }

  // Reset to the current period of a new type.
  SelectedPeriod withType(PeriodType newType) {
    switch (newType) {
      case PeriodType.day:
        return SelectedPeriod.today();
      case PeriodType.week:
        return SelectedPeriod.currentWeek();
      case PeriodType.month:
        return SelectedPeriod.currentMonth();
      case PeriodType.custom:
        // Carry current range as the initial custom range.
        return SelectedPeriod._(
          type: PeriodType.custom,
          referenceDate: _today(),
          customStart: start,
          customEnd: end,
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedPeriod &&
          type == other.type &&
          referenceDate == other.referenceDate &&
          customStart == other.customStart &&
          customEnd == other.customEnd;

  @override
  int get hashCode =>
      Object.hash(type, referenceDate, customStart, customEnd);
}
