import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widgets/social_user_profile_sheet.dart';

import '../../../features/progression/domain/progression_achievement_catalog.dart';
import '../../../features/progression/domain/progression_models.dart';
import '../../../features/progression/presentation/progression_l10n.dart';
import '../../../features/progression/presentation/widgets/ft_progression_domain_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../domain/social_models.dart';

// ── Level / domain helpers ────────────────────────────────────────────────────

FtDomain socialDomainFor(String? domain) {
  switch (domain) {
    case 'steps':
      return FtTokens.steps;
    case 'nutrition':
      return FtTokens.calories;
    case 'sleep':
      return FtTokens.sleep;
    case 'activity':
      return FtTokens.active;
    case 'body':
      return FtTokens.weight;
    default:
      return FtTokens.active;
  }
}

IconData socialIconFor(String? domain) {
  switch (domain) {
    case 'steps':
      return Icons.directions_walk_rounded;
    case 'nutrition':
      return Icons.restaurant_rounded;
    case 'sleep':
      return Icons.nightlight_round;
    case 'activity':
      return Icons.bolt_rounded;
    case 'body':
      return Icons.monitor_weight_outlined;
    default:
      return Icons.workspace_premium_rounded;
  }
}

String socialRelativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'právě teď';
  if (d.inMinutes < 60) return 'před ${d.inMinutes} min';
  if (d.inHours < 24) return 'před ${d.inHours} hod';
  if (d.inDays == 1) return 'včera';
  if (d.inDays < 7) return 'před ${d.inDays} dny';
  return DateFormat('d. M.').format(t);
}

String socialFmtXp(int xp) {
  if (xp >= 100000) return '${(xp / 1000).round()}k';
  if (xp >= 10000) return '${(xp / 1000).toStringAsFixed(1)}k';
  return NumberFormat('#,##0').format(xp);
}

Color colorForDifficultyString(String diff) {
  switch (diff) {
    case 'easy':
      return FtProgressionDomainTheme.achievementEasy;
    case 'medium':
      return FtProgressionDomainTheme.achievementMedium;
    case 'hard':
      return FtProgressionDomainTheme.achievementHard;
    case 'extraHard':
      return FtProgressionDomainTheme.achievementExtraHard;
    default:
      return FtTokens.accent;
  }
}

// ── Achievement catalog lookup ────────────────────────────────────────────────

final Map<String, ProgressionAchievementDefinition>
    progressionAchievementDefinitionsById = {
  for (final definition in const ProgressionAchievementCatalog().build())
    definition.id: definition,
};

// ── Achievement mapping helpers ───────────────────────────────────────────────

