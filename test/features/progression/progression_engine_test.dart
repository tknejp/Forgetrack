import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression/application/progression_engine.dart';
import 'package:forgetrack/features/progression/application/progression_source.dart';
import 'package:forgetrack/features/progression/domain/progression_evaluator.dart';
import 'package:forgetrack/features/progression/domain/progression_level_policy.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';
import 'package:forgetrack/features/progression/domain/progression_reward_finalization_policy.dart';
import 'package:forgetrack/features/progression/domain/progression_repository.dart';

void main() {
  group('ProgressionEngine', () {
    test('grants rewards only once for the same evaluated periods', () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 21, 8),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2050,
            proteinGrams: 160,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 21)),
            activityMinutes: 170,
          ),
        ],
      );

      final firstSync = await engine.sync(source);
      final secondSync = await engine.sync(source);

      expect(firstSync.rewardGrants, hasLength(5));
      expect(firstSync.profile.totalXp, 350);
      expect(secondSync.rewardGrants, hasLength(5));
      expect(secondSync.profile.totalXp, 350);
      expect(
        secondSync.rewardGrants.map((grant) => grant.rewardKey).toSet(),
        hasLength(5),
      );
    });

    test('updates evaluation state but keeps reward idempotent after success',
        () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 21, 8),
      );

      final missedSource = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 8500,
            calories: 2400,
            proteinGrams: 80,
            sleepMinutes: 420,
          ),
        ],
        weeklySnapshots: const [],
      );

      final recoveredSource = _FakeProgressionSource(
        goals: missedSource.goals,
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 11000,
            calories: 1980,
            proteinGrams: 155,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final firstSync = await engine.sync(missedSource);
      final secondSync = await engine.sync(recoveredSource);
      final thirdSync = await engine.sync(recoveredSource);

      expect(firstSync.rewardGrants, isEmpty);
      expect(secondSync.rewardGrants, hasLength(4));
      expect(secondSync.profile.totalXp, 230);
      expect(thirdSync.rewardGrants, hasLength(4));

      final dailyStepsEvaluation = thirdSync.evaluations.firstWhere(
        (evaluation) => evaluation.ruleId == 'daily_steps',
      );
      expect(dailyStepsEvaluation.achieved, isTrue);
      expect(dailyStepsEvaluation.actualValue, 11000);
    });

    test(
        'evaluates snapshots in deterministic order regardless of source order',
        () async {
      final engineA = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 21, 8),
      );
      final engineB = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 21, 8),
      );
      final sourceA = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 22)),
            steps: 12000,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
          ),
        ],
        weeklySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 28)),
            activityMinutes: 170,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 21)),
            activityMinutes: 170,
          ),
        ],
      );
      final sourceB = _FakeProgressionSource(
        goals: sourceA.goals,
        dailySnapshots: sourceA.dailySnapshots.reversed.toList(),
        weeklySnapshots: sourceA.weeklySnapshots.reversed.toList(),
      );

      final stateA = await engineA.sync(sourceA);
      final stateB = await engineB.sync(sourceB);

      expect(
        stateA.evaluations
            .map((evaluation) => evaluation.evaluationKey)
            .toList(),
        orderedEquals(
          stateB.evaluations
              .map((evaluation) => evaluation.evaluationKey)
              .toList(),
        ),
      );
    });

    test('derives rule and domain streak summaries from evaluations', () async {
      final engine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 24, 8),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2000,
            proteinGrams: 160,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 22)),
            steps: 10500,
            calories: 1980,
            proteinGrams: 100,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 23)),
            steps: 9000,
            calories: 2500,
            proteinGrams: 90,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 24)),
            steps: 12000,
            calories: 2500,
            proteinGrams: 155,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final state = await engine.sync(source);
      final stepsStreak = state.streaksByRuleId['daily_steps']!;
      final nutritionStreak =
          state.streaksByDomain[ProgressionDomain.nutrition]!;

      expect(stepsStreak.currentStreak, 1);
      expect(stepsStreak.bestStreak, 2);
      expect(stepsStreak.latestPeriodStart, DateTime(2026, 4, 24));
      expect(stepsStreak.lastAchievedPeriodStart, DateTime(2026, 4, 24));

      expect(nutritionStreak.currentStreak, 1);
      expect(nutritionStreak.bestStreak, 2);
      expect(nutritionStreak.latestPeriodStart, DateTime(2026, 4, 24));
      expect(nutritionStreak.lastAchievedPeriodStart, DateTime(2026, 4, 24));
    });

    test('derives achievements from rewards, xp and streak history', () async {
      final engine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 23, 9),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2000,
            proteinGrams: 160,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 22)),
            steps: 11000,
            calories: 1980,
            proteinGrams: 170,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 23)),
            steps: 10500,
            calories: 2020,
            proteinGrams: 155,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 21)),
            activityMinutes: 170,
          ),
        ],
      );

      final state = await engine.sync(source);
      final achievementsById = {
        for (final achievement in state.achievements)
          achievement.id: achievement,
      };

      expect(achievementsById['first_reward']!.unlocked, isTrue);
      expect(achievementsById['weekly_activity_mastery']!.unlocked, isTrue);
      expect(achievementsById['steps_streak_3']!.unlocked, isTrue);
      expect(achievementsById['nutrition_streak_3']!.unlocked, isTrue);
      expect(achievementsById['pathfinder_level_5']!.unlocked, isFalse);
      expect(
        achievementsById['steps_streak_3']!.unlockedAt,
        DateTime(2026, 4, 23),
      );
      expect(
        achievementsById['nutrition_streak_3']!.unlockedAt,
        DateTime(2026, 4, 23),
      );
      expect(achievementsById['steps_total_100k']!.unlocked, isFalse);
    });

    test('unlocks lifetime step milestones from accumulated evaluations',
        () async {
      final engine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 30, 9),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          for (var day = 21; day <= 30; day++)
            ProgressionSnapshot(
              period: ProgressionPeriod.day(DateTime(2026, 4, day)),
              steps: 10000,
            ),
        ],
        weeklySnapshots: const [],
      );

      final state = await engine.sync(source);
      final achievementsById = {
        for (final achievement in state.achievements)
          achievement.id: achievement,
      };
      final questsById = {
        for (final quest in state.quests) quest.id: quest,
      };

      expect(achievementsById['steps_total_100k']!.unlocked, isTrue);
      expect(
        achievementsById['steps_total_100k']!.unlockedAt,
        DateTime(2026, 4, 30),
      );
      expect(achievementsById['steps_total_500k']!.unlocked, isFalse);
      expect(achievementsById['steps_total_1000000']!.unlocked, isFalse);
      expect(questsById['total_steps_100k']!.isCompleted, isTrue);
      expect(questsById['total_steps_500k']!.status,
          isNot(ProgressionQuestStatus.locked));
    });

    test('derives static quests from ledger, achievements and streaks',
        () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 23, 9),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2000,
            proteinGrams: 160,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 22)),
            steps: 11000,
            calories: 1980,
            proteinGrams: 170,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 23)),
            steps: 10500,
            calories: 2020,
            proteinGrams: 155,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 21)),
            activityMinutes: 170,
          ),
        ],
      );

      final state = await engine.sync(source);
      final questsById = {
        for (final quest in state.quests) quest.id: quest,
      };

      expect(state.rewardGrants, hasLength(13));
      expect(questsById['earn_first_reward']!.isCompleted, isTrue);
      expect(
        questsById['earn_first_reward']!.completedAt,
        DateTime(2026, 4, 23, 9),
      );
      expect(questsById['reach_500_xp']!.isCompleted, isTrue);
      expect(
        questsById['reach_500_xp']!.completedAt,
        DateTime(2026, 4, 23, 9),
      );
      expect(
          questsById['reach_2000_xp']!.status, ProgressionQuestStatus.active);
      expect(
        questsById['reach_2000_xp']!.category,
        ProgressionQuestCategory.journey,
      );
      expect(questsById['steps_streak_3']!.isCompleted, isTrue);
      expect(
        questsById['steps_streak_3']!.completedAt,
        DateTime(2026, 4, 23),
      );
      expect(questsById['nutrition_rewards_5']!.isCompleted, isTrue);
      expect(
        questsById['nutrition_rewards_5']!.completedAt,
        DateTime(2026, 4, 23, 9),
      );
      expect(questsById['weekly_activity_once']!.isCompleted, isTrue);
      expect(
        questsById['weekly_activity_once']!.completedAt,
        DateTime(2026, 4, 23, 9),
      );
      expect(
        questsById['weekly_activity_4']!.status,
        ProgressionQuestStatus.active,
      );
      expect(questsById['unlock_step_chain']!.isCompleted, isTrue);
      expect(
        questsById['unlock_step_chain']!.completedAt,
        DateTime(2026, 4, 23),
      );
      expect(
          questsById['steps_streak_7']!.status, ProgressionQuestStatus.active);
      expect(questsById['steps_streak_7']!.isHighlighted, isTrue);
    });

    test('keeps quests deterministic across source order and reload', () async {
      final repository = _InMemoryProgressionRepository();
      final engineA = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 23, 9),
      );
      final engineB = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 23, 9),
      );
      final sourceA = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2000,
            proteinGrams: 160,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 22)),
            steps: 11000,
            calories: 1980,
            proteinGrams: 170,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 23)),
            steps: 10500,
            calories: 1500,
            proteinGrams: 140,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );
      final sourceB = _FakeProgressionSource(
        goals: sourceA.goals,
        dailySnapshots: sourceA.dailySnapshots.reversed.toList(),
        weeklySnapshots: const [],
      );

      final firstState = await engineA.sync(sourceA);
      final secondState = await engineB.sync(sourceB);
      final reloadedState = await engineB.load();

      expect(
        firstState.quests
            .map((quest) =>
                '${quest.id}|${quest.status.name}|${quest.completedAt}')
            .toList(),
        orderedEquals(
          secondState.quests
              .map((quest) =>
                  '${quest.id}|${quest.status.name}|${quest.completedAt}')
              .toList(),
        ),
      );
      expect(
        secondState.quests
            .map((quest) =>
                '${quest.id}|${quest.status.name}|${quest.completedAt}')
            .toList(),
        orderedEquals(
          reloadedState.quests
              .map((quest) =>
                  '${quest.id}|${quest.status.name}|${quest.completedAt}')
              .toList(),
        ),
      );
      expect(
        firstState.rewardGrants.map((grant) => grant.rewardKey).toSet(),
        equals(
            secondState.rewardGrants.map((grant) => grant.rewardKey).toSet()),
      );
    });

    test('reports partial progress for active quests', () async {
      final engine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 21, 9),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2500,
            proteinGrams: 100,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final state = await engine.sync(source);
      final questsById = {
        for (final quest in state.quests) quest.id: quest,
      };

      expect(questsById['earn_first_reward']!.isCompleted, isTrue);
      expect(questsById['daily_steps_today']!.isCompleted, isTrue);
      expect(
        questsById['daily_triple_win_today']!.status,
        ProgressionQuestStatus.active,
      );
      expect(
        questsById['daily_nutrition_combo_today']!.status,
        ProgressionQuestStatus.active,
      );
      expect(
        questsById['daily_protein_today']!.status,
        ProgressionQuestStatus.available,
      );
      expect(
        questsById['daily_sleep_today']!.isCompleted,
        isTrue,
      );
      expect(questsById['reach_500_xp']!.isCompleted, isFalse);
      expect(questsById['reach_500_xp']!.currentValue, 130);
      expect(questsById['reach_500_xp']!.progress, closeTo(130 / 500, 0.0001));
      expect(
          questsById['steps_streak_3']!.status, ProgressionQuestStatus.active);
      expect(questsById['steps_streak_3']!.currentValue, 1);
      expect(
          questsById['reach_2000_xp']!.status, ProgressionQuestStatus.locked);
      expect(questsById['earn_25_rewards']!.status,
          ProgressionQuestStatus.available);
      expect(questsById['reach_500_xp']!.status, ProgressionQuestStatus.active);
      expect(
        questsById['weekly_activity_once']!.status,
        ProgressionQuestStatus.active,
      );
      expect(questsById['nutrition_rewards_5']!.status,
          ProgressionQuestStatus.active);
      expect(questsById['nutrition_rewards_5']!.currentValue, 0);
      expect(questsById['unlock_step_chain']!.status,
          ProgressionQuestStatus.locked);
      expect(questsById['unlock_step_chain']!.currentValue, 0);
      expect(
          questsById['steps_streak_7']!.status, ProgressionQuestStatus.locked);
      expect(
        state.quests.where((quest) => quest.isHighlighted).length,
        lessThanOrEqualTo(6),
      );
      expect(questsById['steps_streak_3']!.isHighlighted, isTrue);
      expect(questsById['daily_triple_win_today']!.isHighlighted, isTrue);
      expect(questsById['daily_nutrition_combo_today']!.isHighlighted, isTrue);
    });

    test('unlocks chained quests only after prerequisite completion', () async {
      final engine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 27, 8),
      );
      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          for (final day in [21, 22, 23, 24, 25, 26, 27])
            ProgressionSnapshot(
              period: ProgressionPeriod.day(DateTime(2026, 4, day)),
              steps: 12000,
            ),
        ],
        weeklySnapshots: const [],
      );

      final state = await engine.sync(source);
      final questsById = {for (final quest in state.quests) quest.id: quest};

      expect(questsById['steps_streak_3']!.isCompleted, isTrue);
      expect(questsById['unlock_step_chain']!.isCompleted, isTrue);
      expect(questsById['steps_streak_7']!.isCompleted, isTrue);
      expect(
        questsById['steps_streak_7']!.completedAt,
        DateTime(2026, 4, 27),
      );
    });

    test('promotes a new weekly quest into the active set after completion',
        () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 28, 8),
      );

      final initialSource = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: const [],
        weeklySnapshots: const [],
      );
      final completedWeeklySource = _FakeProgressionSource(
        goals: initialSource.goals,
        dailySnapshots: const [],
        weeklySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 28)),
            activityMinutes: 170,
          ),
        ],
      );

      final firstState = await engine.sync(initialSource);
      final secondState = await engine.sync(completedWeeklySource);
      final questsById = {
        for (final quest in secondState.quests) quest.id: quest
      };

      expect(
        firstState.quests
            .firstWhere((quest) => quest.id == 'weekly_activity_once')
            .status,
        ProgressionQuestStatus.active,
      );
      expect(questsById['weekly_activity_once']!.isCompleted, isTrue);
      expect(questsById['weekly_activity_4']!.status,
          ProgressionQuestStatus.active);
      expect(questsById['weekly_activity_4']!.isHighlighted, isTrue);
    });

    test('daily quests evaluate only the latest matching period', () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 22, 8),
      );

      final source = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            proteinGrams: 155,
            sleepMinutes: 500,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 22)),
            steps: 9000,
            proteinGrams: 110,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final state = await engine.sync(source);
      final questsById = {for (final quest in state.quests) quest.id: quest};

      expect(questsById['daily_steps_today']!.status,
          ProgressionQuestStatus.available);
      expect(questsById['daily_steps_today']!.currentValue, 0);
      expect(
        questsById['daily_two_goals_today']!.status,
        ProgressionQuestStatus.active,
      );
      expect(questsById['daily_two_goals_today']!.currentValue, 1);
      expect(
        questsById['daily_nutrition_combo_today']!.status,
        ProgressionQuestStatus.active,
      );
      expect(
        questsById['daily_protein_today']!.status,
        ProgressionQuestStatus.available,
      );
      expect(questsById['daily_protein_today']!.currentValue, 0);
      expect(questsById['daily_sleep_today']!.isCompleted, isTrue);
      expect(
        questsById['daily_sleep_today']!.completedAt,
        DateTime(2026, 4, 22),
      );
    });

    test('locks advanced quests behind level and tracked time gates', () async {
      final earlyEngine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 4, 21, 9),
      );
      final earlySource = _FakeProgressionSource(
        goals: const ProgressionGoalSet(
          dailySteps: 10000,
          dailyCalories: 2000,
          dailyProteinGrams: 150,
          sleepMinutes: 480,
          weeklyActivityMinutes: 150,
        ),
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 12000,
            calories: 2000,
            proteinGrams: 160,
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final earlyState = await earlyEngine.sync(earlySource);
      final earlyQuestsById = {
        for (final quest in earlyState.quests) quest.id: quest,
      };

      expect(
        earlyQuestsById['daily_four_pillars_today']!.status,
        ProgressionQuestStatus.locked,
      );
      expect(
        earlyQuestsById['reach_5000_xp']!.status,
        ProgressionQuestStatus.locked,
      );
      expect(
        earlyQuestsById['weekly_activity_12']!.status,
        ProgressionQuestStatus.locked,
      );

      final lateEngine = ProgressionEngine(
        repository: _InMemoryProgressionRepository(),
        clock: () => DateTime(2026, 5, 5, 9),
      );
      final lateSource = _FakeProgressionSource(
        goals: earlySource.goals,
        dailySnapshots: [
          for (var offset = 0; offset < 15; offset++)
            ProgressionSnapshot(
              period: ProgressionPeriod.day(
                DateTime(2026, 4, 21).add(Duration(days: offset)),
              ),
              steps: 12000,
              calories: 2000,
              proteinGrams: 160,
              sleepMinutes: 500,
            ),
        ],
        weeklySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 21)),
            activityMinutes: 170,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 4, 28)),
            activityMinutes: 170,
          ),
          ProgressionSnapshot(
            period: ProgressionPeriod.week(DateTime(2026, 5, 5)),
            activityMinutes: 170,
          ),
        ],
      );

      final lateState = await lateEngine.sync(lateSource);
      final lateQuestsById = {
        for (final quest in lateState.quests) quest.id: quest,
      };

      expect(
        lateQuestsById['daily_four_pillars_today']!.isCompleted,
        isTrue,
      );
      expect(
        lateQuestsById['reach_5000_xp']!.status,
        isNot(ProgressionQuestStatus.locked),
      );
      expect(
        lateQuestsById['weekly_activity_12']!.status,
        ProgressionQuestStatus.locked,
      );
    });
  });

  group('ProgressionLevelPolicy', () {
    test('resolves growing thresholds consistently', () {
      const policy = ProgressionLevelPolicy(xpPerLevel: 250);

      expect(policy.levelForXp(0), 1);
      expect(policy.levelForXp(249), 1);
      expect(policy.levelForXp(250), 2);
      expect(policy.xpRequiredForLevel(1), 0);
      expect(policy.xpRequiredForLevel(2), 250);
      expect(policy.xpRequiredForLevel(3), 555);
      expect(policy.xpRequiredForLevel(10), 5070);

      final profile = policy.resolve(250);
      expect(profile.level, 2);
      expect(profile.levelFloorXp, 250);
      expect(profile.nextLevelXp, 555);
      expect(profile.xpIntoLevel, 0);
      expect(profile.xpToNextLevel, 305);
      expect(profile.levelProgress, 0);
    });

    test('supports a long tail rank ladder beyond level 21', () {
      const policy = ProgressionLevelPolicy();

      expect(policy.resolve(0).levelTitle, 'Novice Adventurer');
      expect(policy.resolve(policy.xpRequiredForLevel(5)).levelTitle,
          'Pathfinder');
      expect(
        policy.resolve(policy.xpRequiredForLevel(10)).levelTitle,
        'Trail Vanguard',
      );
      expect(
        policy.resolve(policy.xpRequiredForLevel(25)).levelTitle,
        'Storm Herald',
      );
      expect(
        policy.resolve(policy.xpRequiredForLevel(100)).levelTitle,
        'Living Legend',
      );
    });
  });

  group('ProgressionRewardFinalizationPolicy', () {
    test('finalizes daily rewards after the next-day grace window', () {
      const policy = ProgressionRewardFinalizationPolicy(
        dailyGraceWindow: Duration(hours: 3),
      );
      final period = ProgressionPeriod.day(DateTime(2026, 4, 21));

      expect(
        policy.finalizationCutoffFor(period),
        DateTime(2026, 4, 22, 3),
      );
      expect(
        policy.canFinalizeReward(
          period: period,
          evaluatedAt: DateTime(2026, 4, 22, 2, 59),
        ),
        isFalse,
      );
      expect(
        policy.canFinalizeReward(
          period: period,
          evaluatedAt: DateTime(2026, 4, 22, 3),
        ),
        isTrue,
      );
    });

    test('finalizes weekly rewards after the next-week grace window', () {
      const policy = ProgressionRewardFinalizationPolicy(
        weeklyGraceWindow: Duration(hours: 3),
      );
      final period = ProgressionPeriod.week(DateTime(2026, 4, 13));

      expect(
        policy.finalizationCutoffFor(period),
        DateTime(2026, 4, 20, 3),
      );
      expect(
        policy.canFinalizeReward(
          period: period,
          evaluatedAt: DateTime(2026, 4, 20, 2, 59),
        ),
        isFalse,
      );
      expect(
        policy.canFinalizeReward(
          period: period,
          evaluatedAt: DateTime(2026, 4, 20, 3),
        ),
        isTrue,
      );
    });
  });

  group('ProgressionEvaluator', () {
    test('treats tolerance boundaries as achieved', () {
      const evaluator = ProgressionEvaluator();
      const rule = ProgressionRuleDefinition(
        id: 'daily_calories',
        version: 'v1',
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.calories,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.withinRelativeTolerance,
        targetValue: 2000,
        toleranceRatio: 0.10,
        rewardXp: 60,
        title: 'Daily Calories',
        description: 'Stay within tolerance',
      );

      final lowerBoundary = evaluator.evaluate(
        rule: rule,
        snapshot: ProgressionSnapshot(
          period: ProgressionPeriod(
            kind: ProgressionPeriodKind.day,
            start: DateTime(2026, 4, 21),
            end: DateTime(2026, 4, 21),
          ),
          calories: 1800,
        ),
      );
      final outsideBoundary = evaluator.evaluate(
        rule: rule,
        snapshot: ProgressionSnapshot(
          period: ProgressionPeriod(
            kind: ProgressionPeriodKind.day,
            start: DateTime(2026, 4, 21),
            end: DateTime(2026, 4, 21),
          ),
          calories: 1799,
        ),
      );

      expect(lowerBoundary.achieved, isTrue);
      expect(lowerBoundary.status, ProgressionEvaluationStatus.achieved);
      expect(lowerBoundary.missReason, isNull);
      expect(outsideBoundary.achieved, isFalse);
      expect(outsideBoundary.status, ProgressionEvaluationStatus.missed);
      expect(outsideBoundary.missReason, ProgressionMissReason.belowMinimum);
      expect(lowerBoundary.explanation, contains('acceptedMin=1800.0'));
      expect(lowerBoundary.explanation, contains('acceptedMax=2200.0'));
    });

    test('supports atMost comparator with aboveMaximum miss reason', () {
      const evaluator = ProgressionEvaluator();
      const rule = ProgressionRuleDefinition(
        id: 'daily_sugar_cap',
        version: 'v1',
        domain: ProgressionDomain.nutrition,
        metric: ProgressionMetric.calories,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.atMost,
        targetValue: 2000,
        rewardXp: 20,
        title: 'Daily Cap',
        description: 'Stay under the cap',
      );

      final evaluation = evaluator.evaluate(
        rule: rule,
        snapshot: ProgressionSnapshot(
          period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
          calories: 2300,
        ),
      );

      expect(evaluation.achieved, isFalse);
      expect(evaluation.status, ProgressionEvaluationStatus.missed);
      expect(evaluation.missReason, ProgressionMissReason.aboveMaximum);
      expect(evaluation.progress, closeTo(2000 / 2300, 0.0001));
      expect(evaluation.explanation, contains('comparator=atMost'));
    });

    test('supports betweenInclusive comparator and stores upper target', () {
      const evaluator = ProgressionEvaluator();
      const rule = ProgressionRuleDefinition(
        id: 'daily_zone',
        version: 'v1',
        domain: ProgressionDomain.sleep,
        metric: ProgressionMetric.sleepMinutes,
        periodKind: ProgressionPeriodKind.day,
        comparator: ProgressionComparator.betweenInclusive,
        targetValue: 420,
        upperTargetValue: 540,
        rewardXp: 20,
        title: 'Sleep Zone',
        description: 'Stay inside target zone',
      );

      final inside = evaluator.evaluate(
        rule: rule,
        snapshot: ProgressionSnapshot(
          period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
          sleepMinutes: 480,
        ),
      );
      final outside = evaluator.evaluate(
        rule: rule,
        snapshot: ProgressionSnapshot(
          period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
          sleepMinutes: 560,
        ),
      );

      expect(inside.achieved, isTrue);
      expect(inside.upperTargetValue, 540);
      expect(outside.achieved, isFalse);
      expect(outside.missReason, ProgressionMissReason.aboveMaximum);
      expect(outside.explanation, contains('upperTarget=540.0'));
      expect(outside.explanation, contains('comparator=betweenInclusive'));
    });
  });
}

