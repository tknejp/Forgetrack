import 'package:forgetrack/features/health_connect/domain/activity_record.dart';
import 'package:forgetrack/features/health_connect/domain/weight_record.dart';
import 'package:forgetrack/features/nutrition/data/kaloricke_tabulky_service.dart';

abstract interface class BushidoFitnessSource {
  Future<List<StepsRecord>> stepsHistoryForRange(DateTime from, DateTime to);
  Future<WeightRecord?> weightForDate(DateTime date);
}

abstract interface class BushidoNutritionSource {
  Future<KtDayNutrition?> nutritionForDate(DateTime date);
}
