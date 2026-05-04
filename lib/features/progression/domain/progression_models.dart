enum ProgressionDomain {
  steps,
  nutrition,
  sleep,
  activity,
  body,
}

enum ProgressionMetric {
  steps,
  calories,
  proteinGrams,
  sleepMinutes,
  activityMinutes,
  weightKg,
}

enum ProgressionPeriodKind {
  day,
  week,
}

enum ProgressionComparator {
  atLeast,
  atMost,
  betweenInclusive,
  withinRelativeTolerance,
}

enum ProgressionEvaluationStatus {
  achieved,
  missed,
}

enum ProgressionMissReason {
  belowMinimum,
  aboveMaximum,
  outsideAcceptedRange,
}

enum ProgressionAchievementType {
  milestone,
  streak,
  mastery,
}

enum ProgressionAchievementDifficulty {
  easy,
  medium,
  hard,
  extraHard,
  mythic,
}

enum ProgressionAchievementCriterionType {
  totalXpAtLeast,
  rewardCountAtLeast,
  bestStreakAtLeast,
  totalRuleValueAtLeast,
  bestRollingWindowRuleValueAtLeast,
  // Phase 3a additions — counted from the questRewardGrants ledger via the
  // questCategoryById index passed to the achievement evaluator.
  dailyQuestsCompletedAtLeast,
  weeklyQuestsCompletedAtLeast,
  totalQuestsCompletedAtLeast,
  // Distinct days with at least one progression evaluation period — counted
  // from the evaluations list, mirrors CosmeticUnlockSnapshotExtractor.
  activeDaysAtLeast,
  // Phase 3b additions — delegate to the shared PerfectPeriodEvaluator so
  // achievement counts and cosmetic snapshot counts can never disagree.
  perfectDaysAtLeast,
  perfectWeeksAtLeast,
  // Phase 3c additions — combo quest completions, counted from the
  // questRewardGrants ledger filtered against the hard-coded combo and
  // triple-combo quest id sets in the achievement evaluator.
  comboQuestsCompletedAtLeast,
  tripleComboQuestsCompletedAtLeast,
  // Phase 3d addition — composite (AND) over a list of
  // ProgressionAchievementCompositeCondition. The achievement's own
  // targetValue is conventionally 1; current value is 1 iff every
  // sub-condition is met, else 0.
  compositeAllOf,
}

enum ProgressionQuestType {
  milestone,
  streak,
  mastery,
}

enum ProgressionQuestCategory {
  journey,
  daily,
  weekly,
  chain,
}

enum ProgressionQuestCriterionType {
  totalXpAtLeast,
  rewardCountAtLeast,
  bestStreakAtLeast,
  totalRuleValueAtLeast,
  currentPeriodRuleCompletion,
  currentPeriodRuleSetAtLeast,
  achievementUnlocked,
  ruleCompletionsAtLeast,
  domainRewardCountAtLeast,
}

enum ProgressionQuestStatus {
  locked,
  available,
  active,
  completed,
}

enum ProgressionRewardStatus {
  unlocked,
  claimed,
}

class ProgressionGoalSet {
  const ProgressionGoalSet({
    required this.dailySteps,
    required this.dailyCalories,
    required this.dailyProteinGrams,
    required this.sleepMinutes,
    required this.weeklyActivityMinutes,
    this.targetWeightKg = 70.0,
  });

  final int dailySteps;
  final double dailyCalories;
  final double dailyProteinGrams;
  final int sleepMinutes;
  final int weeklyActivityMinutes;
  final double targetWeightKg;
}

class ProgressionPeriod {
  const ProgressionPeriod({
    required this.kind,
    required this.start,
    required this.end,
  });

  factory ProgressionPeriod.day(DateTime date) {
    final normalized = progressionDate(date);
    return ProgressionPeriod(
      kind: ProgressionPeriodKind.day,
      start: normalized,
      end: normalized,
    );
  }

