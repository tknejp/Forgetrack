import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_input.dart';

ProgressionEngineProvider _provider() {
  final repo = InMemoryProgressionEngineRepository();
  final engine = ProgressionEngine(
    repository: repo,
    runIdGenerator: () => 'test',
  );
  return ProgressionEngineProvider(engine: engine, repository: repo);
}

EngineEvaluationInput _input() => EngineEvaluationInput(
      evaluatedAt: DateTime(2026, 5, 11, 12),
      stepsToday: 0,
      proteinGramsToday: 0,
      level: 1,
      totalXp: 0,
    );

void main() {
  group('Daily quest pick', () {
    test('always surfaces exactly dailyQuestPickCount on a given day',
        () async {
      final provider = _provider();
      // Force one evaluation so the provider has a result + ledger.
      await provider.evaluateWith(input: _input());

      final picks = provider.currentDailyQuests;
      expect(picks.length, ProgressionEngineProvider.dailyQuestPickCount);
    });

    test('all daily quests in the catalog are larger than the pick',
        () async {
      final provider = _provider();
      await provider.evaluateWith(input: _input());

      // Sanity: there are more daily quests in the catalog than we
      // surface — otherwise the rotation is moot.
      expect(
        provider.allDailyQuests.length,
        greaterThan(ProgressionEngineProvider.dailyQuestPickCount),
      );
    });

    test('the same provider returns the same picks across calls in one day',
        () async {
      final provider = _provider();
      await provider.evaluateWith(input: _input());

      final firstCall =
          provider.currentDailyQuests.map((q) => q.nodeId).toSet();
      final secondCall =
          provider.currentDailyQuests.map((q) => q.nodeId).toSet();
      expect(firstCall, equals(secondCall));
    });
  });
}
