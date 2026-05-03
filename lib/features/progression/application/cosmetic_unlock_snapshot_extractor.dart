import '../../cosmetics/domain/cosmetic_unlock_snapshot.dart';
import '../domain/perfect_period_evaluator.dart';
import '../domain/progression_models.dart';
import '../domain/progression_quest_catalog.dart';
import 'progression_engine.dart';

/// Builds a [CosmeticUnlockSnapshot] from a [ProgressionEngineState] plus the
/// player's currently-owned cosmetic ids. Pure function (no I/O, no async).
///
/// Quest counts are derived from the durable `questRewardGrants` ledger
/// (one row per quest completion, persisted in Isar — see
/// `ProgressionLedgerSnapshot`). Quest definitions are joined in to map
/// each grant to its [ProgressionQuestCategory] so we can count daily vs
/// weekly without trusting transient UI state.
///
/// Active days are derived from distinct `progressionDate(period.start)`
/// values across [state.evaluations] — the same set
/// `_trackedDaysElapsed` already trusts in the quest evaluator.
class CosmeticUnlockSnapshotExtractor {
  CosmeticUnlockSnapshotExtractor({
    ProgressionQuestCatalog questCatalog = const ProgressionQuestCatalog(),
    PerfectPeriodEvaluator perfectPeriodEvaluator =
        const RealPerfectPeriodEvaluator(),
  })  : _categoryById = _buildCategoryIndex(questCatalog),
        _perfectPeriodEvaluator = perfectPeriodEvaluator;

  final Map<String, ProgressionQuestCategory> _categoryById;
  final PerfectPeriodEvaluator _perfectPeriodEvaluator;

  static Map<String, ProgressionQuestCategory> _buildCategoryIndex(
    ProgressionQuestCatalog catalog,
  ) {
    final out = <String, ProgressionQuestCategory>{};
    for (final def in catalog.build()) {
      out[def.id] = def.category;
    }
    return out;
  }

  CosmeticUnlockSnapshot extract({
    required ProgressionEngineState state,
    required Set<String> ownedCosmeticIds,
  }) {
    var dailyCount = 0;
    var weeklyCount = 0;
    var totalCount = 0;
    for (final grant in state.questRewardGrants) {
      totalCount++;
      final category = _categoryById[grant.questId];
      if (category == ProgressionQuestCategory.daily) {
        dailyCount++;
      } else if (category == ProgressionQuestCategory.weekly) {
        weeklyCount++;
      }
    }

    final activeDays = <DateTime>{
      for (final evaluation in state.evaluations)
        progressionDate(evaluation.period.start),
    }.length;

    return CosmeticUnlockSnapshot(
      level: state.profile.level,
      activeDaysCount: activeDays,
      completedDailyQuests: dailyCount,
      completedWeeklyQuests: weeklyCount,
      totalCompletedQuests: totalCount,
      firstDailyQuestEver: dailyCount >= 1,
      firstWeeklyQuestEver: weeklyCount >= 1,
      perfectDaysCount:
          _perfectPeriodEvaluator.countPerfectDays(state.evaluations),
      perfectWeeksCount:
          _perfectPeriodEvaluator.countPerfectWeeks(state.evaluations),
      ownedCosmeticIds: ownedCosmeticIds,
    );
  }
}
