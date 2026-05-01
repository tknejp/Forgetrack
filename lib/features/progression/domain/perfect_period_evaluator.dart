import '../application/progression_engine.dart';

/// Computes the count of "perfect days" (all configured daily rules
/// achieved on the same calendar day) and "perfect weeks" (seven perfect
/// days within the same calendar week).
///
/// This is the only intentional non-functional piece of the cosmetic
/// unlock system. Cosmetic rules referencing perfect periods
/// (`frame_balance`, `frame_master_routine`) are wired correctly and will
/// fire automatically once a real implementation replaces
/// [PlaceholderPerfectPeriodEvaluator] — no rule-table edits needed.
abstract class PerfectPeriodEvaluator {
  int countPerfectDays(ProgressionEngineState state);
  int countPerfectWeeks(ProgressionEngineState state);
}

/// Returns 0 for both metrics. Replace with a real evaluator that:
/// 1. groups [state.evaluations] by `progressionDate(period.start)` and the
///    rule's [ProgressionPeriodKind.day] kind,
/// 2. defines "perfect day" = all configured `daily_*` rule ids `achieved`,
/// 3. groups perfect days by ISO week to produce perfect-week counts.
///
/// Today's daily rules are `daily_steps`, `daily_calories`, `daily_protein`,
/// `daily_sleep` (see `progression_rule_catalog.dart`).
class PlaceholderPerfectPeriodEvaluator implements PerfectPeriodEvaluator {
  const PlaceholderPerfectPeriodEvaluator();

  @override
  int countPerfectDays(ProgressionEngineState state) => 0;

  @override
  int countPerfectWeeks(ProgressionEngineState state) => 0;
}
