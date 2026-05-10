import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/rarity.dart';
import '../../../../shared/theme/design_tokens.dart';
import 'core_models.dart';

export '../../../../shared/domain/rarity.dart' show Rarity;

enum ProgressionAchievementType {
  milestone,
  streak,
  mastery,
}

/// Visual + localized metadata for each achievement difficulty band.
///
/// Carrying this on the enum eliminates the parallel switch tables that used
/// to live in `ProgressionDomainTheme.colorForAchievementDifficulty`,
/// `progressionLevelAccent`, `achievementBadgeSpec`,
/// `friendAchievementDifficultyLabel`, `socialDifficultyLabelForName` and
/// `colorForDifficultyString`. Callers read `difficulty.color` and
/// `difficulty.label(l10n)` directly.
enum ProgressionAchievementDifficulty {
  easy(color: Tokens.difficultyEasy, label: _difficultyEasyLabel),
  medium(color: Tokens.difficultyMedium, label: _difficultyMediumLabel),
  hard(color: Tokens.difficultyHard, label: _difficultyHardLabel),
  extraHard(color: Tokens.difficultyExtraHard, label: _difficultyExtraHardLabel),
  mythic(color: Tokens.difficultyMythic, label: _difficultyMythicLabel);

  const ProgressionAchievementDifficulty({
    required this.color,
    required ProgressionLocalizedText label,
  }) : _label = label;

  /// Color associated with this difficulty band.
  final Color color;

  final ProgressionLocalizedText _label;

  /// Localised display label.
  String label(AppLocalizations l10n) => _label(l10n);
}

String _difficultyEasyLabel(AppLocalizations l10n) =>
    l10n.progAchievementDifficultyEasy;
String _difficultyMediumLabel(AppLocalizations l10n) =>
    l10n.progAchievementDifficultyMedium;
String _difficultyHardLabel(AppLocalizations l10n) =>
    l10n.progAchievementDifficultyHard;
String _difficultyExtraHardLabel(AppLocalizations l10n) =>
    l10n.progAchievementDifficultyExtraHard;
String _difficultyMythicLabel(AppLocalizations l10n) =>
    l10n.progAchievementDifficultyMythic;

enum ProgressionAchievementCriterionType {
  totalXpAtLeast,
  rewardCountAtLeast,
  bestStreakAtLeast,
  totalRuleValueAtLeast,
  bestRollingWindowRuleValueAtLeast,
  // Phase 3a additions — counted from the questRewardGrants ledger via the
  // questCategoryById index passed to the achievement evaluator.
  dailyQuestsCompletedAtLeast,
  weeklyQuestsCompletedAtLeast,
  totalQuestsCompletedAtLeast,
  // Distinct days with at least one progression evaluation period — counted
  // from the evaluations list, mirrors CosmeticUnlockSnapshotExtractor.
  activeDaysAtLeast,
  // Phase 3b additions — delegate to the shared PerfectPeriodEvaluator so
  // achievement counts and cosmetic snapshot counts can never disagree.
  perfectDaysAtLeast,
  perfectWeeksAtLeast,
  // Phase 3c additions — combo quest completions, counted from the
  // questRewardGrants ledger filtered against the hard-coded combo and
  // triple-combo quest id sets in the achievement evaluator.
  comboQuestsCompletedAtLeast,
  tripleComboQuestsCompletedAtLeast,
  // Phase 3d addition — composite (AND) over a list of
  // ProgressionAchievementCompositeCondition. The achievement's own
  // targetValue is conventionally 1; current value is 1 iff every
  // sub-condition is met, else 0.
  compositeAllOf,
}

class ProgressionAchievementDefinition {
  const ProgressionAchievementDefinition({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.rarity,
    required this.criterionType,
    required this.title,
    required this.description,
    this.badgeEmoji = '\u{1F3C5}',
    required this.targetValue,
    this.cosmeticRewards = const [],
    this.ruleId,
    this.domain,
    this.windowSizeDays,
    this.relatedRuleIds = const [],
    this.difficultyScore,
    this.compositeConditions,
  });

