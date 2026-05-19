import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_resolution_reason.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

import '_engine_test_helpers.dart';

class _FakeObjectiveCatalog extends ObjectiveCatalog {
  const _FakeObjectiveCatalog();

  @override
  List<Objective> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) =>
      const [];
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

CompanionAvailability _forestFoxLikeCompanion() => CompanionAvailability(
      id: const ProgressionEntryId('companion_forest_fox'),
      companionId: CosmeticId('companion_forest_fox'),
      titleKey: (_) => 'Forest Fox',
      descriptionKey: (_) => 'A wild fox',
      rewards: const [
        CompanionAvailabilityReward(
          companionId: CosmeticId('companion_forest_fox'),
        ),
      ],
      unlockConditions: const [
        LevelAtLeast(15),
        OwnsCosmetic(CosmeticId('relic_moonlit_foxglove')),
        OwnsCosmetic(CosmeticId('relic_ancient_root')),
      ],
      lockedHintKey: (_) => 'Reach level 15',
      rarity: Rarity.rare,
    );

const _bothRelics = <String>{
  'relic_moonlit_foxglove',
  'relic_ancient_root',
};

void main() {
  group('CompanionAvailability — OwnsCosmetic-based gate', () {
    test(
      'both relics owned but level below gate → companion stays LOCKED, '
      'not in availability',
      () async {
        final repo = InMemoryProgressionEngineRepository();
        final engine = ProgressionEngine(
          repository: repo,
          objectiveCatalog: const _FakeObjectiveCatalog(),
          nodeCatalog: _FakeNodeCatalog([_forestFoxLikeCompanion()]),
          runIdGenerator: () => 'run-locked',
        );

        final result = await engine.evaluate(
          player: buildTestContext(level: 10).player,
          healthSnapshot: buildTestContext().healthSnapshot,
          nutritionSnapshot: buildTestContext().nutritionSnapshot,
          goalBoard: buildTestContext().goalBoard,
          journal: buildTestContext().journal,
          counters: buildTestContext().counters,
          overrides: buildTestContext().overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 30),
          ownedCosmeticIds: _bothRelics,
          reason: ProgressionResolutionReason.liveUpdate,
        );

        expect(
          result.availableNodes.map((a) => a.nodeId),
          isNot(contains('companion_forest_fox')),
          reason: 'Below-gate level should keep companion locked',
        );
        expect(
          result.lockedNodeIds,
          contains('companion_forest_fox'),
          reason: 'Companion should explicitly show as locked',
        );
      },
    );

    test(
      'late-gate: relics owned first, then level reached → companion '
      'flips to AVAILABLE on the next evaluation tick',
      () async {
        // The bug-screening scenario from Trello #76 sub-issue 1: the
        // player owns both relics while below the companion's level
        // gate, then levels up. The engine must re-classify the
        // companion as available on the very next evaluate() call,
        // even though no NEW achievement / relic event fired —
        // only the level changed via XP grants.
        final repo = InMemoryProgressionEngineRepository();
        final engine = ProgressionEngine(
          repository: repo,
          objectiveCatalog: const _FakeObjectiveCatalog(),
          nodeCatalog: _FakeNodeCatalog([_forestFoxLikeCompanion()]),
          runIdGenerator: () => 'run-late-gate',
        );

        final preLevel = await engine.evaluate(
          player: buildTestContext(level: 10).player,
          healthSnapshot: buildTestContext().healthSnapshot,
          nutritionSnapshot: buildTestContext().nutritionSnapshot,
          goalBoard: buildTestContext().goalBoard,
          journal: buildTestContext().journal,
          counters: buildTestContext().counters,
          overrides: buildTestContext().overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 30),
          ownedCosmeticIds: _bothRelics,
        );
        expect(
          preLevel.availableNodes.map((a) => a.nodeId),
          isNot(contains('companion_forest_fox')),
          reason: 'Sanity check: pre-level-up should still be locked',
        );

        final postLevel = await engine.evaluate(
          player: buildTestContext(level: 15).player,
          healthSnapshot: buildTestContext().healthSnapshot,
          nutritionSnapshot: buildTestContext().nutritionSnapshot,
          goalBoard: buildTestContext().goalBoard,
          journal: buildTestContext().journal,
          counters: buildTestContext().counters,
          overrides: buildTestContext().overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 40),
          ownedCosmeticIds: _bothRelics,
        );
        expect(
          postLevel.availableNodes.map((a) => a.nodeId),
          contains('companion_forest_fox'),
          reason: 'Bug regression — companion must surface as available on '
              'the same evaluate() call where the level threshold is crossed, '
              'without requiring a fresh achievement / relic event to retrigger',
        );
      },
    );

    test(
      'relics owned via side channel (no achievement events in journal) → '
      'engine still surfaces companion as available',
      () async {
        // This is the divergence root cause for Trello #76 sub-issue 1.
        // Pre-fix, CompanionAvailability gated on NodeCompleted(<achievement>)
        // — when the cosmetics inventory got a relic through a side
        // channel (devtools `debugGrantCosmetic`, "Unlock all cosmetics",
        // a partial cloud-pull merge) without the corresponding
        // achievement NodeCompletionEvent in the engine ledger, the
        // engine kept the companion locked while the reveal evaluator
        // (which checks `OwnsCosmetic` against the cosmetics inventory)
        // showed 3/3 conditions met. The two surfaces had two different
        // condition graphs. Post-fix, both surfaces read relic ownership
        // from the same source.
        final repo = InMemoryProgressionEngineRepository();
        // Note: NO NodeCompletionEvent appended for any achievement —
        // the relics arrive only via `ownedCosmeticIds`, mimicking the
        // side-channel scenario.
        final engine = ProgressionEngine(
          repository: repo,
          objectiveCatalog: const _FakeObjectiveCatalog(),
          nodeCatalog: _FakeNodeCatalog([_forestFoxLikeCompanion()]),
          runIdGenerator: () => 'run-side-channel',
        );

        final result = await engine.evaluate(
          player: buildTestContext(level: 15).player,
          healthSnapshot: buildTestContext().healthSnapshot,
          nutritionSnapshot: buildTestContext().nutritionSnapshot,
          goalBoard: buildTestContext().goalBoard,
          journal: buildTestContext().journal,
          counters: buildTestContext().counters,
          overrides: buildTestContext().overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 30),
          ownedCosmeticIds: _bothRelics,
        );
        expect(
          result.availableNodes.map((a) => a.nodeId),
          contains('companion_forest_fox'),
          reason: 'Companion must surface as available when relics are '
              'owned + level is at gate, regardless of how the relics '
              'arrived in cosmetics inventory',
        );
      },
    );

    test(
      'one relic missing → companion stays LOCKED',
      () async {
        final repo = InMemoryProgressionEngineRepository();
        final engine = ProgressionEngine(
          repository: repo,
          objectiveCatalog: const _FakeObjectiveCatalog(),
          nodeCatalog: _FakeNodeCatalog([_forestFoxLikeCompanion()]),
          runIdGenerator: () => 'run-one-relic',
        );

        final result = await engine.evaluate(
          player: buildTestContext(level: 15).player,
          healthSnapshot: buildTestContext().healthSnapshot,
          nutritionSnapshot: buildTestContext().nutritionSnapshot,
          goalBoard: buildTestContext().goalBoard,
          journal: buildTestContext().journal,
          counters: buildTestContext().counters,
          overrides: buildTestContext().overrides,
          evaluatedAt: DateTime(2026, 5, 19, 12, 30),
          ownedCosmeticIds: const {'relic_moonlit_foxglove'},
        );
        expect(
          result.availableNodes.map((a) => a.nodeId),
          isNot(contains('companion_forest_fox')),
        );
        expect(result.lockedNodeIds, contains('companion_forest_fox'));
      },
    );
  });
}
