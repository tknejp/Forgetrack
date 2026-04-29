import 'package:flutter/material.dart';

import '../../domain/progression_level_config.dart' as level_config;
import '../../domain/progression_models.dart';
import '../widgets/ft_progression_domain_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared progression badge specs.
//
// This module is the presentation-layer entry point for badge styling. The
// underlying level emoji / breakpoint data lives in
// `domain/progression_level_config.dart` — a single source of truth shared
// with the achievement catalog and journey adapter. The functions here are
// thin wrappers that add presentation concerns (colour resolution,
// per-non-level achievement emoji map).
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
  final color = FtProgressionDomainTheme.colorForAchievementDifficulty(
    achievement.difficulty,
  );
  final emoji = achievementEmojiForId(achievement.id);
  return AchievementBadgeSpec(emoji: emoji, color: color);
}

/// Emoji lookup keyed by achievement id. Level achievements derive their
/// emoji from `progression_level_config.emojiForLevel`; non-level achievements
/// use the static map below.
String achievementEmojiForId(String id) {
  final level = level_config.levelFromAchievementId(id);
  if (level != null) return level_config.emojiForLevel(level);
  return switch (id) {
    'first_reward' => '🏆',
    'reward_hunter_25' => '⚔️',
    'reward_hunter_100' => '⚔️',
    'xp_100000' => '✨',
    'xp_1000000' => '🌟',
    'steps_total_100k' => '🥾',
    'steps_total_500k' => '🥾',
    'steps_total_1000000' => '🥾',
    'steps_total_5000000' => '💎',
    'steps_total_10000000' => '🏔️',
    'steps_month_300k' => '🗺️',
    'steps_month_600k' => '🌍',
    'steps_streak_3' => '🔥',
    'steps_streak_7' => '🔥',
    'steps_streak_30' => '🔥',
    'steps_streak_100' => '⛓️',
    'nutrition_streak_3' => '🌸',
    'nutrition_streak_30' => '🍎',
    'nutrition_streak_100' => '🍄',
    'nutrition_rewards_25' => '🥗',
    'weekly_activity_mastery' => '🏋',
    'weekly_activity_4' => '🏌',
    'weekly_activity_12' => '🏃',
    'weekly_activity_24' => '🤸',
    'weekly_activity_52' => '🧗',
    'sleep_total_250h' => '🛌',
    'sleep_total_1000h' => '💎',
    'sleep_month_225h' => '🌜',
    'sleep_month_240h' => '👑',
    _ => '🏅',
  };
}

/// Levels at which the journey title changes (excludes level 1 origin).
/// Re-export of `kLevelTitleBreakpoints` for callers already importing from
/// this module.
List<int> get kJourneyTitleBreakpoints => level_config.kLevelTitleBreakpoints;

bool levelHasTitleBreakpoint(int level) =>
    level_config.levelHasTitleBreakpoint(level);

int? nextTitleBreakpointAfter(int level) =>
    level_config.nextTitleBreakpointAfter(level);

/// Re-export of `progression_level_config.emojiForLevel`.
String emojiForLevel(int level) => level_config.emojiForLevel(level);
