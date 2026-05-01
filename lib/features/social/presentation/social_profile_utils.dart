import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widgets/social_user_profile_sheet.dart';

import '../../../features/progression/domain/progression_achievement_catalog.dart';
import '../../../features/progression/domain/progression_models.dart';
import '../../../features/progression/presentation/progression_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../domain/social_models.dart';

// ── Level / domain helpers ────────────────────────────────────────────────────

Domain socialDomainFor(String? domain) {
  switch (domain) {
    case 'steps':
      return Tokens.steps;
    case 'nutrition':
      return Tokens.calories;
    case 'sleep':
      return Tokens.sleep;
    case 'activity':
      return Tokens.active;
    case 'body':
      return Tokens.weight;
    default:
      return Tokens.active;
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

String socialRelativeTime(DateTime t, AppLocalizations l10n) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l10n.socialRelativeNow;
  if (d.inMinutes < 60) return l10n.socialRelativeMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.socialRelativeHoursAgo(d.inHours);
  if (d.inDays == 1) return l10n.socialRelativeYesterday;
  if (d.inDays < 7) return l10n.socialRelativeDaysAgo(d.inDays);
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
      return Tokens.difficultyEasy;
    case 'medium':
      return Tokens.difficultyMedium;
    case 'hard':
      return Tokens.difficultyHard;
    case 'extraHard':
      return Tokens.difficultyExtraHard;
    default:
      return Tokens.accent;
  }
}

String socialDifficultyLabelForName(String diff, AppLocalizations l10n) {
  switch (progressionAchievementDifficultyFromName(diff)) {
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
    return context.l10n.socialLevelLabel(levelTarget).toUpperCase();
  }
  return ProgressionL10n(context.l10n)
      .achievementTitle(achievement)
      .toUpperCase();
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
      if (levelTarget != null) return l10n.socialLevelLabel(levelTarget);
      return '${_formatCompactInt(achievement.targetValue, locale)} ${l10n.socialXpLabel}';
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
    return '$hours ${l10n.goalUnitHours}';
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
