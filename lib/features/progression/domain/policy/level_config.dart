import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../progression_models.dart';

export '../../../../shared/domain/rarity.dart' show Rarity;

// ─────────────────────────────────────────────────────────────────────────────
// Single source of truth for progression level metadata.
//
// Each [ProgressionLevelTier] describes one level breakpoint: the level number,
// the stable achievement id used for persistence, the milestone emoji, the
// difficulty band of the matching level achievement, journey-map flags, and a
// localized [title] closure that resolves to the user's current language.
//
// Achievement IDs follow the pattern `level_<N>` (e.g. `level_5`, `level_100`).
// IDs are decoupled from titles intentionally — titles can change in the
// future without invalidating Firestore / Isar records.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ProgressionLevelTier {
  const ProgressionLevelTier({
    required this.level,
    required this.achievementId,
    required this.emoji,
    required this.difficulty,
    required this.rarity,
    required this.isJourneyMapAnchor,
    required this.isTitleBreakpoint,
    required this.title,
    this.cosmeticRewards = const [],
  });

  /// The level at which this tier is reached.
  final int level;

  /// Stable opaque id used to persist the matching level-milestone achievement
  /// in Firestore (`achievementUnlocks/{id}`) and Isar
  /// (`ProgressionAchievementUnlockRecord.achievementId`).
  ///
  /// Always of the form `level_<N>` — the regex parsers in
  /// [levelFromAchievementId] depend on this convention.
  final String achievementId;

  /// Milestone emoji shown on the journey map and on the matching level
  /// achievement badge.
  final String emoji;

  /// Difficulty band of the matching level achievement. Used by
  /// `ProgressionAchievementCatalog` when generating the achievement
  /// definition list.
  final ProgressionAchievementDifficulty difficulty;

  /// Rarity used by the celebration system when this level is reached.
  /// Distinct from [difficulty] (which controls the achievement card
  /// label/badge); rarity drives the celebration accent and aura.
  final Rarity rarity;

  /// Cosmetic ids unlocked the moment the player crosses into this
  /// level. Empty for non-rewarding tiers (e.g. level 1 origin).
  final List<String> cosmeticRewards;

  /// Whether this tier appears as an anchor node on the static journey map.
  /// Currently every tier is an anchor; the flag exists so future tiers
  /// (e.g. micro-milestones) can opt out without rewriting the map builder.
  final bool isJourneyMapAnchor;

  /// Whether the title returned at this level is *new* (versus the previous
  /// tier's title carrying over). Today every tier is a breakpoint, but the
  /// field lets future config changes split the concepts.
  final bool isTitleBreakpoint;

  /// Localised tier title resolved from the user's current [AppLocalizations].
  /// Single source of truth for level titles across the app.
  final ProgressionLocalizedText title;

  @override
  String toString() =>
      'ProgressionLevelTier(level: $level, id: $achievementId, '
      'emoji: $emoji, difficulty: $difficulty)';
}

