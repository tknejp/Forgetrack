import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/logging/app_log.dart';
import '../domain/cosmetic_models.dart';

/// Cloud-side gateway for the cosmetics feature.
///
/// Mirrors the V2 progression engine pattern
/// ([FirestoreProgressionEngineGateway]) — pure data adapter, no
/// catch-and-classify. Errors propagate; the [HybridCosmeticsRepository]
/// wrapper is responsible for classifying + swallowing so a Firestore
/// outage never blocks a local unlock or equip.
///
/// Firestore layout under `users/{uid}`:
///   * `cosmeticUnlocks/{cosmeticId}` — one doc per owned cosmetic with
///     audit fields (`unlockedAt`, `sourceType`, `sourceId`). Document
///     id IS the cosmetic id so `set()` is idempotent — re-pushing the
///     same unlock collapses to the same doc.
///   * `cosmeticState/state` — single doc holding the equipped
///     [Loadout] slots + `selectedRaceId` + `updatedAt`. Single doc per
///     user (the path uses a subcollection with a fixed `state` doc id
///     for symmetry with the rest of the user namespace and to keep
///     the top-level `users/{uid}` doc owned by the social profile
///     projection).
///
/// Sibling subcollections under `users/{uid}`:
///   * `cosmeticEntitlements` — server-pushed grants (promotional,
///     compensation) consumed by `FirestoreCosmeticEntitlementsSource`.
///     This gateway does NOT write to that collection — entitlements
///     flow one-way from the backend into the local repo via the
///     provider's `_applyEntitlements` step.
class FirestoreCosmeticsGateway {
  FirestoreCosmeticsGateway({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _unlocksCollection = 'cosmeticUnlocks';
  static const _stateCollection = 'cosmeticState';
  static const _stateDocId = 'state';

  // Firestore caps a WriteBatch at 500 operations.
  static const _maxBatchOps = 500;

  CollectionReference<Map<String, dynamic>> _userCol(
    String uid,
    String name,
  ) =>
      _firestore.collection('users').doc(uid).collection(name);

  DocumentReference<Map<String, dynamic>> _stateRef(String uid) =>
      _userCol(uid, _stateCollection).doc(_stateDocId);

  // ── Push ────────────────────────────────────────────────────────────

  /// Writes a single unlock doc. Idempotent — doc id is the cosmetic id,
  /// so re-pushing the same unlock is a same-data overwrite.
  Future<void> pushUnlock(String uid, UnlockedCosmetic unlock) async {
    if (uid.isEmpty) return;
    final docId = _sanitizeDocId(unlock.cosmeticId);
    if (docId.isEmpty) return;
    await _userCol(uid, _unlocksCollection).doc(docId).set(
          _unlockToMap(unlock),
        );
  }

  /// Removes a single unlock doc. No-op if the doc does not exist.
  Future<void> removeUnlock(String uid, String cosmeticId) async {
    if (uid.isEmpty || cosmeticId.isEmpty) return;
    final docId = _sanitizeDocId(cosmeticId);
    if (docId.isEmpty) return;
    await _userCol(uid, _unlocksCollection).doc(docId).delete();
  }

  /// Writes the per-user state doc (equipped loadout + selectedRaceId +
  /// updatedAt). Uses `set(merge: true)` so unrelated fields that future
  /// versions of the app might add do not get wiped by an older client.
  Future<void> pushState(
    String uid, {
    required Loadout loadout,
    required String? selectedRaceId,
    required DateTime updatedAt,
  }) async {
    if (uid.isEmpty) return;
    await _stateRef(uid).set(
      _stateToMap(
        loadout: loadout,
        selectedRaceId: selectedRaceId,
        updatedAt: updatedAt,
      ),
      SetOptions(merge: true),
    );
  }

  // ── Pull ────────────────────────────────────────────────────────────

  /// Reads every cosmetic-related doc for [uid] and assembles a
  /// snapshot. Returns null when no state doc AND no unlocks exist —
  /// the caller treats null as "first-time user, seed defaults
  /// locally". Returns a snapshot with empty unlock map when only the
  /// state doc exists (player on a different device cleared all
  /// unlocks).
  Future<CosmeticsCloudSnapshot?> pull(String uid) async {
    if (uid.isEmpty) return null;

    final results = await Future.wait([
      _stateRef(uid).get(),
      _userCol(uid, _unlocksCollection).get(),
    ]);
    final stateSnap =
        results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final unlocksSnap =
        results[1] as QuerySnapshot<Map<String, dynamic>>;

    final hasState = stateSnap.exists;
    final unlocks = <UnlockedCosmetic>[];
    for (final doc in unlocksSnap.docs) {
      final parsed = _unlockFromMap(doc.id, doc.data());
      if (parsed != null) unlocks.add(parsed);
    }

    if (!hasState && unlocks.isEmpty) {
      AppLog.sync.info(
        'cosmetics pull empty',
        payload: 'uid=$uid',
      );
      return null;
    }

    final stateData = hasState
        ? (stateSnap.data() ?? const <String, dynamic>{})
        : const <String, dynamic>{};
    final loadout = _loadoutFromMap(stateData);
    final raceId = _readNullableString(stateData['selectedRaceId']);
    final updatedAt = _readDate(stateData['updatedAt']);

    AppLog.sync.info(
      'cosmetics pull',
      payload: 'uid=$uid unlocks=${unlocks.length} hasState=$hasState',
    );

    return CosmeticsCloudSnapshot(
      loadout: hasState ? loadout : null,
      selectedRaceId: raceId,
      updatedAt: updatedAt,
      unlocks: unlocks,
    );
  }

  // ── Wipe (devtools / factory reset) ─────────────────────────────────

  /// Deletes the entire cosmetic state for [uid] — state doc + every
  /// unlock doc. Mirrors the devtools wipe path on the local Isar
  /// repo so factory reset is consistent across local + cloud.
  Future<void> wipeAll(String uid) async {
    if (uid.isEmpty) return;
    await Future.wait([
      _stateRef(uid).delete().catchError((_) {}),
      _wipeCollection(_userCol(uid, _unlocksCollection)),
    ]);
    AppLog.sync.info('cosmetics wipe', payload: 'uid=$uid');
  }

  /// Deletes every unlock doc but leaves the state doc untouched. Used
  /// when devtools clears unlocks but the player keeps their selected
  /// race / equipped state row (so a subsequent `loadForUser` doesn't
  /// re-seed defaults).
  Future<void> wipeUnlocks(String uid) async {
    if (uid.isEmpty) return;
    await _wipeCollection(_userCol(uid, _unlocksCollection));
    AppLog.sync.info('cosmetics wipe unlocks', payload: 'uid=$uid');
  }

  Future<void> _wipeCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final snap = await col.get();
    if (snap.docs.isEmpty) return;

    var batch = _firestore.batch();
    var opsInBatch = 0;
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      opsInBatch++;
      if (opsInBatch >= _maxBatchOps) {
        await batch.commit();
        batch = _firestore.batch();
        opsInBatch = 0;
      }
    }
    if (opsInBatch > 0) await batch.commit();
  }

