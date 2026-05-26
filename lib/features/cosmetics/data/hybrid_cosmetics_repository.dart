import 'dart:async';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/firebase_error_classifier.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/result/result.dart';
import '../domain/cosmetic_models.dart';
import 'cosmetics_repository.dart';
import 'firestore_cosmetics_gateway.dart';

/// Wraps the Isar-backed local cosmetics repository and pushes every
/// accepted mutation to a Firestore [FirestoreCosmeticsGateway].
///
/// Mirrors the V2 progression engine's hybrid pattern
/// ([HybridProgressionEngineRepository]):
///   * **Local writes are authoritative.** The service / provider sees
///     exactly what the Isar repo accepted; cloud pushes are
///     fire-and-forget and never block the local commit.
///   * **Cloud failures are logged but swallowed.** Offline or outage
///     must not break a player's ability to unlock or equip. Re-syncing
///     happens naturally on the next mutation (idempotent set() with
///     deterministic doc ids) and on the next `pullAndMerge`.
///   * **Single bound user.** [bindUser] is called from main.dart on
///     auth changes; cloud pushes are gated on the bound uid matching
///     the call uid so sign-out mid-flight does not push another user's
///     data.
///   * **First-load pull-and-merge.** The first [loadForUser] call per
///     uid triggers a pull from Firestore + merge into the local store
///     so a fresh install / second device picks up the player's
///     existing inventory. Subsequent loads short-circuit to local.
class HybridCosmeticsRepository implements CosmeticsRepository {
  HybridCosmeticsRepository({
    required CosmeticsRepository local,
    required FirestoreCosmeticsGateway cloud,
  })  : _local = local,
        _cloud = cloud;

  final CosmeticsRepository _local;
  final FirestoreCosmeticsGateway _cloud;

  String? _uid;

  /// Uids that have already been pull-and-merged in the lifetime of
  /// this wrapper. The local Isar store is the source of truth after
  /// the first merge; we don't re-pull on every load.
  final Set<String> _mergedUids = <String>{};

