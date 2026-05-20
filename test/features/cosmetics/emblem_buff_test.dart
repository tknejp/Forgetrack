import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/reward_source_kind.dart';
import 'package:forgetrack/features/cosmetics/domain/emblem_buff.dart';
import 'package:forgetrack/features/health_connect/domain/player_goal.dart';

void main() {
  group('PerTargetEmblemBuff', () {
    const buff = PerTargetEmblemBuff(
      target: DailyGoalTarget(GoalMetric.dailyCalories),
      percent: 10,
    );

    test('returns configured percent when target matches', () {
      final ctx = EmblemBuffContext(
        target: const DailyGoalTarget(GoalMetric.dailyCalories),
        rewardSourceKind: RewardSourceKind.nutritionXp,
      );
      expect(buff.resolvePercent(ctx), 10);
    });

    test('returns 0 when target mismatches', () {
      final ctx = EmblemBuffContext(
        target: const DailyGoalTarget(GoalMetric.dailySteps),
        rewardSourceKind: RewardSourceKind.activityXp,
      );
      expect(buff.resolvePercent(ctx), 0);
    });
  });

  group('BlanketEmblemBuff', () {
    const blanket = BlanketEmblemBuff(percent: 5);

    test('returns percent for every covered target', () {
      for (final target in BlanketEmblemBuff.coveredTargets) {
        final ctx = EmblemBuffContext(
          target: target,
          rewardSourceKind: RewardSourceKind.allXp,
        );
        expect(
          blanket.resolvePercent(ctx),
          5,
          reason: 'covered target $target should resolve to 5',
        );
      }
    });

    test('returns 0 for an uncovered (synthetic) target', () {
      // weeklyActivityMins is not in the V1 mapping table.
      final ctx = EmblemBuffContext(
        target: const DailyGoalTarget(GoalMetric.weeklyActivityMins),
        rewardSourceKind: RewardSourceKind.activityXp,
      );
      expect(blanket.resolvePercent(ctx), 0);
    });
  });

  test('EmblemBuff sealed exhaustiveness (compile-time)', () {
    const EmblemBuff buff = PerTargetEmblemBuff(
      target: ComboQuestTarget(),
      percent: 10,
    );
    // A switch expression without a default forces the analyzer to
    // verify the sealed hierarchy is exhaustive — adding a new
    // subtype later will break this test, which is the intent.
    final label = switch (buff) {
      PerTargetEmblemBuff() => 'per-target',
      BlanketEmblemBuff() => 'blanket',
    };
    expect(label, 'per-target');

    const EmblemTarget target = DailyGoalTarget(GoalMetric.dailyCalories);
    final targetLabel = switch (target) {
      DailyGoalTarget() => 'daily',
      ComboQuestTarget() => 'combo',
    };
    expect(targetLabel, 'daily');
  });
}
