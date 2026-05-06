import '../policy/level_config.dart';
import '../policy/level_policy.dart';
import '../progression_models.dart';

const _emojiTrophy = '\u{1F3C6}';
const _emojiSword = '\u{2694}\u{FE0F}';
const _emojiSparkles = '\u{2728}';
const _emojiStar = '\u{1F31F}';
const _emojiBoot = '\u{1F97E}';
const _emojiGem = '\u{1F48E}';
const _emojiMountain = '\u{1F3D4}\u{FE0F}';
const _emojiMap = '\u{1F5FA}\u{FE0F}';
const _emojiGlobe = '\u{1F30D}';
const _emojiFire = '\u{1F525}';
const _emojiChains = '\u{26D3}\u{FE0F}';
const _emojiBlossom = '\u{1F338}';
const _emojiApple = '\u{1F34E}';
const _emojiMushroom = '\u{1F344}';
const _emojiSalad = '\u{1F957}';
const _emojiWeightLifter = '\u{1F3CB}';
const _emojiGolfer = '\u{1F3CC}';
const _emojiRunner = '\u{1F3C3}';
const _emojiGymnast = '\u{1F938}';
const _emojiClimber = '\u{1F9D7}';
const _emojiBed = '\u{1F6CC}';
const _emojiCrescent = '\u{1F31C}';
const _emojiCrown = '\u{1F451}';

class ProgressionAchievementCatalog {
  const ProgressionAchievementCatalog();

  static final Map<String, ProgressionAchievementDefinition> _byId = {
    for (final def in ProgressionAchievementCatalog().build()) def.id: def,
  };

  static ProgressionAchievementDefinition? definitionForId(String id) =>
      _byId[id];

