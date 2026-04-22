import 'progression_models.dart';

abstract class ProgressionRepository {
  Future<ProgressionLedgerSnapshot> loadLedger();

  Future<ProgressionLedgerSnapshot> persistEvaluations({
    required List<ProgressionEvaluation> evaluations,
    required DateTime evaluatedAt,
  });

  Future<ProgressionLedgerSnapshot> persistActiveQuestSet({
    required Set<String> activeQuestIds,
  });
}
