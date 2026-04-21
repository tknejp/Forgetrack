import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/models/weight_record.dart';
import 'package:forgetrack/providers/fitness_provider/fitness_queries.dart';

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
}