  /// Sets (or clears) the active user. Pass null on sign-out so cloud
  /// pushes are skipped until the next user signs in. Clears the
  /// "already merged" set so a re-sign-in re-runs the pull-and-merge.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    AppLog.sync.info(
      'cosmetics cloud user bound',
      payload: 'uid=${uid ?? "<null>"}',
    );
    _uid = uid;
    if (uid == null || uid.isEmpty) {
      _mergedUids.clear();
    }
  }

  String? get currentUid => _uid;

  // ── Reads ───────────────────────────────────────────────────────────

  @override
  Future<UserCosmeticsState> loadForUser(String uid) async {
    if (uid.isEmpty) return _local.loadForUser(uid);

    // First load per uid (sign-in / cold start): pull cloud and merge
    // into local before returning. Subsequent loads just hit local —
    // mutations are pushed through fire-and-forget as they happen, so
    // local stays the source of truth in steady state.
    if (!_mergedUids.contains(uid)) {
      _mergedUids.add(uid);
      try {
        return await _pullAndMerge(uid);
      } catch (error, stackTrace) {
        // Pull failed (offline, permission denied, malformed cloud
        // doc): fall through to local. _mergedUids stays populated so
        // we don't thrash on every load; the next mutating op will
        // re-push local state up to cloud, and the next bindUser()
        // cycle re-enables the pull.
        _logSyncFailure(
          'cosmetics pull-and-merge failed',
          uid,
          classifyFirebaseError(
            error,
            stackTrace,
            endpoint: 'cosmetics.pullAndMerge',
          ),
        );
      }
    }
    return _local.loadForUser(uid);
  }

  // ── Writes ──────────────────────────────────────────────────────────

  @override
  Future<void> saveState(UserCosmeticsState state) async {
    await _local.saveState(state);
    if (_shouldPush(state.uid)) {
      unawaited(_pushFullStateSafely(state.uid, state));
    }
  }

  @override
  Future<void> unlockCosmetic({
    required String uid,
    required String cosmeticId,
    required String sourceType,
    String? sourceId,
  }) async {
    await _local.unlockCosmetic(
      uid: uid,
      cosmeticId: cosmeticId,
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (_shouldPush(uid)) {
      unawaited(_pushAfterUnlockSafely(uid, cosmeticId));
    }
  }

  @override
  Future<void> equipCosmetic({
    required String uid,
    required CosmeticType type,
    required String cosmeticId,
  }) async {
    await _local.equipCosmetic(
      uid: uid,
      type: type,
      cosmeticId: cosmeticId,
    );
    if (_shouldPush(uid)) {
      unawaited(_pushStateSafely(uid));
    }
  }

  @override
  Future<void> unequipCosmetic({
    required String uid,
    required CosmeticType type,
  }) async {
    await _local.unequipCosmetic(uid: uid, type: type);
    if (_shouldPush(uid)) {
      unawaited(_pushStateSafely(uid));
    }
  }

  @override
  Future<void> revokeCosmetic({
    required String uid,
    required String cosmeticId,
  }) async {
    await _local.revokeCosmetic(uid: uid, cosmeticId: cosmeticId);
    if (_shouldPush(uid)) {
      unawaited(_pushAfterRevokeSafely(uid, cosmeticId));
    }
  }

  @override
  Future<int> clearAllUnlocks(String uid) async {
    final removed = await _local.clearAllUnlocks(uid);
    if (_shouldPush(uid)) {
      unawaited(_pushAfterClearAllSafely(uid));
    }
    return removed;
  }

  @override
  Future<void> selectRace({
    required String uid,
    required String? raceId,
  }) async {
    await _local.selectRace(uid: uid, raceId: raceId);
    if (_shouldPush(uid)) {
      unawaited(_pushStateSafely(uid));
    }
  }

  // ── Pull-and-merge ──────────────────────────────────────────────────

  /// Reads cloud cosmetics state and merges with local. Strategy:
  ///   * **Unlocks:** union by cosmeticId. For collisions, keep the
  ///     entry with the *earlier* `unlockedAt` so the audit timestamp
  ///     reflects the first time the player ever owned the cosmetic
  ///     across all devices. Local always wins on `sourceType` /
  ///     `sourceId` because it's the device that actually granted it.
  ///   * **Loadout + selectedRaceId + updatedAt:** whichever side has
  ///     the later `updatedAt` wins as a whole bundle. Cloud
  ///     `updatedAt == null` (no state doc) → local wins by default.
  ///
  /// Always re-pushes the merged state up to cloud so the cloud
  /// converges to the union too.
  Future<UserCosmeticsState> _pullAndMerge(String uid) async {
    final cloud = await _cloud.pull(uid);
    final local = await _local.loadForUser(uid);

    if (cloud == null) {
      // Cloud is empty for this user — push local up so the next
      // device picks it up. First-time-user case where the local
      // repo seeded defaults: those defaults are now visible on
      // every device.
      unawaited(_pushFullStateSafely(uid, local));
      return local;
    }

    final merged = _mergeStates(uid: uid, local: local, cloud: cloud);
    if (!_statesEqualOnWire(local, merged)) {
      await _local.saveState(merged);
    }
    unawaited(_pushFullStateSafely(uid, merged));
    AppLog.sync.info(
      'cosmetics merged',
      payload:
          'uid=$uid localUnlocks=${local.unlocked.length} cloudUnlocks=${cloud.unlocks.length} merged=${merged.unlocked.length}',
    );
    return merged;
  }

  UserCosmeticsState _mergeStates({
    required String uid,
    required UserCosmeticsState local,
    required CosmeticsCloudSnapshot cloud,
  }) {
    final unlocks = <String, UnlockedCosmetic>{...local.unlocked};
    for (final cloudUnlock in cloud.unlocks) {
      final existing = unlocks[cloudUnlock.cosmeticId];
      if (existing == null) {
        unlocks[cloudUnlock.cosmeticId] = cloudUnlock;
        continue;
      }
      // Both sides have it — prefer the earlier unlockedAt as the
      // "first acquired" audit timestamp. Local sourceType/sourceId
      // wins (it's authoritative for the device that has the unlock).
      if (cloudUnlock.unlockedAt.isBefore(existing.unlockedAt)) {
        unlocks[cloudUnlock.cosmeticId] = UnlockedCosmetic(
          cosmeticId: existing.cosmeticId,
          unlockedAt: cloudUnlock.unlockedAt,
          sourceType: existing.sourceType,
          sourceId: existing.sourceId,
        );
      }
    }

    final cloudUpdatedAt =
        cloud.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final cloudWins = cloud.loadout != null &&
        cloudUpdatedAt.isAfter(local.updatedAt);

    return UserCosmeticsState(
      uid: uid,
      unlocked: unlocks,
      equipped: cloudWins ? cloud.loadout! : local.equipped,
      updatedAt: cloudWins ? cloudUpdatedAt : local.updatedAt,
      selectedRaceId: cloudWins
          ? cloud.selectedRaceId
          : local.selectedRaceId,
    );
  }

  /// Quick equality test on the wire-shaped bits — used to skip a
  /// redundant `saveState` when the merge produced an identical
  /// snapshot to what's already in Isar.
  bool _statesEqualOnWire(UserCosmeticsState a, UserCosmeticsState b) {
    if (a.unlocked.length != b.unlocked.length) return false;
    for (final id in a.unlocked.keys) {
      if (!b.unlocked.containsKey(id)) return false;
    }
    return a.equipped.frameId == b.equipped.frameId &&
        a.equipped.relicId == b.equipped.relicId &&
        a.equipped.backgroundId == b.equipped.backgroundId &&
        a.equipped.emblemId == b.equipped.emblemId &&
        a.equipped.companionId == b.equipped.companionId &&
        a.equipped.titleFlairId == b.equipped.titleFlairId &&
        a.equipped.mapEffectId == b.equipped.mapEffectId &&
        a.equipped.skinId == b.equipped.skinId &&
        a.equipped.bannerId == b.equipped.bannerId &&
        a.selectedRaceId == b.selectedRaceId &&
        a.updatedAt == b.updatedAt;
  }

  // ── Push helpers ────────────────────────────────────────────────────

  bool _shouldPush(String uid) {
    if (uid.isEmpty) return false;
    final bound = _uid;
    return bound != null && bound == uid;
  }

  Future<void> _pushAfterUnlockSafely(String uid, String cosmeticId) async {
    final result = await _classified<void>(
      endpoint: 'cosmetics.pushUnlock',
      action: () async {
        final state = await _local.loadForUser(uid);
        final unlock = state.unlocked[cosmeticId];
        if (unlock != null) {
          await _cloud.pushUnlock(uid, unlock);
        }
        await _cloud.pushState(
          uid,
          loadout: state.equipped,
          selectedRaceId: state.selectedRaceId,
          updatedAt: state.updatedAt,
        );
      },
    );
    if (result case Failure(error: final e)) {
      _logSyncFailure(
        'cosmetics push unlock failed',
        uid,
        e,
        extra: 'id=$cosmeticId',
      );
    }
  }

  Future<void> _pushAfterRevokeSafely(String uid, String cosmeticId) async {
    final result = await _classified<void>(
      endpoint: 'cosmetics.removeUnlock',
      action: () async {
        await _cloud.removeUnlock(uid, cosmeticId);
        final state = await _local.loadForUser(uid);
        await _cloud.pushState(
          uid,
          loadout: state.equipped,
          selectedRaceId: state.selectedRaceId,
          updatedAt: state.updatedAt,
        );
      },
    );
    if (result case Failure(error: final e)) {
      _logSyncFailure(
        'cosmetics push revoke failed',
        uid,
        e,
        extra: 'id=$cosmeticId',
      );
    }
  }

  Future<void> _pushAfterClearAllSafely(String uid) async {
    final result = await _classified<void>(
      endpoint: 'cosmetics.wipeUnlocks',
      action: () async {
        await _cloud.wipeUnlocks(uid);
        final state = await _local.loadForUser(uid);
        await _cloud.pushState(
          uid,
          loadout: state.equipped,
          selectedRaceId: state.selectedRaceId,
          updatedAt: state.updatedAt,
        );
      },
    );
    if (result case Failure(error: final e)) {
      _logSyncFailure('cosmetics push clear-all failed', uid, e);
    }
  }

  Future<void> _pushStateSafely(String uid) async {
    final result = await _classified<void>(
      endpoint: 'cosmetics.pushState',
      action: () async {
        final state = await _local.loadForUser(uid);
        await _cloud.pushState(
          uid,
          loadout: state.equipped,
          selectedRaceId: state.selectedRaceId,
          updatedAt: state.updatedAt,
        );
      },
    );
    if (result case Failure(error: final e)) {
      _logSyncFailure('cosmetics push state failed', uid, e);
    }
  }

  Future<void> _pushFullStateSafely(
    String uid,
    UserCosmeticsState state,
  ) async {
    final result = await _classified<void>(
      endpoint: 'cosmetics.pushFullState',
      action: () async {
        await _cloud.pushState(
          uid,
          loadout: state.equipped,
          selectedRaceId: state.selectedRaceId,
          updatedAt: state.updatedAt,
        );
        for (final unlock in state.unlocked.values) {
          await _cloud.pushUnlock(uid, unlock);
        }
      },
    );
    if (result case Failure(error: final e)) {
      _logSyncFailure(
        'cosmetics push full state failed',
        uid,
        e,
        extra: 'unlocks=${state.unlocked.length}',
      );
    }
  }

  /// Devtools / factory-reset surface. Wipes the cloud-side state and
  /// unlocks entirely. The hybrid wrapper does NOT call this from any
  /// of the `CosmeticsRepository` methods — `clearAllUnlocks` uses the
  /// gentler `wipeUnlocks` because it preserves the state doc so
  /// reload doesn't re-seed defaults. Provide this as an explicit
  /// hook for the `FactoryResetService`.
  Future<void> wipeAllCloud(String uid) async {
    final result = await _classified<void>(
      endpoint: 'cosmetics.wipeAll',
      action: () => _cloud.wipeAll(uid),
    );
    if (result case Failure(error: final e)) {
      _logSyncFailure('cosmetics wipe-all failed', uid, e);
    }
  }

  Future<Result<T, AppError>> _classified<T>({
    required String endpoint,
    required Future<T> Function() action,
  }) async {
    try {
      return Success<T, AppError>(await action());
    } catch (error, stackTrace) {
      return Failure<T, AppError>(
        classifyFirebaseError(
          error,
          stackTrace,
          endpoint: endpoint,
        ),
      );
    }
  }

  void _logSyncFailure(
    String summary,
    String uid,
    AppError error, {
    String? extra,
  }) {
    final payload = [
      'uid=$uid',
      if (extra != null) extra,
      'error=${error.label}',
      'cause=${error.originalError}',
    ].join(' ');
    if (error.isTransient) {
      AppLog.sync.warn(summary, payload: payload);
    } else {
      AppLog.sync.error(summary, payload: payload);
    }
    final st = error.stackTrace;
    if (st != null) {
      AppLog.sync.debug('$summary stack', payload: st);
    }
  }
}