class _FakeProgressionSource implements ProgressionSource {
  const _FakeProgressionSource({
    required ProgressionGoalSet goals,
    required this.dailySnapshots,
    required this.weeklySnapshots,
  }) : currentGoals = goals;

  @override
  final ProgressionGoalSet currentGoals;

  ProgressionGoalSet get goals => currentGoals;

  @override
  ProgressionGoalSet goalsForPeriod(ProgressionPeriod period) => currentGoals;

  final List<ProgressionSnapshot> dailySnapshots;
  final List<ProgressionSnapshot> weeklySnapshots;

  @override
  String get auditSignature => 'fake';

  @override
  List<ProgressionSnapshot> buildDailySnapshots() => dailySnapshots;

  @override
  List<ProgressionSnapshot> buildWeeklySnapshots() => weeklySnapshots;
}

class _InMemoryProgressionRepository implements ProgressionRepository {
  final Map<String, ProgressionEvaluation> _evaluations = {};
  final Map<String, ProgressionRewardGrant> _rewardGrants = {};
  Set<String> _activeQuestIds = <String>{};
  DateTime? _lastEvaluatedAt;

  @override
  Future<ProgressionLedgerSnapshot> loadLedger() async {
    return ProgressionLedgerSnapshot(
      evaluations: _evaluations.values.toList(),
      rewardGrants: _rewardGrants.values.toList(),
      activeQuestIds: _activeQuestIds,
      lastEvaluatedAt: _lastEvaluatedAt,
    );
  }

