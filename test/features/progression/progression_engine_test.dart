import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression/application/progression_engine.dart';
import 'package:forgetrack/features/progression/application/progression_source.dart';
import 'package:forgetrack/features/progression/domain/progression_evaluator.dart';
import 'package:forgetrack/features/progression/domain/progression_level_policy.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';
import 'package:forgetrack/features/progression/domain/progression_quest_evaluator.dart';
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
      expect(achievementsById['level_5']!.unlocked, isFalse);
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

    test('unlocks rolling 30-day step and sleep achievements', () async {
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
          for (var day = 1; day <= 30; day++)
            ProgressionSnapshot(
              period: ProgressionPeriod.day(DateTime(2026, 4, day)),
              steps: 20000,
              sleepMinutes: 480,
            ),
        ],
        weeklySnapshots: const [],
      );

      final state = await engine.sync(source);
      final achievementsById = {
        for (final achievement in state.achievements)
          achievement.id: achievement,
      };

      expect(achievementsById['steps_month_600k']!.unlocked, isTrue);
      expect(achievementsById['steps_month_600k']!.unlockedAt,
          DateTime(2026, 4, 30));
      expect(achievementsById['sleep_month_240h']!.unlocked, isTrue);
      expect(achievementsById['sleep_month_225h']!.unlockedAt,
          DateTime(2026, 4, 29));
      expect(
        achievementsById['steps_month_600k']!.difficulty,
        ProgressionAchievementDifficulty.hard,
      );
      expect(
        achievementsById['sleep_month_240h']!.difficulty,
        ProgressionAchievementDifficulty.extraHard,
      );
    });

    test('unlocks level milestones at actual policy thresholds', () async {
      const levelPolicy = ProgressionLevelPolicy();
      final engine = ProgressionEngine(
        repository: _StaticProgressionRepository(
          rewardGrants: [
            _claimedReward(
              rewardKey: 'xp-100',
              xpGranted: levelPolicy.xpRequiredForLevel(100),
              progressionAt: DateTime(2026, 4, 30, 9),
            ),
          ],
        ),
        clock: () => DateTime(2026, 4, 30, 9),
      );

      final state = await engine.load();
      final achievementsById = {
        for (final achievement in state.achievements)
          achievement.id: achievement,
      };

      expect(state.profile.level, 100);
      expect(achievementsById['level_5']!.unlocked, isTrue);
      expect(achievementsById['level_10']!.unlocked, isTrue);
      expect(achievementsById['level_20']!.unlocked, isTrue);
      expect(achievementsById['level_50']!.unlocked, isTrue);
      expect(achievementsById['level_100']!.unlocked, isTrue);
      expect(
        achievementsById['level_100']!.difficulty,
        ProgressionAchievementDifficulty.extraHard,
      );
      expect(
        achievementsById['level_100']!.unlockedAt,
        DateTime(2026, 4, 30, 9),
      );
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
        ProgressionQuestStatus.locked,
      );
      final comboPoolStatuses = [
        questsById['daily_two_goals_today']!.status,
        questsById['daily_triple_win_today']!.status,
        questsById['daily_four_pillars_today']!.status,
        questsById['daily_nutrition_combo_today']!.status,
        questsById['daily_nutrition_carbs_combo_today']!.status,
        questsById['daily_nutrition_fat_combo_today']!.status,
        questsById['daily_nutrition_fiber_combo_today']!.status,
        questsById['daily_recovery_focus_today']!.status,
      ];
      expect(
        comboPoolStatuses.where(
          (status) => status != ProgressionQuestStatus.locked,
        ),
        hasLength(1),
      );
      expect(
        questsById['daily_protein_today']!.status,
        ProgressionQuestStatus.active,
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
      expect(
          questsById['earn_25_rewards']!.status, ProgressionQuestStatus.active);
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
        greaterThan(6),
      );
      expect(questsById['steps_streak_3']!.isHighlighted, isTrue);
      expect(questsById['daily_triple_win_today']!.isHighlighted, isFalse);
      expect(
        [
          questsById['daily_two_goals_today']!.isHighlighted,
          questsById['daily_nutrition_combo_today']!.isHighlighted,
          questsById['daily_recovery_focus_today']!.isHighlighted,
        ].where((highlighted) => highlighted),
        hasLength(lessThanOrEqualTo(1)),
      );
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

    test('chapter quests count only evaluations after chapter start', () {
      final evaluator = ProgressionQuestEvaluator();
      final beforeStart = DateTime(2026, 4, 10);
      final start = DateTime(2026, 4, 20, 9);
      final afterStart = DateTime(2026, 4, 21);
      final definitions = [
        ProgressionQuestDefinition(
          id: 'test_chapter_open',
          title: (l10n) => 'Open',
          description: (l10n) => 'Open',
          type: ProgressionQuestType.milestone,
          category: ProgressionQuestCategory.chapter,
          criterionType: ProgressionQuestCriterionType.chapterStarted,
          targetValue: 1,
          rewardXp: 1,
          minimumLevel: 10,
          chainId: 'test_chapter',
          chapterId: 'test_chapter',
          progressStartPolicy: ProgressionProgressStartPolicy.chapterStartedAt,
          nextQuestIds: const ['test_chapter_steps'],
        ),
        ProgressionQuestDefinition(
          id: 'test_chapter_steps',
          title: (l10n) => 'Steps',
          description: (l10n) => 'Steps',
          type: ProgressionQuestType.mastery,
          category: ProgressionQuestCategory.chapter,
          criterionType: ProgressionQuestCriterionType.ruleCompletionsAtLeast,
          targetValue: 2,
          rewardXp: 1,
          ruleId: 'daily_steps',
          periodKind: ProgressionPeriodKind.day,
          prerequisiteQuestIds: const ['test_chapter_open'],
          chainId: 'test_chapter',
          chapterId: 'test_chapter',
          progressStartPolicy: ProgressionProgressStartPolicy.chapterStartedAt,
        ),
      ];

      final result = evaluator.evaluate(
        definitions: definitions,
        previousActiveQuestIds: const <String>{},
        evaluationDate: DateTime(2026, 4, 22),
        profile: const ProgressionProfile(
          totalXp: 0,
          level: 10,
          levelFloorXp: 0,
          nextLevelXp: 100,
          xpIntoLevel: 0,
        ),
        evaluations: [
          _achievedEvaluation('daily_steps', beforeStart),
          _achievedEvaluation('daily_steps', afterStart),
        ],
        rewardGrants: const [],
        questRewardGrants: const [],
        chapterStarts: [
          ProgressionChapterStartRecord(
            uid: '',
            chapterId: 'test_chapter',
            startedAtLevel: 10,
            startedAt: start,
          ),
        ],
        achievements: const [],
        streaksByRuleId: const {},
        streaksByDomain: const {},
      );

      final stepQuest =
          result.quests.firstWhere((quest) => quest.id == 'test_chapter_steps');
      expect(stepQuest.currentValue, 1);
      expect(stepQuest.isCompleted, isFalse);
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
          ProgressionQuestStatus.active);
      expect(questsById['daily_steps_today']!.currentValue, 0);
      expect(
        questsById['daily_two_goals_today']!.status,
        ProgressionQuestStatus.locked,
      );
      expect(questsById['daily_two_goals_today']!.currentValue, 1);
      expect(
        questsById['daily_triple_win_today']!.status,
        ProgressionQuestStatus.active,
      );
      final comboPoolStatuses = [
        questsById['daily_two_goals_today']!.status,
        questsById['daily_triple_win_today']!.status,
        questsById['daily_four_pillars_today']!.status,
        questsById['daily_nutrition_combo_today']!.status,
        questsById['daily_nutrition_carbs_combo_today']!.status,
        questsById['daily_nutrition_fat_combo_today']!.status,
        questsById['daily_nutrition_fiber_combo_today']!.status,
        questsById['daily_recovery_focus_today']!.status,
      ];
      expect(
        comboPoolStatuses.where(
          (status) => status != ProgressionQuestStatus.locked,
        ),
        hasLength(1),
      );
      expect(
        questsById['daily_protein_today']!.status,
        ProgressionQuestStatus.active,
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

    test('creates quest reward grants only once when quests first complete',
        () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
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
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final firstState = await engine.sync(source);
      final secondState = await engine.sync(source);
      final firstRewardQuest = firstState.quests
          .firstWhere((quest) => quest.id == 'earn_first_reward');
      final firstRewardGrant = firstState.questRewardGrants.firstWhere(
        (grant) => grant.questId == 'earn_first_reward',
      );

      expect(firstRewardQuest.isCompleted, isTrue);
      expect(firstRewardQuest.isRewardClaimable, isTrue);
      expect(firstRewardQuest.isRewardClaimed, isFalse);
      expect(firstRewardQuest.rewardKey, firstRewardGrant.rewardKey);
      expect(firstRewardQuest.rewardXp, firstRewardGrant.xpGranted);
      expect(firstRewardGrant.baseXp, 80);
      expect(firstRewardGrant.rewardStatus, ProgressionRewardStatus.unlocked);
      expect(
        secondState.questRewardGrants
            .where((grant) => grant.questId == 'earn_first_reward'),
        hasLength(1),
      );
    });

    test('claiming a quest reward is idempotent and adds bonus xp once',
        () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
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
            sleepMinutes: 500,
          ),
        ],
        weeklySnapshots: const [],
      );

      final syncedState = await engine.sync(source);
      final firstRewardQuest = syncedState.quests
          .firstWhere((quest) => quest.id == 'earn_first_reward');
      final firstClaimedState =
          await engine.claimQuestReward(firstRewardQuest.rewardKey!);
      final secondClaimedState =
          await engine.claimQuestReward(firstRewardQuest.rewardKey!);
      final firstClaimedGrant = firstClaimedState.questRewardGrants.firstWhere(
        (grant) => grant.rewardKey == firstRewardQuest.rewardKey,
      );
      final secondClaimedGrant =
          secondClaimedState.questRewardGrants.firstWhere(
        (grant) => grant.rewardKey == firstRewardQuest.rewardKey,
      );

      expect(
        firstClaimedState.profile.totalXp,
        syncedState.profile.totalXp + firstRewardQuest.rewardXp,
      );
      expect(
        secondClaimedState.profile.totalXp,
        firstClaimedState.profile.totalXp,
      );
      expect(firstClaimedGrant.isClaimed, isTrue);
      expect(secondClaimedGrant.isClaimed, isTrue);
      expect(secondClaimedGrant.claimedAt, firstClaimedGrant.claimedAt);
      expect(
        secondClaimedState.questRewardGrants
            .where((grant) => grant.rewardKey == firstRewardQuest.rewardKey),
        hasLength(1),
      );
    });

    test('keeps reward and quest bulk claim flows separate', () async {
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          _unlockedReward(
            rewardKey: 'reward-steps-1',
            xpGranted: 120,
            progressionAt: DateTime(2026, 4, 21, 9),
          ),
        ],
        questRewardGrants: [
          _unlockedQuestReward(
            rewardKey: 'quest|earn_first_reward|reward',
            questId: 'earn_first_reward',
            xpGranted: 80,
            completedAt: DateTime(2026, 4, 21, 9),
            unlockedAt: DateTime(2026, 4, 21, 9, 30),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 23, 9),
      );

      final rewardsClaimed = await engine.claimAllRewards();
      final questsClaimed = await engine.claimAllQuestRewards();

      expect(rewardsClaimed.rewardGrants.single.isClaimed, isTrue);
      expect(rewardsClaimed.questRewardGrants.single.isUnlocked, isTrue);
      expect(rewardsClaimed.profile.totalXp, 120);

      expect(questsClaimed.rewardGrants.single.isClaimed, isTrue);
      expect(questsClaimed.questRewardGrants.single.isClaimed, isTrue);
      expect(questsClaimed.profile.totalXp, 200);
    });

    test('does not count quest rewards toward reward-count achievements',
        () async {
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          for (var index = 0; index < 24; index++)
            _claimedReward(
              rewardKey: 'reward-$index',
              xpGranted: 10,
              progressionAt: DateTime(2026, 4, 1).add(Duration(days: index)),
            ),
        ],
        questRewardGrants: [
          for (var index = 0; index < 5; index++)
            _claimedQuestReward(
              rewardKey: 'quest-reward-$index',
              questId: 'quest-$index',
              xpGranted: 80,
              completedAt: DateTime(2026, 4, 20).add(Duration(days: index)),
              claimedAt: DateTime(2026, 4, 20).add(Duration(days: index)),
            ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 25, 9),
      );

      final state = await engine.load();
      final rewardCountAchievement = state.achievements.firstWhere(
        (achievement) => achievement.id == 'reward_hunter_25',
      );

      expect(rewardCountAchievement.unlocked, isFalse);
      expect(rewardCountAchievement.currentValue, 24);
    });

    // ── Phase 2: XP scaling and claim-time snapshot ────────────────────────

    test('unclaimed rule rewards do not contribute to profile XP or level',
        () async {
      const levelPolicy = ProgressionLevelPolicy();
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          for (var i = 0; i < 5; i++)
            _unlockedReward(
              rewardKey: 'reward-$i',
              xpGranted: levelPolicy.xpRequiredForLevel(10),
              progressionAt: DateTime(2026, 4, 1).add(Duration(days: i)),
            ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state = await engine.load();

      expect(state.profile.totalXp, 0);
      expect(state.profile.level, 1);
    });

    test('unclaimed rewards do not inflate level used for new reward scaling',
        () async {
      const levelPolicy = ProgressionLevelPolicy();
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          for (var i = 0; i < 10; i++)
            _unlockedReward(
              rewardKey: 'reward-$i',
              xpGranted: levelPolicy.xpRequiredForLevel(10),
              progressionAt: DateTime(2026, 4, 1).add(Duration(days: i)),
            ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 15, 9),
      );

      // Sync with a new day that meets the steps goal.
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
            period: ProgressionPeriod.day(DateTime(2026, 4, 15)),
            steps: 12000,
          ),
        ],
        weeklySnapshots: const [],
      );
      final state = await engine.sync(source);

      // The new steps grant must be scaled at level 1 (0 claimed XP),
      // not at the inflated level the unclaimed grants would produce.
      // daily_steps rule has rewardXp: 80; at level 1 multiplier = 1.0.
      const stepsBaseXp = 80;
      final newGrant = state.rewardGrants.firstWhere(
        (g) =>
            g.ruleId == 'daily_steps' &&
            g.period.start == DateTime(2026, 4, 15),
      );
      final expectedXp =
          levelPolicy.scaledRewardXp(baseXp: stepsBaseXp, level: 1);
      expect(newGrant.xpGranted, expectedXp);
    });

    test('finalXp is frozen at claim-time level', () async {
      const levelPolicy = ProgressionLevelPolicy();
      // Pre-load enough claimed XP to put the user at level 2.
      final level2Xp = levelPolicy.xpRequiredForLevel(2);
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          _claimedReward(
            rewardKey: 'seed-reward',
            xpGranted: level2Xp,
            progressionAt: DateTime(2026, 4, 1),
          ),
          _unlockedReward(
            rewardKey: 'pending-reward',
            xpGranted: levelPolicy.baseDailyRewardXp,
            progressionAt: DateTime(2026, 4, 2),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state = await engine.claimReward('pending-reward');
      final claimedGrant =
          state.rewardGrants.firstWhere((g) => g.rewardKey == 'pending-reward');

      final expectedFinalXp = levelPolicy.scaledRewardXp(
        baseXp: levelPolicy.baseDailyRewardXp,
        level: 2,
      );
      expect(claimedGrant.isClaimed, isTrue);
      expect(claimedGrant.finalXp, expectedFinalXp);
      expect(claimedGrant.levelAtClaim, 2);
      expect(state.profile.totalXp, level2Xp + expectedFinalXp);
    });

    test('claimQuestReward does not double-scale legacy pending quest XP',
        () async {
      const levelPolicy = ProgressionLevelPolicy();
      final level51Xp = levelPolicy.xpRequiredForLevel(51);
      final scaledPreviewXp = levelPolicy.scaledRewardXp(
        baseXp: 80,
        level: 51,
      );
      final doubleScaledXp = levelPolicy.scaledRewardXp(
        baseXp: scaledPreviewXp,
        level: 51,
      );
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          _claimedReward(
            rewardKey: 'seed-level-51',
            xpGranted: level51Xp,
            progressionAt: DateTime(2026, 4, 1),
          ),
        ],
        questRewardGrants: [
          ProgressionQuestRewardGrant(
            rewardKey: 'quest|earn_first_reward|reward',
            questId: 'earn_first_reward',
            // Old buggy records stored a level-scaled preview here without
            // preserving the raw quest base XP.
            xpGranted: scaledPreviewXp,
            rewardStatus: ProgressionRewardStatus.unlocked,
            unlockedAt: DateTime(2026, 4, 2),
            completedAt: DateTime(2026, 4, 2),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state =
          await engine.claimQuestReward('quest|earn_first_reward|reward');
      final claimedGrant = state.questRewardGrants.firstWhere(
        (g) => g.rewardKey == 'quest|earn_first_reward|reward',
      );

      expect(claimedGrant.finalXp, scaledPreviewXp);
      expect(claimedGrant.finalXp, isNot(doubleScaledXp));
      expect(state.profile.totalXp, level51Xp + scaledPreviewXp);
    });

    test('claimReward persists newly unlocked level achievements', () async {
      const levelPolicy = ProgressionLevelPolicy();
      final level5Xp = levelPolicy.xpRequiredForLevel(5);
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          _unlockedReward(
            rewardKey: 'pending-level-5',
            xpGranted: level5Xp,
            progressionAt: DateTime(2026, 4, 2),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state = await engine.claimReward('pending-level-5');
      final ledger = await repository.loadLedger();
      final persistedIds =
          ledger.achievementUnlocks.map((unlock) => unlock.achievementId);

      expect(state.profile.level, 5);
      expect(state.achievements.firstWhere((a) => a.id == 'level_5').unlocked,
          isTrue);
      expect(persistedIds, contains('level_5'));
    });

    test('load backfills missing achievement unlock records', () async {
      const levelPolicy = ProgressionLevelPolicy();
      final level5Xp = levelPolicy.xpRequiredForLevel(5);
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          _claimedReward(
            rewardKey: 'historical-level-5',
            xpGranted: level5Xp,
            progressionAt: DateTime(2026, 4, 2),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state = await engine.load();
      final ledger = await repository.loadLedger();
      final persistedIds =
          ledger.achievementUnlocks.map((unlock) => unlock.achievementId);

      expect(state.profile.level, 5);
      expect(persistedIds, contains('level_5'));
    });

    test(
        'claimAllRewards processes in chronological order with cumulative level',
        () async {
      const levelPolicy = ProgressionLevelPolicy();
      // Enough claimed XP to start at level 2.
      final level2Xp = levelPolicy.xpRequiredForLevel(2);
      final level3Xp = levelPolicy.xpRequiredForLevel(3);

      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          _claimedReward(
            rewardKey: 'seed',
            xpGranted: level2Xp,
            progressionAt: DateTime(2026, 4, 1),
          ),
          _unlockedReward(
            rewardKey: 'reward-day1',
            xpGranted: levelPolicy.baseDailyRewardXp,
            progressionAt: DateTime(2026, 4, 2),
          ),
          _unlockedReward(
            rewardKey: 'reward-day2',
            xpGranted: levelPolicy.baseDailyRewardXp,
            progressionAt: DateTime(2026, 4, 3),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state = await engine.claimAllRewards();
      final grant1 =
          state.rewardGrants.firstWhere((g) => g.rewardKey == 'reward-day1');
      final grant2 =
          state.rewardGrants.firstWhere((g) => g.rewardKey == 'reward-day2');

      // grant1 claimed at level 2 (seed XP = xpRequiredForLevel(2))
      final expectedXpLevel2 = levelPolicy.scaledRewardXp(
        baseXp: levelPolicy.baseDailyRewardXp,
        level: 2,
      );
      expect(grant1.finalXp, expectedXpLevel2);
      expect(grant1.levelAtClaim, 2);

      // grant2 claimed after grant1 — running XP = level2Xp + expectedXpLevel2
      final runningAfterGrant1 = level2Xp + expectedXpLevel2;
      final levelAfterGrant1 = levelPolicy.levelForXp(runningAfterGrant1);
      final expectedXpGrant2 = levelPolicy.scaledRewardXp(
        baseXp: levelPolicy.baseDailyRewardXp,
        level: levelAfterGrant1,
      );
      expect(grant2.finalXp, expectedXpGrant2);

      // Total XP = seed + grant1.finalXp + grant2.finalXp
      expect(
        state.profile.totalXp,
        level2Xp + expectedXpLevel2 + expectedXpGrant2,
      );

      // Verify we don't accidentally level into level 3 range just from these
      // test values — keep the expectation structural, not hard-coded.
      final level3Threshold = level3Xp;
      expect(runningAfterGrant1 < level3Threshold || levelAfterGrant1 >= 3,
          isTrue);
    });

    test('already-claimed migrated grant keeps counting toward XP', () async {
      const levelPolicy = ProgressionLevelPolicy();
      final historicalXp = levelPolicy.xpRequiredForLevel(5);
      final repository = _InMemoryProgressionRepository(
        rewardGrants: [
          // Simulates a record claimed before Phase 2 (finalXp is null).
          _claimedReward(
            rewardKey: 'legacy-reward',
            xpGranted: historicalXp,
            progressionAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 10, 9),
      );

      final state = await engine.load();

      expect(state.profile.totalXp, historicalXp);
      expect(state.profile.level, 5);
    });

    test('claimed reward remains valid if later evaluation becomes false',
        () async {
      final repository = _InMemoryProgressionRepository();
      final engine = ProgressionEngine(
        repository: repository,
        clock: () => DateTime(2026, 4, 21, 8),
      );

      final achievedSource = _FakeProgressionSource(
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
          ),
        ],
        weeklySnapshots: const [],
      );
      final syncedState = await engine.sync(achievedSource);
      final stepsGrant = syncedState.rewardGrants.firstWhere(
        (g) => g.ruleId == 'daily_steps',
      );
      // Auto-claimed in the in-memory repo; record the XP.
      final xpBefore = stepsGrant.effectiveXpGranted;

      // Now re-sync with missed steps — evaluation becomes false.
      final missedSource = _FakeProgressionSource(
        goals: achievedSource.goals,
        dailySnapshots: [
          ProgressionSnapshot(
            period: ProgressionPeriod.day(DateTime(2026, 4, 21)),
            steps: 5000,
          ),
        ],
        weeklySnapshots: const [],
      );
      final resyncedState = await engine.sync(missedSource);
      final resyncedGrant = resyncedState.rewardGrants.firstWhere(
        (g) => g.ruleId == 'daily_steps',
      );

      // Grant must still be claimed; XP unchanged.
      expect(resyncedGrant.isClaimed, isTrue);
      expect(resyncedGrant.effectiveXpGranted, xpBefore);
      expect(resyncedState.profile.totalXp, syncedState.profile.totalXp);
    });

    group('XP display consistency', () {
      test(
          'claimed rule grant with finalXp returns finalXp from effectiveXpGranted',
          () {
        final grant = ProgressionRewardGrant(
          rewardKey: 'daily_steps|v1|day|2026-04-01|reward',
          ruleId: 'daily_steps',
          ruleVersion: 'v1',
          domain: ProgressionDomain.steps,
          period: ProgressionPeriod(
            kind: ProgressionPeriodKind.day,
            start: DateTime(2026, 4, 1),
            end: DateTime(2026, 4, 2),
          ),
          xpGranted: 80,
          targetValue: 10000,
          actualValue: 10000,
          rewardStatus: ProgressionRewardStatus.claimed,
          unlockedAt: DateTime(2026, 4, 1),
          claimedAt: DateTime(2026, 4, 1),
          finalXp: 778,
          levelAtClaim: 10,
        );

        expect(grant.isClaimed, isTrue);
        expect(grant.effectiveXpGranted, 778);
      });

      test('legacy claimed grant with null finalXp falls back to xpGranted',
          () {
        final grant = ProgressionRewardGrant(
          rewardKey: 'legacy|reward',
          ruleId: 'daily_steps',
          ruleVersion: 'v1',
          domain: ProgressionDomain.steps,
          period: ProgressionPeriod(
            kind: ProgressionPeriodKind.day,
            start: DateTime(2026, 1, 1),
            end: DateTime(2026, 1, 2),
          ),
          xpGranted: 80,
          targetValue: 10000,
          actualValue: 10000,
          rewardStatus: ProgressionRewardStatus.claimed,
          unlockedAt: DateTime(2026, 1, 1),
          claimedAt: DateTime(2026, 1, 1),
          // finalXp intentionally left null — legacy record
        );

        expect(grant.isClaimed, isTrue);
        expect(grant.finalXp, isNull);
        expect(grant.effectiveXpGranted, 80);
      });

      test(
          'unclaimed quest shows current-level preview, not stale grant xpGranted',
          () async {
        const levelPolicy = ProgressionLevelPolicy();
        // Seed enough claimed XP to reach level 3.
        final level3Xp = levelPolicy.xpRequiredForLevel(3);
        final repository = _InMemoryProgressionRepository(
          rewardGrants: [
            _claimedReward(
              rewardKey: 'seed',
              xpGranted: level3Xp,
              progressionAt: DateTime(2026, 4, 1),
            ),
          ],
          questRewardGrants: [
            _unlockedQuestReward(
              rewardKey: 'quest|earn_first_reward|reward',
              questId: 'earn_first_reward',
              // stale xpGranted stored at level-1 time (earn_first_reward has rewardXp=80)
              xpGranted: levelPolicy.scaledRewardXp(
                baseXp: 80,
                level: 1,
              ),
              completedAt: DateTime(2026, 4, 2),
              unlockedAt: DateTime(2026, 4, 2),
            ),
          ],
        );
        final engine = ProgressionEngine(
          repository: repository,
          clock: () => DateTime(2026, 4, 10, 9),
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
              period: ProgressionPeriod.day(DateTime(2026, 4, 10)),
              steps: 12000,
            ),
          ],
          weeklySnapshots: const [],
        );

        final state = await engine.sync(source);
        final quest = state.quests.firstWhere(
          (q) => q.id == 'earn_first_reward',
          orElse: () => throw StateError('quest not found'),
        );
        // Preview XP must be the current-level-3 estimate (earn_first_reward rewardXp=80),
        // not the stale level-1 value stored on the grant.
        final staleXp = levelPolicy.scaledRewardXp(baseXp: 80, level: 1);
        final expectedPreviewXp = levelPolicy.scaledRewardXp(
          baseXp: 80,
          level: 3,
        );
        expect(quest.rewardXp, isNot(staleXp));
        expect(quest.rewardXp, expectedPreviewXp);
      });

      test('claimed quest reward shows effectiveXpGranted in quest.rewardXp',
          () async {
        const levelPolicy = ProgressionLevelPolicy();
        final level2Xp = levelPolicy.xpRequiredForLevel(2);
        final claimedFinalXp =
            levelPolicy.scaledRewardXp(baseXp: 100, level: 2);
        final repository = _InMemoryProgressionRepository(
          rewardGrants: [
            _claimedReward(
              rewardKey: 'seed',
              xpGranted: level2Xp,
              progressionAt: DateTime(2026, 4, 1),
            ),
          ],
          questRewardGrants: [
            ProgressionQuestRewardGrant(
              rewardKey: 'quest|earn_first_reward|reward',
              questId: 'earn_first_reward',
              xpGranted: 100,
              rewardStatus: ProgressionRewardStatus.claimed,
              unlockedAt: DateTime(2026, 4, 2),
              completedAt: DateTime(2026, 4, 2),
              claimedAt: DateTime(2026, 4, 2),
              finalXp: claimedFinalXp,
              levelAtClaim: 2,
            ),
          ],
        );
        final engine = ProgressionEngine(
          repository: repository,
          clock: () => DateTime(2026, 4, 10, 9),
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
              period: ProgressionPeriod.day(DateTime(2026, 4, 10)),
              steps: 12000,
            ),
          ],
          weeklySnapshots: const [],
        );

        final state = await engine.sync(source);
        final quest = state.quests.firstWhere(
          (q) => q.id == 'earn_first_reward',
          orElse: () => throw StateError('quest not found'),
        );
        // Claimed quest must show finalXp, not evaluation-time xpGranted.
        expect(quest.rewardXp, claimedFinalXp);
        expect(quest.rewardXp, isNot(100));
      });
    });
  });

  group('ProgressionLevelPolicy', () {
    test('resolves inflated late-game thresholds consistently', () {
      const policy = ProgressionLevelPolicy();

      expect(policy.levelForXp(0), 1);
      expect(policy.levelForXp(274), 1);
      expect(policy.levelForXp(275), 2);
      expect(policy.xpRequiredForLevel(1), 0);
      expect(policy.xpRequiredForLevel(2), 275);
      expect(policy.xpRequiredForLevel(3), 725);
      expect(policy.xpRequiredForLevel(10), 10775);
      expect(policy.xpRequiredForLevel(50), 1899850);
      expect(policy.xpRequiredForLevel(100), 23963725);

      final profile = policy.resolve(275);
      expect(profile.level, 2);
      expect(profile.levelFloorXp, 275);
      expect(profile.nextLevelXp, 725);
      expect(profile.xpIntoLevel, 0);
      expect(profile.xpToNextLevel, 450);
      expect(profile.levelProgress, 0);
    });

    test('resolve() returns the expected level for tier-boundary XP totals',
        () {
      const policy = ProgressionLevelPolicy();

      expect(policy.resolve(0).level, 1);
      expect(policy.resolve(policy.xpRequiredForLevel(5)).level, 5);
      expect(policy.resolve(policy.xpRequiredForLevel(10)).level, 10);
      expect(policy.resolve(policy.xpRequiredForLevel(25)).level, 25);
      expect(policy.resolve(policy.xpRequiredForLevel(100)).level, 100);
    });

    test('scales reward XP aggressively while keeping late levels slower', () {
      const policy = ProgressionLevelPolicy();

      expect(
        policy.scaledRewardXp(baseXp: 80, level: 1),
        80,
      );
      expect(
        policy.scaledRewardXp(baseXp: 80, level: 30),
        1000,
      );
      expect(
        policy.scaledRewardXp(baseXp: 80, level: 50),
        5000,
      );
      expect(
        policy.scaledRewardXp(baseXp: 80, level: 100),
        12000,
      );
      expect(policy.targetDaysForLevel(30),
          greaterThan(policy.targetDaysForLevel(10)));
      expect(policy.targetDaysForLevel(50),
          greaterThan(policy.targetDaysForLevel(30)));
      expect(policy.targetDaysForLevel(100),
          greaterThan(policy.targetDaysForLevel(50)));
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
  _InMemoryProgressionRepository({
    List<ProgressionEvaluation> evaluations = const [],
    List<ProgressionRewardGrant> rewardGrants = const [],
    List<ProgressionQuestRewardGrant> questRewardGrants = const [],
    List<ProgressionChapterStartRecord> chapterStarts = const [],
    Set<String> activeQuestIds = const <String>{},
    DateTime? lastEvaluatedAt,
  })  : _activeQuestIds = {...activeQuestIds},
        _lastEvaluatedAt = lastEvaluatedAt {
    for (final evaluation in evaluations) {
      _evaluations[evaluation.evaluationKey] = evaluation;
    }
    for (final grant in rewardGrants) {
      _rewardGrants[grant.rewardKey] = grant;
    }
    for (final grant in questRewardGrants) {
      _questRewardGrants[grant.rewardKey] = grant;
    }
    for (final start in chapterStarts) {
      _chapterStarts[start.startKey] = start;
    }
  }

  final Map<String, ProgressionEvaluation> _evaluations = {};
  final Map<String, ProgressionRewardGrant> _rewardGrants = {};
  final Map<String, ProgressionQuestRewardGrant> _questRewardGrants = {};
  final Map<String, ProgressionAchievementUnlockEvent> _achievementUnlocks = {};
  final Map<String, ProgressionChapterStartRecord> _chapterStarts = {};
  Set<String> _activeQuestIds;
  DateTime? _lastEvaluatedAt;

  @override
  Future<ProgressionLedgerSnapshot> loadLedger() async {
    return ProgressionLedgerSnapshot(
      evaluations: _evaluations.values.toList(),
      rewardGrants: _rewardGrants.values.toList(),
      questRewardGrants: _questRewardGrants.values.toList(),
      activeQuestIds: _activeQuestIds,
      achievementUnlocks: _achievementUnlocks.values.toList(),
      chapterStarts: _chapterStarts.values.toList(),
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
          baseXp: evaluation.baseXp,
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
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    final reward = _rewardGrants[rewardKey];
    if (reward == null) return loadLedger();
    if (reward.isClaimed) return loadLedger();
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
      finalXp: finalXp,
      levelAtClaim: levelAtClaim,
      multiplierAtClaim: multiplierAtClaim,
      baseXp: reward.baseXp,
    );
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  }) async {
    for (final grant in grants) {
      _questRewardGrants.putIfAbsent(grant.rewardKey, () => grant);
    }
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    final reward = _questRewardGrants[rewardKey];
    if (reward == null) return loadLedger();
    if (reward.isClaimed) return loadLedger();
    _questRewardGrants[rewardKey] = ProgressionQuestRewardGrant(
      rewardKey: reward.rewardKey,
      questId: reward.questId,
      xpGranted: reward.xpGranted,
      rewardStatus: ProgressionRewardStatus.claimed,
      unlockedAt: reward.unlockedAt,
      completedAt: reward.completedAt,
      claimedAt: claimedAt,
      finalXp: finalXp,
      levelAtClaim: levelAtClaim,
      multiplierAtClaim: multiplierAtClaim,
      baseXp: reward.baseXp,
    );
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  }) async {
    _activeQuestIds = {...activeQuestIds};
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistAchievementUnlocks({
    required List<ProgressionAchievementUnlockEvent> unlocks,
  }) async {
    for (final unlock in unlocks) {
      _achievementUnlocks.putIfAbsent(unlock.achievementId, () => unlock);
    }
    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistChapterStarts({
    required List<ProgressionChapterStartRecord> starts,
  }) async {
    for (final start in starts) {
      _chapterStarts.putIfAbsent(start.startKey, () => start);
    }
    return loadLedger();
  }
}

class _StaticProgressionRepository implements ProgressionRepository {
  const _StaticProgressionRepository({
    this.rewardGrants = const [],
  });

  final List<ProgressionEvaluation> evaluations = const [];
  final List<ProgressionRewardGrant> rewardGrants;
  final List<ProgressionQuestRewardGrant> questRewardGrants = const [];
  final Set<String> activeQuestIds = const <String>{};
  final DateTime? lastEvaluatedAt = null;

  @override
  Future<ProgressionLedgerSnapshot> loadLedger() async {
    return ProgressionLedgerSnapshot(
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      activeQuestIds: activeQuestIds,
      lastEvaluatedAt: lastEvaluatedAt,
    );
  }

  @override
  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  }) async =>
      loadLedger();

  @override
  Future<ProgressionLedgerSnapshot> claimReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async =>
      loadLedger();

  @override
  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  }) async =>
      loadLedger();

  @override
  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async =>
      loadLedger();

  @override
  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  }) async =>
      loadLedger();

  @override
  Future<ProgressionLedgerSnapshot> persistAchievementUnlocks({
    required List<ProgressionAchievementUnlockEvent> unlocks,
  }) async =>
      loadLedger();

  @override
  Future<ProgressionLedgerSnapshot> persistChapterStarts({
    required List<ProgressionChapterStartRecord> starts,
  }) async =>
      loadLedger();
}

