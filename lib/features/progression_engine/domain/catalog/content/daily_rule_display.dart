import '../../../../../l10n/app_localizations.dart';
import '../../localized_text.dart';

/// L10n bindings for the daily/weekly rule ids that flow through V2
/// objectives ([RewardCountMetric.ruleId] / [StreakDaysMetric.ruleId]).
///
/// Replaces the V1 `ProgressionRuleCatalog.titleForId` / `unitForId`
/// helpers — V2 objectives already encode metric / scope / target /
/// reward XP themselves, so all we need from "rules" is the display
/// label and the unit string for friend-card / leaderboard / hero
/// surfaces.
abstract final class DailyRuleDisplay {
  /// Localised title for a rule id, or `null` when the id is unknown.
  /// Callers fall back to the id itself or a generic label.
  static LocalizedText? titleFor(String ruleId) => _titles[ruleId];

  /// Localised unit suffix for a rule id (steps / kcal / g / min …),
  /// or `null` when no canonical unit applies. Used by the resolver's
  /// `compactSummary` to render "10k steps" / "150 g" / etc.
  static LocalizedText? unitFor(String ruleId) => _units[ruleId];

  static const Map<String, LocalizedText> _titles = {
    'daily_steps': _ruleDailySteps,
    'daily_calories': _ruleDailyCalories,
    'daily_protein': _ruleDailyProtein,
    'daily_sleep': _ruleDailySleep,
    'daily_activity': _ruleDailyActivity,
    'daily_weight_log': _ruleDailyWeightLog,
    'weekly_activity': _ruleWeeklyActivity,
  };

  static const Map<String, LocalizedText> _units = {
    'daily_steps': _unitSteps,
    'daily_calories': _unitKcal,
    'daily_protein': _unitGrams,
    'daily_sleep': _unitMinutes,
    'daily_activity': _unitMinutes,
    'weekly_activity': _unitMinutes,
    // daily_weight_log has no canonical unit (it's a count-of-1).
  };
}

String _ruleDailySteps(AppLocalizations l) => l.progRuleDailySteps;
String _ruleDailyCalories(AppLocalizations l) => l.progRuleDailyCalories;
String _ruleDailyProtein(AppLocalizations l) => l.progRuleDailyProtein;
String _ruleDailySleep(AppLocalizations l) => l.progRuleDailySleep;
String _ruleDailyActivity(AppLocalizations l) => l.activitiesActiveMins;
String _ruleDailyWeightLog(AppLocalizations l) => l.progRuleDailyWeightLog;
String _ruleWeeklyActivity(AppLocalizations l) => l.progRuleWeeklyActivity;

String _unitSteps(AppLocalizations l) => l.goalUnitSteps;
String _unitKcal(AppLocalizations l) => l.goalUnitKcal;
String _unitGrams(AppLocalizations l) => l.goalUnitG;
String _unitMinutes(AppLocalizations l) => l.goalUnitMins;
