import 'package:meta/meta.dart';
import 'package:intl/intl.dart';

import '../models/engine_evaluation_context.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';

/// Outcome of one objective on one evaluation pass.
@immutable
class ObjectiveOutcome {
  const ObjectiveOutcome({
    required this.objectiveId,
    required this.actualValue,
    required this.completed,
    required this.periodKey,
  });

  final String objectiveId; // lint-ignore: untyped-id — ObjectiveResolution mirrors ObjectiveId from catalog
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
    Objective objective,
    EngineEvaluationContext context,
  ) {
    // Provider-supplied override wins — used for objectives whose
    // actual value depends on ledger history (e.g. chapter step
    // `baselineFromNodeId` counters "since this chain step unlocked").
    final override = context.overrides.objectiveActualOverrides[objective.id];
    final actual =
        override ?? _readMetric(objective.metric, objective.scope, context);
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
      periodKey: _periodKey(objective.scope, context),
    );
  }

  // ── Metric → context field ───────────────────────────────────────

  double _readMetric(
    ObjectiveMetric metric,
    ObjectiveScope scope,
    EngineEvaluationContext context,
  ) {
    final player = context.player;
    final health = context.healthSnapshot;
    final nutrition = context.nutritionSnapshot;
    final counters = context.counters;
    return switch (metric) {
      StepsMetric() => switch (scope) {
          TodayScope() => health.stepsToday.toDouble(),
          ThisWeekScope() => health.stepsThisWeek.toDouble(),
          LifetimeScope() => health.stepsLifetime.toDouble(),
          RollingWindowScope(:final days) =>
            (counters.bestRollingStepsByDays[days] ?? 0).toDouble(),
          CurrentChapterScope() => 0,
        },
      CaloriesMetric() => switch (scope) {
          TodayScope() => nutrition.caloriesToday,
          _ => 0,
        },
      ProteinGramsMetric() => switch (scope) {
          TodayScope() => nutrition.proteinGramsToday,
          _ => 0,
        },
      CarbsGramsMetric() => switch (scope) {
          TodayScope() => nutrition.carbsGramsToday,
          _ => 0,
        },
      FatGramsMetric() => switch (scope) {
          TodayScope() => nutrition.fatGramsToday,
          _ => 0,
        },
      FiberGramsMetric() => switch (scope) {
          TodayScope() => nutrition.fiberGramsToday,
          _ => 0,
        },
      SleepMinutesMetric() => switch (scope) {
          TodayScope() => health.sleepMinutesToday.toDouble(),
          RollingWindowScope(:final days) =>
            (counters.bestRollingSleepMinutesByDays[days] ?? 0).toDouble(),
          _ => 0,
        },
      SleepStartHourCountMetric(:final hour, :final direction) => () {
        // Resolver only wires the (hour, direction) combinations the
        // catalog actually asks for; everything else returns 0 so a
        // new catalog entry without snapshot wiring stays at zero
        // instead of silently lifetime-true.
        if (direction == SleepStartHourDirection.atOrAfter && hour == 1) {
          return health.lifetimeNightsStartedAtOrAfter1am.toDouble();
        }
        if (direction == SleepStartHourDirection.before && hour == 22) {
          return health.lifetimeNightsStartedBefore10pm.toDouble();
        }
        return 0.0;
      }(),
      ActivityMinutesMetric() => switch (scope) {
          TodayScope() => health.activityMinutesToday.toDouble(),
          _ => 0,
        },
      WeightLoggedTodayMetric() => switch (scope) {
          TodayScope() => health.weightLoggedToday ? 1.0 : 0.0,
          _ => 0,
        },
      LevelMetric() => player.level.toDouble(),
      TotalXpMetric() => player.totalXp.toDouble(),
      RewardCountMetric(:final ruleId, :final domain) => () {
          if (ruleId != null) {
            return (counters.rewardCountByRule[ruleId] ?? 0).toDouble();
          }
          if (domain != null) {
            return (counters.rewardCountByDomain[domain] ?? 0).toDouble();
          }
          return counters.totalRewardCount.toDouble();
        }(),
      StreakDaysMetric(:final ruleId, :final domain) => () {
          if (ruleId != null) {
            return (counters.bestStreakByRule[ruleId] ?? 0).toDouble();
          }
          if (domain != null) {
            return (counters.bestStreakByDomain[domain] ?? 0).toDouble();
          }
          return 0.0;
        }(),
      NodeCompletionsMetric(:final nodeId) =>
        (counters.nodeCompletionCounts[nodeId] ?? 0).toDouble(),
      ComboPoolCompletionsMetric(:final poolId) =>
        (counters.comboPoolCompletionCounts[poolId] ?? 0).toDouble(),
      QuestCompletionsByBucketMetric(:final bucket) => bucket == null
          ? counters.totalQuestCompletions.toDouble()
          : (counters.questCompletionsByBucket[bucket.name] ?? 0).toDouble(),
      DistinctActiveDaysMetric() => counters.distinctActiveDays.toDouble(),
      TodayCompletionsAmongMetric(:final nodeIds) => () {
        var n = 0;
        for (final id in nodeIds) {
          if (counters.nodesCompletedToday.contains(id)) n++;
        }
        return n.toDouble();
      }(),
      LifetimeCompletionsAmongMetric(:final nodeIds) => () {
        var n = 0;
        for (final id in nodeIds) {
          n += counters.nodeCompletionCounts[id] ?? 0;
        }
        return n.toDouble();
      }(),
      BestDailyValueMetric(:final metric) => switch (metric) {
          StepsMetric() => health.bestSingleDayStepsLifetime.toDouble(),
          // Only StepsMetric is wired today; other daily metrics fall
          // through to 0 until the snapshot grows the matching field.
          _ => 0,
        },
      ReturnAfterGapMetric(:final gapDays) =>
        (counters.returnsAfterGapByDays[gapDays] ?? 0).toDouble(),
      StreakAfterGapMetric(:final gapDays) =>
        (counters.bestStreakAfterGapByDays[gapDays] ?? 0).toDouble(),
      // Per-day "at least K of these nodes were done" requires the
      // ledger to reconstruct daily groupings — that's done in the
      // provider and surfaced through `objectiveActualOverrides`.
      // The evaluator returns 0 by default so an objective with no
      // override registered (no baseline node yet completed) reads
      // as not-yet-progressed instead of silently lifetime-true.
      DaysWithAtLeastKAmongMetric() => 0,
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

  String? _periodKey(ObjectiveScope scope, EngineEvaluationContext context) {
    final dt = context.evaluatedAt;
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
