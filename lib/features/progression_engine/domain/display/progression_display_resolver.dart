import 'package:flutter/material.dart' show Color; // lint-ignore: domain-purity — Color is the chrome-token type for display VOs
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../catalog/content/daily_rule_display.dart';
import '../catalog/level_milestone_specs.dart';
import '../catalog/objective_catalog.dart';
import '../catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import '../policy/level_policy.dart';
import 'progression_display_models.dart';

/// Public, feature-neutral facade over the V2 progression catalog and
/// level data.
///
/// Phase 9a (current): fully V2-backed. Reads [ProgressionEntryCatalog]
/// + [ObjectiveCatalog] for node displays, [kLevelMilestones] for level
/// metadata, [DailyRuleDisplay] for rule-bound subject labels and unit
/// suffixes.
///
/// Consumers (social, journey, hero, future feed publishers) should
/// import only this module.
class ProgressionDisplayResolver {
  const ProgressionDisplayResolver();

  static const _levelPolicy = ProgressionLevelPolicy();
  static final _levelIdPattern = RegExp(r'^level_(\d+)$');

  // ── Levels ───────────────────────────────────────────────────────────

  /// Display payload for the player's current level. Always returns a
  /// non-null value; for levels that are not themselves a milestone in
  /// [kLevelMilestones] (e.g. 2, 3, 4, 6, 7, …) we surface the *governing*
  /// spec — the highest milestone whose level is ≤ [level]. That keeps the
  /// player wearing the previous breakpoint's title + rarity colour until
  /// the next breakpoint fires, instead of falling back to a generic
  /// "Level N" label and the default accent.
  LevelDisplay levelDisplay(int level) {
    final spec = levelMilestoneAtOrBelow(level);
    return LevelDisplay(
      level: level,
      title: spec.titleKey,
      emoji: spec.emoji,
      rarity: spec.rarity,
      accentColor: _accentForRarity(spec.rarity),
    );
  }

  /// Every reward-bearing level milestone, in catalog order. Journey
  /// map and the social profile header iterate this.
  ///
  /// `isJourneyMapAnchor` mirrors [LevelMilestoneSpec.isTitleBreakpoint]
  /// — journey-display feature owns the actual map-anchor set in
  /// [lib/features/journey/domain/journey_levels.dart]; consumers that
  /// need the visual map spine should read `kJourneyMapAnchors`
  /// directly. The flag stays on the display model for backwards-
  /// compatible API and pre-tested social paths.
  Iterable<LevelMilestoneDisplay> levelMilestones() {
    return kLevelMilestones.map(
      (spec) => LevelMilestoneDisplay(
        level: spec.level,
        title: spec.titleKey,
        emoji: spec.emoji,
        rarity: spec.rarity,
        accentColor: _accentForRarity(spec.rarity),
        cosmeticRewardIds: spec.cosmeticRewardIds,
        isJourneyMapAnchor: spec.isTitleBreakpoint,
        isTitleBreakpoint: spec.isTitleBreakpoint,
      ),
    );
  }

  // ── Nodes ────────────────────────────────────────────────────────────

