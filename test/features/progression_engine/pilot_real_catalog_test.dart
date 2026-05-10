import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/catalog_validator.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_input.dart';
import 'package:forgetrack/features/progression_engine/domain/models/ledger_event.dart';

EngineEvaluationInput _ambitiousPlayerInput() => EngineEvaluationInput(
      evaluatedAt: DateTime(2026, 5, 10, 18),
      // Hit the daily fitness goals.
      stepsToday: 10500,
      proteinGramsToday: 165,
      // Hit the lifetime mastery threshold.
      stepsLifetime: 120000,
      // Reached level 5.
      level: 5,
      totalXp: 5000,
    );

void main() {
  group('Phase 3 pilot — real catalog', () {
    test('catalog validates cleanly with default goals', () {
      const validator = CatalogValidator();
      expect(validator.validateOrThrow, returnsNormally);
    });

    test('catalog validates cleanly with custom goals', () {
      const validator = CatalogValidator();
      expect(
        () => validator.validateOrThrow(
          const EngineCatalogContext(
            goals: EngineGoalSet(dailySteps: 8000, dailyProteinGrams: 200),
          ),
        ),
        returnsNormally,
      );
    });

    test('an ambitious player hits every pilot objective on first run',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-run',
      );

      final result = await engine.evaluate(input: _ambitiousPlayerInput());

      // All five pilot objectives complete.
      final completedIds =
          result.completedObjectives.map((o) => o.objectiveId).toSet();
      expect(completedIds, {
        'daily_steps_today',
        'daily_protein_today',
        'lifetime_steps_100k',
        'welcome_xp',
        'level_5_xp',
      });

      // All five pilot nodes complete.
      final nodeIds = result.completedNodes.map((n) => n.nodeId).toSet();
      expect(nodeIds, {
        'daily_steps_today',
        'daily_protein_today',
        'welcome_to_journey',
        'lifetime_steps_100k',
        'level_5',
      });

      // XP rewards from the two daily quests.
      final xpGrants = result.grantedRewards
          .where((g) => g.event.rewardKind == RewardGrantKind.xp)
          .toList();
      expect(xpGrants, hasLength(2));
      // Cosmetic rewards from welcome (2) + lifetime steps (1) +
      // level 5 (1) = 4.
      final cosmeticGrants = result.grantedRewards
          .where((g) => g.event.rewardKind == RewardGrantKind.cosmetic)
          .toList();
      expect(cosmeticGrants, hasLength(4));
      final cosmeticIds =
          cosmeticGrants.map((g) => g.event.cosmeticId).toSet();
      expect(cosmeticIds, {
        'background_camp',
        'emblem_pilgrim_mark',
        'background_forest_trail',
      });
    });

    test('re-running with the same input emits no new events', () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-rerun',
      );
      final input = _ambitiousPlayerInput();

      final first = await engine.evaluate(input: input);
      expect(first.completedNodes, hasLength(5));

      final second = await engine.evaluate(input: input);
      expect(second.completedObjectives, isEmpty);
      expect(second.completedNodes, isEmpty);
      expect(second.grantedRewards, isEmpty);
    });

    test('a beginner without enough steps does not complete the daily quest',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-beginner',
      );

      final result = await engine.evaluate(
        input: EngineEvaluationInput(
          evaluatedAt: DateTime(2026, 5, 10, 9),
          stepsToday: 4500,
          proteinGramsToday: 0,
          stepsLifetime: 4500,
          level: 1,
          totalXp: 0,
        ),
      );

      // Welcome always completes (totalXp >= 0).
      final ids = result.completedNodes.map((n) => n.nodeId).toSet();
      expect(ids, {'welcome_to_journey'});

      // Daily steps + protein + lifetime + level 5 are all unmet.
      expect(
        result.completedObjectives.map((o) => o.objectiveId),
        contains('welcome_xp'),
      );
      expect(
        result.completedObjectives.map((o) => o.objectiveId),
        isNot(contains('daily_steps_today')),
      );
    });

    test('custom dailySteps goal is reflected in the evaluation', () async {
      // With dailySteps lowered to 3000, a player at 4500 steps now
      // satisfies the daily steps quest.
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-custom-goal',
      );

      final result = await engine.evaluate(
        input: EngineEvaluationInput(
          evaluatedAt: DateTime(2026, 5, 10, 9),
          stepsToday: 4500,
          stepsLifetime: 4500,
          level: 1,
          totalXp: 0,
        ),
        catalogContext: const EngineCatalogContext(
          goals: EngineGoalSet(dailySteps: 3000),
        ),
      );

      final ids = result.completedNodes.map((n) => n.nodeId).toSet();
      expect(ids, contains('daily_steps_today'));
    });

    test('static definitionForId still resolves the ported entries', () {
      // The class-level lookup uses default context; pilot ports
      // include a stable set of ids.
      expect(
        ObjectiveCatalog.definitionForId('daily_steps_today'),
        isNotNull,
      );
      expect(
        ObjectiveCatalog.definitionForId('lifetime_steps_100k'),
        isNotNull,
      );
      expect(
        ProgressionNodeCatalog.definitionForId('welcome_to_journey'),
        isNotNull,
      );
      expect(
        ProgressionNodeCatalog.definitionForId('level_5'),
        isNotNull,
      );
    });
  });
}
