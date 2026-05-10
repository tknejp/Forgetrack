import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../progression/domain/catalog/achievement_catalog.dart';
import '../../../progression/domain/catalog/rule_catalog.dart';
import '../../../progression/domain/policy/level_config.dart';
import '../../../progression/domain/policy/level_policy.dart';
import '../../../progression/domain/progression_models.dart';
import 'progression_display_models.dart';

/// Public, feature-neutral facade over progression catalog and level data.
///
/// Phase 0.5 (current): backed by the legacy progression catalog +
/// `kProgressionLevelTiers`. Phase 7 swaps the backing data source to the
/// new `ProgressionNodeCatalog`; the public method signatures stay
/// unchanged so consumers do not need to be touched again.
///
/// Consumers (social, journey, future feed publishers) should import only
/// this module. They must not reach into `lib/features/progression/...`
/// directly. This is the seam that contains the legacy progression types.
class ProgressionDisplayResolver {
  const ProgressionDisplayResolver();

  static const _levelPolicy = ProgressionLevelPolicy();
  static final _levelIdPattern = RegExp(r'^level_(\d+)$');

  // ── Levels ───────────────────────────────────────────────────────────

  /// Display payload for the player's current level. Always returns a
  /// non-null value; falls back to a synthetic title / common rarity /
  /// accent for levels not in the tier table.
  LevelDisplay levelDisplay(int level) {
    final tier = _tierForLevel(level);
    return LevelDisplay(
      level: level,
      title: tier?.title ?? ((l) => 'Level $level'),
      emoji: tier?.emoji ?? '',
      rarity: tier?.rarity ?? Rarity.common,
      accentColor: _accentForTier(tier),
    );
  }

  /// Every level milestone, in catalog order. Journey map and the social
  /// profile header iterate this.
  Iterable<LevelMilestoneDisplay> levelMilestones() {
    return kProgressionLevelTiers.map(
      (tier) => LevelMilestoneDisplay(
        level: tier.level,
        title: tier.title,
        emoji: tier.emoji,
        rarity: tier.rarity,
        accentColor: _accentForTier(tier),
        cosmeticRewardIds: tier.cosmeticRewards,
        isJourneyMapAnchor: tier.isJourneyMapAnchor,
        isTitleBreakpoint: tier.isTitleBreakpoint,
      ),
    );
  }

  // ── Nodes ────────────────────────────────────────────────────────────

  /// Looks up display metadata for any progression node id.
  ///
  /// Returns:
  /// - Level milestone display for ids matching `level_<N>` (synthesised
  ///   from `kProgressionLevelTiers`).
  /// - Achievement display for ids registered in
  ///   [ProgressionAchievementCatalog].
  /// - `null` for unknown ids — caller decides whether to render an
  ///   "unknown" tile or skip the entry entirely.
  NodeDisplay? nodeDisplay(String nodeId, AppLocalizations l10n) {
    final levelMatch = _levelIdPattern.firstMatch(nodeId);
    if (levelMatch != null) {
      final level = int.parse(levelMatch.group(1)!);
      return _levelMilestoneDisplay(level, nodeId);
    }

    final def = ProgressionAchievementCatalog.definitionForId(nodeId);
    if (def == null) return null;
    return _achievementDisplay(def);
  }

  /// Compact one-line summary for friend cards / leaderboard rows.
  /// Returns `null` for unknown ids; caller falls back to a generic label.
  ///
  /// Locale-aware number formatting (e.g. `10 000` vs `10,000`) goes
  /// through [NumberFormat.compact] so very large targets render as
  /// `10k` / `1M` per the user's locale.
  String? compactSummary(String nodeId, AppLocalizations l10n, String locale) {
    final levelMatch = _levelIdPattern.firstMatch(nodeId);
    if (levelMatch != null) {
      final level = int.parse(levelMatch.group(1)!);
      return l10n.socialLevelLabel(level);
    }

    final def = ProgressionAchievementCatalog.definitionForId(nodeId);
    if (def == null) return null;
    return _achievementCompactSummary(def, l10n, locale);
  }

  // ── Domains ──────────────────────────────────────────────────────────

  /// Display payload (icon, colour, label) for one progression domain.
  DomainDisplay domainDisplay(ProgressionDomain domain) {
    return DomainDisplay(
      domain: domain,
      label: (l) => domain.label(l),
      color: domain.color,
      dim: domain.dim,
      icon: domain.icon,
    );
  }

  /// Parse a serialised domain name (as stored in cloud / Firestore) back
  /// to the enum. Returns `null` for unknown names.
  ProgressionDomain? parseDomain(String? name) {
    if (name == null) return null;
    for (final d in ProgressionDomain.values) {
      if (d.name == name) return d;
    }
    return null;
  }

  // ── Internals ────────────────────────────────────────────────────────

  ProgressionLevelTier? _tierForLevel(int level) {
    for (final t in kProgressionLevelTiers) {
      if (t.level == level) return t;
    }
    return null;
  }

  /// Accent colour for one tier. Today this is `tier.difficulty.color`;
  /// in the new engine the per-rarity colour table will live in design
  /// tokens (one source of truth) and the legacy `Difficulty` enum is
  /// dropped per Q5. For unknown tiers we fall back to the design-token
  /// accent so a freshly-added level still renders in the right ballpark.
  Color _accentForTier(ProgressionLevelTier? tier) =>
      tier?.difficulty.color ?? Tokens.accent;

