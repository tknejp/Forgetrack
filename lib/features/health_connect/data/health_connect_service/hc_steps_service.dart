import 'package:health/health.dart';

import '../../domain/activity_record.dart';
import 'hc_read_client.dart';

class HcStepsService {
  HcStepsService(this._client);

  final HcReadClient _client;

  Future<int> getStepsForDate(DateTime date) async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      _client.logDebug(
        'getStepsForDate(): date=${start.toIso8601String().split("T").first}',
      );

      final steps = await _client.getTotalStepsInInterval(start, end) ?? 0;

      _client.logInfo(
        'getStepsForDate(): ${start.toIso8601String().split("T").first} => $steps',
      );

      return steps;
    } catch (e, st) {
      _client.logError(
        'getStepsForDate() failed for ${start.toIso8601String().split("T").first}',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<List<StepsRecord>> getStepsHistory(int days) async {
    _client.logDebug('getStepsHistory(days=$days)');

    final now = DateTime.now();
    final start = _client.dayOnly(now).subtract(Duration(days: days - 1));

    // Single range fetch instead of one HC API call per day.
    final points = await _client.fetchData(
      label: 'STEPS_HISTORY',
      start: start,
      end: now,
      types: const [HealthDataType.STEPS],
    );

    final stepsByDay = <DateTime, int>{};
    for (final point in points) {
      final day = _client.dayOnly(point.dateFrom);
      final steps = _client.numericValue(point).round();
      stepsByDay.update(day, (value) => value + steps, ifAbsent: () => steps);
    }

    final records = <StepsRecord>[
      for (int i = 0; i < days; i++)
        StepsRecord(
          date: start.add(Duration(days: i)),
          steps: stepsByDay[start.add(Duration(days: i))] ?? 0,
        ),
    ];

    _client.logInfo(
      'getStepsHistory(): produced ${records.length} daily records',
    );
    return records;
  }

  Future<List<StepsRecord>> getStepsHistoryForRange(
    DateTime start,
    DateTime end,
  ) async {
    final startDay = _client.dayOnly(start);
    final endDay = _client.dayOnly(end);
    final now = DateTime.now();
    final queryEnd = endDay.add(const Duration(days: 1)).isBefore(now)
        ? endDay.add(const Duration(days: 1))
        : now;

    if (endDay.isBefore(startDay) || !queryEnd.isAfter(startDay)) {
      return const [];
    }

    _client.logDebug(
      'getStepsHistoryForRange(${_client.fmt(startDay)} -> ${_client.fmt(endDay)})',
    );

    final points = await _client.fetchData(
      label: 'STEPS_HISTORY_RANGE',
      start: startDay,
      end: queryEnd,
      types: const [HealthDataType.STEPS],
    );

    final stepsByDay = <DateTime, int>{};
    for (final point in points) {
      final day = _client.dayOnly(point.dateFrom);
      final steps = _client.numericValue(point).round();
      stepsByDay.update(day, (value) => value + steps, ifAbsent: () => steps);
    }

    final totalDays = endDay.difference(startDay).inDays + 1;
    return [
      for (int i = 0; i < totalDays; i++)
        StepsRecord(
          date: startDay.add(Duration(days: i)),
          steps: stepsByDay[startDay.add(Duration(days: i))] ?? 0,
        ),
    ];
  }
}
