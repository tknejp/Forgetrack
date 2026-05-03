import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_evaluator.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rules.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_snapshot.dart';

CosmeticUnlockSnapshot _snap({
  int level = 1,
  Set<String> owned = const <String>{},
}) {
  return CosmeticUnlockSnapshot(
    level: level,
    activeDaysCount: 0,
    completedDailyQuests: 0,
    completedWeeklyQuests: 0,
    totalCompletedQuests: 0,
    firstDailyQuestEver: false,
    firstWeeklyQuestEver: false,
    perfectDaysCount: 0,
    perfectWeeksCount: 0,
    ownedCosmeticIds: owned,
  );
}

Set<String> _unlock(CosmeticUnlockSnapshot snap, [Set<String>? alreadyOwned]) {
  final evaluator = CosmeticUnlockEvaluator(kCosmeticUnlockRules);
  return evaluator
      .evaluate(snap, alreadyOwned ?? const <String>{})
      .map((t) => t.cosmeticId)
      .toSet();
}

void main() {
  group('companion_ember_sprite (level 5, campfire_spark, warm_kindling)', () {
    const relics = {'relic_campfire_spark', 'relic_warm_kindling'};

    test('unlocks with level 5 and both relics', () {
      expect(
        _unlock(_snap(level: 5, owned: relics)),
        contains('companion_ember_sprite'),
      );
    });

    test('does not unlock when missing relic_warm_kindling', () {
      expect(
        _unlock(_snap(level: 5, owned: {'relic_campfire_spark'})),
        isNot(contains('companion_ember_sprite')),
      );
    });

    test('does not unlock below level 5', () {
      expect(
        _unlock(_snap(level: 4, owned: relics)),
        isNot(contains('companion_ember_sprite')),
      );
    });
  });

  group('companion_forest_fox (level 10, moonlit_foxglove, ancient_root)', () {
    const relics = {'relic_moonlit_foxglove', 'relic_ancient_root'};

    test('unlocks with level 10 and both relics', () {
      expect(
        _unlock(_snap(level: 10, owned: relics)),
        contains('companion_forest_fox'),
      );
    });

    test('does not unlock when missing relic_ancient_root', () {
      expect(
        _unlock(_snap(level: 10, owned: {'relic_moonlit_foxglove'})),
        isNot(contains('companion_forest_fox')),
      );
    });

    test('does not unlock below level 10', () {
      expect(
        _unlock(_snap(level: 9, owned: relics)),
        isNot(contains('companion_forest_fox')),
      );
    });
  });

  group('companion_ruin_raven (level 25, ruin_seal, ashen_omen)', () {
    const relics = {'relic_ruin_seal', 'relic_ashen_omen'};

    test('unlocks with level 25 and both relics', () {
      expect(
        _unlock(_snap(level: 25, owned: relics)),
        contains('companion_ruin_raven'),
      );
    });

    test('does not unlock when missing relic_ruin_seal', () {
      expect(
        _unlock(_snap(level: 25, owned: {'relic_ashen_omen'})),
        isNot(contains('companion_ruin_raven')),
      );
    });

    test('does not unlock below level 25', () {
      expect(
        _unlock(_snap(level: 24, owned: relics)),
        isNot(contains('companion_ruin_raven')),
      );
    });
  });

  group('companion_lantern_golem (level 45, deep_ember_core, miners_lantern)',
      () {
    const relics = {'relic_deep_ember_core', 'relic_miners_lantern'};

    test('unlocks with level 45 and both relics', () {
      expect(
        _unlock(_snap(level: 45, owned: relics)),
        contains('companion_lantern_golem'),
      );
    });

    test('does not unlock when missing relic_deep_ember_core', () {
      expect(
        _unlock(_snap(level: 45, owned: {'relic_miners_lantern'})),
        isNot(contains('companion_lantern_golem')),
      );
    });

    test('does not unlock below level 45', () {
      expect(
        _unlock(_snap(level: 44, owned: relics)),
        isNot(contains('companion_lantern_golem')),
      );
    });
  });

  group('companion_ice_wisp (level 65, polar_lantern, frozen_lake_heart)', () {
    const relics = {'relic_polar_lantern', 'relic_frozen_lake_heart'};

    test('unlocks with level 65 and both relics', () {
      expect(
        _unlock(_snap(level: 65, owned: relics)),
        contains('companion_ice_wisp'),
      );
    });

    test('does not unlock when missing relic_polar_lantern', () {
      expect(
        _unlock(_snap(level: 65, owned: {'relic_frozen_lake_heart'})),
        isNot(contains('companion_ice_wisp')),
      );
    });

    test('does not unlock below level 65', () {
      expect(
        _unlock(_snap(level: 64, owned: relics)),
        isNot(contains('companion_ice_wisp')),
      );
    });
  });

  group(
      'companion_mountain_gryphon (level 85, summit_feather, stormcrest_plume)',
      () {
    const relics = {'relic_summit_feather', 'relic_stormcrest_plume'};

    test('unlocks with level 85 and both relics', () {
      expect(
        _unlock(_snap(level: 85, owned: relics)),
        contains('companion_mountain_gryphon'),
      );
    });

    test('does not unlock when missing relic_stormcrest_plume', () {
      expect(
        _unlock(_snap(level: 85, owned: {'relic_summit_feather'})),
        isNot(contains('companion_mountain_gryphon')),
      );
    });

    test('does not unlock below level 85', () {
      expect(
        _unlock(_snap(level: 84, owned: relics)),
        isNot(contains('companion_mountain_gryphon')),
      );
    });
  });

  group('companion_dragonling (level 100, dragon_scale, dragonrock_heart)', () {
    const relics = {'relic_dragon_scale', 'relic_dragonrock_heart'};

    test('unlocks with level 100 and both relics', () {
      expect(
        _unlock(_snap(level: 100, owned: relics)),
        contains('companion_dragonling'),
      );
    });

    test('does not unlock when missing relic_dragonrock_heart', () {
      expect(
        _unlock(_snap(level: 100, owned: {'relic_dragon_scale'})),
        isNot(contains('companion_dragonling')),
      );
    });

    test('does not unlock with legacy relic_dragonrock_crown instead', () {
      expect(
        _unlock(_snap(level: 100, owned: {'relic_dragonrock_crown'})),
        isNot(contains('companion_dragonling')),
      );
    });

    test('does not unlock below level 100', () {
      expect(
        _unlock(_snap(level: 99, owned: relics)),
        isNot(contains('companion_dragonling')),
      );
    });
  });

  group('Idempotency', () {
    test('companion already owned is not re-granted', () {
      const relics = {'relic_dragon_scale', 'relic_dragonrock_heart'};
      final snap = _snap(level: 100, owned: relics);

      expect(_unlock(snap), contains('companion_dragonling'));
      expect(
        _unlock(snap, {'companion_dragonling'}),
        isNot(contains('companion_dragonling')),
      );
    });

    test('relics remain in owned set after companion unlock (non-destructive)',
        () {
      const relics = {'relic_campfire_spark', 'relic_warm_kindling'};
      final snap = _snap(level: 5, owned: relics);
      final granted = _unlock(snap);

      expect(granted, contains('companion_ember_sprite'));
      // Relics are still in the snapshot — not consumed.
      expect(snap.ownedCosmeticIds, containsAll(relics));
    });
  });

  group('Fixed-point simulation (multi-pass chain)', () {
    // Simulates the dispatcher's Tier-2 fixed-point loop:
    //   pass 1: relics granted via Tier-1 (mocked by pre-populating owned)
    //   pass 2: evaluator runs with relics in owned → companion fires
    //   pass 3: evaluator runs with companion in owned → no new unlocks
    test('relic grant in pass 1 causes companion unlock in pass 2', () {
      final evaluator = CosmeticUnlockEvaluator(kCosmeticUnlockRules);

      // After Tier-1: player at level 5 now owns both campfire relics.
      var owned = <String>{'relic_campfire_spark', 'relic_warm_kindling'};
      final snap = _snap(level: 5, owned: owned);

      // Pass 2 — companion fires.
      final pass2 = evaluator.evaluate(snap, owned);
      expect(pass2.map((t) => t.cosmeticId), contains('companion_ember_sprite'));

      // Absorb the new unlock and re-run (pass 3).
      owned = owned.union(pass2.map((t) => t.cosmeticId).toSet());
      final snapWithCompanion = _snap(level: 5, owned: owned);
      final pass3 = evaluator.evaluate(snapWithCompanion, owned);
      expect(pass3, isEmpty);
    });
  });

  group('Progress hook', () {
    test('progressFor returns 1/3 when only level condition met', () {
      final evaluator = CosmeticUnlockEvaluator(kCosmeticUnlockRules);
      final progress = evaluator.progressFor(
        'companion_dragonling',
        _snap(level: 100),
      );
      expect(progress, isNotNull);
      expect(progress!.satisfied, 1);
      expect(progress.total, 3);
    });

    test('progressFor returns 3/3 when all conditions met', () {
      final evaluator = CosmeticUnlockEvaluator(kCosmeticUnlockRules);
      final progress = evaluator.progressFor(
        'companion_dragonling',
        _snap(
          level: 100,
          owned: {'relic_dragon_scale', 'relic_dragonrock_heart'},
        ),
      );
      expect(progress!.satisfied, 3);
      expect(progress.total, 3);
    });
  });

  group('Legacy ID verification', () {
    final legacyIds = {
      'relic_old_compass',
      'relic_pilgrim_cloak',
      'relic_old_gate_key',
      'relic_dragon_crown',
      'relic_dragonrock_crown',
    };

    test('no active rule references legacy relic IDs', () {
      for (final rule in kCosmeticUnlockRules) {
        expect(legacyIds, isNot(contains(rule.cosmeticId)));
        for (final cond in rule.conditions) {
          for (final legacyId in legacyIds) {
            expect(
              cond.id,
              isNot(contains(legacyId)),
              reason:
                  'Rule ${rule.cosmeticId} has condition referencing $legacyId',
            );
          }
        }
      }
    });
  });
}
