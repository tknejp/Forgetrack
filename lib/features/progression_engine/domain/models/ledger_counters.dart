import 'package:meta/meta.dart';

/// Bundle of journal-derived aggregations the engine evaluator
/// consumes during one evaluation pass.
///
/// Phase 16 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 16) extracts these counter maps off the flat
/// `EngineEvaluationInput` record into their own value object so the
/// engine's public `evaluate()` signature can be structured args
/// (Player + HealthSnapshot + NutritionSnapshot + GoalBoard + Journal
/// + LedgerCounters + EvaluationOverrides + evaluatedAt) instead of
/// one wide record. The counter derivation logic itself still lives
/// in `ProgressionEngineProvider` — Phase 20 (`JournalProjection`)
/// will eventually move it off the provider, but Phase 16 only
/// reshapes the engine boundary.
///
/// All fields default to empty/zero so call sites only pass the
/// counters they actually need (mirrors the pre-extraction
/// `EngineEvaluationInput` default behaviour).
@immutable
class LedgerCounters {
  const LedgerCounters({
    this.totalRewardCount = 0,
    this.rewardCountByRule = const {},
    this.rewardCountByDomain = const {},
    this.bestStreakByRule = const {},
    this.bestStreakByDomain = const {},
    this.bestRollingStepsByDays = const {},
    this.bestRollingSleepMinutesByDays = const {},
    this.nodeCompletionCounts = const {},
    this.comboPoolCompletionCounts = const {},
    this.totalQuestCompletions = 0,
    this.questCompletionsByBucket = const {},
    this.distinctActiveDays = 0,
    this.nodesCompletedToday = const {},
  });

  /// Empty sentinel — used by tests / pre-first-evaluation provider
  /// state so callers can stay null-safe without a `?` guard.
  static const LedgerCounters empty = LedgerCounters();

  final int totalRewardCount;

  /// `ruleId → reward grant count` for `RewardCountMetric` filtered
  /// by rule (e.g. counts of `weekly_activity` rewards for the
  /// "weekly warrior" achievement).
  final Map<String, int> rewardCountByRule;

  /// `domain → reward grant count` for `RewardCountMetric` filtered
  /// by domain (e.g. nutrition grants for "nutrition_rewards_25").
  final Map<String, int> rewardCountByDomain;

  /// `ruleId → best (longest) streak in days` for
  /// `StreakDaysMetric.byRule`.
  final Map<String, int> bestStreakByRule;

  /// `domain → best streak in days` for `StreakDaysMetric.byDomain`.
  final Map<String, int> bestStreakByDomain;

  /// `windowDays → best lifetime steps in any rolling window of that
  /// many days` — for steps achievements scoped on
  /// `RollingWindowScope`.
  final Map<int, int> bestRollingStepsByDays;

  /// Same shape, for sleep minutes.
  final Map<int, int> bestRollingSleepMinutesByDays;

  /// `nodeId → number of completions in scope` for
  /// `NodeCompletionsMetric`.
  final Map<String, int> nodeCompletionCounts;

  /// `comboPoolId → completions in scope` for
  /// `ComboPoolCompletionsMetric`.
  final Map<String, int> comboPoolCompletionCounts;

  /// Total number of `QuestNode` completions in the ledger. Drives
  /// `QuestCompletionsByBucketMetric` when its `bucket` is null
  /// (V1 `totalQuestsCompletedAtLeast`).
  final int totalQuestCompletions;

  /// `QuestDisplayBucket.name → quest completion count`. Drives
  /// `QuestCompletionsByBucketMetric` when its `bucket` is non-null.
  final Map<String, int> questCompletionsByBucket;

  /// Number of distinct calendar dates on which any node completion
  /// fired. Drives `DistinctActiveDaysMetric`. Date-of-event is
  /// computed in the producer (the provider input source) so the
  /// evaluator stays pure.
  final int distinctActiveDays;

  /// Set of node ids whose completion event landed *today*. Drives
  /// `TodayCompletionsAmongMetric` — combo daily quests use this to
  /// ask "K of {daily_steps_today, daily_calories_today, …}
  /// completed today?" Producer (provider input source) decides what
  /// "today" means (uses the same clock as `evaluatedAt`).
  final Set<String> nodesCompletedToday;

  LedgerCounters copyWith({
    int? totalRewardCount,
    Map<String, int>? rewardCountByRule,
    Map<String, int>? rewardCountByDomain,
    Map<String, int>? bestStreakByRule,
    Map<String, int>? bestStreakByDomain,
    Map<int, int>? bestRollingStepsByDays,
    Map<int, int>? bestRollingSleepMinutesByDays,
    Map<String, int>? nodeCompletionCounts,
    Map<String, int>? comboPoolCompletionCounts,
    int? totalQuestCompletions,
    Map<String, int>? questCompletionsByBucket,
    int? distinctActiveDays,
    Set<String>? nodesCompletedToday,
  }) {
    return LedgerCounters(
      totalRewardCount: totalRewardCount ?? this.totalRewardCount,
      rewardCountByRule: rewardCountByRule ?? this.rewardCountByRule,
      rewardCountByDomain: rewardCountByDomain ?? this.rewardCountByDomain,
      bestStreakByRule: bestStreakByRule ?? this.bestStreakByRule,
      bestStreakByDomain: bestStreakByDomain ?? this.bestStreakByDomain,
      bestRollingStepsByDays:
          bestRollingStepsByDays ?? this.bestRollingStepsByDays,
      bestRollingSleepMinutesByDays:
          bestRollingSleepMinutesByDays ?? this.bestRollingSleepMinutesByDays,
      nodeCompletionCounts: nodeCompletionCounts ?? this.nodeCompletionCounts,
      comboPoolCompletionCounts:
          comboPoolCompletionCounts ?? this.comboPoolCompletionCounts,
      totalQuestCompletions:
          totalQuestCompletions ?? this.totalQuestCompletions,
      questCompletionsByBucket:
          questCompletionsByBucket ?? this.questCompletionsByBucket,
      distinctActiveDays: distinctActiveDays ?? this.distinctActiveDays,
      nodesCompletedToday: nodesCompletedToday ?? this.nodesCompletedToday,
    );
  }
}