  List<ProgressionAchievementDefinition> build() {
    const levelPolicy = ProgressionLevelPolicy();
    return [
      ProgressionAchievementDefinition(
        id: 'welcome_to_journey',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType: ProgressionAchievementCriterionType.totalXpAtLeast,
        title: (l10n) => l10n.progAchievementWelcomeToJourneyTitle,
        description: (l10n) => l10n.progAchievementWelcomeToJourneyDesc,
        targetValue: 0,
      ),
      ProgressionAchievementDefinition(
        id: 'first_reward',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementFirstRewardTitle,
        description: (l10n) => l10n.progAchievementFirstRewardDesc,
        badgeEmoji: _emojiTrophy,
        targetValue: 1,
      ),
      // Level milestone achievements — generated from kProgressionLevelTiers.
      // Level 1 is the journey origin (not a milestone the player "earns") so
      // it is excluded from the catalog.
      for (final tier in kProgressionLevelTiers.where((t) => t.level > 1))
        ProgressionAchievementDefinition(
          id: tier.achievementId,
          type: ProgressionAchievementType.milestone,
          difficulty: tier.difficulty,
          criterionType: ProgressionAchievementCriterionType.totalXpAtLeast,
          title: tier.title,
          description: (l10n) => l10n.progLevelAchievementDesc(tier.level),
          badgeEmoji: emojiForLevel(tier.level),
          targetValue: levelPolicy.xpRequiredForLevel(tier.level),
        ),
      ProgressionAchievementDefinition(
        id: 'steps_total_100k',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSteps100kTitle,
        description: (l10n) => l10n.progAchievementSteps100kDesc,
        badgeEmoji: _emojiBoot,
        targetValue: 100000,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_streak_3',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementStepChainTitle,
        description: (l10n) => l10n.progAchievementStepChainDesc,
        badgeEmoji: _emojiFire,
        targetValue: 3,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'nutrition_streak_3',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementBalancedRhythmTitle,
        description: (l10n) => l10n.progAchievementBalancedRhythmDesc,
        badgeEmoji: _emojiBlossom,
        targetValue: 3,
        domain: ProgressionDomain.nutrition,
      ),
      ProgressionAchievementDefinition(
        id: 'weekly_activity_mastery',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementWeeklyWarriorTitle,
        description: (l10n) => l10n.progAchievementWeeklyWarriorDesc,
        badgeEmoji: _emojiWeightLifter,
        targetValue: 1,
        ruleId: 'weekly_activity',
      ),
      ProgressionAchievementDefinition(
        id: 'sleep_total_250h',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.easy,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSleep250hTitle,
        description: (l10n) => l10n.progAchievementSleep250hDesc,
        badgeEmoji: _emojiBed,
        targetValue: 15000,
        ruleId: 'daily_sleep',
      ),
      ProgressionAchievementDefinition(
        id: 'reward_hunter_25',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementRewardHunter25Title,
        description: (l10n) => l10n.progAchievementRewardHunter25Desc,
        badgeEmoji: _emojiSword,
        targetValue: 25,
      ),
      ProgressionAchievementDefinition(
        id: 'steps_total_500k',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSteps500kTitle,
        description: (l10n) => l10n.progAchievementSteps500kDesc,
        badgeEmoji: _emojiBoot,
        targetValue: 500000,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_streak_7',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementStepDisciplineTitle,
        description: (l10n) => l10n.progAchievementStepDisciplineDesc,
        badgeEmoji: _emojiFire,
        targetValue: 7,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'nutrition_rewards_25',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementNutritionRewards25Title,
        description: (l10n) => l10n.progAchievementNutritionRewards25Desc,
        badgeEmoji: _emojiSalad,
        targetValue: 25,
        domain: ProgressionDomain.nutrition,
      ),
      ProgressionAchievementDefinition(
        id: 'weekly_activity_4',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementWeeklyActivity4Title,
        description: (l10n) => l10n.progAchievementWeeklyActivity4Desc,
        badgeEmoji: _emojiGolfer,
        targetValue: 4,
        ruleId: 'weekly_activity',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_month_300k',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType: ProgressionAchievementCriterionType
            .bestRollingWindowRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementStepsMonth300kTitle,
        description: (l10n) => l10n.progAchievementStepsMonth300kDesc,
        badgeEmoji: _emojiMap,
        targetValue: 300000,
        ruleId: 'daily_steps',
        windowSizeDays: 30,
      ),
      ProgressionAchievementDefinition(
        id: 'sleep_total_1000h',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSleep1000hTitle,
        description: (l10n) => l10n.progAchievementSleep1000hDesc,
        badgeEmoji: _emojiGem,
        targetValue: 60000,
        ruleId: 'daily_sleep',
      ),
      ProgressionAchievementDefinition(
        id: 'reward_hunter_100',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementRewardHunter100Title,
        description: (l10n) => l10n.progAchievementRewardHunter100Desc,
        badgeEmoji: _emojiSword,
        targetValue: 100,
      ),
      ProgressionAchievementDefinition(
        id: 'xp_100000',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.totalXpAtLeast,
        title: (l10n) => l10n.progAchievementXp100000Title,
        description: (l10n) => l10n.progAchievementXp100000Desc,
        badgeEmoji: _emojiSparkles,
        targetValue: 100000,
      ),
      ProgressionAchievementDefinition(
        id: 'steps_total_1000000',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSteps1000000Title,
        description: (l10n) => l10n.progAchievementSteps1000000Desc,
        badgeEmoji: _emojiBoot,
        targetValue: 1000000,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_streak_30',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementStepSovereignTitle,
        description: (l10n) => l10n.progAchievementStepSovereignDesc,
        badgeEmoji: _emojiFire,
        targetValue: 30,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_streak_50',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementStepsStreak50Title,
        description: (l10n) => l10n.progAchievementStepsStreak50Desc,
        badgeEmoji: _emojiFire,
        targetValue: 50,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'nutrition_streak_30',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementNutritionStreak30Title,
        description: (l10n) => l10n.progAchievementNutritionStreak30Desc,
        badgeEmoji: _emojiApple,
        targetValue: 30,
        domain: ProgressionDomain.nutrition,
      ),
      ProgressionAchievementDefinition(
        id: 'weekly_activity_12',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementWeeklyActivity12Title,
        description: (l10n) => l10n.progAchievementWeeklyActivity12Desc,
        badgeEmoji: _emojiRunner,
        targetValue: 12,
        ruleId: 'weekly_activity',
      ),
      ProgressionAchievementDefinition(
        id: 'weekly_activity_24',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementWeeklyActivity24Title,
        description: (l10n) => l10n.progAchievementWeeklyActivity24Desc,
        badgeEmoji: _emojiGymnast,
        targetValue: 24,
        ruleId: 'weekly_activity',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_month_600k',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType
            .bestRollingWindowRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementStepsMonth600kTitle,
        description: (l10n) => l10n.progAchievementStepsMonth600kDesc,
        badgeEmoji: _emojiGlobe,
        targetValue: 600000,
        ruleId: 'daily_steps',
        windowSizeDays: 30,
      ),
      ProgressionAchievementDefinition(
        id: 'sleep_month_225h',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        criterionType: ProgressionAchievementCriterionType
            .bestRollingWindowRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSleepMonth225hTitle,
        description: (l10n) => l10n.progAchievementSleepMonth225hDesc,
        badgeEmoji: _emojiCrescent,
        targetValue: 13500,
        ruleId: 'daily_sleep',
        windowSizeDays: 30,
      ),
      ProgressionAchievementDefinition(
        id: 'xp_1000000',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType: ProgressionAchievementCriterionType.totalXpAtLeast,
        title: (l10n) => l10n.progAchievementXp1000000Title,
        description: (l10n) => l10n.progAchievementXp1000000Desc,
        badgeEmoji: _emojiStar,
        targetValue: 1000000,
      ),
      ProgressionAchievementDefinition(
        id: 'steps_total_5000000',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSteps5000000Title,
        description: (l10n) => l10n.progAchievementSteps5000000Desc,
        badgeEmoji: _emojiGem,
        targetValue: 5000000,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_total_10000000',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType:
            ProgressionAchievementCriterionType.totalRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSteps10000000Title,
        description: (l10n) => l10n.progAchievementSteps10000000Desc,
        badgeEmoji: _emojiMountain,
        targetValue: 10000000,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'steps_streak_100',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementStepCenturionTitle,
        description: (l10n) => l10n.progAchievementStepCenturionDesc,
        badgeEmoji: _emojiChains,
        targetValue: 100,
        ruleId: 'daily_steps',
      ),
      ProgressionAchievementDefinition(
        id: 'nutrition_streak_100',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType: ProgressionAchievementCriterionType.bestStreakAtLeast,
        title: (l10n) => l10n.progAchievementNutritionStreak100Title,
        description: (l10n) => l10n.progAchievementNutritionStreak100Desc,
        badgeEmoji: _emojiMushroom,
        targetValue: 100,
        domain: ProgressionDomain.nutrition,
      ),
      ProgressionAchievementDefinition(
        id: 'weekly_activity_52',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
        title: (l10n) => l10n.progAchievementWeeklyActivity52Title,
        description: (l10n) => l10n.progAchievementWeeklyActivity52Desc,
        badgeEmoji: _emojiClimber,
        targetValue: 52,
        ruleId: 'weekly_activity',
      ),
      ProgressionAchievementDefinition(
        id: 'sleep_month_240h',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        criterionType: ProgressionAchievementCriterionType
            .bestRollingWindowRuleValueAtLeast,
        title: (l10n) => l10n.progAchievementSleepMonth240hTitle,
        description: (l10n) => l10n.progAchievementSleepMonth240hDesc,
        badgeEmoji: _emojiCrown,
        targetValue: 14400,
        ruleId: 'daily_sleep',
        windowSizeDays: 30,
      ),
      // -- Phase 3a: quest-count and active-day achievements -----------------
      ProgressionAchievementDefinition(
        id: 'daily_quest_3',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.easy,
        difficultyScore: 1.3,
        criterionType:
            ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast,
        title: (l10n) => l10n.progAchievementDailyQuest3Title,
        description: (l10n) => l10n.progAchievementDailyQuest3Desc,
        targetValue: 3,
      ),
      ProgressionAchievementDefinition(
        id: 'daily_quest_7',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.easy,
        difficultyScore: 1.8,
        criterionType:
            ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast,
        title: (l10n) => l10n.progAchievementDailyQuest7Title,
        description: (l10n) => l10n.progAchievementDailyQuest7Desc,
        targetValue: 7,
      ),
      ProgressionAchievementDefinition(
        id: 'quest_hunter_250',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        difficultyScore: 6.8,
        criterionType:
            ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast,
        title: (l10n) => l10n.progAchievementQuestHunter250Title,
        description: (l10n) => l10n.progAchievementQuestHunter250Desc,
        targetValue: 250,
      ),
      ProgressionAchievementDefinition(
        id: 'active_days_7',
        type: ProgressionAchievementType.streak,
        difficulty: ProgressionAchievementDifficulty.easy,
        difficultyScore: 1.5,
        criterionType: ProgressionAchievementCriterionType.activeDaysAtLeast,
        title: (l10n) => l10n.progAchievementActiveDays7Title,
        description: (l10n) => l10n.progAchievementActiveDays7Desc,
        targetValue: 7,
      ),
      // -- Phase 3b: perfect-period achievements ----------------------------
      ProgressionAchievementDefinition(
        id: 'perfect_days_7',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        difficultyScore: 4.5,
        criterionType: ProgressionAchievementCriterionType.perfectDaysAtLeast,
        title: (l10n) => l10n.progAchievementPerfectDays7Title,
        description: (l10n) => l10n.progAchievementPerfectDays7Desc,
        targetValue: 7,
      ),
      ProgressionAchievementDefinition(
        id: 'perfect_weeks_12',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        difficultyScore: 7.5,
        criterionType: ProgressionAchievementCriterionType.perfectWeeksAtLeast,
        title: (l10n) => l10n.progAchievementPerfectWeeks12Title,
        description: (l10n) => l10n.progAchievementPerfectWeeks12Desc,
        targetValue: 12,
      ),
      // -- Phase 3c: combo quest achievements -------------------------------
      ProgressionAchievementDefinition(
        id: 'combo_victory_10',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.medium,
        difficultyScore: 3.5,
        criterionType:
            ProgressionAchievementCriterionType.comboQuestsCompletedAtLeast,
        title: (l10n) => l10n.progAchievementComboVictory10Title,
        description: (l10n) => l10n.progAchievementComboVictory10Desc,
        targetValue: 10,
      ),
      ProgressionAchievementDefinition(
        id: 'combo_triple_victory_25',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.hard,
        difficultyScore: 5.0,
        criterionType: ProgressionAchievementCriterionType
            .tripleComboQuestsCompletedAtLeast,
        title: (l10n) => l10n.progAchievementComboTripleVictory25Title,
        description: (l10n) => l10n.progAchievementComboTripleVictory25Desc,
        targetValue: 25,
      ),
      ProgressionAchievementDefinition(
        id: 'combo_triple_victory_100',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        difficultyScore: 8.0,
        criterionType: ProgressionAchievementCriterionType
            .tripleComboQuestsCompletedAtLeast,
        title: (l10n) => l10n.progAchievementComboTripleVictory100Title,
        description: (l10n) => l10n.progAchievementComboTripleVictory100Desc,
        targetValue: 100,
      ),
      // -- Phase 3d: composite endgame trial --------------------------------
      ProgressionAchievementDefinition(
        id: 'dragonrock_trial',
        type: ProgressionAchievementType.mastery,
        difficulty: ProgressionAchievementDifficulty.extraHard,
        difficultyScore: 10.0,
        criterionType: ProgressionAchievementCriterionType.compositeAllOf,
        title: (l10n) => l10n.progAchievementDragonrockTrialTitle,
        description: (l10n) => l10n.progAchievementDragonrockTrialDesc,
        targetValue: 1,
        compositeConditions: [
          ProgressionAchievementCompositeCondition(
            type: ProgressionAchievementCriterionType.totalXpAtLeast,
            targetValue: levelPolicy.xpRequiredForLevel(100),
          ),
          const ProgressionAchievementCompositeCondition(
            type:
                ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast,
            targetValue: 250,
          ),
          const ProgressionAchievementCompositeCondition(
            type: ProgressionAchievementCriterionType.totalRuleValueAtLeast,
            ruleId: 'daily_steps',
            targetValue: 10000000,
          ),
        ],
      ),
    ];
  }
}

