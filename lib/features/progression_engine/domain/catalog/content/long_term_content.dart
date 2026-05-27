import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/quest_policies.dart';

import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'quest_assets.dart';

/// Long-term goal chains — multi-month / lifetime quests that share
/// each step's objective with the matching achievement node (V2
/// design rule: quest + achievement with the same goal both reference
/// the same Objective; no duplicate evaluation).
///
/// Three chains mirror V1's long-term display:
///
/// - **lifetime_steps** (100K → 500K → 1M → 5M → 10M). Every step's
///   objective already lives in `steps_content`; the matching
///   `steps_total_*` achievement is the companion that drops the
///   cosmetic / relic / frame rewards.
/// - **xp_milestones** (500 → 2K → 5K → 25K → 100K → 1M XP). 500 / 2K /
///   5K / 25K are new objectives; 100K / 1M reuse `meta_content`'s
///   `lifetime_xp_100k` / `lifetime_xp_1m` with `xp_100000` /
///   `xp_1000000` as companion achievements.
/// - **reward_hunter** (first → 25 → 100 → 250). First / 250 are new
///   objectives; 25 / 100 reuse `meta_content`'s `reward_count_25` /
///   `reward_count_100` with `reward_hunter_25` / `reward_hunter_100`
///   as companion achievements.
///
/// All steps are manual-claim — the player taps the gold pill to grant
/// XP once the objective is satisfied. The matching achievements stay
/// auto-claim so their cosmetics land immediately.
///
/// **No `prerequisiteNodeIds`** on these threshold chains. Each step
/// is the same metric at a higher target (`StepsMetric + LifetimeScope`,
/// `TotalXpMetric + LifetimeScope`, `RewardCountMetric`), so reaching
/// 100k XP logically implies passing 500 / 2k / 5k / 25k — the chain
/// order is purely a display convenience. Adding `NodeCompleted`
/// prereqs would gate downstream steps behind the *claim* of each
/// previous step (manual-claim quests only emit `NodeCompletionEvent`
/// after the player taps the pill), which means a player at 100k+ XP
/// would still see 5k as "locked" because 500 hasn't been claimed yet.
/// Chapter chains (`chapter_content.dart`) keep their prereqs
/// because those steps are genuine sequential dependencies.

const _lifetimeStepsChain = ChainId('lifetime_steps');
const _xpMilestonesChain = ChainId('xp_milestones');
const _rewardHunterChain = ChainId('reward_hunter');

