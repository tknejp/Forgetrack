import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/logging/app_log.dart';
import '../../../cosmetics/data/firestore_cosmetics_gateway.dart';
import '../../../progression_engine/data/firestore_progression_engine_gateway.dart';

/// Deletes the Firestore docs Forgetrack writes under a user's namespace.
///
/// Scope (V2 progression — V1 was removed in Phase 22, 2026-05-19):
/// - `users/{uid}/engineObjectiveCompletions/*`
/// - `users/{uid}/engineNodeCompletions/*`
/// - `users/{uid}/engineNodeClaims/*`
/// - `users/{uid}/engineNodeAnnouncements/*`
/// - `users/{uid}/engineRewardGrants/*`
/// - `users/{uid}/engineQuestOfferings/*`
/// - `users/{uid}/cosmeticEntitlements/*` (server-pushed grants)
/// - `users/{uid}/cosmeticUnlocks/*` (hybrid cosmetics cloud sync)
/// - `users/{uid}/cosmeticState/state` (hybrid cosmetics cloud sync)
/// - `users/{uid}/notifications/*`
///
/// Explicitly NOT touched (would mutate other users' state):
/// - `users/{uid}` (the social profile doc — referenced by friendships)
/// - `friend_requests`, `friendships`, `achievement_shares`, `handles`
///
/// Note on legacy V1 docs: pre-Phase-22 collections
/// (`progressionClaims`, `achievementUnlocks`, `progression/state`) are
/// no longer wiped — the V1 module that wrote them was deleted, and
/// any leftover docs orphan harmlessly per V2 plan §11.1 ("Social
/// Firestore data referencing old node ids is acceptable to break").
///
/// Idempotent: missing collections/docs are silently skipped. Deletes are
/// batched in groups of 500 (Firestore WriteBatch limit). Best-effort: if
/// one collection fails the others still run; per-collection errors are
/// logged and surfaced via the returned [PurgeReport].
class DevToolsUserDataPurgeService {
  DevToolsUserDataPurgeService({
    FirebaseFirestore? firestore,
    FirestoreProgressionEngineGateway? progressionGateway,
    FirestoreCosmeticsGateway? cosmeticsGateway,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _progressionGateway =
            progressionGateway ?? FirestoreProgressionEngineGateway(),
        _cosmeticsGateway =
            cosmeticsGateway ?? FirestoreCosmeticsGateway();

  final FirebaseFirestore _firestore;
  final FirestoreProgressionEngineGateway _progressionGateway;
  final FirestoreCosmeticsGateway _cosmeticsGateway;

  Future<UserDataPurgeReport> purgeForUid(String uid) async {
    AppLog.reset.info('firestore-purge: start uid=$uid');
    final stepErrors = <String, String>{};

    // 1. Progression claims + achievement unlocks + progression/state doc.
    try {
      await _progressionGateway.wipeAll(uid);
      AppLog.reset.success('firestore-purge: progression wiped');
    } catch (e, st) {
      stepErrors['progression'] = e.toString();
      AppLog.reset.error(
        'firestore-purge: progression wipe failed',
        payload: 'uid=$uid',
        err: e,
        stackTrace: st,
      );
    }

    // 2. Cosmetic entitlements sub-collection (server-pushed grants).
    final cosmeticDeleted = await _safeDeleteCollection(
      _userCollection(uid, 'cosmeticEntitlements'),
      label: 'cosmeticEntitlements',
      stepErrors: stepErrors,
    );

    // 3. Cosmetics hybrid cloud sync — `cosmeticUnlocks/*` +
    //    `cosmeticState/state`. Mirrors the local Isar `clearAll()`
    //    step in the factory-reset flow so a post-reset sign-in
    //    starts with a clean slate on both sides.
    var cosmeticsHybridWiped = false;
    try {
      await _cosmeticsGateway.wipeAll(uid);
      cosmeticsHybridWiped = true;
      AppLog.reset.success('firestore-purge: cosmetics hybrid wiped');
    } catch (e, st) {
      stepErrors['cosmeticsHybrid'] = e.toString();
      AppLog.reset.error(
        'firestore-purge: cosmetics hybrid wipe failed',
        payload: 'uid=$uid',
        err: e,
        stackTrace: st,
      );
    }

    // 4. Per-user notifications sub-collection.
    final notificationsDeleted = await _safeDeleteCollection(
      _userCollection(uid, 'notifications'),
      label: 'notifications',
      stepErrors: stepErrors,
    );

    AppLog.reset.success(
      'firestore-purge: done',
      payload:
          'uid=$uid cosmeticDocs=$cosmeticDeleted '
          'cosmeticsHybrid=${cosmeticsHybridWiped ? "✓" : "✗"} '
          'notificationDocs=$notificationsDeleted '
          'errors=${stepErrors.length}',
    );

    return UserDataPurgeReport(
      uid: uid,
      cosmeticEntitlementsDeleted: cosmeticDeleted,
      cosmeticsHybridWiped: cosmeticsHybridWiped,
      notificationsDeleted: notificationsDeleted,
      progressionWiped: !stepErrors.containsKey('progression'),
      stepErrors: stepErrors,
    );
  }

  CollectionReference<Map<String, dynamic>> _userCollection(
    String uid,
    String name,
  ) =>
      _firestore.collection('users').doc(uid).collection(name);

  Future<int> _safeDeleteCollection(
    CollectionReference<Map<String, dynamic>> collection, {
    required String label,
    required Map<String, String> stepErrors,
  }) async {
    try {
      return await _deleteCollectionInBatches(collection);
    } catch (e, st) {
      stepErrors[label] = e.toString();
      AppLog.reset.error(
        'firestore-purge: $label delete failed',
        err: e,
        stackTrace: st,
      );
      return 0;
    }
  }

  Future<int> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return 0;
    var batch = _firestore.batch();
    var pending = 0;
    var total = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      pending++;
      total++;
      if (pending == 500) {
        await batch.commit();
        batch = _firestore.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();
    return total;
  }
}

class UserDataPurgeReport {
  const UserDataPurgeReport({
    required this.uid,
    required this.cosmeticEntitlementsDeleted,
    required this.cosmeticsHybridWiped,
    required this.notificationsDeleted,
    required this.progressionWiped,
    required this.stepErrors,
  });

  final String uid;
  final int cosmeticEntitlementsDeleted;
  final bool cosmeticsHybridWiped;
  final int notificationsDeleted;
  final bool progressionWiped;
  final Map<String, String> stepErrors;

  bool get hasErrors => stepErrors.isNotEmpty;

  String get note {
    final pieces = <String>[
      if (progressionWiped) 'progression✓' else 'progression✗',
      'cosmetic=$cosmeticEntitlementsDeleted',
      if (cosmeticsHybridWiped) 'cosmeticsHybrid✓' else 'cosmeticsHybrid✗',
      'notif=$notificationsDeleted',
    ];
    if (hasErrors) {
      pieces.add('errors=${stepErrors.length}');
    }
    return pieces.join(' ');
  }
}
