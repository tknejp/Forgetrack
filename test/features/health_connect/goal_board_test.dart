import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/health_connect/domain/goal_board.dart';
import 'package:forgetrack/features/health_connect/domain/player_goal.dart';

void main() {
  group('GoalBoard', () {
    test('empty board has a zero-target goal per metric', () {
      final board = GoalBoard.empty;
      for (final metric in GoalMetric.values) {
        expect(board.goalFor(metric).metric, metric);
        expect(board.goalFor(metric).target, 0);
      }
    });

    test('withGoal substitutes the matching metric entry', () {
      final board = GoalBoard.empty;
      final updated = board.withGoal(const PlayerGoal(
        metric: GoalMetric.dailySteps,
        target: 12000,
      ));

      expect(updated.goalFor(GoalMetric.dailySteps).target, 12000);
      expect(updated.goalFor(GoalMetric.dailyCalories).target, 0);
      expect(board.goalFor(GoalMetric.dailySteps).target, 0,
          reason: 'original board is immutable');
    });

    test('progressionHistorySignature excludes targetWeight', () {
      final board = GoalBoard.empty
          .withGoal(PlayerGoal(
            metric: GoalMetric.targetWeight,
            target: 70,
            history: [
              GoalRevision(
                effectiveFrom: DateTime(2026, 5, 18),
                value: 70,
              ),
            ],
          ))
          .withGoal(PlayerGoal(
            metric: GoalMetric.dailyCalories,
            target: 2500,
            history: [
              GoalRevision(
                effectiveFrom: DateTime(2026, 5, 18),
                value: 2500,
              ),
            ],
          ));

      final signature = board.progressionHistorySignature;
      expect(signature.contains('2500.0'), isTrue);
      expect(signature.contains('70.0'), isFalse,
          reason: 'targetWeight has no progression history slot');
    });

    test('signature changes when any tracked goal history changes', () {
      final original = GoalBoard.empty.withGoal(PlayerGoal(
        metric: GoalMetric.dailySteps,
        target: 10000,
        history: [
          GoalRevision(effectiveFrom: DateTime(2026, 5, 1), value: 10000),
        ],
      ));

      final mutated = original.withGoal(
        original
            .goalFor(GoalMetric.dailySteps)
            .withRevision(effectiveFrom: DateTime(2026, 5, 18), value: 12000),
      );

      expect(original.progressionHistorySignature,
          isNot(mutated.progressionHistorySignature));
    });

    test('equality compares goals map element-wise', () {
      final a = GoalBoard.empty.withGoal(
        const PlayerGoal(metric: GoalMetric.dailySteps, target: 10000),
      );
      final b = GoalBoard.empty.withGoal(
        const PlayerGoal(metric: GoalMetric.dailySteps, target: 10000),
      );
      final c = GoalBoard.empty.withGoal(
        const PlayerGoal(metric: GoalMetric.dailySteps, target: 12000),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });
}
