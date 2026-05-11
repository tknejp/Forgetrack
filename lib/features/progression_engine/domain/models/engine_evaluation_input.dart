import 'package:flutter/foundation.dart';

/// Snapshot of the player's measurable state at evaluation time.
///
/// Phase 2 keeps this as a flat data class — real source plumbing
/// (FitnessProvider, KalorickeTabulkyProvider, etc.) is wired in
/// Phase 6. Tests construct it directly with whatever values they
/// need to exercise a metric.
///
/// Fields default to zero so a test can build an input that only
/// cares about steps without listing every other metric.
@immutable
class EngineEvaluationInput {
  const EngineEvaluationInput({
    required this.evaluatedAt,
    this.totalXp = 0,
    this.level = 1,
    this.stepsToday = 0,
    this.stepsThisWeek = 0,
    this.stepsLifetime = 0,
    this.caloriesToday = 0,
    this.proteinGramsToday = 0,
    this.sleepMinutesToday = 0,
    this.activityMinutesToday = 0,
    this.totalRewardCount = 0,
    this.rewardCountByRule = const {},
    this.rewardCountByDomain = const {},
    this.bestStreakByRule = const {},
    this.bestStreakByDomain = const {},
    this.bestRollingStepsByDays = const {},
    this.bestRollingSleepMinutesByDays = const {},
    this.nodeCompletionCounts = const {},
    this.comboPoolCompletionCounts = const {},
    this.objectiveActualOverrides = const {},
    this.rpgModeEnabled = true,
  });

  final DateTime evaluatedAt;
  final int totalXp;
  final int level;

  // Period-scoped metric snapshots. The "today" suffix is canonical:
  // a TodayScope objective on `steps` reads `stepsToday`.
  final int stepsToday;
  final int stepsThisWeek;
  final int stepsLifetime;
  final double caloriesToday;
  final double proteinGramsToday;
  final int sleepMinutesToday;
  final int activityMinutesToday;

  // Engine-derived counters. These typically come from the ledger,
  // not the source — but for Phase 2 the test passes them in
  // alongside other metrics so the evaluator has one input shape.
  final int totalRewardCount;

  /// `ruleId → reward grant count` for [RewardCountMetric] filtered
  /// by rule (e.g. counts of `weekly_activity` rewards for the
  /// "weekly warrior" achievement).
  final Map<String, int> rewardCountByRule;

  /// `domain → reward grant count` for [RewardCountMetric] filtered
  /// by domain (e.g. nutrition grants for "nutrition_rewards_25").
  final Map<String, int> rewardCountByDomain;

  /// `ruleId → best (longest) streak in days` for
  /// [StreakDaysMetric.byRule] — mirrors the legacy
  /// `bestStreakAtLeast` criterion on a rule.
  final Map<String, int> bestStreakByRule;

  /// `domain → best streak in days` for [StreakDaysMetric.byDomain].
  final Map<String, int> bestStreakByDomain;

  /// `windowDays → best lifetime steps in any rolling window of that
  /// many days` — for steps achievements scoped on
  /// [RollingWindowScope] (e.g. "best 30-day window >= 300k steps").
  final Map<int, int> bestRollingStepsByDays;

  /// Same shape, for sleep minutes.
  final Map<int, int> bestRollingSleepMinutesByDays;

  /// `nodeId → number of completions in scope` — for
  /// `NodeCompletionsMetric` evaluation. Empty by default; tests fill
  /// only the entries they need.
  final Map<String, int> nodeCompletionCounts;

  /// `comboPoolId → completions in scope` — for
  /// `ComboPoolCompletionsMetric`.
  final Map<String, int> comboPoolCompletionCounts;

  /// `objectiveId → measured value override` — bypasses the metric
  /// switch in [ObjectiveEvaluator] for objectives whose actual value
  /// is computed elsewhere from the ledger. Used today by
  /// `ObjectiveDefinition.baselineFromNodeId` — chapter step
  /// objectives whose counter must start from the moment the chain
  /// step unlocked instead of all-time.
  final Map<String, double> objectiveActualOverrides;

  /// Whether RPG mode is currently on. Drives [ActivationPolicy]
  /// gating in the resolver.
  final bool rpgModeEnabled;
}
