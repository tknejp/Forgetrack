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
  // Slot unlock 1/6 — emblem-board slot 0 (see
  // `EmblemBoard.slotUnlockLevels`). Carries no cosmetic reward; the
  // unlocked emblem slot itself is the reward, similar in feel to
  // earning a title.
  LevelMilestoneSpec(
    level: 3,
    titleKey: _emblemSlot1,
    emoji: '🛡️',
    rarity: Rarity.common,
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 5,
    titleKey: _title5,
    emoji: '🥾',
    rarity: Rarity.common,
    cosmeticRewardIds: ['background_forest_trail'],
  ),
  // Banner drop — teaser 2 levels before the uncommon-tier frame
  // (lvl 10). Title still reads the active common-tier label so the
  // celebration card shows "you got a new banner" without claiming
  // the player has changed tier.
  LevelMilestoneSpec(
    level: 8,
    titleKey: _title5,
    emoji: '🌲',
    rarity: Rarity.common,
    cosmeticRewardIds: ['banner_forest'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 10,
    titleKey: _title10,
    emoji: '🧭',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['frame_wildwood'],
  ),
  LevelMilestoneSpec(
    level: 12,
    titleKey: _title10,
    emoji: '🐺',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['skin_hunter'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 15,
    titleKey: _title15,
    emoji: '⚒️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['background_ravine'],
  ),
  // Slot unlock 2/6.
  LevelMilestoneSpec(
    level: 17,
    titleKey: _emblemSlot2,
    emoji: '🛡️',
    rarity: Rarity.uncommon,
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 20,
    titleKey: _title20,
    emoji: '🛡️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['frame_ruins'],
  ),
  // Banner drop bridging the uncommon→rare transition. Sits between
  // frame_ruins (lvl 20, uncommon) and background_ruins (lvl 25, rare)
  // as the centerpiece of the ruins set.
  LevelMilestoneSpec(
    level: 23,
    titleKey: _title20,
    emoji: '🏛️',
    rarity: Rarity.uncommon,
    cosmeticRewardIds: ['banner_ruins'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 25,
    titleKey: _title25,
    emoji: '🌩️',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['background_ruins'],
  ),
  LevelMilestoneSpec(
    level: 30,
    titleKey: _title30,
    emoji: '🏰',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['skin_oathbound'],
  ),
  // Slot unlock 3/6.
  LevelMilestoneSpec(
    level: 33,
    titleKey: _emblemSlot3,
    emoji: '🛡️',
    rarity: Rarity.rare,
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 35,
    titleKey: _title30,
    emoji: '🏔️',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['background_bridge_crossing'],
    isTitleBreakpoint: false,
  ),
  // Banner drop — teaser 2 levels before frame_dwarven (lvl 40),
  // breaks the 35→40 dry stretch in the late-rare band.
  LevelMilestoneSpec(
    level: 38,
    titleKey: _title30,
    emoji: '🗝️',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['banner_mine'],
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
    level: 42,
    titleKey: _title40,
    emoji: '⛏️',
    rarity: Rarity.rare,
    cosmeticRewardIds: ['skin_mine'],
    isTitleBreakpoint: false,
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
  // Slot unlock 4/6.
  LevelMilestoneSpec(
    level: 53,
    titleKey: _emblemSlot4,
    emoji: '🛡️',
    rarity: Rarity.epic,
    isTitleBreakpoint: false,
  ),
  // Banner drop — fills the longest dry stretch in the whole ladder
  // (53→60, 7 levels otherwise). Lands inside the epic title era
  // (Pán podzemních cest) so the celebration ties to the active title.
  LevelMilestoneSpec(
    level: 57,
    titleKey: _title50,
    emoji: '🪟',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['banner_frost'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 60,
    titleKey: _title60,
    emoji: '🔱',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['background_frostlands'],
  ),
  LevelMilestoneSpec(
    level: 65,
    titleKey: _title60,
    emoji: '❄️',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['skin_frostwalker'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 70,
    titleKey: _title70,
    emoji: '🌌',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['frame_frost'],
  ),
  // Slot unlock 5/6.
  LevelMilestoneSpec(
    level: 73,
    titleKey: _emblemSlot5,
    emoji: '🛡️',
    rarity: Rarity.epic,
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 75,
    titleKey: _title70,
    emoji: '☄️',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['background_frozen_lake'],
    isTitleBreakpoint: false,
  ),
  // Banner drop — teaser 2 levels before frame_mountain (lvl 80),
  // breaks the 75→80 dry stretch. Player is still in the epic
  // Ledový chodec era; the legendary banner functions as a preview of
  // the tier they're about to enter.
  LevelMilestoneSpec(
    level: 78,
    titleKey: _title70,
    emoji: '⛰️',
    rarity: Rarity.epic,
    cosmeticRewardIds: ['banner_mountain'],
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
    level: 85,
    titleKey: _title80,
    emoji: '🔮',
    rarity: Rarity.legendary,
    cosmeticRewardIds: ['skin_mage'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 90,
    titleKey: _title90,
    emoji: '👑',
    rarity: Rarity.legendary,
    cosmeticRewardIds: ['background_rocky_mountains'],
  ),
  // Slot unlock 6/6 — final emblem-board slot.
  LevelMilestoneSpec(
    level: 93,
    titleKey: _emblemSlot6,
    emoji: '🛡️',
    rarity: Rarity.legendary,
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 95,
    titleKey: _title90,
    emoji: '🜲',
    rarity: Rarity.mythic,
    cosmeticRewardIds: ['skin_dragonrock'],
    isTitleBreakpoint: false,
  ),
  // Banner drop — teaser 2 levels before the mythic finale (lvl 100),
  // breaks the 95→100 dry stretch and previews the Dragonrock tier
  // before the final frame + background land.
  LevelMilestoneSpec(
    level: 98,
    titleKey: _title90,
    emoji: '🌋',
    rarity: Rarity.legendary,
    cosmeticRewardIds: ['banner_dragonrock'],
    isTitleBreakpoint: false,
  ),
  LevelMilestoneSpec(
    level: 100,
    titleKey: _title100,
    emoji: '🐦‍🔥',
    rarity: Rarity.mythic,
    cosmeticRewardIds: ['frame_dragonrock', 'background_dragonrock_fortress'],
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

/// Returns the highest title-breakpoint spec whose level is ≤ [level].
///
/// Used for the player's *active title* + tier emoji at an arbitrary
/// level. Skips non-title-breakpoint specs (decorative cosmetic drops,
/// skin drops, emblem-slot unlocks) so those entries can carry their
/// own distinct titleKey + emoji on the milestone node without
/// overriding the surrounding tier's title in profile / journey /
/// friend displays.
LevelMilestoneSpec levelTitleSpecAtOrBelow(int level) {
  LevelMilestoneSpec current = kLevelMilestones.first;
  for (final spec in kLevelMilestones) {
    if (!spec.isTitleBreakpoint) continue;
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

String _emblemSlot1(AppLocalizations l) => l.progEmblemSlotMilestoneTitle1;
String _emblemSlot2(AppLocalizations l) => l.progEmblemSlotMilestoneTitle2;
String _emblemSlot3(AppLocalizations l) => l.progEmblemSlotMilestoneTitle3;
String _emblemSlot4(AppLocalizations l) => l.progEmblemSlotMilestoneTitle4;
String _emblemSlot5(AppLocalizations l) => l.progEmblemSlotMilestoneTitle5;
String _emblemSlot6(AppLocalizations l) => l.progEmblemSlotMilestoneTitle6;
