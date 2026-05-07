import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';

void main() {
  group('IsoWeek.fromDate', () {
    // Reference: Jan 1 2026 = Thursday; Dec 29 2025 = Monday of 2026-W01
    test('2026-01-01 (Thursday) belongs to 2026-W01', () {
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1));
      expect(week.year, 2026);
      expect(week.weekNumber, 1);
      expect(week.monday, DateTime(2025, 12, 29));
      expect(week.sunday, DateTime(2026, 1, 4));
    });

    test('2025-12-31 (Wednesday) also belongs to 2026-W01', () {
      final week = IsoWeek.fromDate(DateTime(2025, 12, 31));
      expect(week.year, 2026);
      expect(week.weekNumber, 1);
    });

    test('2025-12-28 (Sunday) belongs to 2025-W52', () {
      // 2025 has 52 weeks; Dec 28 is the last day of 2025-W52
      final week = IsoWeek.fromDate(DateTime(2025, 12, 28));
      expect(week.year, 2025);
      expect(week.weekNumber, 52);
      expect(week.monday, DateTime(2025, 12, 22));
      expect(week.sunday, DateTime(2025, 12, 28));
    });

    test('Monday input: week.monday equals that date', () {
      // Jan 5, 2026 is the Monday that starts W02 (W01 runs Dec 29 – Jan 4)
      final week = IsoWeek.fromDate(DateTime(2026, 1, 5));
      expect(week.year, 2026);
      expect(week.weekNumber, 2);
      expect(week.monday, DateTime(2026, 1, 5));
    });

    test('time component is stripped before computing week', () {
      final midnight = IsoWeek.fromDate(DateTime(2026, 1, 1, 0, 0));
      final endOfDay = IsoWeek.fromDate(DateTime(2026, 1, 1, 23, 59, 59));
      expect(midnight, endOfDay);
    });
  });

  group('IsoWeek.marker', () {
    test('single-digit week number is zero-padded', () {
      // Jan 1, 2026 is in W01 (W01 = Dec 29 2025 – Jan 4 2026)
      expect(
        IsoWeek.fromDate(DateTime(2026, 1, 1)).marker,
        'BUSHIDO_WEEK:2026-W01:v1',
      );
    });

    test('two-digit week number needs no padding', () {
      expect(
        IsoWeek.fromDate(DateTime(2025, 12, 28)).marker,
        'BUSHIDO_WEEK:2025-W52:v1',
      );
    });
  });

  group('IsoWeek equality and hashCode', () {
    test('two dates in the same week are equal', () {
      final monday = IsoWeek.fromDate(DateTime(2026, 1, 5));
      final thursday = IsoWeek.fromDate(DateTime(2026, 1, 8));
      expect(monday, equals(thursday));
    });

    test('dates in different weeks are not equal', () {
      final w1 = IsoWeek.fromDate(DateTime(2026, 1, 5));
      final w2 = IsoWeek.fromDate(DateTime(2026, 1, 12));
      expect(w1, isNot(equals(w2)));
    });

    test('equal weeks have the same hash code', () {
      final a = IsoWeek.fromDate(DateTime(2026, 1, 5));
      final b = IsoWeek.fromDate(DateTime(2026, 1, 7));
      expect(a.hashCode, b.hashCode);
    });
  });
}
