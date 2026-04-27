import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/progression/domain/progression_level_policy.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';

void main() {
  group('Progression Reward Double-Scaling Bug', () {
    const policy = ProgressionLevelPolicy(
      baseDailyRewardXp: 230,
      baseWeeklyRewardXp: 120,
      level30RewardMultiplier: 12.5,
      level50RewardMultiplier: 62.5,
      level100RewardMultiplier: 150.0,
    );

    test('claim reward should not double-scale xpGranted', () {
      const baseXp = 80;
      const evaluationLevel = 51;
      const claimLevel = 51;

      // Evaluation: scale base XP using evaluation level
      final scaledAtEval = policy.scaledRewardXp(baseXp: baseXp, level: evaluationLevel);

      // Expected: finalXp should equal scaledAtEval since level hasn't changed
      final finalXpCorrect = policy.scaledRewardXp(baseXp: baseXp, level: claimLevel);

      // BUG: if we scale xpGranted again, we get double-scaling
      final finalXpBuggy = policy.scaledRewardXp(baseXp: scaledAtEval, level: claimLevel);

      expect(scaledAtEval, closeTo(5140, 50), reason: 'Scaled reward at eval should be ~5140');
      expect(finalXpCorrect, closeTo(5140, 50), reason: 'Final XP at same level should equal scaled at eval');
      expect(finalXpBuggy, closeTo(330245, 1000), reason: 'Double-scaling produces ~330k (the bug!)');
      expect(finalXpBuggy, isNot(finalXpCorrect), reason: 'Buggy double-scaling should not equal correct value');
    });

    test('claimed grant should display correct XP in recent rewards', () {
      // This simulates what should be stored in a claimed grant
      const baseXp = 80;
      const claimLevel = 51;

      final correctFinalXp = policy.scaledRewardXp(baseXp: baseXp, level: claimLevel);

      final grant = ProgressionRewardGrant(
        rewardKey: 'test|reward',
        ruleId: 'daily_steps',
        ruleVersion: '1',
        domain: ProgressionDomain.steps,
        period: ProgressionPeriod.day(DateTime.now()),
        xpGranted: correctFinalXp,
        targetValue: 10000,
        actualValue: 12000,
        rewardStatus: ProgressionRewardStatus.claimed,
        unlockedAt: DateTime.now(),
        claimedAt: DateTime.now(),
        finalXp: correctFinalXp,
        levelAtClaim: claimLevel,
        multiplierAtClaim: policy.rewardMultiplierForLevel(claimLevel),
      );

      expect(grant.effectiveXpGranted, closeTo(5140, 50), reason: 'Claimed grant should show ~5140 XP');
      expect(grant.effectiveXpGranted, isNot(330245), reason: 'Should NOT show 330k XP');
    });
  });
}