  factory ProgressionPeriod.week(DateTime weekStart) {
    final normalized = startOfProgressionWeek(weekStart);
    return ProgressionPeriod(
      kind: ProgressionPeriodKind.week,
      start: normalized,
      end: normalized.add(const Duration(days: 6)),
    );
  }

  final ProgressionPeriodKind kind;
  final DateTime start;
  final DateTime end;

  String get anchorKey => progressionDateKey(start);
}

class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.period,
    this.steps = 0,
    this.calories = 0,
    this.proteinGrams = 0,
    this.sleepMinutes = 0,
    this.activityMinutes = 0,
    this.weightKg = 0.0,
  });

  final ProgressionPeriod period;
  final int steps;
  final double calories;
  final double proteinGrams;
  final int sleepMinutes;
  final int activityMinutes;
  final double weightKg;

  double metricValue(ProgressionMetric metric) {
    switch (metric) {
      case ProgressionMetric.steps:
        return steps.toDouble();
      case ProgressionMetric.calories:
        return calories;
      case ProgressionMetric.proteinGrams:
        return proteinGrams;
      case ProgressionMetric.sleepMinutes:
        return sleepMinutes.toDouble();
      case ProgressionMetric.activityMinutes:
        return activityMinutes.toDouble();
      case ProgressionMetric.weightKg:
        return weightKg;
    }
  }
}

class ProgressionRuleDefinition {
  const ProgressionRuleDefinition({
    required this.id,
    required this.version,
    required this.domain,
    required this.metric,
    required this.periodKind,
    required this.comparator,
    required this.targetValue,
    required this.rewardXp,
    required this.title,
    required this.description,
    this.upperTargetValue,
    this.toleranceRatio = 0,
  });

  final String id;
  final String version;
  final ProgressionDomain domain;
  final ProgressionMetric metric;
  final ProgressionPeriodKind periodKind;
  final ProgressionComparator comparator;
  final double targetValue;
  final double? upperTargetValue;
  final double toleranceRatio;
  final int rewardXp;
  final String title;
  final String description;

  bool supportsPeriod(ProgressionPeriod period) => period.kind == periodKind;

  double get minimumAcceptedValue {
    switch (comparator) {
      case ProgressionComparator.atLeast:
        return targetValue;
      case ProgressionComparator.atMost:
        return double.negativeInfinity;
      case ProgressionComparator.betweenInclusive:
        return targetValue;
      case ProgressionComparator.withinRelativeTolerance:
        return targetValue - (targetValue * toleranceRatio);
    }
  }

  double get maximumAcceptedValue {
    switch (comparator) {
      case ProgressionComparator.atLeast:
        return double.infinity;
      case ProgressionComparator.atMost:
        return targetValue;
      case ProgressionComparator.betweenInclusive:
        return upperTargetValue ?? targetValue;
      case ProgressionComparator.withinRelativeTolerance:
        return targetValue + (targetValue * toleranceRatio);
    }
  }

  bool isSatisfiedBy(double actualValue) {
    switch (comparator) {
      case ProgressionComparator.atLeast:
        return actualValue >= targetValue;
      case ProgressionComparator.atMost:
        return actualValue <= targetValue;
      case ProgressionComparator.betweenInclusive:
        return actualValue >= minimumAcceptedValue &&
            actualValue <= maximumAcceptedValue;
      case ProgressionComparator.withinRelativeTolerance:
        return actualValue >= minimumAcceptedValue &&
            actualValue <= maximumAcceptedValue;
    }
  }

  String evaluationKeyFor(ProgressionPeriod period) =>
      '$id|$version|${period.kind.name}|${period.anchorKey}';

  String rewardKeyFor(ProgressionPeriod period) =>
      '${evaluationKeyFor(period)}|reward';
}

