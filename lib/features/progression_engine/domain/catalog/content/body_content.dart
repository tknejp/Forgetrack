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

/// Body / weight domain — daily weight-log quest.
///
/// The objective fires the moment a weight record exists for today,
/// driven by [WeightLoggedTodayMetric]. The home weight card surfaces
/// the resulting "Vyzvednout XP" pill via `daily_weight_log_today`.

List<Objective> bodyObjectives(EngineCatalogContext context) {
  return const [
    // Logged a weight today (presence-only check).
    Objective(
      id: const ObjectiveId('daily_weight_log'),
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
    DailyGoal(
      id: const ProgressionEntryId('daily_weight_log_today'),
      objectiveId: ObjectiveId('daily_weight_log'),
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailyWeightLogDesc,
      titleKey: (l) => l.progRuleDailyWeightLog,
      descriptionKey: (l) => l.progRuleDailyWeightLogDesc,
      rewards: const [
        XpReward(
          sourceKind: RewardSourceKind.activityXp,
          streakDomain: ProgressionDomain.body,
          amount: 20,
        ),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetActivity,
    ),
  ];
}
