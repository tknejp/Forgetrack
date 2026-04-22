import '../../../l10n/app_localizations.dart';
import '../domain/progression_models.dart';

/// Presentation-layer localizer that maps stable domain IDs
/// (quest / achievement / rule IDs, domain enum values, quest criteria)
/// to the user's current language.
///
/// The domain layer still stores English titles/descriptions as a
/// deterministic fallback when a given ID has no translation yet.
class ProgressionL10n {
  ProgressionL10n(this._l10n);

  final AppLocalizations _l10n;

  String domainLabel(ProgressionDomain domain) {
    switch (domain) {
      case ProgressionDomain.steps:
        return _l10n.progDomainSteps;
      case ProgressionDomain.nutrition:
        return _l10n.progDomainNutrition;
      case ProgressionDomain.sleep:
        return _l10n.progDomainSleep;
      case ProgressionDomain.activity:
        return _l10n.progDomainActivity;
    }
  }

  String ruleTitle(String ruleId, {String? fallback}) {
    switch (ruleId) {
      case 'daily_steps':
        return _l10n.progRuleDailySteps;
      case 'daily_calories':
        return _l10n.progRuleDailyCalories;
      case 'daily_protein':
        return _l10n.progRuleDailyProtein;
      case 'daily_sleep':
        return _l10n.progRuleDailySleep;
      case 'weekly_activity':
        return _l10n.progRuleWeeklyActivity;
      default:
        return fallback ?? ruleId.replaceAll('_', ' ');
    }
  }

  String questTitle(ProgressionQuest quest) {
    switch (quest.id) {
      case 'earn_first_reward':
        return _l10n.progQuestEarnFirstRewardTitle;
      case 'daily_two_goals_today':
        return _l10n.progQuestDailyTwoGoalsTodayTitle;
      case 'daily_triple_win_today':
        return _l10n.progQuestDailyTripleWinTodayTitle;
      case 'daily_four_pillars_today':
        return _l10n.progQuestDailyFourPillarsTodayTitle;
      case 'daily_nutrition_combo_today':
        return _l10n.progQuestDailyNutritionComboTodayTitle;
      case 'daily_recovery_focus_today':
        return _l10n.progQuestDailyRecoveryFocusTodayTitle;
      case 'daily_steps_today':
        return _l10n.progQuestDailyStepsTodayTitle;
      case 'daily_calories_today':
        return _l10n.progQuestDailyCaloriesTodayTitle;
      case 'daily_protein_today':
        return _l10n.progQuestDailyProteinTodayTitle;
      case 'daily_sleep_today':
        return _l10n.progQuestDailySleepTodayTitle;
      case 'reach_500_xp':
        return _l10n.progQuestReach500XpTitle;
      case 'reach_2000_xp':
        return _l10n.progQuestReach2000XpTitle;
      case 'reach_5000_xp':
        return _l10n.progQuestReach5000XpTitle;
      case 'earn_25_rewards':
        return _l10n.progQuestEarn25RewardsTitle;
      case 'earn_100_rewards':
        return _l10n.progQuestEarn100RewardsTitle;
      case 'steps_streak_3':
        return _l10n.progQuestStepsStreak3Title;
      case 'nutrition_rewards_5':
        return _l10n.progQuestNutritionRewards5Title;
      case 'nutrition_rewards_25':
        return _l10n.progQuestNutritionRewards25Title;
      case 'total_steps_100k':
        return _l10n.progQuestTotalSteps100kTitle;
      case 'total_steps_500k':
        return _l10n.progQuestTotalSteps500kTitle;
      case 'weekly_activity_once':
        return _l10n.progQuestWeeklyActivityOnceTitle;
      case 'weekly_activity_4':
        return _l10n.progQuestWeeklyActivity4Title;
      case 'weekly_activity_12':
        return _l10n.progQuestWeeklyActivity12Title;
      case 'unlock_step_chain':
        return _l10n.progQuestUnlockStepChainTitle;
      case 'steps_streak_7':
        return _l10n.progQuestStepsStreak7Title;
      case 'steps_streak_14':
        return _l10n.progQuestStepsStreak14Title;
      default:
        return quest.title;
    }
  }

