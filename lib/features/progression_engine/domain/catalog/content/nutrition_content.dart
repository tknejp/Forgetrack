import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/quest_display_bucket.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';

/// Nutrition domain — daily macro rules + streak/grant achievements.
///
/// Mirrors V1: rules daily_calories / daily_protein / daily_carbs /
/// daily_fat / daily_fiber, achievements nutrition_streak_3/30/100
/// and nutrition_rewards_25.

const _nutritionTol = 0.10;

List<ObjectiveDefinition> nutritionObjectives(EngineCatalogContext context) {
  final goals = context.goals;
  return [
    ObjectiveDefinition(
      id: 'daily_calories',
      metric: const CaloriesMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyCalories,
      toleranceRatio: _nutritionTol,
    ),
    ObjectiveDefinition(
      id: 'daily_protein',
      metric: const ProteinGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyProteinGrams,
      toleranceRatio: _nutritionTol,
    ),
    const ObjectiveDefinition(
      id: 'streak_nutrition_3',
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    const ObjectiveDefinition(
      id: 'streak_nutrition_30',
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
    ),
    const ObjectiveDefinition(
      id: 'streak_nutrition_100',
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
    const ObjectiveDefinition(
      id: 'reward_count_nutrition_25',
      metric: RewardCountMetric(domain: 'nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
  ];
}

List<ProgressionNode> nutritionNodes() {
  return [
    // Daily macro quests.
    QuestNode(
      id: 'daily_calories_today',
      objectiveId: 'daily_calories',
      displayBucket: QuestDisplayBucket.daily,
      titleKey: (l) => l.progRuleDailyCalories,
      descriptionKey: (l) => l.progRuleDailyCaloriesDesc,
      rewards: const [XpReward(amount: 60)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    QuestNode(
      id: 'daily_protein_today',
      objectiveId: 'daily_protein',
      displayBucket: QuestDisplayBucket.daily,
      titleKey: (l) => l.progRuleDailyProtein,
      descriptionKey: (l) => l.progRuleDailyProteinDesc,
      rewards: const [XpReward(amount: 40)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    // Nutrition streak + reward-count achievements.
    AchievementNode(
      id: 'nutrition_streak_3',
      objectiveId: 'streak_nutrition_3',
      badgeEmoji: '\u{1F338}',
      titleKey: (l) => l.progAchievementBalancedRhythmTitle,
      descriptionKey: (l) => l.progAchievementBalancedRhythmDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    AchievementNode(
      id: 'nutrition_streak_30',
      objectiveId: 'streak_nutrition_30',
      badgeEmoji: '\u{1F34E}',
      titleKey: (l) => l.progAchievementNutritionStreak30Title,
      descriptionKey: (l) => l.progAchievementNutritionStreak30Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    AchievementNode(
      id: 'nutrition_streak_100',
      objectiveId: 'streak_nutrition_100',
      badgeEmoji: '\u{1F344}',
      titleKey: (l) => l.progAchievementNutritionStreak100Title,
      descriptionKey: (l) => l.progAchievementNutritionStreak100Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
    AchievementNode(
      id: 'nutrition_rewards_25',
      objectiveId: 'reward_count_nutrition_25',
      badgeEmoji: '\u{1F957}',
      titleKey: (l) => l.progAchievementNutritionRewards25Title,
      descriptionKey: (l) => l.progAchievementNutritionRewards25Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
  ];
}
