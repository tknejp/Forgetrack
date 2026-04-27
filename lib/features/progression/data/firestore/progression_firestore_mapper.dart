import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/progression_models.dart';

/// Pure serialization/deserialization between domain models and Firestore maps.
///
/// Does not depend on Isar or FirebaseFirestore.
/// Callers (gateway) are responsible for adding `createdAt: FieldValue.serverTimestamp()`
/// at write time — this class does not produce that sentinel.
class ProgressionFirestoreMapper {
  const ProgressionFirestoreMapper._();

  // ---------------------------------------------------------------------------
  // Upload guards
  // ---------------------------------------------------------------------------

  /// True when [grant] should be uploaded to Firestore.
  /// Unclaimed, zero-XP, or missing-claimedAt records are excluded.
  static bool isRuleGrantUploadable(ProgressionRewardGrant grant) {
    return grant.isClaimed &&
        grant.effectiveXpGranted > 0 &&
        grant.claimedAt != null;
  }

  /// True when [grant] should be uploaded to Firestore.
  static bool isQuestGrantUploadable(ProgressionQuestRewardGrant grant) {
    return grant.isClaimed &&
        grant.effectiveXpGranted > 0 &&
        grant.claimedAt != null;
  }

  // ---------------------------------------------------------------------------
  // Serialization  (domain → Firestore map)
  // ---------------------------------------------------------------------------

  /// Serializes a claimed rule grant.
  /// For legacy records where [ProgressionRewardGrant.finalXp] is null,
  /// uploads [ProgressionRewardGrant.xpGranted] as the `finalXp` value.
  ///
  /// Precondition: [isRuleGrantUploadable] must return true.
  static Map<String, dynamic> ruleGrantToMap(ProgressionRewardGrant grant) {
    assert(isRuleGrantUploadable(grant),
        'ruleGrantToMap called on non-uploadable grant: ${grant.rewardKey}');
    return {
      'rewardKey': grant.rewardKey,
      'type': 'rule',
      'ruleId': grant.ruleId,
      'ruleVersion': grant.ruleVersion,
      'domainName': grant.domain.name,
      'periodKindName': grant.period.kind.name,
      'periodStart': Timestamp.fromDate(grant.period.start),
      'baseXp': grant.xpGranted,
      'finalXp': grant.finalXp ?? grant.xpGranted,
      'levelAtClaim': grant.levelAtClaim,
      'multiplierAtClaim': grant.multiplierAtClaim,
      'rewardStatusName': ProgressionRewardStatus.claimed.name,
      'unlockedAt': Timestamp.fromDate(grant.unlockedAt),
      'claimedAt': Timestamp.fromDate(grant.claimedAt!),
    };
  }

  /// Serializes a claimed quest grant.
  /// For legacy records where [ProgressionQuestRewardGrant.finalXp] is null,
  /// uploads [ProgressionQuestRewardGrant.xpGranted] as the `finalXp` value.
  ///
  /// Precondition: [isQuestGrantUploadable] must return true.
  static Map<String, dynamic> questGrantToMap(ProgressionQuestRewardGrant grant) {
    assert(isQuestGrantUploadable(grant),
        'questGrantToMap called on non-uploadable grant: ${grant.rewardKey}');
    return {
      'rewardKey': grant.rewardKey,
      'type': 'quest',
      'questId': grant.questId,
      'baseXp': grant.xpGranted,
      'finalXp': grant.finalXp ?? grant.xpGranted,
      'levelAtClaim': grant.levelAtClaim,
      'multiplierAtClaim': grant.multiplierAtClaim,
      'rewardStatusName': ProgressionRewardStatus.claimed.name,
      'unlockedAt': Timestamp.fromDate(grant.unlockedAt),
      'claimedAt': Timestamp.fromDate(grant.claimedAt!),
    };
  }

  /// Serializes an achievement unlock event.
  static Map<String, dynamic> achievementUnlockToMap(
    ProgressionAchievementUnlockEvent unlock,
  ) {
    return {
      'achievementId': unlock.achievementId,
      'unlockKey': unlock.unlockKey,
      'unlockedAt': Timestamp.fromDate(unlock.unlockedAt),
    };
  }

  // ---------------------------------------------------------------------------
  // Deserialization  (Firestore map → domain)
  // ---------------------------------------------------------------------------

  /// Deserializes a Firestore document into a [ProgressionRewardGrant].
  /// Returns null if the document type is wrong or required fields are missing.
  ///
  /// Note: `targetValue` and `actualValue` are evaluation-only fields not stored
  /// in Firestore; they are set to 0.0 on the restored record. Isar will have
  /// the full values once the engine re-evaluates.
  static ProgressionRewardGrant? ruleGrantFromMap(Map<String, dynamic> data) {
    if (data['type'] != 'rule') return null;
    try {
      final periodKindName = data['periodKindName'] as String;
      final periodKind = ProgressionPeriodKind.values.byName(periodKindName);
      final periodStart = (data['periodStart'] as Timestamp).toDate();
      final periodEnd = periodKind == ProgressionPeriodKind.week
          ? periodStart.add(const Duration(days: 6))
          : periodStart;

      return ProgressionRewardGrant(
        rewardKey: data['rewardKey'] as String,
        ruleId: data['ruleId'] as String,
        ruleVersion: data['ruleVersion'] as String,
        domain: ProgressionDomain.values.byName(data['domainName'] as String),
        period: ProgressionPeriod(
          kind: periodKind,
          start: periodStart,
          end: periodEnd,
        ),
        xpGranted: data['baseXp'] as int,
        targetValue: 0.0,
        actualValue: 0.0,
        rewardStatus: ProgressionRewardStatus.claimed,
        unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
        finalXp: data['finalXp'] as int?,
        levelAtClaim: data['levelAtClaim'] as int?,
        multiplierAtClaim: (data['multiplierAtClaim'] as num?)?.toDouble(),
        claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Deserializes a Firestore document into a [ProgressionQuestRewardGrant].
  /// Returns null if the document type is wrong or required fields are missing.
  ///
  /// Note: `completedAt` is not stored separately in Firestore; `claimedAt` is
  /// used as a fallback. Isar will have the exact value after next sync.
  static ProgressionQuestRewardGrant? questGrantFromMap(
    Map<String, dynamic> data,
  ) {
    if (data['type'] != 'quest') return null;
    try {
      final claimedAt = (data['claimedAt'] as Timestamp).toDate();
      return ProgressionQuestRewardGrant(
        rewardKey: data['rewardKey'] as String,
        questId: data['questId'] as String,
        xpGranted: data['baseXp'] as int,
        rewardStatus: ProgressionRewardStatus.claimed,
        unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
        completedAt: claimedAt,
        finalXp: data['finalXp'] as int?,
        levelAtClaim: data['levelAtClaim'] as int?,
        multiplierAtClaim: (data['multiplierAtClaim'] as num?)?.toDouble(),
        claimedAt: claimedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Deserializes a Firestore document into a [ProgressionAchievementUnlockEvent].
  /// Returns null if required fields are missing.
  static ProgressionAchievementUnlockEvent? achievementUnlockFromMap(
    Map<String, dynamic> data,
  ) {
    try {
      return ProgressionAchievementUnlockEvent(
        unlockKey: data['unlockKey'] as String,
        achievementId: data['achievementId'] as String,
        unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
      );
    } catch (_) {
      return null;
    }
  }
}