class ProgressionEvaluation {
  const ProgressionEvaluation({
    required this.evaluationKey,
    required this.rewardKey,
    required this.ruleId,
    required this.ruleVersion,
    required this.domain,
    required this.period,
    required this.comparator,
    required this.actualValue,
    required this.targetValue,
    required this.upperTargetValue,
    required this.toleranceRatio,
    required this.progress,
    required this.achieved,
    required this.status,
    required this.missReason,
    required this.rewardXp,
    required this.title,
    required this.description,
    required this.explanation,
    this.baseXp,
  });

  final String evaluationKey;
  final String rewardKey;
  final String ruleId;
  final String ruleVersion;
  final ProgressionDomain domain;
  final ProgressionPeriod period;
  final ProgressionComparator comparator;
  final double actualValue;
  final double targetValue;
  final double? upperTargetValue;
  final double toleranceRatio;
  final double progress;
  final bool achieved;
  final ProgressionEvaluationStatus status;
  final ProgressionMissReason? missReason;
  final int rewardXp;
  final String title;
  final String description;
  final String explanation;
  final int? baseXp;

  double get deltaFromTarget => actualValue - targetValue;

  int get effectiveRewardXp => achieved ? rewardXp : 0;

  double get shortfallValue =>
      achieved ? 0 : (targetValue - actualValue).clamp(0, double.infinity);

  double get surplusValue =>
      achieved ? (actualValue - targetValue).clamp(0, double.infinity) : 0;
}

class ProgressionRewardGrant {
  const ProgressionRewardGrant({
    required this.rewardKey,
    required this.ruleId,
    required this.ruleVersion,
    required this.domain,
    required this.period,
    required this.xpGranted,
    required this.targetValue,
    required this.actualValue,
    required this.rewardStatus,
    required this.unlockedAt,
    this.upperTargetValue,
    this.toleranceRatio = 0,
    this.claimedAt,
    this.finalXp,
    this.levelAtClaim,
    this.multiplierAtClaim,
    this.baseXp,
  });

  final String rewardKey;
  final String ruleId;
  final String ruleVersion;
  final ProgressionDomain domain;
  final ProgressionPeriod period;
  final int xpGranted;
  final double targetValue;
  final double actualValue;
  final double? upperTargetValue;
  final double toleranceRatio;
  final ProgressionRewardStatus rewardStatus;
  final DateTime unlockedAt;
  final DateTime? claimedAt;
  final int? finalXp;
  final int? levelAtClaim;
  final double? multiplierAtClaim;
  final int? baseXp;

  bool get isClaimed => rewardStatus == ProgressionRewardStatus.claimed;
  bool get isUnlocked => rewardStatus == ProgressionRewardStatus.unlocked;
  // For already-claimed migrated records where finalXp was not set: fall back to xpGranted.
  int get effectiveXpGranted => isClaimed ? (finalXp ?? xpGranted) : 0;
  DateTime get progressionAt => claimedAt ?? unlockedAt;
}

class ProgressionProfile {
  const ProgressionProfile({
    required this.totalXp,
    required this.level,
    required this.levelFloorXp,
    required this.nextLevelXp,
    required this.xpIntoLevel,
  });

  final int totalXp;
  final int level;
  final int levelFloorXp;
  final int nextLevelXp;
  final int xpIntoLevel;

  int get xpToNextLevel => nextLevelXp - totalXp;

  double get levelProgress {
    final span = nextLevelXp - levelFloorXp;
    if (span <= 0) return 1;
    return (xpIntoLevel / span).clamp(0, 1).toDouble();
  }
}

class ProgressionAchievementUnlockEvent {
  const ProgressionAchievementUnlockEvent({
    required this.unlockKey,
    required this.achievementId,
    required this.unlockedAt,
  });

  final String unlockKey;
  final String achievementId;
  final DateTime unlockedAt;
}

class ProgressionLedgerSnapshot {
  const ProgressionLedgerSnapshot({
    required this.evaluations,
    required this.rewardGrants,
    this.questRewardGrants = const [],
    this.activeQuestIds = const <String>{},
    this.achievementUnlocks = const [],
    this.lastEvaluatedAt,
  });

