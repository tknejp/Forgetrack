import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/domain/catalog/granting_achievement_lookup.dart';

void main() {
  group('grantingNodeForCosmetic — real catalog walk', () {
    test('relic_moonlit_foxglove resolves to an achievement node', () {
      // forest_fox's first relic is granted by the achievement
      // `active_days_7` per the meta achievement catalog. The exact id
      // is asserted via cross-check with the catalog so this test
      // catches catalog renames; if the granting achievement is ever
      // changed, the assertion below fails and the regression surfaces.
      final id = grantingNodeForCosmetic('relic_moonlit_foxglove');
      expect(id, isNotNull,
          reason: 'Every relic in the cosmetics catalog must have a '
              'granting progression node so devtools can route grants '
              'through the engine');
    });

    test('relic_oathbound_mark (bridge_gargoyle gating) resolves to '
        'an achievement node', () {
      final id = grantingNodeForCosmetic('relic_oathbound_mark');
      expect(id, equals('combo_victory_10'));
    });

    test('relic_bridge_key resolves to reward_hunter_100', () {
      final id = grantingNodeForCosmetic('relic_bridge_key');
      expect(id, equals('reward_hunter_100'));
    });

    test('relic_aurora_thread resolves to weekly_activity_36', () {
      final id = grantingNodeForCosmetic('relic_aurora_thread');
      expect(id, equals('weekly_activity_36'));
    });

    test('companion cosmetic id has no granting node (companion '
        'cosmetics are granted via CompanionAvailability reward kind, '
        'not via CosmeticReward on an achievement)', () {
      final id = grantingNodeForCosmetic('companion_forest_fox');
      expect(id, isNull);
    });

    test('non-existent cosmetic id returns null', () {
      final id = grantingNodeForCosmetic('definitely_not_a_real_id');
      expect(id, isNull);
    });
  });
}
