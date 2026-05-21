import 'package:meta/meta.dart';

/// Pure-Dart immutable summary of the Health Connect read surfaces the
/// progression engine consumes during one evaluation cycle.
///
/// Phase 15 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 15) introduces this snapshot so the engine input builder
/// stops reaching into `FitnessProvider` field-by-field. Engine /
/// objective evaluators read fields here; provider stays the
/// fabrication site. Phase 16 has now landed: the engine consumes
/// this snapshot directly via structured named args on `evaluate()`;
/// the flat `EngineEvaluationInput` record is gone.
///
/// **Date semantics.** `<metric>Today` fields are scoped to
/// [evaluatedDate] — they are *not* "now" reads; they are the
/// snapshot's "for this day" aggregates so the engine evaluates
/// deterministically against a single anchor date (mirrors how
/// `ProviderEngineInputSource._today()` worked pre-extraction).
/// [stepsThisWeek] sums Monday → [evaluatedDate], inclusive of both.
/// [stepsLifetime] is the bounded sum of every step record currently
/// loaded by `FitnessProvider` — bounded by Health Connect's
/// retention window, matching the pre-extraction behaviour.
///
/// **Performance.** Const constructible. Fabrication is one pass per
/// list (steps history, activities) — the provider can cache an
/// instance per `(evaluatedDate, dataRevision)` if rebuild cost
/// becomes a hot path.
@immutable
class HealthSnapshot {
  const HealthSnapshot({
    required this.evaluatedDate,
    this.stepsToday = 0,
    this.stepsThisWeek = 0,
    this.stepsLifetime = 0,
    this.sleepMinutesToday = 0,
    this.sleepMinutesThisWeek = 0,
    this.activityMinutesToday = 0,
    this.activityMinutesThisWeek = 0,
    this.weightLoggedToday = false,
    this.lifetimeNightsStartedAtOrAfter1am = 0,
    this.lifetimeNightsStartedBefore10pm = 0,
    this.bestSingleDayStepsLifetime = 0,
  });

