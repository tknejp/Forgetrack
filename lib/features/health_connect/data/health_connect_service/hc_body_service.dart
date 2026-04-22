import 'package:health/health.dart';

import '../../domain/weight_record.dart';
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

  Future<List<WeightRecord>> getWeightHistoryForRange(
    DateTime start,
    DateTime end,
  ) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final now = DateTime.now();
    final queryEnd = endDay.add(const Duration(days: 1)).isBefore(now)
        ? endDay.add(const Duration(days: 1))
        : now;

    if (endDay.isBefore(startDay) || !queryEnd.isAfter(startDay)) {
      return const [];
    }

    final points = await _client.fetchData(
      label: 'WEIGHT_RANGE',
      start: startDay,
      end: queryEnd,
      types: const [HealthDataType.WEIGHT],
    );

    if (points.isEmpty) {
      _client.logInfo('getWeightHistoryForRange(): no data');
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

    _client.logInfo(
      'getWeightHistoryForRange(): ${result.length} weight entries',
    );
    return result;
  }

  Future<double?> getLatestBodyFat({int lookbackDays = 365}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: lookbackDays));

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
