/// A single aggregated sleep record for one night.
///
/// [sleepStart] is the earliest recorded sleep start time.
/// [wakeTime] is the latest recorded wake time.
/// [totalDuration] is the sum of all sleep session durations within the night
/// window (not wall-clock time from start to wake, which would include awake
/// periods).
class SleepRecord {
  final DateTime sleepStart;
  final DateTime wakeTime;
  final Duration totalDuration;

  const SleepRecord({
    required this.sleepStart,
    required this.wakeTime,
    required this.totalDuration,
  });
}
