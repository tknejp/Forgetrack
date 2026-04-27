import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:forgetrack/features/progression/data/firestore/progression_cloud_gateway.dart';
import 'package:forgetrack/features/progression/data/hybrid_progression_repository.dart';
import 'package:forgetrack/features/progression/domain/progression_local_repository.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';

void main() {
  late _FakeLocalRepository local;
  late _FakeGateway gateway;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    local = _FakeLocalRepository();
    gateway = _FakeGateway();
  });

  HybridProgressionRepository buildRepo(String? Function() uid) =>
      HybridProgressionRepository(
        local: local,
        remote: gateway,
        userIdProvider: uid,
        prefs: prefs,
      );

  // ── Logged-out behaviour ────────────────────────────────────────────────────

  group('logged-out', () {
    test('loadLedger returns local snapshot without touching gateway', () async {
      final repo = buildRepo(() => null);
      await repo.loadLedger();
      expect(local.loadLedgerCalls, 1);
      expect(gateway.pushRuleCalls, 0);
      expect(gateway.pushQuestCalls, 0);
      expect(gateway.pushUnlockCalls, 0);
    });

    test('claimReward writes to local only', () async {
      local.rewardGrants = [_unlockedRuleGrant('key1')];
      final repo = buildRepo(() => null);
      await repo.claimReward(
        rewardKey: 'key1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 80,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      expect(local.claimRewardCalls, 1);
      expect(gateway.pushRuleCalls, 0);
    });

    test('claimQuestReward writes to local only', () async {
      local.questRewardGrants = [_unlockedQuestGrant('qkey1')];
      final repo = buildRepo(() => null);
      await repo.claimQuestReward(
        rewardKey: 'qkey1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 200,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      expect(local.claimQuestRewardCalls, 1);
      expect(gateway.pushQuestCalls, 0);
    });

    test('persistAchievementUnlocks writes to local only', () async {
      final repo = buildRepo(() => null);
      await repo.persistAchievementUnlocks(
        unlocks: [_unlock('achievement|first_reward', 'first_reward')],
      );
      expect(local.persistUnlockCalls, 1);
      expect(gateway.pushUnlockCalls, 0);
    });

    test('persistEvaluations, persistQuestRewardGrants, persistActiveQuestSet delegate to local', () async {
      final repo = buildRepo(() => null);
      await repo.persistEvaluations(evaluations: [], evaluatedAt: DateTime(2026, 4, 27));
      await repo.persistQuestRewardGrants(grants: []);
      await repo.persistActiveQuestSet(activeQuestIds: {});
      expect(local.persistEvaluationsCalls, 1);
      expect(local.persistQuestGrantsCalls, 1);
      expect(local.persistActiveQuestSetCalls, 1);
      expect(gateway.pushRuleCalls, 0);
    });
  });

  // ── Logged-in write behaviour ───────────────────────────────────────────────

  group('logged-in writes', () {
    test('claimReward: local first, then gateway push', () async {
      local.rewardGrants = [_unlockedRuleGrant('key1')];
      final repo = buildRepo(() => 'uid-abc');
      await repo.claimReward(
        rewardKey: 'key1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 80,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      expect(local.claimRewardCalls, 1);
      await Future.delayed(Duration.zero); // let fire-and-forget run
      expect(gateway.pushRuleCalls, 1);
      expect(gateway.lastPushRuleUid, 'uid-abc');
    });

    test('claimQuestReward: local first, then gateway push', () async {
      local.questRewardGrants = [_unlockedQuestGrant('qkey1')];
      final repo = buildRepo(() => 'uid-abc');
      await repo.claimQuestReward(
        rewardKey: 'qkey1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 200,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      expect(local.claimQuestRewardCalls, 1);
      await Future.delayed(Duration.zero);
      expect(gateway.pushQuestCalls, 1);
      expect(gateway.lastPushQuestUid, 'uid-abc');
    });

    test('persistAchievementUnlocks: local first, then gateway push per unlock', () async {
      final repo = buildRepo(() => 'uid-abc');
      await repo.persistAchievementUnlocks(unlocks: [
        _unlock('achievement|a1', 'a1'),
        _unlock('achievement|a2', 'a2'),
      ]);
      expect(local.persistUnlockCalls, 1);
      await Future.delayed(Duration.zero);
      expect(gateway.pushUnlockCalls, 2);
    });

    test('claimReward with no matching grant skips gateway push', () async {
      local.rewardGrants = []; // grant doesn't exist
      final repo = buildRepo(() => 'uid-abc');
      await repo.claimReward(
        rewardKey: 'missing',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 80,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      await Future.delayed(Duration.zero);
      expect(gateway.pushRuleCalls, 0);
    });
  });

  // ── loadLedger pull trigger ─────────────────────────────────────────────────

  group('loadLedger pull trigger', () {
    test('no pull when prefs has a fresh timestamp', () async {
      await prefs.setString(
        'progressionLastFirestorePullAt',
        DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      );
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.pullClaimsCalls, 0);
    });

    test('triggers background pull when prefs has no timestamp', () async {
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.pullClaimsCalls, 1);
    });

    test('triggers background pull when cached timestamp is stale (> 5 min)', () async {
      await prefs.setString(
        'progressionLastFirestorePullAt',
        DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
      );
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.pullClaimsCalls, 1);
    });

    test('returns Isar snapshot immediately even when pull is triggered', () async {
      gateway.pullDelay = const Duration(milliseconds: 50);
      final repo = buildRepo(() => 'uid-abc');
      final ledger = await repo.loadLedger(); // must not wait for pull
      expect(ledger, isNotNull);
      expect(local.loadLedgerCalls, greaterThanOrEqualTo(1));
    });

    test('no pull when logged out, even with stale timestamp', () async {
      final repo = buildRepo(() => null);
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.pullClaimsCalls, 0);
    });
  });

  // ── pullAndHydrate ──────────────────────────────────────────────────────────

  group('pullAndHydrate', () {
    test('inserts remote rule grants not present locally', () async {
      gateway.remoteClaims = (
        ruleGrants: [_claimedRuleGrant('remote-rule-1')],
        questGrants: [],
      );
      local.rewardGrants = [];
      final repo = buildRepo(() => 'uid-abc');
      await repo.pullAndHydrate('uid-abc');
      expect(local.insertRestoredRuleGrantCalls, 1);
    });

    test('skips rule grants already present locally', () async {
      gateway.remoteClaims = (
        ruleGrants: [_claimedRuleGrant('rule-exists')],
        questGrants: [],
      );
      local.rewardGrants = [_claimedRuleGrant('rule-exists')];
      final repo = buildRepo(() => 'uid-abc');
      await repo.pullAndHydrate('uid-abc');
      expect(local.insertRestoredRuleGrantCalls, 0);
    });

    test('inserts remote quest grants not present locally', () async {
      gateway.remoteClaims = (
        ruleGrants: [],
        questGrants: [_claimedQuestGrant('remote-quest-1')],
      );
      local.questRewardGrants = [];
      final repo = buildRepo(() => 'uid-abc');
      await repo.pullAndHydrate('uid-abc');
      expect(local.insertRestoredQuestGrantCalls, 1);
    });

    test('inserts remote achievement unlocks not present locally', () async {
      gateway.remoteUnlocks = [_unlock('achievement|a1', 'a1')];
      local.achievementUnlocks = [];
      final repo = buildRepo(() => 'uid-abc');
      await repo.pullAndHydrate('uid-abc');
      expect(local.persistUnlockCalls, 1);
    });

    test('skips achievement unlocks already present locally', () async {
      gateway.remoteUnlocks = [_unlock('achievement|a1', 'a1')];
      local.achievementUnlocks = [_unlock('achievement|a1', 'a1')];
      final repo = buildRepo(() => 'uid-abc');
      await repo.pullAndHydrate('uid-abc');
      expect(local.persistUnlockCalls, 0);
    });

    test('updates lastFirestorePullAt after successful pull', () async {
      final repo = buildRepo(() => 'uid-abc');
      await repo.pullAndHydrate('uid-abc');
      expect(prefs.getString('progressionLastFirestorePullAt'), isNotNull);
    });
  });

  // ── Phase 4d: Migration trigger ─────────────────────────────────────────────

  group('migration trigger (Phase 4d)', () {
    test('does not migrate when logged out', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      final repo = buildRepo(() => null);
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.migrationCalls, 0);
    });

    test('triggers migration on loadLedger when uid is available', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      local.achievementUnlocks = [];
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.migrationCalls, 1);
      expect(gateway.lastMigrationUid, 'uid-abc');
    });

    test('migration runs once per uid (tracked in prefs)', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      local.achievementUnlocks = [];
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.migrationCalls, 1);
      // Second load should not trigger migration
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.migrationCalls, 1);
    });

    test('SharedPreferences key format is progression_migrated_\$uid', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      local.achievementUnlocks = [];
      final repo = buildRepo(() => 'uid-test123');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(prefs.getBool('progression_migrated_uid-test123'), true);
    });

    test('migration includes all claimed rule grants', () async {
      local.rewardGrants = [
        _claimedRuleGrant('rule1'),
        _claimedRuleGrant('rule2'),
      ];
      local.questRewardGrants = [];
      local.achievementUnlocks = [];
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.lastMigrationRuleGrants?.length, 2);
    });

    test('migration includes all achievement unlocks', () async {
      local.rewardGrants = [];
      local.questRewardGrants = [];
      local.achievementUnlocks = [
        _unlock('achievement|a1', 'a1'),
        _unlock('achievement|a2', 'a2'),
      ];
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.lastMigrationAchievementUnlocks?.length, 2);
    });

    test('migration failure does not mark complete (allows retry)', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      local.achievementUnlocks = [];
      gateway.shouldFailMigration = true;
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      expect(gateway.migrationCalls, 1);
      // Migration key should not be set if migration failed
      expect(prefs.getBool('progression_migrated_uid-abc'), isNot(true));
    });

    test('migration failure does not block subsequent loadLedger', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      local.achievementUnlocks = [];
      gateway.shouldFailMigration = true;
      final repo = buildRepo(() => 'uid-abc');
      await repo.loadLedger();
      await Future.delayed(Duration.zero);
      // Should still return ledger even if migration failed
      expect(local.loadLedgerCalls, greaterThanOrEqualTo(1));
    });

    test('different uids can have independent migration states', () async {
      local.rewardGrants = [_claimedRuleGrant('key1')];
      local.achievementUnlocks = [];
      
      final repo1 = buildRepo(() => 'uid-user1');
      await repo1.loadLedger();
      await Future.delayed(Duration.zero);
      expect(prefs.getBool('progression_migrated_uid-user1'), true);
      expect(prefs.getBool('progression_migrated_uid-user2'), isNot(true));

      final repo2 = buildRepo(() => 'uid-user2');
      await repo2.loadLedger();
      await Future.delayed(Duration.zero);
      expect(prefs.getBool('progression_migrated_uid-user2'), true);
    });
  });

  // ── Summary update (Phase 4e) ───────────────────────────────────────────────

  group('progression summary (Phase 4e)', () {
    test('logged-out claim does not update summary', () async {
      local.rewardGrants = [_unlockedRuleGrant('key1')];
      final repo = buildRepo(() => null);
      await repo.claimReward(
        rewardKey: 'key1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 80,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      expect(gateway.updateSummaryCalls, 0);
    });

    test('logged-in claimReward updates summary', () async {
      local.rewardGrants = [_claimedRuleGrant('key1', finalXp: 80)];
      final repo = buildRepo(() => 'uid-abc');
      await repo.claimReward(
        rewardKey: 'key1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 80,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      expect(gateway.updateSummaryCalls, 1);
      expect(gateway.lastSummaryUid, 'uid-abc');
      expect(gateway.lastSummaryLedger, isNotNull);
    });

    test('logged-in claimQuestReward updates summary', () async {
      local.questRewardGrants = [_claimedQuestGrant('qkey1', finalXp: 150)];
      final repo = buildRepo(() => 'uid-abc');
      await repo.claimQuestReward(
        rewardKey: 'qkey1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 150,
        levelAtClaim: 2,
        multiplierAtClaim: 1.2,
      );
      expect(gateway.updateSummaryCalls, 1);
      expect(gateway.lastSummaryUid, 'uid-abc');
    });

    test('logged-in persistAchievementUnlocks updates summary', () async {
      final unlock = _unlock('achievement|first_reward', 'first_reward');
      final repo = buildRepo(() => 'uid-abc');
      // Persistence adds the unlock to local
      await repo.persistAchievementUnlocks(unlocks: [unlock]);
      expect(gateway.updateSummaryCalls, 1);
      expect(gateway.lastSummaryUid, 'uid-abc');
      expect(gateway.lastSummaryLedger?.achievementUnlocks, hasLength(1));
    });

    test('summary uses effectiveXpGranted from claimed grants', () async {
      // Claim two grants: one with finalXp set, one legacy with finalXp=null
      local.rewardGrants = [
        _claimedRuleGrant('key1', finalXp: 100),
        _claimedRuleGrant('key2', xpGranted: 80, finalXp: null),
      ];
      final repo = buildRepo(() => 'uid-abc');
      await repo.claimReward(
        rewardKey: 'key1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 100,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      final summary = gateway.lastSummaryLedger;
      expect(summary, isNotNull);
      // effectiveXpGranted for key1: finalXp ?? xpGranted = 100 ?? ? = 100
      // effectiveXpGranted for key2: finalXp ?? xpGranted = null ?? 80 = 80
      final totalEffective = summary!.rewardGrants.fold<int>(
        0,
        (sum, g) => sum + g.effectiveXpGranted,
      );
      expect(totalEffective, 180); // 100 + 80
    });

    test('summary write failure does not break local claim', () async {
      gateway.shouldFailSummary = true;
      local.rewardGrants = [_unlockedRuleGrant('key1')];
      final repo = buildRepo(() => 'uid-abc');
      final ledger = await repo.claimReward(
        rewardKey: 'key1',
        claimedAt: DateTime(2026, 4, 27),
        finalXp: 80,
        levelAtClaim: 1,
        multiplierAtClaim: 1.0,
      );
      // Claim should succeed even though summary write failed
      expect(local.claimRewardCalls, 1);
      expect(ledger, isNotNull);
    });
  });
}


// ─── Helpers ──────────────────────────────────────────────────────────────────

ProgressionRewardGrant _unlockedRuleGrant(String rewardKey) =>
    ProgressionRewardGrant(
      rewardKey: rewardKey,
      ruleId: 'daily_steps',
      ruleVersion: 'v1',
      domain: ProgressionDomain.steps,
      period: ProgressionPeriod(
        kind: ProgressionPeriodKind.day,
        start: DateTime(2026, 4, 27),
        end: DateTime(2026, 4, 27),
      ),
      xpGranted: 80,
      targetValue: 10000,
      actualValue: 12000,
      rewardStatus: ProgressionRewardStatus.unlocked,
      unlockedAt: DateTime(2026, 4, 27),
    );

ProgressionRewardGrant _claimedRuleGrant(
  String rewardKey, {
  int? xpGranted,
  int? finalXp,
}) =>
    ProgressionRewardGrant(
      rewardKey: rewardKey,
      ruleId: 'daily_steps',
      ruleVersion: 'v1',
      domain: ProgressionDomain.steps,
      period: ProgressionPeriod(
        kind: ProgressionPeriodKind.day,
        start: DateTime(2026, 4, 27),
        end: DateTime(2026, 4, 27),
      ),
      xpGranted: xpGranted ?? 80,
      targetValue: 10000,
      actualValue: 12000,
      rewardStatus: ProgressionRewardStatus.claimed,
      unlockedAt: DateTime(2026, 4, 27),
      claimedAt: DateTime(2026, 4, 27, 12),
      finalXp: finalXp ?? 80,
      levelAtClaim: 1,
      multiplierAtClaim: 1.0,
    );

ProgressionQuestRewardGrant _unlockedQuestGrant(String rewardKey) =>
    ProgressionQuestRewardGrant(
      rewardKey: rewardKey,
      questId: 'first_steps',
      xpGranted: 200,
      rewardStatus: ProgressionRewardStatus.unlocked,
      unlockedAt: DateTime(2026, 4, 27),
      completedAt: DateTime(2026, 4, 27),
    );

ProgressionQuestRewardGrant _claimedQuestGrant(
  String rewardKey, {
  int? xpGranted,
  int? finalXp,
}) =>
    ProgressionQuestRewardGrant(
      rewardKey: rewardKey,
      questId: 'first_steps',
      xpGranted: xpGranted ?? 200,
      rewardStatus: ProgressionRewardStatus.claimed,
      unlockedAt: DateTime(2026, 4, 27),
      completedAt: DateTime(2026, 4, 27),
      claimedAt: DateTime(2026, 4, 27, 12),
      finalXp: finalXp ?? 200,
      levelAtClaim: 1,
      multiplierAtClaim: 1.0,
    );

ProgressionAchievementUnlockEvent _unlock(String unlockKey, String achievementId) =>
    ProgressionAchievementUnlockEvent(
      unlockKey: unlockKey,
      achievementId: achievementId,
      unlockedAt: DateTime(2026, 4, 27),
    );

// ─── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeLocalRepository implements ProgressionLocalRepository {
  List<ProgressionRewardGrant> rewardGrants = [];
  List<ProgressionQuestRewardGrant> questRewardGrants = [];
  List<ProgressionAchievementUnlockEvent> achievementUnlocks = [];

  int loadLedgerCalls = 0;
  int claimRewardCalls = 0;
  int claimQuestRewardCalls = 0;
  int persistUnlockCalls = 0;
  int persistEvaluationsCalls = 0;
  int persistQuestGrantsCalls = 0;
  int persistActiveQuestSetCalls = 0;
  int insertRestoredRuleGrantCalls = 0;
  int insertRestoredQuestGrantCalls = 0;

  ProgressionLedgerSnapshot _snapshot() => ProgressionLedgerSnapshot(
        evaluations: [],
        rewardGrants: rewardGrants,
        questRewardGrants: questRewardGrants,
        activeQuestIds: {},
        achievementUnlocks: achievementUnlocks,
        lastEvaluatedAt: null,
      );

  @override
  Future<ProgressionLedgerSnapshot> loadLedger() async {
    loadLedgerCalls++;
    return _snapshot();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    claimRewardCalls++;
    rewardGrants = rewardGrants.map((g) {
      if (g.rewardKey == rewardKey) {
        return ProgressionRewardGrant(
          rewardKey: g.rewardKey,
          ruleId: g.ruleId,
          ruleVersion: g.ruleVersion,
          domain: g.domain,
          period: g.period,
          xpGranted: g.xpGranted,
          targetValue: g.targetValue,
          actualValue: g.actualValue,
          rewardStatus: ProgressionRewardStatus.claimed,
          unlockedAt: g.unlockedAt,
          claimedAt: claimedAt,
          finalXp: finalXp,
          levelAtClaim: levelAtClaim,
          multiplierAtClaim: multiplierAtClaim,
        );
      }
      return g;
    }).toList();
    return _snapshot();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    claimQuestRewardCalls++;
    questRewardGrants = questRewardGrants.map((g) {
      if (g.rewardKey == rewardKey) {
        return ProgressionQuestRewardGrant(
          rewardKey: g.rewardKey,
          questId: g.questId,
          xpGranted: g.xpGranted,
          rewardStatus: ProgressionRewardStatus.claimed,
          unlockedAt: g.unlockedAt,
          completedAt: g.completedAt,
          claimedAt: claimedAt,
          finalXp: finalXp,
          levelAtClaim: levelAtClaim,
          multiplierAtClaim: multiplierAtClaim,
        );
      }
      return g;
    }).toList();
    return _snapshot();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  }) async {
    persistEvaluationsCalls++;
    return _snapshot();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  }) async {
    persistQuestGrantsCalls++;
    return _snapshot();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  }) async {
    persistActiveQuestSetCalls++;
    return _snapshot();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistAchievementUnlocks({
    required List<ProgressionAchievementUnlockEvent> unlocks,
  }) async {
    persistUnlockCalls++;
    achievementUnlocks = [...achievementUnlocks, ...unlocks];
    return _snapshot();
  }

  @override
  Future<void> insertRestoredRuleGrant(ProgressionRewardGrant grant) async {
    insertRestoredRuleGrantCalls++;
    rewardGrants = [...rewardGrants, grant];
  }

  @override
  Future<void> insertRestoredQuestGrant(ProgressionQuestRewardGrant grant) async {
    insertRestoredQuestGrantCalls++;
    questRewardGrants = [...questRewardGrants, grant];
  }
}

