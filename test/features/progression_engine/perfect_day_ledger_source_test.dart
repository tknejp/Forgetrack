import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/features/progression_engine/application/perfect_day_ledger_source.dart';
import 'package:forgetrack/features/progression_engine/domain/repository/ledger_snapshot.dart';

ObjectiveCompletionEvent _event(String objectiveId, DateTime day) {
  final key =
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  return ObjectiveCompletionEvent(
    eventKey: 'objective|$objectiveId|$key|completed',
    timestamp: DateTime(day.year, day.month, day.day, 23),
    objectiveId: objectiveId,
    actualValue: 1,
    periodKey: key,
  );
}

LedgerSnapshot _ledger(List<ObjectiveCompletionEvent> events) {
  return LedgerSnapshot(objectiveCompletions: events);
}

List<ObjectiveCompletionEvent> _allFour(DateTime day) {
  return [
    for (final id in PerfectDayLedgerSource.requiredObjectiveIds) _event(id, day),
  ];
}

void main() {
  group('PerfectDayLedgerSource.perfectDates', () {
    test('emits only days where every required objective fired', () {
      final partial = DateTime(2026, 5, 18);
      final perfect = DateTime(2026, 5, 19);
      final events = [
        // Partial day — missing daily_sleep.
        _event('daily_steps', partial),
        _event('daily_calories', partial),
        _event('daily_activity', partial),
        // Fully perfect day.
        ..._allFour(perfect),
      ];
      final dates = PerfectDayLedgerSource.perfectDates(_ledger(events));
      expect(dates, [perfect]);
    });

    test('sorts dates ascending', () {
      final d1 = DateTime(2026, 5, 19);
      final d2 = DateTime(2026, 5, 18);
      final dates = PerfectDayLedgerSource.perfectDates(
        _ledger([..._allFour(d1), ..._allFour(d2)]),
      );
      expect(dates, [d2, d1]);
    });

    test('skips lifetime-scoped events (no periodKey)', () {
      final dates = PerfectDayLedgerSource.perfectDates(_ledger([
        for (final id in PerfectDayLedgerSource.requiredObjectiveIds)
          ObjectiveCompletionEvent(
            eventKey: 'objective|$id|completed',
            timestamp: DateTime(2026, 5, 18),
            objectiveId: id,
            actualValue: 1,
            periodKey: null,
          ),
      ]));
      expect(dates, isEmpty);
    });
  });

  group('PerfectDayLedgerSource.bestStreak', () {
    test('zero for empty input', () {
      expect(PerfectDayLedgerSource.bestStreak(const []), 0);
    });

    test('counts longest consecutive run', () {
      final dates = [
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
        DateTime(2026, 5, 3),
        // Gap.
        DateTime(2026, 5, 10),
        DateTime(2026, 5, 11),
      ];
      expect(PerfectDayLedgerSource.bestStreak(dates), 3);
    });

    test('singleton counts as a 1-day streak', () {
      expect(
        PerfectDayLedgerSource.bestStreak([DateTime(2026, 5, 1)]),
        1,
      );
    });
  });

  group('PerfectDayLedgerSource.perfectWeeksLifetime', () {
    test('counts ISO weeks where every Mon-Sun day appears', () {
      // Monday 2026-05-04 → Sunday 2026-05-10 (week 19).
      final fullWeek = [
        for (var i = 0; i < 7; i++)
          DateTime(2026, 5, 4).add(Duration(days: i)),
      ];
      // Same week minus Sunday — should not count.
      final partial = [
        for (var i = 0; i < 6; i++)
          DateTime(2026, 5, 11).add(Duration(days: i)),
      ];
      final dates = [...fullWeek, ...partial]..sort();
      expect(PerfectDayLedgerSource.perfectWeeksLifetime(dates), 1);
    });

    test('zero when no week has all seven days', () {
      final dates = [
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
        DateTime(2026, 5, 3),
      ];
      expect(PerfectDayLedgerSource.perfectWeeksLifetime(dates), 0);
    });
  });
}
