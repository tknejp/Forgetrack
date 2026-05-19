import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/nutrition/domain/nutrition_snapshot.dart';

void main() {
  group('NutritionSnapshot', () {
    test('empty sentinel anchored at unix epoch with zero macros', () {
      final snap = NutritionSnapshot.empty;
      expect(snap.evaluatedDate,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      expect(snap.caloriesToday, 0);
      expect(snap.proteinGramsToday, 0);
      expect(snap.carbsGramsToday, 0);
      expect(snap.fatGramsToday, 0);
      expect(snap.fiberGramsToday, 0);
    });

    test('equality is value-based across every macro', () {
      final base = NutritionSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        caloriesToday: 2200,
        proteinGramsToday: 145,
        carbsGramsToday: 230,
        fatGramsToday: 72,
        fiberGramsToday: 28,
      );
      final twin = NutritionSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        caloriesToday: 2200,
        proteinGramsToday: 145,
        carbsGramsToday: 230,
        fatGramsToday: 72,
        fiberGramsToday: 28,
      );
      expect(base, equals(twin));
      expect(base.hashCode, twin.hashCode);

      expect(base, isNot(equals(base.copyWith(caloriesToday: 2400))));
      expect(base, isNot(equals(base.copyWith(fiberGramsToday: 30))));
    });

    test('copyWith preserves untouched fields', () {
      final base = NutritionSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        caloriesToday: 2200,
        proteinGramsToday: 145,
      );
      final updated = base.copyWith(caloriesToday: 2400);

      expect(updated.caloriesToday, 2400);
      expect(updated.proteinGramsToday, 145);
      expect(updated.evaluatedDate, DateTime(2026, 5, 18));
    });

    test('signature changes when any tracked field changes', () {
      final base = NutritionSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        caloriesToday: 2200,
      );
      expect(base.signature,
          isNot(base.copyWith(caloriesToday: 2400).signature));
      expect(base.signature,
          isNot(base.copyWith(evaluatedDate: DateTime(2026, 5, 19)).signature));
    });
  });
}
