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
