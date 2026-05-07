import 'package:health/health.dart';

import '../../domain/weight_record.dart';
import 'hc_read_client.dart';

class HcBodyService {
  HcBodyService(this._client);

  final HcReadClient _client;

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// Fetches body fat measurements for the given window.
  /// Returns a map of date-key → fat percentage.
  /// Never throws — returns empty map on any error.
  Future<Map<String, double>> _bodyFatByDate(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final points = await _client.fetchData(
        label: 'BODY_FAT_PERCENTAGE',
        start: start,
        end: end,
        types: const [HealthDataType.BODY_FAT_PERCENTAGE],
      );
      final map = <String, double>{};
      for (final p in points) {
        map[_dateKey(p.dateFrom)] = _client.numericValue(p);
      }
      _client.logInfo('_bodyFatByDate(): ${map.length} entries');
      return map;
    } catch (e) {
      _client.logInfo('_bodyFatByDate(): failed, returning empty — $e');
      return {};
    }
  }

  /// Fetches body water mass (kg) for the given window.
  /// Returns a map of date-key → water mass in kg.
  /// Never throws — returns empty map on any error.
  Future<Map<String, double>> _bodyWaterByDate(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final points = await _client.fetchData(
        label: 'BODY_WATER_MASS',
        start: start,
        end: end,
        types: const [HealthDataType.BODY_WATER_MASS],
      );
      final map = <String, double>{};
      for (final p in points) {
        map[_dateKey(p.dateFrom)] = _client.numericValue(p);
      }
      _client.logInfo('_bodyWaterByDate(): ${map.length} entries');
      return map;
    } catch (e) {
      _client.logInfo('_bodyWaterByDate(): failed, returning empty — $e');
      return {};
    }
  }

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

    final fatByDate = await _bodyFatByDate(start, end);
    final waterByDate = await _bodyWaterByDate(start, end);

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final result = points
        .map(
          (p) => WeightRecord(
            date: p.dateFrom,
            weight: _client.numericValue(p),
            bodyFat: fatByDate[_dateKey(p.dateFrom)],
            bodyWater: waterByDate[_dateKey(p.dateFrom)],
          ),
        )
        .toList();

    _client.logInfo(
      'getWeightHistory(): ${result.length} weight, ${fatByDate.length} fat, ${waterByDate.length} water entries',
    );
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

    final fatByDate = await _bodyFatByDate(startDay, queryEnd);
    final waterByDate = await _bodyWaterByDate(startDay, queryEnd);

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final result = points
        .map(
          (p) => WeightRecord(
            date: p.dateFrom,
            weight: _client.numericValue(p),
            bodyFat: fatByDate[_dateKey(p.dateFrom)],
            bodyWater: waterByDate[_dateKey(p.dateFrom)],
          ),
        )
        .toList();

    _client.logInfo(
      'getWeightHistoryForRange(): ${result.length} weight, ${fatByDate.length} fat, ${waterByDate.length} water entries',
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
