import 'quest_display_bucket.dart';

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

class CarbsGramsMetric extends ObjectiveMetric {
  const CarbsGramsMetric();
}

class FatGramsMetric extends ObjectiveMetric {
  const FatGramsMetric();
}

class FiberGramsMetric extends ObjectiveMetric {
  const FiberGramsMetric();
}

class SleepMinutesMetric extends ObjectiveMetric {
  const SleepMinutesMetric();
}

class ActivityMinutesMetric extends ObjectiveMetric {
  const ActivityMinutesMetric();
}

/// Boolean "did the player log a weight measurement today?" metric.
/// Reads as `1.0` when at least one weight record exists for the
/// evaluated date and `0.0` otherwise. Pair with [TodayScope] +
/// `atLeast 1` for the `daily_weight_log` objective.
class WeightLoggedTodayMetric extends ObjectiveMetric {
  const WeightLoggedTodayMetric();
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

/// Number of [QuestNode] completions across the catalog. When [bucket]
/// is set, only quests with that [QuestDisplayBucket] are counted
/// (e.g. `daily` for "complete 3 daily quests"). When null, every
/// quest counts (the V1 `totalQuestsCompletedAtLeast` semantic).
class QuestCompletionsByBucketMetric extends ObjectiveMetric {
  const QuestCompletionsByBucketMetric({this.bucket});

  final QuestDisplayBucket? bucket;
}

/// Count of distinct calendar dates on which at least one node
/// completion fired. Mirrors V1 `activeDaysAtLeast` — V1 counted any
/// rule evaluation; the direct V2 analog is any [NodeCompletionEvent].
class DistinctActiveDaysMetric extends ObjectiveMetric {
  const DistinctActiveDaysMetric();
}

/// Count of how many of the named nodes have a completion event
/// recorded today. Mirrors V1 `currentPeriodRuleSetAtLeast` — combo
/// daily quests express "K of M daily rules met today" by listing
/// the M rule node ids and asking for K matches.
///
/// Scope is implicit (today). Pair with [TodayScope] so the resolver
/// reads the right input slot.
class TodayCompletionsAmongMetric extends ObjectiveMetric {
  const TodayCompletionsAmongMetric({required this.nodeIds});

  final List<String> nodeIds;
}

/// Total lifetime completion count summed across a list of node ids.
/// Use when an objective counts across several quest variants that
/// can't share a [comboPoolId] (each [QuestNode] declares at most one
/// pool today, so achievements like "25 triple-or-higher combos"
/// that span `daily_triple_win_today` + `daily_four_pillars_today`
/// reach for this metric instead).
class LifetimeCompletionsAmongMetric extends ObjectiveMetric {
  const LifetimeCompletionsAmongMetric({required this.nodeIds});

  final List<String> nodeIds;
}

/// Number of distinct calendar days on which at least [atLeast] of the
/// named nodes were "done" (goal met or claimed). Use when a quest
/// reads as "complete at least K daily goals on N different days"
/// (`atLeast=K`, `targetValue=N`) or "complete both X and Y on the
/// same day, N times" (`nodeIds=[X, Y], atLeast=2, targetValue=N`).
///
/// Always paired with [Objective.baselineFromNodeId] today —
/// the provider's `objectiveActualOverrides` path computes the day
/// count from the ledger, restricted to days after the baseline node
/// first completed. Without per-event history a non-baselined
/// lifetime count isn't meaningful: chapter steps that use this
/// must declare their baseline.
class DaysWithAtLeastKAmongMetric extends ObjectiveMetric {
  const DaysWithAtLeastKAmongMetric({
    required this.nodeIds,
    required this.atLeast,
  });

  final List<String> nodeIds;
  final int atLeast;
}
