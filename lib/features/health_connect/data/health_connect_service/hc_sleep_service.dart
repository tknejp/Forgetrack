import 'package:health/health.dart';

import '../../domain/sleep_record.dart';
import 'hc_read_client.dart';

class HcSleepService {
  HcSleepService(this._client);

  final HcReadClient _client;

  static const _stageTypes = <HealthDataType>[
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
  ];

  bool _overlapsWindow(
    HealthDataPoint point,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    return point.dateTo.isAfter(windowStart) &&
        point.dateFrom.isBefore(windowEnd);
  }

  SleepStage? _stageFromType(HealthDataType type) {
    return switch (type) {
      HealthDataType.SLEEP_DEEP => SleepStage.deep,
      HealthDataType.SLEEP_LIGHT => SleepStage.light,
      HealthDataType.SLEEP_REM => SleepStage.rem,
      HealthDataType.SLEEP_AWAKE => SleepStage.awake,
      _ => null,
    };
  }

  /// Builds a [SleepRecord] for one night, given the union of session points
  /// and stage points that overlap the window.
  ///
  /// The session points drive [sleepStart], [wakeTime] and [totalDuration]
  /// (preserving the existing semantics). Stage points are clipped to the
  /// window and then aggregated into per-stage durations + a sorted segment
  /// list for the timeline.
  SleepRecord? _buildSleepRecord({
    required List<HealthDataPoint> sessionPoints,
    required List<HealthDataPoint> stagePoints,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    if (!windowEnd.isAfter(windowStart)) return null;
    if (sessionPoints.isEmpty && stagePoints.isEmpty) return null;

    // ── Session-level totals & window ────────────────────────────────────────
    Duration sessionTotal = Duration.zero;
    DateTime? earliest;
    DateTime? latest;

    for (final point in sessionPoints) {
      final start =
          point.dateFrom.isAfter(windowStart) ? point.dateFrom : windowStart;
      final end = point.dateTo.isBefore(windowEnd) ? point.dateTo : windowEnd;
      if (!end.isAfter(start)) continue;

      sessionTotal += end.difference(start);
      earliest =
          earliest == null || start.isBefore(earliest) ? start : earliest;
      latest = latest == null || end.isAfter(latest) ? end : latest;
    }

    // ── Stage segments & per-stage durations ────────────────────────────────
    final segments = <SleepSegment>[];
    var deep = Duration.zero;
    var light = Duration.zero;
    var rem = Duration.zero;
    var awake = Duration.zero;

    for (final point in stagePoints) {
      final stage = _stageFromType(point.type);
      if (stage == null) continue;

      final start =
          point.dateFrom.isAfter(windowStart) ? point.dateFrom : windowStart;
      final end = point.dateTo.isBefore(windowEnd) ? point.dateTo : windowEnd;
      if (!end.isAfter(start)) continue;

      final duration = end.difference(start);
      segments.add(SleepSegment(start: start, end: end, stage: stage));
      switch (stage) {
        case SleepStage.deep:
          deep += duration;
        case SleepStage.light:
          light += duration;
        case SleepStage.rem:
          rem += duration;
        case SleepStage.awake:
          awake += duration;
      }

      // Stage points may extend past or precede the session window — fold them
      // into the night's start/end so the timeline x-axis covers the whole
      // recorded sleep, not just the SESSION-typed slice.
      earliest =
          earliest == null || start.isBefore(earliest) ? start : earliest;
      latest = latest == null || end.isAfter(latest) ? end : latest;
    }

    segments.sort((a, b) => a.start.compareTo(b.start));

    // Fall back to stage totals when no SESSION rows are present (some
    // recorders write only the per-stage points).
    final hasStages = segments.isNotEmpty;
    final total = sessionTotal == Duration.zero && hasStages
        ? deep + light + rem
        : sessionTotal;

    if (total == Duration.zero || earliest == null || latest == null) {
      return null;
    }

    return SleepRecord(
      sleepStart: earliest,
      wakeTime: latest,
      totalDuration: total,
      deepDuration: deep,
      lightDuration: light,
      remDuration: rem,
      awakeDuration: awake,
      segments: segments,
    );
  }

  Future<List<HealthDataPoint>> _fetchStagePoints(
    String label,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _client.fetchData(
        label: label,
        start: start,
        end: end,
        types: _stageTypes,
      );
    } catch (e) {
      // Stage permissions are optional; degrade gracefully if any stage type
      // is unauthorised or unsupported on the device.
      _client.logInfo('$label stage fetch failed — $e');
      return const [];
    }
  }