List<ProgressionAchievement> mapSocialAchievementsToProgression(
  List<SocialUnlockedAchievement> achievements,
) {
  final mapped = achievements.map((achievement) {
    final definition =
        progressionAchievementDefinitionsById[achievement.achievementId];
    if (definition != null) {
      return ProgressionAchievement(
        id: definition.id,
        type: definition.type,
        difficulty: definition.difficulty,
        criterionType: definition.criterionType,
        title: definition.title,
        description: definition.description,
        targetValue: definition.targetValue,
        currentValue: definition.targetValue,
        progress: 1,
        unlocked: true,
        unlockedAt: achievement.unlockedAt,
        ruleId: definition.ruleId ?? achievement.ruleId,
        domain:
            definition.domain ?? progressionDomainFromName(achievement.domain),
        relatedRuleIds: definition.relatedRuleIds,
      );
    }

    final fallbackDifficulty =
        progressionAchievementDifficultyFromName(achievement.difficulty);

    return ProgressionAchievement(
      id: achievement.achievementId,
      type: progressionAchievementTypeFromName(achievement.type),
      difficulty: fallbackDifficulty,
      criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
      title: achievement.title,
      description: achievement.description,
      targetValue: 1,
      currentValue: 1,
      progress: 1,
      unlocked: true,
      unlockedAt: achievement.unlockedAt,
      ruleId: achievement.ruleId,
      domain: progressionDomainFromName(achievement.domain),
    );
  }).toList(growable: false);

  mapped.sort((a, b) {
    final unlockedCompare =
        (b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (unlockedCompare != 0) return unlockedCompare;
    return a.id.compareTo(b.id);
  });
  return mapped;
}

ProgressionDomain? progressionDomainFromName(String? value) {
  switch (value) {
    case 'steps':
      return ProgressionDomain.steps;
    case 'nutrition':
      return ProgressionDomain.nutrition;
    case 'sleep':
      return ProgressionDomain.sleep;
    case 'activity':
      return ProgressionDomain.activity;
    case 'body':
      return ProgressionDomain.body;
    default:
      return null;
  }
}

ProgressionAchievementDifficulty progressionAchievementDifficultyFromName(
  String? value,
) {
  switch (value) {
    case 'easy':
      return ProgressionAchievementDifficulty.easy;
    case 'medium':
      return ProgressionAchievementDifficulty.medium;
    case 'hard':
      return ProgressionAchievementDifficulty.hard;
    case 'extraHard':
      return ProgressionAchievementDifficulty.extraHard;
    default:
      return ProgressionAchievementDifficulty.easy;
  }
}

ProgressionAchievementType progressionAchievementTypeFromName(String? value) {
  switch (value) {
    case 'streak':
      return ProgressionAchievementType.streak;
    case 'mastery':
      return ProgressionAchievementType.mastery;
    case 'milestone':
    default:
      return ProgressionAchievementType.milestone;
  }
}

// ── Achievement display helpers ───────────────────────────────────────────────

String friendAchievementDisplayLabel(
  ProgressionAchievement achievement,
  BuildContext context,
) {
  final levelTarget = achievementLevelTargetForId(achievement.id);
  if (levelTarget != null) {
    return 'LEVEL $levelTarget';
  }
  switch (achievement.id) {
    case 'first_reward':
      return 'FIRST REWARD';
    case 'reward_hunter_25':
      return '25 REWARDS';
    case 'reward_hunter_100':
      return '100 REWARDS';
    case 'xp_100000':
      return '100K XP';
    case 'xp_1000000':
      return '1M XP';
    case 'steps_total_100k':
      return '100K STEPS';
    case 'steps_total_500k':
      return '500K STEPS';
    case 'steps_total_1000000':
      return '1M STEPS';
    case 'steps_total_5000000':
      return '5M STEPS';
    case 'steps_total_10000000':
      return '10M STEPS';
    case 'steps_month_300k':
      return '30D 300K';
    case 'steps_month_600k':
      return '30D 600K';
    case 'steps_streak_3':
      return '3 DAY STREAK';
    case 'steps_streak_7':
      return '7 DAY STREAK';
    case 'steps_streak_30':
      return '30 DAY STREAK';
    case 'steps_streak_100':
      return '100 DAY STREAK';
    case 'nutrition_streak_3':
      return '3 DAY RHYTHM';
    case 'nutrition_streak_30':
      return '30 DAY RHYTHM';
    case 'nutrition_streak_100':
      return '100 DAY RHYTHM';
    case 'nutrition_rewards_25':
      return '25 NUTRITION';
    case 'weekly_activity_mastery':
      return 'WEEKLY WIN';
    case 'weekly_activity_4':
      return '4 ACTIVITY';
    case 'weekly_activity_12':
      return '12 ACTIVITY';
    case 'weekly_activity_24':
      return '24 ACTIVITY';
    case 'weekly_activity_52':
      return '52 ACTIVITY';
    case 'sleep_total_250h':
      return '250H SLEEP';
    case 'sleep_total_1000h':
      return '1000H SLEEP';
    case 'sleep_month_225h':
      return '30D 225H';
    case 'sleep_month_240h':
      return '30D 240H';
    default:
      return ProgressionL10n(context.l10n)
          .achievementTitle(achievement)
          .toUpperCase();
  }
}

String friendAchievementDifficultyLabel(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
) {
  switch (achievement.difficulty) {
    case ProgressionAchievementDifficulty.easy:
      return l10n.progAchievementDifficultyEasy;
    case ProgressionAchievementDifficulty.medium:
      return l10n.progAchievementDifficultyMedium;
    case ProgressionAchievementDifficulty.hard:
      return l10n.progAchievementDifficultyHard;
    case ProgressionAchievementDifficulty.extraHard:
      return l10n.progAchievementDifficultyExtraHard;
  }
}

String friendAchievementCompactSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  ProgressionL10n progL10n,
  String locale,
) {
  switch (achievement.criterionType) {
    case ProgressionAchievementCriterionType.totalXpAtLeast:
      final levelTarget = achievementLevelTargetForId(achievement.id);
      if (levelTarget != null) return 'Level $levelTarget';
      return '${_formatCompactInt(achievement.targetValue, locale)} XP';
    case ProgressionAchievementCriterionType.rewardCountAtLeast:
      if (achievement.ruleId != null) {
        return '${achievement.targetValue}x ${progL10n.ruleTitle(achievement.ruleId!)}';
      }
      if (achievement.domain != null) {
        return '${achievement.targetValue}x ${progL10n.domainLabel(achievement.domain!)}';
      }
      return '${achievement.targetValue} ${l10n.progRewardsSectionLabel}';
    case ProgressionAchievementCriterionType.bestStreakAtLeast:
      return '${achievement.targetValue} ${l10n.progStreakDaysSuffix}';
    case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
    case ProgressionAchievementCriterionType.bestRollingWindowRuleValueAtLeast:
      return _friendAchievementTargetSummary(achievement, l10n, locale);
  }
}

String _friendAchievementTargetSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  String locale,
) {
  if (achievement.ruleId == 'daily_sleep') {
    final hours = (achievement.targetValue / 60).round();
    return '$hours h';
  }
  final unit = _friendAchievementUnitForRule(achievement.ruleId, l10n);
  return '${_formatCompactInt(achievement.targetValue, locale)} $unit';
}

String _friendAchievementUnitForRule(String? ruleId, AppLocalizations l10n) {
  switch (ruleId) {
    case 'daily_steps':
      return l10n.goalUnitSteps;
    case 'daily_calories':
      return l10n.goalUnitKcal;
    case 'daily_protein':
      return l10n.goalUnitG;
    case 'daily_sleep':
      return l10n.goalUnitHours;
    case 'weekly_activity':
      return l10n.goalUnitMins;
    default:
      return '';
  }
}

String formatAchievementDateTime(DateTime value, String locale) {
  return DateFormat('d MMM, HH:mm', locale).format(value);
}

int? achievementLevelTargetForId(String id) {
  final match = RegExp(r'_level_(\d+)$').firstMatch(id);
  return match == null ? null : int.tryParse(match.group(1)!);
}

String _formatCompactInt(int value, String locale) {
  return NumberFormat.compact(locale: locale).format(value);
}

// ── Navigation ────────────────────────────────────────────────────────────────

void openUserProfile(
  BuildContext context, {
  required String uid,
  String? initialDisplayName,
  String? initialPhotoUrl,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SocialUserProfileSheet(
      uid: uid,
      initialDisplayName: initialDisplayName,
      initialPhotoUrl: initialPhotoUrl,
    ),
  );
}
