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
