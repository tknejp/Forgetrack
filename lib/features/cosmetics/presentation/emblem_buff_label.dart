// Pure helper that turns an [EmblemBuff] into a localized 1-line label
// rendered under emblem tiles in the cosmetics inventory. See
// `docs/emblem_buffs/archive/plan.md` Phase 3.
//
// Kept widget-free so it can be reused by both the inventory tile and
// the cosmetic details sheet, and unit-tested without pumping widgets.

import '../../../l10n/app_localizations.dart';
import '../../health_connect/domain/player_goal.dart';
import '../domain/emblem_buff.dart';

/// Localized 1-line summary of [buff] (e.g. "Bonus: +10% XP from daily
/// calories" / blanket variant). Returns `null` for buffs we cannot
/// summarise — currently none, but the nullable shape lets call sites
/// hide the line for purely cosmetic emblems uniformly with future
/// buff variants.
String? emblemBuffLabel(EmblemBuff buff, AppLocalizations l10n) {
  switch (buff) {
    case PerTargetEmblemBuff(:final target, :final percent):
      final metric = _targetLabel(target, l10n);
      return l10n.emblemBuffPerTarget(percent, metric);
    case BlanketEmblemBuff(:final percent):
      return l10n.emblemBuffBlanket(percent);
  }
}

String _targetLabel(EmblemTarget target, AppLocalizations l10n) {
  switch (target) {
    case DailyGoalTarget(:final metric):
      return _metricLabel(metric, l10n);
    case ComboQuestTarget():
      return l10n.emblemBuffComboTarget;
  }
}

/// Resolves the localized label rendered under an emblem tile for a
/// [DailyGoalTarget] metric.
///
/// `GoalMetric.targetWeight` returns [AppLocalizations.emblemBuffWeightLogTarget]
/// ("denní zápis váhy" / "daily weight log") rather than the shared
/// [AppLocalizations.goalTargetWeight] ("Cílová váha") — `targetWeight`
/// is the body-weight setting in Settings, but the matching emblem
/// (`emblem_mountain_crest`) actually buffs the daily weight-log claim
/// (`daily_weight_log_today`). Settings UI calls `goalTargetWeight`
/// directly without going through this resolver, so the split label is
/// confined to the emblem render path.
String _metricLabel(GoalMetric metric, AppLocalizations l10n) {
  switch (metric) {
    case GoalMetric.dailySteps:
      return l10n.goalDailySteps;
    case GoalMetric.targetWeight:
      return l10n.emblemBuffWeightLogTarget;
    case GoalMetric.dailyCalories:
      return l10n.goalDailyCalories;
    case GoalMetric.dailyProtein:
      return l10n.goalDailyProtein;
    case GoalMetric.dailyFat:
      return l10n.goalDailyFat;
    case GoalMetric.dailyCarbs:
      return l10n.goalDailyCarbs;
    case GoalMetric.dailyFiber:
      return l10n.goalDailyFiber;
    case GoalMetric.sleepHours:
      return l10n.goalSleepHours;
    case GoalMetric.weeklyActivityMins:
      return l10n.goalWeeklyActivity;
    case GoalMetric.dailyActivityMins:
      return l10n.goalDailyActivity;
  }
}
