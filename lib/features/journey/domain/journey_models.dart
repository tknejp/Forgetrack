enum JourneyEventType {
  /// Minor level milestone — divisible by 5 but not by 10. Smaller node,
  /// amber/gold, level number is the primary visual.
  level,

  /// Major title milestone — divisible by 10 (Pathfinder, Iron Warden, …).
  /// Largest node, gold + purple accent, double ring, emoji prominent.
  titleMilestone,

  /// Standalone unlocked achievement.
  achievement,

  /// Completed quest.
  quest,

  /// Reserved for future ledger sources (streak / XP). Currently NOT
  /// surfaced on the map per UX guidance — streaks change too often and
  /// would clutter the journey.
  streak,
  xpMilestone,
}

class JourneyCheckpoint {
  const JourneyCheckpoint({
    required this.id,
    required this.type,
    required this.label,
    this.sublabel,
    this.description,
    this.unlockedAt,
    this.levelNumber,
    this.title,
    this.emoji,
    this.accentColorValue,
    this.achievementDifficultyLabel,
    this.isUnlocked = false,
    this.isCurrent = false,
    this.isNext = false,
    this.isPathAnchor = true,
    this.mapPointId,
    this.mapUnlockedThroughPointId,
    this.mapProgress,
    this.mapSide,
  });

  final String id; // lint-ignore: untyped-id — journey-feed dedupe token composed by the producer
  final JourneyEventType type;

  /// Primary display text (achievement name, level title, …).
  final String label;

  /// Secondary line ("Level 30", "Úspěch odemčen", …).
  final String? sublabel;

  /// Longer description for the tooltip / feed row.
  final String? description;

  final DateTime? unlockedAt;

  /// Numeric level — populated for `level` and `titleMilestone` types.
  final int? levelNumber;

  /// RPG title string (Pathfinder, Iron Warden, …) — populated for
  /// `titleMilestone` types.
  final String? title;

  /// Pre-resolved emoji from `progression_badge_specs`. Map node renders
  /// it directly so the same glyph appears in node, tooltip and feed.
  final String? emoji;

  /// Optional ARGB color override for item-specific styling, e.g. achievement
  /// rarity colours. Kept as an int so the domain model stays Flutter-free.
  final int? accentColorValue;

  /// Localized difficulty/rarity text for achievement checkpoints.
  final String? achievementDifficultyLabel;

  /// Node is in the player's unlocked history.
  final bool isUnlocked;

  /// Most-recent unlocked node — drawn with pulse ring and largest size.
  final bool isCurrent;

  /// First locked milestone ahead of the player. It stays locked, but gets a
  /// stronger outline so the next destination is easy to spot.
  final bool isNext;

  /// Whether this checkpoint sits on the main level path. Achievements and
  /// quests can be rendered near the path without bending the path through
  /// every historical event.
  final bool isPathAnchor;

  /// ID of the static route point from `assets/map/journey_map_route.json`.
  /// This is intentionally separate from the checkpoint list index.
  final int? mapPointId;

  /// Highest route point that should be considered unlocked for path progress.
  /// Current title anchors can stay on their milestone point while still
  /// letting small level dots advance to the player's exact current level.
  final int? mapUnlockedThroughPointId;

  /// Stable top-to-bottom map position where 0 = top/final destination and
  /// 1 = bottom/start. Side events use this to keep chronological placement
  /// independent from the number of visible nodes.
  final double? mapProgress;

  /// Horizontal side offset for non-path nodes. Negative values sit left of
  /// the path, positive values right of it.
  final double? mapSide;

  /// Convenience: divisible-by-10 level milestones get the major styling.
  bool get isMajorMilestone => type == JourneyEventType.titleMilestone;

  /// Convenience: divisible-by-5-but-not-10 level milestones.
  bool get isMinorMilestone => type == JourneyEventType.level;
}

/// Static map anchor for the Journey milestone path.
///
/// These anchors are deliberately separate from feed events: the map layout is
/// fixed from level 100 (top) to level 1 (bottom), while achievements and
/// quests remain historical entries in the feed.
class JourneyMilestoneAnchor {
  const JourneyMilestoneAnchor({
    required this.level,
    required this.title,
    required this.emoji,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isNext,
    this.unlockedAt,
  });

  final int level;
  final String title;
  final String emoji;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isNext;
  final DateTime? unlockedAt;
}
