import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

import '_engine_test_helpers.dart';

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

Objective _activeDays7Objective() => Objective(
      id: ObjectiveId('active_days_7'),
      metric: const DistinctActiveDaysMetric(),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 7,
    );

Achievement _activeDays7Achievement() => Achievement(
      id: const ProgressionEntryId('active_days_7'),
      objectiveId: ObjectiveId('active_days_7'),
      titleKey: (_) => 'Active 7 days',
      descriptionKey: (_) => 'Be active 7 days',
      rewards: const [
        CosmeticReward(cosmeticId: CosmeticId('relic_moonlit_foxglove')),
      ],
      contentTags: const [ContentTag.core],
      rarity: Rarity.rare,
    );

void main() {
  group('simulateClaim auto-claim path — reward dispatch (Trello #76 sub-issue 1 follow-on)', () {
    test(
      'auto-claim Achievement with CosmeticReward: result.grantedRewards '
      'contains the cosmetic so the bridge can dispatch it',
      () async {
        // Before the fix, simulateClaim pre-wrote NodeCompletionEvent +
        // every RewardGrantEvent directly, then re-evaluated. The
        // re-eval saw all of those events as "already in ledger" and
        // returned `result.grantedRewards = []`. The cosmetic-unlock
        // bridge walks `result.grantedRewards`, so the relic never
        // landed in inventory and the user's "Grant relic" devtools
        // button looked like it did nothing.
        //
        // After the fix, simulateClaim only writes the
        // ObjectiveCompletionEvent. The engine's re-evaluation sees
        // the forced-true objective outcome, fires the
        // NodeCompletionEvent + reward grants naturally, and exposes
        // them on `result.grantedRewards` — the bridge then dispatches.
        final repo = InMemoryProgressionEngineRepository();
        final engine = ProgressionEngine(
          repository: repo,
          objectiveCatalog: _FakeObjectiveCatalog([_activeDays7Objective()]),
          nodeCatalog: _FakeNodeCatalog([_activeDays7Achievement()]),
          runIdGenerator: () => 'run-auto-claim',
        );

        final ctx = buildTestContext(level: 1);
        final result = await engine.simulateClaim(
          nodeId: 'active_days_7',
          player: ctx.player,
          healthSnapshot: ctx.healthSnapshot,
          nutritionSnapshot: ctx.nutritionSnapshot,
          goalBoard: ctx.goalBoard,
          journal: ctx.journal,
          counters: ctx.counters,
          overrides: ctx.overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 30),
        );

        final cosmeticGrants = result.grantedRewards
            .where((g) =>
                g.event.rewardKind == RewardGrantKind.cosmetic &&
                g.event.cosmeticId == 'relic_moonlit_foxglove')
            .toList();
        expect(
          cosmeticGrants,
          isNotEmpty,
          reason:
              'simulateClaim must surface the auto-claim achievement\'s '
              'CosmeticReward in result.grantedRewards so the unlock '
              'bridge can dispatch it (without this, devtools-granting '
              'a relic silently no-ops and #76 sub-issue 1 reproduces)',
        );
        expect(
          result.completedNodes.map((c) => c.nodeId),
          contains('active_days_7'),
          reason: 'Achievement must also surface as completed on the '
              'same run so downstream celebration / cosmetic flows fire',
        );
      },
    );

    test(
      'auto-claim simulateClaim is idempotent: a second call produces '
      'no new grants (the engine sees the prior NodeCompletionEvent in '
      'the ledger and doesn\'t re-emit rewards)',
      () async {
        final repo = InMemoryProgressionEngineRepository();
        final engine = ProgressionEngine(
          repository: repo,
          objectiveCatalog: _FakeObjectiveCatalog([_activeDays7Objective()]),
          nodeCatalog: _FakeNodeCatalog([_activeDays7Achievement()]),
          runIdGenerator: () => 'run-idempotent',
        );

        final ctx = buildTestContext(level: 1);
        // First call grants the cosmetic.
        await engine.simulateClaim(
          nodeId: 'active_days_7',
          player: ctx.player,
          healthSnapshot: ctx.healthSnapshot,
          nutritionSnapshot: ctx.nutritionSnapshot,
          goalBoard: ctx.goalBoard,
          journal: ctx.journal,
          counters: ctx.counters,
          overrides: ctx.overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 30),
        );

        // Second call: no new grants — already in ledger.
        final result2 = await engine.simulateClaim(
          nodeId: 'active_days_7',
          player: ctx.player,
          healthSnapshot: ctx.healthSnapshot,
          nutritionSnapshot: ctx.nutritionSnapshot,
          goalBoard: ctx.goalBoard,
          journal: ctx.journal,
          counters: ctx.counters,
          overrides: ctx.overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 31),
        );
        expect(result2.grantedRewards, isEmpty);
        expect(result2.completedNodes, isEmpty);
      },
    );
  });
}