ProgressionRewardGrant _claimedReward({
  required String rewardKey,
  required int xpGranted,
  required DateTime progressionAt,
}) {
  return ProgressionRewardGrant(
    rewardKey: rewardKey,
    ruleId: 'daily_steps',
    ruleVersion: 'test',
    domain: ProgressionDomain.steps,
    period: ProgressionPeriod.day(progressionAt),
    xpGranted: xpGranted,
    targetValue: 10000,
    actualValue: 10000,
    rewardStatus: ProgressionRewardStatus.claimed,
    unlockedAt: progressionAt,
    claimedAt: progressionAt,
  );
}

ProgressionRewardGrant _unlockedReward({
  required String rewardKey,
  required int xpGranted,
  required DateTime progressionAt,
}) {
  return ProgressionRewardGrant(
    rewardKey: rewardKey,
    ruleId: 'daily_steps',
    ruleVersion: 'test',
    domain: ProgressionDomain.steps,
    period: ProgressionPeriod.day(progressionAt),
    xpGranted: xpGranted,
    targetValue: 10000,
    actualValue: 10000,
    rewardStatus: ProgressionRewardStatus.unlocked,
    unlockedAt: progressionAt,
  );
}

ProgressionQuestRewardGrant _claimedQuestReward({
  required String rewardKey,
  required String questId,
  required int xpGranted,
  required DateTime completedAt,
  required DateTime claimedAt,
}) {
  return ProgressionQuestRewardGrant(
    rewardKey: rewardKey,
    questId: questId,
    xpGranted: xpGranted,
    rewardStatus: ProgressionRewardStatus.claimed,
    unlockedAt: completedAt,
    completedAt: completedAt,
    claimedAt: claimedAt,
  );
}

