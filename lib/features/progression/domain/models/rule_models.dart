import 'core_models.dart';

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
    required this.unit,
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

  final ProgressionLocalizedText title;
  final ProgressionLocalizedText description;
  final ProgressionLocalizedText unit;

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
      case ProgressionComparator.atLeastRelativeTolerance:
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
      case ProgressionComparator.atLeastRelativeTolerance:
        return double.infinity;
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
      case ProgressionComparator.atLeastRelativeTolerance:
        return actualValue >= minimumAcceptedValue;
    }
  }

  String evaluationKeyFor(ProgressionPeriod period) =>
      '$id|$version|${period.kind.name}|${period.anchorKey}';

  String rewardKeyFor(ProgressionPeriod period) =>
      '${evaluationKeyFor(period)}|reward';
}

class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.period,
    this.steps = 0,
    this.calories = 0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
    this.fiberGrams = 0,
    this.sleepMinutes = 0,
    this.activityMinutes = 0,
    this.weightKg = 0.0,
  });

  final ProgressionPeriod period;
  final int steps;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;
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
      case ProgressionMetric.carbsGrams:
        return carbsGrams;
      case ProgressionMetric.fatGrams:
        return fatGrams;
      case ProgressionMetric.fiberGrams:
        return fiberGrams;
      case ProgressionMetric.sleepMinutes:
        return sleepMinutes.toDouble();
      case ProgressionMetric.activityMinutes:
        return activityMinutes.toDouble();
      case ProgressionMetric.weightKg:
        return weightKg;
    }
  }
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