class _FakeGateway implements ProgressionCloudGateway {

  int pushRuleCalls = 0;
  int pushQuestCalls = 0;
  int pushUnlockCalls = 0;
  int pullClaimsCalls = 0;
  int migrationCalls = 0;
  int updateSummaryCalls = 0;
  String? lastPushRuleUid;
  String? lastPushQuestUid;
  String? lastMigrationUid;
  String? lastSummaryUid;
  ProgressionLedgerSnapshot? lastSummaryLedger;
  List<ProgressionRewardGrant>? lastMigrationRuleGrants;
  List<ProgressionQuestRewardGrant>? lastMigrationQuestGrants;
  List<ProgressionAchievementUnlockEvent>? lastMigrationAchievementUnlocks;
  bool shouldFailMigration = false;
  bool shouldFailSummary = false;
  Duration pullDelay = Duration.zero;

  ({
    List<ProgressionRewardGrant> ruleGrants,
    List<ProgressionQuestRewardGrant> questGrants,
  }) remoteClaims = (ruleGrants: [], questGrants: []);
  List<ProgressionAchievementUnlockEvent> remoteUnlocks = [];

  @override
  Future<void> pushRuleClaimIfMissing(
    String uid,
    ProgressionRewardGrant grant,
  ) async {
    pushRuleCalls++;
    lastPushRuleUid = uid;
  }

