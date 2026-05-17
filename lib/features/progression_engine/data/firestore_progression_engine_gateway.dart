import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/logging/app_log.dart';
import '../domain/models/ledger_event.dart';
import '../domain/repository/ledger_snapshot.dart';

/// Cloud-side gateway for the V2 progression engine ledger.
///
/// Maps the sealed [JournalEvent] hierarchy to Firestore documents under
/// `users/{uid}/engine{EventType}s/{eventKey}`. Writes use plain `set()`
/// because [JournalEvent.eventKey] is deterministic and event payloads
/// are immutable — re-writing the same event with the same data is a
/// safe no-op at the data level (Firestore still bills the write,
/// which is why the hybrid repository pushes only the events the local
/// repo actually accepted).
///
/// All methods are best-effort from the engine's perspective; the
/// hybrid repository is responsible for catching errors so a Firestore
/// outage never blocks a local claim.
class FirestoreProgressionEngineGateway {
  FirestoreProgressionEngineGateway({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _objectiveCollection = 'engineObjectiveCompletions';
  static const _nodeCompletionCollection = 'engineNodeCompletions';
  static const _nodeClaimCollection = 'engineNodeClaims';
  static const _nodeAnnouncementCollection = 'engineNodeAnnouncements';
  static const _rewardGrantCollection = 'engineRewardGrants';
  static const _questOfferingCollection = 'engineQuestOfferings';

  // Firestore caps a WriteBatch at 500 operations.
  static const _maxBatchOps = 500;

  CollectionReference<Map<String, dynamic>> _userCol(
    String uid,
    String name,
  ) =>
      _firestore.collection('users').doc(uid).collection(name);

  // ── Push ────────────────────────────────────────────────────────────

  /// Pushes [events] to Firestore. Splits across multiple WriteBatches
  /// when over the 500-op limit. Errors propagate; the caller decides
  /// whether to retry or swallow.
  Future<void> pushEvents(String uid, List<JournalEvent> events) async {
    if (uid.isEmpty || events.isEmpty) return;

    var batch = _firestore.batch();
    var opsInBatch = 0;
    Future<void> flush() async {
      if (opsInBatch == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      opsInBatch = 0;
    }

    for (final event in events) {
      final ref = _refFor(uid, event);
      if (ref == null) continue;
      batch.set(ref, _toMap(event));
      opsInBatch++;
      if (opsInBatch >= _maxBatchOps) {
        await flush();
      }
    }
    await flush();

    AppLog.sync.info(
      'engine ledger push',
      payload: 'uid=$uid count=${events.length}',
    );
  }

  // ── Pull ────────────────────────────────────────────────────────────

  /// Reads every engine event from Firestore for [uid] and returns
  /// them as a [LedgerSnapshot]. Used on session bind to converge a
  /// fresh install / second device with the cloud state.
  Future<LedgerSnapshot> pullEvents(String uid) async {
    if (uid.isEmpty) return const LedgerSnapshot();

    final results = await Future.wait([
      _userCol(uid, _objectiveCollection).get(),
      _userCol(uid, _nodeCompletionCollection).get(),
      _userCol(uid, _nodeClaimCollection).get(),
      _userCol(uid, _nodeAnnouncementCollection).get(),
      _userCol(uid, _rewardGrantCollection).get(),
      _userCol(uid, _questOfferingCollection).get(),
    ]);

    final objectives = <ObjectiveCompletionEvent>[];
    final nodeCompletions = <NodeCompletionEvent>[];
    final nodeClaims = <NodeClaimEvent>[];
    final nodeAnnouncements = <NodeAnnouncedEvent>[];
    final rewardGrants = <RewardGrantEvent>[];
    final questOfferings = <QuestOfferedEvent>[];

    for (final doc in results[0].docs) {
      final e = _objectiveFromMap(doc.data());
      if (e != null) objectives.add(e);
    }
    for (final doc in results[1].docs) {
      final e = _nodeCompletionFromMap(doc.data());
      if (e != null) nodeCompletions.add(e);
    }
    for (final doc in results[2].docs) {
      final e = _nodeClaimFromMap(doc.data());
      if (e != null) nodeClaims.add(e);
    }
    for (final doc in results[3].docs) {
      final e = _nodeAnnouncedFromMap(doc.data());
      if (e != null) nodeAnnouncements.add(e);
    }
    for (final doc in results[4].docs) {
      final e = _rewardGrantFromMap(doc.data());
      if (e != null) rewardGrants.add(e);
    }
    for (final doc in results[5].docs) {
      final e = _questOfferedFromMap(doc.data());
      if (e != null) questOfferings.add(e);
    }

    AppLog.sync.info(
      'engine ledger pull',
      payload:
          'uid=$uid objectives=${objectives.length} nodeCompletions=${nodeCompletions.length} '
          'nodeClaims=${nodeClaims.length} announcements=${nodeAnnouncements.length} '
          'rewardGrants=${rewardGrants.length} questOfferings=${questOfferings.length}',
    );

    return LedgerSnapshot(
      objectiveCompletions: objectives,
      nodeCompletions: nodeCompletions,
      nodeClaims: nodeClaims,
      nodeAnnouncements: nodeAnnouncements,
      rewardGrants: rewardGrants,
      questOfferings: questOfferings,
    );
  }

  // ── Wipe (devtools / factory reset) ─────────────────────────────────

  Future<void> wipeAll(String uid) async {
    if (uid.isEmpty) return;
    await Future.wait([
      _wipeCollection(_userCol(uid, _objectiveCollection)),
      _wipeCollection(_userCol(uid, _nodeCompletionCollection)),
      _wipeCollection(_userCol(uid, _nodeClaimCollection)),
      _wipeCollection(_userCol(uid, _nodeAnnouncementCollection)),
      _wipeCollection(_userCol(uid, _rewardGrantCollection)),
      _wipeCollection(_userCol(uid, _questOfferingCollection)),
    ]);
    AppLog.sync.info('engine ledger wipe', payload: 'uid=$uid');
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

  // ── Routing ─────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>>? _refFor(
    String uid,
    JournalEvent event,
  ) {
    final docId = _sanitizeDocId(event.eventKey);
    if (docId.isEmpty) return null;
    return switch (event) {
      ObjectiveCompletionEvent() =>
        _userCol(uid, _objectiveCollection).doc(docId),
      NodeCompletionEvent() =>
        _userCol(uid, _nodeCompletionCollection).doc(docId),
      NodeClaimEvent() => _userCol(uid, _nodeClaimCollection).doc(docId),
      NodeAnnouncedEvent() =>
        _userCol(uid, _nodeAnnouncementCollection).doc(docId),
      RewardGrantEvent() => _userCol(uid, _rewardGrantCollection).doc(docId),
      QuestOfferedEvent() =>
        _userCol(uid, _questOfferingCollection).doc(docId),
    };
  }

  // Firestore document IDs cannot contain `/` and must be ≤1500 bytes.
  // Engine eventKeys use `|` as separator so `/` is unexpected, but a
  // node/objective/period id from the catalog could conceivably hold
  // one — be defensive.
  static String _sanitizeDocId(String key) =>
      key.replaceAll('/', '_').replaceAll('.', '_');

  // ── Domain → Map ────────────────────────────────────────────────────

  Map<String, dynamic> _toMap(JournalEvent event) {
    final base = {
      'eventKey': event.eventKey,
      'timestamp': Timestamp.fromDate(event.timestamp),
    };
    return switch (event) {
      ObjectiveCompletionEvent() => {
          ...base,
          'type': 'objectiveCompletion',
          'objectiveId': event.objectiveId,
          'actualValue': event.actualValue,
          'periodKey': event.periodKey,
        },
      NodeCompletionEvent() => {
          ...base,
          'type': 'nodeCompletion',
          'nodeId': event.nodeId,
          'periodKey': event.periodKey,
        },
      NodeClaimEvent() => {
          ...base,
          'type': 'nodeClaim',
          'nodeId': event.nodeId,
          'periodKey': event.periodKey,
        },
      NodeAnnouncedEvent() => {
          ...base,
          'type': 'nodeAnnounced',
          'nodeId': event.nodeId,
          'periodKey': event.periodKey,
        },
      RewardGrantEvent() => {
          ...base,
          'type': 'rewardGrant',
          'nodeId': event.nodeId,
          'rewardOrdinal': event.rewardOrdinal,
          'rewardKind': event.rewardKind.name,
          'periodKey': event.periodKey,
          'xpAmount': event.xpAmount,
          'cosmeticId': event.cosmeticId,
          'chapterId': event.chapterId,
          'companionId': event.companionId,
          'titleId': event.titleId,
          'emblemId': event.emblemId,
          'relicId': event.relicId,
          'levelAtGrant': event.levelAtGrant,
          'multiplierAtGrant': event.multiplierAtGrant,
        },
      QuestOfferedEvent() => {
          ...base,
          'type': 'questOffered',
          'nodeId': event.nodeId,
          'dayKey': event.dayKey,
        },
    };
  }

  // ── Map → Domain ────────────────────────────────────────────────────

  ObjectiveCompletionEvent? _objectiveFromMap(Map<String, dynamic> data) {
    final eventKey = _readString(data['eventKey']);
    final timestamp = _readDate(data['timestamp']);
    final objectiveId = _readString(data['objectiveId']);
    final actualValue = _readDouble(data['actualValue']);
    if (eventKey == null ||
        timestamp == null ||
        objectiveId == null ||
        actualValue == null) {
      return null;
    }
    return ObjectiveCompletionEvent(
      eventKey: eventKey,
      timestamp: timestamp,
      objectiveId: objectiveId,
      actualValue: actualValue,
      periodKey: _readNullableString(data['periodKey']),
    );
  }

  NodeCompletionEvent? _nodeCompletionFromMap(Map<String, dynamic> data) {
    final eventKey = _readString(data['eventKey']);
    final timestamp = _readDate(data['timestamp']);
    final nodeId = _readString(data['nodeId']);
    if (eventKey == null || timestamp == null || nodeId == null) return null;
    return NodeCompletionEvent(
      eventKey: eventKey,
      timestamp: timestamp,
      nodeId: nodeId,
      periodKey: _readNullableString(data['periodKey']),
    );
  }

  NodeClaimEvent? _nodeClaimFromMap(Map<String, dynamic> data) {
    final eventKey = _readString(data['eventKey']);
    final timestamp = _readDate(data['timestamp']);
    final nodeId = _readString(data['nodeId']);
    if (eventKey == null || timestamp == null || nodeId == null) return null;
    return NodeClaimEvent(
      eventKey: eventKey,
      timestamp: timestamp,
      nodeId: nodeId,
      periodKey: _readNullableString(data['periodKey']),
    );
  }

  NodeAnnouncedEvent? _nodeAnnouncedFromMap(Map<String, dynamic> data) {
    final eventKey = _readString(data['eventKey']);
    final timestamp = _readDate(data['timestamp']);
    final nodeId = _readString(data['nodeId']);
    if (eventKey == null || timestamp == null || nodeId == null) return null;
    return NodeAnnouncedEvent(
      eventKey: eventKey,
      timestamp: timestamp,
      nodeId: nodeId,
      periodKey: _readNullableString(data['periodKey']),
    );
  }

  QuestOfferedEvent? _questOfferedFromMap(Map<String, dynamic> data) {
    final eventKey = _readString(data['eventKey']);
    final timestamp = _readDate(data['timestamp']);
    final nodeId = _readString(data['nodeId']);
    final dayKey = _readString(data['dayKey']);
    if (eventKey == null ||
        timestamp == null ||
        nodeId == null ||
        dayKey == null) {
      return null;
    }
    return QuestOfferedEvent(
      eventKey: eventKey,
      timestamp: timestamp,
      nodeId: nodeId,
      dayKey: dayKey,
    );
  }

  RewardGrantEvent? _rewardGrantFromMap(Map<String, dynamic> data) {
    final eventKey = _readString(data['eventKey']);
    final timestamp = _readDate(data['timestamp']);
    final nodeId = _readString(data['nodeId']);
    final rewardOrdinal = _readInt(data['rewardOrdinal']);
    final rewardKindName = _readString(data['rewardKind']);
    if (eventKey == null ||
        timestamp == null ||
        nodeId == null ||
        rewardOrdinal == null ||
        rewardKindName == null) {
      return null;
    }
    final rewardKind = RewardGrantKind.values.firstWhere(
      (k) => k.name == rewardKindName,
      orElse: () => RewardGrantKind.xp,
    );
    return RewardGrantEvent(
      eventKey: eventKey,
      timestamp: timestamp,
      nodeId: nodeId,
      rewardOrdinal: rewardOrdinal,
      rewardKind: rewardKind,
      periodKey: _readNullableString(data['periodKey']),
      xpAmount: _readNullableInt(data['xpAmount']),
      cosmeticId: _readNullableString(data['cosmeticId']),
      chapterId: _readNullableString(data['chapterId']),
      companionId: _readNullableString(data['companionId']),
      titleId: _readNullableString(data['titleId']),
      emblemId: _readNullableString(data['emblemId']),
      relicId: _readNullableString(data['relicId']),
      levelAtGrant: _readNullableInt(data['levelAtGrant']),
      multiplierAtGrant: _readNullableDouble(data['multiplierAtGrant']),
    );
  }

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

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static int? _readNullableInt(Object? value) => _readInt(value);

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  static double? _readNullableDouble(Object? value) => _readDouble(value);

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
