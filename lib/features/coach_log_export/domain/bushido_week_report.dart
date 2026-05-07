import 'package:flutter/foundation.dart';

import 'bushido_day_row.dart';
import 'iso_week.dart';

@immutable
class BushidoWeekReport {
  final IsoWeek week;
  final List<BushidoDayRow> days;

  BushidoWeekReport({required this.week, required this.days})
      : assert(days.length == 7, 'days must contain exactly 7 entries'),
        assert(
          _isDaysChronologicalFromMonday(days, week),
          'days must be in chronological order starting from Monday of the week',
        );

  static bool _isDaysChronologicalFromMonday(
    List<BushidoDayRow> days,
    IsoWeek week,
  ) {
    for (var i = 0; i < days.length; i++) {
      final expected = week.monday.add(Duration(days: i));
      final d = days[i].date;
      if (d.year != expected.year ||
          d.month != expected.month ||
          d.day != expected.day) {
        return false;
      }
    }
    return true;
  }
}