/// Canonical, ordered list of tiers. The journey map, the achievement catalog
/// and all level emoji / title lookups derive from this.
///
/// Level 1 is the journey origin (start node). It does NOT appear in the
/// achievement catalog — players don't "earn" level 1 — but it does appear on
/// the journey map as the bottom anchor and has a localised title.
const List<ProgressionLevelTier> kProgressionLevelTiers = [
  ProgressionLevelTier(
    level: 1,
    achievementId: 'level_1',
    emoji: '🧌',
    difficulty: ProgressionAchievementDifficulty.easy,
    rarity: Rarity.common,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title1,
    // Level 1 is the journey origin — starter cosmetics flow from the
    // welcome_to_journey achievement, not from this tier.
  ),
  ProgressionLevelTier(
    level: 5,
    achievementId: 'level_5',
    emoji: '🥾',
    difficulty: ProgressionAchievementDifficulty.easy,
    rarity: Rarity.common,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title5,
    cosmeticRewards: ['background_forest_trail'],
  ),
  ProgressionLevelTier(
    level: 10,
    achievementId: 'level_10',
    emoji: '🧭',
    difficulty: ProgressionAchievementDifficulty.easy,
    rarity: Rarity.common,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title10,
    cosmeticRewards: ['frame_wildwood'],
  ),
  ProgressionLevelTier(
    level: 15,
    achievementId: 'level_15',
    emoji: '⚒️',
    difficulty: ProgressionAchievementDifficulty.easy,
    rarity: Rarity.uncommon,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title15,
    cosmeticRewards: ['background_ravine'],
  ),
  ProgressionLevelTier(
    level: 20,
    achievementId: 'level_20',
    emoji: '🛡️',
    difficulty: ProgressionAchievementDifficulty.medium,
    rarity: Rarity.uncommon,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title20,
    cosmeticRewards: ['frame_ruins'],
  ),
  ProgressionLevelTier(
    level: 25,
    achievementId: 'level_25',
    emoji: '🌩️',
    difficulty: ProgressionAchievementDifficulty.medium,
    rarity: Rarity.uncommon,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title25,
    cosmeticRewards: ['background_ruins'],
  ),
  ProgressionLevelTier(
    level: 30,
    achievementId: 'level_30',
    emoji: '🏰',
    difficulty: ProgressionAchievementDifficulty.medium,
    rarity: Rarity.uncommon,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title30,
  ),
  ProgressionLevelTier(
    level: 40,
    achievementId: 'level_40',
    emoji: '🐉',
    difficulty: ProgressionAchievementDifficulty.medium,
    rarity: Rarity.rare,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title40,
    cosmeticRewards: ['frame_dwarven'],
  ),
  ProgressionLevelTier(
    level: 50,
    achievementId: 'level_50',
    emoji: '🏹',
    difficulty: ProgressionAchievementDifficulty.hard,
    rarity: Rarity.epic,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title50,
    cosmeticRewards: ['frame_underways'],
  ),
  ProgressionLevelTier(
    level: 60,
    achievementId: 'level_60',
    emoji: '🔱',
    difficulty: ProgressionAchievementDifficulty.hard,
    rarity: Rarity.epic,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title60,
    cosmeticRewards: ['background_frostlands'],
  ),
  ProgressionLevelTier(
    level: 70,
    achievementId: 'level_70',
    emoji: '🌌',
    difficulty: ProgressionAchievementDifficulty.hard,
    rarity: Rarity.epic,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title70,
    cosmeticRewards: ['frame_frost'],
  ),
  ProgressionLevelTier(
    level: 80,
    achievementId: 'level_80',
    emoji: '♾️',
    difficulty: ProgressionAchievementDifficulty.extraHard,
    rarity: Rarity.legendary,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title80,
    cosmeticRewards: ['frame_mountain'],
  ),
  ProgressionLevelTier(
    level: 90,
    achievementId: 'level_90',
    emoji: '👑',
    difficulty: ProgressionAchievementDifficulty.extraHard,
    rarity: Rarity.legendary,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title90,
    cosmeticRewards: ['background_rocky_mountains'],
  ),
  ProgressionLevelTier(
    level: 100,
    achievementId: 'level_100',
    emoji: '🐦‍🔥',
    difficulty: ProgressionAchievementDifficulty.mythic,
    rarity: Rarity.mythic,
    isJourneyMapAnchor: true,
    isTitleBreakpoint: true,
    title: _title100,
    cosmeticRewards: ['frame_dragonrock'],
  ),
];

/// Cosmetic ids unlocked at *decorative* levels (those between title
/// breakpoints — 35, 45, 75, 95). Title-breakpoint tiers carry their
/// cosmetics on [ProgressionLevelTier.cosmeticRewards] directly; this map
/// covers the in-between bands so [cosmeticsForLevel] is the single
/// source of truth.
const Map<int, List<String>> kProgressionDecorativeLevelCosmetics =
    <int, List<String>>{
  35: ['background_bridge_crossing'],
  45: ['background_mines'],
  75: ['background_frozen_lake'],
  95: ['background_dragonrock_fortress'],
};

/// All cosmetic ids unlocked the moment the player crosses into [level].
/// Title-breakpoint tiers and decorative levels both flow through here, so
/// callers (the cosmetic dispatcher, the celebration adapter) don't need
/// to know which kind of level it is.
List<String> cosmeticsForLevel(int level) {
  final tier = exactTierForLevel(level);
  if (tier != null) return tier.cosmeticRewards;
  return kProgressionDecorativeLevelCosmetics[level] ?? const [];
}

