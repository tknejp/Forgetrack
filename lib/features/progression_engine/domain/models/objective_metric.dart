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
class RewardCountMetric extends ObjectiveMetric {
  const RewardCountMetric({this.objectiveId});

  /// When set, counts only grants from this specific objective.
  final String? objectiveId;
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
