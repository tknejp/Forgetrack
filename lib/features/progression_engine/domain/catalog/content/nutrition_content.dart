import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import '../../models/claim_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// Nutrition domain — daily macro rules + streak/grant achievements.
///
/// Mirrors V1: rules daily_calories / daily_protein / daily_carbs /
/// daily_fat / daily_fiber, achievements nutrition_streak_3/30/100
/// and nutrition_rewards_25.

const _nutritionTol = 0.10;

List<Objective> nutritionObjectives(EngineCatalogContext context) {
  final goals = context.goals;
  return [
    Objective(
      id: const ObjectiveId('daily_calories'),
      domain: ProgressionDomain.nutrition,
      metric: const CaloriesMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyCalories,
      toleranceRatio: _nutritionTol,
    ),
    Objective(
      id: const ObjectiveId('daily_protein'),
      domain: ProgressionDomain.nutrition,
      metric: const ProteinGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyProteinGrams,
      toleranceRatio: _nutritionTol,
    ),
    Objective(
      id: const ObjectiveId('daily_carbs'),
      domain: ProgressionDomain.nutrition,
      metric: const CarbsGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyCarbsGrams,
      toleranceRatio: _nutritionTol,
    ),
    Objective(
      id: const ObjectiveId('daily_fat'),
      domain: ProgressionDomain.nutrition,
      metric: const FatGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyFatGrams,
      toleranceRatio: _nutritionTol,
    ),
    Objective(
      id: const ObjectiveId('daily_fiber'),
      domain: ProgressionDomain.nutrition,
      metric: const FiberGramsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeastWithTolerance,
      targetValue: goals.dailyFiberGrams,
      toleranceRatio: _nutritionTol,
    ),
    const Objective(
      id: const ObjectiveId('streak_nutrition_3'),
      domain: ProgressionDomain.nutrition,
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    const Objective(
      id: const ObjectiveId('streak_nutrition_30'),
      domain: ProgressionDomain.nutrition,
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
    ),
    const Objective(
      id: const ObjectiveId('streak_nutrition_100'),
      domain: ProgressionDomain.nutrition,
      metric: StreakDaysMetric.byDomain('nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
    const Objective(
      id: const ObjectiveId('reward_count_nutrition_25'),
      domain: ProgressionDomain.nutrition,
      metric: RewardCountMetric(domain: 'nutrition'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25,
    ),
  ];
}

List<ProgressionEntry> nutritionNodes() {
  return [
    // Daily macro quests.
    DailyQuest(
      id: const ProgressionEntryId('daily_calories_today'),
      objectiveId: 'daily_calories',
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
    DailyQuest(
      id: const ProgressionEntryId('daily_protein_today'),
      objectiveId: 'daily_protein',
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyProteinDesc,
      titleKey: (l) => l.progRuleDailyProtein,
      descriptionKey: (l) => l.progRuleDailyProteinDesc,
      rewards: const [XpReward(amount: 40)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    DailyQuest(
      id: const ProgressionEntryId('daily_carbs_today'),
      objectiveId: 'daily_carbs',
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyCarbsDesc,
      titleKey: (l) => l.progRuleDailyCarbs,
      descriptionKey: (l) => l.progRuleDailyCarbsDesc,
      rewards: const [XpReward(amount: 35)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    DailyQuest(
      id: const ProgressionEntryId('daily_fat_today'),
      objectiveId: 'daily_fat',
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyFatDesc,
      titleKey: (l) => l.progRuleDailyFat,
      descriptionKey: (l) => l.progRuleDailyFatDesc,
      rewards: const [XpReward(amount: 35)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetNutrition,
    ),
    DailyQuest(
      id: const ProgressionEntryId('daily_fiber_today'),
      objectiveId: 'daily_fiber',
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
    Achievement(
      id: const ProgressionEntryId('nutrition_streak_3'),
      objectiveId: 'streak_nutrition_3',
      badgeEmoji: '\u{1F338}',
      titleKey: (l) => l.progAchievementBalancedRhythmTitle,
      descriptionKey: (l) => l.progAchievementBalancedRhythmDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('nutrition_streak_30'),
      objectiveId: 'streak_nutrition_30',
      badgeEmoji: '\u{1F34E}',
      titleKey: (l) => l.progAchievementNutritionStreak30Title,
      descriptionKey: (l) => l.progAchievementNutritionStreak30Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('nutrition_streak_100'),
      objectiveId: 'streak_nutrition_100',
      badgeEmoji: '\u{1F344}',
      titleKey: (l) => l.progAchievementNutritionStreak100Title,
      descriptionKey: (l) => l.progAchievementNutritionStreak100Desc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: const ProgressionEntryId('nutrition_rewards_25'),
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
