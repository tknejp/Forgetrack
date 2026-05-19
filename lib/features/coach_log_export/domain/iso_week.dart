import 'package:meta/meta.dart';

import 'bushido_sheet_layout.dart';

@immutable
class IsoWeek {
  final int year;
  final int weekNumber;
  final DateTime monday;
  final DateTime sunday;

  const IsoWeek._({
    required this.year,
    required this.weekNumber,
    required this.monday,
    required this.sunday,
  });

  factory IsoWeek.fromDate(DateTime date) {
    // All arithmetic in UTC to avoid DST-induced off-by-one in difference.inDays
    final d = DateTime.utc(date.year, date.month, date.day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    // ISO week year is the year of the Thursday of this week
    final thursday = monday.add(const Duration(days: 3));
    final isoYear = thursday.year;
    // Week 1 is the week containing Jan 4
    final jan4 = DateTime.utc(isoYear, 1, 4);
    final mondayOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    final weekNumber = (monday.difference(mondayOfWeek1).inDays ~/ 7) + 1;
    return IsoWeek._(
      year: isoYear,
      weekNumber: weekNumber,
      monday: DateTime(monday.year, monday.month, monday.day),
      sunday: DateTime(sunday.year, sunday.month, sunday.day),
    );
  }

  String get marker =>
      'BUSHIDO_WEEK:$year-W${weekNumber.toString().padLeft(2, '0')}:${BushidoSheetLayout.layoutVersion}';

  @override
  bool operator ==(Object other) =>
      other is IsoWeek && other.year == year && other.weekNumber == weekNumber;

  @override
  int get hashCode => Object.hash(year, weekNumber);

  @override
  String toString() =>
      'IsoWeek($year-W${weekNumber.toString().padLeft(2, '0')})';
}
