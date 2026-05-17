import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/rarity.dart';
import '../localized_text.dart';

export '../../../../shared/domain/rarity.dart' show Rarity;

/// Single source of truth for V2 level-milestone metadata.
///
/// Drives the `levelMilestones()` catalog (which the engine grants
/// rewards from) and the `ProgressionDisplayResolver` level helpers.
/// Replaces V1's [kProgressionLevelTiers] / decorative-cosmetics map /
/// decorative-emoji map — one flat ordered list instead of three side
/// tables.
///
/// Each entry represents a reward-bearing level milestone: either a
/// tier-anchored title breakpoint (5, 10, …, 100) or a decorative
/// cosmetic drop (35, 45, 75, 95). Levels with neither a reward nor a
/// title change (55, 65, 85) are pure journey-map decoration and live
/// in `lib/features/journey/domain/journey_levels.dart`.
class LevelMilestoneSpec {
  const LevelMilestoneSpec({
    required this.level,
    required this.titleKey,
    required this.emoji,
    required this.rarity,
    this.cosmeticRewardIds = const [],
    this.isTitleBreakpoint = true,
  });

  /// Player level this milestone fires at.
  final int level;

  /// Localised title shown for any level in `[this.level, nextBreakpoint)`.
  /// Decorative entries (35, 45, 75, 95) carry the governing breakpoint's
  /// closure so a single field access works for every spec.
  final LocalizedText titleKey;

  /// Milestone emoji surfaced in celebration / journey / inventory views.
  final String emoji;

  /// Rarity drives celebration accent + level-badge colour via
  /// `RarityPalette.forRarity(...)`.
  final Rarity rarity;

  /// Cosmetic ids granted on crossing into this level. Empty for tiers
  /// that exist only for the title change (e.g. level 30).
  final List<String> cosmeticRewardIds;

  /// `true` for entries whose [titleKey] is *new* (versus the previous
  /// spec's title carrying over). The journey feed / celebration
  /// overlay use this flag to distinguish "you unlocked a new title!"
  /// events from cosmetic-only level-ups.
  final bool isTitleBreakpoint;
}

/// Canonical, ascending-by-level list of every reward-bearing level
/// milestone. Order matters — helpers walk this list to find the
/// governing spec for an arbitrary level.
const List<LevelMilestoneSpec> kLevelMilestones = [
  LevelMilestoneSpec(
    level: 1,
    titleKey: _title1,
    emoji: '🧌',
    rarity: Rarity.common,
    // Level 1 is the journey origin — starter cosmetics flow from the
    // welcome_to_journey achievement, not from this milestone.
  ),
  LevelMilestoneSpec(
    level: 5,
    titleKey: _title5,
    emoji: '🥾',
    rarity: Rarity.common,
    cosmeticRewardIds: ['background_forest_trail'],
  ),
  LevelMilestoneSpec(
    level: 10,
    titleKey: _title10,
    emoji: '🧭',
    rarity: Rarity.common,
    cosmeticRewardIds: ['frame_wildwood'],
  ),
  LevelMilestoneSpec(
    level: 15,
    titleKey: _title15,
    emoji: '⚒️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['background_ravine'],
  ),
  LevelMilestoneSpec(
    level: 20,
    titleKey: _title20,
    emoji: '🛡️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['frame_ruins'],
  ),
  LevelMilestoneSpec(
    level: 25,
    titleKey: _title25,
    emoji: '🌩️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['background_ruins'],
  ),
  LevelMilestoneSpec(
    level: 30,
    titleKey: _title30,
    emoji: '🏰',
    rarity: Rarity.uncommon,
  ),
  LevelMilestoneSpec(
    level: 35,
    titleKey: _title30,
    emoji: '🏔️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['background_bridge_crossing'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 40,
    titleKey: _title40,
    emoji: '🐉',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['frame_dwarven'],
  ),
  LevelMilestoneSpec(
    level: 45,
    titleKey: _title40,
    emoji: '⚔️',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['background_mines'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 50,
    titleKey: _title50,
    emoji: '🏹',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['frame_underways'],
  ),
  LevelMilestoneSpec(
    level: 60,
    titleKey: _title60,
    emoji: '🔱',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['background_frostlands'],
  ),
  LevelMilestoneSpec(
    level: 70,
    titleKey: _title70,
    emoji: '🌌',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['frame_frost'],
  ),
  LevelMilestoneSpec(
    level: 75,
    titleKey: _title70,
    emoji: '☄️',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['background_frozen_lake'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 80,
    titleKey: _title80,
    emoji: '♾️',
    rarity: Rarity.legendary,
    cosmeticRewardIds: ['frame_mountain'],
  ),
  LevelMilestoneSpec(
    level: 90,
    titleKey: _title90,
    emoji: '👑',
    rarity: Rarity.legendary,
    cosmeticRewardIds: ['background_rocky_mountains'],
  ),
  LevelMilestoneSpec(
    level: 95,
    titleKey: _title90,
    emoji: '🜲',
    rarity: Rarity.legendary,
    cosmeticRewardIds: ['background_dragonrock_fortress'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 100,
    titleKey: _title100,
    emoji: '🐦‍🔥',
    rarity: Rarity.mythic,
    cosmeticRewardIds: ['frame_dragonrock'],
  ),
];

/// Returns the spec whose [LevelMilestoneSpec.level] exactly matches
/// [level], or `null` when no spec sits at that level.
LevelMilestoneSpec? levelMilestoneByLevel(int level) {
  for (final spec in kLevelMilestones) {
    if (spec.level == level) return spec;
  }
  return null;
}

/// Returns the spec governing [level] — the highest spec whose level is
/// ≤ [level]. For level 0 / negative, returns the first spec (level 1).
LevelMilestoneSpec levelMilestoneAtOrBelow(int level) {
  LevelMilestoneSpec current = kLevelMilestones.first;
  for (final spec in kLevelMilestones) {
    if (spec.level <= level) {
      current = spec;
    } else {
      break;
    }
  }
  return current;
}

/// Cosmetic ids granted on crossing into [level]. Empty for levels with
/// no spec entry, or for spec entries that carry no cosmetic rewards
/// (e.g. level 30 — title change only).
List<String> cosmeticsForLevel(int level) =>
    levelMilestoneByLevel(level)?.cosmeticRewardIds ?? const [];

/// `true` when [level] sits on a title-breakpoint spec. Drives the
/// "title unlocked" celebration overlay.
bool levelHasTitleBreakpoint(int level) =>
    levelMilestoneByLevel(level)?.isTitleBreakpoint ?? false;

// Top-level title functions for const tear-offs. `const` constructors
// can reference top-level function references but cannot capture local
// closures.
String _title1(AppLocalizations l) => l.progLevelTitle1;
String _title5(AppLocalizations l) => l.progLevelTitle5;
String _title10(AppLocalizations l) => l.progLevelTitle10;
String _title15(AppLocalizations l) => l.progLevelTitle15;
String _title20(AppLocalizations l) => l.progLevelTitle20;
String _title25(AppLocalizations l) => l.progLevelTitle25;
String _title30(AppLocalizations l) => l.progLevelTitle30;
String _title40(AppLocalizations l) => l.progLevelTitle40;
String _title50(AppLocalizations l) => l.progLevelTitle50;
String _title60(AppLocalizations l) => l.progLevelTitle60;
String _title70(AppLocalizations l) => l.progLevelTitle70;
String _title80(AppLocalizations l) => l.progLevelTitle80;
String _title90(AppLocalizations l) => l.progLevelTitle90;
String _title100(AppLocalizations l) => l.progLevelTitle100;
