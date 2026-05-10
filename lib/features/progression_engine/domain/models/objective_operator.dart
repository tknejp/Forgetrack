/// Comparison operator binding an [ObjectiveMetric] value to a target.
enum ObjectiveOperator {
  /// `value >= targetValue`
  atLeast,

  /// `value <= targetValue`
  atMost,

  /// `targetValue <= value <= upperTargetValue`
  betweenInclusive,

  /// `(target * (1 - tol)) <= value <= (target * (1 + tol))`
  withinTolerance,

  /// `value >= (target * (1 - tol))` — one-sided tolerance, used for
  /// "hit at least 90% of your protein goal".
  atLeastWithTolerance,
}
