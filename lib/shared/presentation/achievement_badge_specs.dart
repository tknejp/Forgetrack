import 'package:flutter/material.dart';

import '../../features/progression/domain/policy/level_config.dart'
    as level_config;
import '../../features/progression/domain/progression_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared achievement badge specs.
//
// Thin wrappers that map progression domain models to visual data (emoji +
// color). Lives in shared/ so both the progression and social features can
// consume it without cross-feature presentation imports.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AchievementBadgeSpec {
  const AchievementBadgeSpec({required this.emoji, required this.color});
  final String emoji;
  final Color color;
}

/// Returns the level encoded in an achievement id of the form `level_<n>`,
/// or `null` for non-level achievements.
int? achievementLevelTarget(ProgressionAchievement achievement) =>
    level_config.levelFromAchievementId(achievement.id);

AchievementBadgeSpec achievementBadgeSpec(ProgressionAchievement achievement) {
  return AchievementBadgeSpec(
    emoji: achievement.badgeEmoji,
    color: achievement.difficulty.color,
  );
}

/// Re-export of `kLevelTitleBreakpoints` for callers already importing from
/// this module.
List<int> get kJourneyTitleBreakpoints => level_config.kLevelTitleBreakpoints;

bool levelHasTitleBreakpoint(int level) =>
    level_config.levelHasTitleBreakpoint(level);

int? nextTitleBreakpointAfter(int level) =>
    level_config.nextTitleBreakpointAfter(level);

/// Re-export of `progression_level_config.emojiForLevel`.
String emojiForLevel(int level) => level_config.emojiForLevel(level);
