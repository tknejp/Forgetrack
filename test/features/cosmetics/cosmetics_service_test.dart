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
        'frame_lvl10',
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
      await service.equip(uid, 'frame_lvl10');

      final result = await service.resetProgressionUnlocks(uid);

      expect(result.removedCount, 2);
      expect(result.state.unlocked.containsKey('frame_lvl10'), isFalse);
      expect(result.state.unlocked.containsKey('emblem_forest_mark'), isFalse);
      expect(result.state.unlocked.containsKey('frame_developer_tom'), isTrue);
      expect(result.state.equipped.frameId, isNull);
    });
  });
}
