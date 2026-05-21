import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/application/food_trigger_service.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';
import 'package:forgetrack/features/nutrition/domain/calorie_entry.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';

// Pinned Cosmetic id used across the tests below. Synthesized so the
// tests don't depend on the real catalog row that may move sortOrder
// / asset paths between commits.
const _kTestCompanionId = CosmeticId('companion_test_monster');

Companion _companion({FoodTriggerReward? trigger}) {
  return Companion(
    id: _kTestCompanionId,
    rarity: Rarity.mythic,
    region: CosmeticRegion.neutral,
    name: (_) => 'Test',
    description: (_) => 'Test',
    foodTrigger: trigger,
  );
}

CalorieEntry _entry(String foodName) {
  return CalorieEntry(
    id: 'id-$foodName',
    date: DateTime(2026, 5, 21, 12),
    meal: MealType.svacina,
    food: FoodItem(name: foodName, kcalPer100g: 50),
    grams: 100,
  );
}

void main() {
  group('FoodKeywordTrigger', () {
    test('case-insensitive substring match', () {
      const trigger = FoodKeywordTrigger(
        keywords: ['monster'],
        perEntryXp: 25,
        perDayMaxXp: 75,
      );

      expect(trigger.matchesEntry('Monster Energy Ultra Red'), isTrue);
      expect(trigger.matchesEntry('monsterka'), isTrue);
      expect(trigger.matchesEntry('Red Bull'), isFalse);
      expect(trigger.matchesEntry(''), isFalse);
    });

    test('any keyword matches (OR semantics)', () {
      const trigger = FoodKeywordTrigger(
        keywords: ['mléko', 'milk'],
        perEntryXp: 10,
        perDayMaxXp: 30,
      );

      expect(trigger.matchesEntry('Polotučné mléko 1.5%'), isTrue);
      expect(trigger.matchesEntry('Almond milk'), isTrue);
      expect(trigger.matchesEntry('Voda'), isFalse);
    });
  });

  group('FoodTriggerService.evaluate', () {
    const service = FoodTriggerService();
    const trigger = FoodKeywordTrigger(
      keywords: ['monster'],
      perEntryXp: 25,
      perDayMaxXp: 75,
    );

    test('returns null when companion has no trigger', () {
      final snap = service.evaluate(
        companion: _companion(),
        todayLog: [_entry('Monster Energy')],
        alreadyClaimedXpToday: 0,
      );
      expect(snap, isNull);
    });

    test('no matches → zero claimable, snapshot still returned', () {
      final snap = service.evaluate(
        companion: _companion(trigger: trigger),
        todayLog: [_entry('Voda'), _entry('Kuřecí prsa')],
        alreadyClaimedXpToday: 0,
      );
      expect(snap, isNotNull);
      expect(snap!.matchedEntryCount, 0);
      expect(snap.grossXp, 0);
      expect(snap.claimableXp, 0);
      expect(snap.hasClaimable, isFalse);
    });

    test('per-entry XP grants linearly under cap', () {
      final snap = service.evaluate(
        companion: _companion(trigger: trigger),
        todayLog: [
          _entry('Monster Energy'),
          _entry('Voda'),
        ],
        alreadyClaimedXpToday: 0,
      );
      expect(snap!.matchedEntryCount, 1);
      expect(snap.grossXp, 25);
      expect(snap.claimableXp, 25);
      expect(snap.hasClaimable, isTrue);
      expect(snap.sampleEntryName, 'Monster Energy');
    });

    test('per-day cap clamps the gross', () {
      final snap = service.evaluate(
        companion: _companion(trigger: trigger),
        todayLog: List.generate(8, (i) => _entry('Monster $i')),
        alreadyClaimedXpToday: 0,
      );
      expect(snap!.matchedEntryCount, 8);
      expect(snap.grossXp, 200);
      expect(snap.claimableXp, 75); // cap
    });

    test('already-claimed subtracts from cap-adjusted total', () {
      final snap = service.evaluate(
        companion: _companion(trigger: trigger),
        todayLog: [
          _entry('Monster Energy'),
          _entry('Monster Ultra'),
          _entry('Monster Zero'),
        ],
        alreadyClaimedXpToday: 50,
      );
      // gross = 75, capped = 75, already claimed 50 → 25 claimable
      expect(snap!.claimableXp, 25);
      expect(snap.alreadyClaimedXp, 50);
    });

    test('over-claim (impossible in normal flow) clamps to zero', () {
      final snap = service.evaluate(
        companion: _companion(trigger: trigger),
        todayLog: [_entry('Monster Energy')],
        alreadyClaimedXpToday: 100,
      );
      expect(snap!.claimableXp, 0);
      expect(snap.hasClaimable, isFalse);
    });
  });
}