  /// Sentinel "no data" snapshot keyed at the unix epoch. Used by
  /// `FitnessProvider` before its first Health Connect read settles
  /// so engine callers can stay null-safe without a `?` guard.
  static final HealthSnapshot empty = HealthSnapshot(
    evaluatedDate: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// Anchor date the metrics are scoped to. Normalised to
  /// `DateTime(year, month, day)` by the provider before construction.
  final DateTime evaluatedDate;

  final int stepsToday;
  final int stepsThisWeek;
  final int stepsLifetime;
  final int sleepMinutesToday;

  /// Minutes of sleep summed across the current ISO week
  /// (Monday → [evaluatedDate], inclusive). Drives the weekly sleep
  /// quest via [SleepMinutesMetric] + [ThisWeekScope].
  final int sleepMinutesThisWeek;

  final int activityMinutesToday;
  final int activityMinutesThisWeek;
  final bool weightLoggedToday;

  /// Lifetime count of recorded sleep records whose `sleepStart`
  /// local hour is **at or after 1:00** — drives the `night_owl`
  /// achievement via [SleepStartHourCountMetric]. Bounded by
  /// `FitnessProvider`'s sleep history retention window.
  final int lifetimeNightsStartedAtOrAfter1am;

  /// Lifetime count of recorded sleep records whose `sleepStart`
  /// local hour is **strictly before 22:00** — drives the
  /// `early_bird` achievement via [SleepStartHourCountMetric].
  final int lifetimeNightsStartedBefore10pm;

  /// Highest single-day steps total recorded across the entire
  /// step-history window kept by `FitnessProvider`. Drives
  /// [BestDailyValueMetric] wrapped around `StepsMetric` — feeds
  /// `marathon_day` (42k) and `steps_day_100k`. Bounded by Health
  /// Connect's retention window, matching the pre-extraction
  /// behaviour.
  final int bestSingleDayStepsLifetime;

  /// Stable signature for change detection. Joined with the
  /// [NutritionSnapshot] / [GoalBoard] signatures inside
  /// `ProviderEngineInputSource.auditSignature` so any meaningful
  /// data change triggers a re-evaluation.
  String get signature => [
        evaluatedDate.toIso8601String(),
        stepsToday,
        stepsThisWeek,
        stepsLifetime,
        sleepMinutesToday,
        sleepMinutesThisWeek,
        activityMinutesToday,
        activityMinutesThisWeek,
        weightLoggedToday ? 1 : 0,
        lifetimeNightsStartedAtOrAfter1am,
        lifetimeNightsStartedBefore10pm,
        bestSingleDayStepsLifetime,
      ].join('|');

  HealthSnapshot copyWith({
    DateTime? evaluatedDate,
    int? stepsToday,
    int? stepsThisWeek,
    int? stepsLifetime,
    int? sleepMinutesToday,
    int? sleepMinutesThisWeek,
    int? activityMinutesToday,
    int? activityMinutesThisWeek,
    bool? weightLoggedToday,
    int? lifetimeNightsStartedAtOrAfter1am,
    int? lifetimeNightsStartedBefore10pm,
    int? bestSingleDayStepsLifetime,
  }) {
    return HealthSnapshot(
      evaluatedDate: evaluatedDate ?? this.evaluatedDate,
      stepsToday: stepsToday ?? this.stepsToday,
      stepsThisWeek: stepsThisWeek ?? this.stepsThisWeek,
      stepsLifetime: stepsLifetime ?? this.stepsLifetime,
      sleepMinutesToday: sleepMinutesToday ?? this.sleepMinutesToday,
      sleepMinutesThisWeek: sleepMinutesThisWeek ?? this.sleepMinutesThisWeek,
      activityMinutesToday: activityMinutesToday ?? this.activityMinutesToday,
      activityMinutesThisWeek:
          activityMinutesThisWeek ?? this.activityMinutesThisWeek,
      weightLoggedToday: weightLoggedToday ?? this.weightLoggedToday,
      lifetimeNightsStartedAtOrAfter1am: lifetimeNightsStartedAtOrAfter1am ??
          this.lifetimeNightsStartedAtOrAfter1am,
      lifetimeNightsStartedBefore10pm: lifetimeNightsStartedBefore10pm ??
          this.lifetimeNightsStartedBefore10pm,
      bestSingleDayStepsLifetime:
          bestSingleDayStepsLifetime ?? this.bestSingleDayStepsLifetime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthSnapshot &&
        other.evaluatedDate == evaluatedDate &&
        other.stepsToday == stepsToday &&
        other.stepsThisWeek == stepsThisWeek &&
        other.stepsLifetime == stepsLifetime &&
        other.sleepMinutesToday == sleepMinutesToday &&
        other.sleepMinutesThisWeek == sleepMinutesThisWeek &&
        other.activityMinutesToday == activityMinutesToday &&
        other.activityMinutesThisWeek == activityMinutesThisWeek &&
        other.weightLoggedToday == weightLoggedToday &&
        other.lifetimeNightsStartedAtOrAfter1am ==
            lifetimeNightsStartedAtOrAfter1am &&
        other.lifetimeNightsStartedBefore10pm ==
            lifetimeNightsStartedBefore10pm &&
        other.bestSingleDayStepsLifetime == bestSingleDayStepsLifetime;
  }

  @override
  int get hashCode => Object.hash(
        evaluatedDate,
        stepsToday,
        stepsThisWeek,
        stepsLifetime,
        sleepMinutesToday,
        sleepMinutesThisWeek,
        activityMinutesToday,
        activityMinutesThisWeek,
        weightLoggedToday,
        lifetimeNightsStartedAtOrAfter1am,
        lifetimeNightsStartedBefore10pm,
        bestSingleDayStepsLifetime,
      );

  @override
  String toString() =>
      'HealthSnapshot(date: $evaluatedDate, stepsToday: $stepsToday, '
      'stepsThisWeek: $stepsThisWeek, stepsLifetime: $stepsLifetime, '
      'sleepMin: $sleepMinutesToday, sleepMinWeek: $sleepMinutesThisWeek, '
      'activityMin: $activityMinutesToday, '
      'activityMinWeek: $activityMinutesThisWeek, '
      'weightLogged: $weightLoggedToday, '
      'nightsAfter1am: $lifetimeNightsStartedAtOrAfter1am, '
      'nightsBefore10pm: $lifetimeNightsStartedBefore10pm, '
      'bestSingleDaySteps: $bestSingleDayStepsLifetime)';
}