  final String id;
  final ProgressionAchievementType type;
  final ProgressionAchievementDifficulty difficulty;

  /// Rarity of the unlock moment. Distinct from [difficulty] (which is the
  /// "Lehké/Těžké" badge label/colour shown on the achievement card) — the
  /// celebration system uses [rarity] to drive its accent and aura.
  /// Authored on the catalog entry; the celebration adapter reads it
  /// directly with no translation.
  final Rarity rarity;
  final ProgressionAchievementCriterionType criterionType;
  final ProgressionLocalizedText title;
  final ProgressionLocalizedText description;
  final String badgeEmoji;
  final int targetValue;

  /// Cosmetic ids granted when this achievement unlocks. Replaces the
  /// previous side-table mapping; one source of truth per achievement.
  final List<String> cosmeticRewards;
  final String? ruleId;
  final ProgressionDomain? domain;
  final int? windowSizeDays;
  final List<String> relatedRuleIds;

  /// Fine-grained difficulty (1.0–10.0) used for balancing, debug tooling,
  /// and future UI ordering. The coarse [difficulty] enum stays as the
  /// authoritative bucket; this is an additional dimension and may be null
  /// for legacy entries that have not been scored yet.
  final double? difficultyScore;

  /// Sub-conditions for [ProgressionAchievementCriterionType.compositeAllOf].
  /// All conditions must be met (AND) for the achievement to unlock.
  /// Conventionally [targetValue] is `1` for composite achievements; the
  /// evaluator returns `1` iff every entry's `targetValue` is satisfied,
  /// else `0`.
  final List<ProgressionAchievementCompositeCondition>? compositeConditions;

  String get unlockKey => 'achievement|$id';
}

/// One leg of a [ProgressionAchievementCriterionType.compositeAllOf]
/// achievement. The evaluator computes the metric implied by [type] (with
/// [ruleId]/[domain] filters where applicable) and checks
/// `value >= targetValue`.
///
/// Nesting composites is not allowed — `type == compositeAllOf` is rejected
/// by the evaluator.
class ProgressionAchievementCompositeCondition {
  const ProgressionAchievementCompositeCondition({
    required this.type,
    required this.targetValue,
    this.ruleId,
    this.domain,
  });

  final ProgressionAchievementCriterionType type;
  final int targetValue;
  final String? ruleId;
  final ProgressionDomain? domain;
}

class ProgressionAchievement {
  const ProgressionAchievement({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.rarity,
    required this.criterionType,
    required this.title,
    required this.description,
    this.badgeEmoji = '\u{1F3C5}',
    required this.targetValue,
    required this.currentValue,
    required this.progress,
    required this.unlocked,
    this.cosmeticRewards = const [],
    this.unlockedAt,
    this.ruleId,
    this.domain,
    this.relatedRuleIds = const [],
  });

  final String id;
  final ProgressionAchievementType type;
  final ProgressionAchievementDifficulty difficulty;

  /// Mirrored from [ProgressionAchievementDefinition.rarity].
  final Rarity rarity;
  final ProgressionAchievementCriterionType criterionType;
  final ProgressionLocalizedText title;
  final ProgressionLocalizedText description;
  final String badgeEmoji;
  final int targetValue;
  final int currentValue;
  final double progress;
  final bool unlocked;
  final DateTime? unlockedAt;
  final String? ruleId;
  final ProgressionDomain? domain;
  final List<String> relatedRuleIds;

  /// Mirrored from [ProgressionAchievementDefinition.cosmeticRewards].
  final List<String> cosmeticRewards;
}

class ProgressionAchievementUnlockEvent {
  const ProgressionAchievementUnlockEvent({
    required this.unlockKey,
    required this.achievementId,
    required this.unlockedAt,
  });

  final String unlockKey;
  final String achievementId;
  final DateTime unlockedAt;
}
