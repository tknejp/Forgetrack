import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_evaluator.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rules.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_snapshot.dart';

CosmeticUnlockSnapshot _baseSnapshot({
  int level = 1,
  int activeDays = 0,
  int dailyQuests = 0,
  int weeklyQuests = 0,
  int totalQuests = 0,
  int perfectDays = 0,
  int perfectWeeks = 0,
  Set<String> owned = const <String>{},
}) {
  return CosmeticUnlockSnapshot(
    level: level,
    activeDaysCount: activeDays,
    completedDailyQuests: dailyQuests,
    completedWeeklyQuests: weeklyQuests,
    totalCompletedQuests: totalQuests,
    firstDailyQuestEver: dailyQuests >= 1,
    firstWeeklyQuestEver: weeklyQuests >= 1,
    perfectDaysCount: perfectDays,
    perfectWeeksCount: perfectWeeks,
    ownedCosmeticIds: owned,
  );
}

void main() {
  final evaluator = CosmeticUnlockEvaluator(kCosmeticUnlockRules);

  group('Tier-2 single-condition rules', () {
    test('first daily quest unlocks relic_campfire_spark', () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(dailyQuests: 1),
        const <String>{},
      );
      expect(
        tuples.map((t) => t.cosmeticId),
        contains('relic_campfire_spark'),
      );
    });

    test('first weekly quest unlocks relic_ruin_seal', () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(weeklyQuests: 1),
        const <String>{},
      );
      expect(tuples.map((t) => t.cosmeticId), contains('relic_ruin_seal'));
    });

    test('50 total quests unlocks relic_miners_lantern', () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(totalQuests: 50),
        const <String>{},
      );
      expect(
        tuples.map((t) => t.cosmeticId),
        contains('relic_miners_lantern'),
      );
    });

    test('250 total quests unlocks relic_dragon_crown', () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(totalQuests: 250),
        const <String>{},
      );
      expect(tuples.map((t) => t.cosmeticId), contains('relic_dragon_crown'));
    });
  });

  group('Compound rules', () {
    test(
        'companion_dragonling fires only when level == 100 AND owns dragonrock_crown',
        () {
      final without = evaluator.evaluate(
        _baseSnapshot(level: 100),
        const <String>{},
      );
      expect(
        without.map((t) => t.cosmeticId),
        isNot(contains('companion_dragonling')),
      );

      final withRelic = evaluator.evaluate(
        _baseSnapshot(level: 100, owned: const {'relic_dragonrock_crown'}),
        const {'relic_dragonrock_crown'},
      );
      expect(
        withRelic.map((t) => t.cosmeticId),
        contains('companion_dragonling'),
      );
    });

    test('companion_ice_wisp requires both frost shard and frozen lake heart',
        () {
      final partial = evaluator.evaluate(
        _baseSnapshot(owned: const {'relic_frost_shard'}),
        const {'relic_frost_shard'},
      );
      expect(
        partial.map((t) => t.cosmeticId),
        isNot(contains('companion_ice_wisp')),
      );

      final both = evaluator.evaluate(
        _baseSnapshot(
          owned: const {'relic_frost_shard', 'relic_frozen_lake_heart'},
        ),
        const {'relic_frost_shard', 'relic_frozen_lake_heart'},
      );
      expect(
        both.map((t) => t.cosmeticId),
        contains('companion_ice_wisp'),
      );
    });

    test(
        'relic_dragonrock_crown requires level 100 AND 250 quests completed',
        () {
      final justLevel = evaluator.evaluate(
        _baseSnapshot(level: 100),
        const <String>{},
      );
      expect(
        justLevel.map((t) => t.cosmeticId),
        isNot(contains('relic_dragonrock_crown')),
      );

      final both = evaluator.evaluate(
        _baseSnapshot(level: 100, totalQuests: 250),
        const <String>{},
      );
      expect(
        both.map((t) => t.cosmeticId),
        contains('relic_dragonrock_crown'),
      );
    });
  });

  group('Idempotency', () {
    test('cosmetic already in alreadyOwned is filtered out', () {
      final first = evaluator.evaluate(
        _baseSnapshot(dailyQuests: 1),
        const <String>{},
      );
      expect(
        first.map((t) => t.cosmeticId),
        contains('relic_campfire_spark'),
      );

      final ownedIds = first.map((t) => t.cosmeticId).toSet();
      final second = evaluator.evaluate(
        _baseSnapshot(dailyQuests: 1),
        ownedIds,
      );
      expect(
        second.map((t) => t.cosmeticId),
        isNot(contains('relic_campfire_spark')),
      );
    });

    test(
        'OR-style rule (companion_ember_sprite) deduplicates to one tuple per pass',
        () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(activeDays: 7, dailyQuests: 3),
        const <String>{},
      );
      final emberTuples =
          tuples.where((t) => t.cosmeticId == 'companion_ember_sprite');
      expect(emberTuples, hasLength(1));
    });
  });

  group('Progress hook for future UI', () {
    test('progressFor returns satisfied/total for compound rules', () {
      final progress = evaluator.progressFor(
        'companion_dragonling',
        _baseSnapshot(level: 100),
      );
      expect(progress, isNotNull);
      expect(progress!.satisfied, 1);
      expect(progress.total, 2);
    });
  });

  group('Perfect-period placeholder is wired', () {
    test('frame_balance fires when perfectDaysCount >= 7', () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(perfectDays: 7),
        const <String>{},
      );
      expect(tuples.map((t) => t.cosmeticId), contains('frame_balance'));
    });

    test('frame_master_routine fires when perfectWeeksCount >= 12', () {
      final tuples = evaluator.evaluate(
        _baseSnapshot(perfectWeeks: 12),
        const <String>{},
      );
      expect(
        tuples.map((t) => t.cosmeticId),
        contains('frame_master_routine'),
      );
    });
  });
}
