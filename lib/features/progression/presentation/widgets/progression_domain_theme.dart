import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../domain/progression_models.dart';
import '../../domain/catalog/rule_catalog.dart';

class ProgressionDomainTheme {
  const ProgressionDomainTheme._();

  static const Color achievementEasy = Tokens.difficultyEasy;
  static const Color achievementMedium = Tokens.difficultyMedium;
  static const Color achievementHard = Tokens.difficultyHard;
  static const Color achievementExtraHard = Tokens.difficultyExtraHard;
  static const Color achievementMythic = Tokens.difficultyMythic;

  static Domain tokenFor(ProgressionDomain domain) => domain.token;

  static Color colorFor(ProgressionDomain domain) => domain.color;

  static Color colorForAchievementDifficulty(
    ProgressionAchievementDifficulty difficulty,
  ) =>
      difficulty.color;

  static IconData iconFor(ProgressionDomain domain) => domain.icon;

  static ProgressionDomain? domainForRuleId(String? ruleId) {
    if (ruleId == null) return null;
    return ProgressionRuleCatalog.displayDefinitionForId(ruleId)?.domain;
  }

  static ProgressionDomain resolveForQuest(ProgressionQuest quest) {
    return quest.visualDomain ??
        quest.domain ??
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