  final List<ProgressionEvaluation> evaluations;
  final List<ProgressionRewardGrant> rewardGrants;
  final List<ProgressionQuestRewardGrant> questRewardGrants;
  final Set<String> activeQuestIds;
  final List<ProgressionAchievementUnlockEvent> achievementUnlocks;
  final DateTime? lastEvaluatedAt;
}

class ProgressionQuestRewardGrant {
  const ProgressionQuestRewardGrant({
    required this.rewardKey,
    required this.questId,
    required this.xpGranted,
    required this.rewardStatus,
    required this.unlockedAt,
    required this.completedAt,
    this.claimedAt,
    this.finalXp,
    this.levelAtClaim,
    this.multiplierAtClaim,
    this.baseXp,
  });

  final String rewardKey;
  final String questId;
  final int xpGranted;
  final ProgressionRewardStatus rewardStatus;
  final DateTime unlockedAt;
  final DateTime completedAt;
  final DateTime? claimedAt;
  final int? finalXp;
  final int? levelAtClaim;
  final double? multiplierAtClaim;
  final int? baseXp;

  bool get isClaimed => rewardStatus == ProgressionRewardStatus.claimed;
  bool get isUnlocked => rewardStatus == ProgressionRewardStatus.unlocked;
  int get effectiveXpGranted => isClaimed ? (finalXp ?? xpGranted) : 0;
  DateTime get progressionAt => claimedAt ?? unlockedAt;
}

class ProgressionAchievementDefinition {
  const ProgressionAchievementDefinition({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.criterionType,
    required this.title,
    required this.description,
    required this.targetValue,
    this.ruleId,
    this.domain,
    this.windowSizeDays,
    this.relatedRuleIds = const [],
    this.difficultyScore,
    this.compositeConditions,
  });

  final String id;
  final ProgressionAchievementType type;
  final ProgressionAchievementDifficulty difficulty;
  final ProgressionAchievementCriterionType criterionType;
  final String title;
  final String description;
  final int targetValue;
  final String? ruleId;
  final ProgressionDomain? domain;
  final int? windowSizeDays;
  final List<String> relatedRuleIds;

  /// Fine-grained difficulty (1.0–10.0) used for balancing, debug tooling,
  /// and future UI ordering. The coarse [difficulty] enum stays as the
  /// authoritative bucket; this is an additional dimension and may be null
  /// for legacy entries that have not been scored yet.
  final double? difficultyScore;

  /// Sub-conditions for [ProgressionAchievementCriterionType.compositeAllOf].
  /// All conditions must be met (AND) for the achievement to unlock.
  /// Conventionally [targetValue] is `1` for composite achievements; the
  /// evaluator returns `1` iff every entry's `targetValue` is satisfied,
  /// else `0`.
  final List<ProgressionAchievementCompositeCondition>? compositeConditions;

  String get unlockKey => 'achievement|$id';
}

/// One leg of a [ProgressionAchievementCriterionType.compositeAllOf]
/// achievement. The evaluator computes the metric implied by [type] (with
/// [ruleId]/[domain] filters where applicable) and checks
/// `value >= targetValue`.
///
/// Nesting composites is not allowed — `type == compositeAllOf` is rejected
/// by the evaluator.
class ProgressionAchievementCompositeCondition {
  const ProgressionAchievementCompositeCondition({
    required this.type,
    required this.targetValue,
    this.ruleId,
    this.domain,
  });

  final ProgressionAchievementCriterionType type;
  final int targetValue;
  final String? ruleId;
  final ProgressionDomain? domain;
}

class ProgressionAchievement {
  const ProgressionAchievement({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.criterionType,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
    this.ruleId,
    this.domain,
    this.relatedRuleIds = const [],
  });

