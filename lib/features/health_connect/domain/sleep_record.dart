/// Sleep stage classifications recognised by Health Connect.
///
/// Order matters: deeper stages get the warmer, larger visual weight in the
/// stage timeline. Keep this order stable — the UI renders rows in this order.
enum SleepStage {
  awake,
  rem,
  light,
  deep,
}

/// Single contiguous slice of a sleep stage within one night.
class SleepSegment {
  final DateTime start;
  final DateTime end;
  final SleepStage stage;

  const SleepSegment({
    required this.start,
    required this.end,
    required this.stage,
  });

  Duration get duration => end.difference(start);
}

/// A single aggregated sleep record for one night.
///
/// [sleepStart] is the earliest recorded sleep start time.
/// [wakeTime] is the latest recorded wake time.
/// [totalDuration] is the sum of all sleep session durations within the night
/// window (not wall-clock time from start to wake, which would include awake
/// periods).
///
/// Stage data is optional — older nights synced before stage support was added
/// won't have it, and not every device records stages. When [segments] is empty
/// the per-stage durations should also be zero.
class SleepRecord {
  final DateTime sleepStart;
  final DateTime wakeTime;
  final Duration totalDuration;
  final Duration deepDuration;
  final Duration lightDuration;
  final Duration remDuration;
  final Duration awakeDuration;
  final List<SleepSegment> segments;

  const SleepRecord({
    required this.sleepStart,
    required this.wakeTime,
    required this.totalDuration,
    this.deepDuration = Duration.zero,
    this.lightDuration = Duration.zero,
    this.remDuration = Duration.zero,
    this.awakeDuration = Duration.zero,
    this.segments = const [],
  });

  bool get hasStageData => segments.isNotEmpty;

  /// Total sleep time excluding awake periods. Falls back to [totalDuration]
  /// when no stage data is available.
  Duration get classifiedSleepDuration {
    if (!hasStageData) return totalDuration;
    return deepDuration + lightDuration + remDuration;
  }

  Duration durationFor(SleepStage stage) {
    return switch (stage) {
      SleepStage.deep => deepDuration,
      SleepStage.light => lightDuration,
      SleepStage.rem => remDuration,
      SleepStage.awake => awakeDuration,
    };
  }
}
