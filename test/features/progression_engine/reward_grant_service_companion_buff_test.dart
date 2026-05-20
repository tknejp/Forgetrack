import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/journal/in_memory_journal.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/player.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/features/cosmetics/domain/companion_buff.dart';
import 'package:forgetrack/features/health_connect/domain/goal_board.dart';
import 'package:forgetrack/features/health_connect/domain/health_snapshot.dart';
import 'package:forgetrack/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:forgetrack/features/progression_engine/application/reward_grant_service.dart';
import 'package:forgetrack/features/progression_engine/domain/evaluator/reward_grant_planner.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_context.dart';
import 'package:forgetrack/features/progression_engine/domain/models/evaluation_overrides.dart';
import 'package:forgetrack/features/progression_engine/domain/models/ledger_counters.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

/// Test fixtures: tiny catalog rows + planned grants. We deliberately
/// fabricate the nodes here instead of building the real catalog so
/// each test stays focused on the reward-grant pipeline.
DailyGoal _dailyActivityGoal() => DailyGoal(
      id: const ProgressionEntryId('test_daily_activity'),
      objectiveId: const ObjectiveId('test_daily_activity_obj'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (_) => 'Activity',
      descriptionKey: (_) => 'Move',
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
      descriptionKey: (_) => 'Week',
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.questXp, amount: 100),
      ],
      contentTags: const [],
      rarity: Rarity.common,
    );

ChapterStep _chapterStep({required int chainOrder}) => ChapterStep(
      id: ProgressionEntryId('test_chapter_step_$chainOrder'),
      objectiveId: ObjectiveId('test_chapter_step_${chainOrder}_obj'),
      titleKey: (_) => 'Step',
      descriptionKey: (_) => '',
      rewards: const [
        XpReward(sourceKind: RewardSourceKind.chapterXp, amount: 100),
      ],
      contentTags: const [],
      rarity: Rarity.rare,
      chapterId: const ChapterId('test_chapter'),
      chainId: const ChainId('test_chapter'),
      chainOrder: chainOrder,
      nextNodeIds: const [],
    );

PlannedRewardGrant _planFromNode(ProgressionEntry node) => PlannedRewardGrant(
      eventKey: 'reward|${node.id}|0|test|grant',
      node: node,
      rewardOrdinal: 0,
      reward: node.rewards.first,
      periodKey: 'test',
    );

EngineEvaluationContext _context({
  CompanionBuff? buff,
  Map<ProgressionDomain, int> streaks = const {},
  bool rpg = true,
  List<JournalEvent> journalEvents = const [],
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
    journal: InMemoryJournal(journalEvents),
    counters: LedgerCounters.empty,
    overrides: const EvaluationOverrides(),
    evaluatedAt: DateTime.utc(2026, 5, 20, 12),
    equippedCompanionBuff: buff,
    currentStreakByDomain: streaks,
  );
}