/// Objectives unique to the long-term chains. XP / reward objectives
/// already in `meta_content` and step objectives already in
/// `steps_content` are reused; only the missing endpoints are added
/// here.
List<Objective> longTermObjectives() {
  return const [
    // XP milestones not already in meta_content.
    Objective(
      id: const ObjectiveId('lifetime_xp_500'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 500,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_2000'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 2000,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_5000'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5000,
    ),
    Objective(
      id: const ObjectiveId('lifetime_xp_25000'),
      metric: TotalXpMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 25000,
    ),
    // Reward-count milestones not already in meta_content.
    Objective(
      id: const ObjectiveId('reward_count_first'),
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
    Objective(
      id: const ObjectiveId('reward_count_250'),
      metric: RewardCountMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 250,
    ),
  ];
}

List<ProgressionEntry> longTermNodes() {
  return [
    // ── Lifetime steps chain ────────────────────────────────────────
    LongTermQuest(
      id: const ProgressionEntryId('long_term_steps_100k'),
      objectiveId: ObjectiveId('lifetime_steps_100k'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progAchievementSteps100kTitle,
      descriptionKey: (l) => l.progAchievementSteps100kDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 120)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetSteps,
      chainId: _lifetimeStepsChain,
      chainOrder: 0,
      chainStepIcon: ChainStepIcon.opener,
      nextNodeIds: const [ProgressionEntryId('long_term_steps_500k')],
      sortOrder: 1100,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_steps_500k'),
      objectiveId: ObjectiveId('lifetime_steps_500k'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progAchievementSteps500kTitle,
      descriptionKey: (l) => l.progAchievementSteps500kDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 360)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
      assetKey: questAssetSteps,
      chainId: _lifetimeStepsChain,
      chainOrder: 1,
      chainStepLabelKey: (_) => '500K',
      nextNodeIds: const [ProgressionEntryId('long_term_steps_1m')],
      sortOrder: 1101,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_steps_1m'),
      objectiveId: ObjectiveId('lifetime_steps_1m'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progAchievementSteps1000000Title,
      descriptionKey: (l) => l.progAchievementSteps1000000Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 720)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
      assetKey: questAssetSteps,
      chainId: _lifetimeStepsChain,
      chainOrder: 2,
      chainStepLabelKey: (_) => '1M',
      nextNodeIds: const [ProgressionEntryId('long_term_steps_5m')],
      sortOrder: 1102,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_steps_5m'),
      objectiveId: ObjectiveId('lifetime_steps_5m'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progAchievementSteps5000000Title,
      descriptionKey: (l) => l.progAchievementSteps5000000Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 1200)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
      assetKey: questAssetSteps,
      chainId: _lifetimeStepsChain,
      chainOrder: 3,
      chainStepLabelKey: (_) => '5M',
      nextNodeIds: const [ProgressionEntryId('long_term_steps_10m')],
      sortOrder: 1103,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_steps_10m'),
      objectiveId: ObjectiveId('lifetime_steps_10m'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progAchievementSteps10000000Title,
      descriptionKey: (l) => l.progAchievementSteps10000000Desc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 2000)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
      assetKey: questAssetSteps,
      chainId: _lifetimeStepsChain,
      chainOrder: 4,
      chainStepIcon: ChainStepIcon.finale,
      sortOrder: 1104,
    ),

    // ── XP milestones chain ─────────────────────────────────────────
    LongTermQuest(
      id: const ProgressionEntryId('long_term_reach_500_xp'),
      objectiveId: ObjectiveId('lifetime_xp_500'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach500XpTitle,
      descriptionKey: (l) => l.progQuestReach500XpDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 120)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetActivity,
      chainId: _xpMilestonesChain,
      chainOrder: 0,
      chainStepIcon: ChainStepIcon.opener,
      nextNodeIds: const [ProgressionEntryId('long_term_reach_2000_xp')],
      sortOrder: 1200,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_reach_2000_xp'),
      objectiveId: ObjectiveId('lifetime_xp_2000'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach2000XpTitle,
      descriptionKey: (l) => l.progQuestReach2000XpDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 180)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetActivity,
      chainId: _xpMilestonesChain,
      chainOrder: 1,
      chainStepLabelKey: (_) => '2K',
      nextNodeIds: const [ProgressionEntryId('long_term_reach_5000_xp')],
      sortOrder: 1201,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_reach_5000_xp'),
      objectiveId: ObjectiveId('lifetime_xp_5000'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach5000XpTitle,
      descriptionKey: (l) => l.progQuestReach5000XpDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 260)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetActivity,
      chainId: _xpMilestonesChain,
      chainOrder: 2,
      chainStepLabelKey: (_) => '5K',
      nextNodeIds: const [ProgressionEntryId('long_term_reach_25000_xp')],
      sortOrder: 1202,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_reach_25000_xp'),
      objectiveId: ObjectiveId('lifetime_xp_25000'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach25000XpTitle,
      descriptionKey: (l) => l.progQuestReach25000XpDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 420)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetActivity,
      chainId: _xpMilestonesChain,
      chainOrder: 3,
      chainStepLabelKey: (_) => '25K',
      nextNodeIds: const [ProgressionEntryId('long_term_reach_100000_xp')],
      sortOrder: 1203,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_reach_100000_xp'),
      objectiveId: ObjectiveId('lifetime_xp_100k'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach100000XpTitle,
      descriptionKey: (l) => l.progQuestReach100000XpDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 640)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetActivity,
      chainId: _xpMilestonesChain,
      chainOrder: 4,
      chainStepLabelKey: (_) => '100K',
      nextNodeIds: const [ProgressionEntryId('long_term_reach_1000000_xp')],
      sortOrder: 1204,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_reach_1000000_xp'),
      objectiveId: ObjectiveId('lifetime_xp_1m'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestReach1000000XpTitle,
      descriptionKey: (l) => l.progQuestReach1000000XpDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 1000)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
      assetKey: questAssetActivity,
      chainId: _xpMilestonesChain,
      chainOrder: 5,
      chainStepIcon: ChainStepIcon.finale,
      sortOrder: 1205,
    ),

    // ── Reward hunter chain ─────────────────────────────────────────
    LongTermQuest(
      id: const ProgressionEntryId('long_term_earn_first_reward'),
      objectiveId: ObjectiveId('reward_count_first'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestEarnFirstRewardTitle,
      descriptionKey: (l) => l.progQuestEarnFirstRewardDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 60)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetActivity,
      chainId: _rewardHunterChain,
      chainOrder: 0,
      chainStepIcon: ChainStepIcon.opener,
      nextNodeIds: const [ProgressionEntryId('long_term_earn_25_rewards')],
      sortOrder: 1300,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_earn_25_rewards'),
      objectiveId: ObjectiveId('reward_count_25'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestEarn25RewardsTitle,
      descriptionKey: (l) => l.progQuestEarn25RewardsDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 180)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetActivity,
      chainId: _rewardHunterChain,
      chainOrder: 1,
      chainStepLabelKey: (_) => '25',
      nextNodeIds: const [ProgressionEntryId('long_term_earn_100_rewards')],
      sortOrder: 1301,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_earn_100_rewards'),
      objectiveId: ObjectiveId('reward_count_100'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestEarn100RewardsTitle,
      descriptionKey: (l) => l.progQuestEarn100RewardsDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 320)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.epic,
      assetKey: questAssetActivity,
      chainId: _rewardHunterChain,
      chainOrder: 2,
      chainStepLabelKey: (_) => '100',
      nextNodeIds: const [ProgressionEntryId('long_term_earn_250_rewards')],
      sortOrder: 1302,
    ),
    LongTermQuest(
      id: const ProgressionEntryId('long_term_earn_250_rewards'),
      objectiveId: ObjectiveId('reward_count_250'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (l) => l.progQuestEarn250RewardsTitle,
      descriptionKey: (l) => l.progQuestEarn250RewardsDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.questXp, amount: 520)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.legendary,
      assetKey: questAssetActivity,
      chainId: _rewardHunterChain,
      chainOrder: 3,
      chainStepIcon: ChainStepIcon.finale,
      sortOrder: 1303,
    ),
  ];
}