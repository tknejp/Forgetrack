import 'package:isar/isar.dart';

part 'progression_engine_local_models.g.dart';

/// Objective completion event — recorded when an objective evaluator
/// transitions an objective from incomplete to complete in a given
/// period. `eventKey` shape: `objective|<objectiveId>|<periodKey?>|completed`.
@Collection()
class EngineObjectiveCompletionRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String eventKey;

  @Index()
  late String objectiveId;

  String? periodKey;
  late double actualValue;

  @Index()
  late DateTime timestamp;
}

/// Node completion event — written when a node enters the `completed`
/// state. `eventKey` shape: `node|<nodeId>|<periodKey?>|complete`.
@Collection()
class EngineNodeCompletionRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String eventKey;

  @Index()
  late String nodeId;

  String? periodKey;

  @Index()
  late DateTime timestamp;
}

/// First-time availability announcement marker for a manual-claim
/// node. Written once per (nodeId, periodKey) the first time the
/// engine resolves the node into the `available` state. The
/// celebration adapter reads `result.newlyAvailableNodes` (which
/// the engine populates only when the matching announce event is
/// fresh) to fire a "company unlocked" overlay exactly once, even
/// across app restarts.
///
/// `eventKey` shape: `node|<nodeId>|<periodKey?>|announced`.
@Collection()
class EngineNodeAnnouncementRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String eventKey;

  @Index()
  late String nodeId;

  String? periodKey;

  @Index()
  late DateTime timestamp;
}

/// Player-initiated claim on a manual-claim node. `eventKey` shape:
/// `node|<nodeId>|<periodKey?>|claim`.
@Collection()
class EngineNodeClaimRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String eventKey;

  @Index()
  late String nodeId;

  String? periodKey;

  @Index()
  late DateTime timestamp;
}

/// Reward grant event — one per reward bound to a node. The
/// `rewardKindName` discriminator keeps every reward type in one
/// collection; only the matching payload field is populated.
///
/// `eventKey` shape: `reward|<nodeId>|<rewardOrdinal>|<periodKey?>|grant`.
@Collection()
class EngineRewardGrantRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String eventKey;

  @Index()
  late String nodeId;

  late int rewardOrdinal;

  /// String form of [RewardGrantKind] (xp, cosmetic, chapterUnlock,
  /// companionAvailability, title, emblem, relic).
  late String rewardKindName;

  String? periodKey;

  @Index()
  late DateTime timestamp;

  // Reward-kind-specific payload — exactly one is set per row,
  // matching `rewardKindName`.
  int? xpAmount;
  String? cosmeticId;
  String? chapterId;
  String? companionId;
  String? titleId;
  String? emblemId;
  String? relicId;

  // XP-scaling capture, only populated for kind == xp.
  int? levelAtGrant;
  double? multiplierAtGrant;

  /// Companion-buff bonus portion of [xpAmount], populated only for
  /// kind == xp. Read by the engine's daily-softcap accountant.
  int? companionBuffBonusXp;
}

/// Per-day record that a daily-section slot picked this node on
/// [dayKey]. Used by `DailySectionResolver` to read recent offerings
/// for anti-repeat cooldown and to pin today's pick across UI
/// rebuilds (so the resolver doesn't re-roll within the same day).
///
/// `eventKey` shape: `offered|<nodeId>|<dayKey>`.
@Collection()
class EngineQuestOfferingRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String eventKey;

  @Index()
  late String nodeId;

  @Index()
  late String dayKey;

  @Index()
  late DateTime timestamp;
}

/// Stochastic per-period selection record — combo pool rotation,
/// tiered daily picks. Persisted so a re-roll on app restart does
/// not change the player's daily set.
///
/// `selectionKey` shape: `comboPool|<poolId>|<periodAnchor>` or
/// `dailyTier|<groupId>|<periodAnchor>`.
@Collection()
class EngineActiveSelectionRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String selectionKey;

  late String selectedValue;

  @Index()
  late DateTime assignedAt;

  DateTime? expiresAt;
}
