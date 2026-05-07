import 'package:forgetrack/features/coach_log_export/domain/bushido_data_sources.dart';
import 'package:forgetrack/features/health_connect/application/fitness_provider.dart';
import 'package:forgetrack/features/health_connect/domain/activity_record.dart';
import 'package:forgetrack/features/health_connect/domain/weight_record.dart';

class BushidoFitnessSourceAdapter implements BushidoFitnessSource {
  final FitnessProvider _provider;

  const BushidoFitnessSourceAdapter(this._provider);

  @override
  Future<List<StepsRecord>> stepsHistoryForRange(DateTime from, DateTime to) async =>
      _provider.stepsHistoryForRange(from, to);

  @override
  Future<WeightRecord?> weightForDate(DateTime date) async =>
      _provider.weightForDate(date);
}
