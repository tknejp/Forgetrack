import 'progression_models.dart';

class ProgressionRuleCatalog {
  const ProgressionRuleCatalog();

  static const _version = '2026-04-defaults-v1';
  static const _calorieToleranceRatio = 0.10;

  List<ProgressionRuleDefinition> build(ProgressionGoalSet goals) {
    return [
      ProgressionRuleDefinition(
        id: 'daily_steps',
        version: _version,
        domain: ProgressionDomain.steps,
        metric: ProgressionMetric.steps,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.dailySteps.toDouble(),
        rewardXp: 80,
        title: 'Daily Steps',
        description: 'Reach the configured daily steps target.',
      ),
      ProgressionRuleDefinition(
        id: 'daily_calories',
        version: _version,
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.calories,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.withinRelativeTolerance,
        targetValue: goals.dailyCalories,
        toleranceRatio: _calorieToleranceRatio,
        rewardXp: 60,
        title: 'Daily Calories',
        description: 'Stay within the default +-10% calorie target window.',
      ),
      ProgressionRuleDefinition(
        id: 'daily_protein',
        version: _version,
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.proteinGrams,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.dailyProteinGrams,
        rewardXp: 40,
        title: 'Daily Protein',
        description: 'Reach the configured daily protein target.',
      ),
      ProgressionRuleDefinition(
        id: 'daily_sleep',
        version: _version,
        domain: ProgressionDomain.sleep,
        metric: ProgressionMetric.sleepMinutes,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.sleepMinutes.toDouble(),
        rewardXp: 50,
        title: 'Daily Sleep',
        description: 'Reach the configured nightly sleep duration target.',
      ),
      ProgressionRuleDefinition(
        id: 'weekly_activity',
        version: _version,
        domain: ProgressionDomain.activity,
        metric: ProgressionMetric.activityMinutes,
        periodKind: ProgressionPeriodKind.week,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.weeklyActivityMinutes.toDouble(),
        rewardXp: 120,
        title: 'Weekly Activity',
        description: 'Accumulate the configured weekly activity minutes.',
      ),
    ];
  }
}
