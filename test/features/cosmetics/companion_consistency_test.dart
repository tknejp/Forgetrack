import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rules.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/content/companions_content.dart';

/// The catalog [Companion] row is the single source of truth for every
/// companion's level + item gate, rarity, region, audit `sourceId`, and
/// display closures. `kCosmeticUnlockRules` (cosmetics grant pipeline) and
/// `companionNodes()` (progression engine availability) both derive their
/// shapes from the catalog by filtering + mapping.
///
/// These assertions are structural by construction today — but they stay
/// load-bearing as a guard against future edits that bypass the derivation
/// (e.g. appending a manual `CosmeticUnlockRule` literal next to the
/// filtered list, or hand-authoring an extra `CompanionAvailability`).
void main() {
  group('companion catalog → derivations consistency', () {
    test('every Companion row has consistent gate fields (level + items '
        'together, or neither)', () {
      final invalidRows = <String>[];
      for (final companion in CosmeticCatalog().companions) {
        final hasLevel = companion.levelGate != null;
        final hasItems = companion.requiredItems.isNotEmpty;

        // Either both present (progression-gated) or both absent (dev-only).
        // Mixed states are bugs: a level without items can't gate; items
        // without a level mean the engine never evaluates them.
        if (hasLevel != hasItems) {
          invalidRows.add(
            '${companion.id.value}: level=$hasLevel, items=$hasItems',
          );
        }
      }

      expect(
        invalidRows,
        isEmpty,
        reason: 'Companion rows must be either fully gated (level + items) '
            'or fully dev-only (neither). Mixed:\n'
            '  ${invalidRows.join('\n  ')}',
      );
    });

    test('kCosmeticUnlockRules matches the catalog companions with a '
        'level gate, 1:1', () {
      final gatedCompanionIds = CosmeticCatalog()
          .companions
          .where((c) => c.levelGate != null)
          .map((c) => c.id.value)
          .toSet();

      final ruleIds = kCosmeticUnlockRules
          .where((r) => r.sourceType == 'compound')
          .map((r) => r.cosmeticId)
          .toSet();

      expect(
        ruleIds,
        equals(gatedCompanionIds),
        reason: 'CosmeticUnlockRule set drifts from the catalog '
            "(gated-companions filter):\n"
            '  Only in catalog: ${gatedCompanionIds.difference(ruleIds)}\n'
            '  Only in rules: ${ruleIds.difference(gatedCompanionIds)}',
      );
    });

    test('companionNodes() matches the catalog companions with a level gate, '
        '1:1 — and every node\'s conditions echo the catalog row', () {
      final catalogById = <String, Companion>{
        for (final c in CosmeticCatalog().companions) c.id.value: c,
      };

      final nodes = companionNodes().whereType<CompanionAvailability>().toList();
      final gatedIds = catalogById.values
          .where((c) => c.levelGate != null)
          .map((c) => c.id.value)
          .toSet();
      final nodeIds = nodes.map((n) => n.companionId.value).toSet();

      expect(
        nodeIds,
        equals(gatedIds),
        reason: 'CompanionAvailability set drifts from the catalog '
            '(gated-companions filter):\n'
            '  Only in catalog: ${gatedIds.difference(nodeIds)}\n'
            '  Only in nodes: ${nodeIds.difference(gatedIds)}',
      );

      // For every node, conditions echo the catalog row by construction —
      // assert it so future refactors of `_toCompanionAvailabilityNode`
      // can't silently change what the engine evaluates.
      final fingerprintDrift = <String>[];
      for (final node in nodes) {
        final companion = catalogById[node.companionId.value]!;
        final expectedLevel = companion.levelGate!;
        final expectedItems = companion.requiredItems
            .map((id) => id.value)
            .toSet();
        final actualLevel = _readLevel(node.unlockConditions);
        final actualItems = _readItems(node.unlockConditions);

        if (actualLevel != expectedLevel ||
            !_setsEqual(actualItems, expectedItems)) {
          fingerprintDrift.add(
            '${companion.id.value}: '
            'expected level=$expectedLevel + items=$expectedItems, '
            'got level=$actualLevel + items=$actualItems',
          );
        }
        if (node.rarity != companion.rarity) {
          fingerprintDrift.add(
            '${companion.id.value}: node rarity=${node.rarity.name} '
            '!= catalog rarity=${companion.rarity.name}',
          );
        }
      }

      expect(
        fingerprintDrift,
        isEmpty,
        reason: 'CompanionAvailability nodes diverge from catalog rows:\n'
            '  ${fingerprintDrift.join('\n  ')}',
      );
    });
  });
}

int _readLevel(List<UnlockCondition> conditions) {
  for (final c in conditions) {
    if (c is LevelAtLeast) return c.level;
  }
  throw StateError('CompanionAvailability missing LevelAtLeast gate');
}

Set<String> _readItems(List<UnlockCondition> conditions) {
  final items = <String>{};
  for (final c in conditions) {
    if (c is OwnsCosmetic) items.add(c.cosmeticId.value);
  }
  return items;
}

bool _setsEqual(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
