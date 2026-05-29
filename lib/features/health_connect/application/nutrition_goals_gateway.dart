/// Consumer-side port that lets [GoalsProvider] read nutrition goals
/// (calories + macros) from an *external* source — currently Kalorické
/// Tabulky — without importing the nutrition feature.
///
/// `GoalsProvider` lives under `health_connect` but owns every player
/// goal, including the five nutrition metrics. Trello #98 lets those
/// five optionally come per-day from KT instead of the local goal board.
/// To keep the dependency direction clean (nutrition already imports
/// health_connect, never the reverse), the port is declared here and the
/// nutrition layer adapts its KT day model to [NutritionGoalsView].
library;

/// Read-only per-day nutrition goal values exposed by an external source.
abstract class NutritionGoalsView {
  double get calories;
  double get protein;
  double get fat;
  double get carbs;
  double get fiber;

  /// False when the source has no usable goals for the day (e.g. a
  /// logged-in KT account that never set targets → all zeros). The
  /// dispatcher in [GoalsProvider] falls back to the local board then.
  bool get hasData;
}

/// Port read by [GoalsProvider] when the nutrition goal source is the
/// external one. Implemented by the nutrition feature
/// (`KalorickeTabulkyProvider`).
abstract class NutritionGoalsGateway {
  /// Whether the external source is currently usable (e.g. logged in).
  bool get isAvailable;

  /// The external goals effective on [day], or null when none are cached.
  NutritionGoalsView? goalsForDate(DateTime day);
}
