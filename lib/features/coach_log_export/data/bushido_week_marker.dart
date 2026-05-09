import 'package:forgetrack/features/coach_log_export/domain/bushido_sheet_layout.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';

class BushidoWeekMarker {
  BushidoWeekMarker._();

  static final RegExp _regex =
      RegExp(r'^BUSHIDO_WEEK:(\d{4})-W(\d{2}):v(\d+)$');

  static String format(IsoWeek week) => 'BUSHIDO_WEEK:${week.year}-W'
      '${week.weekNumber.toString().padLeft(2, '0')}'
      ':${BushidoSheetLayout.layoutVersion}';

  static ({IsoWeek week, String version})? parse(String raw) {
    final m = _regex.firstMatch(raw);
    if (m == null) return null;
    final year = int.parse(m.group(1)!);
    final weekNum = int.parse(m.group(2)!);
    final version = 'v${m.group(3)!}';
    // Reconstruct the IsoWeek by anchoring to the Thursday of (year, weekNum):
    // ISO Thursday determines the year, so this round-trips correctly.
    final jan4 = DateTime.utc(year, 1, 4);
    final mondayOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    final monday = mondayOfWeek1.add(Duration(days: 7 * (weekNum - 1)));
    final week = IsoWeek.fromDate(monday);
    return (week: week, version: version);
  }
}
