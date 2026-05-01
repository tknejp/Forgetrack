import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../../features/progression/domain/progression_level_config.dart'
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
  final color = switch (achievement.difficulty) {
    ProgressionAchievementDifficulty.easy => Tokens.difficultyEasy,
    ProgressionAchievementDifficulty.medium => Tokens.difficultyMedium,
    ProgressionAchievementDifficulty.hard => Tokens.difficultyHard,
    ProgressionAchievementDifficulty.extraHard => Tokens.difficultyExtraHard,
  };
  return AchievementBadgeSpec(
    emoji: achievementEmojiForId(achievement.id),
    color: color,
  );
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

/// Re-export of `kLevelTitleBreakpoints` for callers already importing from
/// this module.
List<int> get kJourneyTitleBreakpoints => level_config.kLevelTitleBreakpoints;

bool levelHasTitleBreakpoint(int level) =>
    level_config.levelHasTitleBreakpoint(level);

int? nextTitleBreakpointAfter(int level) =>
    level_config.nextTitleBreakpointAfter(level);

/// Re-export of `progression_level_config.emojiForLevel`.
String emojiForLevel(int level) => level_config.emojiForLevel(level);
