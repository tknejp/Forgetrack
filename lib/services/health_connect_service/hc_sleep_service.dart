import 'package:health/health.dart';

import '../../models/sleep_record.dart';
import 'hc_read_client.dart';

class HcSleepService {
  HcSleepService(this._client);

  final HcReadClient _client;

  bool _overlapsWindow(
    HealthDataPoint point,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    return point.dateTo.isAfter(windowStart) &&
        point.dateFrom.isBefore(windowEnd);
  }

  SleepRecord? _buildSleepRecord(
    List<HealthDataPoint> points, {
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    if (points.isEmpty || !windowEnd.isAfter(windowStart)) return null;

    Duration total = Duration.zero;
    DateTime? earliest;
    DateTime? latest;

    for (final point in points) {
      final start =
          point.dateFrom.isAfter(windowStart) ? point.dateFrom : windowStart;
      final end = point.dateTo.isBefore(windowEnd) ? point.dateTo : windowEnd;

      if (!end.isAfter(start)) continue;

      total += end.difference(start);
      earliest = earliest == null || start.isBefore(earliest) ? start : earliest;
      latest = latest == null || end.isAfter(latest) ? end : latest;
    }

    if (total == Duration.zero || earliest == null || latest == null) {
      return null;
    }

    return SleepRecord(
      sleepStart: earliest,
      wakeTime: latest,
      totalDuration: total,
    );
  }

  /// Returns the aggregated sleep record for the night ending on [date].
  ///
  /// The lookup window is 18:00 the previous day → 14:00 on [date], which
  /// covers all typical overnight sleep patterns including late bedtimes and
  /// morning lie-ins while excluding the following night's sleep.
  ///
  /// [totalDuration] is the sum of all individual SLEEP_SESSION durations
  /// within the window — not the wall-clock span from first sleep to last
  /// wake, which would inflate the number by awake time between sessions.
  Future<SleepRecord?> getSleepForNight(DateTime date) async {
    final dayStart = _client.dayOnly(date);
    final windowStart = dayStart.subtract(const Duration(hours: 6)); // 18:00 prev day
    final windowEnd = dayStart.add(const Duration(hours: 14)); // 14:00 today
    final now = DateTime.now();
    final end = windowEnd.isBefore(now) ? windowEnd : now;

    final points = await _client.fetchData(
      label: 'SLEEP_SESSION',
      start: windowStart,
      end: end,
      types: const [HealthDataType.SLEEP_SESSION],
    );

    final record = _buildSleepRecord(
      points,
      windowStart: windowStart,
      windowEnd: end,
    );

    if (record == null) {
      _client.logInfo(
        'getSleepForNight(): no sleep data for ${_client.fmt(dayStart)}',
      );
      return null;
    }

    _client.logInfo(
      'getSleepForNight(): total=${record.totalDuration.inMinutes}min'
      ' start=${_client.fmt(record.sleepStart)} wake=${_client.fmt(record.wakeTime)}',
    );

    return record;
  }

  Future<List<SleepRecord>> getSleepHistory(int nights) async {
    _client.logDebug('getSleepHistory(nights=$nights)');

    final now = DateTime.now();
    final latestDay = _client.dayOnly(now);
    final oldestDay = latestDay.subtract(Duration(days: nights - 1));
    final start = oldestDay.subtract(const Duration(hours: 6));
    final rawEnd = latestDay.add(const Duration(hours: 14));
    final end = rawEnd.isBefore(now) ? rawEnd : now;

    if (!end.isAfter(start)) return const [];

    final points = await _client.fetchData(
      label: 'SLEEP_SESSION_HISTORY',
      start: start,
      end: end,
      types: const [HealthDataType.SLEEP_SESSION],
    );

    final records = <SleepRecord>[];
    for (int i = 0; i < nights; i++) {
      final dayStart = latestDay.subtract(Duration(days: i));
      final windowStart = dayStart.subtract(const Duration(hours: 6));
      final rawWindowEnd = dayStart.add(const Duration(hours: 14));
      final windowEnd = rawWindowEnd.isBefore(now) ? rawWindowEnd : now;

      final nightlyPoints = points
          .where((point) => _overlapsWindow(point, windowStart, windowEnd))
          .toList();

      final record = _buildSleepRecord(
        nightlyPoints,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      if (record != null) {
        records.add(record);
      }
    }

    _client.logInfo(
      'getSleepHistory(): produced ${records.length} nightly records',
    );
    return records;
  }
}
