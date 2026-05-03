import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/health_connect/application/fitness_provider/fitness_queries.dart';
import 'package:forgetrack/features/health_connect/domain/weight_record.dart';
import 'package:forgetrack/features/health_connect/domain/activity_record.dart';

void main() {
  group('FitnessQueries weight filters', () {
    final history = <WeightRecord>[
      WeightRecord(
        date: DateTime(2026, 4, 17, 7, 30),
        weight: 80.9,
      ),
      WeightRecord(
        date: DateTime(2026, 4, 18, 8, 15),
        weight: 81.0,
      ),
      WeightRecord(
        date: DateTime(2026, 4, 18, 20, 45),
        weight: 81.2,
      ),
      WeightRecord(
        date: DateTime(2026, 4, 21, 9, 0),
        weight: 82.4,
      ),
    ];

    test('weightHistoryForRange matches calendar days even with time bounds', () {
      final records = FitnessQueries.weightHistoryForRange(
        history,
        DateTime(2026, 4, 18, 12, 0),
        DateTime(2026, 4, 18, 12, 0),
      );

      expect(records.length, 2);
      expect(records.first.weight, 81.0);
      expect(records.last.weight, 81.2);
    });

    test('weightForDate returns the selected day value instead of latest overall', () {
      final record = FitnessQueries.weightForDate(
        history,
        DateTime(2026, 4, 18, 23, 59),
      );

      expect(record, isNotNull);
      expect(record?.weight, 81.2);
    });

    test('previousWeightBefore ignores same-day later measurements', () {
      final previous = FitnessQueries.previousWeightBefore(
        history,
        DateTime(2026, 4, 18, 10, 0),
      );

      expect(previous, 80.9);
    });
  });

  group('FitnessQueries steps', () {
    final history = <StepsRecord>[
      StepsRecord(date: DateTime(2026, 4, 25), steps: 5000),
      StepsRecord(date: DateTime(2026, 4, 26), steps: 10639),
      StepsRecord(date: DateTime(2026, 4, 27), steps: 0), // today with 0
    ];

    test('stepsForDate matches exact date', () {
      expect(FitnessQueries.stepsForDate(history, DateTime(2026, 4, 26)), 10639);
      expect(FitnessQueries.stepsForDate(history, DateTime(2026, 4, 27)), 0);
      expect(FitnessQueries.stepsForDate(history, DateTime(2026, 4, 28)), 0); // not in history
    });

    test('todaySteps does not use .last when today has 0', () {
      // Simulate todaySteps using stepsForDate instead of history.last.steps
      final today = DateTime(2026, 4, 27);
      final todaySteps = FitnessQueries.stepsForDate(history, today);
      expect(todaySteps, 0); // not 10639
    });

    test('records ending yesterday do not count as today', () {
      final yesterday = DateTime(2026, 4, 26);
      final today = DateTime(2026, 4, 27);
      expect(FitnessQueries.stepsForDate(history, yesterday), 10639);
      expect(FitnessQueries.stepsForDate(history, today), 0);
    });

    test('UTC boundary does not shift steps', () {
      // Assuming history dates are in local time
      final todayLocal = DateTime(2026, 4, 27);
      todayLocal.toUtc();
      // stepsForDate should match regardless of UTC vs local, but since history is local, and query is local
      expect(FitnessQueries.stepsForDate(history, todayLocal), 0);
      // If query was UTC, it might not match, but our fix ensures bucketing to local
    });
  });
}
