import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_context.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';

import '_engine_test_helpers.dart';

EngineEvaluationContext _context({
  int level = 10,
  int totalXp = 5000,
  Map<String, int> nodeCompletionCounts = const {},
  Map<String, double> objectiveActualOverrides = const {},
}) =>
    buildTestContext(
      evaluatedAt: DateTime(2026, 5, 11, 12),
      level: level,
      totalXp: totalXp,
      nodeCompletionCounts: nodeCompletionCounts,
      objectiveActualOverrides: objectiveActualOverrides,
    );

/// Seed the ledger with a pilgrim_path_finale completion so the
/// Forest Trail chain's open clears its cross-chapter prereq without
/// us having to walk the whole starter chapter step by step.
Future<void> _seedPilgrimComplete(
  InMemoryProgressionEngineRepository repo,
) async {
  await repo.appendEvents([
    NodeCompletionEvent(
      eventKey: 'node|pilgrim_path_finale|lifetime|complete',
      timestamp: DateTime(2026, 5, 10, 12),
      nodeId: ProgressionEntryId('pilgrim_path_finale'),
    ),
  ]);
}

void main() {
  group('Forest Trial chain', () {
    test('open auto-fires at level 10; subsequent steps remain locked',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      await _seedPilgrimComplete(repo);
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'forest-trial-1',
      );

      final result = await evaluateWithContext(engine, _context());

      final completedIds =
          result.completedNodes.map((n) => n.nodeId).toSet();
      final availableIds =
          result.availableNodes.map((a) => a.nodeId).toSet();

      // Open is auto-claim with LevelMetric >= 10 → completes
      // immediately and grants its XP.
      expect(completedIds, contains('forest_trial_open'));

      // Steps remain hidden until their objectives accumulate AND
      // their prereq is complete. No daily quest completions in the
      // input → none should be available yet.
      expect(availableIds.contains('forest_trial_daily_wins_5'), isFalse);
      expect(availableIds.contains('forest_trial_steps_5'), isFalse);
      expect(availableIds.contains('forest_trial_recovery_3'), isFalse);
      expect(availableIds.contains('forest_trial_finale'), isFalse);
    });

    test(
        'step 1 becomes available once the player banks 5 days with 2+ daily goals',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      await _seedPilgrimComplete(repo);
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'forest-trial-2',
      );

      // First run: open auto-completes (gates the chain).
      await evaluateWithContext(engine, _context());

      // Second run: provider would derive
      // `forest_trial_daily_wins_5_objective = 5` from the ledger
      // once 5 distinct days banked at least 2 daily completions
      // each. Seed the override directly so the engine test stays
      // independent of the ledger-history producer in the provider.
      final result = await evaluateWithContext(
        engine,
        _context(
          objectiveActualOverrides: const {
            'forest_trial_daily_wins_5_objective': 5.0,
          },
        ),
      );

      final availableIds =
          result.availableNodes.map((a) => a.nodeId).toSet();
      expect(availableIds, contains('forest_trial_daily_wins_5'));

      // Later steps still gated by their own prereqs.
      expect(availableIds.contains('forest_trial_steps_5'), isFalse);
      expect(availableIds.contains('forest_trial_recovery_3'), isFalse);
      expect(availableIds.contains('forest_trial_finale'), isFalse);
    });

    test('finale stays locked until all three steps complete', () async {
      final repo = InMemoryProgressionEngineRepository();
      await _seedPilgrimComplete(repo);
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'forest-trial-3',
      );

      // First evaluate: open auto-fires (lands in the ledger). Step
      // 1's prereq isn't yet visible to the resolver — it walks the
      // ledger snapshot taken before this run, not after.
      await evaluateWithContext(engine, _context());

      // Second evaluate with all backing objective values seeded.
      // Step 1 (`DaysWithAtLeastKAmongMetric`) and step 3
      // (`DaysWithAtLeastKAmongMetric` for steps+sleep) read from
      // `objectiveActualOverrides` — the provider's ledger producer
      // is bypassed in this unit test. Step 2 is the only single-
      // node `NodeCompletionsMetric` left in the chain.
      final result = await evaluateWithContext(
        engine,
        _context(
          nodeCompletionCounts: const {'daily_steps_today': 5},
          objectiveActualOverrides: const {
            'forest_trial_daily_wins_5_objective': 5.0,
            'forest_trial_recovery_3_objective': 3.0,
          },
        ),
      );

      final availableIds =
          result.availableNodes.map((a) => a.nodeId).toSet();
      expect(availableIds, contains('forest_trial_daily_wins_5'));
      // Step 2 and 3 still gated by chain prereqs (their predecessor
      // hasn't been claimed yet).
      expect(availableIds.contains('forest_trial_steps_5'), isFalse);
      expect(availableIds.contains('forest_trial_recovery_3'), isFalse);
      expect(availableIds.contains('forest_trial_finale'), isFalse);
    });
  });
}