  /// Returns the aggregated sleep record for the night ending on [date].
  ///
  /// The lookup window is 18:00 the previous day → 14:00 on [date], which
  /// covers all typical overnight sleep patterns including late bedtimes and
  /// morning lie-ins while excluding the following night's sleep.
  Future<SleepRecord?> getSleepForNight(DateTime date) async {
    final dayStart = _client.dayOnly(date);
    final windowStart =
        dayStart.subtract(const Duration(hours: 6)); // 18:00 prev day
    final windowEnd = dayStart.add(const Duration(hours: 14)); // 14:00 today
    final now = DateTime.now();
    final end = windowEnd.isBefore(now) ? windowEnd : now;

    final sessionPoints = await _client.fetchData(
      label: 'SLEEP_SESSION',
      start: windowStart,
      end: end,
      types: const [HealthDataType.SLEEP_SESSION],
    );

    final stagePoints = await _fetchStagePoints('SLEEP_STAGES', windowStart, end);

    final record = _buildSleepRecord(
      sessionPoints: sessionPoints,
      stagePoints: stagePoints,
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
      ' deep=${record.deepDuration.inMinutes}'
      ' light=${record.lightDuration.inMinutes}'
      ' rem=${record.remDuration.inMinutes}'
      ' awake=${record.awakeDuration.inMinutes}'
      ' segments=${record.segments.length}',
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

    final sessionPoints = await _client.fetchData(
      label: 'SLEEP_SESSION_HISTORY',
      start: start,
      end: end,
      types: const [HealthDataType.SLEEP_SESSION],
    );
    final stagePoints =
        await _fetchStagePoints('SLEEP_STAGES_HISTORY', start, end);

    final records = <SleepRecord>[];
    for (int i = 0; i < nights; i++) {
      final dayStart = latestDay.subtract(Duration(days: i));
      final windowStart = dayStart.subtract(const Duration(hours: 6));
      final rawWindowEnd = dayStart.add(const Duration(hours: 14));
      final windowEnd = rawWindowEnd.isBefore(now) ? rawWindowEnd : now;

      final nightlySessions = sessionPoints
          .where((point) => _overlapsWindow(point, windowStart, windowEnd))
          .toList();
      final nightlyStages = stagePoints
          .where((point) => _overlapsWindow(point, windowStart, windowEnd))
          .toList();

      final record = _buildSleepRecord(
        sessionPoints: nightlySessions,
        stagePoints: nightlyStages,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      if (record != null) {
        records.add(record);
      }
    }

    _client.logInfo(
      'getSleepHistory(): produced ${records.length} nightly records'
      ' (${stagePoints.length} stage points)',
    );
    return records;
  }

  Future<List<SleepRecord>> getSleepHistoryForRange(
    DateTime start,
    DateTime end,
  ) async {
    final oldestDay = _client.dayOnly(start);
    final latestDay = _client.dayOnly(end);
    final now = DateTime.now();
    final queryStart = oldestDay.subtract(const Duration(hours: 6));
    final rawQueryEnd = latestDay.add(const Duration(hours: 14));
    final queryEnd = rawQueryEnd.isBefore(now) ? rawQueryEnd : now;

    if (latestDay.isBefore(oldestDay) || !queryEnd.isAfter(queryStart)) {
      return const [];
    }

    _client.logDebug(
      'getSleepHistoryForRange(${_client.fmt(oldestDay)} -> ${_client.fmt(latestDay)})',
    );

    final sessionPoints = await _client.fetchData(
      label: 'SLEEP_SESSION_HISTORY_RANGE',
      start: queryStart,
      end: queryEnd,
      types: const [HealthDataType.SLEEP_SESSION],
    );
    final stagePoints = await _fetchStagePoints(
      'SLEEP_STAGES_HISTORY_RANGE',
      queryStart,
      queryEnd,
    );

    final records = <SleepRecord>[];
    final totalDays = latestDay.difference(oldestDay).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final dayStart = latestDay.subtract(Duration(days: i));
      final windowStart = dayStart.subtract(const Duration(hours: 6));
      final rawWindowEnd = dayStart.add(const Duration(hours: 14));
      final windowEnd = rawWindowEnd.isBefore(now) ? rawWindowEnd : now;

      final nightlySessions = sessionPoints
          .where((point) => _overlapsWindow(point, windowStart, windowEnd))
          .toList();
      final nightlyStages = stagePoints
          .where((point) => _overlapsWindow(point, windowStart, windowEnd))
          .toList();

      final record = _buildSleepRecord(
        sessionPoints: nightlySessions,
        stagePoints: nightlyStages,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      if (record != null) {
        records.add(record);
      }
    }

    _client.logInfo(
      'getSleepHistoryForRange(): produced ${records.length} nightly records'
      ' (${stagePoints.length} stage points)',
    );
    return records;
  }
}
