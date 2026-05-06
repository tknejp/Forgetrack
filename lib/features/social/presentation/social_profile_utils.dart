import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widgets/social_user_profile_sheet.dart';

import '../../progression/domain/catalog/achievement_catalog.dart';
import '../../../features/progression/domain/progression_models.dart';
import '../../progression/domain/catalog/rule_catalog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../domain/social_models.dart';

// ── Level / domain helpers ────────────────────────────────────────────────────

Domain socialDomainFor(String? domain) =>
    (progressionDomainFromName(domain) ?? ProgressionDomain.activity).token;

IconData socialIconFor(String? domain) =>
    progressionDomainFromName(domain)?.icon ?? Icons.workspace_premium_rounded;

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
  for (final d in ProgressionAchievementDifficulty.values) {
    if (d.name == diff) return d.color;
  }
  return Tokens.accent;
}

String socialDifficultyLabelForName(String diff, AppLocalizations l10n) =>
    progressionAchievementDifficultyFromName(diff).label(l10n);

// ── Achievement catalog lookup ────────────────────────────────────────────────

// ── Achievement mapping helpers ───────────────────────────────────────────────

List<ProgressionAchievement> mapSocialAchievementsToProgression(
  List<SocialUnlockedAchievement> achievements,
  AppLocalizations l10n,
) {
  final mapped = achievements.map((achievement) {
    final definition = ProgressionAchievementCatalog.definitionForId(
        achievement.achievementId);
    if (definition != null) {
      return ProgressionAchievement(
        id: definition.id,
        type: definition.type,
        difficulty: definition.difficulty,
        criterionType: definition.criterionType,
        title: definition.title,
        description: definition.description,
        badgeEmoji: definition.badgeEmoji,
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
      title: (_) => achievement.title,
      description: (_) => achievement.description,
      badgeEmoji: '\u{1F3C5}',
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
  if (value == null) return null;
  for (final domain in ProgressionDomain.values) {
    if (domain.name == value) return domain;
  }
  return null;
}

ProgressionAchievementDifficulty progressionAchievementDifficultyFromName(
  String? value,
) {
  if (value == null) return ProgressionAchievementDifficulty.easy;
  for (final d in ProgressionAchievementDifficulty.values) {
    if (d.name == value) return d;
  }
  return ProgressionAchievementDifficulty.easy;
}

ProgressionAchievementType progressionAchievementTypeFromName(String? value) {
  if (value == null) return ProgressionAchievementType.milestone;
  for (final t in ProgressionAchievementType.values) {
    if (t.name == value) return t;
  }
  return ProgressionAchievementType.milestone;
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
  return achievement.title(context.l10n).toUpperCase();
}

String friendAchievementDifficultyLabel(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
) =>
    achievement.difficulty.label(l10n);

String friendAchievementCompactSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  String locale,
) {
  switch (achievement.criterionType) {
    case ProgressionAchievementCriterionType.totalXpAtLeast:
      final levelTarget = achievementLevelTargetForId(achievement.id);
      if (levelTarget != null) return l10n.socialLevelLabel(levelTarget);
      return '${_formatCompactInt(achievement.targetValue, locale)} ${l10n.socialXpLabel}';
    case ProgressionAchievementCriterionType.rewardCountAtLeast:
      if (achievement.ruleId != null) {
        return '${achievement.targetValue}x ${ProgressionRuleCatalog.titleForId(achievement.ruleId!, l10n)}';
      }
      if (achievement.domain != null) {
        return '${achievement.targetValue}x ${achievement.domain!.label(l10n)}';
      }
      return '${achievement.targetValue} ${l10n.progRewardsSectionLabel}';
    case ProgressionAchievementCriterionType.bestStreakAtLeast:
      return '${achievement.targetValue} ${l10n.progStreakDaysSuffix}';
    case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
    case ProgressionAchievementCriterionType.bestRollingWindowRuleValueAtLeast:
      return _friendAchievementTargetSummary(achievement, l10n, locale);
    case ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryDailyQuests}';
    case ProgressionAchievementCriterionType.weeklyQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryWeeklyQuests}';
    case ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryTotalQuests}';
    case ProgressionAchievementCriterionType.activeDaysAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryActiveDays}';
    case ProgressionAchievementCriterionType.perfectDaysAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryPerfectDays}';
    case ProgressionAchievementCriterionType.perfectWeeksAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryPerfectWeeks}';
    case ProgressionAchievementCriterionType.comboQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryComboQuests}';
    case ProgressionAchievementCriterionType.tripleComboQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryTripleComboQuests}';
    case ProgressionAchievementCriterionType.compositeAllOf:
      return l10n.progAchievementSummaryComposite;
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
  final unit = ProgressionRuleCatalog.unitForId(achievement.ruleId, l10n);
  return '${_formatCompactInt(achievement.targetValue, locale)} $unit';
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
