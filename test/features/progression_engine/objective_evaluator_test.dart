import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/domain/evaluator/objective_evaluator.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_context.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';

import '_engine_test_helpers.dart';

EngineEvaluationContext _input({
  int stepsToday = 0,
  int stepsThisWeek = 0,
  int stepsLifetime = 0,
  int level = 1,
  int totalXp = 0,
  int totalRewardCount = 0,
  Map<String, int> nodeCompletionCounts = const {},
  Map<String, int> comboPoolCompletionCounts = const {},
}) =>
    buildTestContext(
      evaluatedAt: DateTime(2026, 5, 10, 12),
      stepsToday: stepsToday,
      stepsThisWeek: stepsThisWeek,
      stepsLifetime: stepsLifetime,
      level: level,
      totalXp: totalXp,
      totalRewardCount: totalRewardCount,
      nodeCompletionCounts: nodeCompletionCounts,
      comboPoolCompletionCounts: comboPoolCompletionCounts,
    );

Objective _objective({
  String id = 'o',
  ObjectiveMetric metric = const StepsMetric(),
  ObjectiveScope scope = const TodayScope(),
  ObjectiveOperator operator = ObjectiveOperator.atLeast,
  double targetValue = 10,
  double? upperTargetValue,
  double toleranceRatio = 0,
}) =>
    Objective(
      id: ObjectiveId(id),
      metric: metric,
      scope: scope,
      operator: operator,
      targetValue: targetValue,
      upperTargetValue: upperTargetValue,
      toleranceRatio: toleranceRatio,
    );

