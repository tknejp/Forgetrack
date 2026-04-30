import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression/data/firestore/progression_firestore_mapper.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  final unlockedAt = DateTime(2026, 4, 10);
  final claimedAt = DateTime(2026, 4, 10, 12);
  final periodStart = DateTime(2026, 4, 10);

  ProgressionRewardGrant ruleGrant({
    int xpGranted = 80,
    int? baseXp,
    int? finalXp,
    ProgressionRewardStatus status = ProgressionRewardStatus.claimed,
    int? levelAtClaim,
    double? multiplierAtClaim,
  }) {
    return ProgressionRewardGrant(
      rewardKey: 'daily_steps|v1|day|2026-04-10|reward',
      ruleId: 'daily_steps',
      ruleVersion: 'v1',
      domain: ProgressionDomain.steps,
      period: ProgressionPeriod(
        kind: ProgressionPeriodKind.day,
        start: periodStart,
        end: periodStart,
      ),
      xpGranted: xpGranted,
      targetValue: 10000,
      actualValue: 12000,
      rewardStatus: status,
      unlockedAt: unlockedAt,
      claimedAt: status == ProgressionRewardStatus.claimed ? claimedAt : null,
      finalXp: finalXp,
      levelAtClaim: levelAtClaim,
      multiplierAtClaim: multiplierAtClaim,
      baseXp: baseXp,
    );
  }

  ProgressionQuestRewardGrant questGrant({
    int xpGranted = 200,
    int? baseXp,
    int? finalXp,
    ProgressionRewardStatus status = ProgressionRewardStatus.claimed,
    int? levelAtClaim,
    double? multiplierAtClaim,
  }) {
    return ProgressionQuestRewardGrant(
      rewardKey: 'quest|first_steps|reward',
      questId: 'first_steps',
      xpGranted: xpGranted,
      rewardStatus: status,
      unlockedAt: unlockedAt,
      completedAt: claimedAt,
      claimedAt: status == ProgressionRewardStatus.claimed ? claimedAt : null,
      finalXp: finalXp,
      levelAtClaim: levelAtClaim,
      multiplierAtClaim: multiplierAtClaim,
      baseXp: baseXp,
    );
  }

  final unlock = ProgressionAchievementUnlockEvent(
    unlockKey: 'achievement|first_reward',
    achievementId: 'first_reward',
    unlockedAt: unlockedAt,
  );

  // ---------------------------------------------------------------------------
  // isRuleGrantUploadable
  // ---------------------------------------------------------------------------

  group('isRuleGrantUploadable', () {
    test('claimed grant with xpGranted > 0 and claimedAt is uploadable', () {
      expect(
        ProgressionFirestoreMapper.isRuleGrantUploadable(ruleGrant()),
        isTrue,
      );
    });

    test('unclaimed grant is not uploadable', () {
      expect(
        ProgressionFirestoreMapper.isRuleGrantUploadable(
          ruleGrant(status: ProgressionRewardStatus.unlocked),
        ),
        isFalse,
      );
    });

    test('claimed grant with xpGranted = 0 and no finalXp is not uploadable',
        () {
      expect(
        ProgressionFirestoreMapper.isRuleGrantUploadable(
          ruleGrant(xpGranted: 0, finalXp: null),
        ),
        isFalse,
      );
    });

    test('claimed grant with claimedAt null is not uploadable', () {
      final grant = ProgressionRewardGrant(
        rewardKey: 'daily_steps|v1|day|2026-04-10|reward',
        ruleId: 'daily_steps',
        ruleVersion: 'v1',
        domain: ProgressionDomain.steps,
        period: ProgressionPeriod(
          kind: ProgressionPeriodKind.day,
          start: periodStart,
          end: periodStart,
        ),
        xpGranted: 80,
        targetValue: 10000,
        actualValue: 12000,
        rewardStatus: ProgressionRewardStatus.claimed,
        unlockedAt: unlockedAt,
        claimedAt: null,
      );
      expect(ProgressionFirestoreMapper.isRuleGrantUploadable(grant), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isQuestGrantUploadable
  // ---------------------------------------------------------------------------

  group('isQuestGrantUploadable', () {
    test('claimed quest grant is uploadable', () {
      expect(
        ProgressionFirestoreMapper.isQuestGrantUploadable(questGrant()),
        isTrue,
      );
    });

    test('unclaimed quest grant is not uploadable', () {
      expect(
        ProgressionFirestoreMapper.isQuestGrantUploadable(
          questGrant(status: ProgressionRewardStatus.unlocked),
        ),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ruleGrantToMap — serialization
  // ---------------------------------------------------------------------------

  group('ruleGrantToMap', () {
    test('uploads finalXp when set', () {
      final map = ProgressionFirestoreMapper.ruleGrantToMap(
        ruleGrant(
          xpGranted: 120,
          baseXp: 80,
          finalXp: 120,
          levelAtClaim: 3,
          multiplierAtClaim: 1.5,
        ),
      );

      expect(map['finalXp'], 120);
      expect(map['baseXp'], 80);
      expect(map['levelAtClaim'], 3);
      expect(map['multiplierAtClaim'], 1.5);
    });

    test(
        'uploads xpGranted as finalXp fallback when finalXp is null (legacy record)',
        () {
      final map = ProgressionFirestoreMapper.ruleGrantToMap(
        ruleGrant(xpGranted: 80, finalXp: null),
      );

      expect(map['finalXp'], 80);
      expect(map['baseXp'], 80);
    });

    test('serializes all required fields', () {
      final map = ProgressionFirestoreMapper.ruleGrantToMap(ruleGrant());

      expect(map['rewardKey'], 'daily_steps|v1|day|2026-04-10|reward');
      expect(map['type'], 'rule');
      expect(map['ruleId'], 'daily_steps');
      expect(map['ruleVersion'], 'v1');
      expect(map['domainName'], 'steps');
      expect(map['periodKindName'], 'day');
      expect(map['rewardStatusName'], 'claimed');
      expect(map['periodStart'], Timestamp.fromDate(periodStart));
      expect(map['unlockedAt'], Timestamp.fromDate(unlockedAt));
      expect(map['claimedAt'], Timestamp.fromDate(claimedAt));
    });

    test('does not include createdAt (gateway adds it)', () {
      final map = ProgressionFirestoreMapper.ruleGrantToMap(ruleGrant());
      expect(map.containsKey('createdAt'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // questGrantToMap — serialization
  // ---------------------------------------------------------------------------

  group('questGrantToMap', () {
    test('uploads finalXp when set', () {
      final map = ProgressionFirestoreMapper.questGrantToMap(
        questGrant(xpGranted: 300, baseXp: 200, finalXp: 300, levelAtClaim: 5),
      );

      expect(map['finalXp'], 300);
      expect(map['baseXp'], 200);
      expect(map['levelAtClaim'], 5);
    });

    test('uploads xpGranted as finalXp fallback when finalXp is null', () {
      final map = ProgressionFirestoreMapper.questGrantToMap(
        questGrant(xpGranted: 200, finalXp: null),
      );

      expect(map['finalXp'], 200);
    });

    test('serializes required fields', () {
      final map = ProgressionFirestoreMapper.questGrantToMap(questGrant());

      expect(map['rewardKey'], 'quest|first_steps|reward');
      expect(map['type'], 'quest');
      expect(map['questId'], 'first_steps');
      expect(map['rewardStatusName'], 'claimed');
      expect(map['unlockedAt'], Timestamp.fromDate(unlockedAt));
      expect(map['claimedAt'], Timestamp.fromDate(claimedAt));
    });
  });

  // ---------------------------------------------------------------------------
  // achievementUnlockToMap — serialization
  // ---------------------------------------------------------------------------

  group('achievementUnlockToMap', () {
    test('serializes all fields', () {
      final map = ProgressionFirestoreMapper.achievementUnlockToMap(unlock);

      expect(map['achievementId'], 'first_reward');
      expect(map['unlockKey'], 'achievement|first_reward');
      expect(map['unlockedAt'], Timestamp.fromDate(unlockedAt));
    });
  });

  // ---------------------------------------------------------------------------
  // ruleGrantFromMap — deserialization
  // ---------------------------------------------------------------------------

  group('ruleGrantFromMap', () {
    test('deserializes a valid rule grant map', () {
      final map = {
        'rewardKey': 'daily_steps|v1|day|2026-04-10|reward',
        'type': 'rule',
        'ruleId': 'daily_steps',
        'ruleVersion': 'v1',
        'domainName': 'steps',
        'periodKindName': 'day',
        'periodStart': Timestamp.fromDate(periodStart),
        'baseXp': 80,
        'finalXp': 120,
        'levelAtClaim': 3,
        'multiplierAtClaim': 1.5,
        'rewardStatusName': 'claimed',
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'claimedAt': Timestamp.fromDate(claimedAt),
      };

      final grant = ProgressionFirestoreMapper.ruleGrantFromMap(map);

      expect(grant, isNotNull);
      expect(grant!.rewardKey, 'daily_steps|v1|day|2026-04-10|reward');
      expect(grant.ruleId, 'daily_steps');
      expect(grant.domain, ProgressionDomain.steps);
      expect(grant.period.kind, ProgressionPeriodKind.day);
      expect(grant.period.start, periodStart);
      expect(grant.period.end, periodStart);
      expect(grant.xpGranted, 80);
      expect(grant.finalXp, 120);
      expect(grant.levelAtClaim, 3);
      expect(grant.multiplierAtClaim, 1.5);
      expect(grant.isClaimed, isTrue);
      expect(grant.effectiveXpGranted, 120);
    });

    test('reconstructs week period end as start + 6 days', () {
      final weekStart = DateTime(2026, 4, 14);
      final map = {
        'rewardKey': 'daily_activity|v1|week|2026-04-14|reward',
        'type': 'rule',
        'ruleId': 'daily_activity',
        'ruleVersion': 'v1',
        'domainName': 'activity',
        'periodKindName': 'week',
        'periodStart': Timestamp.fromDate(weekStart),
        'baseXp': 150,
        'finalXp': 150,
        'rewardStatusName': 'claimed',
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'claimedAt': Timestamp.fromDate(claimedAt),
      };

      final grant = ProgressionFirestoreMapper.ruleGrantFromMap(map);

      expect(grant, isNotNull);
      expect(grant!.period.kind, ProgressionPeriodKind.week);
      expect(grant.period.end, weekStart.add(const Duration(days: 6)));
    });

    test('returns null for wrong type', () {
      expect(
        ProgressionFirestoreMapper.ruleGrantFromMap({'type': 'quest'}),
        isNull,
      );
    });

    test('returns null for missing required field', () {
      expect(
        ProgressionFirestoreMapper.ruleGrantFromMap({'type': 'rule'}),
        isNull,
      );
    });

    test('round-trip: serialize then deserialize preserves key fields', () {
      final original =
          ruleGrant(finalXp: 120, levelAtClaim: 3, multiplierAtClaim: 1.5);
      final map = ProgressionFirestoreMapper.ruleGrantToMap(original);
      final restored = ProgressionFirestoreMapper.ruleGrantFromMap(map);

      expect(restored, isNotNull);
      expect(restored!.rewardKey, original.rewardKey);
      expect(restored.finalXp, original.finalXp);
      expect(restored.effectiveXpGranted, original.effectiveXpGranted);
      expect(restored.levelAtClaim, original.levelAtClaim);
      expect(restored.isClaimed, isTrue);
    });

    test(
        'round-trip: legacy grant with null finalXp restores xpGranted as finalXp',
        () {
      final legacy = ruleGrant(xpGranted: 80, finalXp: null);
      final map = ProgressionFirestoreMapper.ruleGrantToMap(legacy);
      final restored = ProgressionFirestoreMapper.ruleGrantFromMap(map);

      expect(restored, isNotNull);
      // finalXp was written as 80 (xpGranted fallback), restored correctly
      expect(restored!.finalXp, 80);
      expect(restored.effectiveXpGranted, 80);
    });
  });

  // ---------------------------------------------------------------------------
  // questGrantFromMap — deserialization
  // ---------------------------------------------------------------------------

  group('questGrantFromMap', () {
    test('deserializes a valid quest grant map', () {
      final map = {
        'rewardKey': 'quest|first_steps|reward',
        'type': 'quest',
        'questId': 'first_steps',
        'baseXp': 200,
        'finalXp': 250,
        'levelAtClaim': 2,
        'rewardStatusName': 'claimed',
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'claimedAt': Timestamp.fromDate(claimedAt),
      };

      final grant = ProgressionFirestoreMapper.questGrantFromMap(map);

      expect(grant, isNotNull);
      expect(grant!.questId, 'first_steps');
      expect(grant.xpGranted, 200);
      expect(grant.finalXp, 250);
      expect(grant.levelAtClaim, 2);
      expect(grant.isClaimed, isTrue);
      expect(grant.effectiveXpGranted, 250);
    });

    test('uses claimedAt as completedAt fallback', () {
      final map = {
        'rewardKey': 'quest|first_steps|reward',
        'type': 'quest',
        'questId': 'first_steps',
        'baseXp': 200,
        'finalXp': 200,
        'rewardStatusName': 'claimed',
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'claimedAt': Timestamp.fromDate(claimedAt),
      };

      final grant = ProgressionFirestoreMapper.questGrantFromMap(map);

      expect(grant!.completedAt, claimedAt);
    });

    test('returns null for wrong type', () {
      expect(
        ProgressionFirestoreMapper.questGrantFromMap({'type': 'rule'}),
        isNull,
      );
    });

    test('round-trip preserves key fields', () {
      final original =
          questGrant(finalXp: 300, levelAtClaim: 5, multiplierAtClaim: 2.0);
      final map = ProgressionFirestoreMapper.questGrantToMap(original);
      final restored = ProgressionFirestoreMapper.questGrantFromMap(map);

      expect(restored, isNotNull);
      expect(restored!.rewardKey, original.rewardKey);
      expect(restored.questId, original.questId);
      expect(restored.finalXp, original.finalXp);
      expect(restored.effectiveXpGranted, original.effectiveXpGranted);
    });
  });

  // ---------------------------------------------------------------------------
  // achievementUnlockFromMap — deserialization
  // ---------------------------------------------------------------------------

  group('achievementUnlockFromMap', () {
    test('deserializes a valid achievement unlock map', () {
      final map = {
        'achievementId': 'first_reward',
        'unlockKey': 'achievement|first_reward',
        'unlockedAt': Timestamp.fromDate(unlockedAt),
      };

      final result = ProgressionFirestoreMapper.achievementUnlockFromMap(map);

      expect(result, isNotNull);
      expect(result!.achievementId, 'first_reward');
      expect(result.unlockKey, 'achievement|first_reward');
      expect(result.unlockedAt, unlockedAt);
    });

    test('returns null for missing required field', () {
      expect(
        ProgressionFirestoreMapper.achievementUnlockFromMap(
            {'achievementId': 'x'}),
        isNull,
      );
    });

    test('round-trip preserves all fields', () {
      final map = ProgressionFirestoreMapper.achievementUnlockToMap(unlock);
      final restored = ProgressionFirestoreMapper.achievementUnlockFromMap(map);

      expect(restored, isNotNull);
      expect(restored!.achievementId, unlock.achievementId);
      expect(restored.unlockKey, unlock.unlockKey);
      expect(restored.unlockedAt, unlock.unlockedAt);
    });
  });
}
