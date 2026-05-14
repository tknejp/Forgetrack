import 'dart:async';

import '../../../core/logging/app_log.dart';
import '../domain/models/ledger_event.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';
import 'firestore_progression_engine_gateway.dart';

/// Wraps the Isar-backed local repository and pushes every accepted
/// ledger event through to a Firestore [FirestoreProgressionEngineGateway].
///
/// Design contract:
/// - Local writes are authoritative. The engine sees exactly what the
///   local repo accepted; the cloud push is best-effort and never
///   blocks the local commit.
/// - Cloud failures are logged but swallowed — offline / outage must
///   not break a player's ability to claim a quest. Re-syncing happens
///   naturally next time [appendEvents] runs (any backlog of new
///   events the cloud is still missing has been re-evaluated locally
///   and gets re-attempted; the gateway is idempotent at the data
///   level via deterministic eventKeys).
/// - The wrapper holds a uid set externally via [bindUser]. Engine
///   construction in main.dart happens before AuthProvider has a uid,
///   so this is the only sane way to inject the cloud target.
///
/// This implements [ProgressionEngineLocalRepository] (not just
/// [ProgressionEngineRepository]) so devtools wipe paths can still
/// reach `wipeAll` — and that wipe is mirrored to Firestore.
class HybridProgressionEngineRepository
    implements ProgressionEngineLocalRepository {
  HybridProgressionEngineRepository({
    required ProgressionEngineLocalRepository local,
    required FirestoreProgressionEngineGateway cloud,
  })  : _local = local,
        _cloud = cloud;

  final ProgressionEngineLocalRepository _local;
  final FirestoreProgressionEngineGateway _cloud;

  String? _uid;

  /// Sets (or clears) the active user. Pass null on sign-out so cloud
  /// pushes are skipped until the next user signs in.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    AppLog.sync.info(
      'engine cloud user bound',
      payload: 'uid=${uid ?? "<null>"}',
    );
    _uid = uid;
  }

  String? get currentUid => _uid;

  @override
  Future<LedgerSnapshot> loadLedger() => _local.loadLedger();

  @override
  Future<LedgerSnapshot> appendEvents(List<LedgerEvent> events) async {
    final snapshot = await _local.appendEvents(events);

    final uid = _uid;
    if (uid != null && uid.isNotEmpty && events.isNotEmpty) {
      // Engine.evaluate / claim only generate events it knows aren't
      // already in the ledger (it consults the local snapshot before
      // emitting), so pushing the raw input list is safe — no extra
      // Isar load needed. If a duplicate did slip through, the
      // gateway's set() is idempotent at the data level (immutable
      // events with deterministic keys); the only cost would be one
      // wasted Firestore write.
      unawaited(_pushSafely(uid, events));
    }

    return snapshot;
  }

  @override
  Future<void> wipeAll() async {
    await _local.wipeAll();
    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      unawaited(_wipeSafely(uid));
    }
  }

  /// Pulls every ledger event from Firestore for [uid] and merges them
  /// into the local Isar store. Called on user bind so a fresh install
  /// or second device converges to the cloud's authoritative state.
  ///
  /// Idempotent — local appendEvents dedupes by eventKey, so events the
  /// device already has are dropped silently.
  Future<LedgerSnapshot> pullAndMerge(String uid) async {
    if (uid.isEmpty) return _local.loadLedger();

    LedgerSnapshot cloud;
    try {
      cloud = await _cloud.pullEvents(uid);
    } catch (error, stackTrace) {
      AppLog.sync.warn(
        'engine ledger pull failed',
        payload: 'uid=$uid error=$error',
      );
      AppLog.sync.debug('engine ledger pull stack', payload: stackTrace);
      return _local.loadLedger();
    }

    final all = <LedgerEvent>[
      ...cloud.objectiveCompletions,
      ...cloud.nodeCompletions,
      ...cloud.nodeClaims,
      ...cloud.nodeAnnouncements,
      ...cloud.rewardGrants,
    ];
    if (all.isEmpty) return _local.loadLedger();
    return _local.appendEvents(all);
  }

  Future<void> _pushSafely(String uid, List<LedgerEvent> events) async {
    try {
      await _cloud.pushEvents(uid, events);
    } catch (error, stackTrace) {
      AppLog.sync.warn(
        'engine ledger push failed',
        payload: 'uid=$uid count=${events.length} error=$error',
      );
      AppLog.sync.debug('engine ledger push stack', payload: stackTrace);
    }
  }

  Future<void> _wipeSafely(String uid) async {
    try {
      await _cloud.wipeAll(uid);
    } catch (error, stackTrace) {
      AppLog.sync.warn(
        'engine ledger wipe failed',
        payload: 'uid=$uid error=$error',
      );
      AppLog.sync.debug('engine ledger wipe stack', payload: stackTrace);
    }
  }
}
