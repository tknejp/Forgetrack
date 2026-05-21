import 'ids.dart';
import 'quest_display_bucket.dart';

/// What an objective measures. Sealed so the evaluator gets exhaustive
/// switch checking and adding a new metric is one case + one resolver
/// branch.
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

/// Whether [SleepStartHourCountMetric] counts nights whose start hour
/// is *at or after* a threshold, or *strictly before* it.
enum SleepStartHourDirection { before, atOrAfter }

/// Number of recorded sleep records whose `sleepStart` local hour
/// matches a threshold (e.g. *at or after 1:00* — `night_owl`,
/// *before 22:00* — `early_bird`). Pair with [LifetimeScope] and
/// `atLeast N` to express "N nights starting after/before X o'clock".
///
/// The resolver reads this from a pre-aggregated count on
/// `HealthSnapshot` — wiring populates the specific (hour, direction)
/// combinations the catalog actually queries; unwired combinations
/// evaluate to 0.
class SleepStartHourCountMetric extends ObjectiveMetric {
  const SleepStartHourCountMetric({
    required this.hour,
    required this.direction,
  });

  /// Hour-of-day threshold in 24h local time. Compared against the
  /// `sleepStart` timestamp's hour component.
  final int hour;

  /// `before` → hour < threshold; `atOrAfter` → hour >= threshold.
  final SleepStartHourDirection direction;
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

  final ProgressionEntryId nodeId;
}

/// Combo-pool completions — Q1 decision: combo achievements reference
/// the pool id, not a hard-coded quest list.
class ComboPoolCompletionsMetric extends ObjectiveMetric {
  const ComboPoolCompletionsMetric({required this.poolId});

  final ComboPoolId poolId;
}

/// Number of [Quest] completions across the catalog. When [bucket]
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

  final List<ProgressionEntryId> nodeIds;
}

/// Total lifetime completion count summed across a list of node ids.
/// Use when an objective counts across several quest variants that
/// can't share a [comboPoolId] (each [Quest] declares at most one
/// pool today, so achievements like "25 triple-or-higher combos"
/// that span `daily_triple_win_today` + `daily_four_pillars_today`
/// reach for this metric instead).
class LifetimeCompletionsAmongMetric extends ObjectiveMetric {
  const LifetimeCompletionsAmongMetric({required this.nodeIds});

  final List<ProgressionEntryId> nodeIds;
}

/// Best single-day value of a wrapped daily metric across history.
/// Drives "marathon day" / "100k steps in a day" type achievements —
/// the player only needs *one* day that hits the threshold, ever.
///
/// The wrapped metric carries the unit; only daily-source metrics
/// make sense here (StepsMetric is the only one wired today). The
/// resolver reads a pre-aggregated single-day max from
/// `HealthSnapshot`.
class BestDailyValueMetric extends ObjectiveMetric {
  const BestDailyValueMetric({required this.metric});

  final ObjectiveMetric metric;
}

/// Counts how many node-completion events landed after the player had
/// previously been inactive for at least [gapDays] consecutive days.
/// Pair with `LifetimeScope` + `atLeast 1` for a "you came back!"
/// achievement (`zero_day_recovery`).
///
/// Producer (provider input source) scans the ledger's node-completion
/// events in chronological order, groups by local-day, and increments
/// the counter every time the gap between two consecutive active days
/// is >= [gapDays]. Brand new players (no prior active day) do not
/// trip this — the first ever completion is not a "return".
class ReturnAfterGapMetric extends ObjectiveMetric {
  const ReturnAfterGapMetric({required this.gapDays});

  final int gapDays;
}

/// Longest run of consecutive active days that *began* after a gap of
/// at least [gapDays] inactive days. Drives `comeback_streak` —
/// rewards the player who powered through after a long break.
///
/// Producer increments the running streak each consecutive active
/// day, resets on inactivity, and records `bestStreakAfterGap` only
/// for streaks whose first day followed a >= [gapDays] gap from the
/// previous active day. Returns 0 when no qualifying comeback streak
/// has happened yet.
class StreakAfterGapMetric extends ObjectiveMetric {
  const StreakAfterGapMetric({required this.gapDays});

  final int gapDays;
}

/// Number of distinct calendar days on which at least [atLeast] of the
/// named nodes were "done" (goal met or claimed). Use when a quest
/// reads as "complete at least K daily goals on N different days"
/// (`atLeast=K`, `targetValue=N`) or "complete both X and Y on the
/// same day, N times" (`nodeIds=[X, Y], atLeast=2, targetValue=N`).
class DaysWithAtLeastKAmongMetric extends ObjectiveMetric {
  const DaysWithAtLeastKAmongMetric({
    required this.nodeIds,
    required this.atLeast,
  });

  final List<ProgressionEntryId> nodeIds;
  final int atLeast;
}
