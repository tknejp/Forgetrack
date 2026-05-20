import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/journal/journal_projection.dart';
import 'package:forgetrack/features/cosmetics/application/cosmetics_provider.dart';
import 'package:forgetrack/features/cosmetics/application/cosmetics_service.dart';
import 'package:forgetrack/features/cosmetics/data/in_memory_cosmetics_repository.dart';
import 'package:forgetrack/features/progression_engine/application/cosmetic_unlock_bridge.dart';

/// Tests Phase 20's [JournalProjection] contract on
/// [CosmeticUnlockBridge].
///
/// Mirrors the two rebuild scenarios the migration plan calls out:
///
/// * **Factory reset** — empty event stream → no cosmetics applied,
///   inventory stays empty. The bridge must not crash on an empty
///   ledger or report phantom unlocks.
/// * **Pull-and-merge** — historical reward grants from a merged
///   ledger get replayed into the local cosmetics inventory exactly
///   once. A second rebuild must be a true no-op (idempotency).
///
/// Together these reproduce the pre-Phase-20
/// `cosmetic_unlock_bridge.reapplyHistoricalCosmetics` semantics
/// bit-for-bit, so a regression in projection ordering or filtering
/// would surface here.
void main() {
  group('CosmeticUnlockBridge — JournalProjection', () {
    late InMemoryCosmeticsRepository repo;
    late CosmeticsService service;
    late CosmeticsProvider cosmetics;
    late CosmeticUnlockBridge bridge;

    setUp(() async {
      repo = InMemoryCosmeticsRepository();
      service = CosmeticsService(repository: repo);
      cosmetics = CosmeticsProvider(service: service);
      cosmetics.bindUser('user-1');
      // Wait for the initial load to settle so `cosmetics.state` is non-null.
      await Future<void>.delayed(Duration.zero);
      await cosmetics.refresh();

      bridge = CosmeticUnlockBridge();
      bridge.bindCosmetics(cosmetics);
    });

    test('factoryReset with empty events → 0 applied, inventory empty', () async {
      final applied = await bridge.rebuildFromJournal(
        events: const <JournalEvent>[],
        reason: RebuildFromJournalReason.factoryReset,
      );

      expect(applied, 0);
      expect(cosmetics.state!.unlocked, isEmpty);
    });

    test('pullAndMerge replays historical cosmetic grants into inventory',
        () async {
      final events = <JournalEvent>[
        RewardGrantEvent(
          eventKey: 'k1',
          timestamp: DateTime(2026, 1, 1),
          nodeId: ProgressionEntryId('achievement_first_steps'),
          rewardOrdinal: 0,
          rewardKind: RewardGrantKind.cosmetic,
          cosmeticId: CosmeticId('frame_wildwood'),
        ),
        RewardGrantEvent(
          eventKey: 'k2',
          timestamp: DateTime(2026, 1, 2),
          nodeId: ProgressionEntryId('companion_node'),
          rewardOrdinal: 0,
          rewardKind: RewardGrantKind.companionAvailability,
          companionId: CosmeticId('companion_forest_fox'),
        ),
        // XP grants must NOT trigger a cosmetic unlock.
        RewardGrantEvent(
          eventKey: 'k3',
          timestamp: DateTime(2026, 1, 3),
          nodeId: ProgressionEntryId('xp_node'),
          rewardOrdinal: 0,
          rewardKind: RewardGrantKind.xp,
          xpAmount: 50,
        ),
      ];

      final applied = await bridge.rebuildFromJournal(
        events: events,
        reason: RebuildFromJournalReason.pullAndMerge,
      );

      expect(applied, 2);
      expect(cosmetics.state!.unlocked.keys,
          containsAll(<String>['frame_wildwood', 'companion_forest_fox']));
    });

    test('rebuild is idempotent — second call applies 0 new unlocks',
        () async {
      final events = <JournalEvent>[
        RewardGrantEvent(
          eventKey: 'k1',
          timestamp: DateTime(2026, 1, 1),
          nodeId: ProgressionEntryId('achievement_first_steps'),
          rewardOrdinal: 0,
          rewardKind: RewardGrantKind.cosmetic,
          cosmeticId: CosmeticId('frame_wildwood'),
        ),
      ];

      final firstApplied = await bridge.rebuildFromJournal(
        events: events,
        reason: RebuildFromJournalReason.pullAndMerge,
      );
      final secondApplied = await bridge.rebuildFromJournal(
        events: events,
        reason: RebuildFromJournalReason.pullAndMerge,
      );

      expect(firstApplied, 1);
      expect(secondApplied, 0);
      expect(cosmetics.state!.unlocked.keys, contains('frame_wildwood'));
    });

    test('rebuildFromJournal without cosmetics binding is a safe no-op',
        () async {
      final unbound = CosmeticUnlockBridge();

      final applied = await unbound.rebuildFromJournal(
        events: <JournalEvent>[
          RewardGrantEvent(
            eventKey: 'k1',
            timestamp: DateTime(2026, 1, 1),
            nodeId: ProgressionEntryId('achievement_first_steps'),
            rewardOrdinal: 0,
            rewardKind: RewardGrantKind.cosmetic,
            cosmeticId: CosmeticId('frame_wildwood'),
          ),
        ],
        reason: RebuildFromJournalReason.devToolsWipe,
      );

      expect(applied, 0);
    });
  });
}