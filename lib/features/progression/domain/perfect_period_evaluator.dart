import 'progression_models.dart';

/// Computes the count of "perfect days" (all configured daily rules
/// achieved on the same calendar day) and "perfect weeks" (seven perfect
/// days within the same calendar week).
///
/// Consumers (achievement evaluator, cosmetic snapshot extractor) call the
/// same evaluator instance — this is the single source of truth for what
/// counts as "perfect", so a `perfect_days_7` achievement and a
/// `frame_balance` cosmetic unlock can never disagree.
abstract class PerfectPeriodEvaluator {
  int countPerfectDays(List<ProgressionEvaluation> evaluations);
  int countPerfectWeeks(List<ProgressionEvaluation> evaluations);
}

/// Returns 0 for both metrics. Kept for tests that want deterministic
/// "no perfect periods" baselines without setting up real evaluations.
class PlaceholderPerfectPeriodEvaluator implements PerfectPeriodEvaluator {
  const PlaceholderPerfectPeriodEvaluator();

  @override
  int countPerfectDays(List<ProgressionEvaluation> evaluations) => 0;

  @override
  int countPerfectWeeks(List<ProgressionEvaluation> evaluations) => 0;
}

/// Real implementation. A "perfect day" is a calendar day on which every
/// daily rule in [_kRequiredDailyRuleIds] has at least one matching
/// evaluation with `achieved == true`. A "perfect week" is a progression
/// week (per [startOfProgressionWeek]) containing 7 perfect days.
///
/// Required rule ids match `progression_rule_catalog.dart` and
/// `daily_four_pillars_today` quest's `relatedRuleIds`.
class RealPerfectPeriodEvaluator implements PerfectPeriodEvaluator {
  const RealPerfectPeriodEvaluator({
    Set<String> requiredDailyRuleIds = _kRequiredDailyRuleIds,
  }) : _requiredDailyRuleIds = requiredDailyRuleIds;

  static const Set<String> _kRequiredDailyRuleIds = <String>{
    'daily_steps',
    'daily_calories',
    'daily_protein',
    'daily_sleep',
  };

  final Set<String> _requiredDailyRuleIds;

  @override
  int countPerfectDays(List<ProgressionEvaluation> evaluations) {
    return _perfectDayDates(evaluations).length;
  }

  @override
  int countPerfectWeeks(List<ProgressionEvaluation> evaluations) {
    final perfectDays = _perfectDayDates(evaluations);
    if (perfectDays.isEmpty) return 0;

    // Bucket perfect days by their progression-week anchor.
    final daysByWeek = <DateTime, Set<DateTime>>{};
    for (final day in perfectDays) {
      final weekStart = startOfProgressionWeek(day);
      daysByWeek.putIfAbsent(weekStart, () => <DateTime>{}).add(day);
    }

    var weeks = 0;
    for (final daysInWeek in daysByWeek.values) {
      if (daysInWeek.length >= 7) weeks++;
    }
    return weeks;
  }

  /// Returns the set of calendar days where every required daily rule has
  /// at least one `achieved` evaluation. Pure, no I/O.
  Set<DateTime> _perfectDayDates(List<ProgressionEvaluation> evaluations) {
    // achievedRuleIdsByDay[day] = set of distinct rule ids achieved that day
    final achievedRuleIdsByDay = <DateTime, Set<String>>{};
    for (final evaluation in evaluations) {
      if (evaluation.period.kind != ProgressionPeriodKind.day) continue;
      if (!evaluation.achieved) continue;
      if (!_requiredDailyRuleIds.contains(evaluation.ruleId)) continue;

      final day = progressionDate(evaluation.period.start);
      achievedRuleIdsByDay
          .putIfAbsent(day, () => <String>{})
          .add(evaluation.ruleId);
    }

    return <DateTime>{
      for (final entry in achievedRuleIdsByDay.entries)
        if (entry.value.length >= _requiredDailyRuleIds.length) entry.key,
    };
  }
}
