import 'dart:async';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/firebase_error_classifier.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/result/result.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
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
  Future<LedgerSnapshot> appendEvents(List<JournalEvent> events) async {
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

  @override
  Future<void> clearEventsForNode(String nodeId) async {
    // Devtools-only revoke: delete the node's events from both the
    // local Isar store and the Firestore mirror. The cloud delete is
    // best-effort (errors are logged + swallowed via the same
    // classifier the wipe path uses) — the local clear is the
    // user-visible signal; the cloud mirror catches up on the next
    // successful sync. Without the cloud-side delete the next
    // pull-and-merge would replay the historical grant events and
    // undo the revoke (Trello #92 "auto-claim on refresh").
    await _local.clearEventsForNode(nodeId);
    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      unawaited(_clearNodeSafely(uid, nodeId));
    }
  }

  Future<void> _clearNodeSafely(String uid, String nodeId) async {
    try {
      await _cloud.clearEventsForNode(uid, nodeId);
    } catch (e, st) {
      _logSyncFailure(
        'engine ledger clearNode failed',
        uid,
        classifyFirebaseError(e, st, endpoint: 'engine.clearNode'),
      );
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

    final cloud = await pullEventsClassified(uid);
    switch (cloud) {
      case Failure(error: final e):
        _logSyncFailure('engine ledger pull failed', uid, e);
        return _local.loadLedger();
      case Success(value: final snapshot):
        final all = <JournalEvent>[
          ...snapshot.objectiveCompletions,
          ...snapshot.nodeCompletions,
          ...snapshot.nodeClaims,
          ...snapshot.nodeAnnouncements,
          ...snapshot.rewardGrants,
          ...snapshot.questOfferings,
        ];
        if (all.isEmpty) return _local.loadLedger();
        return _local.appendEvents(all);
    }
  }

  /// Result-typed pull. Exposed for tests + future consumers that
  /// want to pattern-match on error severity rather than collapse to
  /// the local snapshot.
  Future<Result<LedgerSnapshot, AppError>> pullEventsClassified(
    String uid,
  ) async {
    try {
      final snapshot = await _cloud.pullEvents(uid);
      return Success(snapshot);
    } catch (error, stackTrace) {
      return Failure(classifyFirebaseError(
        error,
        stackTrace,
        endpoint: 'engine.pullEvents',
      ));
    }
  }

  Future<void> _pushSafely(String uid, List<JournalEvent> events) async {
    final result = await _pushEventsClassified(uid, events);
    if (result case Failure(error: final e)) {
      _logSyncFailure(
        'engine ledger push failed',
        uid,
        e,
        extra: 'count=${events.length}',
      );
    }
  }

  Future<Result<void, AppError>> _pushEventsClassified(
    String uid,
    List<JournalEvent> events,
  ) async {
    try {
      await _cloud.pushEvents(uid, events);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(classifyFirebaseError(
        error,
        stackTrace,
        endpoint: 'engine.pushEvents',
      ));
    }
  }

  Future<void> _wipeSafely(String uid) async {
    final result = await _wipeClassified(uid);
    if (result case Failure(error: final e)) {
      _logSyncFailure('engine ledger wipe failed', uid, e);
    }
  }

  Future<Result<void, AppError>> _wipeClassified(String uid) async {
    try {
      await _cloud.wipeAll(uid);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(classifyFirebaseError(
        error,
        stackTrace,
        endpoint: 'engine.wipeAll',
      ));
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
