import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/engine_evaluation_input.dart';
import '../models/objective_definition.dart';
import '../models/objective_metric.dart';
import '../models/objective_operator.dart';
import '../models/objective_scope.dart';

/// Outcome of one objective on one evaluation pass.
@immutable
class ObjectiveOutcome {
  const ObjectiveOutcome({
    required this.objectiveId,
    required this.actualValue,
    required this.completed,
    required this.periodKey,
  });

  final String objectiveId;
  final double actualValue;
  final bool completed;

  /// Period anchor used in the ledger event key. `null` for
  /// lifetime-scoped objectives.
  final String? periodKey;
}

/// Pure objective evaluator. Given input metrics + an objective
/// definition, returns whether the objective is currently satisfied
/// and the measured value.
///
/// Phase 2 implements the metrics needed to demonstrate the design
/// end-to-end (steps, calories, level, totalXp, reward count, node
/// completions, combo pool completions); the rest land alongside
/// real catalog entries during Phase 3 — adding a metric is one
/// switch case.
class ObjectiveEvaluator {
  const ObjectiveEvaluator();

  ObjectiveOutcome evaluate(
    ObjectiveDefinition objective,
    EngineEvaluationInput input,
  ) {
    // Provider-supplied override wins — used for objectives whose
    // actual value depends on ledger history (e.g. chapter step
    // `baselineFromNodeId` counters "since this chain step unlocked").
    final override = input.objectiveActualOverrides[objective.id];
    final actual = override ?? _readMetric(objective.metric, objective.scope, input);
    final completed = _matches(
      operator: objective.operator,
      value: actual,
      target: objective.targetValue,
      upperTarget: objective.upperTargetValue,
      tolerance: objective.toleranceRatio,
    );
    return ObjectiveOutcome(
      objectiveId: objective.id,
      actualValue: actual,
      completed: completed,
      periodKey: _periodKey(objective.scope, input),
    );
  }

  // ── Metric → input field ─────────────────────────────────────────

  double _readMetric(
    ObjectiveMetric metric,
    ObjectiveScope scope,
    EngineEvaluationInput input,
  ) {
    return switch (metric) {
      StepsMetric() => switch (scope) {
          TodayScope() => input.stepsToday.toDouble(),
          ThisWeekScope() => input.stepsThisWeek.toDouble(),
          LifetimeScope() => input.stepsLifetime.toDouble(),
          RollingWindowScope(:final days) =>
            (input.bestRollingStepsByDays[days] ?? 0).toDouble(),
          CurrentChapterScope() => 0,
        },
      CaloriesMetric() => switch (scope) {
          TodayScope() => input.caloriesToday,
          _ => 0,
        },
      ProteinGramsMetric() => switch (scope) {
          TodayScope() => input.proteinGramsToday,
          _ => 0,
        },
      CarbsGramsMetric() => switch (scope) {
          TodayScope() => input.carbsGramsToday,
          _ => 0,
        },
      FatGramsMetric() => switch (scope) {
          TodayScope() => input.fatGramsToday,
          _ => 0,
        },
      FiberGramsMetric() => switch (scope) {
          TodayScope() => input.fiberGramsToday,
          _ => 0,
        },
      SleepMinutesMetric() => switch (scope) {
          TodayScope() => input.sleepMinutesToday.toDouble(),
          RollingWindowScope(:final days) =>
            (input.bestRollingSleepMinutesByDays[days] ?? 0).toDouble(),
          _ => 0,
        },
      ActivityMinutesMetric() => switch (scope) {
          TodayScope() => input.activityMinutesToday.toDouble(),
          _ => 0,
        },
      LevelMetric() => input.level.toDouble(),
      TotalXpMetric() => input.totalXp.toDouble(),
      RewardCountMetric(:final ruleId, :final domain) => () {
          if (ruleId != null) {
            return (input.rewardCountByRule[ruleId] ?? 0).toDouble();
          }
          if (domain != null) {
            return (input.rewardCountByDomain[domain] ?? 0).toDouble();
          }
          return input.totalRewardCount.toDouble();
        }(),
      StreakDaysMetric(:final ruleId, :final domain) => () {
          if (ruleId != null) {
            return (input.bestStreakByRule[ruleId] ?? 0).toDouble();
          }
          if (domain != null) {
            return (input.bestStreakByDomain[domain] ?? 0).toDouble();
          }
          return 0.0;
        }(),
      NodeCompletionsMetric(:final nodeId) =>
        (input.nodeCompletionCounts[nodeId] ?? 0).toDouble(),
      ComboPoolCompletionsMetric(:final poolId) =>
        (input.comboPoolCompletionCounts[poolId] ?? 0).toDouble(),
      QuestCompletionsByBucketMetric(:final bucket) => bucket == null
          ? input.totalQuestCompletions.toDouble()
          : (input.questCompletionsByBucket[bucket.name] ?? 0).toDouble(),
      DistinctActiveDaysMetric() => input.distinctActiveDays.toDouble(),
      TodayCompletionsAmongMetric(:final nodeIds) => () {
        var n = 0;
        for (final id in nodeIds) {
          if (input.nodesCompletedToday.contains(id)) n++;
        }
        return n.toDouble();
      }(),
      LifetimeCompletionsAmongMetric(:final nodeIds) => () {
        var n = 0;
        for (final id in nodeIds) {
          n += input.nodeCompletionCounts[id] ?? 0;
        }
        return n.toDouble();
      }(),
    };
  }

  // ── Operator comparison ───────────────────────────────────────────

  bool _matches({
    required ObjectiveOperator operator,
    required double value,
    required double target,
    required double? upperTarget,
    required double tolerance,
  }) {
    switch (operator) {
      case ObjectiveOperator.atLeast:
        return value >= target;
      case ObjectiveOperator.atMost:
        return value <= target;
      case ObjectiveOperator.betweenInclusive:
        final upper = upperTarget ?? target;
        return value >= target && value <= upper;
      case ObjectiveOperator.withinTolerance:
        final lower = target - (target * tolerance);
        final upper = target + (target * tolerance);
        return value >= lower && value <= upper;
      case ObjectiveOperator.atLeastWithTolerance:
        final lower = target - (target * tolerance);
        return value >= lower;
    }
  }

  // ── Period keying ─────────────────────────────────────────────────

  String? _periodKey(ObjectiveScope scope, EngineEvaluationInput input) {
    final dt = input.evaluatedAt;
    return switch (scope) {
      TodayScope() => DateFormat('yyyy-MM-dd').format(_dateOnly(dt)),
      ThisWeekScope() =>
        'w-${DateFormat('yyyy-MM-dd').format(_isoWeekStart(dt))}',
      LifetimeScope() => null,
      RollingWindowScope(:final days) =>
        'rw$days-${DateFormat('yyyy-MM-dd').format(_dateOnly(dt))}',
      CurrentChapterScope() =>
        // Without active-chapter context plumbed through, fall back
        // to a per-day scope so re-runs idempotently produce the
        // same key. Catalog port will replace this with the real
        // chapter id once chapters land in the new engine.
        'chapter-${DateFormat('yyyy-MM-dd').format(_dateOnly(dt))}',
    };
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _isoWeekStart(DateTime dt) {
    final d = _dateOnly(dt);
    // ISO week starts on Monday (weekday 1).
    return d.subtract(Duration(days: d.weekday - 1));
  }
}
