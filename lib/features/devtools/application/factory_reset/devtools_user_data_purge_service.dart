import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/logging/app_log.dart';
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
/// - `users/{uid}/cosmeticEntitlements/*`
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
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _progressionGateway =
            progressionGateway ?? FirestoreProgressionEngineGateway();

  final FirebaseFirestore _firestore;
  final FirestoreProgressionEngineGateway _progressionGateway;

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

    // 2. Cosmetic entitlements sub-collection.
    final cosmeticDeleted = await _safeDeleteCollection(
      _userCollection(uid, 'cosmeticEntitlements'),
      label: 'cosmeticEntitlements',
      stepErrors: stepErrors,
    );

    // 3. Per-user notifications sub-collection.
    final notificationsDeleted = await _safeDeleteCollection(
      _userCollection(uid, 'notifications'),
      label: 'notifications',
      stepErrors: stepErrors,
    );

    AppLog.reset.success(
      'firestore-purge: done',
      payload:
          'uid=$uid cosmeticDocs=$cosmeticDeleted notificationDocs=$notificationsDeleted '
          'errors=${stepErrors.length}',
    );

    return UserDataPurgeReport(
      uid: uid,
      cosmeticEntitlementsDeleted: cosmeticDeleted,
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
    required this.notificationsDeleted,
    required this.progressionWiped,
    required this.stepErrors,
  });

  final String uid;
  final int cosmeticEntitlementsDeleted;
  final int notificationsDeleted;
  final bool progressionWiped;
  final Map<String, String> stepErrors;

  bool get hasErrors => stepErrors.isNotEmpty;

  String get note {
    final pieces = <String>[
      if (progressionWiped) 'progression✓' else 'progression✗',
      'cosmetic=$cosmeticEntitlementsDeleted',
      'notif=$notificationsDeleted',
    ];
    if (hasErrors) {
      pieces.add('errors=${stepErrors.length}');
    }
    return pieces.join(' ');
  }
}