  final String id;
  final ProgressionAchievementType type;
  final ProgressionAchievementDifficulty difficulty;
  final ProgressionAchievementCriterionType criterionType;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final double progress;
  final bool unlocked;
  final DateTime? unlockedAt;
  final String? ruleId;
  final ProgressionDomain? domain;
  final List<String> relatedRuleIds;
}

class ProgressionQuestDefinition {
  const ProgressionQuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.criterionType,
    required this.targetValue,
    required this.rewardXp,
    this.ruleId,
    this.domain,
    this.periodKind,
    this.achievementId,
    this.relatedRuleIds = const [],
    this.minimumLevel,
    this.minimumTrackedDays,
    this.prerequisiteQuestIds = const [],
    this.sortOrder = 0,
    this.priority = 0,
  });

  final String id;
  final String title;
  final String description;
  final ProgressionQuestType type;
  final ProgressionQuestCategory category;
  final ProgressionQuestCriterionType criterionType;
  final int targetValue;
  final int rewardXp;
  final String? ruleId;
  final ProgressionDomain? domain;
  final ProgressionPeriodKind? periodKind;
  final String? achievementId;
  final List<String> relatedRuleIds;
  final int? minimumLevel;
  final int? minimumTrackedDays;
  final List<String> prerequisiteQuestIds;
  final int sortOrder;
  final int priority;

  bool get isRepeatableReward =>
      criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleCompletion ||
      criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast;

  String rewardKeyFor(DateTime completedAt) {
    if (!isRepeatableReward) return 'quest|$id|reward';
    final anchor = progressionDateKey(completedAt);
    return 'quest|$id|$anchor|reward';
  }
}

class ProgressionQuest {
  const ProgressionQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.criterionType,
    required this.status,
    required this.targetValue,
    required this.currentValue,
    required this.progress,
    required this.prerequisiteQuestIds,
    required this.sortOrder,
    required this.priority,
    required this.isHighlighted,
    this.rewardXp = 0,
    this.rewardKey,
    this.rewardStatus,
    this.rewardUnlockedAt,
    this.rewardClaimedAt,
    this.completedAt,
    this.ruleId,
    this.domain,
    this.periodKind,
    this.achievementId,
    this.relatedRuleIds = const [],
    this.minimumLevel,
    this.minimumTrackedDays,
  });

  final String id;
  final String title;
  final String description;
  final ProgressionQuestType type;
  final ProgressionQuestCategory category;
  final ProgressionQuestCriterionType criterionType;
  final ProgressionQuestStatus status;
  final int targetValue;
  final int currentValue;
  final double progress;
  final List<String> prerequisiteQuestIds;
  final int sortOrder;
  final int priority;
  final bool isHighlighted;
  final int rewardXp;
  final String? rewardKey;
  final ProgressionRewardStatus? rewardStatus;
  final DateTime? rewardUnlockedAt;
  final DateTime? rewardClaimedAt;
  final DateTime? completedAt;
  final String? ruleId;
  final ProgressionDomain? domain;
  final ProgressionPeriodKind? periodKind;
  final String? achievementId;
  final List<String> relatedRuleIds;
  final int? minimumLevel;
  final int? minimumTrackedDays;

  bool get isCompleted => status == ProgressionQuestStatus.completed;
  bool get isLocked => status == ProgressionQuestStatus.locked;
  bool get isActive => status == ProgressionQuestStatus.active;
  bool get hasReward => rewardXp > 0;
  bool get isRewardClaimable =>
      rewardStatus == ProgressionRewardStatus.unlocked;
  bool get isRewardClaimed => rewardStatus == ProgressionRewardStatus.claimed;
}

DateTime progressionDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime startOfProgressionWeek(DateTime value) {
  final normalized = progressionDate(value);
  return normalized
      .subtract(Duration(days: normalized.weekday - DateTime.monday));
}

String progressionDateKey(DateTime value) {
  final normalized = progressionDate(value);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
