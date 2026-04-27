import 'progression_models.dart';

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
