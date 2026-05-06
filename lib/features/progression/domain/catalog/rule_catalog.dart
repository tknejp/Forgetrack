import '../../../../l10n/app_localizations.dart';
import '../progression_models.dart';

class ProgressionRuleCatalog {
  const ProgressionRuleCatalog();

  static String titleForId(
    String id,
    AppLocalizations l10n, {
    String? fallback,
  }) {
    final definition = displayDefinitionForId(id);
    assert(
      definition != null || fallback != null,
      'Unknown progression rule id: $id',
    );
    return definition?.title(l10n) ??
        fallback ??
        id.replaceAll('_', ' ');
  }

  static String unitForId(String? id, AppLocalizations l10n) =>
      id == null ? '' : (displayDefinitionForId(id)?.unit(l10n) ?? '');

  static ProgressionRuleDefinition? displayDefinitionForId(String id) =>
      _displayDefinitionsById[id];

  static final Map<String, ProgressionRuleDefinition> _displayDefinitionsById =
      {
    for (final definition in ProgressionRuleCatalog().build(
      ProgressionGoalSet(
        dailySteps: 0,
        dailyCalories: 0,
        dailyProteinGrams: 0,
        sleepMinutes: 0,
        weeklyActivityMinutes: 0,
      ),
    ))
      definition.id: definition,
  };

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
        title: (l10n) => l10n.progRuleDailySteps,
        description: (l10n) => l10n.progRuleDailyStepsDesc,
        unit: (l10n) => l10n.goalUnitSteps,
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
        title: (l10n) => l10n.progRuleDailyCalories,
        description: (l10n) => l10n.progRuleDailyCaloriesDesc,
        unit: (l10n) => l10n.goalUnitKcal,
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
        title: (l10n) => l10n.progRuleDailyProtein,
        description: (l10n) => l10n.progRuleDailyProteinDesc,
        unit: (l10n) => l10n.goalUnitG,
      ),
      ProgressionRuleDefinition(
        id: 'daily_carbs',
        version: _version,
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.carbsGrams,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.dailyCarbsGrams,
        rewardXp: 35,
        title: (l10n) => l10n.progRuleDailyCarbs,
        description: (l10n) => l10n.progRuleDailyCarbsDesc,
        unit: (l10n) => l10n.goalUnitG,
      ),
      ProgressionRuleDefinition(
        id: 'daily_fat',
        version: _version,
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.fatGrams,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.dailyFatGrams,
        rewardXp: 35,
        title: (l10n) => l10n.progRuleDailyFat,
        description: (l10n) => l10n.progRuleDailyFatDesc,
        unit: (l10n) => l10n.goalUnitG,
      ),
      ProgressionRuleDefinition(
        id: 'daily_fiber',
        version: _version,
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.fiberGrams,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: goals.dailyFiberGrams,
        rewardXp: 45,
        title: (l10n) => l10n.progRuleDailyFiber,
        description: (l10n) => l10n.progRuleDailyFiberDesc,
        unit: (l10n) => l10n.goalUnitG,
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
        title: (l10n) => l10n.progRuleDailySleep,
        description: (l10n) => l10n.progRuleDailySleepDesc,
        unit: (l10n) => l10n.goalUnitMins,
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
        title: (l10n) => l10n.progRuleWeeklyActivity,
        description: (l10n) => l10n.progRuleWeeklyActivityDesc,
        unit: (l10n) => l10n.goalUnitMins,
      ),
      ProgressionRuleDefinition(
        id: 'daily_weight_log',
        version: _version,
        domain: ProgressionDomain.body,
        metric: ProgressionMetric.weightKg,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atLeast,
        targetValue: 1.0,
        rewardXp: 20,
        title: (l10n) => l10n.progRuleDailyWeightLog,
        description: (l10n) => l10n.progRuleDailyWeightLogDesc,
        unit: (l10n) => l10n.goalUnitKg,
      ),
      ProgressionRuleDefinition(
        id: 'daily_weight_goal',
        version: _version,
        domain: ProgressionDomain.body,
        metric: ProgressionMetric.weightKg,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.withinRelativeTolerance,
        targetValue: goals.targetWeightKg,
        toleranceRatio: 0.03,
        rewardXp: 150,
        title: (l10n) => l10n.progRuleDailyWeightGoal,
        description: (l10n) => l10n.progRuleDailyWeightGoalDesc,
        unit: (l10n) => l10n.goalUnitKg,
      ),
    ];
  }
}
