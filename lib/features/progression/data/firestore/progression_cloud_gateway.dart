import '../../domain/progression_models.dart';

/// Abstract interface for the Firestore cloud gateway.
///
/// Decouples [HybridProgressionRepository] from Firebase, enabling
/// pure-Dart unit tests without initializing Firebase.
abstract class ProgressionCloudGateway {
  Future<void> pushRuleClaimIfMissing(
    String uid,
    ProgressionRewardGrant grant,
  );

  Future<void> pushQuestClaimIfMissing(
    String uid,
    ProgressionQuestRewardGrant grant,
  );

  Future<void> pushAchievementUnlockIfMissing(
    String uid,
    ProgressionAchievementUnlockEvent unlock,
  );

  Future<({
    List<ProgressionRewardGrant> ruleGrants,
    List<ProgressionQuestRewardGrant> questGrants,
  })> pullClaims(String uid);

  Future<List<ProgressionAchievementUnlockEvent>> pullAchievementUnlocks(
    String uid,
  );
}
