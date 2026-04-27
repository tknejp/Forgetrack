import 'progression_models.dart';

/// Storage-agnostic interface for the progression ledger.
///
/// **Current source of truth**: local Isar (`ProgressionRepositoryImpl`).
/// Records are append-only and keyed by deterministic strings so any storage
/// backend can enforce idempotency.
///
/// **Future source of truth (Phase 4)**: Firestore.
/// Only claimed rewards (`ProgressionRewardGrant`, `ProgressionQuestRewardGrant`)
/// and achievement unlocks (`ProgressionAchievementUnlockEvent`) will be synced
/// to the cloud — these are the events that must survive reinstall.
/// Raw evaluations, active quest assignments, and raw health/nutrition data are
/// derived locally and must never leave the device.
abstract class ProgressionRepository {
  Future<ProgressionLedgerSnapshot> loadLedger();

  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  });

  Future<ProgressionLedgerSnapshot> claimReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  });

  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  });

  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  });

  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  });

  Future<ProgressionLedgerSnapshot> persistAchievementUnlocks({
    required List<ProgressionAchievementUnlockEvent> unlocks,
  });
}
