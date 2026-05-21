import 'cosmetic_unlock_snapshot.dart';

/// A single named predicate over a [CosmeticUnlockSnapshot]. Rules are built
/// from one or more conditions joined with logical AND.
///
/// The `id` and `descriptionKey` are exposed so a future hidden/partial-reveal
/// UI can render "1/2 conditions met — still need Frost Shard" without having
/// to re-derive condition semantics.
class CosmeticUnlockCondition {
  const CosmeticUnlockCondition({
    required this.id,
    required this.test,
    this.descriptionKey,
  });

  final String id; // lint-ignore: untyped-id — author-supplied condition key inside a CosmeticUnlockRule
  final String? descriptionKey;
  final bool Function(CosmeticUnlockSnapshot snapshot) test;
}

/// A declarative unlock rule: when every condition passes for a player, the
/// referenced cosmetic is granted. OR-style rules are expressed by listing
/// two rules with the same `cosmeticId` — the evaluator deduplicates by id.
///
/// `sourceType` flows through to `CosmeticsProvider.unlock` for audit
/// (the same pipeline that records achievement-driven unlocks).
/// `sourceId` is optional — present when the rule's source carries a
/// disambiguating reference (e.g. the granting achievement id for a
/// reward-style unlock), null when `(cosmeticId, sourceType)` is already
/// 1:1 with the rule (e.g. compound companion rules).
class CosmeticUnlockRule {
  const CosmeticUnlockRule({
    required this.cosmeticId,
    required this.sourceType,
    required this.conditions,
    this.sourceId,
    this.isHidden = false,
  });

  final String cosmeticId; // lint-ignore: untyped-id — mirrors CosmeticId in the unlock rule
  final String sourceType;
  final String? sourceId; // lint-ignore: untyped-id — opaque rule-author-supplied source key (quest/achievement/level/...), null for 1:1 mappings
  final List<CosmeticUnlockCondition> conditions;

  /// When true, partial-progress UI should not surface this rule even if it
  /// has more than one condition. Defaults to `false`; compound rules can
  /// flip it to keep prestige rewards a surprise.
  final bool isHidden;

  bool isSatisfied(CosmeticUnlockSnapshot snapshot) =>
      conditions.every((c) => c.test(snapshot));

  int satisfiedCount(CosmeticUnlockSnapshot snapshot) =>
      conditions.where((c) => c.test(snapshot)).length;
}

/// Builders for the predicates used in [kCosmeticUnlockRules]. Each returns
/// a [CosmeticUnlockCondition] whose `id` is stable across releases so
/// future UI can render localised hints.
class Cond {
  Cond._();

  static CosmeticUnlockCondition firstDailyQuest() => CosmeticUnlockCondition(
        id: 'first_daily_quest',
        test: (s) => s.firstDailyQuestEver,
      );

  static CosmeticUnlockCondition firstWeeklyQuest() => CosmeticUnlockCondition(
        id: 'first_weekly_quest',
        test: (s) => s.firstWeeklyQuestEver,
      );

  static CosmeticUnlockCondition dailyQuestsCompletedAtLeast(int target) =>
      CosmeticUnlockCondition(
        id: 'daily_quests_completed_at_least_$target',
        test: (s) => s.completedDailyQuests >= target,
      );

  static CosmeticUnlockCondition weeklyQuestsCompletedAtLeast(int target) =>
      CosmeticUnlockCondition(
        id: 'weekly_quests_completed_at_least_$target',
        test: (s) => s.completedWeeklyQuests >= target,
      );

  static CosmeticUnlockCondition totalQuestsCompletedAtLeast(int target) =>
      CosmeticUnlockCondition(
        id: 'total_quests_completed_at_least_$target',
        test: (s) => s.totalCompletedQuests >= target,
      );

  static CosmeticUnlockCondition activeDaysAtLeast(int target) =>
      CosmeticUnlockCondition(
        id: 'active_days_at_least_$target',
        test: (s) => s.activeDaysCount >= target,
      );

  static CosmeticUnlockCondition perfectDaysAtLeast(int target) =>
      CosmeticUnlockCondition(
        id: 'perfect_days_at_least_$target',
        test: (s) => s.perfectDaysCount >= target,
      );

  static CosmeticUnlockCondition perfectWeeksAtLeast(int target) =>
      CosmeticUnlockCondition(
        id: 'perfect_weeks_at_least_$target',
        test: (s) => s.perfectWeeksCount >= target,
      );

  static CosmeticUnlockCondition ownsCosmetic(String cosmeticId) =>
      CosmeticUnlockCondition(
        id: 'owns_$cosmeticId',
        test: (s) => s.ownedCosmeticIds.contains(cosmeticId),
      );

  static CosmeticUnlockCondition atLevel(int level) => CosmeticUnlockCondition(
        id: 'level_at_least_$level',
        test: (s) => s.level >= level,
      );
}