void main() {
  const service = RewardGrantService();
  final timestamp = DateTime.utc(2026, 5, 20, 12);

  group('RewardGrantService companion buff', () {
    test('no buff equipped → no bonus (xpAmount = scaled base)', () {
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(),
      );
      final event = result.events.single;
      expect(event.xpAmount, 100);
      expect(event.companionBuffBonusXp, isNull);
    });

    test('null context skips buff entirely (callers without context)', () {
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
      );
      final event = result.events.single;
      expect(event.companionBuffBonusXp, isNull);
    });

    test('RPG mode off → buff does not apply', () {
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          rpg: false,
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.activityXp,
            percent: 8,
          ),
        ),
      );
      expect(result.events.single.companionBuffBonusXp, isNull);
    });

    test('flat kind match → bonus applied', () {
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.activityXp,
            percent: 8,
          ),
        ),
      );
      final event = result.events.single;
      expect(event.companionBuffBonusXp, 8);
      expect(event.xpAmount, 108);
    });

    test('kind mismatch → no bonus', () {
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.nutritionXp,
            percent: 8,
          ),
        ),
      );
      expect(result.events.single.companionBuffBonusXp, isNull);
    });

    test('allXp buff applies to every kind', () {
      final result = service.build(
        planned: [
          _planFromNode(_dailyActivityGoal()),
          _planFromNode(_weeklyQuest()),
        ],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.allXp,
            percent: 7,
          ),
        ),
      );
      expect(result.events[0].companionBuffBonusXp, 7);
      expect(result.events[1].companionBuffBonusXp, 7);
    });

    // NB: per-tier streak resolution is covered exhaustively in
    // `companion_buff_test.dart`. Here we just confirm the engine
    // pipes the per-domain streak into the rule. The buff applies
    // to any reward with a non-null streakDomain — the hand-rolled
    // node mirrors steps_content.dart's tag so the engine sees a
    // matching domain key on the streak map.
    test('engine threads per-domain streak into Ember tier resolution', () {
      DailyGoal streakNode() => DailyGoal(
            id: const ProgressionEntryId('test_streak_node'),
            objectiveId: const ObjectiveId('test_streak_obj'),
            claimPolicy: ClaimPolicy.manual,
            titleKey: (_) => 'Streak',
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
      const buff = StreakLengthCompanionBuff();

      // 1-day streak in the matching domain → tier 0 (no bonus).
      final tier0 = service.build(
        planned: [_planFromNode(streakNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: buff,
          streaks: const {ProgressionDomain.activity: 1},
        ),
      );
      expect(
        tier0.events.single.companionBuffBonusXp,
        // Tier 0 resolves to 0 % — the engine collapses that to a
        // null bonus on the event.
        isNull,
      );

      // 50-day streak in the matching domain → cap tier 4.
      final cap = service.build(
        planned: [_planFromNode(streakNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: buff,
          streaks: const {ProgressionDomain.activity: 50},
        ),
      );
      expect(
        cap.events.single.companionBuffBonusXp,
        CompanionBuffPercents.emberTier4,
      );

      // 50-day streak in a *different* domain → no bonus (the
      // matching domain's streak is 0).
      final wrongDomain = service.build(
        planned: [_planFromNode(streakNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: buff,
          streaks: const {ProgressionDomain.sleep: 50},
        ),
      );
      expect(wrongDomain.events.single.companionBuffBonusXp, isNull);
    });

    test('engine respects Lantern Golem threshold per domain', () {
      // The threshold-flat buff only pays out at or above
      // [minStreak] on the granting reward's own domain.
      DailyGoal nutritionNode() => DailyGoal(
            id: const ProgressionEntryId('test_nutrition_node'),
            objectiveId: const ObjectiveId('test_nutrition_obj'),
            claimPolicy: ClaimPolicy.manual,
            titleKey: (_) => 'Nutrition',
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
      const buff = StreakThresholdFlatCompanionBuff(
        percent: CompanionBuffPercents.lanternGolemPercent,
        minStreak: CompanionBuffPercents.lanternGolemThreshold,
      );

      // Below threshold → no bonus, surfaced as null on the event.
      final below = service.build(
        planned: [_planFromNode(nutritionNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: buff,
          streaks: const {ProgressionDomain.nutrition: 5},
        ),
      );
      expect(below.events.single.companionBuffBonusXp, isNull);

      // At threshold → full percent (cap allows it on a 100 base
      // since 30 > 33-cap floor sits below the daily share cap).
      final atThreshold = service.build(
        planned: [_planFromNode(nutritionNode())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: buff,
          streaks: const {ProgressionDomain.nutrition: 7},
        ),
      );
      // 30 % on a 100-base grant is 30, just under the 33 cap.
      expect(
        atThreshold.events.single.companionBuffBonusXp,
        CompanionBuffPercents.lanternGolemPercent,
      );
    });

    test('Raven weekly emphasis: daily vs weekly quest', () {
      const buff = WeeklyEmphasisCompanionBuff();
      // Daily quest → dampened bonus (we use the daily activity
      // quest since its kind is activityXp, not questXp — match
      // fails). Instead test the weekly path through the engine:
      final result = service.build(
        planned: [_planFromNode(_weeklyQuest())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(buff: buff),
      );
      // WeeklyQuest with questXp source + weekly bucket → ravenWeekly.
      expect(
        result.events.single.companionBuffBonusXp,
        CompanionBuffPercents.ravenWeekly,
      );
    });

    test('Cave Lynx depth: chain position drives percent', () {
      // Run each tier as a separate `build` call so the daily cap
      // accountant resets between runs — three sequential chapter
      // claims in the same batch would push the deep tier into the
      // softcap and undershoot the raw rule output (that scenario
      // is its own assertion in "cap accumulates").
      const buff = ChapterDepthCompanionBuff();
      int bonusForChainOrder(int order) {
        final result = service.build(
          planned: [_planFromNode(_chapterStep(chainOrder: order))],
          runningClaimedXp: 0,
          timestamp: timestamp,
          context: _context(buff: buff),
        );
        return result.events.single.companionBuffBonusXp ?? 0;
      }
      // Opener tier sits under the single-grant cap and applies raw;
      // mid + deep tiers blow through the 25 % share cap on a 100-base
      // grant and read back at the cap value (33). The buff resolution
      // itself is covered exhaustively in `companion_buff_test.dart`;
      // here we just verify the engine pipes chain position into the
      // rule. (Single-grant cap = floor(0.25 × 100 / 0.75) = 33.)
      expect(bonusForChainOrder(0), CompanionBuffPercents.lynxOpener);
      expect(bonusForChainOrder(2), 33);
      expect(bonusForChainOrder(5), 33);
    });

    test('25 % daily share cap clamps over-budget bonus', () {
      // Big allXp buff that would normally drop +50 XP on a 100 XP
      // grant. With no prior history the cap allows at most ~33 %
      // of the post-grant total, which works out to 33 XP bonus on
      // a 100-base grant. Anything above that is clamped.
      // Note: (cap*(total+base) - bonus) / (1 - cap)
      //     = (0.25 * (0 + 100) - 0) / 0.75
      //     = 33.33 → floor = 33.
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.allXp,
            percent: 50,
          ),
        ),
      );
      final event = result.events.single;
      expect(event.companionBuffBonusXp, 33);
      expect(event.xpAmount, 133);
    });

    test('cap accumulates across same-batch grants', () {
      // Two 100-base grants with a 50 % allXp buff: first bonus is
      // capped at 33 (per single-grant test); second has total=133
      // and bonus=33 already banked → headroom shrinks.
      final result = service.build(
        planned: [
          _planFromNode(_dailyActivityGoal()),
          _planFromNode(_dailyActivityGoal()),
        ],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.allXp,
            percent: 50,
          ),
        ),
      );
      expect(result.events[0].companionBuffBonusXp, 33);
      // Second grant: post-history (total=133, bonus=33).
      // (0.25 * (133 + 100) - 33) / 0.75 = (58.25 - 33) / 0.75 = 33.66 → 33.
      expect(result.events[1].companionBuffBonusXp, 33);
      // Combined: 66 bonus on 266 total ≈ 24.8 % ≤ 25 % cap.
      final totalBonus = result.events
          .map((e) => e.companionBuffBonusXp ?? 0)
          .fold<int>(0, (a, b) => a + b);
      final totalXp = result.events
          .map((e) => e.xpAmount ?? 0)
          .fold<int>(0, (a, b) => a + b);
      expect(totalBonus / totalXp, lessThanOrEqualTo(0.25));
    });

    test('cap reads prior journal events from today', () {
      // Pre-seed journal with a 1000-XP grant earlier today (no
      // companion bonus). Cap headroom for a new 100-base grant:
      // (0.25 * (1000 + 100) - 0) / 0.75 ≈ 366 → way above the
      // raw 8 % bonus (8), so full bonus applies.
      final earlierEvent = RewardGrantEvent(
        eventKey: 'prior',
        timestamp: timestamp.subtract(const Duration(hours: 1)),
        nodeId: 'prior_node',
        rewardOrdinal: 0,
        rewardKind: RewardGrantKind.xp,
        xpAmount: 1000,
        levelAtGrant: 1,
        multiplierAtGrant: 1.0,
      );
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.activityXp,
            percent: 8,
          ),
          journalEvents: [earlierEvent],
        ),
      );
      expect(result.events.single.companionBuffBonusXp, 8);
    });

    test('cap ignores yesterday\'s events (daily window)', () {
      final yesterdayEvent = RewardGrantEvent(
        eventKey: 'prior',
        timestamp: timestamp.subtract(const Duration(days: 1)),
        nodeId: 'prior_node',
        rewardOrdinal: 0,
        rewardKind: RewardGrantKind.xp,
        xpAmount: 1000,
        companionBuffBonusXp: 100,
        levelAtGrant: 1,
        multiplierAtGrant: 1.0,
      );
      final result = service.build(
        planned: [_planFromNode(_dailyActivityGoal())],
        runningClaimedXp: 0,
        timestamp: timestamp,
        context: _context(
          buff: const FlatCompanionBuff(
            kind: RewardSourceKind.allXp,
            percent: 50,
          ),
          journalEvents: [yesterdayEvent],
        ),
      );
      // Should behave as if no prior bonus exists today.
      expect(result.events.single.companionBuffBonusXp, 33);
    });
  });
}
