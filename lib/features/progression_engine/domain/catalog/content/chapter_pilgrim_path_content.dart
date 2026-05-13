import 'package:flutter/material.dart' show Icons;

import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import 'quest_assets.dart';

/// Pilgrim's Path — the level-1 starter chapter.
///
/// Onboarding chapter that mirrors V1's "starter quest" set
/// (`kProgressionStarterQuestIds` = daily_steps_today + daily_sleep_today
/// + earn_first_reward). Sits at chapter slot 0 so a brand-new player
/// has a guided three-step tour of the core daily loop before the
/// Forest Trial unlocks at level 10. Finale drops `emblem_pilgrim_mark`,
/// which the cosmetic catalog already ships with art.
///
/// Step semantics use [ObjectiveDefinition.baselineFromNodeId] so each
/// step starts counting from the moment the chain step actually
/// unlocked — a returning player who already has 100 daily completions
/// banked still has to walk / sleep / earn once after touching this
/// chapter to clear the steps.

const _chapterId = 'pilgrim_path';

List<ObjectiveDefinition> pilgrimPathObjectives() {
  return const [
    ObjectiveDefinition(
      id: 'pilgrim_path_open_objective',
      domain: ProgressionDomain.activity,
      metric: LevelMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      debugLabel: 'Pilgrim Path open — level >= 1 (auto-unlocked)',
    ),
    ObjectiveDefinition(
      id: 'pilgrim_path_first_steps_objective',
      domain: ProgressionDomain.steps,
      metric: NodeCompletionsMetric(nodeId: 'daily_steps_today'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      baselineFromNodeId: 'pilgrim_path_open',
      debugLabel: 'Pilgrim Path step 1 — daily steps since open',
    ),
    ObjectiveDefinition(
      id: 'pilgrim_path_first_sleep_objective',
      domain: ProgressionDomain.sleep,
      metric: NodeCompletionsMetric(nodeId: 'daily_sleep_today'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      baselineFromNodeId: 'pilgrim_path_first_steps',
      debugLabel: 'Pilgrim Path step 2 — daily sleep since step 1',
    ),
    // Step 3 used to be `RewardCountMetric()` baselined on step 2,
    // but that self-fulfils: claiming step 2 grants XP, which lands
    // a reward event the same tick — step 3 reads 100% the instant
    // step 2 finishes. Replaced with a "complete daily protein once
    // since unlock" check. Narratively this introduces the third
    // daily-loop pillar (steps + sleep already taught by steps 1 and
    // 2) — a fitting send-off before the player heads into the
    // Forest Trial chapter at level 10.
    ObjectiveDefinition(
      id: 'pilgrim_path_first_reward_objective',
      domain: ProgressionDomain.nutrition,
      metric: NodeCompletionsMetric(nodeId: 'daily_protein_today'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      baselineFromNodeId: 'pilgrim_path_first_sleep',
      debugLabel: 'Pilgrim Path step 3 — daily protein since step 2',
    ),
    ObjectiveDefinition(
      id: 'pilgrim_path_finale_objective',
      domain: ProgressionDomain.activity,
      metric: LevelMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
      debugLabel: 'Pilgrim Path finale — level gate (prereqs gate the chain)',
    ),
  ];
}

List<ProgressionNode> pilgrimPathNodes() {
  return [
    ChapterOpenerNode(
      id: 'pilgrim_path_open',
      objectiveId: 'pilgrim_path_open_objective',
      unlockConditions: const [LevelAtLeast(1)],
      titleKey: (l) => l.progQuestPilgrimPathOpenTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathOpenDesc,
      rewards: const [XpReward(amount: 40)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      nextNodeIds: const ['pilgrim_path_first_steps'],
      chainStepIcon: Icons.play_arrow_rounded,
      sortOrder: 200,
    ),
    ChapterStepNode(
      id: 'pilgrim_path_first_steps',
      objectiveId: 'pilgrim_path_first_steps_objective',
      titleKey: (l) => l.progQuestPilgrimPathFirstStepsTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFirstStepsDesc,
      rewards: const [XpReward(amount: 60)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 1,
      prerequisiteNodeIds: const ['pilgrim_path_open'],
      nextNodeIds: const ['pilgrim_path_first_sleep'],
      chainStepLabelKey: (_) => '1',
      sortOrder: 201,
    ),
    ChapterStepNode(
      id: 'pilgrim_path_first_sleep',
      objectiveId: 'pilgrim_path_first_sleep_objective',
      titleKey: (l) => l.progQuestPilgrimPathFirstSleepTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFirstSleepDesc,
      rewards: const [XpReward(amount: 60)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 2,
      prerequisiteNodeIds: const ['pilgrim_path_first_steps'],
      nextNodeIds: const ['pilgrim_path_first_reward'],
      chainStepLabelKey: (_) => '1',
      sortOrder: 202,
    ),
    ChapterStepNode(
      id: 'pilgrim_path_first_reward',
      objectiveId: 'pilgrim_path_first_reward_objective',
      titleKey: (l) => l.progQuestPilgrimPathFirstRewardTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFirstRewardDesc,
      rewards: const [XpReward(amount: 80)],
      contentTags: const [ContentTag.core],
      rarity: Rarity.common,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 3,
      prerequisiteNodeIds: const ['pilgrim_path_first_sleep'],
      nextNodeIds: const ['pilgrim_path_finale'],
      chainStepLabelKey: (_) => '1',
      sortOrder: 203,
    ),
    ChapterFinaleNode(
      id: 'pilgrim_path_finale',
      objectiveId: 'pilgrim_path_finale_objective',
      titleKey: (l) => l.progQuestPilgrimPathFinaleTitle,
      descriptionKey: (l) => l.progQuestPilgrimPathFinaleDesc,
      rewards: const [
        XpReward(amount: 120),
        CosmeticReward(cosmeticId: 'emblem_pilgrim_mark'),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.uncommon,
      assetKey: questAssetPilgrimPathIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 4,
      prerequisiteNodeIds: const ['pilgrim_path_first_reward'],
      chainStepIcon: Icons.shield_rounded,
      sortOrder: 204,
    ),
  ];
}
