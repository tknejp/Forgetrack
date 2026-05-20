import 'package:meta/meta.dart';

/// One persisted record in the engine's append-only ledger. Sealed so
/// the repository, devtools dump, and future cloud-sync mapper get
/// exhaustive switch checking.
///
/// Every event has a deterministic [eventKey]: re-running the engine
/// with the same inputs produces no new events, just `SkippedEvent`s
/// in the resolution result.
@immutable
sealed class JournalEvent {
  const JournalEvent({required this.eventKey, required this.timestamp});

  final String eventKey;
  final DateTime timestamp;
}

/// One objective evaluated as completed for a given period (or
/// lifetime, for lifetime-scoped objectives).
///
/// Key shape: `objective|<objectiveId>|<periodKey?>|completed`. For
/// lifetime objectives `periodKey` is omitted; for daily/weekly it
/// embeds the period anchor.
class ObjectiveCompletionEvent extends JournalEvent {
  const ObjectiveCompletionEvent({
    required super.eventKey,
    required super.timestamp,
    required this.objectiveId,
    required this.actualValue,
    this.periodKey,
  });

  final String objectiveId; // lint-ignore: untyped-id — JournalEvent fields are storage-boundary raw strings
  final double actualValue;
  final String? periodKey;
}

/// One node entered the `completed` state for a given period.
///
/// Key shape: `node|<nodeId>|<periodKey?>|complete`.
class NodeCompletionEvent extends JournalEvent {
  const NodeCompletionEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    this.periodKey,
  });

  final String nodeId; // lint-ignore: untyped-id — JournalEvent fields are storage-boundary raw strings
  final String? periodKey;
}

/// First time a manual-claim node was surfaced to the player as
/// available. Idempotent — written once per (node, period) so the
/// adapter can emit a celebration for the *newly available* node
/// exactly once, not on every subsequent evaluation that re-confirms
/// the same availability.
///
/// Key shape: `node|<nodeId>|<periodKey?>|announced`. The matching
/// `NodeAvailability` shows up in
/// `ProgressionResolutionResult.newlyAvailableNodes` on the run that
/// writes this event; subsequent runs only put the node in
/// `availableNodes` (full snapshot) until it's claimed.
class NodeAnnouncedEvent extends JournalEvent {
  const NodeAnnouncedEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    this.periodKey,
  });

  final String nodeId; // lint-ignore: untyped-id — JournalEvent fields are storage-boundary raw strings
  final String? periodKey;
}

/// Per-day record that a daily-section slot picked this node on
/// [dayKey]. Idempotent — written once per (node, dayKey) so the
/// resolver can read recent offerings to enforce an anti-repeat
/// cooldown and pin today's pick across UI rebuilds.
///
/// Key shape: `offered|<nodeId>|<dayKey>`. [dayKey] is always a
/// non-null `yyyy-MM-dd` string; the daily-section pool runs per
/// calendar day, so the periodKey concept from completion/claim
/// events doesn't apply here.
class QuestOfferedEvent extends JournalEvent {
  const QuestOfferedEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    required this.dayKey,
  });

  final String nodeId; // lint-ignore: untyped-id — JournalEvent fields are storage-boundary raw strings
  final String dayKey;
}

/// Player-initiated claim on a manual-claim node (companion, etc.).
///
/// Key shape: `node|<nodeId>|<periodKey?>|claim`.
class NodeClaimEvent extends JournalEvent {
  const NodeClaimEvent({
    required super.eventKey,
    required super.timestamp,
    required this.nodeId,
    this.periodKey,
  });

  final String nodeId; // lint-ignore: untyped-id — JournalEvent fields are storage-boundary raw strings
  final String? periodKey;
}

/// One concrete reward granted as a consequence of a node completion
/// or claim. The XP-scaling fields populate only for XP rewards; for
/// other reward kinds they are null.
///
/// Key shape: `reward|<nodeId>|<rewardOrdinal>|<periodKey?>|grant`.
class RewardGrantEvent extends JournalEvent {
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
    this.companionBuffBonusXp,
    this.emblemBuffBonusXp,
  });

  final String nodeId; // lint-ignore: untyped-id — JournalEvent fields are storage-boundary raw strings
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

  /// Companion-buff bonus XP included inside [xpAmount]. Recorded
  /// separately so the daily-softcap accountant can read prior
  /// buff-contribution from the ledger without re-deriving it from
  /// the multiplier. Null on pre-buff events (older ledgers) and on
  /// non-XP grants.
  final int? companionBuffBonusXp;

  /// Emblem-buff bonus XP included inside [xpAmount]. Mirrors
  /// [companionBuffBonusXp] but sourced from equipped emblems' buffs
  /// (additively summed with the companion buff percent at grant
  /// time). Null on pre-emblem-buff events and on non-XP grants.
  final int? emblemBuffBonusXp;
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
