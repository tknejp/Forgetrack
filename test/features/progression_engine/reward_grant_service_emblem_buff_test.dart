import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/journal/in_memory_journal.dart';
import 'package:forgetrack/domain/player/player.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/features/cosmetics/domain/companion_buff.dart';
import 'package:forgetrack/features/cosmetics/domain/emblem_buff.dart';
import 'package:forgetrack/features/health_connect/domain/goal_board.dart';
import 'package:forgetrack/features/health_connect/domain/health_snapshot.dart';
import 'package:forgetrack/features/health_connect/domain/player_goal.dart';
import 'package:forgetrack/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:forgetrack/features/progression_engine/application/reward_grant_service.dart';
import 'package:forgetrack/features/progression_engine/domain/evaluator/reward_grant_planner.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_context.dart';
import 'package:forgetrack/features/progression_engine/domain/models/evaluation_overrides.dart';
import 'package:forgetrack/features/progression_engine/domain/models/ledger_counters.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

// Hand-rolled nodes that mirror real catalog ids so the engine's
// `emblemTargetForNode` mapping resolves the same way it does in
// production. Keeping these fabricated keeps the tests focused on
// the reward-grant pipeline (the catalog itself is exercised in
// emblem_buff_test.dart).
DailyGoal _dailyCaloriesNode() => DailyGoal(
      id: const ProgressionEntryId('daily_calories_today'),
      objectiveId: const ObjectiveId('daily_calories'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (_) => 'Cals',
      descriptionKey: (_) => '',
      rewards: const [
        XpReward(
          sourceKind: RewardSourceKind.nutritionXp,
          streakDomain: ProgressionDomain.nutrition,
          amount: 100,
        ),
      ],
      contentTags: const [],
      rarity: Rarity.common,
    );

DailyGoal _dailyStepsNode() => DailyGoal(
      id: const ProgressionEntryId('daily_steps_today'),
      objectiveId: const ObjectiveId('daily_steps'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (_) => 'Steps',
      descriptionKey: (_) => '',
      rewards: const [
        XpReward(
          sourceKind: RewardSourceKind.activityXp,
          streakDomain: ProgressionDomain.activity,
          amount: 100,
        ),
      ],
      contentTags: const [],
      rarity: Rarity.common,
    );

WeeklyQuest _weeklyQuest() => WeeklyQuest(
      id: const ProgressionEntryId('test_weekly'),
      objectiveId: const ObjectiveId('test_weekly_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (_) => 'Weekly',
      descriptionKey: (_) => '',
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 100),
      ],
      contentTags: const [],
      rarity: Rarity.common,
    );

PlannedRewardGrant _plan(ProgressionEntry node) => PlannedRewardGrant(
      eventKey: 'reward|${node.id}|0|test|grant',
      node: node,
      rewardOrdinal: 0,
      reward: node.rewards.first,
      periodKey: 'test',
    );

EngineEvaluationContext _ctx({
  CompanionBuff? companion,
  List<EmblemBuff> emblems = const [],
  bool rpg = true,
}) {
  return EngineEvaluationContext(
    player: Player(
      uid: 'test',
      level: 1,
      totalXp: 0,
      joinedAt: DateTime.utc(2026, 5, 1),
      rpgModeEnabled: rpg,
    ),
    healthSnapshot: HealthSnapshot.empty,
    nutritionSnapshot: NutritionSnapshot.empty,
    goalBoard: GoalBoard.empty,
    journal: InMemoryJournal(const []),
    counters: LedgerCounters.empty,
    overrides: const EvaluationOverrides(),
    evaluatedAt: DateTime.utc(2026, 5, 20, 12),
    equippedCompanionBuff: companion,
    equippedEmblemBuffs: emblems,
  );
}

void main() {
  const service = RewardGrantService();
  final timestamp = DateTime.utc(2026, 5, 20, 12);

  group('RewardGrantService emblem buff', () {
    test('per-target match adds bonus (calories emblem on calories claim)',
        () {
      final result = service.build(
        planned: [_plan(_dailyCaloriesNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          emblems: const [
            PerTargetEmblemBuff(
              target: DailyGoalTarget(GoalMetric.dailyCalories),
              percent: 10,
            ),
          ],
        ),
      );
      final event = result.events.single;
      expect(event.xpAmount, 110);
      expect(event.emblemBuffBonusXp, 10);
      expect(event.companionBuffBonusXp, isNull);
    });

    test('per-target mismatch → no bonus', () {
      final result = service.build(
        planned: [_plan(_dailyStepsNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          emblems: const [
            PerTargetEmblemBuff(
              target: DailyGoalTarget(GoalMetric.dailyCalories),
              percent: 10,
            ),
          ],
        ),
      );
      expect(result.events.single.emblemBuffBonusXp, isNull);
      expect(result.events.single.xpAmount, 100);
    });

    test('RPG mode off → emblem bonus suppressed even when equipped', () {
      final result = service.build(
        planned: [_plan(_dailyCaloriesNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          rpg: false,
          emblems: const [
            PerTargetEmblemBuff(
              target: DailyGoalTarget(GoalMetric.dailyCalories),
              percent: 10,
            ),
          ],
        ),
      );
      expect(result.events.single.emblemBuffBonusXp, isNull);
      expect(result.events.single.xpAmount, 100);
    });

    test('blanket buff applies whenever target is covered', () {
      final result = service.build(
        planned: [_plan(_dailyStepsNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          emblems: const [BlanketEmblemBuff(percent: 5)],
        ),
      );
      expect(result.events.single.emblemBuffBonusXp, 5);
      expect(result.events.single.xpAmount, 105);
    });

    test('blanket buff returns 0 on un-mapped target (weekly quest)', () {
      final result = service.build(
        planned: [_plan(_weeklyQuest())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          emblems: const [BlanketEmblemBuff(percent: 5)],
        ),
      );
      expect(result.events.single.emblemBuffBonusXp, isNull);
    });

    test('multiple equipped buffs stack additively on a single target', () {
      final result = service.build(
        planned: [_plan(_dailyCaloriesNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          emblems: const [
            PerTargetEmblemBuff(
              target: DailyGoalTarget(GoalMetric.dailyCalories),
              percent: 10,
            ),
            BlanketEmblemBuff(percent: 5),
          ],
        ),
      );
      // 100 * (1 + 15/100) = 115.
      expect(result.events.single.xpAmount, 115);
      expect(result.events.single.emblemBuffBonusXp, 15);
    });

    test('companion + emblem stack additively (math golden)', () {
      // companion 8% + emblem 10% = 18% total. base 100 → bonus 18 → xp 118.
      final result = service.build(
        planned: [_plan(_dailyCaloriesNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          companion: const FlatCompanionBuff(
            kind: RewardSourceKind.nutritionXp,
            percent: 8,
          ),
          emblems: const [
            PerTargetEmblemBuff(
              target: DailyGoalTarget(GoalMetric.dailyCalories),
              percent: 10,
            ),
          ],
        ),
      );
      final event = result.events.single;
      expect(event.xpAmount, 118);
      // Proportional split: 18 * 8/18 = 8, remainder 10 → emblem.
      expect(event.companionBuffBonusXp, 8);
      expect(event.emblemBuffBonusXp, 10);
      // Split sum invariant.
      expect(
        (event.companionBuffBonusXp ?? 0) + (event.emblemBuffBonusXp ?? 0),
        18,
      );
    });

    test('proportional split rounding falls to emblem half', () {
      // companion 7% + emblem 8% = 15% on base 100 = 15 bonus.
      // companion share = round(15 * 7/15) = round(7.0) = 7.
      // emblem share = 15 - 7 = 8.
      final result = service.build(
        planned: [_plan(_dailyCaloriesNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          companion: const FlatCompanionBuff(
            kind: RewardSourceKind.nutritionXp,
            percent: 7,
          ),
          emblems: const [
            PerTargetEmblemBuff(
              target: DailyGoalTarget(GoalMetric.dailyCalories),
              percent: 8,
            ),
          ],
        ),
      );
      final event = result.events.single;
      expect(event.companionBuffBonusXp, 7);
      expect(event.emblemBuffBonusXp, 8);
      expect(event.xpAmount, 115);
    });

    test('empty emblem list → no emblem bonus, companion still applies', () {
      final result = service.build(
        planned: [_plan(_dailyStepsNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _ctx(
          companion: const FlatCompanionBuff(
            kind: RewardSourceKind.activityXp,
            percent: 8,
          ),
        ),
      );
      expect(result.events.single.companionBuffBonusXp, 8);
      expect(result.events.single.emblemBuffBonusXp, isNull);
      expect(result.events.single.xpAmount, 108);
    });
  });
}
