import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_input.dart';

EngineEvaluationInput _input({
  int level = 10,
  int totalXp = 5000,
  Map<String, int> nodeCompletionCounts = const {},
}) =>
    EngineEvaluationInput(
      evaluatedAt: DateTime(2026, 5, 11, 12),
      level: level,
      totalXp: totalXp,
      stepsToday: 0,
      proteinGramsToday: 0,
      nodeCompletionCounts: nodeCompletionCounts,
    );

void main() {
  group('Forest Trial chain', () {
    test('open auto-fires at level 10; subsequent steps remain locked',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'forest-trial-1',
      );

      final result = await engine.evaluate(input: _input());

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

    test('step 1 becomes available once daily_steps_today has 5 completions',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'forest-trial-2',
      );

      // First run: open auto-completes (gates the chain).
      await engine.evaluate(input: _input());

      // Second run: player has racked up 5 daily_steps_today
      // completions over time.
      final result = await engine.evaluate(
        input: _input(
          nodeCompletionCounts: const {'daily_steps_today': 5},
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
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'forest-trial-3',
      );

      // First evaluate: open auto-fires (lands in the ledger). Step
      // 1's prereq isn't yet visible to the resolver — it walks the
      // ledger snapshot taken before this run, not after.
      await engine.evaluate(input: _input());

      // Second evaluate with all backing objectives satisfied. Open
      // is now in the ledger so step 1 unlocks; step 2 and 3 stay
      // gated until the player claims step 1 (and step 2 in turn).
      final result = await engine.evaluate(
        input: _input(
          nodeCompletionCounts: const {
            'daily_steps_today': 5,
            'daily_protein_today': 5,
            'daily_sleep_today': 3,
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
