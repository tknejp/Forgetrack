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

  /// Uploads all eligible claimed grants and achievement unlocks from the local
  /// ledger snapshot to Firestore. Each write is create-if-not-exists and safe
  /// to retry. Writes are batched in groups of 500 (Firestore WriteBatch limit).
  ///
  /// Phase 4d: triggered by [HybridProgressionRepository] on first user load
  /// after login (idempotent via SharedPreferences tracking).
  Future<void> migrateLocalLedger({
    required String uid,
    required List<ProgressionRewardGrant> ruleGrants,
    required List<ProgressionQuestRewardGrant> questGrants,
    required List<ProgressionAchievementUnlockEvent> achievementUnlocks,
  });

  /// Updates the derived progression state summary document at
  /// users/{uid}/progression/state with derived cache fields:
  /// totalXp, level, claimCount, achievementCount, lastSyncedAt.
  ///
  /// Phase 4e: called after successful claim/unlock/migration writes
  /// to keep the summary document in sync. Best-effort only — failures
  /// are logged but do not block local behavior.
  Future<void> updateProgressionSummary({
    required String uid,
    required ProgressionLedgerSnapshot ledger,
  });
}
