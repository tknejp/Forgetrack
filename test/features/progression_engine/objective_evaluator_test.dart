import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/domain/evaluator/objective_evaluator.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_input.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_metric.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_operator.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_scope.dart';

EngineEvaluationInput _input({
  int stepsToday = 0,
  int stepsThisWeek = 0,
  int stepsLifetime = 0,
  int level = 1,
  int totalXp = 0,
  int totalRewardCount = 0,
  Map<String, int> nodeCompletionCounts = const {},
  Map<String, int> comboPoolCompletionCounts = const {},
}) =>
    EngineEvaluationInput(
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

ObjectiveDefinition _objective({
  String id = 'o',
  ObjectiveMetric metric = const StepsMetric(),
  ObjectiveScope scope = const TodayScope(),
  ObjectiveOperator operator = ObjectiveOperator.atLeast,
  double targetValue = 10,
  double? upperTargetValue,
  double toleranceRatio = 0,
}) =>
    ObjectiveDefinition(
      id: id,
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
        metric: const NodeCompletionsMetric(nodeId: 'q1'),
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
        metric: const ComboPoolCompletionsMetric(poolId: 'p1'),
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
}
