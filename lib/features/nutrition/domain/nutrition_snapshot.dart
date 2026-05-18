import 'package:meta/meta.dart';

/// Pure-Dart immutable summary of the nutrition read surfaces the
/// progression engine consumes during one evaluation cycle.
///
/// Phase 15 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 15) introduces this snapshot so the engine input builder
/// stops reaching into `KalorickeTabulkyProvider.todayX` getters
/// field-by-field. Engine / objective evaluators read fields here;
/// provider stays the fabrication site. Phase 16 has now landed: the
/// engine consumes this snapshot directly via structured named args
/// on `evaluate()`; the flat `EngineEvaluationInput` record is gone.
///
/// **Date semantics.** `<metric>Today` fields are scoped to
/// [evaluatedDate]. Today's nutrition data comes from KT's `_today`
/// cache, which is rebuilt by the sync coordinator whenever the
/// active day changes — the snapshot is therefore a point-in-time
/// read of the provider's *currently surfaced day*, tagged with the
/// date the provider believes is "today".
@immutable
class NutritionSnapshot {
  const NutritionSnapshot({
    required this.evaluatedDate,
    this.caloriesToday = 0,
    this.proteinGramsToday = 0,
    this.carbsGramsToday = 0,
    this.fatGramsToday = 0,
    this.fiberGramsToday = 0,
  });

  /// Sentinel "no data" snapshot keyed at the unix epoch. Used by
  /// `KalorickeTabulkyProvider` before the first KT sync settles so
  /// engine callers can stay null-safe without a `?` guard.
  static final NutritionSnapshot empty = NutritionSnapshot(
    evaluatedDate: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// Anchor date the metrics are scoped to. Normalised to
  /// `DateTime(year, month, day)` by the provider before construction.
  final DateTime evaluatedDate;

  final double caloriesToday;
  final double proteinGramsToday;
  final double carbsGramsToday;
  final double fatGramsToday;
  final double fiberGramsToday;

  /// Stable signature for change detection. Joined with the
  /// [HealthSnapshot] / [GoalBoard] signatures inside
  /// `ProviderEngineInputSource.auditSignature` so any meaningful
  /// data change triggers a re-evaluation.
  String get signature => [
        evaluatedDate.toIso8601String(),
        caloriesToday,
        proteinGramsToday,
        carbsGramsToday,
        fatGramsToday,
        fiberGramsToday,
      ].join('|');

  NutritionSnapshot copyWith({
    DateTime? evaluatedDate,
    double? caloriesToday,
    double? proteinGramsToday,
    double? carbsGramsToday,
    double? fatGramsToday,
    double? fiberGramsToday,
  }) {
    return NutritionSnapshot(
      evaluatedDate: evaluatedDate ?? this.evaluatedDate,
      caloriesToday: caloriesToday ?? this.caloriesToday,
      proteinGramsToday: proteinGramsToday ?? this.proteinGramsToday,
      carbsGramsToday: carbsGramsToday ?? this.carbsGramsToday,
      fatGramsToday: fatGramsToday ?? this.fatGramsToday,
      fiberGramsToday: fiberGramsToday ?? this.fiberGramsToday,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionSnapshot &&
        other.evaluatedDate == evaluatedDate &&
        other.caloriesToday == caloriesToday &&
        other.proteinGramsToday == proteinGramsToday &&
        other.carbsGramsToday == carbsGramsToday &&
        other.fatGramsToday == fatGramsToday &&
        other.fiberGramsToday == fiberGramsToday;
  }

  @override
  int get hashCode => Object.hash(
        evaluatedDate,
        caloriesToday,
        proteinGramsToday,
        carbsGramsToday,
        fatGramsToday,
        fiberGramsToday,
      );

  @override
  String toString() =>
      'NutritionSnapshot(date: $evaluatedDate, '
      'kcal: $caloriesToday, P: $proteinGramsToday, '
      'C: $carbsGramsToday, F: $fatGramsToday, '
      'fiber: $fiberGramsToday)';
}
