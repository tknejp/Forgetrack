import 'package:health/health.dart';

import '../../models/weight_record.dart';
import 'hc_read_client.dart';

class HcBodyService {
  HcBodyService(this._client);

  final HcReadClient _client;

  Future<List<WeightRecord>> getWeightHistory(int days) async {
    final end = DateTime.now();
    final start = DateTime(end.year, end.month, end.day)
        .subtract(Duration(days: days - 1));

    final points = await _client.fetchData(
      label: 'WEIGHT',
      start: start,
      end: end,
      types: const [HealthDataType.WEIGHT],
    );

    if (points.isEmpty) {
      _client.logInfo('getWeightHistory(): no data');
      return [];
    }

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final result = points
        .map(
          (p) => WeightRecord(
            date: p.dateFrom,
            weight: _client.numericValue(p),
          ),
        )
        .toList();

    _client.logInfo('getWeightHistory(): ${result.length} weight entries');
    return result;
  }

  Future<double?> getLatestBodyFat() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 365));

    final points = await _client.fetchData(
      label: 'BODY_FAT_PERCENTAGE',
      start: start,
      end: end,
      types: const [HealthDataType.BODY_FAT_PERCENTAGE],
    );

    if (points.isEmpty) {
      _client.logInfo('getLatestBodyFat(): no data');
      return null;
    }

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final latest = _client.numericValue(points.last);

    _client.logInfo('getLatestBodyFat(): latest=$latest');
    return latest;
  }
}
