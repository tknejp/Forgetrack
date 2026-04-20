import 'package:health/health.dart';

import 'hc_read_client.dart';

class HcCaloriesService {
  HcCaloriesService(this._client);

  final HcReadClient _client;

  Future<double> getActiveCaloriesBurned(DateTime start, DateTime end) async {
    final points = await _client.fetchData(
      label: 'ACTIVE_ENERGY_BURNED',
      start: start,
      end: end,
      types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
    );

    final total = _client.sumNumericValues(points);

    _client.logInfo(
      'getActiveCaloriesBurned(): total=$total from=${_client.fmt(start)} to=${_client.fmt(end)}',
    );

    return total;
  }

  Future<List<double>> getActiveCaloriesHistory(int days) async {
    _client.logDebug('getActiveCaloriesHistory(days=$days)');

    final now = DateTime.now();
    final start = _client.dayOnly(now).subtract(Duration(days: days - 1));

    // Single range fetch instead of one HC API call per day.
    final points = await _client.fetchData(
      label: 'ACTIVE_ENERGY_BURNED_HISTORY',
      start: start,
      end: now,
      types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
    );

    final caloriesByDay = <DateTime, double>{};
    for (final point in points) {
      final day = _client.dayOnly(point.dateFrom);
      final calories = _client.numericValue(point);
      caloriesByDay.update(
        day,
        (value) => value + calories,
        ifAbsent: () => calories,
      );
    }

    final result = <double>[
      for (int i = 0; i < days; i++)
        caloriesByDay[start.add(Duration(days: i))] ?? 0.0,
    ];

    _client.logInfo(
      'getActiveCaloriesHistory(): produced ${result.length} values',
    );
    return result;
  }
}
