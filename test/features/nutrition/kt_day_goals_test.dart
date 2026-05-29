import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/nutrition/application/kaloricke_tabulky_provider.dart';
import 'package:forgetrack/features/nutrition/data/kaloricke_tabulky_service.dart';

void main() {
  group('KtDayNutrition goals (#98)', () {
    test('goal fields round-trip through toJson/fromJson', () {
      final original = KtDayNutrition(
        calories: 2700,
        protein: 216,
        fat: 61,
        carbs: 308,
        fiber: 26,
        goalCalories: 2785,
        goalProtein: 230,
        goalFat: 85,
        goalCarbs: 275,
        goalFiber: 30,
      );

      final restored = KtDayNutrition.fromJson(original.toJson());

      expect(restored.goalCalories, 2785);
      expect(restored.goalProtein, 230);
      expect(restored.goalFat, 85);
      expect(restored.goalCarbs, 275);
      expect(restored.goalFiber, 30);
    });

    test('hasGoals reflects whether any goal is non-zero', () {
      expect(
        KtDayNutrition(
          calories: 0,
          protein: 0,
          fat: 0,
          carbs: 0,
          fiber: 0,
        ).hasGoals,
        isFalse,
      );
      expect(
        KtDayNutrition(
          calories: 0,
          protein: 0,
          fat: 0,
          carbs: 0,
          fiber: 0,
          goalProtein: 180,
        ).hasGoals,
        isTrue,
      );
    });

    test('old JSON without goal fields decodes goals as zero', () {
      final restored = KtDayNutrition.fromJson({
        'calories': 2000,
        'protein': 120,
      });
      expect(restored.goalCalories, 0);
      expect(restored.hasGoals, isFalse);
    });
  });

  group('KtDayGoals view adapter (#98)', () {
    test('maps the nutrition record goal fields onto the view', () {
      final goals = KtDayGoals.fromNutrition(
        KtDayNutrition(
          calories: 0,
          protein: 0,
          fat: 0,
          carbs: 0,
          fiber: 0,
          goalCalories: 2785,
          goalProtein: 230,
          goalFat: 85,
          goalCarbs: 275,
          goalFiber: 30,
        ),
      );

      expect(goals.calories, 2785);
      expect(goals.protein, 230);
      expect(goals.fat, 85);
      expect(goals.carbs, 275);
      expect(goals.fiber, 30);
      expect(goals.hasData, isTrue);
    });

    test('hasData is false when the source carried no goals', () {
      final goals = KtDayGoals.fromNutrition(
        KtDayNutrition(calories: 2000, protein: 120, fat: 0, carbs: 0, fiber: 0),
      );
      expect(goals.hasData, isFalse);
    });
  });
}
