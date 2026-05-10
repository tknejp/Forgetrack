/// What an objective measures. Sealed so the evaluator gets exhaustive
/// switch checking and adding a new metric is one case + one resolver
/// branch.
///
/// Phase 1 only declares the shape and a representative subset; the
/// full metric library lands during the catalog port (Phase 3) as
/// real objectives need each branch.
sealed class ObjectiveMetric {
  const ObjectiveMetric();
}

// ── Health-source metrics (mirror legacy ProgressionMetric) ───────────

class StepsMetric extends ObjectiveMetric {
  const StepsMetric();
}

class CaloriesMetric extends ObjectiveMetric {
  const CaloriesMetric();
}

class ProteinGramsMetric extends ObjectiveMetric {
  const ProteinGramsMetric();
}

class SleepMinutesMetric extends ObjectiveMetric {
  const SleepMinutesMetric();
}

class ActivityMinutesMetric extends ObjectiveMetric {
  const ActivityMinutesMetric();
}

// ── Engine-derived metrics ────────────────────────────────────────────

class LevelMetric extends ObjectiveMetric {
  const LevelMetric();
}

class TotalXpMetric extends ObjectiveMetric {
  const TotalXpMetric();
}

/// Number of reward grants matching an optional rule / domain filter.
/// Mirrors the legacy `rewardCountAtLeast` criterion which counts grants
/// either globally, or for a specific rule, or for a specific domain.
class RewardCountMetric extends ObjectiveMetric {
  const RewardCountMetric({this.ruleId, this.domain});

  /// When set, counts only grants from this specific rule (e.g.
  /// `daily_steps`).
  final String? ruleId;

  /// When set, counts only grants from this domain (e.g. `nutrition`).
  /// Mutually exclusive with [ruleId].
  final String? domain;
}

/// Best (longest) consecutive-day streak for a specific rule or domain.
/// Mirrors the legacy `bestStreakAtLeast` criterion.
class StreakDaysMetric extends ObjectiveMetric {
  const StreakDaysMetric.byRule(this.ruleId) : domain = null;
  const StreakDaysMetric.byDomain(this.domain) : ruleId = null;

  final String? ruleId;
  final String? domain;
}

/// Number of completions of a specific node (e.g. quest completions).
class NodeCompletionsMetric extends ObjectiveMetric {
  const NodeCompletionsMetric({required this.nodeId});

  final String nodeId;
}

/// Combo-pool completions — Q1 decision: combo achievements reference
/// the pool id, not a hard-coded quest list.
class ComboPoolCompletionsMetric extends ObjectiveMetric {
  const ComboPoolCompletionsMetric({required this.poolId});

  final String poolId;
}
