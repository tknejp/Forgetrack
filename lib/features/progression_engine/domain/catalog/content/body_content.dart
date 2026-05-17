import '../../../../../shared/domain/rarity.dart';
import '../../models/claim_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// Body / weight domain — daily weight-log quest.
///
/// The objective fires the moment a weight record exists for today,
/// driven by [WeightLoggedTodayMetric]. The home weight card surfaces
/// the resulting "Vyzvednout XP" pill via `daily_weight_log_today`.

List<Objective> bodyObjectives(EngineCatalogContext context) {
  return const [
    // Logged a weight today (presence-only check).
    Objective(
      id: 'daily_weight_log',
      domain: ProgressionDomain.body,
      metric: WeightLoggedTodayMetric(),
      scope: TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1,
    ),
  ];
}

List<ProgressionEntry> bodyNodes() {
  return [
    DailyQuest(
      id: 'daily_weight_log_today',
      objectiveId: 'daily_weight_log',
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
