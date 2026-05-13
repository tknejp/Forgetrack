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

// Chapter id used by both the catalog and the screen to look up the
// background image. Keep in sync with [chapterBgAssetFor].
const _chapterId = 'forest_trial';

/// Forest Trial chapter — pilot port of a V1 journey chapter.
///
/// Shape mirrors the V1 monolith: one auto-claim "open" quest gated by
/// player level, three manual-claim "step" quests that share the
/// chapter chain via [QuestNode.prerequisiteNodeIds] /
/// [QuestNode.nextNodeIds], and a manual-claim finale that drops the
/// chapter emblem (cosmetic reward).
///
/// Other V1 chapters (ruins_discipline, mine_descent, …) are deferred
/// until this pattern proves itself end-to-end in the V2 quests
/// screen.
List<ObjectiveDefinition> forestTrialObjectives() {
  return const [
    // Open: satisfied automatically once the player reaches level 10.
    ObjectiveDefinition(
      id: 'forest_trial_open_objective',
      domain: ProgressionDomain.activity,
      metric: LevelMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 10,
      debugLabel: 'Forest Trial open — level >= 10',
    ),
    // Step 1: 5 daily-steps completions *after* the chapter opens.
    // The `baselineFromNodeId` makes the engine count only daily
    // completions banked after `forest_trial_open` cleared (player
    // hit level 10 and the auto-claim fired). Without this, a
    // late-arriving level-10 player would auto-finish step 1 the
    // moment the chapter unlocked just because they already had 5+
    // daily step completions on the books.
    ObjectiveDefinition(
      id: 'forest_trial_daily_wins_5_objective',
      domain: ProgressionDomain.activity,
      metric: NodeCompletionsMetric(nodeId: 'daily_steps_today'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5,
      baselineFromNodeId: 'forest_trial_open',
      debugLabel: 'Forest Trial step 1 — 5 daily steps since open',
    ),
    // Step 2: 5 daily-protein completions after step 1 cleared.
    ObjectiveDefinition(
      id: 'forest_trial_steps_5_objective',
      domain: ProgressionDomain.nutrition,
      metric: NodeCompletionsMetric(nodeId: 'daily_protein_today'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 5,
      baselineFromNodeId: 'forest_trial_daily_wins_5',
      debugLabel: 'Forest Trial step 2 — 5 daily protein since step 1',
    ),
    // Step 3: 3 daily-sleep completions after step 2 cleared.
    ObjectiveDefinition(
      id: 'forest_trial_recovery_3_objective',
      domain: ProgressionDomain.sleep,
      metric: NodeCompletionsMetric(nodeId: 'daily_sleep_today'),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 3,
      baselineFromNodeId: 'forest_trial_steps_5',
      debugLabel: 'Forest Trial step 3 — 3 daily sleep since step 2',
    ),
    // Finale: cheap auto-true objective. Real gating lives in
    // [QuestNode.prerequisiteNodeIds] which forces all 3 steps to
    // complete first.
    ObjectiveDefinition(
      id: 'forest_trial_finale_objective',
      domain: ProgressionDomain.activity,
      metric: LevelMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 10,
      debugLabel: 'Forest Trial finale — level >= 10 (prereqs gate the chain)',
    ),
  ];
}

List<ProgressionNode> forestTrialNodes() {
  return [
    ChapterOpenerNode(
      id: 'forest_trial_open',
      objectiveId: 'forest_trial_open_objective',
      // Explicit level gate so the resolver marks the chapter
      // ineligible (and the chapter card renders a locked overlay)
      // until the player reaches the chapter's start level. The
      // objective also encodes the gate for backwards compatibility
      // with consumers that only look at objective outcomes.
      unlockConditions: const [LevelAtLeast(10)],
      titleKey: (l) => l.progQuestForestTrialOpenTitle,
      descriptionKey: (l) => l.progQuestForestTrialOpenDesc,
      rewards: const [XpReward(amount: 120)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetForestTrialIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      // Chapters chain across the whole game: Forest Trial can't
      // auto-open until the player finishes the starter chapter.
      prerequisiteNodeIds: const ['pilgrim_path_finale'],
      nextNodeIds: const ['forest_trial_daily_wins_5'],
      chainStepIcon: Icons.play_arrow_rounded,
      sortOrder: 300,
    ),
    ChapterStepNode(
      id: 'forest_trial_daily_wins_5',
      objectiveId: 'forest_trial_daily_wins_5_objective',
      titleKey: (l) => l.progQuestForestTrialDailyWins5Title,
      descriptionKey: (l) => l.progQuestForestTrialDailyWins5Desc,
      rewards: const [XpReward(amount: 180)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetForestTrialIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 1,
      prerequisiteNodeIds: const ['forest_trial_open'],
      nextNodeIds: const ['forest_trial_steps_5'],
      chainStepLabelKey: (_) => '5',
      sortOrder: 301,
    ),
    ChapterStepNode(
      id: 'forest_trial_steps_5',
      objectiveId: 'forest_trial_steps_5_objective',
      titleKey: (l) => l.progQuestForestTrialSteps5Title,
      descriptionKey: (l) => l.progQuestForestTrialSteps5Desc,
      rewards: const [XpReward(amount: 180)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetForestTrialIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 2,
      prerequisiteNodeIds: const ['forest_trial_daily_wins_5'],
      nextNodeIds: const ['forest_trial_recovery_3'],
      chainStepLabelKey: (_) => '5',
      sortOrder: 302,
    ),
    ChapterStepNode(
      id: 'forest_trial_recovery_3',
      objectiveId: 'forest_trial_recovery_3_objective',
      titleKey: (l) => l.progQuestForestTrialRecovery3Title,
      descriptionKey: (l) => l.progQuestForestTrialRecovery3Desc,
      rewards: const [XpReward(amount: 220)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: questAssetForestTrialIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 3,
      prerequisiteNodeIds: const ['forest_trial_steps_5'],
      nextNodeIds: const ['forest_trial_finale'],
      chainStepLabelKey: (_) => '3',
      sortOrder: 303,
    ),
    ChapterFinaleNode(
      id: 'forest_trial_finale',
      objectiveId: 'forest_trial_finale_objective',
      titleKey: (l) => l.progQuestForestTrialFinaleTitle,
      descriptionKey: (l) => l.progQuestForestTrialFinaleDesc,
      rewards: const [
        XpReward(amount: 300),
        // Drops the V1 emblem cosmetic. CosmeticUnlockBridge dispatches
        // it to CosmeticsProvider just like every other engine grant.
        CosmeticReward(cosmeticId: 'emblem_forest_mark'),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
      assetKey: questAssetForestTrialIcon,
      chapterId: _chapterId,
      chainId: _chapterId,
      chainOrder: 4,
      prerequisiteNodeIds: const ['forest_trial_recovery_3'],
      chainStepIcon: Icons.shield_rounded,
      // The chapter is gated by player level; the open auto-fires at
      // level 10 so its prereq does the heavy lifting. We add an
      // explicit LevelAtLeast on the finale too so a stale ledger
      // can never grant it before the player actually qualifies.
      unlockConditions: const [LevelAtLeast(10)],
      sortOrder: 304,
    ),
  ];
}
