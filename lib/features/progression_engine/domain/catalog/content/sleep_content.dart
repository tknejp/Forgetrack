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
    const Objective(
      id: const ObjectiveId('rolling_sleep_30d_270h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: RollingWindowScope(days: 30),
      operator: ObjectiveOperator.atLeast,
      // 270h × 60 = 16200 min (9h / night for 30 days).
      targetValue: 16200,
    ),
    const Objective(
      id: const ObjectiveId('rolling_sleep_30d_300h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: RollingWindowScope(days: 30),
      operator: ObjectiveOperator.atLeast,
      // 300h × 60 = 18000 min (10h / night for 30 days).
      targetValue: 18000,
    ),
    const Objective(
      id: const ObjectiveId('rolling_sleep_200d_1600h'),
      domain: ProgressionDomain.sleep,
      metric: SleepMinutesMetric(),
      scope: RollingWindowScope(days: 200),
      operator: ObjectiveOperator.atLeast,
      // 1600h × 60 = 96000 min (8h / night for 200 days).
      targetValue: 96000,
    ),
    const Objective(
      id: const ObjectiveId('sleep_starts_after_1am_30'),
      domain: ProgressionDomain.sleep,
      metric: SleepStartHourCountMetric(
        hour: 1,
        direction: SleepStartHourDirection.atOrAfter,
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
    ),
    const Objective(
      id: const ObjectiveId('sleep_starts_before_10pm_30'),
      domain: ProgressionDomain.sleep,
      metric: SleepStartHourCountMetric(
        hour: 22,
        direction: SleepStartHourDirection.before,
      ),
      scope: LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 30,
    ),
  ];
}

List<ProgressionEntry> sleepNodes() {
  return [
    DailyGoal(
      id: const ProgressionEntryId('daily_sleep_today'),
      objectiveId: ObjectiveId('daily_sleep'),
      claimPolicy: ClaimPolicy.manual,
      lockedHintKey: (l) => l.progRuleDailySleepDesc,
      titleKey: (l) => l.progRuleDailySleep,
      descriptionKey: (l) => l.progRuleDailySleepDesc,
      rewards: const [
        XpReward(
          sourceKind: RewardSourceKind.sleepXp,
          streakDomain: ProgressionDomain.sleep,
          amount: 50,
        ),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
      assetKey: questAssetStreak,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_total_250h'),
      objectiveId: ObjectiveId('lifetime_sleep_250h'),
      badgeEmoji: '\u{1F6CC}',
      titleKey: (l) => l.progAchievementSleep250hTitle,
      descriptionKey: (l) => l.progAchievementSleep250hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.common,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_total_1000h'),
      objectiveId: ObjectiveId('lifetime_sleep_1000h'),
      badgeEmoji: '\u{1F48E}',
      titleKey: (l) => l.progAchievementSleep1000hTitle,
      descriptionKey: (l) => l.progAchievementSleep1000hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_month_225h'),
      objectiveId: ObjectiveId('rolling_sleep_30d_225h'),
      badgeEmoji: '\u{1F31C}',
      titleKey: (l) => l.progAchievementSleepMonth225hTitle,
      descriptionKey: (l) => l.progAchievementSleepMonth225hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_month_240h'),
      objectiveId: ObjectiveId('rolling_sleep_30d_240h'),
      badgeEmoji: '\u{1F451}',
      titleKey: (l) => l.progAchievementSleepMonth240hTitle,
      descriptionKey: (l) => l.progAchievementSleepMonth240hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_month_270h'),
      objectiveId: ObjectiveId('rolling_sleep_30d_270h'),
      badgeEmoji: '\u{1F30C}',
      titleKey: (l) => l.progAchievementSleepMonth270hTitle,
      descriptionKey: (l) => l.progAchievementSleepMonth270hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.legendary,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_month_300h'),
      objectiveId: ObjectiveId('rolling_sleep_30d_300h'),
      badgeEmoji: '\u{1F9DA}',
      titleKey: (l) => l.progAchievementSleepMonth300hTitle,
      descriptionKey: (l) => l.progAchievementSleepMonth300hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.mythic,
    ),
    Achievement(
      id: const ProgressionEntryId('sleep_200d_1600h'),
      objectiveId: ObjectiveId('rolling_sleep_200d_1600h'),
      badgeEmoji: '\u{1F3C6}',
      titleKey: (l) => l.progAchievementSleep200d1600hTitle,
      descriptionKey: (l) => l.progAchievementSleep200d1600hDesc,
      rewards: const [],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.mythic,
    ),
    Achievement(
      id: const ProgressionEntryId('night_owl'),
      objectiveId: ObjectiveId('sleep_starts_after_1am_30'),
      badgeEmoji: '\u{1F989}',
      titleKey: (l) => l.progAchievementNightOwlTitle,
      descriptionKey: (l) => l.progAchievementNightOwlDesc,
      // Paired with `early_bird`: both grant `relic_ruin_seal`. The
      // cosmetic unlock bridge is idempotent (`cosmetics.unlock`
      // no-ops when the id is already unlocked), so whichever
      // achievement completes first awards the relic and the second
      // is silent.
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_ruin_seal'))],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
    ),
    Achievement(
      id: const ProgressionEntryId('early_bird'),
      objectiveId: ObjectiveId('sleep_starts_before_10pm_30'),
      badgeEmoji: '\u{1F424}',
      titleKey: (l) => l.progAchievementEarlyBirdTitle,
      descriptionKey: (l) => l.progAchievementEarlyBirdDesc,
      // Pair with `night_owl` — see comment above for idempotence.
      rewards: const [CosmeticReward(cosmeticId: CosmeticId('relic_ruin_seal'))],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
    ),
  ];
}
