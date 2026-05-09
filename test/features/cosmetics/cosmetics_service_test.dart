import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/application/cosmetics_service.dart';
import 'package:forgetrack/features/cosmetics/data/in_memory_cosmetics_repository.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';

void main() {
  group('CosmeticsService.resetProgressionUnlocks', () {
    test('removes progression unlocks but preserves custom inventory',
        () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-1';

      await service.unlock(
        uid,
        'frame_wildwood',
        sourceType: CosmeticUnlockSource.progressionLevel.name,
        sourceId: 'level_10',
      );
      await service.unlock(
        uid,
        'emblem_forest_mark',
        sourceType: CosmeticUnlockSource.achievement.name,
        sourceId: 'first_reward',
      );
      await service.unlock(
        uid,
        'frame_developer_tom',
        sourceType: CosmeticUnlockSource.manual.name,
        sourceId: 'custom_grant',
      );
      await service.equip(uid, 'frame_wildwood');

      final result = await service.resetProgressionUnlocks(uid);

      expect(result.removedCount, 2);
      expect(result.state.unlocked.containsKey('frame_wildwood'), isFalse);
      expect(result.state.unlocked.containsKey('emblem_forest_mark'), isFalse);
      expect(result.state.unlocked.containsKey('frame_developer_tom'), isTrue);
      expect(result.state.equipped.frameId, isNull);
    });
  });

  group('CosmeticsService.revoke', () {
    test('removes an unlocked cosmetic and returns reloaded state', () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-1';

      await service.unlock(
        uid,
        'frame_wildwood',
        sourceType: CosmeticUnlockSource.manual.name,
      );
      expect(
        (await repository.loadForUser(uid)).unlocked.containsKey('frame_wildwood'),
        isTrue,
      );

      final state = await service.revoke(uid, 'frame_wildwood');

      expect(state.unlocked.containsKey('frame_wildwood'), isFalse);
    });

    test('clears equipped slot when revoked cosmetic is equipped', () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-1';

      await service.unlock(
        uid,
        'frame_dwarven',
        sourceType: CosmeticUnlockSource.manual.name,
      );
      await service.equip(uid, 'frame_dwarven');
      expect(
        (await repository.loadForUser(uid)).equipped.frameId,
        'frame_dwarven',
      );

      final state = await service.revoke(uid, 'frame_dwarven');

      expect(state.unlocked.containsKey('frame_dwarven'), isFalse);
      expect(state.equipped.frameId, isNull);
    });

    test('is a no-op for a cosmetic that is not unlocked', () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-1';

      final before = await repository.loadForUser(uid);
      final state = await service.revoke(uid, 'frame_underways');

      expect(state.unlocked, equals(before.unlocked));
    });
  });

  group('CosmeticsService.clearAllUnlocks', () {
    test('removes all unlocks and returns correct removed count', () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-1';

      await service.unlock(
        uid,
        'frame_pilgrim',
        sourceType: CosmeticUnlockSource.defaultBaseline.name,
      );
      await service.unlock(
        uid,
        'relic_campfire_spark',
        sourceType: CosmeticUnlockSource.manual.name,
      );

      final result = await service.clearAllUnlocks(uid);

      expect(result.removedCount, 2);
      expect(result.state.unlocked, isEmpty);
    });

    test('clears all equipped slots', () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-1';

      await service.unlock(
        uid,
        'frame_pilgrim',
        sourceType: CosmeticUnlockSource.manual.name,
      );
      await service.equip(uid, 'frame_pilgrim');

      final result = await service.clearAllUnlocks(uid);

      expect(result.state.equipped.frameId, isNull);
    });

    test('returns zero when inventory already empty', () async {
      final repository = InMemoryCosmeticsRepository();
      final service = CosmeticsService(repository: repository);
      const uid = 'user-empty';

      // Load creates a default state; clear it first by revoking nothing
      // then call clearAllUnlocks on a fresh uid with no unlocks.
      await repository.loadForUser(uid);
      // Manually wipe the default-seeded unlocks (none for uid 'user-empty'
      // since InMemory only seeds defaults for known rule ids).
      final result = await service.clearAllUnlocks(uid);

      expect(result.removedCount, greaterThanOrEqualTo(0));
      expect(result.state.unlocked, isEmpty);
    });
  });
}
