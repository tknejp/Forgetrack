import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/application/player_cosmetic_lifecycle_service.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_lifecycle_helpers.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_reveal_state.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/features/cosmetics/domain/inventory.dart';
import 'package:forgetrack/features/cosmetics/domain/player_cosmetic_lifecycle.dart';

void main() {
  // Stable id pickers for the catalog. The catalog is well-formed (validated
  // by cosmetic_sealed_catalog_test) so byId never returns null for these.
  final catalog = CosmeticCatalog();
  final frame = catalog.byId('frame_pilgrim')! as Frame;
  final companion = catalog.byId('companion_ember_sprite')! as Companion;
  final relic = catalog.byId('relic_campfire_spark')! as RelicCosmetic;

  final stamp = DateTime.utc(2026, 5, 18, 12);
  const service = PlayerCosmeticLifecycleService();

  Map<String, CosmeticRevealResult> revealMap(
      Map<String, CosmeticRevealResult> overrides) {
    final base = <String, CosmeticRevealResult>{};
    for (final def in catalog.enabled) {
      base[def.id] = CosmeticRevealResult(
        cosmeticId: def.id,
        state: CosmeticRevealState.hidden,
      );
    }
    base.addAll(overrides);
    return base;
  }

  group('PlayerCosmeticLifecycleService.build', () {
    test('unlocked entries resolve to CosmeticOwned with provenance', () {
      final unlock = UnlockedCosmetic(
        cosmeticId: frame.id,
        unlockedAt: DateTime.utc(2026, 5, 17),
        sourceType: 'progressionLevel',
        sourceId: 'level_5',
      );
      final inventory = service.build(
        catalog: catalog,
        unlocked: {frame.id: unlock},
        revealResults: revealMap(const {}),
        claimableNodeIds: const {},
        evaluatedAt: stamp,
      );

      final entry = inventory.byIdString(frame.id);
      expect(entry, isNotNull);
      final lifecycle = entry!.lifecycle;
      expect(lifecycle, isA<CosmeticOwned>());
      lifecycle as CosmeticOwned;
      expect(lifecycle.unlockedAt, DateTime.utc(2026, 5, 17));
      expect(lifecycle.source, 'progressionLevel');
      expect(lifecycle.sourceId, 'level_5');
    });

    test('companion in availableNodeIds resolves to CosmeticClaimable', () {
      final inventory = service.build(
        catalog: catalog,
        unlocked: const {},
        revealResults: revealMap(const {}),
        claimableNodeIds: {companion.id},
        evaluatedAt: stamp,
      );

      final lifecycle = inventory.byIdString(companion.id)!.lifecycle;
      expect(lifecycle, isA<CosmeticClaimable>());
      expect((lifecycle as CosmeticClaimable).claimVia, companion.id);
    });

    test('non-companion availability does NOT surface as Claimable', () {
      // Defensive guard: an id collision between a relic and an
      // availability node should never flip the relic to Claimable.
      final inventory = service.build(
        catalog: catalog,
        unlocked: const {},
        revealResults: revealMap({
          relic.id: CosmeticRevealResult(
            cosmeticId: relic.id,
            state: CosmeticRevealState.visibleLocked,
          ),
        }),
        claimableNodeIds: {relic.id},
        evaluatedAt: stamp,
      );

      final lifecycle = inventory.byIdString(relic.id)!.lifecycle;
      expect(lifecycle, isA<CosmeticTeased>());
    });

    test('partial reveal → CosmeticTeased with progress + rows', () {
      final rows = [
        const CosmeticRevealConditionRow(
          conditionId: 'level_at_least_5',
          met: true,
        ),
        const CosmeticRevealConditionRow(
          conditionId: 'owns_relic_campfire_spark',
          met: false,
        ),
      ];
      final inventory = service.build(
        catalog: catalog,
        unlocked: const {},
        revealResults: revealMap({
          companion.id: CosmeticRevealResult(
            cosmeticId: companion.id,
            state: CosmeticRevealState.partial,
            satisfiedConditions: 1,
            totalConditions: 2,
            conditionRows: rows,
          ),
        }),
        claimableNodeIds: const {},
        evaluatedAt: stamp,
      );

      final lifecycle = inventory.byIdString(companion.id)!.lifecycle;
      expect(lifecycle, isA<CosmeticTeased>());
      lifecycle as CosmeticTeased;
      expect(lifecycle.satisfiedConditions, 1);
      expect(lifecycle.totalConditions, 2);
      expect(lifecycle.hasProgress, isTrue);
      expect(lifecycle.conditionRows, rows);
    });

    test('visibleLocked → CosmeticTeased without progress', () {
      final inventory = service.build(
        catalog: catalog,
        unlocked: const {},
        revealResults: revealMap({
          frame.id: CosmeticRevealResult(
            cosmeticId: frame.id,
            state: CosmeticRevealState.visibleLocked,
          ),
        }),
        claimableNodeIds: const {},
        evaluatedAt: stamp,
      );

      final lifecycle = inventory.byIdString(frame.id)!.lifecycle;
      expect(lifecycle, isA<CosmeticTeased>());
      lifecycle as CosmeticTeased;
      expect(lifecycle.hasProgress, isFalse);
      expect(lifecycle.satisfiedConditions, 0);
      expect(lifecycle.totalConditions, 0);
    });

    test('hidden reveal → CosmeticHidden', () {
      final inventory = service.build(
        catalog: catalog,
        unlocked: const {},
        revealResults: revealMap({
          frame.id: CosmeticRevealResult(
            cosmeticId: frame.id,
            state: CosmeticRevealState.hidden,
          ),
        }),
        claimableNodeIds: const {},
        evaluatedAt: stamp,
      );

      expect(
        inventory.byIdString(frame.id)!.lifecycle,
        isA<CosmeticHidden>(),
      );
    });

    test('precedence: Owned wins over Claimable + Teased', () {
      // Companion is both unlocked AND in available nodes (rare race
      // window, but the precedence rule must be deterministic).
      final inventory = service.build(
        catalog: catalog,
        unlocked: {
          companion.id: UnlockedCosmetic(
            cosmeticId: companion.id,
            unlockedAt: stamp,
            sourceType: 'manual',
          ),
        },
        revealResults: revealMap({
          companion.id: CosmeticRevealResult(
            cosmeticId: companion.id,
            state: CosmeticRevealState.partial,
            satisfiedConditions: 1,
            totalConditions: 3,
          ),
        }),
        claimableNodeIds: {companion.id},
        evaluatedAt: stamp,
      );

      expect(
        inventory.byIdString(companion.id)!.lifecycle,
        isA<CosmeticOwned>(),
      );
    });

    test('Inventory partitions: owned + claimable + teased + hidden = all',
        () {
      final inventory = service.build(
        catalog: catalog,
        unlocked: {
          frame.id: UnlockedCosmetic(
            cosmeticId: frame.id,
            unlockedAt: stamp,
          ),
        },
        revealResults: revealMap({
          companion.id: CosmeticRevealResult(
            cosmeticId: companion.id,
            state: CosmeticRevealState.partial,
            satisfiedConditions: 1,
            totalConditions: 2,
          ),
          relic.id: CosmeticRevealResult(
            cosmeticId: relic.id,
            state: CosmeticRevealState.visibleLocked,
          ),
        }),
        claimableNodeIds: const {},
        evaluatedAt: stamp,
      );

      final sum = inventory.owned.length +
          inventory.claimable.length +
          inventory.teased.length +
          inventory.hidden.length;
      expect(sum, inventory.length);
      expect(inventory.length, catalog.enabled.length);
    });

    test('Owned → unlock event transition mirrors Inventory', () {
      // Simulates the happy-path transition: Hidden → Teased(partial) →
      // Claimable → Owned via three successive builds.
      final results = <PlayerCosmeticLifecycle>[];

      // 1. No progression data yet → defaults to Hidden.
      results.add(
        service
            .build(
              catalog: catalog,
              unlocked: const {},
              revealResults: revealMap(const {}),
              claimableNodeIds: const {},
              evaluatedAt: stamp,
            )
            .byIdString(companion.id)!
            .lifecycle,
      );

      // 2. Partial progress lands → Teased.
      results.add(
        service
            .build(
              catalog: catalog,
              unlocked: const {},
              revealResults: revealMap({
                companion.id: CosmeticRevealResult(
                  cosmeticId: companion.id,
                  state: CosmeticRevealState.partial,
                  satisfiedConditions: 1,
                  totalConditions: 2,
                ),
              }),
              claimableNodeIds: const {},
              evaluatedAt: stamp,
            )
            .byIdString(companion.id)!
            .lifecycle,
      );

      // 3. Engine fires availability → Claimable (rows still attached
      //    so the sheet can render the checklist alongside the CTA).
      results.add(
        service
            .build(
              catalog: catalog,
              unlocked: const {},
              revealResults: revealMap({
                companion.id: CosmeticRevealResult(
                  cosmeticId: companion.id,
                  state: CosmeticRevealState.partial,
                  satisfiedConditions: 2,
                  totalConditions: 2,
                ),
              }),
              claimableNodeIds: {companion.id},
              evaluatedAt: stamp,
            )
            .byIdString(companion.id)!
            .lifecycle,
      );

      // 4. Player claims → Owned.
      results.add(
        service
            .build(
              catalog: catalog,
              unlocked: {
                companion.id: UnlockedCosmetic(
                  cosmeticId: companion.id,
                  unlockedAt: stamp,
                  sourceType: 'progression',
                ),
              },
              revealResults: revealMap(const {}),
              claimableNodeIds: const {},
              evaluatedAt: stamp,
            )
            .byIdString(companion.id)!
            .lifecycle,
      );

      expect(results[0], isA<CosmeticHidden>());
      expect(results[1], isA<CosmeticTeased>());
      expect(results[2], isA<CosmeticClaimable>());
      expect(results[3], isA<CosmeticOwned>());
    });
  });

  group('lifecycle helpers (proposal Â§4.3)', () {
    test('hidesIdentity: only Companion + not Owned', () {
      expect(hidesIdentity(companion, const CosmeticHidden()), isTrue);
      expect(
        hidesIdentity(
          companion,
          const CosmeticTeased(satisfiedConditions: 1, totalConditions: 2),
        ),
        isTrue,
      );
      expect(
        hidesIdentity(companion, const CosmeticClaimable()),
        isTrue,
      );
      expect(
        hidesIdentity(
          companion,
          CosmeticOwned(unlockedAt: stamp),
        ),
        isFalse,
      );
      // Non-companion cosmetics never hide their identity.
      expect(hidesIdentity(frame, const CosmeticHidden()), isFalse);
      expect(hidesIdentity(relic, const CosmeticHidden()), isFalse);
    });

    test('showsChecklist: false only for Hidden', () {
      expect(showsChecklist(const CosmeticHidden()), isFalse);
      expect(showsChecklist(const CosmeticTeased()), isTrue);
      expect(showsChecklist(const CosmeticClaimable()), isTrue);
      expect(showsChecklist(CosmeticOwned(unlockedAt: stamp)), isTrue);
    });
  });

  group('Inventory accessors', () {
    test('empty sentinel returns empty iterables', () {
      expect(Inventory.empty.length, 0);
      expect(Inventory.empty.isEmpty, isTrue);
      expect(Inventory.empty.all, isEmpty);
      expect(Inventory.empty.byIdString('anything'), isNull);
      expect(Inventory.empty.byId(const CosmeticId('anything')), isNull);
    });

    test('among() preserves caller-provided id order', () {
      final inventory = service.build(
        catalog: catalog,
        unlocked: const {},
        revealResults: revealMap(const {}),
        claimableNodeIds: const {},
        evaluatedAt: stamp,
      );
      final ids = [
        CosmeticId(companion.id),
        CosmeticId(frame.id),
        CosmeticId(relic.id),
      ];
      final picked = inventory.among(ids).toList();
      expect(picked.map((p) => p.id.toString()).toList(),
          ids.map((i) => i.toString()).toList());
    });
  });
}
