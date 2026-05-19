import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// **DennÃ­ quest** templates â€” one rotating themed bonus quest per
/// day, picked deterministically from this pool by a date hash.
/// Higher XP than the simple "DENNÃ CÃLE" tier (those are pure
/// metric thresholds â€” steps, calories, etc.); this tier is the
/// flavour layer that asks for *combinations* of daily atoms with
/// a small narrative twist.
///
/// **Design rules.**
/// - Every template uses [TodayCompletionsAmongMetric] against the
///   existing daily-atom node ids so no new metric kind / engine
///   plumbing is needed.
/// - All templates share `comboPoolId: ComboPoolId('daily_combo_pool')` so they
///   feed the `combo_victory_10` achievement alongside the combo
///   chain.
/// - `LifetimeScope` so completion is once-and-done per template â€”
///   the daily *picker* (provider) rotates which template surfaces
///   today, not the engine's per-period reset. If a template
///   resurfaces months later, the player can claim it again only
///   if it hasn't been completed before; otherwise it stays in the
///   "Completed quests" archive.
/// - Manual claim (the player taps "Vyzvednout" to confirm).

const _comboPoolId = ComboPoolId('daily_combo_pool');

const _nutriAtoms = <ProgressionEntryId>[
  ProgressionEntryId('daily_calories_today'),
  ProgressionEntryId('daily_protein_today'),
  ProgressionEntryId('daily_carbs_today'),
  ProgressionEntryId('daily_fat_today'),
  ProgressionEntryId('daily_fiber_today'),
];

const _allDailyAtoms = <ProgressionEntryId>[
  ProgressionEntryId('daily_steps_today'),
  ProgressionEntryId('daily_calories_today'),
  ProgressionEntryId('daily_protein_today'),
  ProgressionEntryId('daily_carbs_today'),
  ProgressionEntryId('daily_fat_today'),
  ProgressionEntryId('daily_fiber_today'),
  ProgressionEntryId('daily_sleep_today'),
  ProgressionEntryId('daily_activity_today'),
];

List<Objective> dailyChallengeObjectives(
  EngineCatalogContext context,
) {
  return const [
    Objective(
      id: const ObjectiveId('daily_challenge_nutri_triple_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _nutriAtoms),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: const ObjectiveId('daily_challenge_active_day_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_steps_today'), ProgressionEntryId('daily_activity_today')],
      ),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: const ObjectiveId('daily_challenge_full_plate_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _nutriAtoms),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5,
    ),
    Objective(
      id: const ObjectiveId('daily_challenge_recovery_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [ProgressionEntryId('daily_sleep_today'), ProgressionEntryId('daily_protein_today')],
      ),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2,
    ),
    Objective(
      id: const ObjectiveId('daily_challenge_triple_combo_obj'),
      metric: TodayCompletionsAmongMetric(
        nodeIds: [
          ProgressionEntryId('daily_steps_today'),
          ProgressionEntryId('daily_sleep_today'),
          ProgressionEntryId('daily_protein_today'),
        ],
      ),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
    ),
    Objective(
      id: const ObjectiveId('daily_challenge_balanced_obj'),
      metric: TodayCompletionsAmongMetric(nodeIds: _allDailyAtoms),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 4,
    ),
  ];
}

List<ProgressionEntry> dailyChallenges() {
  return [
    DailyChallenge(
      id: const ProgressionEntryId('daily_challenge_nutri_triple'),
      objectiveId: ObjectiveId('daily_challenge_nutri_triple_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progDailyChallengeNutriTripleTitle,
      descriptionKey: (l) => l.progDailyChallengeNutriTripleDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 200)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
    ),
    DailyChallenge(
      id: const ProgressionEntryId('daily_challenge_active_day'),
      objectiveId: ObjectiveId('daily_challenge_active_day_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progDailyChallengeActiveDayTitle,
      descriptionKey: (l) => l.progDailyChallengeActiveDayDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 180)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
      assetKey: questAssetActivity,
      comboPoolId: _comboPoolId,
    ),
    DailyChallenge(
      id: const ProgressionEntryId('daily_challenge_full_plate'),
      objectiveId: ObjectiveId('daily_challenge_full_plate_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progDailyChallengeFullPlateTitle,
      descriptionKey: (l) => l.progDailyChallengeFullPlateDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 280)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetNutrition,
      comboPoolId: _comboPoolId,
    ),
    DailyChallenge(
      id: const ProgressionEntryId('daily_challenge_recovery'),
      objectiveId: ObjectiveId('daily_challenge_recovery_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progDailyChallengeRecoveryTitle,
      descriptionKey: (l) => l.progDailyChallengeRecoveryDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 160)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
      assetKey: questAssetStreak,
      comboPoolId: _comboPoolId,
    ),
    DailyChallenge(
      id: const ProgressionEntryId('daily_challenge_triple_combo'),
      objectiveId: ObjectiveId('daily_challenge_triple_combo_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progDailyChallengeTripleComboTitle,
      descriptionKey: (l) => l.progDailyChallengeTripleComboDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 220)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
    ),
    DailyChallenge(
      id: const ProgressionEntryId('daily_challenge_balanced'),
      objectiveId: ObjectiveId('daily_challenge_balanced_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progDailyChallengeBalancedTitle,
      descriptionKey: (l) => l.progDailyChallengeBalancedDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 250)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetDoubleWin,
      comboPoolId: _comboPoolId,
    ),
  ];
}
