import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progression_local_repository.dart';
import '../domain/progression_models.dart';
import 'firestore/progression_cloud_gateway.dart';

const _kLastPullKey = 'progressionLastFirestorePullAt';
const _kStaleDuration = Duration(minutes: 5);

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
    _maybeTriggerBackgroundPull();
    return _local.loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  }) =>
      _local.persistEvaluations(evaluations: evaluations, evaluatedAt: evaluatedAt);

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
        _remote.pushRuleClaimIfMissing(uid, grant).ignore();
      }
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
        _remote.pushQuestClaimIfMissing(uid, grant).ignore();
      }
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
        _remote.pushAchievementUnlockIfMissing(uid, unlock).ignore();
      }
    }
    return ledger;
  }

  @override
  Future<void> insertRestoredRuleGrant(ProgressionRewardGrant grant) =>
      _local.insertRestoredRuleGrant(grant);

  @override
  Future<void> insertRestoredQuestGrant(ProgressionQuestRewardGrant grant) =>
      _local.insertRestoredQuestGrant(grant);

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
      if (last != null &&
          DateTime.now().difference(last) < _kStaleDuration) {
        return;
      }
    }

    pullAndHydrate(uid).ignore();
  }
}
