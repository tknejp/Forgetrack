import 'package:isar/isar.dart';

import '../domain/progression_models.dart';
import '../domain/progression_repository.dart';
import 'local/progression_database.dart';
import 'local/progression_local_models.dart';

class ProgressionRepositoryImpl implements ProgressionRepository {
  ProgressionRepositoryImpl(this._database);

  final ProgressionDatabase _database;

  @override
  Future<ProgressionLedgerSnapshot> loadLedger() async {
    final isar = _database.isar;
    final evaluationRecords =
        await isar.progressionEvaluationRecords.where().findAll();
    final rewardRecords =
        await isar.progressionRewardGrantRecords.where().findAll();
    final questRewardRecords =
        await isar.progressionQuestRewardGrantRecords.where().findAll();
    final activeQuestRecords =
        await isar.progressionActiveQuestRecords.where().findAll();
    final achievementUnlockRecords =
        await isar.progressionAchievementUnlockRecords.where().findAll();

    final lastEvaluatedAt = evaluationRecords.isEmpty
        ? null
        : evaluationRecords
            .map((record) => record.evaluatedAt)
            .reduce((left, right) => left.isAfter(right) ? left : right);

    return ProgressionLedgerSnapshot(
      evaluations: evaluationRecords.map(_mapEvaluation).toList(),
      rewardGrants: rewardRecords.map(_mapGrant).toList(),
      questRewardGrants: questRewardRecords.map(_mapQuestRewardGrant).toList(),
      activeQuestIds:
          activeQuestRecords.map((record) => record.questId).toSet(),
      achievementUnlocks:
          achievementUnlockRecords.map(_mapAchievementUnlock).toList(),
      lastEvaluatedAt: lastEvaluatedAt,
    );
  }