  @override
  Future<void> pushQuestClaimIfMissing(
    String uid,
    ProgressionQuestRewardGrant grant,
  ) async {
    pushQuestCalls++;
    lastPushQuestUid = uid;
  }

  @override
  Future<void> pushAchievementUnlockIfMissing(
    String uid,
    ProgressionAchievementUnlockEvent unlock,
  ) async {
    pushUnlockCalls++;
  }

  @override
  Future<({
    List<ProgressionRewardGrant> ruleGrants,
    List<ProgressionQuestRewardGrant> questGrants,
  })> pullClaims(String uid) async {
    pullClaimsCalls++;
    if (pullDelay > Duration.zero) await Future.delayed(pullDelay);
    return remoteClaims;
  }

  @override
  Future<List<ProgressionAchievementUnlockEvent>> pullAchievementUnlocks(
    String uid,
  ) async {
    return remoteUnlocks;
  }

  @override
  Future<void> migrateLocalLedger({
    required String uid,
    required List<ProgressionRewardGrant> ruleGrants,
    required List<ProgressionQuestRewardGrant> questGrants,
    required List<ProgressionAchievementUnlockEvent> achievementUnlocks,
  }) async {
    migrationCalls++;
    lastMigrationUid = uid;
    lastMigrationRuleGrants = ruleGrants;
    lastMigrationQuestGrants = questGrants;
    lastMigrationAchievementUnlocks = achievementUnlocks;
    if (shouldFailMigration) {
      throw Exception('Simulated migration failure');
    }
  }

  @override
  Future<void> updateProgressionSummary({
    required String uid,
    required ProgressionLedgerSnapshot ledger,
  }) async {
    updateSummaryCalls++;
    lastSummaryUid = uid;
    lastSummaryLedger = ledger;
    if (shouldFailSummary) {
      throw Exception('Simulated summary write failure');
    }
  }
}
