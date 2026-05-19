import 'package:isar/isar.dart';

import 'package:forgetrack/domain/journal/journal_event.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';
import 'local/progression_engine_database.dart';
import 'local/progression_engine_local_models.dart';

/// Isar-backed implementation of [ProgressionEngineRepository].
///
/// Append is idempotent at the eventKey level — Isar's unique
/// indexes (replace=false) drop conflicting rows silently. The
/// repository wraps each append batch in one write transaction so
/// partial failures roll back together.
class IsarProgressionEngineRepository
    implements ProgressionEngineLocalRepository {
  IsarProgressionEngineRepository(this._database);

  final ProgressionEngineDatabase _database;

  Isar get _isar => _database.isar;

  @override
  Future<LedgerSnapshot> loadLedger() async {
    final objectives =
        await _isar.engineObjectiveCompletionRecords.where().findAll();
    final nodeCompletions =
        await _isar.engineNodeCompletionRecords.where().findAll();
    final nodeClaims = await _isar.engineNodeClaimRecords.where().findAll();
    final nodeAnnouncements =
        await _isar.engineNodeAnnouncementRecords.where().findAll();
    final rewardGrants =
        await _isar.engineRewardGrantRecords.where().findAll();
    final questOfferings =
        await _isar.engineQuestOfferingRecords.where().findAll();

    return LedgerSnapshot(
      objectiveCompletions: [
        for (final r in objectives) _toObjectiveCompletionEvent(r),
      ],
      nodeCompletions: [
        for (final r in nodeCompletions) _toNodeCompletionEvent(r),
      ],
      nodeClaims: [for (final r in nodeClaims) _toNodeClaimEvent(r)],
      nodeAnnouncements: [
        for (final r in nodeAnnouncements) _toNodeAnnouncedEvent(r),
      ],
      rewardGrants: [for (final r in rewardGrants) _toRewardGrantEvent(r)],
      questOfferings: [
        for (final r in questOfferings) _toQuestOfferedEvent(r),
      ],
    );
  }

  @override
  Future<LedgerSnapshot> appendEvents(List<JournalEvent> events) async {
    if (events.isEmpty) return loadLedger();

    final objectiveRows = <EngineObjectiveCompletionRecord>[];
    final nodeCompletionRows = <EngineNodeCompletionRecord>[];
    final nodeClaimRows = <EngineNodeClaimRecord>[];
    final nodeAnnouncementRows = <EngineNodeAnnouncementRecord>[];
    final rewardRows = <EngineRewardGrantRecord>[];
    final questOfferingRows = <EngineQuestOfferingRecord>[];

    for (final e in events) {
      switch (e) {
        case ObjectiveCompletionEvent():
          objectiveRows.add(_fromObjectiveCompletion(e));
        case NodeCompletionEvent():
          nodeCompletionRows.add(_fromNodeCompletion(e));
        case NodeClaimEvent():
          nodeClaimRows.add(_fromNodeClaim(e));
        case NodeAnnouncedEvent():
          nodeAnnouncementRows.add(_fromNodeAnnounced(e));
        case RewardGrantEvent():
          rewardRows.add(_fromRewardGrant(e));
        case QuestOfferedEvent():
          questOfferingRows.add(_fromQuestOffered(e));
      }
    }

    await _isar.writeTxn(() async {
      // putAllByEventKey + replace:false → existing rows with the
      // same key are not overwritten. New rows insert; duplicates
      // silently drop. Matches the contract the in-memory repo
      // provides.
      if (objectiveRows.isNotEmpty) {
        await _isar.engineObjectiveCompletionRecords
            .putAllByEventKey(objectiveRows);
      }
      if (nodeCompletionRows.isNotEmpty) {
        await _isar.engineNodeCompletionRecords
            .putAllByEventKey(nodeCompletionRows);
      }
      if (nodeClaimRows.isNotEmpty) {
        await _isar.engineNodeClaimRecords.putAllByEventKey(nodeClaimRows);
      }
      if (nodeAnnouncementRows.isNotEmpty) {
        await _isar.engineNodeAnnouncementRecords
            .putAllByEventKey(nodeAnnouncementRows);
      }
      if (rewardRows.isNotEmpty) {
        await _isar.engineRewardGrantRecords.putAllByEventKey(rewardRows);
      }
      if (questOfferingRows.isNotEmpty) {
        await _isar.engineQuestOfferingRecords
            .putAllByEventKey(questOfferingRows);
      }
    });

    return loadLedger();
  }

  @override
  Future<void> wipeAll() async {
    await _isar.writeTxn(() async {
      await _isar.engineObjectiveCompletionRecords.clear();
      await _isar.engineNodeCompletionRecords.clear();
      await _isar.engineNodeClaimRecords.clear();
      await _isar.engineNodeAnnouncementRecords.clear();
      await _isar.engineRewardGrantRecords.clear();
      await _isar.engineQuestOfferingRecords.clear();
      await _isar.engineActiveSelectionRecords.clear();
    });
  }

  @override
  Future<void> clearEventsForNode(String nodeId) async {
    await _isar.writeTxn(() async {
      await _isar.engineNodeCompletionRecords
          .filter()
          .nodeIdEqualTo(nodeId)
          .deleteAll();
      await _isar.engineNodeClaimRecords
          .filter()
          .nodeIdEqualTo(nodeId)
          .deleteAll();
      await _isar.engineNodeAnnouncementRecords
          .filter()
          .nodeIdEqualTo(nodeId)
          .deleteAll();
      await _isar.engineRewardGrantRecords
          .filter()
          .nodeIdEqualTo(nodeId)
          .deleteAll();
      await _isar.engineQuestOfferingRecords
          .filter()
          .nodeIdEqualTo(nodeId)
          .deleteAll();
    });
  }

  // ── Domain → Isar ────────────────────────────────────────────────

  EngineObjectiveCompletionRecord _fromObjectiveCompletion(
    ObjectiveCompletionEvent e,
  ) =>
      EngineObjectiveCompletionRecord()
        ..eventKey = e.eventKey
        ..objectiveId = e.objectiveId
        ..periodKey = e.periodKey
        ..actualValue = e.actualValue
        ..timestamp = e.timestamp;

  EngineNodeCompletionRecord _fromNodeCompletion(NodeCompletionEvent e) =>
      EngineNodeCompletionRecord()
        ..eventKey = e.eventKey
        ..nodeId = e.nodeId
        ..periodKey = e.periodKey
        ..timestamp = e.timestamp;

  EngineNodeClaimRecord _fromNodeClaim(NodeClaimEvent e) =>
      EngineNodeClaimRecord()
        ..eventKey = e.eventKey
        ..nodeId = e.nodeId
        ..periodKey = e.periodKey
        ..timestamp = e.timestamp;

  EngineNodeAnnouncementRecord _fromNodeAnnounced(NodeAnnouncedEvent e) =>
      EngineNodeAnnouncementRecord()
        ..eventKey = e.eventKey
        ..nodeId = e.nodeId
        ..periodKey = e.periodKey
        ..timestamp = e.timestamp;

  EngineRewardGrantRecord _fromRewardGrant(RewardGrantEvent e) =>
      EngineRewardGrantRecord()
        ..eventKey = e.eventKey
        ..nodeId = e.nodeId
        ..rewardOrdinal = e.rewardOrdinal
        ..rewardKindName = e.rewardKind.name
        ..periodKey = e.periodKey
        ..timestamp = e.timestamp
        ..xpAmount = e.xpAmount
        ..cosmeticId = e.cosmeticId
        ..chapterId = e.chapterId
        ..companionId = e.companionId
        ..titleId = e.titleId
        ..emblemId = e.emblemId
        ..relicId = e.relicId
        ..levelAtGrant = e.levelAtGrant
        ..multiplierAtGrant = e.multiplierAtGrant
        ..companionBuffBonusXp = e.companionBuffBonusXp;

  EngineQuestOfferingRecord _fromQuestOffered(QuestOfferedEvent e) =>
      EngineQuestOfferingRecord()
        ..eventKey = e.eventKey
        ..nodeId = e.nodeId
        ..dayKey = e.dayKey
        ..timestamp = e.timestamp;

  // ── Isar → Domain ────────────────────────────────────────────────

  ObjectiveCompletionEvent _toObjectiveCompletionEvent(
    EngineObjectiveCompletionRecord r,
  ) =>
      ObjectiveCompletionEvent(
        eventKey: r.eventKey,
        timestamp: r.timestamp,
        objectiveId: r.objectiveId,
        actualValue: r.actualValue,
        periodKey: r.periodKey,
      );

  NodeCompletionEvent _toNodeCompletionEvent(
    EngineNodeCompletionRecord r,
  ) =>
      NodeCompletionEvent(
        eventKey: r.eventKey,
        timestamp: r.timestamp,
        nodeId: r.nodeId,
        periodKey: r.periodKey,
      );

  NodeClaimEvent _toNodeClaimEvent(EngineNodeClaimRecord r) =>
      NodeClaimEvent(
        eventKey: r.eventKey,
        timestamp: r.timestamp,
        nodeId: r.nodeId,
        periodKey: r.periodKey,
      );

  NodeAnnouncedEvent _toNodeAnnouncedEvent(EngineNodeAnnouncementRecord r) =>
      NodeAnnouncedEvent(
        eventKey: r.eventKey,
        timestamp: r.timestamp,
        nodeId: r.nodeId,
        periodKey: r.periodKey,
      );

  QuestOfferedEvent _toQuestOfferedEvent(EngineQuestOfferingRecord r) =>
      QuestOfferedEvent(
        eventKey: r.eventKey,
        timestamp: r.timestamp,
        nodeId: r.nodeId,
        dayKey: r.dayKey,
      );

  RewardGrantEvent _toRewardGrantEvent(EngineRewardGrantRecord r) {
    final kind = RewardGrantKind.values.firstWhere(
      (k) => k.name == r.rewardKindName,
      orElse: () => RewardGrantKind.xp,
    );
    return RewardGrantEvent(
      eventKey: r.eventKey,
      timestamp: r.timestamp,
      nodeId: r.nodeId,
      rewardOrdinal: r.rewardOrdinal,
      rewardKind: kind,
      periodKey: r.periodKey,
      xpAmount: r.xpAmount,
      cosmeticId: r.cosmeticId,
      chapterId: r.chapterId,
      companionId: r.companionId,
      titleId: r.titleId,
      emblemId: r.emblemId,
      relicId: r.relicId,
      levelAtGrant: r.levelAtGrant,
      multiplierAtGrant: r.multiplierAtGrant,
      companionBuffBonusXp: r.companionBuffBonusXp,
    );
  }
}
