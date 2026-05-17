import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/models/claim_policy.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_input.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_metric.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_operator.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_scope.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_node_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/reward_definition.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

class _FakeObjectiveCatalog extends ObjectiveCatalog {
  const _FakeObjectiveCatalog(this._defs);
  final List<Objective> _defs;

  @override
  List<Objective> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) =>
      _defs;
}

class _FakeNodeCatalog extends ProgressionEntryCatalog {
  const _FakeNodeCatalog(this._nodes);
  final List<ProgressionEntry> _nodes;

  @override
  List<ProgressionEntry> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) =>
      _nodes;
}

Objective _stepsTodayObjective({double target = 1000}) =>
    Objective(
      id: 'steps_today_$target',
      metric: const StepsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: target,
    );

Quest _quest({
  required String id,
  required String objectiveId,
  int xp = 100,
  ClaimPolicy? claimPolicy,
  List<RewardDefinition>? rewards,
}) =>
    DailyQuest(
      id: id,
      objectiveId: objectiveId,
      titleKey: (_) => 'Title',
      descriptionKey: (_) => 'Desc',
      rewards: rewards ?? [XpReward(amount: xp)],
      rarity: Rarity.common,
      claimPolicy: claimPolicy ?? ClaimPolicy.automatic,
    );

EngineEvaluationInput _input({int steps = 1500, int level = 1, int totalXp = 0}) =>
    EngineEvaluationInput(
      evaluatedAt: DateTime(2026, 5, 10, 12),
      stepsToday: steps,
      level: level,
      totalXp: totalXp,
    );

ProgressionEngine _newEngine({
  required ObjectiveCatalog objectives,
  required ProgressionEntryCatalog nodes,
  required InMemoryProgressionEngineRepository repository,
  String runId = 'test-run',
}) =>
    ProgressionEngine(
      repository: repository,
      objectiveCatalog: objectives,
      nodeCatalog: nodes,
      runIdGenerator: () => runId,
    );

void main() {
  group('ProgressionEngine — happy path', () {
    test('emits objective + node + reward events on first run', () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = _newEngine(
        objectives: _FakeObjectiveCatalog([_stepsTodayObjective()]),
        nodes: _FakeNodeCatalog([
          _quest(id: 'q1', objectiveId: _stepsTodayObjective().id, xp: 50),
        ]),
        repository: repo,
      );

      final result = await engine.evaluate(input: _input(steps: 1500));

      expect(result.completedObjectives, hasLength(1));
      expect(result.completedNodes, hasLength(1));
      expect(result.grantedRewards, hasLength(1));
      expect(
        result.grantedRewards.single.event.rewardKind,
        RewardGrantKind.xp,
      );

      final ledger = await repo.loadLedger();
      expect(ledger.objectiveCompletions, hasLength(1));
      expect(ledger.nodeCompletions, hasLength(1));
      expect(ledger.rewardGrants, hasLength(1));
    });

    test('does not complete when objective is unsatisfied', () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = _newEngine(
        objectives: _FakeObjectiveCatalog([_stepsTodayObjective()]),
        nodes: _FakeNodeCatalog([
          _quest(id: 'q1', objectiveId: _stepsTodayObjective().id),
        ]),
        repository: repo,
      );

      final result = await engine.evaluate(input: _input(steps: 500));

      expect(result.completedObjectives, isEmpty);
      expect(result.completedNodes, isEmpty);
      expect(result.grantedRewards, isEmpty);
    });
  });

  group('ProgressionEngine — idempotency', () {
    test('second run with same input emits no new completions or grants',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = _newEngine(
        objectives: _FakeObjectiveCatalog([_stepsTodayObjective()]),
        nodes: _FakeNodeCatalog([
          _quest(id: 'q1', objectiveId: _stepsTodayObjective().id, xp: 50),
        ]),
        repository: repo,
      );

      final first = await engine.evaluate(input: _input(steps: 1500));
      final second = await engine.evaluate(input: _input(steps: 1500));

      expect(first.completedNodes, hasLength(1));
      expect(second.completedNodes, isEmpty);
      expect(second.grantedRewards, isEmpty);
      expect(second.completedObjectives, isEmpty);

      // Ledger holds one of each, not duplicates.
      final ledger = await repo.loadLedger();
      expect(ledger.objectiveCompletions, hasLength(1));
      expect(ledger.nodeCompletions, hasLength(1));
      expect(ledger.rewardGrants, hasLength(1));
    });

    test('same objective shared across two nodes grants both, only once',
        () async {
      // The whole point of objective + node split: one objective,
      // multiple nodes, no double-evaluation.
      final repo = InMemoryProgressionEngineRepository();
      final objective = _stepsTodayObjective();
      final engine = _newEngine(
        objectives: _FakeObjectiveCatalog([objective]),
        nodes: _FakeNodeCatalog([
          _quest(id: 'quest', objectiveId: objective.id, xp: 50),
          LongTermQuest(
            id: 'achievement_like',
            objectiveId: objective.id,
            titleKey: (_) => 'Achievement',
            descriptionKey: (_) => 'Same objective',
            rewards: const [CosmeticReward(cosmeticId: 'frame_test')],
            rarity: Rarity.uncommon,
          ),
        ]),
        repository: repo,
      );

      final first = await engine.evaluate(input: _input(steps: 1500));
      expect(first.completedObjectives, hasLength(1));
      expect(first.completedNodes, hasLength(2));
      expect(first.grantedRewards, hasLength(2));
      // Different reward kinds for the two nodes.
      final kinds = first.grantedRewards.map((g) => g.event.rewardKind).toSet();
      expect(kinds, {RewardGrantKind.xp, RewardGrantKind.cosmetic});

      // Re-run is idempotent.
      final second = await engine.evaluate(input: _input(steps: 1500));
      expect(second.completedNodes, isEmpty);
      expect(second.grantedRewards, isEmpty);
    });
  });

  group('ProgressionEngine — manual claim', () {
    test('manual node enters availability, claim then completes + grants',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final objective = _stepsTodayObjective();
      final engine = _newEngine(
        objectives: _FakeObjectiveCatalog([objective]),
        nodes: _FakeNodeCatalog([
          LongTermQuest(
            id: 'manual_node',
            objectiveId: objective.id,
            titleKey: (_) => 'Manual',
            descriptionKey: (_) => 'Desc',
            rewards: const [XpReward(amount: 200)],
            rarity: Rarity.rare,
            claimPolicy: ClaimPolicy.manual,
            lockedHintKey: (_) => 'Tap to claim',
          ),
        ]),
        repository: repo,
      );

      // Objective satisfied → node available, NOT completed.
      final first = await engine.evaluate(input: _input(steps: 1500));
      expect(first.completedNodes, isEmpty);
      expect(first.availableNodes, hasLength(1));
      expect(first.grantedRewards, isEmpty);

      // Player claims.
      final claimed =
          await engine.claim(nodeId: 'manual_node', input: _input(steps: 1500));
      expect(claimed.completedNodes, hasLength(1));
      expect(claimed.grantedRewards, hasLength(1));
      expect(claimed.grantedRewards.single.event.xpAmount, isPositive);

      // Re-run is idempotent post-claim.
      final after = await engine.evaluate(input: _input(steps: 1500));
      expect(after.completedNodes, isEmpty);
      expect(after.grantedRewards, isEmpty);
    });
  });
}
