import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/progression/domain/progression_level_policy.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';

void main() {
  group('Unclaimed Reward Preview Refresh', () {
    const policy = ProgressionLevelPolicy(
      baseDailyRewardXp: 230,
      baseWeeklyRewardXp: 120,
      level30RewardMultiplier: 12.5,
      level50RewardMultiplier: 62.5,
      level100RewardMultiplier: 150.0,
    );

    test('unclaimed reward preview uses current level, not stale xpGranted', () {
      const baseXp = 80;
      const profileLevel = 10;

      // Create grant that was evaluated at level 10
      final grantAtLevel10 = ProgressionRewardGrant(
        rewardKey: 'test|reward',
        ruleId: 'daily_steps',
        ruleVersion: '1',
        domain: ProgressionDomain.steps,
        period: ProgressionPeriod.day(DateTime.now()),
        xpGranted: policy.scaledRewardXp(baseXp: baseXp, level: profileLevel),
        targetValue: 10000,
        actualValue: 12000,
        rewardStatus: ProgressionRewardStatus.unlocked,
        unlockedAt: DateTime.now(),
        baseXp: baseXp,
      );

      // Profile is now level 11
      final profileLevel11 = ProgressionProfile(
        totalXp: 5000,
        level: 11,
        levelTitle: 'Test',
        levelFloorXp: 0,
        nextLevelXp: 10000,
        xpIntoLevel: 5000,
      );

      // Compute preview for unclaimed grant at new level
      final previewAtLevel11 = policy.scaledRewardXp(
        baseXp: grantAtLevel10.baseXp ?? grantAtLevel10.xpGranted,
        level: profileLevel11.level,
      );

      // Preview at level 11 should be higher than xpGranted (which was computed for level 10)
      expect(
        previewAtLevel11,
        greaterThan(grantAtLevel10.xpGranted),
        reason: 'Preview at level 11 should be higher than stale xpGranted from level 10',
      );

      // Verify specific values
      final previewAtLevel10 = policy.scaledRewardXp(
        baseXp: baseXp,
        level: profileLevel.toInt(),
      );
      expect(grantAtLevel10.xpGranted, equals(previewAtLevel10));
      expect(previewAtLevel11, greaterThan(previewAtLevel10));
    });

    test('claimed reward display remains frozen at claim-time finalXp', () {
      const baseXp = 80;
      const claimLevel = 10;

      // Create a claimed grant with frozen finalXp
      final claimedGrant = ProgressionRewardGrant(
        rewardKey: 'test|claimed',
        ruleId: 'daily_steps',
        ruleVersion: '1',
        domain: ProgressionDomain.steps,
        period: ProgressionPeriod.day(DateTime.now()),
        xpGranted: policy.scaledRewardXp(baseXp: baseXp, level: claimLevel),
        targetValue: 10000,
        actualValue: 12000,
        rewardStatus: ProgressionRewardStatus.claimed,
        unlockedAt: DateTime.now(),
        claimedAt: DateTime.now(),
        finalXp: policy.scaledRewardXp(baseXp: baseXp, level: claimLevel),
        levelAtClaim: claimLevel,
        multiplierAtClaim: policy.rewardMultiplierForLevel(claimLevel),
        baseXp: baseXp,
      );

      // Profile is now at higher level
      final profileLevel20 = ProgressionProfile(
        totalXp: 50000,
        level: 20,
        levelTitle: 'Test',
        levelFloorXp: 0,
        nextLevelXp: 100000,
        xpIntoLevel: 50000,
      );

      // For claimed rewards, use effectiveXpGranted which is frozen at claim time
      final displayXp = claimedGrant.effectiveXpGranted;

      // Display should remain frozen, not refresh to level 20
      expect(
        displayXp,
        equals(claimedGrant.finalXp),
        reason: 'Claimed reward XP should remain frozen at finalXp',
      );

      // Verify it's NOT the preview for level 20
      final previewAtLevel20 = policy.scaledRewardXp(
        baseXp: baseXp,
        level: profileLevel20.level,
      );
      expect(
        displayXp,
        lessThan(previewAtLevel20),
        reason: 'Frozen finalXp should be less than what level 20 preview would be',
      );
    });

    test('displayXp computation logic uses baseXp with fallback', () {
      const baseXp = 100;

      // Grant with baseXp
      final grantWithBase = ProgressionRewardGrant(
        rewardKey: 'test|with-base',
        ruleId: 'daily_steps',
        ruleVersion: '1',
        domain: ProgressionDomain.steps,
        period: ProgressionPeriod.day(DateTime.now()),
        xpGranted: 5000, // Already scaled
        targetValue: 10000,
        actualValue: 12000,
        rewardStatus: ProgressionRewardStatus.unlocked,
        unlockedAt: DateTime.now(),
        baseXp: baseXp,
      );

      final profile = ProgressionProfile(
        totalXp: 1000,
        level: 5,
        levelTitle: 'Test',
        levelFloorXp: 0,
        nextLevelXp: 5000,
        xpIntoLevel: 1000,
      );

      // Compute display using baseXp (not xpGranted which is already scaled)
      final displayXp = policy.scaledRewardXp(
        baseXp: grantWithBase.baseXp ?? grantWithBase.xpGranted,
        level: profile.level,
      );

      // Should use baseXp (100), not xpGranted (5000) to avoid double-scaling
      expect(
        displayXp,
        equals(policy.scaledRewardXp(baseXp: baseXp, level: profile.level)),
      );
      expect(displayXp, lessThan(grantWithBase.xpGranted));
    });
  });
}
