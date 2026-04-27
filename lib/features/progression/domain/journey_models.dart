enum JourneyEventType {
  level,
  title,
  achievement,
  quest,
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
    this.isUnlocked = false,
    this.isCurrent = false,
  });

  final String id;
  final JourneyEventType type;

  /// Primary display text (title, level name, achievement name, …).
  final String label;

  /// Secondary line (domain name, "Level 12 dosažen", …).
  final String? sublabel;

  /// Optional longer description shown in the detail card.
  final String? description;

  final DateTime? unlockedAt;

  /// Numeric level – populated only for [JourneyEventType.level] nodes.
  final int? levelNumber;

  /// Node is in the player's unlocked history.
  final bool isUnlocked;

  /// Most-recent unlocked node — drawn with pulse ring and largest size.
  final bool isCurrent;
}
