import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../domain/progression_level_config.dart';
import '../../domain/progression_models.dart';

/// Maps progression domain ids to visual tokens and Material icons.
///
/// Kept in presentation to avoid leaking design tokens into the domain layer
/// and to give a single place to extend the mapping when new domains land.
class ProgressionDomainTheme {
  const ProgressionDomainTheme._();

  static const Color achievementEasy = Tokens.difficultyEasy;
  static const Color achievementMedium = Tokens.difficultyMedium;
  static const Color achievementHard = Tokens.difficultyHard;
  static const Color achievementExtraHard = Tokens.difficultyExtraHard;

  static Domain tokenFor(ProgressionDomain domain) {
    switch (domain) {
      case ProgressionDomain.steps:
        return Tokens.steps;
      case ProgressionDomain.nutrition:
        return Tokens.calories;
      case ProgressionDomain.sleep:
        return Tokens.sleep;
      case ProgressionDomain.activity:
        return Tokens.active;
      case ProgressionDomain.body:
        return Tokens.weight;
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
    final levelTarget = levelFromAchievementId(achievement.id);
    if (levelTarget != null) return _iconForLevelMilestone(levelTarget);

    switch (achievement.id) {
      case 'first_reward':
        return Icons.emoji_events_rounded;
      case 'reward_hunter_25':
        return Icons.workspace_premium_rounded;
      case 'reward_hunter_100':
        return Icons.shield_moon_rounded;
      case 'xp_100000':
        return Icons.local_fire_department_rounded;
      case 'xp_1000000':
        return Icons.star_rounded;
      case 'steps_total_100k':
        return Icons.directions_walk_rounded;
      case 'steps_total_500k':
      case 'steps_month_300k':
        return Icons.route_rounded;
      case 'steps_total_1000000':
      case 'steps_month_600k':
        return Icons.military_tech_rounded;
      case 'steps_total_5000000':
        return Icons.diamond_rounded;
      case 'steps_total_10000000':
        return Icons.landscape_rounded;
      case 'steps_streak_3':
        return Icons.local_fire_department_rounded;
      case 'steps_streak_7':
        return Icons.bolt_rounded;
      case 'steps_streak_30':
        return Icons.whatshot_rounded;
      case 'steps_streak_100':
        return Icons.link_rounded;
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

  /// Material icon for a level-milestone achievement at [level]. Keyed by
  /// the level number rather than the (mutable) title, so future title
  /// changes don't require touching this map.
  static IconData _iconForLevelMilestone(int level) {
    switch (level) {
      case 5:
        return Icons.hiking_rounded;
      case 10:
        return Icons.explore_rounded;
      case 15:
        return Icons.hardware_rounded;
      case 20:
        return Icons.shield_rounded;
      case 25:
        return Icons.thunderstorm_rounded;
      case 30:
        return Icons.castle_rounded;
      case 40:
        return Icons.local_fire_department_rounded;
      case 50:
        return Icons.sports_rounded;
      case 60:
        return Icons.anchor_rounded;
      case 70:
        return Icons.auto_awesome_rounded;
      case 80:
        return Icons.all_inclusive_rounded;
      case 90:
        return Icons.workspace_premium_rounded;
      case 100:
        return Icons.star_rounded;
      default:
        return Icons.workspace_premium_rounded;
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
