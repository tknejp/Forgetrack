import '../../progression_engine/domain/catalog/level_milestone_specs.dart';

/// Journey-display layer on top of the engine's [kLevelMilestones].
///
/// Owns concepts that are pure map / feed visuals: which levels render
/// as anchor nodes on the static map spine, which levels mark a "new
/// title" feed event, and the decorative emojis for intermediate
/// visual nodes that don't carry rewards.
///
/// The engine catalog ([LevelMilestoneSpec] + `LevelMilestoneNode`)
/// remains the source of truth for *what rewards exist at a level*;
/// this file only adds the journey-specific display rules.

/// Levels rendered as anchors on the static journey map spine.
/// Bottom-to-top in level order. Includes the level-1 origin.
const List<int> kJourneyMapAnchors = [
  1,
  5,
  10,
  15,
  20,
  25,
  30,
  40,
  50,
  60,
  70,
  80,
  90,
  100,
];

/// Levels at which the player's title actually changes — the journey
/// feed surfaces only these. Excludes the level-1 origin by convention.
const List<int> kJourneyTitleBreakpoints = [
  5,
  10,
  15,
  20,
  25,
  30,
  40,
  50,
  60,
  70,
  80,
  90,
  100,
];

/// Emoji-only intermediate visual nodes. These levels carry neither a
/// title change nor a cosmetic reward — they exist purely to make the
/// journey map feel populated between anchor tiers.
const Map<int, String> _decorativeEmojiByLevel = {
  55: '🦅',
  65: '🌠',
  85: '🪽',
};

/// Emoji for a given level, suitable for journey-map nodes.
/// Resolution order:
///   1. Exact match in [kLevelMilestones] — reward-bearing milestones
///      carry their own emoji (anchors at 5/10/… and decoratives at
///      35/45/75/95).
///   2. Journey-only decorative emoji (55/65/85).
///   3. Fall back to the governing milestone's emoji so any level
///      between anchors renders the active tier glyph.
String journeyEmojiForLevel(int level) {
  final exact = levelMilestoneByLevel(level);
  if (exact != null) return exact.emoji;
  final decorative = _decorativeEmojiByLevel[level];
  if (decorative != null) return decorative;
  return levelMilestoneAtOrBelow(level).emoji;
}

/// Returns the next journey title breakpoint strictly above [level], or
/// `null` when the player has already passed the highest one.
int? nextJourneyTitleBreakpointAfter(int level) {
  for (final bp in kJourneyTitleBreakpoints) {
    if (bp > level) return bp;
  }
  return null;
}
