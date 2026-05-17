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

/// Steps domain — daily walking quest, lifetime mastery achievements,
/// best-rolling-window achievements, and per-rule streak achievements.
///
/// Mirrors V1 entries: rule `daily_steps`, achievements
/// `steps_total_100k`/`500k`/`1M`/`5M`/`10M`, `steps_month_300k`/`600k`,
/// `steps_streak_3`/`7`/`30`/`50`/`100`.

List<Objective> stepsObjectives(EngineCatalogContext context) {
  final goals = context.goals;
  return [
    Objective(
      id: 'daily_steps',
      domain: ProgressionDomain.steps,
      metric: const StepsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: goals.dailySteps.toDouble(),
      debugLabel: 'Steps today >= dailyStepsGoal',
    ),
    const Objective(
      id: 'lifetime_steps_100k',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100000,
    ),
    const Objective(
      id: 'lifetime_steps_500k',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 500000,
    ),
    const Objective(
      id: 'lifetime_steps_1m',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1000000,
    ),
    const Objective(
      id: 'lifetime_steps_2_5m',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2500000,
    ),
    const Objective(
      id: 'lifetime_steps_5m',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5000000,
    ),
    const Objective(
      id: 'lifetime_steps_10m',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 10000000,
    ),
    const Objective(
      id: 'rolling_steps_30d_300k',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: RollingWindowScope(days: 30),
      operator: ObjectiveOperator.atLeast,
      targetValue: 300000,
    ),
    const Objective(
      id: 'rolling_steps_30d_600k',
      domain: ProgressionDomain.steps,
      metric: StepsMetric(),
      scope: RollingWindowScope(days: 30),
      operator: ObjectiveOperator.atLeast,
      targetValue: 600000,
    ),
    const Objective(
      id: 'streak_steps_3',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    const Objective(
      id: 'streak_steps_7',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
    ),
    const Objective(
      id: 'streak_steps_30',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
    ),
    const Objective(
      id: 'streak_steps_50',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 50,
    ),
    const Objective(
      id: 'streak_steps_100',
      domain: ProgressionDomain.steps,
      metric: StreakDaysMetric.byRule('daily_steps'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 100,
    ),
  ];
}

List<ProgressionEntry> stepsNodes() {
  return [
    // Daily quest — manual claim so the player taps "Vyzvednout"
    // to grant XP, matching V1 UX.
    DailyQuest(
      id: 'daily_steps_today',
      objectiveId: 'daily_steps',
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyStepsDesc,
      titleKey: (l) => l.progRuleDailySteps,
      descriptionKey: (l) => l.progRuleDailyStepsHintedDesc,
      // Base 80 XP, +80 bonus when claimed before 18:00 (2× total).
      // Rewards on-the-day completion vs. last-minute claims.
      rewards: const [
        XpReward(amount: 80),
        BonusXpReward(
          amount: 80,
          condition: CompletedBeforeHour(18),
        ),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetSteps,
    ),

    // Lifetime mastery achievements.
    Achievement(
      id: 'steps_total_100k',
      objectiveId: 'lifetime_steps_100k',
      badgeEmoji: '\u{1F97E}',
      titleKey: (l) => l.progAchievementSteps100kTitle,
      descriptionKey: (l) => l.progAchievementSteps100kDesc,
      // Relic reward moved to `steps_total_2_5m` so the Cave Lynx (lvl 55)
      // unlock pair lands in the right difficulty band rather than week one.
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    Achievement(
      id: 'steps_total_500k',
      objectiveId: 'lifetime_steps_500k',
      badgeEmoji: '\u{1F97E}',
      titleKey: (l) => l.progAchievementSteps500kTitle,
      descriptionKey: (l) => l.progAchievementSteps500kDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: 'steps_total_1000000',
      objectiveId: 'lifetime_steps_1m',
      badgeEmoji: '\u{1F97E}',
      titleKey: (l) => l.progAchievementSteps1000000Title,
      descriptionKey: (l) => l.progAchievementSteps1000000Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_deep_ember_core')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'steps_total_2_5m',
      objectiveId: 'lifetime_steps_2_5m',
      badgeEmoji: '\u{1F97E}',
      titleKey: (l) => l.progAchievementSteps2500000Title,
      descriptionKey: (l) => l.progAchievementSteps2500000Desc,
      // Sources relic_ravine_stone — mid-game (~8–9 months) ingredient for
      // the Cave Lynx (lvl 55) companion pair.
      rewards: const [CosmeticReward(cosmeticId: 'relic_ravine_stone')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'steps_total_5000000',
      objectiveId: 'lifetime_steps_5m',
      badgeEmoji: '\u{1F48E}',
      titleKey: (l) => l.progAchievementSteps5000000Title,
      descriptionKey: (l) => l.progAchievementSteps5000000Desc,
      rewards: const [CosmeticReward(cosmeticId: 'relic_frost_shard')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: 'steps_total_10000000',
      objectiveId: 'lifetime_steps_10m',
      badgeEmoji: '\u{1F3D4}\u{FE0F}',
      titleKey: (l) => l.progAchievementSteps10000000Title,
      descriptionKey: (l) => l.progAchievementSteps10000000Desc,
      rewards: const [
        CosmeticReward(cosmeticId: 'relic_dragon_scale'),
        CosmeticReward(cosmeticId: 'frame_worldwalker'),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),

    // Rolling-window mastery achievements.
    Achievement(
      id: 'steps_month_300k',
      objectiveId: 'rolling_steps_30d_300k',
      badgeEmoji: '\u{1F5FA}\u{FE0F}',
      titleKey: (l) => l.progAchievementStepsMonth300kTitle,
      descriptionKey: (l) => l.progAchievementStepsMonth300kDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: 'steps_month_600k',
      objectiveId: 'rolling_steps_30d_600k',
      badgeEmoji: '\u{1F30D}',
      titleKey: (l) => l.progAchievementStepsMonth600kTitle,
      descriptionKey: (l) => l.progAchievementStepsMonth600kDesc,
      rewards: const [CosmeticReward(cosmeticId: 'frame_endless_trail')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),

    // Streak achievements.
    Achievement(
      id: 'steps_streak_3',
      objectiveId: 'streak_steps_3',
      badgeEmoji: '\u{1F525}',
      titleKey: (l) => l.progAchievementStepChainTitle,
      descriptionKey: (l) => l.progAchievementStepChainDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    Achievement(
      id: 'steps_streak_7',
      objectiveId: 'streak_steps_7',
      badgeEmoji: '\u{1F525}',
      titleKey: (l) => l.progAchievementStepDisciplineTitle,
      descriptionKey: (l) => l.progAchievementStepDisciplineDesc,
      rewards: const [
        CosmeticReward(cosmeticId: 'relic_ruin_seal'),
        CosmeticReward(cosmeticId: 'frame_discipline'),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: 'steps_streak_30',
      objectiveId: 'streak_steps_30',
      badgeEmoji: '\u{1F525}',
      titleKey: (l) => l.progAchievementStepSovereignTitle,
      descriptionKey: (l) => l.progAchievementStepSovereignDesc,
      rewards: const [CosmeticReward(cosmeticId: 'frame_endurance')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'steps_streak_50',
      objectiveId: 'streak_steps_50',
      badgeEmoji: '\u{1F525}',
      titleKey: (l) => l.progAchievementStepsStreak50Title,
      descriptionKey: (l) => l.progAchievementStepsStreak50Desc,
      rewards: const [CosmeticReward(cosmeticId: 'frame_steel')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: 'steps_streak_100',
      objectiveId: 'streak_steps_100',
      badgeEmoji: '\u{26D3}\u{FE0F}',
      titleKey: (l) => l.progAchievementStepCenturionTitle,
      descriptionKey: (l) => l.progAchievementStepCenturionDesc,
      rewards: const [CosmeticReward(cosmeticId: 'frame_eternal_flame')],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
  ];
}