ProgressionQuestRewardGrant _unlockedQuestReward({
  required String rewardKey,
  required String questId,
  required int xpGranted,
  required DateTime completedAt,
  required DateTime unlockedAt,
}) {
  return ProgressionQuestRewardGrant(
    rewardKey: rewardKey,
    questId: questId,
    xpGranted: xpGranted,
    rewardStatus: ProgressionRewardStatus.unlocked,
    unlockedAt: unlockedAt,
    completedAt: completedAt,
  );
}

ProgressionEvaluation _achievedEvaluation(String ruleId, DateTime day) {
  return ProgressionEvaluation(
    evaluationKey: '$ruleId|v1|day|${progressionDateKey(day)}',
    rewardKey: '$ruleId|v1|day|${progressionDateKey(day)}|reward',
    ruleId: ruleId,
    ruleVersion: 'v1',
    domain: ProgressionDomain.steps,
    period: ProgressionPeriod.day(day),
    comparator: ProgressionComparator.atLeast,
    actualValue: 1,
    targetValue: 1,
    upperTargetValue: null,
    toleranceRatio: 0,
    progress: 1,
    achieved: true,
    status: ProgressionEvaluationStatus.achieved,
    missReason: null,
    rewardXp: 0,
    title: ruleId,
    description: ruleId,
    explanation: 'test',
  );
}
