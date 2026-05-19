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
    this.activityMinutesToday = 0,
    this.weightLoggedToday = false,
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
  final int activityMinutesToday;
  final bool weightLoggedToday;

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
        activityMinutesToday,
        weightLoggedToday ? 1 : 0,
      ].join('|');

  HealthSnapshot copyWith({
    DateTime? evaluatedDate,
    int? stepsToday,
    int? stepsThisWeek,
    int? stepsLifetime,
    int? sleepMinutesToday,
    int? activityMinutesToday,
    bool? weightLoggedToday,
  }) {
    return HealthSnapshot(
      evaluatedDate: evaluatedDate ?? this.evaluatedDate,
      stepsToday: stepsToday ?? this.stepsToday,
      stepsThisWeek: stepsThisWeek ?? this.stepsThisWeek,
      stepsLifetime: stepsLifetime ?? this.stepsLifetime,
      sleepMinutesToday: sleepMinutesToday ?? this.sleepMinutesToday,
      activityMinutesToday: activityMinutesToday ?? this.activityMinutesToday,
      weightLoggedToday: weightLoggedToday ?? this.weightLoggedToday,
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
        other.activityMinutesToday == activityMinutesToday &&
        other.weightLoggedToday == weightLoggedToday;
  }

  @override
  int get hashCode => Object.hash(
        evaluatedDate,
        stepsToday,
        stepsThisWeek,
        stepsLifetime,
        sleepMinutesToday,
        activityMinutesToday,
        weightLoggedToday,
      );

  @override
  String toString() =>
      'HealthSnapshot(date: $evaluatedDate, stepsToday: $stepsToday, '
      'stepsThisWeek: $stepsThisWeek, stepsLifetime: $stepsLifetime, '
      'sleepMin: $sleepMinutesToday, activityMin: $activityMinutesToday, '
      'weightLogged: $weightLoggedToday)';
}
