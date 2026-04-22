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
    final activeQuestRecords =
        await isar.progressionActiveQuestRecords.where().findAll();

    final lastEvaluatedAt = evaluationRecords.isEmpty
        ? null
        : evaluationRecords
            .map((record) => record.evaluatedAt)
            .reduce((left, right) => left.isAfter(right) ? left : right);

    return ProgressionLedgerSnapshot(
      evaluations: evaluationRecords.map(_mapEvaluation).toList(),
      rewardGrants: rewardRecords.map(_mapGrant).toList(),
      activeQuestIds:
          activeQuestRecords.map((record) => record.questId).toSet(),
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
              grantedAt: evaluatedAt,
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
      actualValue: record.actualValue,
      targetValue: record.targetValue,
      upperTargetValue: record.upperTargetValue,
      toleranceRatio: record.toleranceRatio,
      progress: record.progress,
      achieved: record.achieved,
      status: record.statusName == null
          ? (record.achieved
              ? ProgressionEvaluationStatus.achieved
              : ProgressionEvaluationStatus.missed)
          : ProgressionEvaluationStatus.values.byName(record.statusName!),
      missReason: record.missReasonName == null
          ? null
          : ProgressionMissReason.values.byName(record.missReasonName!),
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
      grantedAt: record.grantedAt,
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
    required DateTime grantedAt,
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
      ..grantedAt = grantedAt;
  }
}