  @override
  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  }) async {
    final isar = _database.isar;

    await isar.writeTxn(() async {
      await isar.progressionEvaluationRecords.putAll(
        evaluations
            .map(
              (evaluation) => _toEvaluationRecord(
                evaluation: evaluation,
                evaluatedAt: evaluatedAt,
              ),
            )
            .toList(),
      );

      final existingRewardKeys =
          (await isar.progressionRewardGrantRecords.where().findAll())
              .map((record) => record.rewardKey)
              .toSet();

      final newRewardRecords = evaluations
          .where((evaluation) => evaluation.achieved && evaluation.rewardXp > 0)
          .where((evaluation) =>
              !existingRewardKeys.contains(evaluation.rewardKey))
          .map(
            (evaluation) => _toGrantRecord(
              evaluation: evaluation,
              unlockedAt: evaluatedAt,
            ),
          )
          .toList();

      if (newRewardRecords.isNotEmpty) {
        await isar.progressionRewardGrantRecords.putAll(newRewardRecords);
      }
    });

    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    final isar = _database.isar;

    await isar.writeTxn(() async {
      final record = await isar.progressionRewardGrantRecords
          .filter()
          .rewardKeyEqualTo(rewardKey)
          .findFirst();
      if (record == null) return;
      if (record.rewardStatusName == ProgressionRewardStatus.claimed.name) {
        return;
      }

      record.rewardStatusName = ProgressionRewardStatus.claimed.name;
      record.claimedAt = claimedAt;
      record.finalXp = finalXp;
      record.levelAtClaim = levelAtClaim;
      record.multiplierAtClaim = multiplierAtClaim;
      await isar.progressionRewardGrantRecords.put(record);
    });

    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistQuestRewardGrants({
    required List<ProgressionQuestRewardGrant> grants,
  }) async {
    final isar = _database.isar;
    if (grants.isEmpty) return loadLedger();

    await isar.writeTxn(() async {
      await isar.progressionQuestRewardGrantRecords.putAll(
        grants.map(_toQuestRewardGrantRecord).toList(),
      );
    });

    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> claimQuestReward({
    required String rewardKey,
    required DateTime claimedAt,
    required int finalXp,
    required int levelAtClaim,
    required double multiplierAtClaim,
  }) async {
    final isar = _database.isar;

    await isar.writeTxn(() async {
      final record = await isar.progressionQuestRewardGrantRecords
          .filter()
          .rewardKeyEqualTo(rewardKey)
          .findFirst();
      if (record == null) return;
      if (record.rewardStatusName == ProgressionRewardStatus.claimed.name) {
        return;
      }

      record.rewardStatusName = ProgressionRewardStatus.claimed.name;
      record.claimedAt = claimedAt;
      record.finalXp = finalXp;
      record.levelAtClaim = levelAtClaim;
      record.multiplierAtClaim = multiplierAtClaim;
      await isar.progressionQuestRewardGrantRecords.put(record);
    });

    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistAchievementUnlocks({
    required List<ProgressionAchievementUnlockEvent> unlocks,
  }) async {
    final isar = _database.isar;
    if (unlocks.isEmpty) return loadLedger();

    await isar.writeTxn(() async {
      final existingKeys =
          (await isar.progressionAchievementUnlockRecords.where().findAll())
              .map((record) => record.unlockKey)
              .toSet();

      final newRecords = unlocks
          .where((unlock) => !existingKeys.contains(unlock.unlockKey))
          .map(_toAchievementUnlockRecord)
          .toList();

      if (newRecords.isNotEmpty) {
        await isar.progressionAchievementUnlockRecords.putAll(newRecords);
      }
    });

    return loadLedger();
  }

  @override
  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  }) async {
    final isar = _database.isar;
    final assignedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.progressionActiveQuestRecords.clear();
      if (activeQuestIds.isEmpty) return;

      await isar.progressionActiveQuestRecords.putAll(
        activeQuestIds
            .map(
              (questId) => ProgressionActiveQuestRecord()
                ..questId = questId
                ..assignedAt = assignedAt,
            )
            .toList(),
      );
    });

    return loadLedger();
  }

  double _sanitizeDouble(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value;
  }

  T? _parseEnum<T extends Enum>(List<T> values, String? name) {
    if (name == null || name.isEmpty) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  ProgressionEvaluation _mapEvaluation(ProgressionEvaluationRecord record) {
    return ProgressionEvaluation(
      evaluationKey: record.evaluationKey,
      rewardKey: record.rewardKey,
      ruleId: record.ruleId,
      ruleVersion: record.ruleVersion,
      domain: ProgressionDomain.values.byName(record.domainName),
      period: ProgressionPeriod(
        kind: ProgressionPeriodKind.values.byName(record.periodKindName),
        start: progressionDate(record.periodStart),
        end: progressionDate(record.periodEnd),
      ),
      comparator: ProgressionComparator.values.byName(record.comparatorName),
      actualValue: _sanitizeDouble(record.actualValue),
      targetValue: _sanitizeDouble(record.targetValue),
      upperTargetValue: record.upperTargetValue == null
          ? null
          : _sanitizeDouble(record.upperTargetValue!),
      toleranceRatio: _sanitizeDouble(record.toleranceRatio),
      progress: _sanitizeDouble(record.progress),
      achieved: record.achieved,
      status: _parseEnum(
            ProgressionEvaluationStatus.values,
            record.statusName,
          ) ??
          (record.achieved
              ? ProgressionEvaluationStatus.achieved
              : ProgressionEvaluationStatus.missed),
      missReason:
          _parseEnum(ProgressionMissReason.values, record.missReasonName),
      rewardXp: record.rewardXp,
      title: record.title,
      description: record.description,
      explanation: record.explanation,
    );
  }

  ProgressionRewardGrant _mapGrant(ProgressionRewardGrantRecord record) {
    return ProgressionRewardGrant(
      rewardKey: record.rewardKey,
      ruleId: record.ruleId,
      ruleVersion: record.ruleVersion,
      domain: ProgressionDomain.values.byName(record.domainName),
      period: ProgressionPeriod(
        kind: ProgressionPeriodKind.values.byName(record.periodKindName),
        start: progressionDate(record.periodStart),
        end: progressionDate(record.periodEnd),
      ),
      xpGranted: record.xpGranted,
      targetValue: _sanitizeDouble(record.targetValue),
      actualValue: _sanitizeDouble(record.actualValue),
      upperTargetValue: record.upperTargetValue == null
          ? null
          : _sanitizeDouble(record.upperTargetValue!),
      toleranceRatio: _sanitizeDouble(record.toleranceRatio),
      rewardStatus:
          _parseEnum(ProgressionRewardStatus.values, record.rewardStatusName) ??
              ProgressionRewardStatus.unlocked,
      unlockedAt: record.unlockedAt,
      claimedAt: record.claimedAt,
      finalXp: record.finalXp,
      levelAtClaim: record.levelAtClaim,
      multiplierAtClaim: record.multiplierAtClaim,
    );
  }

  ProgressionQuestRewardGrant _mapQuestRewardGrant(
    ProgressionQuestRewardGrantRecord record,
  ) {
    return ProgressionQuestRewardGrant(
      rewardKey: record.rewardKey,
      questId: record.questId,
      xpGranted: record.xpGranted,
      rewardStatus:
          _parseEnum(ProgressionRewardStatus.values, record.rewardStatusName) ??
              ProgressionRewardStatus.unlocked,
      unlockedAt: record.unlockedAt,
      completedAt: record.completedAt,
      claimedAt: record.claimedAt,
      finalXp: record.finalXp,
      levelAtClaim: record.levelAtClaim,
      multiplierAtClaim: record.multiplierAtClaim,
    );
  }

  ProgressionEvaluationRecord _toEvaluationRecord({
    required ProgressionEvaluation evaluation,
    required DateTime evaluatedAt,
  }) {
    return ProgressionEvaluationRecord()
      ..evaluationKey = evaluation.evaluationKey
      ..rewardKey = evaluation.rewardKey
      ..ruleId = evaluation.ruleId
      ..ruleVersion = evaluation.ruleVersion
      ..domainName = evaluation.domain.name
      ..periodKindName = evaluation.period.kind.name
      ..periodStart = evaluation.period.start
      ..periodEnd = evaluation.period.end
      ..comparatorName = evaluation.comparator.name
      ..actualValue = evaluation.actualValue
      ..targetValue = evaluation.targetValue
      ..upperTargetValue = evaluation.upperTargetValue
      ..toleranceRatio = evaluation.toleranceRatio
      ..progress = evaluation.progress
      ..achieved = evaluation.achieved
      ..statusName = evaluation.status.name
      ..missReasonName = evaluation.missReason?.name
      ..rewardXp = evaluation.rewardXp
      ..title = evaluation.title
      ..description = evaluation.description
      ..explanation = evaluation.explanation
      ..evaluatedAt = evaluatedAt;
  }

  ProgressionRewardGrantRecord _toGrantRecord({
    required ProgressionEvaluation evaluation,
    required DateTime unlockedAt,
  }) {
    return ProgressionRewardGrantRecord()
      ..rewardKey = evaluation.rewardKey
      ..ruleId = evaluation.ruleId
      ..ruleVersion = evaluation.ruleVersion
      ..domainName = evaluation.domain.name
      ..periodKindName = evaluation.period.kind.name
      ..periodStart = evaluation.period.start
      ..periodEnd = evaluation.period.end
      ..xpGranted = evaluation.rewardXp
      ..targetValue = evaluation.targetValue
      ..actualValue = evaluation.actualValue
      ..upperTargetValue = evaluation.upperTargetValue
      ..toleranceRatio = evaluation.toleranceRatio
      ..rewardStatusName = ProgressionRewardStatus.unlocked.name
      ..unlockedAt = unlockedAt
      ..claimedAt = null;
  }

  ProgressionQuestRewardGrantRecord _toQuestRewardGrantRecord(
    ProgressionQuestRewardGrant grant,
  ) {
    return ProgressionQuestRewardGrantRecord()
      ..rewardKey = grant.rewardKey
      ..questId = grant.questId
      ..xpGranted = grant.xpGranted
      ..rewardStatusName = grant.rewardStatus.name
      ..unlockedAt = grant.unlockedAt
      ..completedAt = grant.completedAt
      ..claimedAt = grant.claimedAt;
  }

  ProgressionAchievementUnlockEvent _mapAchievementUnlock(
    ProgressionAchievementUnlockRecord record,
  ) {
    return ProgressionAchievementUnlockEvent(
      unlockKey: record.unlockKey,
      achievementId: record.achievementId,
      unlockedAt: record.unlockedAt,
    );
  }

  ProgressionAchievementUnlockRecord _toAchievementUnlockRecord(
    ProgressionAchievementUnlockEvent unlock,
  ) {
    return ProgressionAchievementUnlockRecord()
      ..unlockKey = unlock.unlockKey
      ..achievementId = unlock.achievementId
      ..unlockedAt = unlock.unlockedAt;
  }
}

/// Convenience alias that makes the Phase 4 Firestore substitution explicit.
/// Replace with `FirestoreProgressionRepository` (implements same interface)
/// when cloud sync is added.
typedef LocalProgressionRepository = ProgressionRepositoryImpl;
