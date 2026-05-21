import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';

import '../../cosmetics/domain/emblem_buff.dart';
import '../../health_connect/domain/player_goal.dart';

/// Resolves the [EmblemTarget] for a quest claim, used by
/// `RewardGrantService` to build the [EmblemBuffContext] each
/// equipped [EmblemBuff] is asked to resolve against.
///
/// Mapping is intentionally string-switched on the node id — the
/// per-target emblem mapping in `docs/emblem_buffs/archive/plan.md` is keyed
/// on the same node ids the daily-section catalog uses
/// (`daily_calories_today`, `daily_steps_today`, …). Combo bucket
/// quests fall back to the generic [ComboQuestTarget].
///
/// Returns null for nodes that no emblem currently targets (chapter
/// steps, weekly quests, side quests, meta achievements, etc.). The
/// blanket buff still respects this — see [BlanketEmblemBuff.covers].
EmblemTarget? emblemTargetForNode(ProgressionEntry node) {
  switch (node.id.value) {
    case 'daily_calories_today':
      return const DailyGoalTarget(GoalMetric.dailyCalories);
    case 'daily_steps_today':
      return const DailyGoalTarget(GoalMetric.dailySteps);
    case 'daily_protein_today':
      return const DailyGoalTarget(GoalMetric.dailyProtein);
    case 'daily_fat_today':
      return const DailyGoalTarget(GoalMetric.dailyFat);
    case 'daily_carbs_today':
      return const DailyGoalTarget(GoalMetric.dailyCarbs);
    case 'daily_fiber_today':
      return const DailyGoalTarget(GoalMetric.dailyFiber);
    case 'daily_sleep_today':
      return const DailyGoalTarget(GoalMetric.sleepHours);
    case 'daily_activity_today':
      return const DailyGoalTarget(GoalMetric.dailyActivityMins);
    case 'daily_weight_log_today':
      return const DailyGoalTarget(GoalMetric.targetWeight);
  }
  if (node is Quest && node.displayBucket == QuestDisplayBucket.combo) {
    return const ComboQuestTarget();
  }
  return null;
}
