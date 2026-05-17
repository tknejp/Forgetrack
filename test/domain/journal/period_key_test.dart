// Cross-timezone UTC normalisation tests for PeriodKey.
//
// Audit finding (docs/domain_model/follow_ups.md §1 + §2.12): the
// long-offline + cross-TZ scenario could produce duplicate periodKey
// claims for the same calendar day if the device clock was in a
// different timezone when the second write happened. PeriodKey is
// constructed exclusively via UTC-normalising factories so the same
// UTC instant always yields the same key regardless of the caller's
// local timezone.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/journal/period_key.dart';

void main() {
  group('PeriodKey.day', () {
    test('normalises same UTC instant from any local TZ to same key', () {
      // Same UTC instant — 2026-05-17 23:30 UTC.
      final utcInstant = DateTime.utc(2026, 5, 17, 23, 30);

      // Re-cast as local time in different offsets. Dart's DateTime
      // doesn't carry TZ info beyond local vs UTC, but toUtc() always
      // normalises correctly — that's what the factory relies on.
      final asUtc = utcInstant.toUtc();
      final asLocal = utcInstant.toLocal();

      expect(PeriodKey.day(asUtc).raw, '2026-05-17');
      expect(PeriodKey.day(asLocal).raw, '2026-05-17');
      expect(PeriodKey.day(asUtc), PeriodKey.day(asLocal));
    });

    test('formats as yyyy-MM-dd in UTC', () {
      expect(PeriodKey.day(DateTime.utc(2026, 1, 5)).raw, '2026-01-05');
      expect(PeriodKey.day(DateTime.utc(2026, 12, 31)).raw, '2026-12-31');
      expect(PeriodKey.day(DateTime.utc(0, 1, 1)).raw, '0000-01-01');
    });

    test('two moments on the same UTC day produce the same key', () {
      final morning = DateTime.utc(2026, 5, 17, 6, 0);
      final evening = DateTime.utc(2026, 5, 17, 23, 59, 59);
      expect(PeriodKey.day(morning), PeriodKey.day(evening));
    });

    test('two moments on adjacent UTC days produce different keys', () {
      final endOfDay = DateTime.utc(2026, 5, 17, 23, 59, 59);
      final startOfNextDay = DateTime.utc(2026, 5, 18, 0, 0, 0);
      expect(PeriodKey.day(endOfDay), isNot(PeriodKey.day(startOfNextDay)));
    });
  });

  group('PeriodKey.isoWeek', () {
    test('ISO week 1 contains the year\'s first Thursday', () {
      // 2026-01-01 is a Thursday → week 1 of 2026.
      expect(PeriodKey.isoWeek(DateTime.utc(2026, 1, 1)).raw, '2026-W01');
      // 2025-12-29 (Monday) is in ISO week 1 of 2026 because it shares
      // the Thursday 2026-01-01.
      expect(PeriodKey.isoWeek(DateTime.utc(2025, 12, 29)).raw, '2026-W01');
    });

    test('handles year boundaries (2027 week 1 starts Dec 28 2026)', () {
      // 2027-01-01 is a Friday → ISO week 53 of 2026.
      expect(PeriodKey.isoWeek(DateTime.utc(2027, 1, 1)).raw, '2026-W53');
      // 2027-01-04 is a Monday → ISO week 1 of 2027.
      expect(PeriodKey.isoWeek(DateTime.utc(2027, 1, 4)).raw, '2027-W01');
    });

    test('Monday and Sunday of the same ISO week share a key', () {
      final monday = DateTime.utc(2026, 5, 11);
      final sunday = DateTime.utc(2026, 5, 17);
      expect(monday.weekday, DateTime.monday);
      expect(sunday.weekday, DateTime.sunday);
      expect(PeriodKey.isoWeek(monday), PeriodKey.isoWeek(sunday));
    });

    test('zero-pads week numbers below 10', () {
      // 2026-03-02 falls in ISO week 10. Verify formatting is `W10`,
      // and that an earlier week pads correctly.
      expect(PeriodKey.isoWeek(DateTime.utc(2026, 3, 2)).raw, '2026-W10');
      expect(PeriodKey.isoWeek(DateTime.utc(2026, 1, 1)).raw, '2026-W01');
    });
  });

  group('PeriodKey.lifetime and .chapter', () {
    test('lifetime is a stable singleton', () {
      expect(PeriodKey.lifetime.raw, 'lifetime');
      expect(PeriodKey.lifetime, PeriodKey.lifetime);
    });

    test('chapter namespaces by id', () {
      expect(
        PeriodKey.chapter('forest_trial').raw,
        'chapter:forest_trial',
      );
      expect(
        PeriodKey.chapter('forest_trial'),
        PeriodKey.chapter('forest_trial'),
      );
      expect(
        PeriodKey.chapter('forest_trial'),
        isNot(PeriodKey.chapter('pilgrim_path')),
      );
    });
  });

  group('PeriodKey.fromRaw', () {
    test('round-trips a previously serialised value verbatim', () {
      final original = PeriodKey.day(DateTime.utc(2026, 5, 17));
      final roundTripped = PeriodKey.fromRaw(original.raw);
      expect(roundTripped, original);
      expect(roundTripped.raw, '2026-05-17');
    });

    test('preserves legacy / malformed raw strings without re-normalising', () {
      // Pre-Phase-2 data may have stored TZ-dependent keys. fromRaw is
      // trust-the-store — devtools audit, not application code, decides
      // whether to clean such records up. See follow_ups.md §2.12.
      final legacy = PeriodKey.fromRaw('2026/05/17');
      expect(legacy.raw, '2026/05/17');
    });
  });

  group('equality and hashCode', () {
    test('value equality holds across different factory paths', () {
      final fromDay = PeriodKey.day(DateTime.utc(2026, 5, 17));
      final fromRaw = PeriodKey.fromRaw('2026-05-17');
      expect(fromDay, fromRaw);
      expect(fromDay.hashCode, fromRaw.hashCode);
    });

    test('different keys are not equal', () {
      expect(
        PeriodKey.day(DateTime.utc(2026, 5, 17)),
        isNot(PeriodKey.day(DateTime.utc(2026, 5, 18))),
      );
      expect(PeriodKey.lifetime, isNot(PeriodKey.fromRaw('lifetime_v2')));
    });
  });
}
