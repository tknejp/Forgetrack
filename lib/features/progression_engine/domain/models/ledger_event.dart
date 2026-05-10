import 'package:flutter/foundation.dart';

/// One persisted record in the engine's append-only ledger. Sealed so
/// the repository, devtools dump, and future cloud-sync mapper get
/// exhaustive switch checking.
///
/// Every event has a deterministic [eventKey]: re-running the engine
/// with the same inputs produces no new events, just `SkippedEvent`s
/// in the resolution result.
@immutable
sealed class LedgerEvent {
  const LedgerEvent({required this.eventKey, required this.timestamp});

  final String eventKey;
  final DateTime timestamp;
}

/// One objective evaluated as completed for a given period (or
/// lifetime, for lifetime-scoped objectives).
///
/// Key shape: `objective|<objectiveId>|<periodKey?>|completed`. For
/// lifetime objectives `periodKey` is omitted; for daily/weekly it
/// embeds the period anchor.
class ObjectiveCompletionEvent extends LedgerEvent {
  const ObjectiveCompletionEvent({
    required super.eventKey,
    required super.timestamp,
    required this.objectiveId,
    required this.actualValue,
    this.periodKey,
  });

  final String objectiveId;
  final double actualValue;
  final String? periodKey;
}

/// One node entered the `completed` state for a given period.
///
/// Key shape: `node|<nodeId>|<periodKey?>|complete`.
class NodeCompletionEvent extends LedgerEvent {
  const NodeCompletionEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    this.periodKey,
  });

  final String nodeId;
  final String? periodKey;
}

/// Player-initiated claim on a manual-claim node (companion, etc.).
///
/// Key shape: `node|<nodeId>|<periodKey?>|claim`.
class NodeClaimEvent extends LedgerEvent {
  const NodeClaimEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    this.periodKey,
  });

  final String nodeId;
  final String? periodKey;
}

/// One concrete reward granted as a consequence of a node completion
/// or claim. The XP-scaling fields populate only for XP rewards; for
/// other reward kinds they are null.
///
/// Key shape: `reward|<nodeId>|<rewardOrdinal>|<periodKey?>|grant`.
class RewardGrantEvent extends LedgerEvent {
  const RewardGrantEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    required this.rewardOrdinal,
    required this.rewardKind,
    this.periodKey,
    this.xpAmount,
    this.cosmeticId,
    this.chapterId,
    this.companionId,
    this.titleId,
    this.emblemId,
    this.relicId,
    this.levelAtGrant,
    this.multiplierAtGrant,
  });

  final String nodeId;
  final int rewardOrdinal;
  final RewardGrantKind rewardKind;
  final String? periodKey;

  // Reward-kind-specific payload — exactly one is set per event,
  // matching [rewardKind].
  final int? xpAmount;
  final String? cosmeticId;
  final String? chapterId;
  final String? companionId;
  final String? titleId;
  final String? emblemId;
  final String? relicId;

  // XP-scaling fields, only populated for [RewardGrantKind.xp].
  final int? levelAtGrant;
  final double? multiplierAtGrant;
}

/// Discriminator on [RewardGrantEvent] so the same record table can
/// hold all reward grant kinds without one nullable field per type
/// in the read path.
enum RewardGrantKind {
  xp,
  cosmetic,
  chapterUnlock,
  companionAvailability,
  title,
  emblem,
  relic,
}
