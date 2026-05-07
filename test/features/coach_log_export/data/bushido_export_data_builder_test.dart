import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_export_data_builder.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_data_sources.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';
import 'package:forgetrack/features/health_connect/domain/activity_record.dart';
import 'package:forgetrack/features/health_connect/domain/weight_record.dart';
import 'package:forgetrack/features/nutrition/data/kaloricke_tabulky_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeFitness implements BushidoFitnessSource {
  final Map<String, int> stepsMap;
  final Map<String, double> weightMap;

  _FakeFitness({this.stepsMap = const {}, this.weightMap = const {}});

  @override
  Future<List<StepsRecord>> stepsHistoryForRange(DateTime from, DateTime to) async {
    final records = <StepsRecord>[];
    var d = from;
    while (!d.isAfter(to)) {
      final key = _key(d);
      if (stepsMap.containsKey(key)) records.add(StepsRecord(date: d, steps: stepsMap[key]!));
      d = d.add(const Duration(days: 1));
    }
    return records;
  }

  @override
  Future<WeightRecord?> weightForDate(DateTime date) async {
    final w = weightMap[_key(date)];
    return w != null ? WeightRecord(date: date, weight: w) : null;
  }
}

class _FakeNutrition implements BushidoNutritionSource {
  final Map<String, KtDayNutrition> map;

  _FakeNutrition(this.map);

  @override
  Future<KtDayNutrition?> nutritionForDate(DateTime date) async => map[_key(date)];
}

String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

KtDayNutrition _kt({
  double calories = 0,
  double protein = 0,
  double fat = 0,
  double carbs = 0,
  double fiber = 0,
  int foodCount = 1,
}) =>
    KtDayNutrition(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      foodCount: foodCount,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final week = IsoWeek.fromDate(DateTime(2026, 1, 5)); // 2026-W02: Jan 5–11

  BushidoExportDataBuilder builder({
    Map<String, int> steps = const {},
    Map<String, double> weight = const {},
    Map<String, KtDayNutrition> nutrition = const {},
  }) =>
      BushidoExportDataBuilder(
        fitness: _FakeFitness(stepsMap: steps, weightMap: weight),
        nutrition: _FakeNutrition(nutrition),
      );

  group('BushidoExportDataBuilder.build', () {
    test('all-null week: no data sources return anything → every field is null', () async {
      final report = await builder().build(week);

      expect(report.week, week);
      expect(report.days.length, 7);
      for (final day in report.days) {
        expect(day.weightKg, isNull, reason: '${day.date} weightKg');
        expect(day.steps, isNull, reason: '${day.date} steps');
        expect(day.kcal, isNull, reason: '${day.date} kcal');
        expect(day.proteinG, isNull, reason: '${day.date} proteinG');
        expect(day.carbsG, isNull, reason: '${day.date} carbsG');
        expect(day.fatG, isNull, reason: '${day.date} fatG');
        expect(day.fiberG, isNull, reason: '${day.date} fiberG');
      }
    });

    test('partial data: only Wed (Jan 7) and Fri (Jan 9) have data', () async {
      final wed = DateTime(2026, 1, 7);
      final fri = DateTime(2026, 1, 9);
      final report = await builder(
        steps: {_key(wed): 8000, _key(fri): 12000},
        weight: {_key(wed): 82.3},
        nutrition: {
          _key(fri): _kt(calories: 2100, protein: 150, carbs: 200, fat: 70, fiber: 30),
        },
      ).build(week);

      final days = {for (final d in report.days) d.date.weekday: d};

      // Wednesday (weekday 3)
      expect(days[3]!.steps, 8000);
      expect(days[3]!.weightKg, 82.3);
      expect(days[3]!.kcal, isNull);

      // Friday (weekday 5)
      expect(days[5]!.steps, 12000);
      expect(days[5]!.weightKg, isNull);
      expect(days[5]!.kcal, 2100);
      expect(days[5]!.proteinG, 150);

      // Monday (weekday 1) — untouched
      expect(days[1]!.steps, isNull);
      expect(days[1]!.kcal, isNull);
    });

    test('KT kcal == 0 with foodCount > 0 is legitimate zero, not null', () async {
      final mon = DateTime(2026, 1, 5);
      final report = await builder(
        nutrition: {_key(mon): _kt(calories: 0, foodCount: 1)},
      ).build(week);

      expect(report.days.first.kcal, 0);
    });

    test('steps == 0 from source is legitimate zero, not null', () async {
      final mon = DateTime(2026, 1, 5);
      final report = await builder(steps: {_key(mon): 0}).build(week);

      expect(report.days.first.steps, 0);
    });

    test('weight is rounded to 1 decimal place', () async {
      final mon = DateTime(2026, 1, 5);
      final report = await builder(weight: {_key(mon): 82.349}).build(week);

      expect(report.days.first.weightKg, 82.3);
    });

    test('month-boundary week (2025-W53 / Dec 29 2025 – Jan 4 2026)', () async {
      final w53 = IsoWeek.fromDate(DateTime(2025, 12, 29));
      final dec31 = DateTime(2025, 12, 31);
      final jan2 = DateTime(2026, 1, 2);
      final report = await builder(
        steps: {_key(dec31): 5000, _key(jan2): 7000},
        weight: {_key(jan2): 80.0},
      ).build(w53);

      expect(report.week, w53);
      expect(report.days.length, 7);

      final dec31Day = report.days.firstWhere((d) => d.date.day == 31 && d.date.month == 12);
      final jan2Day = report.days.firstWhere((d) => d.date.day == 2 && d.date.month == 1);

      expect(dec31Day.steps, 5000);
      expect(dec31Day.weightKg, isNull);
      expect(jan2Day.steps, 7000);
      expect(jan2Day.weightKg, 80.0);
    });

    test('future week: no data available → all nulls, report still valid', () async {
      final future = IsoWeek.fromDate(DateTime(2030, 6, 1));
      final report = await builder().build(future);

      expect(report.week, future);
      expect(report.days.length, 7);
      expect(report.days.every((d) => d.steps == null && d.kcal == null), isTrue);
    });
  });
}
