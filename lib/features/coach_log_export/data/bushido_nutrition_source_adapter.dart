import 'package:forgetrack/features/coach_log_export/domain/bushido_data_sources.dart';
import 'package:forgetrack/features/nutrition/application/kaloricke_tabulky_provider.dart';
import 'package:forgetrack/features/nutrition/data/kaloricke_tabulky_service.dart';

class BushidoNutritionSourceAdapter implements BushidoNutritionSource {
  final KalorickeTabulkyProvider _provider;

  const BushidoNutritionSourceAdapter(this._provider);

  @override
  Future<KtDayNutrition?> nutritionForDate(DateTime date) async =>
      _provider.nutritionForDate(date);
}
