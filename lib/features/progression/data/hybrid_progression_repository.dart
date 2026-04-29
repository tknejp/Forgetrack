import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_log.dart';
import '../domain/progression_local_repository.dart';
import '../domain/progression_models.dart';
import 'firestore/progression_cloud_gateway.dart';

const _kLastPullKey = 'progressionLastFirestorePullAt';
const _kStaleDuration = Duration(minutes: 5);
const _kMigrationKeyPrefix = 'progression_migrated_';

/// Wraps [LocalProgressionRepository] (Isar) with a [ProgressionCloudGateway]
/// for cloud persistence of claimed rewards and achievement unlocks.
///
/// **Read strategy**: always from Isar (instant). A background pull from Firestore
/// is triggered when the cached pull timestamp is stale (> 5 min) and the user
/// is logged in.
///
/// **Write strategy**: Isar first (synchronous commit), then fire-and-forget
/// Firestore write (offline SDK handles retry).
///
/// When [userIdProvider] returns null (logged out), all methods delegate to
/// [_local] with no Firestore interaction.
class HybridProgressionRepository implements ProgressionLocalRepository {
  HybridProgressionRepository({
    required ProgressionLocalRepository local,
    required ProgressionCloudGateway remote,
    required String? Function() userIdProvider,
    required SharedPreferences prefs,
  })  : _local = local,
        _remote = remote,
        _userIdProvider = userIdProvider,
        _prefs = prefs;

  final ProgressionLocalRepository _local;
  final ProgressionCloudGateway _remote;
  final String? Function() _userIdProvider;
  final SharedPreferences _prefs;

  // ---------------------------------------------------------------------------
  // ProgressionRepository interface
  // ---------------------------------------------------------------------------

