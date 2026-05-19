// Phase 7 adapter contract pin for PlayerQuestCatalogService.
//
// The service is the bridge between the engine's per-evaluation
// `EngineQuestProgress` view-model list and the pure-domain
// `PlayerQuestCatalog`. It pulls the lifecycle through the Phase 6
// bridge getter (`EngineQuestProgress.lifecycle`), stamps the
// evaluation timestamp, and produces a catalog that downstream
// screens / future projections consume.
//
// These tests verify:
//   1. The service produces a catalog with the right size + entries.
//   2. Lifecycle is preserved through the projection â€” flag-derived
//      states on the input show up as the matching sealed subtypes
//      on the output.
//   3. evaluatedAt is stamped on every entry.
//   4. An empty input produces the empty sentinel-equivalent catalog.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_quest_lifecycle.dart';
import 'package:forgetrack/features/progression_engine/application/player_quest_catalog_service.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 5, 18, 12);

  EngineQuestProgress engineEntry({
    required String id,
    bool isCompleted = false,
    bool isAvailableForClaim = false,
    bool isLockedByConditions = false,
  }) {
    return EngineQuestProgress(
      node: DailyQuest(
        id: QuestId(id),
        titleKey: _titleStub,
        descriptionKey: _descStub,
        objectiveId: ObjectiveId('obj'),
        rewards: const [],
      ),
      actualValue: 3000,
      targetValue: 10000,
      progress: 0.3,
      isCompleted: isCompleted,
      isAvailableForClaim: isAvailableForClaim,
      baseXp: 100,
      previewXp: 230,
      domain: ProgressionDomain.steps,
      isLockedByConditions: isLockedByConditions,
    );
  }

  const service = PlayerQuestCatalogService();

  test('empty input produces an empty catalog', () {
    final catalog = service.build(
      questProgressEntries: const [],
      evaluatedAt: evaluatedAt,
    );
    expect(catalog.isEmpty, isTrue);
  });

  test('projects every input entry into a PlayerQuest keyed by QuestId', () {
    final catalog = service.build(
      questProgressEntries: [
        engineEntry(id: 'a'),
        engineEntry(id: 'b', isAvailableForClaim: true),
        engineEntry(id: 'c', isCompleted: true),
      ],
      evaluatedAt: evaluatedAt,
    );
    expect(catalog.length, 3);
    expect(catalog.byId(const QuestId('a')), isNotNull);
    expect(catalog.byId(const QuestId('b')), isNotNull);
    expect(catalog.byId(const QuestId('c')), isNotNull);
  });

  test('lifecycle bridge is preserved across the projection', () {
    final catalog = service.build(
      questProgressEntries: [
        engineEntry(id: 'locked', isLockedByConditions: true),
        engineEntry(id: 'available'),
        engineEntry(id: 'pending', isAvailableForClaim: true),
        engineEntry(id: 'claimed', isCompleted: true),
      ],
      evaluatedAt: evaluatedAt,
    );
    expect(catalog.byId(const QuestId('locked'))!.lifecycle,
        isA<QuestLocked>());
    expect(catalog.byId(const QuestId('available'))!.lifecycle,
        isA<QuestAvailable>());
    expect(catalog.byId(const QuestId('pending'))!.lifecycle,
        isA<QuestCompletedPendingClaim>());
    expect(catalog.byId(const QuestId('claimed'))!.lifecycle,
        isA<QuestClaimed>());
  });

  test('Available lifecycle carries the engine actual / target / progress', () {
    final catalog = service.build(
      questProgressEntries: [engineEntry(id: 'a')],
      evaluatedAt: evaluatedAt,
    );
    final lifecycle =
        catalog.byId(const QuestId('a'))!.lifecycle as QuestAvailable;
    expect(lifecycle.actual, 3000);
    expect(lifecycle.target, 10000);
    expect(lifecycle.progress, 0.3);
  });

  test('PendingClaim lifecycle carries previewXp = engine previewXp', () {
    final catalog = service.build(
      questProgressEntries: [
        engineEntry(id: 'p', isAvailableForClaim: true),
      ],
      evaluatedAt: evaluatedAt,
    );
    final lifecycle = catalog.byId(const QuestId('p'))!.lifecycle
        as QuestCompletedPendingClaim;
    expect(lifecycle.previewXp, 230);
  });

  test('Claimed lifecycle carries finalXp = engine previewXp (invariant)', () {
    final catalog = service.build(
      questProgressEntries: [engineEntry(id: 'c', isCompleted: true)],
      evaluatedAt: evaluatedAt,
    );
    final lifecycle =
        catalog.byId(const QuestId('c'))!.lifecycle as QuestClaimed;
    expect(lifecycle.finalXp, 230);
  });

  test('evaluatedAt is stamped on every PlayerQuest', () {
    final catalog = service.build(
      questProgressEntries: [
        engineEntry(id: 'a'),
        engineEntry(id: 'b', isCompleted: true),
      ],
      evaluatedAt: evaluatedAt,
    );
    for (final quest in catalog.all) {
      expect(quest.evaluatedAt, evaluatedAt);
    }
  });

  test('duplicate ids fold to the last occurrence (defensive contract)', () {
    final catalog = service.build(
      questProgressEntries: [
        engineEntry(id: 'a'),
        engineEntry(id: 'a', isCompleted: true),
      ],
      evaluatedAt: evaluatedAt,
    );
    expect(catalog.length, 1);
    expect(catalog.byId(const QuestId('a'))!.lifecycle, isA<QuestClaimed>());
  });
}

String _titleStub(Object? _) => 'q';
String _descStub(Object? _) => 'q-desc';
