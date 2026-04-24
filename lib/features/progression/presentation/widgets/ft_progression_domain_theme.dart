import 'package:flutter/material.dart';

import '../../../../theme/ft_design_tokens.dart';
import '../../domain/progression_models.dart';

/// Maps progression domain ids to visual tokens and Material icons.
///
/// Kept in presentation to avoid leaking design tokens into the domain layer
/// and to give a single place to extend the mapping when new domains land.
class FtProgressionDomainTheme {
  const FtProgressionDomainTheme._();

  static const Color achievementEasy = Color(0xFF34D399);
  static const Color achievementMedium = Color(0xFF60A5FA);
  static const Color achievementHard = Color(0xFFA78BFA);
  static const Color achievementExtraHard = Color(0xFFFBBF24);

  static FtDomain tokenFor(ProgressionDomain domain) {
    switch (domain) {
      case ProgressionDomain.steps:
        return FtTokens.steps;
      case ProgressionDomain.nutrition:
        return FtTokens.calories;
      case ProgressionDomain.sleep:
        return FtTokens.sleep;
      case ProgressionDomain.activity:
        return FtTokens.active;
      case ProgressionDomain.body:
        return FtTokens.weight;
    }
  }

  static Color colorFor(ProgressionDomain domain) => tokenFor(domain).color;

  static Color colorForAchievementDifficulty(
    ProgressionAchievementDifficulty difficulty,
  ) {
    switch (difficulty) {
      case ProgressionAchievementDifficulty.easy:
        return achievementEasy;
      case ProgressionAchievementDifficulty.medium:
        return achievementMedium;
      case ProgressionAchievementDifficulty.hard:
        return achievementHard;
      case ProgressionAchievementDifficulty.extraHard:
        return achievementExtraHard;
    }
  }

  static IconData iconFor(ProgressionDomain domain) {
    switch (domain) {
      case ProgressionDomain.steps:
        return Icons.directions_walk_rounded;
      case ProgressionDomain.nutrition:
        return Icons.restaurant_rounded;
      case ProgressionDomain.sleep:
        return Icons.nightlight_round;
      case ProgressionDomain.activity:
        return Icons.bolt_rounded;
      case ProgressionDomain.body:
        return Icons.monitor_weight_outlined;
    }
  }

  static IconData iconForAchievement(ProgressionAchievement achievement) {
    switch (achievement.id) {
      case 'first_reward':
        return Icons.emoji_events_rounded;
      case 'reward_hunter_25':
        return Icons.workspace_premium_rounded;
      case 'reward_hunter_100':
        return Icons.shield_moon_rounded;
      case 'pathfinder_level_5':
      case 'trail_vanguard_level_10':
        return Icons.explore_rounded;
      case 'forge_knight_level_15':
        return Icons.hardware_rounded;
      case 'iron_warden_level_20':
        return Icons.shield_rounded;
      case 'storm_herald_level_25':
        return Icons.thunderstorm_rounded;
      case 'dawn_sentinel_level_30':
        return Icons.wb_twilight_rounded;
      case 'rift_walker_level_40':
        return Icons.blur_circular_rounded;
      case 'xp_100000':
      case 'xp_1000000':
        return Icons.local_fire_department_rounded;
      case 'mythic_ranger_level_50':
      case 'titan_forger_level_60':
      case 'astral_champion_level_70':
      case 'eternal_paragon_level_80':
      case 'realm_sovereign_level_90':
      case 'living_legend_level_100':
        return Icons.workspace_premium_rounded;
      case 'steps_total_100k':
        return Icons.directions_walk_rounded;
      case 'steps_total_500k':
      case 'steps_month_300k':
        return Icons.route_rounded;
      case 'steps_total_1000000':
      case 'steps_total_5000000':
      case 'steps_total_10000000':
      case 'steps_month_600k':
        return Icons.military_tech_rounded;
      case 'steps_streak_3':
        return Icons.local_fire_department_rounded;
      case 'steps_streak_7':
        return Icons.bolt_rounded;
      case 'steps_streak_30':
      case 'steps_streak_100':
        return Icons.whatshot_rounded;
      case 'nutrition_streak_3':
      case 'nutrition_streak_30':
      case 'nutrition_streak_100':
        return Icons.restaurant_menu_rounded;
      case 'nutrition_rewards_25':
        return Icons.restaurant_rounded;
      case 'weekly_activity_mastery':
        return Icons.fitness_center_rounded;
      case 'weekly_activity_4':
        return Icons.flash_on_rounded;
      case 'weekly_activity_12':
      case 'weekly_activity_24':
      case 'weekly_activity_52':
        return Icons.rocket_launch_rounded;
      case 'sleep_total_250h':
      case 'sleep_total_1000h':
        return Icons.bedtime_rounded;
      case 'sleep_month_225h':
      case 'sleep_month_240h':
        return Icons.nightlight_round;
      default:
        final domain = resolveForAchievement(achievement);
        return iconFor(domain);
    }
  }

  /// Rule-id → domain map. Kept in sync with ProgressionRuleCatalog.
  static ProgressionDomain? domainForRuleId(String? ruleId) {
    switch (ruleId) {
      case 'daily_steps':
        return ProgressionDomain.steps;
      case 'daily_calories':
      case 'daily_protein':
        return ProgressionDomain.nutrition;
      case 'daily_sleep':
        return ProgressionDomain.sleep;
      case 'weekly_activity':
        return ProgressionDomain.activity;
      case 'daily_weight_log':
      case 'daily_weight_goal':
        return ProgressionDomain.body;
      default:
        return null;
    }
  }

  static ProgressionDomain resolveForQuest(ProgressionQuest quest) {
    return quest.domain ??
        domainForRuleId(quest.ruleId) ??
        ProgressionDomain.steps;
  }

  static ProgressionDomain resolveForAchievement(
    ProgressionAchievement achievement,
  ) {
    return achievement.domain ??
        domainForRuleId(achievement.ruleId) ??
        ProgressionDomain.steps;
  }
}
