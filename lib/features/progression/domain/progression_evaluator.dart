import 'progression_models.dart';

class ProgressionEvaluator {
  const ProgressionEvaluator();

  ProgressionEvaluation evaluate({
    required ProgressionRuleDefinition rule,
    required ProgressionSnapshot snapshot,
  }) {
    if (!rule.supportsPeriod(snapshot.period)) {
      throw ArgumentError(
        'Rule ${rule.id} expects ${rule.periodKind.name} period, '
        'got ${snapshot.period.kind.name}.',
      );
    }

    final actualValue = snapshot.metricValue(rule.metric);
    final targetValue = rule.targetValue;
    final achieved = rule.isSatisfiedBy(actualValue);
    final status = achieved
        ? ProgressionEvaluationStatus.achieved
        : ProgressionEvaluationStatus.missed;
    final missReason = achieved
        ? null
        : _resolveMissReason(rule: rule, actualValue: actualValue);

    final progress = switch (rule.comparator) {
      ProgressionComparator.atLeast =>
        _thresholdProgress(actualValue, targetValue),
      ProgressionComparator.atMost => _atMostProgress(actualValue, targetValue),
      ProgressionComparator.betweenInclusive => _betweenProgress(
          actualValue,
          rule.minimumAcceptedValue,
          rule.maximumAcceptedValue,
        ),
      ProgressionComparator.withinRelativeTolerance =>
        _toleranceProgress(actualValue, targetValue, rule.toleranceRatio),
    };

    return ProgressionEvaluation(
      evaluationKey: rule.evaluationKeyFor(snapshot.period),
      rewardKey: rule.rewardKeyFor(snapshot.period),
      ruleId: rule.id,
      ruleVersion: rule.version,
      domain: rule.domain,
      period: snapshot.period,
      comparator: rule.comparator,
      actualValue: actualValue,
      targetValue: targetValue,
      upperTargetValue: rule.upperTargetValue,
      toleranceRatio: rule.toleranceRatio,
      progress: progress,
      achieved: achieved,
      status: status,
      missReason: missReason,
      rewardXp: rule.rewardXp,
      title: rule.title,
      description: rule.description,
      explanation: _buildExplanation(
        rule: rule,
        comparator: rule.comparator,
        actualValue: actualValue,
        targetValue: targetValue,
        upperTargetValue: rule.upperTargetValue,
        toleranceRatio: rule.toleranceRatio,
        status: status,
        missReason: missReason,
      ),
    );
  }

  double _thresholdProgress(double actualValue, double targetValue) {
    if (targetValue <= 0) {
      return actualValue > 0 ? 1 : 0;
    }
    return (actualValue / targetValue).clamp(0, 1).toDouble();
  }

  double _atMostProgress(double actualValue, double targetValue) {
    if (actualValue <= targetValue) return 1;
    if (targetValue <= 0) return actualValue <= 0 ? 1 : 0;
    return (targetValue / actualValue).clamp(0, 1).toDouble();
  }

  double _betweenProgress(
    double actualValue,
    double minimumAcceptedValue,
    double maximumAcceptedValue,
  ) {
    if (actualValue >= minimumAcceptedValue &&
        actualValue <= maximumAcceptedValue) {
      return 1;
    }

    final span = maximumAcceptedValue - minimumAcceptedValue;
    if (span <= 0) {
      return actualValue == minimumAcceptedValue ? 1 : 0;
    }

    final distance = actualValue < minimumAcceptedValue
        ? minimumAcceptedValue - actualValue
        : actualValue - maximumAcceptedValue;
    return (1 - (distance / span)).clamp(0, 1).toDouble();
  }

  double _toleranceProgress(
    double actualValue,
    double targetValue,
    double toleranceRatio,
  ) {
    if (targetValue <= 0 || toleranceRatio <= 0) {
      return actualValue == targetValue ? 1 : 0;
    }

    final delta = (actualValue - targetValue).abs();
    final maxDelta = targetValue * toleranceRatio;
    final normalized = 1 - (delta / maxDelta);
    return normalized.clamp(0, 1).toDouble();
  }

  String _buildExplanation({
    required ProgressionRuleDefinition rule,
    required ProgressionComparator comparator,
    required double actualValue,
    required double targetValue,
    required double? upperTargetValue,
    required double toleranceRatio,
    required ProgressionEvaluationStatus status,
    required ProgressionMissReason? missReason,
  }) {
    final delta = actualValue - targetValue;
    final statusName = status.name;
    final missReasonName = missReason?.name;
    switch (comparator) {
      case ProgressionComparator.atLeast:
        return 'actual=$actualValue target=$targetValue comparator=atLeast '
            'acceptedMin=${rule.minimumAcceptedValue} delta=$delta '
            'status=$statusName missReason=$missReasonName';
      case ProgressionComparator.atMost:
        return 'actual=$actualValue target=$targetValue comparator=atMost '
            'acceptedMax=${rule.maximumAcceptedValue} delta=$delta '
            'status=$statusName missReason=$missReasonName';
      case ProgressionComparator.betweenInclusive:
        return 'actual=$actualValue target=$targetValue upperTarget=$upperTargetValue '
            'comparator=betweenInclusive acceptedMin=${rule.minimumAcceptedValue} '
            'acceptedMax=${rule.maximumAcceptedValue} delta=$delta '
            'status=$statusName missReason=$missReasonName';
      case ProgressionComparator.withinRelativeTolerance:
        return 'actual=$actualValue target=$targetValue comparator=withinRelativeTolerance '
            'acceptedMin=${rule.minimumAcceptedValue} acceptedMax=${rule.maximumAcceptedValue} '
            'toleranceRatio=$toleranceRatio delta=$delta '
            'status=$statusName missReason=$missReasonName';
    }
  }

  ProgressionMissReason _resolveMissReason({
    required ProgressionRuleDefinition rule,
    required double actualValue,
  }) {
    if (actualValue < rule.minimumAcceptedValue) {
      return ProgressionMissReason.belowMinimum;
    }
    if (actualValue > rule.maximumAcceptedValue) {
      return ProgressionMissReason.aboveMaximum;
    }
    return ProgressionMissReason.outsideAcceptedRange;
  }
}