  NodeDisplay _levelMilestoneDisplay(int level, String nodeId) {
    final tier = _tierForLevel(level);
    return NodeDisplay(
      nodeId: nodeId,
      kind: NodeDisplayKind.levelMilestone,
      title: tier?.title ?? ((l) => 'Level $level'),
      description: (l) => l.progLevelAchievementDesc(level),
      rarity: tier?.rarity ?? Rarity.common,
      accentColor: _accentForTier(tier),
      badgeEmoji: tier?.emoji ?? '',
      targetValue: _levelPolicy.xpRequiredForLevel(level),
    );
  }

  NodeDisplay _achievementDisplay(ProgressionAchievementDefinition def) {
    return NodeDisplay(
      nodeId: def.id,
      kind: NodeDisplayKind.achievement,
      title: def.title,
      description: def.description,
      rarity: def.rarity,
      accentColor: def.difficulty.color,
      badgeEmoji: def.badgeEmoji,
      targetValue: def.targetValue,
      domain: def.domain,
      subjectLabel: _subjectLabelFor(def),
    );
  }

  /// Pill-friendly secondary label — rule title for rule-bound
  /// achievements, domain label otherwise, null when neither applies.
  LocalizedText? _subjectLabelFor(ProgressionAchievementDefinition def) {
    final ruleId = def.ruleId;
    if (ruleId != null) {
      return (l) => ProgressionRuleCatalog.titleForId(ruleId, l);
    }
    final domain = def.domain;
    if (domain != null) {
      return (l) => domain.label(l);
    }
    return null;
  }

  /// Builds a synthetic display for a node id surfaced from cloud data
  /// that is not in the local catalog (renamed, removed, or from a future
  /// build). Caller passes the snapshot strings + rarity / domain hints
  /// that travelled with the cloud record.
  ///
  /// Used by social to render friend feed / profile entries that reference
  /// achievements the local app does not know about, instead of dropping
  /// the entry or crashing.
  NodeDisplay unknownNodeDisplay({
    required String nodeId,
    required String fallbackTitle,
    String fallbackDescription = '',
    String? badgeEmoji,
    Rarity rarity = Rarity.common,
    Color? accentColor,
    DateTime? unlockedAt,
    ProgressionDomain? domain,
  }) {
    return NodeDisplay(
      nodeId: nodeId,
      kind: NodeDisplayKind.achievement,
      title: (_) => fallbackTitle,
      description: (_) => fallbackDescription,
      rarity: rarity,
      accentColor: accentColor ?? Tokens.accent,
      badgeEmoji: badgeEmoji,
      unlockedAt: unlockedAt,
      domain: domain,
    );
  }

  /// "Friendly" display label for a node — uppercase title, with a
  /// special-case for level-milestone ids that show e.g. `LEVEL 25`
  /// instead of the tier title (matches V1 behaviour for friend cards).
  String friendDisplayLabel(NodeDisplay display, AppLocalizations l10n) {
    final levelMatch = _levelIdPattern.firstMatch(display.nodeId);
    if (levelMatch != null) {
      final level = int.parse(levelMatch.group(1)!);
      return l10n.socialLevelLabel(level).toUpperCase();
    }
    return display.title(l10n).toUpperCase();
  }

  String _achievementCompactSummary(
    ProgressionAchievementDefinition def,
    AppLocalizations l10n,
    String locale,
  ) {
    switch (def.criterionType) {
      case ProgressionAchievementCriterionType.totalXpAtLeast:
        return '${_compactInt(def.targetValue, locale)} ${l10n.socialXpLabel}';
      case ProgressionAchievementCriterionType.rewardCountAtLeast:
        if (def.ruleId != null) {
          return '${def.targetValue}x ${ProgressionRuleCatalog.titleForId(def.ruleId!, l10n)}';
        }
        if (def.domain != null) {
          return '${def.targetValue}x ${def.domain!.label(l10n)}';
        }
        return '${def.targetValue} ${l10n.progRewardsSectionLabel}';
      case ProgressionAchievementCriterionType.bestStreakAtLeast:
        return '${def.targetValue} ${l10n.progStreakDaysSuffix}';
      case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
      case ProgressionAchievementCriterionType.bestRollingWindowRuleValueAtLeast:
        return _ruleTargetSummary(def, l10n, locale);
      case ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryDailyQuests}';
      case ProgressionAchievementCriterionType.weeklyQuestsCompletedAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryWeeklyQuests}';
      case ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryTotalQuests}';
      case ProgressionAchievementCriterionType.activeDaysAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryActiveDays}';
      case ProgressionAchievementCriterionType.perfectDaysAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryPerfectDays}';
      case ProgressionAchievementCriterionType.perfectWeeksAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryPerfectWeeks}';
      case ProgressionAchievementCriterionType.comboQuestsCompletedAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryComboQuests}';
      case ProgressionAchievementCriterionType.tripleComboQuestsCompletedAtLeast:
        return '${def.targetValue} ${l10n.progAchievementSummaryTripleComboQuests}';
      case ProgressionAchievementCriterionType.compositeAllOf:
        return l10n.progAchievementSummaryComposite;
    }
  }

  String _ruleTargetSummary(
    ProgressionAchievementDefinition def,
    AppLocalizations l10n,
    String locale,
  ) {
    // Sleep is special-cased: rule values are stored in minutes but the
    // friendly summary shows hours.
    if (def.ruleId == 'daily_sleep') {
      final hours = (def.targetValue / 60).round();
      return '$hours ${l10n.goalUnitHours}';
    }
    final unit = ProgressionRuleCatalog.unitForId(def.ruleId, l10n);
    return '${_compactInt(def.targetValue, locale)} $unit';
  }

  String _compactInt(int value, String locale) =>
      NumberFormat.compact(locale: locale).format(value);
}