  // ── Domain → Map ────────────────────────────────────────────────────

  Map<String, dynamic> _unlockToMap(UnlockedCosmetic unlock) {
    return {
      'cosmeticId': unlock.cosmeticId,
      'unlockedAt': Timestamp.fromDate(unlock.unlockedAt),
      'sourceType': unlock.sourceType,
      'sourceId': unlock.sourceId,
    };
  }

  Map<String, dynamic> _stateToMap({
    required Loadout loadout,
    required String? selectedRaceId,
    required DateTime updatedAt,
  }) {
    return {
      'frameId': loadout.frameId,
      'relicId': loadout.relicId,
      'backgroundId': loadout.backgroundId,
      'emblemId': loadout.emblemId,
      'companionId': loadout.companionId,
      'titleFlairId': loadout.titleFlairId,
      'mapEffectId': loadout.mapEffectId,
      'skinId': loadout.skinId,
      'bannerId': loadout.bannerId,
      'selectedRaceId': selectedRaceId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ── Map → Domain ────────────────────────────────────────────────────

  UnlockedCosmetic? _unlockFromMap(String docId, Map<String, dynamic> data) {
    final cosmeticId = _readString(data['cosmeticId']) ?? docId;
    final unlockedAt = _readDate(data['unlockedAt']);
    if (cosmeticId.isEmpty || unlockedAt == null) return null;
    return UnlockedCosmetic(
      cosmeticId: cosmeticId,
      unlockedAt: unlockedAt,
      sourceType: _readNullableString(data['sourceType']),
      sourceId: _readNullableString(data['sourceId']),
    );
  }

  Loadout _loadoutFromMap(Map<String, dynamic> data) {
    return Loadout(
      frameId: _readNullableString(data['frameId']),
      relicId: _readNullableString(data['relicId']),
      backgroundId: _readNullableString(data['backgroundId']),
      emblemId: _readNullableString(data['emblemId']),
      companionId: _readNullableString(data['companionId']),
      titleFlairId: _readNullableString(data['titleFlairId']),
      mapEffectId: _readNullableString(data['mapEffectId']),
      skinId: _readNullableString(data['skinId']),
      bannerId: _readNullableString(data['bannerId']),
    );
  }

  // Firestore document IDs cannot contain `/` and must be ≤1500 bytes.
  // Cosmetic ids are catalog-controlled (kebab-case, no slashes) but
  // be defensive in case a future id picks up a path separator.
  static String _sanitizeDocId(String key) =>
      key.replaceAll('/', '_').replaceAll('.', '_');

  static String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _readNullableString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Wire snapshot returned by [FirestoreCosmeticsGateway.pull]. The hybrid
/// wrapper merges this with the local state — see
/// [HybridCosmeticsRepository.pullAndMerge].
class CosmeticsCloudSnapshot {
  const CosmeticsCloudSnapshot({
    required this.loadout,
    required this.selectedRaceId,
    required this.updatedAt,
    required this.unlocks,
  });

  /// Null when the cloud state doc didn't exist (only unlocks were
  /// pushed by an older client). Callers fall back to the local
  /// loadout in that case.
  final Loadout? loadout;
  final String? selectedRaceId;

  /// Null when the cloud state doc didn't exist OR didn't carry an
  /// `updatedAt` field. Treated as `epoch` when comparing against
  /// the local `updatedAt`.
  final DateTime? updatedAt;

  final List<UnlockedCosmetic> unlocks;
}
