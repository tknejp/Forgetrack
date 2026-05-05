import 'package:health/health.dart';

import '../../domain/activity_record.dart';
import 'hc_read_client.dart';

class HcStepsService {
  HcStepsService(this._client, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final HcReadClient _client;
  final DateTime Function() _now;

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

    final now = _now();
    final today = _client.dayOnly(now);
    final tomorrowStart = today.add(const Duration(days: 1));
    final start = today.subtract(Duration(days: days - 1));

    // Diagnostic: compare today's steps via aggregate with two different query
    // ends. Samsung Health writes an all-day record (dateTo=23:59) that HC only
    // returns when the query end covers the full interval.
    final todayStepsToNow =
        await _client.getTotalStepsInInterval(today, now) ?? 0;
    final todayStepsFullDay =
        await _client.getTotalStepsInInterval(today, tomorrowStart) ?? 0;
    _client.logInfo(
      'getStepsHistory(): today aggregate: '
      'todayStart->now=$todayStepsToNow  '
      'todayStart->tomorrowStart=$todayStepsFullDay',
    );

    // Fetch raw data using tomorrowStart as end (not now) so that Samsung
    // Health all-day records (dateFrom=0:00, dateTo=23:59) are included.
    final points = await _client.fetchData(
      label: 'STEPS_HISTORY',
      start: start,
      end: tomorrowStart,
      types: const [HealthDataType.STEPS],
    );

    _client.logDebug(
      'query local start=${_client.fmt(start)} end=${_client.fmt(tomorrowStart)} '
      'UTC start=${start.toUtc()} end=${tomorrowStart.toUtc()}',
    );
    _client.logDebug('raw step point count=${points.length}');

    // Log unique sources and today's individual records to detect origin issues.
    final sources = points.map((p) => '${p.sourceName}/${p.sourceId}').toSet();
    _client.logDebug('raw step sources: $sources');
    for (final point in points) {
      if (_client.dayOnly(point.dateFrom.toLocal()) == today) {
        _client.logDebug(
          'today raw record: from=${_client.fmt(point.dateFrom.toLocal())} '
          'to=${_client.fmt(point.dateTo.toLocal())} '
          'src=${point.sourceName} pkg=${point.sourceId} '
          'steps=${_client.numericValue(point).round()}',
        );
      }
    }

    final stepsByDay = <DateTime, int>{};
    for (final point in points) {
      final day = _client.dayOnly(point.dateFrom.toLocal());
      final steps = _client.numericValue(point).round();
      stepsByDay.update(day, (value) => value + steps, ifAbsent: () => steps);
    }

    // Always override today with the full-day aggregate result so that Samsung
    // Health all-day totals are captured even when raw records are missing.
    stepsByDay[today] = todayStepsFullDay;

    for (final entry in stepsByDay.entries) {
      _client.logDebug(
          'daily bucket ${_client.fmt(entry.key)}: ${entry.value} steps');
    }

    final records = <StepsRecord>[
      for (int i = 0; i < days; i++)
        StepsRecord(
          date: start.add(Duration(days: i)),
          steps: stepsByDay[start.add(Duration(days: i))] ?? 0,
        ),
    ];

    _client.logInfo(
      'getStepsHistory(): produced ${records.length} daily records, '
      'today=${records.last.steps} steps',
    );
    return records;
  }

  Future<List<StepsRecord>> getStepsHistoryForRange(
    DateTime start,
    DateTime end,
  ) async {
    final startDay = _client.dayOnly(start);
    final endDay = _client.dayOnly(end);

    if (endDay.isBefore(startDay)) {
      return const [];
    }

    // Always use the full calendar day end — do not cap at now — so Samsung
    // Health all-day records (dateTo=23:59) are included for the requested range.
    final queryEnd = endDay.add(const Duration(days: 1));

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
      final day = _client.dayOnly(point.dateFrom.toLocal());
      final steps = _client.numericValue(point).round();
      stepsByDay.update(day, (value) => value + steps, ifAbsent: () => steps);
    }

    // Override today with the full-day aggregate if today falls in the range.
    final today = _client.dayOnly(_now());
    if (!today.isBefore(startDay) && !today.isAfter(endDay)) {
      final tomorrowStart = today.add(const Duration(days: 1));
      final todaySteps =
          await _client.getTotalStepsInInterval(today, tomorrowStart) ?? 0;
      stepsByDay[today] = todaySteps;
      _client.logDebug(
          'getStepsHistoryForRange(): today aggregate override=$todaySteps');
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
