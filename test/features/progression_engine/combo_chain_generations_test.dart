import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/progression/catalog/generation_suffix.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/catalog_validator.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/content/combo_content.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';

/// Combo chains are pre-allocated in [kComboGenerationCount]
/// generations to make the gameplay loop repeatable past chain 3 and
/// to keep the `combo_triple_victory_25/100` achievements reachable.
/// These tests pin the structural invariants that make that work.
void main() {
  group('combo chain pre-allocated generations', () {
    final nodes = comboNodes();
    final byId = {for (final n in nodes) n.id: n};

    test('emits kComboGenerationCount generations × 13 nodes per chain set',
        () {
      // 4 + 4 + 5 = 13 step/finale nodes per generation across the
      // three chains (balanced, recovery, nutrition).
      expect(nodes.length, kComboGenerationCount * 13);
    });

    test('generation 1 keeps canonical (unsuffixed) ids', () {
      expect(byId.containsKey('combo_balanced_step_1'), isTrue);
      expect(byId.containsKey('combo_nutrition_finale'), isTrue);
      // No suffix means generation 1 (back-compat for existing ledger
      // events recorded before pre-allocation landed).
      expect(generationOf('combo_balanced_step_1'), 1);
    });

    test('generations 2..N use @<gen> suffix on ids', () {
      expect(byId.containsKey('combo_balanced_step_1@2'), isTrue);
      expect(byId.containsKey('combo_balanced_step_1@$kComboGenerationCount'),
          isTrue);
      expect(generationOf('combo_balanced_step_1@7'), 7);
      expect(templateIdOf('combo_balanced_step_1@7'), 'combo_balanced_step_1');
    });

    test('intra-generation chain prereqs reference the same generation', () {
      final step2Gen3 = byId['combo_balanced_step_2@3']! as Quest;
      expect(step2Gen3.prerequisiteNodeIds, ['combo_balanced_step_1@3']);

      final recoveryStep1Gen3 = byId['combo_recovery_step_1@3']! as Quest;
      // Chain 2 starts after chain 1 finale of the same generation.
      expect(recoveryStep1Gen3.prerequisiteNodeIds,
          ['combo_balanced_finale@3']);
    });

    test('gen N chain 1 step 1 prereqs gen (N-1) chain 3 finale (loop closure)',
        () {
      // Generation 1 starts unlocked — no predecessor.
      final gen1Start = byId['combo_balanced_step_1']! as Quest;
      expect(gen1Start.prerequisiteNodeIds, isEmpty);

      // Generation 2's first step prereqs generation 1's last finale.
      final gen2Start = byId['combo_balanced_step_1@2']! as Quest;
      expect(gen2Start.prerequisiteNodeIds, ['combo_nutrition_finale']);

      // Generation 5's first step prereqs generation 4's last finale.
      final gen5Start = byId['combo_balanced_step_1@5']! as Quest;
      expect(gen5Start.prerequisiteNodeIds, ['combo_nutrition_finale@4']);
    });

    test('chainId is suffixed per generation so the chain renderer treats '
        'each generation as its own bucket', () {
      final gen1 = byId['combo_balanced_step_1']! as Quest;
      final gen2 = byId['combo_balanced_step_1@2']! as Quest;
      expect(gen1.chainId, 'combo_balanced');
      expect(gen2.chainId, 'combo_balanced@2');
    });

    test('objectiveId is suffixed per generation so per-step objectives '
        'are once-and-done per generation', () {
      final gen1 = byId['combo_balanced_step_1']! as Quest;
      final gen3 = byId['combo_balanced_step_1@3']! as Quest;
      expect(gen1.objectiveId, 'combo_balanced_step_1_obj');
      expect(gen3.objectiveId, 'combo_balanced_step_1_obj@3');
    });

    test('every gen objective is in the objective catalog '
        '(no dangling node→objective refs)', () {
      final knownObjectiveIds = {
        for (final o in const ObjectiveCatalog().build()) o.id
      };
      for (final node in nodes) {
        if (node is Quest) {
          expect(knownObjectiveIds.contains(node.objectiveId.raw), isTrue,
              reason: 'Missing objective: ${node.objectiveId.raw}');
        }
      }
    });

    test('catalog validator finds no errors on the full pre-allocated catalog',
        () {
      // The shipped catalog has pre-existing **warnings** (manual-claim
      // nodes without lockedHintKey) we deliberately don't gate on
      // here. The contract: pre-allocating N generations must not
      // introduce any error-severity issue — no duplicate ids, no
      // missing cross-gen objective refs, no dangling NodeCompleted
      // unlock conditions.
      final errors = const CatalogValidator()
          .validate()
          .where((i) => i.severity == CatalogValidationSeverity.error)
          .toList();
      expect(errors, isEmpty,
          reason: 'Catalog validator surfaced errors:\n${errors.join('\n')}');
    });

    test('tripleComboNodeIds stays at template form (rolls up via evaluator)',
        () {
      // The metric in meta_content.dart authors **template** ids;
      // the evaluator's LifetimeCompletionsAmongMetric matches per
      // template, so we never enumerate `@N` variants here.
      for (final id in tripleComboNodeIds) {
        expect(id.contains(kGenerationSuffixSeparator), isFalse,
            reason: 'tripleComboNodeIds must list template ids only.');
        // And each template id must exist in generation 1 of the
        // catalog so the metric remains anchored to real nodes.
        expect(byId.containsKey(id.toString()), isTrue);
      }
    });

    test('loop closure points at the LAST chain finale of the prior generation '
        '(future-proof when chains are added)', () {
      // The cross-generation loop closure (`balancedStep1Prereqs` in
      // combo_content.dart) hardcodes a single chain id alias as
      // "the last chain in the loop". When a chain 4+ gets added,
      // forgetting to update that alias would silently shorten the
      // loop — players would skip the new chain on every repeat.
      //
      // This test derives "the last chain" from gen 1's structure
      // instead of hardcoding the chain id, so it stays correct
      // regardless of how many chains live in combo_content.dart.

      // Group gen 1 nodes by chainId and find each chain's finale
      // (last node by chainOrder) and first step (chainOrder 0).
      final gen1Nodes = nodes
          .whereType<Quest>()
          .where((q) => generationOf(q.id) == 1)
          .toList();
      final byChain = <String, List<Quest>>{};
      for (final q in gen1Nodes) {
        byChain.putIfAbsent(q.chainId!, () => []).add(q);
      }

      final firstStepByChain = <String, Quest>{};
      final finaleByChain = <String, Quest>{};
      for (final entry in byChain.entries) {
        final ordered = [...entry.value]
          ..sort((a, b) => (a.chainOrder ?? 0).compareTo(b.chainOrder ?? 0));
        firstStepByChain[entry.key] = ordered.first;
        finaleByChain[entry.key] = ordered.last;
      }

      // The "last chain" is the one whose finale id is not referenced
      // as a prerequisite by any other chain's first step within the
      // same generation. (Mid-loop chains feed the next chain; the
      // tail of the loop has no in-gen successor.)
      final finalesReferencedByOtherFirstSteps = <String>{};
      for (final firstStep in firstStepByChain.values) {
        finalesReferencedByOtherFirstSteps.addAll(
          firstStep.prerequisiteNodeIds.map((p) => p.toString()),
        );
      }
      final lastChainEntry = finaleByChain.entries.firstWhere(
        (e) => !finalesReferencedByOtherFirstSteps.contains(e.value.id),
        orElse: () => throw StateError(
          'Could not find a chain whose gen 1 finale is unreferenced — '
          'either the loop has no tail or two chains both terminate it.',
        ),
      );
      final lastChainFinaleGen1Id = lastChainEntry.value.id;

      // Gen 2 chain 1 step 1 must prereq exactly that gen 1 finale.
      final gen2Chain1Step1 = byId['combo_balanced_step_1@2']! as Quest;
      expect(
        gen2Chain1Step1.prerequisiteNodeIds.map((p) => p.toString()).toList(),
        [lastChainFinaleGen1Id],
        reason:
            'Loop closure must point at the last chain ($lastChainFinaleGen1Id) '
            'of the prior generation. If you just added a new chain, update '
            'the cross-generation prereq alias in combo_content.dart.',
      );

      // And the same shape holds at higher generations (gen 5 → gen 4 finale).
      final gen5Chain1Step1 = byId['combo_balanced_step_1@5']! as Quest;
      final gen4LastFinale = withGenerationSuffix(
        templateIdOf(lastChainFinaleGen1Id),
        4,
      );
      expect(
        gen5Chain1Step1.prerequisiteNodeIds.map((p) => p.toString()).toList(),
        [gen4LastFinale],
      );
    });
  });
}