  @override
  Future<ProgressionLedgerSnapshot> loadLedger() async {
    _maybeTriggerMigration();
    _maybeTriggerBackgroundPull();
    return _local.loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  }) =>
      _local.persistEvaluations(
          evaluations: evaluations, evaluatedAt: evaluatedAt);

  @override
  Future<ProgressionLedgerSnapshot> claimReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    final ledger = await _local.claimReward(
      rewardKey: rewardKey,
      claimedAt: claimedAt,
      finalXp: finalXp,
      levelAtClaim: levelAtClaim,
      multiplierAtClaim: multiplierAtClaim,
    );
    final uid = _userIdProvider();
    if (uid != null) {
      final grant = ledger.rewardGrants
          .where((g) => g.rewardKey == rewardKey)
          .firstOrNull;
      if (grant != null) {
        _trackRemoteWrite(
          _remote.pushRuleClaimIfMissing(uid, grant),
          'pushRuleClaimIfMissing',
          uid: uid,
          key: grant.rewardKey,
        );
      }
      _trackRemoteWrite(
        _remote.updateProgressionSummary(uid: uid, ledger: ledger),
        'updateProgressionSummary',
        uid: uid,
      );
    }
    return ledger;
  }

  @override
  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    final ledger = await _local.claimQuestReward(
      rewardKey: rewardKey,
      claimedAt: claimedAt,
      finalXp: finalXp,
      levelAtClaim: levelAtClaim,
      multiplierAtClaim: multiplierAtClaim,
    );
    final uid = _userIdProvider();
    if (uid != null) {
      final grant = ledger.questRewardGrants
          .where((g) => g.rewardKey == rewardKey)
          .firstOrNull;
      if (grant != null) {
        _trackRemoteWrite(
          _remote.pushQuestClaimIfMissing(uid, grant),
          'pushQuestClaimIfMissing',
          uid: uid,
          key: grant.rewardKey,
        );
      }
      _trackRemoteWrite(
        _remote.updateProgressionSummary(uid: uid, ledger: ledger),
        'updateProgressionSummary',
        uid: uid,
      );
    }
    return ledger;
  }

  @override
  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  }) =>
      _local.persistQuestRewardGrants(grants: grants);

  @override
  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  }) =>
      _local.persistActiveQuestSet(activeQuestIds: activeQuestIds);

  @override
  Future<ProgressionLedgerSnapshot> persistAchievementUnlocks({
    required List<ProgressionAchievementUnlockEvent> unlocks,
  }) async {
    final ledger = await _local.persistAchievementUnlocks(unlocks: unlocks);
    final uid = _userIdProvider();
    if (uid != null) {
      for (final unlock in unlocks) {
        _trackRemoteWrite(
          _remote.pushAchievementUnlockIfMissing(uid, unlock),
          'pushAchievementUnlockIfMissing',
          uid: uid,
          key: unlock.achievementId,
        );
      }
      _trackRemoteWrite(
        _remote.updateProgressionSummary(uid: uid, ledger: ledger),
        'updateProgressionSummary',
        uid: uid,
      );
    }
    return ledger;
  }

  @override
  Future<void> insertRestoredRuleGrant(ProgressionRewardGrant grant) =>
      _local.insertRestoredRuleGrant(grant);

  @override
  Future<void> insertRestoredQuestGrant(ProgressionQuestRewardGrant grant) =>
      _local.insertRestoredQuestGrant(grant);

  @override
  Future<void> wipeAllProgressionData() async {
    // Local wipe is authoritative — fail loudly if it doesn't succeed.
    await _local.wipeAllProgressionData();

    // Reset pull / migration markers so the next sync round-trip starts fresh.
    await _prefs.remove(_kLastPullKey);
    final keysToRemove = _prefs
        .getKeys()
        .where((k) => k.startsWith(_kMigrationKeyPrefix))
        .toList(growable: false);
    for (final k in keysToRemove) {
      await _prefs.remove(k);
    }

    // Remote wipe is best-effort: a failure here would otherwise resurface
    // old claims via the next pull, but a) devtools resets are typically
    // followed by manual verification, and b) we'd rather keep the local
    // wipe successful than tear it down on a transient network blip.
    final uid = _userIdProvider();
    if (uid != null) {
      try {
        await _remote.wipeAllRemoteData(uid);
      } catch (error) {
        AppLog.sync.warn(
          'Devtools: remote progression wipe failed for uid=$uid',
          payload: error,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pull / hydration
  // ---------------------------------------------------------------------------

  /// Pulls all claims and achievement unlocks from Firestore and hydrates Isar
  /// with any records not already present locally.
  ///
  /// Safe to call on login / reinstall. All writes to Isar are additive
  /// (create-if-not-exists semantics). Updates the pull timestamp on completion.
  Future<void> pullAndHydrate(String uid) async {
    final remote = await Future.wait([
      _remote.pullClaims(uid),
      _remote.pullAchievementUnlocks(uid),
    ]);

    final claims = remote[0] as ({
      List<ProgressionRewardGrant> ruleGrants,
      List<ProgressionQuestRewardGrant> questGrants,
    });
    final unlocks = remote[1] as List<ProgressionAchievementUnlockEvent>;

    if (claims.ruleGrants.isNotEmpty || claims.questGrants.isNotEmpty) {
      final local = await _local.loadLedger();
      final existingRuleKeys =
          local.rewardGrants.map((g) => g.rewardKey).toSet();
      final existingQuestKeys =
          local.questRewardGrants.map((g) => g.rewardKey).toSet();

      final newRuleGrants = claims.ruleGrants
          .where((g) => !existingRuleKeys.contains(g.rewardKey))
          .toList();
      final newQuestGrants = claims.questGrants
          .where((g) => !existingQuestKeys.contains(g.rewardKey))
          .toList();

      // Persist as claimed — these arrive from Firestore with status = claimed.
      // We write them directly by re-claiming each key so the local schema
      // stores finalXp / levelAtClaim properly.
      for (final grant in newRuleGrants) {
        // Insert as unlocked first (persistEvaluations path won't cover these),
        // then claim immediately to freeze finalXp.
        await _local.insertRestoredRuleGrant(grant);
      }
      for (final grant in newQuestGrants) {
        await _local.insertRestoredQuestGrant(grant);
      }
    }

    if (unlocks.isNotEmpty) {
      final local = await _local.loadLedger();
      final existingKeys =
          local.achievementUnlocks.map((u) => u.unlockKey).toSet();
      final newUnlocks =
          unlocks.where((u) => !existingKeys.contains(u.unlockKey)).toList();
      if (newUnlocks.isNotEmpty) {
        await _local.persistAchievementUnlocks(unlocks: newUnlocks);
      }
    }

    await _prefs.setString(
      _kLastPullKey,
      DateTime.now().toIso8601String(),
    );
  }

  // ---------------------------------------------------------------------------
  // Background pull trigger
  // ---------------------------------------------------------------------------

  void _maybeTriggerBackgroundPull() {
    final uid = _userIdProvider();
    if (uid == null) return;

    final raw = _prefs.getString(_kLastPullKey);
    if (raw != null) {
      final last = DateTime.tryParse(raw);
      if (last != null && DateTime.now().difference(last) < _kStaleDuration) {
        return;
      }
    }

    pullAndHydrate(uid).ignore();
  }

  // ---------------------------------------------------------------------------
  // Migration trigger (Phase 4d)
  // ---------------------------------------------------------------------------

  /// Triggers migration of local progression ledger to Firestore when uid
  /// becomes available (after login). Runs once per canonical uid.
  ///
  /// **Semantics:**
  /// - Migration is tracked in SharedPreferences using key `progression_migrated_$uid`.
  /// - Once migration succeeds for a uid, it is never retried.
  /// - If migration fails (network, permission, etc.), it is not marked complete,
  ///   allowing retry on next call.
  /// - Failures are logged but do not block the app or raise exceptions.
  /// - Fire-and-forget: does not block normal local claim behavior.
  ///
  /// **Data uploaded:**
  /// - Only claimed rewards and achievement unlocks (verified via mapper).
  /// - Unclaimed rewards, evaluations, active quest set, raw health/nutrition
  ///   data remain local-only.
  /// - Legacy claimed records with finalXp == null are uploaded with
  ///   finalXp = xpGranted (via mapper).
  void _maybeTriggerMigration() {
    final uid = _userIdProvider();
    if (uid == null) return;

    final migrationKey = '$_kMigrationKeyPrefix$uid';
    if (_prefs.getBool(migrationKey) ?? false) {
      return; // Already migrated for this uid
    }

    _performMigrationAsync(uid, migrationKey).ignore();
  }

  Future<void> _performMigrationAsync(String uid, String migrationKey) async {
    try {
      final ledger = await _local.loadLedger();

      await _remote.migrateLocalLedger(
        uid: uid,
        ruleGrants: ledger.rewardGrants,
        questGrants: ledger.questRewardGrants,
        achievementUnlocks: ledger.achievementUnlocks,
      );

      await _prefs.setBool(migrationKey, true);
    } catch (error) {
      AppLog.sync.warn(
        'Phase 4d: Progression migration failed for uid=$uid',
        payload: error,
      );
      // Do not mark migration complete; it can be retried on next app load.
    }
  }

  void _trackRemoteWrite(
    Future<void> future,
    String operation, {
    required String uid,
    String? key,
  }) {
    future.then((_) {
      AppLog.sync.debug(
        'Progression cloud write ok: $operation uid=$uid'
        '${key == null ? '' : ' key=$key'}',
      );
    }).catchError((Object error, StackTrace stackTrace) {
      AppLog.sync.warn(
        'Progression cloud write failed: $operation uid=$uid'
        '${key == null ? '' : ' key=$key'}',
        payload: error,
      );
    });
  }
}
