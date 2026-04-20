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
