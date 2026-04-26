import 'package:flutter/material.dart';

import '../../domain/progression_models.dart';
import 'ft_progression_domain_theme.dart';

@immutable
class AchievementBadgeSpec {
  const AchievementBadgeSpec({required this.emoji, required this.color});
  final String emoji;
  final Color color;
}

int? achievementLevelTarget(ProgressionAchievement achievement) {
  final match = RegExp(r'_level_(\d+)$').firstMatch(achievement.id);
  return match == null ? null : int.tryParse(match.group(1)!);
}

AchievementBadgeSpec achievementBadgeSpec(ProgressionAchievement achievement) {
  final color = FtProgressionDomainTheme.colorForAchievementDifficulty(
    achievement.difficulty,
  );
  final emoji = achievementEmojiForId(achievement.id);
  return AchievementBadgeSpec(emoji: emoji, color: color);
}

String achievementEmojiForId(String id) {
  // Level achievements: use same regex as achievementBadgeSpec for perfect parity
  final levelMatch = RegExp(r'_level_(\d+)$').firstMatch(id);
  if (levelMatch != null) {
    final level = int.tryParse(levelMatch.group(1)!);
    if (level != null) {
      return switch (level) {
        5 => '🥾',
        10 => '🧭',
        15 => '⚒️',
        20 => '🛡️',
        25 => '🌩️',
        30 => '🏰',
        40 => '🐉',
        50 => '🏹',
        60 => '🔱',
        70 => '🌌',
        80 => '♾️',
        90 => '👑',
        100 => '🐦‍🔥',
        _ => '👑',
      };
    }
  }
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
