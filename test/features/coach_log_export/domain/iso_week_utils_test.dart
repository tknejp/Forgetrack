import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week_utils.dart';

void main() {
  group('dateOnly', () {
    test('midnight input returns same date as local DateTime', () {
      expect(dateOnly(DateTime(2026, 5, 7, 0, 0, 0)), DateTime(2026, 5, 7));
    });

    test('noon input strips time', () {
      expect(
        dateOnly(DateTime(2026, 5, 7, 12, 30, 45)),
        DateTime(2026, 5, 7),
      );
    });

    test('end-of-day input strips time', () {
      expect(
        dateOnly(DateTime(2026, 5, 7, 23, 59, 59, 999)),
        DateTime(2026, 5, 7),
      );
    });

    test('UTC input preserves date components and returns local DateTime', () {
      final result = dateOnly(DateTime.utc(2026, 5, 7, 12, 0));
      expect(result.year, 2026);
      expect(result.month, 5);
      expect(result.day, 7);
      expect(result.isUtc, isFalse,
          reason: 'dateOnly always returns a local DateTime');
    });
  });

  group('startOfIsoWeek', () {
    // Reference: Jan 1 2026 = Thursday; Jan 5 2026 = Monday
    test('Monday returns itself', () {
      expect(startOfIsoWeek(DateTime(2026, 1, 5)), DateTime(2026, 1, 5));
    });

    test('Wednesday returns the Monday of the same week', () {
      expect(startOfIsoWeek(DateTime(2026, 1, 7)), DateTime(2026, 1, 5));
    });

    test('Sunday returns Monday of the same ISO week — not the next Monday', () {
      // ISO 8601: Sunday is the last day of the week, not the first
      expect(startOfIsoWeek(DateTime(2026, 1, 11)), DateTime(2026, 1, 5));
    });

    test('time component is stripped before computing', () {
      expect(
        startOfIsoWeek(DateTime(2026, 1, 7, 23, 59)),
        DateTime(2026, 1, 5),
      );
    });
  });

  group('isoWeeksOverlapping', () {
    test('range within a single week returns one week', () {
      // Jan 6 (Tue) – Jan 8 (Thu), both in 2026-W01
      final weeks = isoWeeksOverlapping(
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 8),
      );
      expect(weeks.length, 1);
      expect(weeks.first, IsoWeek.fromDate(DateTime(2026, 1, 5)));
    });

    test('Monday-to-Sunday of the same week returns one week', () {
      final weeks = isoWeeksOverlapping(
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 11),
      );
      expect(weeks.length, 1);
    });

    test('Monday-to-following-Monday spans two weeks', () {
      // Jan 5 = W02 Mon; Jan 12 = W03 Mon — both are touched
      final weeks = isoWeeksOverlapping(
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 12),
      );
      expect(weeks.length, 2);
      expect(weeks[0].weekNumber, 2);
      expect(weeks[1].weekNumber, 3);
    });

    test('range spanning 4 full weeks returns 4 weeks', () {
      // Jan 1 (W01) through Jan 25 (last day of W04)
      // W01: Dec 29–Jan 4 | W02: Jan 5–11 | W03: Jan 12–18 | W04: Jan 19–25
      final weeks = isoWeeksOverlapping(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 25),
      );
      expect(weeks.length, 4);
      expect(weeks.map((w) => w.weekNumber).toList(), [1, 2, 3, 4]);
    });

    test('range crossing year boundary covers 2025-W52 and 2026-W01', () {
      // 2025 has 52 weeks (starts on Wednesday, not a leap year).
      // 2025-W52: Mon Dec 22 – Sun Dec 28. 2026-W01: Mon Dec 29 – Sun Jan 4.
      final weeks = isoWeeksOverlapping(
        DateTime(2025, 12, 25), // Thursday in 2025-W52
        DateTime(2026, 1, 4),   // Sunday in 2026-W01
      );
      expect(weeks.length, 2);
      expect(weeks[0].year, 2025);
      expect(weeks[0].weekNumber, 52);
      expect(weeks[1].year, 2026);
      expect(weeks[1].weekNumber, 1);
    });

    test('from == to returns exactly one week', () {
      final weeks = isoWeeksOverlapping(
        DateTime(2026, 3, 15),
        DateTime(2026, 3, 15),
      );
      expect(weeks.length, 1);
    });
  });

  group('nextIsoWeekAfter', () {
    test('last week of 2025 advances to 2026-W01', () {
      // Dec 28 2025 is in 2025-W52; next week wraps to 2026-W01
      final next = nextIsoWeekAfter(DateTime(2025, 12, 28));
      expect(next.year, 2026);
      expect(next.weekNumber, 1);
    });

    test('mid-year advances by exactly one week', () {
      // May 7 2026 (Thursday) is in 2026-W19; next is W20
      final next = nextIsoWeekAfter(DateTime(2026, 5, 7));
      expect(next.year, 2026);
      expect(next.weekNumber, 20);
    });
  });
}
