import 'package:forgetrack/domain/progression/catalog/ids.dart';
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

/// Sleep domain — daily sleep quest + lifetime mastery + rolling-window
/// mastery achievements. Mirrors V1: rule `daily_sleep`,
/// `sleep_total_250h`/`1000h`, `sleep_month_225h`/`240h`.

List<Objective> sleepObjectives(EngineCatalogContext context) {
  final goals = context.goals;
  return [
    Objective(
      id: const ObjectiveId('daily_sleep'),
      domain: ProgressionDomain.sleep,
      metric: const SleepMinutesMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: goals.sleepMinutes.toDouble(),
    ),
    const Objective(
      id: const ObjectiveId('lifetime_sleep_250h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      // V1 stores sleep in minutes; 250h = 15000 minutes.
      targetValue: 15000,
    ),
    const Objective(
      id: const ObjectiveId('lifetime_sleep_1000h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 60000,
    ),
    const Objective(
      id: const ObjectiveId('rolling_sleep_30d_225h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: RollingWindowScope(days: 30),
      operator: ObjectiveOperator.atLeast,
      targetValue: 13500,
    ),
    const Objective(
      id: const ObjectiveId('rolling_sleep_30d_240h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: RollingWindowScope(days: 30),
      operator: ObjectiveOperator.atLeast,
      targetValue: 14400,
    ),
  ];
}

List<ProgressionEntry> sleepNodes() {
  return [
    DailyQuest(
      id: const ProgressionEntryId('daily_sleep_today'),
      objectiveId: 'daily_sleep',
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailySleepDesc,
      titleKey: (l) => l.progRuleDailySleep,
      descriptionKey: (l) => l.progRuleDailySleepDesc,
      rewards: const [XpReward(amount: 50)],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetStreak,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_total_250h'),
      objectiveId: 'lifetime_sleep_250h',
      badgeEmoji: '\u{1F6CC}',
      titleKey: (l) => l.progAchievementSleep250hTitle,
      descriptionKey: (l) => l.progAchievementSleep250hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_total_1000h'),
      objectiveId: 'lifetime_sleep_1000h',
      badgeEmoji: '\u{1F48E}',
      titleKey: (l) => l.progAchievementSleep1000hTitle,
      descriptionKey: (l) => l.progAchievementSleep1000hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.uncommon,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_month_225h'),
      objectiveId: 'rolling_sleep_30d_225h',
      badgeEmoji: '\u{1F31C}',
      titleKey: (l) => l.progAchievementSleepMonth225hTitle,
      descriptionKey: (l) => l.progAchievementSleepMonth225hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_month_240h'),
      objectiveId: 'rolling_sleep_30d_240h',
      badgeEmoji: '\u{1F451}',
      titleKey: (l) => l.progAchievementSleepMonth240hTitle,
      descriptionKey: (l) => l.progAchievementSleepMonth240hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
  ];
}
