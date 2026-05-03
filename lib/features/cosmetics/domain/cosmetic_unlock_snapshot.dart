/// Read-only data the rule evaluator inspects to decide which cosmetics to
/// unlock. Built once per dispatcher pass by progression — see
/// `lib/features/progression/application/cosmetic_unlock_snapshot_extractor.dart`.
///
/// Intentionally minimal: step totals, streaks, monthly windows, and level
/// milestones are unlocked through the achievement reward table (Tier 1) and
/// don't need fields here. The snapshot only carries signals the achievement
/// engine cannot express today.
///
/// `level` and `ownedCosmeticIds` are present for compound rules
/// (e.g. "level 100 AND owns relic_dragon_scale").
class CosmeticUnlockSnapshot {
  const CosmeticUnlockSnapshot({
    required this.level,
    required this.activeDaysCount,
    required this.completedDailyQuests,
    required this.completedWeeklyQuests,
    required this.totalCompletedQuests,
    required this.firstDailyQuestEver,
    required this.firstWeeklyQuestEver,
    required this.perfectDaysCount,
    required this.perfectWeeksCount,
    required this.ownedCosmeticIds,
  });

  /// Used only for compound conditions; level-only unlocks live in the
  /// achievement reward table.
  final int level;

  /// Distinct calendar days for which a `ProgressionEvaluation` exists.
  /// Approximates "days the player engaged" without inventing a new metric.
  final int activeDaysCount;

  /// Lifetime counts derived from the durable `questRewardGrants` ledger.
  final int completedDailyQuests;
  final int completedWeeklyQuests;
  final int totalCompletedQuests;

  final bool firstDailyQuestEver;
  final bool firstWeeklyQuestEver;

  /// Returned by `PerfectPeriodEvaluator`. The placeholder implementation
  /// returns 0; rules referencing these simply won't fire until a real
  /// implementation lands.
  final int perfectDaysCount;
  final int perfectWeeksCount;

  /// Cosmetics the player already owns at the start of the current pass.
  /// Tier-2 rules reference this for compound conditions and to avoid
  /// double-granting (the evaluator also pre-filters on this).
  final Set<String> ownedCosmeticIds;

  /// Convenience for tests / future tooling.
  CosmeticUnlockSnapshot copyWith({
    int? level,
    int? activeDaysCount,
    int? completedDailyQuests,
    int? completedWeeklyQuests,
    int? totalCompletedQuests,
    bool? firstDailyQuestEver,
    bool? firstWeeklyQuestEver,
    int? perfectDaysCount,
    int? perfectWeeksCount,
    Set<String>? ownedCosmeticIds,
  }) {
    return CosmeticUnlockSnapshot(
      level: level ?? this.level,
      activeDaysCount: activeDaysCount ?? this.activeDaysCount,
      completedDailyQuests: completedDailyQuests ?? this.completedDailyQuests,
      completedWeeklyQuests:
          completedWeeklyQuests ?? this.completedWeeklyQuests,
      totalCompletedQuests: totalCompletedQuests ?? this.totalCompletedQuests,
      firstDailyQuestEver: firstDailyQuestEver ?? this.firstDailyQuestEver,
      firstWeeklyQuestEver: firstWeeklyQuestEver ?? this.firstWeeklyQuestEver,
      perfectDaysCount: perfectDaysCount ?? this.perfectDaysCount,
      perfectWeeksCount: perfectWeeksCount ?? this.perfectWeeksCount,
      ownedCosmeticIds: ownedCosmeticIds ?? this.ownedCosmeticIds,
    );
  }
}
