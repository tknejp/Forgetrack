import 'package:forgetrack/features/coach_log_export/domain/bushido_data_sources.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_day_row.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_week_report.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';

class BushidoExportDataBuilder {
  final BushidoFitnessSource _fitness;
  final BushidoNutritionSource _nutrition;

  const BushidoExportDataBuilder({
    required BushidoFitnessSource fitness,
    required BushidoNutritionSource nutrition,
  })  : _fitness = fitness,
        _nutrition = nutrition;

  Future<BushidoWeekReport> build(IsoWeek week) async {
    final stepsMap = await _fitness
        .stepsHistoryForRange(week.monday, week.sunday)
        .then((list) => {for (final r in list) _dateKey(r.date): r.steps});

    final days = <BushidoDayRow>[];
    for (var i = 0; i < 7; i++) {
      final date = week.monday.add(Duration(days: i));
      final key = _dateKey(date);

      final weight = await _fitness.weightForDate(date);
      final nutrition = await _nutrition.nutritionForDate(date);

      final nt = (nutrition != null && nutrition.hasData) ? nutrition : null;

      days.add(BushidoDayRow(
        date: date,
        weightKg: weight != null
            ? (weight.weight * 10).round() / 10
            : null,
        steps: stepsMap.containsKey(key) ? stepsMap[key] : null,
        kcal: nt?.calories.round(),
        proteinG: nt?.protein.round(),
        carbsG: nt?.carbs.round(),
        fatG: nt?.fat.round(),
        fiberG: nt?.fiber.round(),
      ));
    }

    return BushidoWeekReport(week: week, days: days);
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
