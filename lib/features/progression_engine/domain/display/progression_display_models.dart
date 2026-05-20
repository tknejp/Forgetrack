import 'package:flutter/material.dart'; // lint-ignore: domain-purity — UI display models carry Color tokens for chrome-coherent rendering

import '../../../../l10n/app_localizations.dart';

// Re-export the enums downstream consumers need to read off a NodeDisplay /
// DomainDisplay without importing from the legacy progression module
// directly. When Phase 7 swaps the resolver's backing data source these
// re-exports either stay (the new engine reuses the same enum) or change to
// point at the new module — call sites are unaffected either way.
export '../../../../shared/domain/rarity.dart' show Rarity;
export 'package:forgetrack/domain/progression/catalog/progression_domain.dart' show ProgressionDomain;

import '../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart' show ProgressionDomain;

/// Closure returning a localised string. Same shape as the legacy
/// `ProgressionLocalizedText` typedef; defined here so the display module
/// is the single import path for downstream consumers.
typedef LocalizedText = String Function(AppLocalizations l10n);

/// Coarse classification of a progression node — drives display routing
/// (icon, kicker label, celebration variant) but not behaviour.
enum NodeDisplayKind {
  achievement,
  quest,
  levelMilestone,
  chapterCompletion,
  milestone,
  companionAvailability,
  relic,
  contentUnlock,
}

/// Display payload for one progression node (achievement, quest, milestone,
/// level, …). The resolver returns this; consumers render it.
@immutable
class NodeDisplay {
  const NodeDisplay({
    required this.nodeId,
    required this.kind,
    required this.title,
    required this.description,
    required this.rarity,
    required this.accentColor,
    this.badgeEmoji,
    this.assetKey,
    this.unlockedAt,
    this.domain,
    this.subjectLabel,
    this.targetValue,
    this.currentValue,
  });

  final String nodeId; // lint-ignore: untyped-id — display VO mirrors ProgressionEntryId from resolver output
  final NodeDisplayKind kind;
  final LocalizedText title;
  final LocalizedText description;
  final Rarity rarity;

  /// Drives the tile background gradient + accent stripes. Today
  /// derived from the legacy `Difficulty` enum colour; when the new
  /// engine lands the value is sourced from a `Rarity → Color` token
  /// map (Q5 decision: drop `Difficulty`, keep `Rarity`).
  final Color accentColor;

  final String? badgeEmoji;
  final String? assetKey;
  final DateTime? unlockedAt;

  /// Optional domain hint for icon / accent colour. Read via
  /// [ProgressionDisplayResolver.domainDisplay] for full visuals.
  final ProgressionDomain? domain;

  /// Optional secondary label — typically the rule title for
  /// rule-bound achievements (e.g. "Daily steps") or the domain label
  /// otherwise. Encapsulates the rule-vs-domain branching so consumers
  /// just render `display.subjectLabel?.call(l10n)` as a pill.
  final LocalizedText? subjectLabel;

  final int? targetValue;
  final int? currentValue;
}

/// Display payload for the player's current level — title + emoji + rarity
/// + accent color (used by level badges, accents on hero card, etc.).
@immutable
class LevelDisplay {
  const LevelDisplay({
    required this.level,
    required this.title,
    required this.emoji,
    required this.rarity,
    required this.accentColor,
  });

  final int level;
  final LocalizedText title;
  final String emoji;
  final Rarity rarity;

  /// Drives badge fill / glow / accent stripes. Today derived from the
  /// legacy `tier.difficulty.color`; in the new engine this becomes a
  /// `Rarity → Color` mapping in design tokens. The value is the same
  /// either way for a given level.
  final Color accentColor;
}

/// Display payload for one level tier — what the journey map and the
/// social profile header render. Includes the cosmetic ids so consumers
/// can preview "what you got at this level" without hitting the cosmetics
/// catalog directly.
@immutable
class LevelMilestoneDisplay {
  const LevelMilestoneDisplay({
    required this.level,
    required this.title,
    required this.emoji,
    required this.rarity,
    required this.accentColor,
    required this.cosmeticRewardIds,
    required this.isJourneyMapAnchor,
    required this.isTitleBreakpoint,
  });

  final int level;
  final LocalizedText title;
  final String emoji;
  final Rarity rarity;
  final Color accentColor;
  final List<String> cosmeticRewardIds;
  final bool isJourneyMapAnchor;
  final bool isTitleBreakpoint;
}

/// Display payload for a progression domain (steps, nutrition, sleep, …)
/// — colour, icon, localised label. Consumers render chips, badges, and
/// section headers off this.
@immutable
class DomainDisplay {
  const DomainDisplay({
    required this.domain,
    required this.label,
    required this.color,
    required this.dim,
    required this.icon,
  });

  final ProgressionDomain domain;
  final LocalizedText label;
  final Color color;
  final Color dim;
  final IconData icon;
}