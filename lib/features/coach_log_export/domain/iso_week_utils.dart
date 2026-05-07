import 'iso_week.dart';

/// Strips the time component, preserving the local date fields.
DateTime dateOnly(DateTime input) =>
    DateTime(input.year, input.month, input.day);

/// Returns the Monday that starts the ISO week containing [date].
DateTime startOfIsoWeek(DateTime date) {
  // Use UTC to avoid DST gaps when subtracting across a DST boundary
  final utc = DateTime.utc(date.year, date.month, date.day);
  final mondayUtc = utc.subtract(Duration(days: utc.weekday - 1));
  return DateTime(mondayUtc.year, mondayUtc.month, mondayUtc.day);
}

/// Returns all ISO weeks that at least partially overlap the range [from, to].
List<IsoWeek> isoWeeksOverlapping(DateTime from, DateTime to) {
  assert(!to.isBefore(from), 'to must not be before from');
  final weeks = <IsoWeek>[];
  var current = IsoWeek.fromDate(from);
  final last = IsoWeek.fromDate(to);
  while (true) {
    weeks.add(current);
    if (current == last) break;
    // Use calendar-day arithmetic (day+7) to advance without DST distortion
    final m = current.monday;
    current = IsoWeek.fromDate(DateTime(m.year, m.month, m.day + 7));
  }
  return weeks;
}

/// Returns the ISO week immediately following the week that contains [date].
IsoWeek nextIsoWeekAfter(DateTime date) {
  final current = IsoWeek.fromDate(date);
  final m = current.monday;
  return IsoWeek.fromDate(DateTime(m.year, m.month, m.day + 7));
}
