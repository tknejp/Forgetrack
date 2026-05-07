import 'package:isar/isar.dart';

part 'hc_records.g.dart';

// ─── Steps ────────────────────────────────────────────────────────────────────

@Collection()
class HcStepsDayRecord {
  Id id = Isar.autoIncrement;

  /// ISO date key: 'yyyy-MM-dd'. Unique per day.
  @Index(unique: true, replace: true)
  late String dateKey;

  int steps = 0;
}

// ─── Active calories ──────────────────────────────────────────────────────────

@Collection()
class HcCalorieDayRecord {
  Id id = Isar.autoIncrement;

  /// ISO date key: 'yyyy-MM-dd'. Unique per day.
  @Index(unique: true, replace: true)
  late String dateKey;

  double kcal = 0;
}

// ─── Weight ───────────────────────────────────────────────────────────────────

@Collection()
class HcWeightRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  double weight = 0;
  double? bodyFat;
  double? bodyWater;
}

// ─── Sleep ────────────────────────────────────────────────────────────────────

@Collection()
class HcSleepRecord {
  Id id = Isar.autoIncrement;

  /// ISO date key of the wake day: 'yyyy-MM-dd'. One record per night.
  @Index(unique: true, replace: true)
  late String dateKey;

  late DateTime sleepStart;
  late DateTime wakeTime;

  /// Sum of all sleep session durations (not wall-clock span).
  int totalDurationSeconds = 0;

  // ── Sleep-stage breakdown (Health Connect, optional) ─────────────────────
  // Aggregated time spent in each stage during the night, in seconds.
  // Zero when the device / sync did not report stage data.
  int deepDurationSeconds = 0;
  int lightDurationSeconds = 0;
  int remDurationSeconds = 0;
  int awakeDurationSeconds = 0;

  /// Encoded list of stage segments for the timeline view.
  ///
  /// Format: lines of `<startMs>|<endMs>|<stageIndex>` where stageIndex
  /// matches [SleepStage.index]. Empty when no stage data is present.
  String segmentsEncoded = '';
}

// ─── Activities ───────────────────────────────────────────────────────────────

@Collection()
class HcActivityRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime startTime;

  late DateTime endTime;
  late String type;
  int? caloriesBurned;
  double? distanceKm;
}

// ─── Metadata (singleton, id = 1) ─────────────────────────────────────────────

@Collection()
class HcMetaRecord {
  /// Fixed id so put() always updates the same record.
  Id id = 1;

  DateTime? lastSyncedAt;
  bool workoutPermission = false;
  double? latestBodyFat;
}
