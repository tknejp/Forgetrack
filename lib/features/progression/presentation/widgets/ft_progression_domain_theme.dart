import 'package:flutter/material.dart';

import '../../../../theme/ft_design_tokens.dart';
import '../../domain/progression_models.dart';

/// Maps progression domain ids to visual tokens and Material icons.
///
/// Kept in presentation to avoid leaking design tokens into the domain layer
/// and to give a single place to extend the mapping when new domains land.
class FtProgressionDomainTheme {
  const FtProgressionDomainTheme._();

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
    }
  }

  static Color colorFor(ProgressionDomain domain) => tokenFor(domain).color;

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
        return Icons.explore_rounded;
      case 'forge_knight_xp_5000':
        return Icons.local_fire_department_rounded;
      case 'living_legend_xp_15000':
        return Icons.auto_awesome_rounded;
      case 'steps_total_100k':
        return Icons.directions_walk_rounded;
      case 'steps_total_500k':
        return Icons.route_rounded;
      case 'steps_total_1000000':
        return Icons.military_tech_rounded;
      case 'steps_streak_3':
        return Icons.local_fire_department_rounded;
      case 'steps_streak_7':
        return Icons.bolt_rounded;
      case 'steps_streak_30':
        return Icons.whatshot_rounded;
      case 'nutrition_streak_3':
        return Icons.restaurant_menu_rounded;
      case 'nutrition_rewards_25':
        return Icons.restaurant_rounded;
      case 'weekly_activity_mastery':
        return Icons.fitness_center_rounded;
      case 'weekly_activity_4':
        return Icons.flash_on_rounded;
      case 'weekly_activity_12':
        return Icons.rocket_launch_rounded;
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