  /// Looks up display metadata for any V2 progression node id.
  ///
  /// Returns:
  /// - Level milestone display for ids matching `level_<N>` (resolved
  ///   from [ProgressionEntryCatalog] or synthesised from the tier table
  ///   for ids the catalog hasn't materialised, e.g. level 1 origin).
  /// - Achievement display for ids registered as [Achievement] in
  ///   [ProgressionEntryCatalog].
  /// - Milestone / chapter completion / content unlock displays for the
  ///   corresponding V2 node kinds.
  /// - `null` for unknown ids — caller decides whether to render an
  ///   "unknown" tile or skip the entry entirely.
  NodeDisplay? nodeDisplay(String nodeId, AppLocalizations l10n) {
    final levelMatch = _levelIdPattern.firstMatch(nodeId);
    if (levelMatch != null) {
      final level = int.parse(levelMatch.group(1)!);
      return _levelMilestoneDisplay(level, nodeId);
    }

    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node == null) return null;
    return _displayForNode(node);
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

    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node == null) return null;
    return _compactSummaryForNode(node, l10n, locale);
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

  /// Accent colour for a rarity. Drops V1's `Difficulty → Color` mapping
  /// per Q5; the per-rarity colour table lives in design tokens. Unknown
  /// rarities (null) fall back to the design-token accent.
  Color _accentForRarity(Rarity? rarity) =>
      rarity == null ? Tokens.accent : RarityPalette.forRarity(rarity).color;

  NodeDisplay _levelMilestoneDisplay(int level, String nodeId) {
    final spec = levelMilestoneByLevel(level);
    return NodeDisplay(
      nodeId: nodeId,
      kind: NodeDisplayKind.levelMilestone,
      title: spec?.titleKey ?? ((l) => 'Level $level'),
      description: (l) => l.progLevelAchievementDesc(level),
      rarity: spec?.rarity ?? Rarity.common,
      accentColor: _accentForRarity(spec?.rarity),
      badgeEmoji: spec?.emoji ?? '',
      targetValue: _levelPolicy.xpRequiredForLevel(level),
    );
  }

  NodeDisplay _displayForNode(ProgressionEntry node) {
    return switch (node) {
      LevelMilestone() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.levelMilestone,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
          badgeEmoji: node.emoji,
          targetValue: _levelPolicy.xpRequiredForLevel(node.level),
        ),
      Achievement() => _achievementDisplay(node),
      Milestone() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.milestone,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
          domain: _objectiveDomain(node.objectiveId),
          targetValue: _objectiveTargetInt(node.objectiveId),
        ),
      ChapterCompletion() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.chapterCompletion,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
        ),
      ContentUnlock() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.contentUnlock,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
        ),
      CompanionAvailability() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.companionAvailability,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
        ),
      Relic() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.relic,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
        ),
      Quest() => NodeDisplay(
          nodeId: node.id,
          kind: NodeDisplayKind.quest,
          title: node.titleKey,
          description: node.descriptionKey,
          rarity: node.rarity,
          accentColor: _accentForRarity(node.rarity),
          domain: _objectiveDomain(node.objectiveId),
          assetKey: node.assetKey,
          targetValue: _objectiveTargetInt(node.objectiveId),
          subjectLabel: _subjectLabelForObjective(node.objectiveId),
        ),
    };
  }

  NodeDisplay _achievementDisplay(Achievement node) {
    return NodeDisplay(
      nodeId: node.id,
      kind: NodeDisplayKind.achievement,
      title: node.titleKey,
      description: node.descriptionKey,
      rarity: node.rarity,
      accentColor: _accentForRarity(node.rarity),
      badgeEmoji: node.badgeEmoji,
      assetKey: node.assetKey,
      domain: _objectiveDomain(node.objectiveId),
      subjectLabel: _subjectLabelForObjective(node.objectiveId),
      targetValue: _objectiveTargetInt(node.objectiveId),
    );
  }

  Objective? _objectiveById(String? id) {
    if (id == null) return null;
    return ObjectiveCatalog.definitionForId(id);
  }

  ProgressionDomain? _objectiveDomain(String? objectiveId) =>
      _objectiveById(objectiveId)?.domain;

  int? _objectiveTargetInt(String? objectiveId) {
    final value = _objectiveById(objectiveId)?.targetValue;
    if (value == null) return null;
    return value.isFinite ? value.toInt() : null;
  }

  /// Pill-friendly secondary label for an objective — rule title for
  /// rule-bound `RewardCountMetric` / `StreakDaysMetric`, domain label
  /// otherwise, null when neither applies.
  LocalizedText? _subjectLabelForObjective(String? objectiveId) {
    final objective = _objectiveById(objectiveId);
    if (objective == null) return null;
    final metric = objective.metric;
    final ruleId = switch (metric) {
      RewardCountMetric() => metric.ruleId,
      StreakDaysMetric() => metric.ruleId,
      _ => null,
    };
    if (ruleId != null) {
      final ruleTitle = DailyRuleDisplay.titleFor(ruleId);
      if (ruleTitle != null) return ruleTitle;
    }
    final domain = objective.domain;
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
      accentColor: accentColor ?? _accentForRarity(rarity),
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

  String? _compactSummaryForNode(
    ProgressionEntry node,
    AppLocalizations l10n,
    String locale,
  ) {
    // Composite achievements (multiple unlock-condition gates) — V2
    // models these via [unlockConditions] rather than the V1
    // `compositeAllOf` criterion. Render the same generic label so the
    // social card copy stays stable.
    if (node is Achievement && node.unlockConditions.length > 1) {
      return l10n.progAchievementSummaryComposite;
    }

    final objectiveId = _objectiveIdOf(node);
    if (objectiveId == null) {
      // Reward-bearing nodes without an objective (e.g. condition-only
      // welcomes, level milestones that already short-circuited above).
      // Title makes the most sensible fallback.
      return node.titleKey(l10n);
    }

    final objective = _objectiveById(objectiveId);
    if (objective == null) return node.titleKey(l10n);
    return _compactSummaryForObjective(objective, l10n, locale);
  }

  String? _objectiveIdOf(ProgressionEntry node) {
    return switch (node) {
      Achievement() => node.objectiveId,
      Quest() => node.objectiveId,
      Milestone() => node.objectiveId,
      _ => null,
    };
  }

  /// V2 metric-driven compact summary. Mirrors the V1 criterion switch
  /// shape so friend cards keep their label format (e.g. "10k XP",
  /// "30 steps streak", "5 daily quests").
  String _compactSummaryForObjective(
    Objective objective,
    AppLocalizations l10n,
    String locale,
  ) {
    final target = objective.targetValue.toInt();
    final metric = objective.metric;
    return switch (metric) {
      TotalXpMetric() =>
        '${_compactInt(target, locale)} ${l10n.socialXpLabel}',
      RewardCountMetric(:final ruleId, :final domain) => () {
          if (ruleId != null) {
            final ruleTitle = DailyRuleDisplay.titleFor(ruleId);
            if (ruleTitle != null) {
              return '${target}x ${ruleTitle(l10n)}';
            }
          }
          if (domain != null) {
            final parsed = parseDomain(domain);
            if (parsed != null) {
              return '${target}x ${parsed.label(l10n)}';
            }
          }
          return '$target ${l10n.progRewardsSectionLabel}';
        }(),
      StreakDaysMetric() =>
        '$target ${l10n.progStreakDaysSuffix}',
      StepsMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_steps',
        ),
      CaloriesMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_calories',
        ),
      ProteinGramsMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_protein',
        ),
      CarbsGramsMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_carbs',
        ),
      FatGramsMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_fat',
        ),
      FiberGramsMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_fiber',
        ),
      SleepMinutesMetric() => _sleepSummary(target, l10n),
      SleepStartHourCountMetric() =>
        '$target ${l10n.progAchievementSummaryNights}',
      ActivityMinutesMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'weekly_activity',
        ),
      WeightLoggedTodayMetric() => _ruleScaledSummary(
          objective: objective,
          targetValue: target,
          l10n: l10n,
          locale: locale,
          ruleHintId: 'daily_weight_log',
        ),
      NodeCompletionsMetric() => _nodeCompletionsSummary(
          metric: metric,
          target: target,
          l10n: l10n,
        ),
      ComboPoolCompletionsMetric() =>
        '$target ${l10n.progAchievementSummaryComboQuests}',
      QuestCompletionsByBucketMetric(:final bucket) => switch (bucket) {
        QuestDisplayBucket.daily =>
          '$target ${l10n.progAchievementSummaryDailyQuests}',
        QuestDisplayBucket.weekly =>
          '$target ${l10n.progAchievementSummaryWeeklyQuests}',
        _ => '$target ${l10n.progAchievementSummaryTotalQuests}',
      },
      DistinctActiveDaysMetric() =>
        '$target ${l10n.progAchievementSummaryActiveDays}',
      TodayCompletionsAmongMetric(:final nodeIds) =>
        '$target/${nodeIds.length} ${l10n.progAchievementSummaryDailyQuests}',
      LifetimeCompletionsAmongMetric() =>
        '$target ${l10n.progAchievementSummaryTripleComboQuests}',
      DaysWithAtLeastKAmongMetric() =>
        '$target ${l10n.progAchievementSummaryActiveDays}',
      LevelMetric() => l10n.socialLevelLabel(target),
    };
  }

  String _ruleScaledSummary({
    required Objective objective,
    required int targetValue,
    required AppLocalizations l10n,
    required String locale,
    required String ruleHintId,
  }) {
    final unit = DailyRuleDisplay.unitFor(ruleHintId)?.call(l10n);
    if (unit == null || unit.isEmpty) return _compactInt(targetValue, locale);
    return '${_compactInt(targetValue, locale)} $unit';
  }

  String _sleepSummary(int targetMinutes, AppLocalizations l10n) {
    final hours = (targetMinutes / 60).round();
    return '$hours ${l10n.goalUnitHours}';
  }

  String _nodeCompletionsSummary({
    required NodeCompletionsMetric metric,
    required int target,
    required AppLocalizations l10n,
  }) {
    final referenced = ProgressionEntryCatalog.definitionForId(metric.nodeId);
    if (referenced is Quest) {
      switch (referenced.displayBucket) {
        case _:
          // Display bucket → friend summary label.
        }
      // Note: switch above is intentionally exhaustive in the next block
      // to give a labelled summary per quest bucket.
      return switch (referenced.displayBucket.name) {
        'daily' => '$target ${l10n.progAchievementSummaryDailyQuests}',
        'weekly' => '$target ${l10n.progAchievementSummaryWeeklyQuests}',
        _ => '$target ${l10n.progAchievementSummaryTotalQuests}',
      };
    }
    return '$target ${l10n.progAchievementSummaryTotalQuests}';
  }

  String _compactInt(int value, String locale) =>
      NumberFormat.compact(locale: locale).format(value);
}