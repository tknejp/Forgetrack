import '../../../../l10n/app_localizations.dart';

// Re-export the V2-owned [ProgressionDomain] enum so any remaining V1
// code that imported `progression_models.dart` for the enum keeps
// compiling. V2 is the source of truth as of Phase 9a; V1's copy was
// deleted to avoid duplicate Dart class identity.
export '../../../progression_engine/domain/progression_domain.dart';

typedef ProgressionLocalizedText = String Function(AppLocalizations l10n);

enum ProgressionMetric {
  steps,
  calories,
  proteinGrams,
  carbsGrams,
  fatGrams,
  fiberGrams,
  sleepMinutes,
  activityMinutes,
  weightKg,
}

enum ProgressionPeriodKind {
  day,
  week,
}

enum ProgressionComparator {
  atLeast,
  atMost,
  betweenInclusive,
  withinRelativeTolerance,
  atLeastRelativeTolerance,
}

enum ProgressionEvaluationStatus {
  achieved,
  missed,
}

enum ProgressionMissReason {
  belowMinimum,
  aboveMaximum,
  outsideAcceptedRange,
}

enum ProgressionRewardStatus {
  unlocked,
  claimed,
}

class ProgressionGoalSet {
  const ProgressionGoalSet({
    required this.dailySteps,
    required this.dailyCalories,
    required this.dailyProteinGrams,
    this.dailyCarbsGrams = 250,
    this.dailyFatGrams = 65,
    this.dailyFiberGrams = 30,
    required this.sleepMinutes,
    required this.weeklyActivityMinutes,
    this.targetWeightKg = 70.0,
  });

  final int dailySteps;
  final double dailyCalories;
  final double dailyProteinGrams;
  final double dailyCarbsGrams;
  final double dailyFatGrams;
  final double dailyFiberGrams;
  final int sleepMinutes;
  final int weeklyActivityMinutes;
  final double targetWeightKg;
}

class ProgressionPeriod {
  const ProgressionPeriod({
    required this.kind,
    required this.start,
    required this.end,
  });

  factory ProgressionPeriod.day(DateTime date) {
    final normalized = progressionDate(date);
    return ProgressionPeriod(
      kind: ProgressionPeriodKind.day,
      start: normalized,
      end: normalized,
    );
  }

  factory ProgressionPeriod.week(DateTime weekStart) {
    final normalized = startOfProgressionWeek(weekStart);
    return ProgressionPeriod(
      kind: ProgressionPeriodKind.week,
      start: normalized,
      end: normalized.add(const Duration(days: 6)),
    );
  }

  final ProgressionPeriodKind kind;
  final DateTime start;
  final DateTime end;

  String get anchorKey => progressionDateKey(start);
}

DateTime progressionDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime startOfProgressionWeek(DateTime value) {
  final normalized = progressionDate(value);
  return normalized
      .subtract(Duration(days: normalized.weekday - DateTime.monday));
}

String progressionDateKey(DateTime value) {
  final normalized = progressionDate(value);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
