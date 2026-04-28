import 'package:flutter/material.dart';

import '../../domain/progression_models.dart';
import '../widgets/ft_progression_domain_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared progression badge specs.
//
// Single source of truth for achievement / level emoji and colour mapping.
// Originally lived in `widgets/ft_achievement_badge_spec.dart`; moved here so
// the Journey adapter and map widgets can reuse the same lookups without
// pulling in unrelated achievement-list UI.
//
// The legacy file at `widgets/ft_achievement_badge_spec.dart` re-exports
// from this module so existing imports keep working.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AchievementBadgeSpec {
  const AchievementBadgeSpec({required this.emoji, required this.color});
  final String emoji;
  final Color color;
}

/// Returns the level number embedded in an achievement id whose suffix
/// matches `_level_<n>` (e.g. `journey_level_30` → 30). `null` when no
/// match — i.e. the achievement is not a level achievement.
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

/// Emoji lookup keyed by achievement id (or level number for level
/// achievements). Used by both the achievement list UI and the Journey map
/// nodes / tooltip / feed so they stay visually consistent.
String achievementEmojiForId(String id) {
  // Level achievements — derive the level and look up the milestone emoji.
  final levelMatch = RegExp(r'_level_(\d+)$').firstMatch(id);
  if (levelMatch != null) {
    final level = int.tryParse(levelMatch.group(1)!);
    if (level != null) {
      return emojiForLevel(level);
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

/// Levels at which `ProgressionLevelPolicy.titleForLevel` actually changes the
/// rank — i.e. the only levels that should surface as journey milestones.
/// Up to and including 30 the breakpoints land every 5 levels; from 30 they
/// step by 10 because the policy doesn't introduce a new title between them.
/// Level 1 (Troll) is intentionally NOT in this list — it's the journey's
/// starting state, not a milestone the player "reaches".
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

/// Convenience predicate matching [kJourneyTitleBreakpoints].
bool levelHasTitleBreakpoint(int level) =>
    kJourneyTitleBreakpoints.contains(level);

/// Returns the next title breakpoint strictly above [level], or `null` when
/// the player has already passed the highest one.
int? nextTitleBreakpointAfter(int level) {
  for (final bp in kJourneyTitleBreakpoints) {
    if (bp > level) return bp;
  }
  return null;
}

/// Emoji for a given milestone level. Used by the Journey adapter to attach
/// emoji even when no level achievement exists for that level yet. The
/// concrete level → emoji map matches `achievementEmojiForId`'s level branch
/// so map nodes look identical regardless of source.
String emojiForLevel(int level) {
  return switch (level) {
    1 => '🧌',
    5 => '🥾',
    10 => '🧭',
    15 => '⚒️',
    20 => '🛡️',
    25 => '🌩️',
    30 => '🏰',
    35 => '🏔️',
    40 => '🐉',
    45 => '⚔️',
    50 => '🏹',
    55 => '🦅',
    60 => '🔱',
    65 => '🌠',
    70 => '🌌',
    75 => '☄️',
    80 => '♾️',
    85 => '🪽',
    90 => '👑',
    95 => '🜲',
    100 => '🐦‍🔥',
    _ => '👑',
  };
}
