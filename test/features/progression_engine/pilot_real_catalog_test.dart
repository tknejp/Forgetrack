import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/catalog_validator.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_context.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';

import '_engine_test_helpers.dart';

EngineEvaluationContext _ambitiousPlayerInput() => buildTestContext(
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

      final result = await evaluateWithContext(engine, _ambitiousPlayerInput());

      // Four core objectives complete (welcome_to_journey is
      // condition-driven only — no objective).
      final completedIds =
          result.completedObjectives.map((o) => o.objectiveId).toSet();
      expect(completedIds, containsAll({
        'daily_steps',
        'daily_protein',
        'lifetime_steps_100k',
        'level_xp_5',
      }));

      // Auto-claim nodes complete on first run.
      // `pilgrim_path_open` is the starter chapter's auto-claim open
      // step — fires once the player reaches level 1.
      final autoCompletedIds = result.completedNodes.map((n) => n.nodeId).toSet();
      expect(autoCompletedIds, containsAll({
        'welcome_to_journey',
        'pilgrim_path_open',
        'steps_total_100k',
        'level_5',
      }));

      // Manual-claim quest nodes go to availability, not completion.
      final availableIds =
          result.availableNodes.map((a) => a.nodeId).toSet();
      expect(availableIds, containsAll({
        'daily_steps_today',
        'daily_protein_today',
      }));

      // Manual-claim quest XP only arrives after the player claims —
      // confirm none of the manual-claim daily quests have been paid
      // out yet. The auto-claim Pilgrim Path opener does ship its XP
      // (40) immediately, so we filter that node out before asserting.
      final manualClaimXpGrants = result.grantedRewards
          .where((g) =>
              g.event.rewardKind == RewardGrantKind.xp &&
              g.event.nodeId != 'pilgrim_path_open')
          .toList();
      expect(manualClaimXpGrants, isEmpty);
      // Cosmetics: welcome's camp background + background from level_5.
      // emblem_pilgrim_mark moved to the Pilgrim Path finale (manual claim)
      // so it no longer fires on the first evaluation. relic_ravine_stone
      // moved off steps_total_100k to steps_total_2_5m (Cave Lynx ingredient)
      // so it no longer fires on the 100k step milestone.
      final cosmeticIds = result.grantedRewards
          .where((g) => g.event.rewardKind == RewardGrantKind.cosmetic)
          .map((g) => g.event.cosmeticId)
          .toSet();
      expect(cosmeticIds, containsAll({
        'background_camp',
        'background_forest_trail',
      }));
      expect(cosmeticIds, isNot(contains('emblem_pilgrim_mark')));
      expect(cosmeticIds, isNot(contains('relic_ravine_stone')));
    });

    test('claiming a manual quest grants XP and moves it to completed',
        () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-claim',
      );
      final ctx = _ambitiousPlayerInput();

      // Initial eval: quest available but not granted.
      final pre = await evaluateWithContext(engine, ctx);
      expect(
        pre.availableNodes.map((a) => a.nodeId),
        contains('daily_steps_today'),
      );

      // Player claims.
      final post = await engine.claim(
        nodeId: 'daily_steps_today',
        player: ctx.player,
        healthSnapshot: ctx.healthSnapshot,
        nutritionSnapshot: ctx.nutritionSnapshot,
        goalBoard: ctx.goalBoard,
        journal: ctx.journal,
        counters: ctx.counters,
        overrides: ctx.overrides,
        evaluatedAt: ctx.evaluatedAt,
      );
      expect(
        post.completedNodes.map((n) => n.nodeId),
        contains('daily_steps_today'),
      );
      final xp = post.grantedRewards
          .where((g) => g.event.nodeId == 'daily_steps_today' &&
              g.event.rewardKind == RewardGrantKind.xp)
          .single;
      expect(xp.event.xpAmount, isPositive);
    });

    test('re-running with the same input emits no new events', () async {
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-rerun',
      );
      final ctx = _ambitiousPlayerInput();

      final first = await evaluateWithContext(engine, ctx);
      expect(first.completedNodes, isNotEmpty);

      final second = await evaluateWithContext(engine, ctx);
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

      final result = await evaluateWithContext(
        engine,
        buildTestContext(
          evaluatedAt: DateTime(2026, 5, 10, 9),
          stepsToday: 4500,
          stepsLifetime: 4500,
          level: 1,
        ),
      );

      // Welcome always completes (no objective, no conditions).
      // The Pilgrim Path open also auto-claims at level 1 — it's the
      // level-1 starter chapter, gated only by `LevelAtLeast(1)`.
      final ids = result.completedNodes.map((n) => n.nodeId).toSet();
      expect(ids, {'welcome_to_journey', 'pilgrim_path_open'});

      // Daily steps + protein + lifetime + level 5 are all unmet.
      expect(
        result.completedObjectives.map((o) => o.objectiveId),
        isNot(contains('daily_steps')),
      );
      expect(
        result.completedObjectives.map((o) => o.objectiveId),
        isNot(contains('level_xp_5')),
      );
    });

    test('custom dailySteps goal is reflected in the evaluation', () async {
      // With dailySteps lowered to 3000, a player at 4500 steps now
      // satisfies the daily steps objective. Quest is manual-claim
      // so it appears in availableNodes, not completedNodes.
      final repo = InMemoryProgressionEngineRepository();
      final engine = ProgressionEngine(
        repository: repo,
        runIdGenerator: () => 'pilot-custom-goal',
      );

      final result = await evaluateWithContext(
        engine,
        buildTestContext(
          evaluatedAt: DateTime(2026, 5, 10, 9),
          stepsToday: 4500,
          stepsLifetime: 4500,
          level: 1,
        ),
        catalogContext: const EngineCatalogContext(
          goals: EngineGoalSet(dailySteps: 3000),
        ),
      );

      final availableIds =
          result.availableNodes.map((a) => a.nodeId).toSet();
      expect(availableIds, contains('daily_steps_today'));
    });

    test('static definitionForId resolves canonical entries', () {
      // The class-level lookup uses default context; canonical ids
      // are stable across the full port.
      expect(ObjectiveCatalog.definitionForId('daily_steps'), isNotNull);
      expect(ObjectiveCatalog.definitionForId('lifetime_steps_100k'),
          isNotNull);
      expect(
          ProgressionEntryCatalog.definitionForId('welcome_to_journey'),
          isNotNull);
      expect(ProgressionEntryCatalog.definitionForId('level_5'), isNotNull);
      expect(ProgressionEntryCatalog.definitionForId('steps_total_100k'),
          isNotNull);
    });
  });
}