  @override
  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  }) async {
    for (final evaluation in evaluations) {
      _evaluations[evaluation.evaluationKey] = evaluation;
      if (!evaluation.achieved || evaluation.rewardXp <= 0) {
        continue;
      }

      _rewardGrants.putIfAbsent(
        evaluation.rewardKey,
        () => ProgressionRewardGrant(
          rewardKey: evaluation.rewardKey,
          ruleId: evaluation.ruleId,
          ruleVersion: evaluation.ruleVersion,
          domain: evaluation.domain,
          period: evaluation.period,
          xpGranted: evaluation.rewardXp,
          targetValue: evaluation.targetValue,
          actualValue: evaluation.actualValue,
          upperTargetValue: evaluation.upperTargetValue,
          toleranceRatio: evaluation.toleranceRatio,
          rewardStatus: ProgressionRewardStatus.claimed,
          unlockedAt: evaluatedAt,
          claimedAt: evaluatedAt,
        ),
      );
    }

    _lastEvaluatedAt = evaluatedAt;
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimReward({
    required String rewardKey,
    required DateTime claimedAt,
  }) async {
    final reward = _rewardGrants[rewardKey];
    if (reward == null) return loadLedger();
    _rewardGrants[rewardKey] = ProgressionRewardGrant(
      rewardKey: reward.rewardKey,
      ruleId: reward.ruleId,
      ruleVersion: reward.ruleVersion,
      domain: reward.domain,
      period: reward.period,
      xpGranted: reward.xpGranted,
      targetValue: reward.targetValue,
      actualValue: reward.actualValue,
      upperTargetValue: reward.upperTargetValue,
      toleranceRatio: reward.toleranceRatio,
      rewardStatus: ProgressionRewardStatus.claimed,
      unlockedAt: reward.unlockedAt,
      claimedAt: claimedAt,
    );
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimAllRewards({
    required DateTime claimedAt,
  }) async {
    for (final rewardKey in _rewardGrants.keys.toList()) {
      await claimReward(rewardKey: rewardKey, claimedAt: claimedAt);
    }
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  }) async {
    _activeQuestIds = {...activeQuestIds};
    return loadLedger();
  }
}
