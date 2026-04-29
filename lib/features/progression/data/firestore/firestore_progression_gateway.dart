import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/progression_level_policy.dart';
import '../../domain/progression_models.dart';
import 'progression_cloud_gateway.dart';
import 'progression_firestore_mapper.dart';

/// Handles all Firestore I/O for the progression ledger.
///
/// This is an internal component used by [HybridProgressionRepository] (Phase 4b).
/// Not wired into the app yet — only the mapper and this class exist in Phase 4a.
///
/// All writes use create-if-not-exists transactions: if the document already
/// exists the write is silently skipped, making every operation idempotent.
class FirestoreProgressionGateway implements ProgressionCloudGateway {
  FirestoreProgressionGateway({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Collection references
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _claimsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('progressionClaims');

  CollectionReference<Map<String, dynamic>> _unlocksRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('achievementUnlocks');

  // ---------------------------------------------------------------------------
  // Push (local → Firestore)
  // ---------------------------------------------------------------------------

  /// Pushes a claimed rule grant to Firestore if the document does not exist.
  /// Skips records that fail [ProgressionFirestoreMapper.isRuleGrantUploadable].
  @override
  Future<void> pushRuleClaimIfMissing(
    String uid,
    ProgressionRewardGrant grant,
  ) async {
    if (!ProgressionFirestoreMapper.isRuleGrantUploadable(grant)) return;
    final ref = _claimsRef(uid).doc(grant.rewardKey);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      tx.set(ref, {
        ...ProgressionFirestoreMapper.ruleGrantToMap(grant),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Pushes a claimed quest grant to Firestore if the document does not exist.
  /// Skips records that fail [ProgressionFirestoreMapper.isQuestGrantUploadable].
  @override
  Future<void> pushQuestClaimIfMissing(
    String uid,
    ProgressionQuestRewardGrant grant,
  ) async {
    if (!ProgressionFirestoreMapper.isQuestGrantUploadable(grant)) return;
    final ref = _claimsRef(uid).doc(grant.rewardKey);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      tx.set(ref, {
        ...ProgressionFirestoreMapper.questGrantToMap(grant),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Pushes an achievement unlock to Firestore if the document does not exist.
  @override
  Future<void> pushAchievementUnlockIfMissing(
    String uid,
    ProgressionAchievementUnlockEvent unlock,
  ) async {
    final ref = _unlocksRef(uid).doc(unlock.achievementId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      tx.set(ref, {
        ...ProgressionFirestoreMapper.achievementUnlockToMap(unlock),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Pull (Firestore → domain)
  // ---------------------------------------------------------------------------

  /// Fetches all claimed grants for [uid] and deserializes them.
  /// Documents with unknown or missing `type` fields are silently skipped.
  @override
  Future<({
    List<ProgressionRewardGrant> ruleGrants,
    List<ProgressionQuestRewardGrant> questGrants,
  })> pullClaims(String uid) async {
    final snapshot = await _claimsRef(uid).get();
    final ruleGrants = <ProgressionRewardGrant>[];
    final questGrants = <ProgressionQuestRewardGrant>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String?;
      if (type == 'rule') {
        final grant = ProgressionFirestoreMapper.ruleGrantFromMap(data);
        if (grant != null) ruleGrants.add(grant);
      } else if (type == 'quest') {
        final grant = ProgressionFirestoreMapper.questGrantFromMap(data);
        if (grant != null) questGrants.add(grant);
      }
    }
    return (ruleGrants: ruleGrants, questGrants: questGrants);
  }

  /// Fetches all achievement unlocks for [uid] and deserializes them.
  @override
  Future<List<ProgressionAchievementUnlockEvent>> pullAchievementUnlocks(
    String uid,
  ) async {
    final snapshot = await _unlocksRef(uid).get();
    return snapshot.docs
        .map((doc) =>
            ProgressionFirestoreMapper.achievementUnlockFromMap(doc.data()))
        .whereType<ProgressionAchievementUnlockEvent>()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Migration skeleton (Phase 4d)
  // ---------------------------------------------------------------------------

  /// Uploads all eligible claimed grants and achievement unlocks from the local
  /// ledger snapshot to Firestore. Each write is create-if-not-exists and safe
  /// to retry. Writes are batched in groups of 500 (Firestore WriteBatch limit).
  ///
  /// Phase 4d stub — not wired until [HybridProgressionRepository] calls it
  /// from the migration flow on first login.
  @override
  Future<void> migrateLocalLedger({
    required String uid,
    required List<ProgressionRewardGrant> ruleGrants,
    required List<ProgressionQuestRewardGrant> questGrants,
    required List<ProgressionAchievementUnlockEvent> achievementUnlocks,
  }) async {
    final uploadableRule =
        ruleGrants.where(ProgressionFirestoreMapper.isRuleGrantUploadable);
    final uploadableQuest =
        questGrants.where(ProgressionFirestoreMapper.isQuestGrantUploadable);

    // Pre-fetch existing document IDs to avoid transaction overhead per record.
    final existingSnap = await _claimsRef(uid).get();
    final existingKeys = existingSnap.docs.map((d) => d.id).toSet();

    final existingUnlockSnap = await _unlocksRef(uid).get();
    final existingUnlockKeys =
        existingUnlockSnap.docs.map((d) => d.id).toSet();

    Future<void> writeBatch<T>(
      Iterable<T> items,
      String Function(T) idOf,
      Map<String, dynamic> Function(T) toMap,
      CollectionReference<Map<String, dynamic>> collection,
      Set<String> existing,
    ) async {
      final newItems = items.where((item) => !existing.contains(idOf(item)));
      var batch = _firestore.batch();
      var count = 0;
      for (final item in newItems) {
        batch.set(collection.doc(idOf(item)), {
          ...toMap(item),
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
        if (count == 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }

    await writeBatch<ProgressionRewardGrant>(
      uploadableRule,
      (g) => g.rewardKey,
      ProgressionFirestoreMapper.ruleGrantToMap,
      _claimsRef(uid),
      existingKeys,
    );
    await writeBatch<ProgressionQuestRewardGrant>(
      uploadableQuest,
      (g) => g.rewardKey,
      ProgressionFirestoreMapper.questGrantToMap,
      _claimsRef(uid),
      existingKeys,
    );
    await writeBatch<ProgressionAchievementUnlockEvent>(
      achievementUnlocks,
      (u) => u.achievementId,
      ProgressionFirestoreMapper.achievementUnlockToMap,
      _unlocksRef(uid),
      existingUnlockKeys,
    );

    // Update the derived summary document after migration completes
    final ledgerSnapshot = ProgressionLedgerSnapshot(
      evaluations: const [],
      rewardGrants: ruleGrants,
      questRewardGrants: questGrants,
      activeQuestIds: const {},
      achievementUnlocks: achievementUnlocks,
    );
    updateProgressionSummary(uid: uid, ledger: ledgerSnapshot).ignore();
  }

  // ---------------------------------------------------------------------------
  // Summary cache (Phase 4e)
  // ---------------------------------------------------------------------------

  /// Updates the derived progression state summary document at
  /// users/{uid}/progression/state. Computes derived fields from the
  /// current ledger snapshot: totalXp, level, claimCount, achievementCount.
  /// This is a best-effort cache — failures do not break local behavior.
  @override
  Future<void> updateProgressionSummary({
    required String uid,
    required ProgressionLedgerSnapshot ledger,
  }) async {
    const levelPolicy = ProgressionLevelPolicy();

    final totalXp = ledger.rewardGrants.fold<int>(
          0,
          (total, grant) => total + grant.effectiveXpGranted,
        ) +
        ledger.questRewardGrants.fold<int>(
          0,
          (total, grant) => total + grant.effectiveXpGranted,
        );
    final level = levelPolicy.levelForXp(totalXp);
    final claimCount = ledger.rewardGrants.where((g) => g.isClaimed).length +
        ledger.questRewardGrants.where((g) => g.isClaimed).length;
    final achievementCount = ledger.achievementUnlocks.length;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('progression')
        .doc('state')
        .set(
          {
            'totalXp': totalXp,
            'level': level,
            'claimCount': claimCount,
            'achievementCount': achievementCount,
            'lastSyncedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  // ---------------------------------------------------------------------------
  // Devtools wipe
  // ---------------------------------------------------------------------------

  @override
  Future<void> wipeAllRemoteData(String uid) async {
    Future<void> deleteAll(
      CollectionReference<Map<String, dynamic>> collection,
    ) async {
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) return;
      var batch = _firestore.batch();
      var count = 0;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count == 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }

    await deleteAll(_claimsRef(uid));
    await deleteAll(_unlocksRef(uid));
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('progression')
        .doc('state')
        .delete();
  }
}