void main() {
  const evaluator = ObjectiveEvaluator();

  group('ObjectiveEvaluator — operators', () {
    test('atLeast completes when value >= target', () {
      final outcome =
          evaluator.evaluate(_objective(targetValue: 100), _input(stepsToday: 100));
      expect(outcome.completed, isTrue);
      expect(outcome.actualValue, 100);
    });

    test('atLeast does not complete when value < target', () {
      final outcome =
          evaluator.evaluate(_objective(targetValue: 100), _input(stepsToday: 99));
      expect(outcome.completed, isFalse);
    });

    test('atMost completes when value <= target', () {
      final outcome = evaluator.evaluate(
        _objective(operator: ObjectiveOperator.atMost, targetValue: 50),
        _input(stepsToday: 50),
      );
      expect(outcome.completed, isTrue);
    });

    test('betweenInclusive respects upper bound', () {
      final spec = _objective(
        operator: ObjectiveOperator.betweenInclusive,
        targetValue: 10,
        upperTargetValue: 20,
      );
      expect(evaluator.evaluate(spec, _input(stepsToday: 5)).completed, isFalse);
      expect(evaluator.evaluate(spec, _input(stepsToday: 15)).completed, isTrue);
      expect(evaluator.evaluate(spec, _input(stepsToday: 25)).completed, isFalse);
    });

    test('atLeastWithTolerance allows undershoot', () {
      final spec = _objective(
        operator: ObjectiveOperator.atLeastWithTolerance,
        targetValue: 100,
        toleranceRatio: 0.10,
      );
      expect(evaluator.evaluate(spec, _input(stepsToday: 95)).completed, isTrue);
      expect(evaluator.evaluate(spec, _input(stepsToday: 89)).completed, isFalse);
    });
  });

  group('ObjectiveEvaluator — metrics', () {
    test('StepsMetric reads the right field per scope', () {
      final today = _objective(metric: const StepsMetric(), scope: const TodayScope());
      final week = _objective(metric: const StepsMetric(), scope: const ThisWeekScope());
      final lifetime =
          _objective(metric: const StepsMetric(), scope: const LifetimeScope());
      final input = _input(stepsToday: 10000, stepsThisWeek: 50000, stepsLifetime: 1000000);
      expect(evaluator.evaluate(today, input).actualValue, 10000);
      expect(evaluator.evaluate(week, input).actualValue, 50000);
      expect(evaluator.evaluate(lifetime, input).actualValue, 1000000);
    });

    test('LevelMetric reads level regardless of scope', () {
      final spec = _objective(metric: const LevelMetric(), targetValue: 5);
      expect(evaluator.evaluate(spec, _input(level: 4)).completed, isFalse);
      expect(evaluator.evaluate(spec, _input(level: 5)).completed, isTrue);
    });

    test('TotalXpMetric reads totalXp', () {
      final spec = _objective(metric: const TotalXpMetric(), targetValue: 1000);
      expect(evaluator.evaluate(spec, _input(totalXp: 1000)).completed, isTrue);
    });

    test('NodeCompletionsMetric reads count by id', () {
      final spec = _objective(
        metric: const NodeCompletionsMetric(nodeId: ProgressionEntryId('q1')),
        targetValue: 3,
      );
      expect(
        evaluator.evaluate(spec, _input(nodeCompletionCounts: {'q1': 3})).completed,
        isTrue,
      );
      expect(
        evaluator.evaluate(spec, _input(nodeCompletionCounts: {'q2': 5})).completed,
        isFalse,
      );
    });

    test('ComboPoolCompletionsMetric reads count by pool id', () {
      final spec = _objective(
        metric: const ComboPoolCompletionsMetric(poolId: ComboPoolId('p1')),
        targetValue: 2,
      );
      expect(
        evaluator.evaluate(spec, _input(comboPoolCompletionCounts: {'p1': 2})).completed,
        isTrue,
      );
    });
  });

  group('ObjectiveEvaluator — period keys', () {
    test('TodayScope produces a yyyy-MM-dd key', () {
      final outcome = evaluator.evaluate(_objective(), _input(stepsToday: 10));
      expect(outcome.periodKey, '2026-05-10');
    });

    test('ThisWeekScope produces a w-<monday-date> key', () {
      final outcome = evaluator.evaluate(
        _objective(scope: const ThisWeekScope()),
        _input(stepsThisWeek: 10),
      );
      // 2026-05-10 is a Sunday → ISO week starts the previous Monday (May 4).
      expect(outcome.periodKey, 'w-2026-05-04');
    });

    test('LifetimeScope produces a null key', () {
      final outcome = evaluator.evaluate(
        _objective(scope: const LifetimeScope()),
        _input(stepsLifetime: 10),
      );
      expect(outcome.periodKey, isNull);
    });
  });

  group('ObjectiveEvaluator — SleepStartHourCountMetric', () {
    test('atOrAfter 1am reads lifetimeNightsStartedAtOrAfter1am', () {
      final spec = _objective(
        metric: const SleepStartHourCountMetric(
          hour: 1,
          direction: SleepStartHourDirection.atOrAfter,
        ),
        scope: const LifetimeScope(),
        targetValue: 30,
      );
      final ctx = buildTestContext(
        evaluatedAt: DateTime(2026, 5, 21, 12),
        lifetimeNightsStartedAtOrAfter1am: 30,
      );
      final out = evaluator.evaluate(spec, ctx);
      expect(out.actualValue, 30);
      expect(out.completed, isTrue);
    });

    test('before 10pm reads lifetimeNightsStartedBefore10pm', () {
      final spec = _objective(
        metric: const SleepStartHourCountMetric(
          hour: 22,
          direction: SleepStartHourDirection.before,
        ),
        scope: const LifetimeScope(),
        targetValue: 30,
      );
      final under = buildTestContext(
        evaluatedAt: DateTime(2026, 5, 21, 12),
        lifetimeNightsStartedBefore10pm: 29,
      );
      final at = buildTestContext(
        evaluatedAt: DateTime(2026, 5, 21, 12),
        lifetimeNightsStartedBefore10pm: 30,
      );
      expect(evaluator.evaluate(spec, under).completed, isFalse);
      expect(evaluator.evaluate(spec, at).completed, isTrue);
    });

    test('BestDailyValueMetric(StepsMetric) reads bestSingleDayStepsLifetime',
        () {
      final spec = _objective(
        metric: const BestDailyValueMetric(metric: StepsMetric()),
        scope: const LifetimeScope(),
        targetValue: 42195,
      );
      final under = buildTestContext(bestSingleDayStepsLifetime: 42000);
      final at = buildTestContext(bestSingleDayStepsLifetime: 42195);
      expect(evaluator.evaluate(spec, under).completed, isFalse);
      expect(evaluator.evaluate(spec, at).completed, isTrue);
    });

    test('BestDailyValueMetric falls to 0 for unwired wrapped metrics', () {
      // Only StepsMetric is wired; e.g. CaloriesMetric returns 0 so a
      // new achievement on the wrong axis does not silently complete.
      final spec = _objective(
        metric: const BestDailyValueMetric(metric: CaloriesMetric()),
        targetValue: 1,
      );
      expect(
          evaluator
              .evaluate(spec, buildTestContext(bestSingleDayStepsLifetime: 99999))
              .actualValue,
          0);
    });

    test('ReturnAfterGapMetric reads returnsAfterGapByDays[gapDays]', () {
      final spec = _objective(
        metric: const ReturnAfterGapMetric(gapDays: 7),
        scope: const LifetimeScope(),
        targetValue: 1,
      );
      final none = buildTestContext(returnsAfterGapByDays: const {7: 0});
      final hit = buildTestContext(returnsAfterGapByDays: const {7: 1});
      expect(evaluator.evaluate(spec, none).completed, isFalse);
      expect(evaluator.evaluate(spec, hit).completed, isTrue);
    });

    test('StreakAfterGapMetric reads bestStreakAfterGapByDays[gapDays]', () {
      final spec = _objective(
        metric: const StreakAfterGapMetric(gapDays: 7),
        scope: const LifetimeScope(),
        targetValue: 14,
      );
      final under =
          buildTestContext(bestStreakAfterGapByDays: const {7: 13});
      final at = buildTestContext(bestStreakAfterGapByDays: const {7: 14});
      expect(evaluator.evaluate(spec, under).completed, isFalse);
      expect(evaluator.evaluate(spec, at).completed, isTrue);
    });

    test('BestPerfectDayStreakMetric reads bestPerfectDayStreak', () {
      final spec = _objective(
        metric: const BestPerfectDayStreakMetric(),
        scope: const LifetimeScope(),
        targetValue: 30,
      );
      final under = buildTestContext(bestPerfectDayStreak: 29);
      final at = buildTestContext(bestPerfectDayStreak: 30);
      expect(evaluator.evaluate(spec, under).completed, isFalse);
      expect(evaluator.evaluate(spec, at).completed, isTrue);
    });

    test('PerfectWeeksLifetimeMetric reads perfectWeeksLifetime', () {
      final spec = _objective(
        metric: const PerfectWeeksLifetimeMetric(),
        scope: const LifetimeScope(),
        targetValue: 52,
      );
      final under = buildTestContext(perfectWeeksLifetime: 51);
      final at = buildTestContext(perfectWeeksLifetime: 52);
      expect(evaluator.evaluate(spec, under).completed, isFalse);
      expect(evaluator.evaluate(spec, at).completed, isTrue);
    });

    test('unwired (hour, direction) combinations evaluate to 0', () {
      // Catalog only wires (1, atOrAfter) and (22, before). Anything
      // else stays at 0 so a new entry without snapshot wiring does
      // not silently complete.
      final spec = _objective(
        metric: const SleepStartHourCountMetric(
          hour: 3,
          direction: SleepStartHourDirection.atOrAfter,
        ),
        targetValue: 1,
      );
      final ctx = buildTestContext(
        evaluatedAt: DateTime(2026, 5, 21, 12),
        lifetimeNightsStartedAtOrAfter1am: 999,
      );
      expect(evaluator.evaluate(spec, ctx).actualValue, 0);
    });
  });

  group('ObjectiveEvaluator — LifetimeCompletionsAmongMetric (template id)', () {
    // Repeatable combo chains suffix node ids per generation
    // (`combo_balanced_step_3`, `combo_balanced_step_3@2`, …). The
    // triple-combo achievements list **template** ids and rely on the
    // evaluator to roll up completions across every generation.
    Objective triple({double target = 25}) => _objective(
          metric: const LifetimeCompletionsAmongMetric(
            nodeIds: [
              ProgressionEntryId('combo_balanced_step_3'),
              ProgressionEntryId('combo_recovery_step_3'),
              ProgressionEntryId('combo_nutrition_step_3'),
            ],
          ),
          scope: const LifetimeScope(),
          targetValue: target,
        );

    test('counts gen 1 completions (canonical ids)', () {
      final ctx = _input(nodeCompletionCounts: const {
        'combo_balanced_step_3': 1,
        'combo_recovery_step_3': 1,
      });
      final out = evaluator.evaluate(triple(target: 1), ctx);
      expect(out.actualValue, 2);
      expect(out.completed, isTrue);
    });

    test('counts gen 2+ completions via template-id match', () {
      final ctx = _input(nodeCompletionCounts: const {
        'combo_balanced_step_3@2': 1,
        'combo_balanced_step_3@3': 1,
        'combo_nutrition_step_3@5': 1,
      });
      final out = evaluator.evaluate(triple(target: 3), ctx);
      expect(out.actualValue, 3);
      expect(out.completed, isTrue);
    });

    test('aggregates canonical + suffixed across generations', () {
      final ctx = _input(nodeCompletionCounts: const {
        'combo_balanced_step_3': 1,
        'combo_balanced_step_3@2': 1,
        'combo_recovery_step_3@3': 1,
        'combo_nutrition_step_3@10': 1,
        // Unrelated node — must not contribute.
        'daily_steps_today': 25,
      });
      final out = evaluator.evaluate(triple(target: 4), ctx);
      expect(out.actualValue, 4);
      expect(out.completed, isTrue);
    });

    test('ignores ids whose template is not in the metric set', () {
      final ctx = _input(nodeCompletionCounts: const {
        // step_2 templates are not in `tripleComboNodeIds` — must not count.
        'combo_balanced_step_2': 9,
        'combo_balanced_step_2@5': 9,
      });
      final out = evaluator.evaluate(triple(target: 1), ctx);
      expect(out.actualValue, 0);
      expect(out.completed, isFalse);
    });
  });
}
