import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/quest_policies.dart';

import '../../../../../shared/domain/rarity.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import 'quest_assets.dart';

/// Pilgrim's Path â€” the level-1 starter chapter.
///
/// Onboarding chapter that mirrors V1's "starter quest" set
/// (`kProgressionStarterQuestIds` = daily_steps_today + daily_sleep_today
/// + earn_first_reward). Sits at chapter slot 0 so a brand-new player
/// has a guided three-step tour of the core daily loop before the
/// Forest Trial unlocks at level 10. Finale drops `emblem_pilgrim_mark`,
/// which the cosmetic catalog already ships with art.
///
/// Step semantics use [Objective.baselineFromNodeId] so each
/// step starts counting from the moment the chain step actually
/// unlocked â€” a returning player who already has 100 daily completions
/// banked still has to walk / sleep / earn once after touching this
/// chapter to clear the steps.

const _chapterId = ChapterId('pilgrim_path');
const _chainId = ChainId('pilgrim_path');

List<Objective> pilgrimPathObjectives() {
  return const [
    Objective(
      id: const ObjectiveId('pilgrim_path_open_objective'),
      domain: ProgressionDomain.activity,
      metric: LevelMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      debugLabel: 'Pilgrim Path open â€” level >= 1 (auto-unlocked)',
    ),
    Objective(
      id: const ObjectiveId('pilgrim_path_first_steps_objective'),
      domain: ProgressionDomain.steps,
      metric: NodeCompletionsMetric(nodeId: ProgressionEntryId('daily_steps_today')),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      baselineFromNodeId: ProgressionEntryId('pilgrim_path_open'),
      debugLabel: 'Pilgrim Path step 1 â€” daily steps since open',
    ),
    Objective(
      id: const ObjectiveId('pilgrim_path_first_sleep_objective'),
      domain: ProgressionDomain.sleep,
      metric: NodeCompletionsMetric(nodeId: ProgressionEntryId('daily_sleep_today')),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      baselineFromNodeId: ProgressionEntryId('pilgrim_path_first_steps'),
      debugLabel: 'Pilgrim Path step 2 â€” daily sleep since step 1',
    ),
    // Step 3 used to be `RewardCountMetric()` baselined on step 2,
    // but that self-fulfils: claiming step 2 grants XP, which lands
    // a reward event the same tick â€” step 3 reads 100% the instant
    // step 2 finishes. Replaced with a "complete daily protein once
    // since unlock" check. Narratively this introduces the third
    // daily-loop pillar (steps + sleep already taught by steps 1 and
    // 2) â€” a fitting send-off before the player heads into the
    // Forest Trial chapter at level 10.
    Objective(
      id: const ObjectiveId('pilgrim_path_first_reward_objective'),
      domain: ProgressionDomain.nutrition,
      metric: NodeCompletionsMetric(nodeId: ProgressionEntryId('daily_protein_today')),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      baselineFromNodeId: ProgressionEntryId('pilgrim_path_first_sleep'),
      debugLabel: 'Pilgrim Path step 3 â€” daily protein since step 2',
    ),
    Objective(
      id: const ObjectiveId('pilgrim_path_finale_objective'),
      domain: ProgressionDomain.activity,
      metric: LevelMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      debugLabel: 'Pilgrim Path finale â€” level gate (prereqs gate the chain)',
    ),
  ];
}

List<ProgressionEntry> pilgrimPathNodes() {
  return [
    ChapterOpener(
      id: const ProgressionEntryId('pilgrim_path_open'),
      objectiveId: ObjectiveId('pilgrim_path_open_objective'),
      unlockConditions: const [LevelAtLeast(1)],
      titleKey: (l) => l.progQuestPilgrimPathOpenTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathOpenDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.chapterXp, amount: 40)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chainId,
      nextNodeIds: const [ProgressionEntryId('pilgrim_path_first_steps')],
      chainStepIcon: ChainStepIcon.opener,
      sortOrder: 200,
    ),
    ChapterStep(
      id: const ProgressionEntryId('pilgrim_path_first_steps'),
      objectiveId: ObjectiveId('pilgrim_path_first_steps_objective'),
      titleKey: (l) => l.progQuestPilgrimPathFirstStepsTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFirstStepsDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.chapterXp, amount: 60)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chainId,
      chainOrder: 1,
      prerequisiteNodeIds: const [ProgressionEntryId('pilgrim_path_open')],
      nextNodeIds: const [ProgressionEntryId('pilgrim_path_first_sleep')],
      chainStepLabelKey: (_) => '1',
      sortOrder: 201,
    ),
    ChapterStep(
      id: const ProgressionEntryId('pilgrim_path_first_sleep'),
      objectiveId: ObjectiveId('pilgrim_path_first_sleep_objective'),
      titleKey: (l) => l.progQuestPilgrimPathFirstSleepTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFirstSleepDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.chapterXp, amount: 60)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chainId,
      chainOrder: 2,
      prerequisiteNodeIds: const [ProgressionEntryId('pilgrim_path_first_steps')],
      nextNodeIds: const [ProgressionEntryId('pilgrim_path_first_reward')],
      chainStepLabelKey: (_) => '1',
      sortOrder: 202,
    ),
    ChapterStep(
      id: const ProgressionEntryId('pilgrim_path_first_reward'),
      objectiveId: ObjectiveId('pilgrim_path_first_reward_objective'),
      titleKey: (l) => l.progQuestPilgrimPathFirstRewardTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFirstRewardDesc,
      rewards: const [XpReward(sourceKind: RewardSourceKind.chapterXp, amount: 80)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chainId,
      chainOrder: 3,
      prerequisiteNodeIds: const [ProgressionEntryId('pilgrim_path_first_sleep')],
      nextNodeIds: const [ProgressionEntryId('pilgrim_path_finale')],
      chainStepLabelKey: (_) => '1',
      sortOrder: 203,
    ),
    ChapterFinale(
      id: const ProgressionEntryId('pilgrim_path_finale'),
      objectiveId: ObjectiveId('pilgrim_path_finale_objective'),
      titleKey: (l) => l.progQuestPilgrimPathFinaleTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFinaleDesc,
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.chapterXp, amount: 120),
        CosmeticReward(cosmeticId: CosmeticId('emblem_pilgrim_mark')),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chainId,
      chainOrder: 4,
      prerequisiteNodeIds: const [ProgressionEntryId('pilgrim_path_first_reward')],
      chainStepIcon: ChainStepIcon.finale,
      sortOrder: 204,
    ),
  ];
}