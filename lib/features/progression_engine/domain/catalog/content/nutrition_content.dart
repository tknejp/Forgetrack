import '../../../../../shared/domain/rarity.dart';
import '../../models/claim_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/quest_display_bucket.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

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
      domain: ProgressionDomain.nutrition,
      metric: const CaloriesMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyCalories,
      toleranceRatio: _nutritionTol,
    ),
    ObjectiveDefinition(
      id: 'daily_protein',
      domain: ProgressionDomain.nutrition,
      metric: const ProteinGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyProteinGrams,
      toleranceRatio: _nutritionTol,
    ),
    ObjectiveDefinition(
      id: 'daily_carbs',
      domain: ProgressionDomain.nutrition,
      metric: const CarbsGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyCarbsGrams,
      toleranceRatio: _nutritionTol,
    ),
    ObjectiveDefinition(
      id: 'daily_fat',
      domain: ProgressionDomain.nutrition,
      metric: const FatGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyFatGrams,
      toleranceRatio: _nutritionTol,
    ),
    ObjectiveDefinition(
      id: 'daily_fiber',
      domain: ProgressionDomain.nutrition,
      metric: const FiberGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyFiberGrams,
      toleranceRatio: _nutritionTol,
    ),
    const ObjectiveDefinition(
      id: 'streak_nutrition_3',
      domain: ProgressionDomain.nutrition,
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    const ObjectiveDefinition(
      id: 'streak_nutrition_30',
      domain: ProgressionDomain.nutrition,
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
    ),
    const ObjectiveDefinition(
      id: 'streak_nutrition_100',
      domain: ProgressionDomain.nutrition,
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
    const ObjectiveDefinition(
      id: 'reward_count_nutrition_25',
      domain: ProgressionDomain.nutrition,
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
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyCaloriesDesc,
      titleKey: (l) => l.progRuleDailyCalories,
      descriptionKey: (l) => l.progRuleDailyCaloriesHintedDesc,
      // Base 60 XP, +60 bonus when claimed before 14:00 (lunch).
      rewards: const [
        XpReward(amount: 60),
        BonusXpReward(
          amount: 60,
          condition: CompletedBeforeHour(14),
        ),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    QuestNode(
      id: 'daily_protein_today',
      objectiveId: 'daily_protein',
      displayBucket: QuestDisplayBucket.daily,
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyProteinDesc,
      titleKey: (l) => l.progRuleDailyProtein,
      descriptionKey: (l) => l.progRuleDailyProteinDesc,
      rewards: const [XpReward(amount: 40)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    QuestNode(
      id: 'daily_carbs_today',
      objectiveId: 'daily_carbs',
      displayBucket: QuestDisplayBucket.daily,
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyCarbsDesc,
      titleKey: (l) => l.progRuleDailyCarbs,
      descriptionKey: (l) => l.progRuleDailyCarbsDesc,
      rewards: const [XpReward(amount: 35)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    QuestNode(
      id: 'daily_fat_today',
      objectiveId: 'daily_fat',
      displayBucket: QuestDisplayBucket.daily,
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyFatDesc,
      titleKey: (l) => l.progRuleDailyFat,
      descriptionKey: (l) => l.progRuleDailyFatDesc,
      rewards: const [XpReward(amount: 35)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    QuestNode(
      id: 'daily_fiber_today',
      objectiveId: 'daily_fiber',
      displayBucket: QuestDisplayBucket.daily,
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyFiberDesc,
      titleKey: (l) => l.progRuleDailyFiber,
      descriptionKey: (l) => l.progRuleDailyFiberDesc,
      rewards: const [XpReward(amount: 35)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
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
