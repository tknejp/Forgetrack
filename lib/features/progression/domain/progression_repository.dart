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
  });

  Future<ProgressionLedgerSnapshot> claimAllRewards({
    required DateTime claimedAt,
  });

  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  });

  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
  });

  Future<ProgressionLedgerSnapshot> claimAllQuestRewards({
    required DateTime claimedAt,
  });

  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  });
}
