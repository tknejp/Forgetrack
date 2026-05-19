import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/health_connect/domain/player_goal.dart';

void main() {
  group('GoalRevision', () {
    test('normalises effectiveFrom to date-only', () {
      final revision = GoalRevision(
        effectiveFrom: DateTime(2026, 5, 18, 14, 32, 11),
        value: 2500,
      );
      expect(revision.effectiveFrom, DateTime(2026, 5, 18));
    });

    test('equality and hash are value-based', () {
      final a = GoalRevision(
        effectiveFrom: DateTime(2026, 5, 18),
        value: 2500,
      );
      final b = GoalRevision(
        effectiveFrom: DateTime(2026, 5, 18, 23, 59),
        value: 2500,
      );
      final c = GoalRevision(
        effectiveFrom: DateTime(2026, 5, 18),
        value: 3000,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('round-trips through JSON', () {
      final revision = GoalRevision(
        effectiveFrom: DateTime(2026, 5, 18),
        value: 2500.5,
      );
      final restored = GoalRevision.fromJson(revision.toJson());
      expect(restored, revision);
    });
  });

  group('PlayerGoal', () {
    test('empty history → resolveForDate returns target', () {
      const goal = PlayerGoal(
        metric: GoalMetric.targetWeight,
        target: 75.5,
      );
      expect(goal.resolveForDate(DateTime(2026, 5, 18)), 75.5);
    });

    test('resolveForDate picks latest revision ≤ day', () {
      final goal = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2500,
        history: [
          GoalRevision(effectiveFrom: DateTime(1970, 1, 1), value: 2000),
          GoalRevision(effectiveFrom: DateTime(2026, 3, 1), value: 2200),
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 2500),
        ],
      );

      expect(goal.resolveForDate(DateTime(2026, 1, 1)), 2000);
      expect(goal.resolveForDate(DateTime(2026, 3, 1)), 2200);
      expect(goal.resolveForDate(DateTime(2026, 4, 30)), 2200);
      expect(goal.resolveForDate(DateTime(2026, 5, 1)), 2500);
      expect(goal.resolveForDate(DateTime(2026, 12, 31)), 2500);
    });

    test('resolveForDate before all revisions falls back to first', () {
      final goal = PlayerGoal(
        metric: GoalMetric.dailySteps,
        target: 12000,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 1, 1), value: 10000),
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 12000),
        ],
      );
      expect(goal.resolveForDate(DateTime(2025, 12, 31)), 10000);
    });

    test('withRevision appends new entry sorted by date', () {
      const initial = PlayerGoal(
        metric: GoalMetric.dailySteps,
        target: 10000,
      );
      final updated = initial.withRevision(
        effectiveFrom: DateTime(2026, 5, 18),
        value: 12000,
      );

      expect(updated.target, 12000);
      expect(updated.history, hasLength(1));
      expect(updated.history.single.value, 12000);
      expect(updated.history.single.effectiveFrom, DateTime(2026, 5, 18));
    });

    test('withRevision replaces same-day entry', () {
      final initial = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2200,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 5, 18), value: 2200),
        ],
      );
      final updated = initial.withRevision(
        effectiveFrom: DateTime(2026, 5, 18, 9, 0),
        value: 2500,
      );

      expect(updated.history, hasLength(1));
      expect(updated.history.single.value, 2500);
      expect(updated.target, 2500);
    });

    test('ensureRevisionAt is no-op when resolution matches', () {
      final goal = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2200,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 2200),
        ],
      );
      final after = goal.ensureRevisionAt(
        anchor: DateTime(2026, 5, 18),
        currentValue: 2200,
      );
      expect(identical(after, goal), isTrue);
    });

    test('ensureRevisionAt rewrites future-dated stale revision', () {
      final goal = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2500,
        history: [
          GoalRevision(effectiveFrom: DateTime(1970, 1, 1), value: 2000),
          GoalRevision(effectiveFrom: DateTime(2030, 1, 1), value: 2500),
        ],
      );
      final after = goal.ensureRevisionAt(
        anchor: DateTime(2026, 5, 18),
        currentValue: 2500,
      );
      expect(after.resolveForDate(DateTime(2026, 5, 18)), 2500);
      expect(after.history.any((e) => e.effectiveFrom == DateTime(2026, 5, 18)),
          isTrue);
    });

    test('historySignature is stable and order-sensitive', () {
      final goal = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2500,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 1, 1), value: 2000),
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 2500),
        ],
      );
      expect(
        goal.historySignature,
        '2026-01-01T00:00:00.000:2000.0,2026-05-01T00:00:00.000:2500.0',
      );
    });

    test('equality compares history element-wise', () {
      final a = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2500,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 2500),
        ],
      );
      final b = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2500,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 2500),
        ],
      );
      final c = PlayerGoal(
        metric: GoalMetric.dailyCalories,
        target: 2500,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 5, 2), value: 2500),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });
}