// Top-level functions (rather than inline lambdas) so [kProgressionLevelTiers]
// stays a `const` list. `const` constructors can reference top-level function
// tear-offs but cannot capture local closures.
String _title1(AppLocalizations l10n) => l10n.progLevelTitle1;
String _title5(AppLocalizations l10n) => l10n.progLevelTitle5;
String _title10(AppLocalizations l10n) => l10n.progLevelTitle10;
String _title15(AppLocalizations l10n) => l10n.progLevelTitle15;
String _title20(AppLocalizations l10n) => l10n.progLevelTitle20;
String _title25(AppLocalizations l10n) => l10n.progLevelTitle25;
String _title30(AppLocalizations l10n) => l10n.progLevelTitle30;
String _title40(AppLocalizations l10n) => l10n.progLevelTitle40;
String _title50(AppLocalizations l10n) => l10n.progLevelTitle50;
String _title60(AppLocalizations l10n) => l10n.progLevelTitle60;
String _title70(AppLocalizations l10n) => l10n.progLevelTitle70;
String _title80(AppLocalizations l10n) => l10n.progLevelTitle80;
String _title90(AppLocalizations l10n) => l10n.progLevelTitle90;
String _title100(AppLocalizations l10n) => l10n.progLevelTitle100;

/// Decorative emoji for in-between levels with no title change and no
/// matching achievement. Surfaced by [emojiForLevel] when a player reaches
/// e.g. level 35 — the journey UI can still show a glyph even though the
/// tier title is unchanged from level 30.
const Map<int, String> kProgressionDecorativeLevelEmoji = {
  35: '🏔️',
  45: '⚔️',
  55: '🦅',
  65: '🌠',
  75: '☄️',
  85: '🪽',
  95: '🜲',
};

/// Levels at which the title actually changes — the journey "feed" surfaces
/// only these. Excludes level 1 (origin) by convention.
List<int> get kLevelTitleBreakpoints => kProgressionLevelTiers
    .where((t) => t.isTitleBreakpoint && t.level > 1)
    .map((t) => t.level)
    .toList(growable: false);

/// Levels that anchor the static journey map spine, including the level-1
/// origin. Bottom-to-top in level order.
List<int> get kJourneyMapAnchors => kProgressionLevelTiers
    .where((t) => t.isJourneyMapAnchor)
    .map((t) => t.level)
    .toList(growable: false);

/// Returns the tier governing [level] — i.e. the highest tier whose `level`
/// is ≤ [level]. For level 0 or below, returns the first tier (level 1).
ProgressionLevelTier tierForLevel(int level) {
  if (level <= kProgressionLevelTiers.first.level) {
    return kProgressionLevelTiers.first;
  }
  ProgressionLevelTier current = kProgressionLevelTiers.first;
  for (final tier in kProgressionLevelTiers) {
    if (tier.level <= level) {
      current = tier;
    } else {
      break;
    }
  }
  return current;
}

/// Looks up an exact tier by [level], or `null` if no tier sits exactly at
/// that level. Use this when you need to know whether [level] *is* a tier
/// boundary; for "what title applies right now" use [tierForLevel].
ProgressionLevelTier? exactTierForLevel(int level) {
  for (final tier in kProgressionLevelTiers) {
    if (tier.level == level) return tier;
  }
  return null;
}

/// Emoji for a given level. Tier-anchor levels return their tier emoji;
/// decorative in-between levels return their dedicated emoji; everything else
/// falls back to the governing tier's emoji.
String emojiForLevel(int level) {
  final exact = exactTierForLevel(level);
  if (exact != null) return exact.emoji;
  final decorative = kProgressionDecorativeLevelEmoji[level];
  if (decorative != null) return decorative;
  return tierForLevel(level).emoji;
}

/// True when [level] is a journey title breakpoint (excluding the level-1
/// origin).
bool levelHasTitleBreakpoint(int level) => kLevelTitleBreakpoints.contains(level);

/// Returns the next title breakpoint strictly above [level], or `null` when
/// the player has already passed the highest one.
int? nextTitleBreakpointAfter(int level) {
  for (final bp in kLevelTitleBreakpoints) {
    if (bp > level) return bp;
  }
  return null;
}

/// Parses the level number out of an achievement id of the form `level_<N>`.
/// Returns `null` for non-level achievements.
int? levelFromAchievementId(String id) {
  final match = _levelIdPattern.firstMatch(id);
  return match == null ? null : int.tryParse(match.group(1)!);
}

final RegExp _levelIdPattern = RegExp(r'^level_(\d+)$');

/// Runtime pairing of a static [ProgressionLevelTier] with its unlock state.
/// Built by adapters that combine the static config with provider data.
@immutable
class ProgressionLevelMilestone {
  const ProgressionLevelMilestone({
    required this.tier,
    required this.isUnlocked,
    this.unlockedAt,
    this.isCurrent = false,
    this.isNext = false,
  });

  final ProgressionLevelTier tier;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isCurrent;
  final bool isNext;

  int get level => tier.level;
  String get achievementId => tier.achievementId;
  String get emoji => tier.emoji;
  ProgressionAchievementDifficulty get difficulty => tier.difficulty;
}
