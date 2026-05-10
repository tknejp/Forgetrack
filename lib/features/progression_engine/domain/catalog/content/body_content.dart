import '../../../../../shared/domain/rarity.dart';
import '../../models/claim_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/quest_display_bucket.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// Body / weight domain — daily weight-log + daily weight-goal quests.
///
/// V1 rules `daily_weight_log` and `daily_weight_goal` use the
/// `weightKg` metric which the V2 evaluator does not yet read off the
/// source (the input doesn't carry weight today). These nodes are
/// kept here for shape; their objectives will start completing once
/// the V2 source plumbing wires weight into [EngineEvaluationInput] —
/// happens during Phase 6 UI integration.

List<ObjectiveDefinition> bodyObjectives(EngineCatalogContext context) {
  // Weight metric not yet plumbed; emit the objectives so the
  // catalog is structurally complete and validator stays happy.
  return const [
    // Logged a weight today (presence-only check).
    ObjectiveDefinition(
      id: 'daily_weight_log',
      domain: ProgressionDomain.body,
      // Reuse RewardCountMetric as a placeholder presence-check until
      // a WeightLoggedTodayMetric lands — the engine will simply not
      // complete this objective until Phase 6 wires the source.
      metric: RewardCountMetric(ruleId: 'daily_weight_log'),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
  ];
}

List<ProgressionNode> bodyNodes() {
  return [
    QuestNode(
      id: 'daily_weight_log_today',
      objectiveId: 'daily_weight_log',
      displayBucket: QuestDisplayBucket.daily,
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyWeightLogDesc,
      titleKey: (l) => l.progRuleDailyWeightLog,
      descriptionKey: (l) => l.progRuleDailyWeightLogDesc,
      rewards: const [XpReward(amount: 20)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetActivity,
    ),
  ];
}