  String questDescription(ProgressionQuest quest) {
    switch (quest.id) {
      case 'earn_first_reward':
        return _l10n.progQuestEarnFirstRewardDesc;
      case 'daily_two_goals_today':
        return _l10n.progQuestDailyTwoGoalsTodayDesc;
      case 'daily_triple_win_today':
        return _l10n.progQuestDailyTripleWinTodayDesc;
      case 'daily_four_pillars_today':
        return _l10n.progQuestDailyFourPillarsTodayDesc;
      case 'daily_nutrition_combo_today':
        return _l10n.progQuestDailyNutritionComboTodayDesc;
      case 'daily_recovery_focus_today':
        return _l10n.progQuestDailyRecoveryFocusTodayDesc;
      case 'daily_steps_today':
        return _l10n.progQuestDailyStepsTodayDesc;
      case 'daily_calories_today':
        return _l10n.progQuestDailyCaloriesTodayDesc;
      case 'daily_protein_today':
        return _l10n.progQuestDailyProteinTodayDesc;
      case 'daily_sleep_today':
        return _l10n.progQuestDailySleepTodayDesc;
      case 'reach_500_xp':
        return _l10n.progQuestReach500XpDesc;
      case 'reach_2000_xp':
        return _l10n.progQuestReach2000XpDesc;
      case 'reach_5000_xp':
        return _l10n.progQuestReach5000XpDesc;
      case 'earn_25_rewards':
        return _l10n.progQuestEarn25RewardsDesc;
      case 'earn_100_rewards':
        return _l10n.progQuestEarn100RewardsDesc;
      case 'steps_streak_3':
        return _l10n.progQuestStepsStreak3Desc;
      case 'nutrition_rewards_5':
        return _l10n.progQuestNutritionRewards5Desc;
      case 'nutrition_rewards_25':
        return _l10n.progQuestNutritionRewards25Desc;
      case 'total_steps_100k':
        return _l10n.progQuestTotalSteps100kDesc;
      case 'total_steps_500k':
        return _l10n.progQuestTotalSteps500kDesc;
      case 'weekly_activity_once':
        return _l10n.progQuestWeeklyActivityOnceDesc;
      case 'weekly_activity_4':
        return _l10n.progQuestWeeklyActivity4Desc;
      case 'weekly_activity_12':
        return _l10n.progQuestWeeklyActivity12Desc;
      case 'unlock_step_chain':
        return _l10n.progQuestUnlockStepChainDesc;
      case 'steps_streak_7':
        return _l10n.progQuestStepsStreak7Desc;
      case 'steps_streak_14':
        return _l10n.progQuestStepsStreak14Desc;
      default:
        return quest.description;
    }
  }

  String achievementTitle(ProgressionAchievement achievement) {
    switch (achievement.id) {
      case 'first_reward':
        return _l10n.progAchievementFirstRewardTitle;
      case 'reward_hunter_25':
        return _l10n.progAchievementRewardHunter25Title;
      case 'reward_hunter_100':
        return _l10n.progAchievementRewardHunter100Title;
      case 'pathfinder_level_5':
        return _l10n.progAchievementPathfinderTitle;
      case 'forge_knight_xp_5000':
        return _l10n.progAchievementForgeKnight5000Title;
      case 'living_legend_xp_15000':
        return _l10n.progAchievementLivingLegend15000Title;
      case 'steps_total_100k':
        return _l10n.progAchievementSteps100kTitle;
      case 'steps_total_500k':
        return _l10n.progAchievementSteps500kTitle;
      case 'steps_total_1000000':
        return _l10n.progAchievementSteps1000000Title;
      case 'steps_streak_3':
        return _l10n.progAchievementStepChainTitle;
      case 'steps_streak_7':
        return _l10n.progAchievementStepDisciplineTitle;
      case 'steps_streak_30':
        return _l10n.progAchievementStepSovereignTitle;
      case 'nutrition_streak_3':
        return _l10n.progAchievementBalancedRhythmTitle;
      case 'nutrition_rewards_25':
        return _l10n.progAchievementNutritionRewards25Title;
      case 'weekly_activity_mastery':
        return _l10n.progAchievementWeeklyWarriorTitle;
      case 'weekly_activity_4':
        return _l10n.progAchievementWeeklyActivity4Title;
      case 'weekly_activity_12':
        return _l10n.progAchievementWeeklyActivity12Title;
      default:
        return achievement.title;
    }
  }

  String achievementDescription(ProgressionAchievement achievement) {
    switch (achievement.id) {
      case 'first_reward':
        return _l10n.progAchievementFirstRewardDesc;
      case 'reward_hunter_25':
        return _l10n.progAchievementRewardHunter25Desc;
      case 'reward_hunter_100':
        return _l10n.progAchievementRewardHunter100Desc;
      case 'pathfinder_level_5':
        return _l10n.progAchievementPathfinderDesc;
      case 'forge_knight_xp_5000':
        return _l10n.progAchievementForgeKnight5000Desc;
      case 'living_legend_xp_15000':
        return _l10n.progAchievementLivingLegend15000Desc;
      case 'steps_total_100k':
        return _l10n.progAchievementSteps100kDesc;
      case 'steps_total_500k':
        return _l10n.progAchievementSteps500kDesc;
      case 'steps_total_1000000':
        return _l10n.progAchievementSteps1000000Desc;
      case 'steps_streak_3':
        return _l10n.progAchievementStepChainDesc;
      case 'steps_streak_7':
        return _l10n.progAchievementStepDisciplineDesc;
      case 'steps_streak_30':
        return _l10n.progAchievementStepSovereignDesc;
      case 'nutrition_streak_3':
        return _l10n.progAchievementBalancedRhythmDesc;
      case 'nutrition_rewards_25':
        return _l10n.progAchievementNutritionRewards25Desc;
      case 'weekly_activity_mastery':
        return _l10n.progAchievementWeeklyWarriorDesc;
      case 'weekly_activity_4':
        return _l10n.progAchievementWeeklyActivity4Desc;
      case 'weekly_activity_12':
        return _l10n.progAchievementWeeklyActivity12Desc;
      default:
        return achievement.description;
    }
  }

  String questCriterionDescriptor(ProgressionQuest quest) {
    switch (quest.criterionType) {
      case ProgressionQuestCriterionType.totalXpAtLeast:
        return _l10n.progQuestCriterionTotalXp;
      case ProgressionQuestCriterionType.rewardCountAtLeast:
        if (quest.ruleId != null) {
          return _l10n.progQuestCriterionRewardCountWithRule(
            ruleTitle(quest.ruleId!),
          );
        }
        return _l10n.progQuestCriterionRewardCount;
      case ProgressionQuestCriterionType.bestStreakAtLeast:
        if (quest.ruleId != null) {
          return _l10n.progQuestCriterionStreakWithRule(
            ruleTitle(quest.ruleId!),
          );
        }
        if (quest.domain != null) {
          return _l10n.progQuestCriterionStreakWithDomain(
            domainLabel(quest.domain!),
          );
        }
        return _l10n.progQuestCriterionStreakGeneric;
      case ProgressionQuestCriterionType.totalRuleValueAtLeast:
        if (quest.ruleId != null) {
          return _l10n.progQuestCriterionTotalRuleValueWithRule(
            ruleTitle(quest.ruleId!),
          );
        }
        return _l10n.progQuestCriterionTotalRuleValueGeneric;
      case ProgressionQuestCriterionType.currentPeriodRuleCompletion:
        if (quest.ruleId != null) {
          return _l10n.progQuestCriterionCurrentPeriodRule(
            ruleTitle(quest.ruleId!),
          );
        }
        return _l10n.progQuestCriterionCurrentPeriodGeneric;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
        return _l10n.progQuestCriterionCurrentPeriodRuleSet;
      case ProgressionQuestCriterionType.achievementUnlocked:
        return _l10n.progQuestCriterionAchievement;
      case ProgressionQuestCriterionType.ruleCompletionsAtLeast:
        if (quest.ruleId != null) {
          return _l10n.progQuestCriterionCompletionsWithRule(
            ruleTitle(quest.ruleId!),
          );
        }
        return _l10n.progQuestCriterionCompletionsGeneric;
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        if (quest.domain != null) {
          return _l10n.progQuestCriterionDomainRewardsWithDomain(
            domainLabel(quest.domain!),
          );
        }
        return _l10n.progQuestCriterionDomainRewardsGeneric;
    }
  }
}
