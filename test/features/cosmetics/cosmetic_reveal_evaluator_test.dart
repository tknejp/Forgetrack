import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_reveal_evaluator.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_reveal_state.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rule.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rules.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_snapshot.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

CosmeticUnlockSnapshot _snapshot({
  int level = 0,
  int activeDays = 0,
  int dailyQuests = 0,
  int weeklyQuests = 0,
  int totalQuests = 0,
  bool firstDaily = false,
  bool firstWeekly = false,
  int perfectDays = 0,
  int perfectWeeks = 0,
  Set<String> owned = const {},
}) =>
    CosmeticUnlockSnapshot(
      level: level,
      activeDaysCount: activeDays,
      completedDailyQuests: dailyQuests,
      completedWeeklyQuests: weeklyQuests,
      totalCompletedQuests: totalQuests,
      firstDailyQuestEver: firstDaily,
      firstWeeklyQuestEver: firstWeekly,
      perfectDaysCount: perfectDays,
      perfectWeeksCount: perfectWeeks,
      ownedCosmeticIds: owned,
    );

Map<String, CosmeticRevealResult> _evaluate({
  List<CosmeticUnlockRule>? rules,
  CosmeticUnlockSnapshot? snapshot,
  Set<String> owned = const {},
}) {
  return CosmeticRevealEvaluator.evaluateAll(
    catalog: const CosmeticCatalog(),
    rules: rules ?? kCosmeticUnlockRules,
    snapshot: snapshot ?? _snapshot(owned: owned),
    ownedIds: owned,
  );
}

// ── tests ────────────────────────────────────────────────────────────────────

void main() {
  group('CosmeticRevealEvaluator — no UI widget dependencies', () {
    test('evaluator is a pure Dart class with no Flutter widget imports', () {
      // This test simply verifies the evaluator can be constructed and called
      // in a plain dart test environment (no WidgetTester, no BuildContext).
      final results = _evaluate();
      expect(results, isNotEmpty);
    });
  });

  group('CosmeticRevealEvaluator — unlocked always wins', () {
    test('owned cosmetic returns unlocked regardless of rule state', () {
      // companion_forest_fox has isHidden:true; if owned it must be unlocked.
      const id = 'companion_forest_fox';
      final results = _evaluate(owned: {id});
      expect(results[id]?.state, CosmeticRevealState.unlocked);
    });

    test('unlocked item with compound hidden rule does not show as partial', () {
      // companion_dragonling has isHidden:true; once owned → unlocked.
      const id = 'companion_dragonling';
      final results = _evaluate(owned: {id});
      expect(results[id]?.state, CosmeticRevealState.unlocked);
    });
  });

  group('CosmeticRevealEvaluator — hidden items', () {
    test('compound hidden item with 0 conditions met returns hidden', () {
      // companion_forest_fox: atLevel(10) + relic_moonlit_foxglove + relic_ancient_root.
      // With level 0 and no owned items, all conditions fail → hidden.
      const id = 'companion_forest_fox';
      final results = _evaluate(owned: {});
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.hidden);
      expect(result.satisfiedConditions, 0);
    });

    test('companion_ember_sprite returns hidden when no conditions met', () {
      // Compound hidden rule: atLevel(5) + campfire_spark + warm_kindling.
      // Level 0, no relics → 0/3 conditions → hidden.
      const id = 'companion_ember_sprite';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.hidden);
    });

    test('hidden item does not surface name, asset, or unlock hint via state', () {
      // The reveal system should return CosmeticRevealState.hidden so UI can
      // substitute ??? — the test verifies the state, not the widget.
      const id = 'companion_dragonling';
      final results = _evaluate(
        snapshot: _snapshot(level: 0),
        owned: {},
      );
      expect(results[id]?.state, CosmeticRevealState.hidden);
    });

    test('premium items return hidden when not owned', () {
      const id = 'frame_developer_tom';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.hidden);
    });

    test('devOnly background returns hidden for normal player', () {
      const id = 'background_dev_altar';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.hidden);
    });
  });

  group('CosmeticRevealEvaluator — visibleLocked', () {
    test('tier-1 level reward (no Tier-2 rule) returns visibleLocked', () {
      // frame_lvl10 is a level-10 reward with no entry in kCosmeticUnlockRules.
      const id = 'frame_lvl10';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });

    test('tier-1 achievement reward returns visibleLocked', () {
      // background_camp is granted via the welcome_to_journey achievement.
      const id = 'background_camp';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });

    test('frame_balance (no Tier-2 rule, granted by achievement) returns visibleLocked', () {
      // frame_balance is now a Tier-1 achievement reward (perfect_days_7) with no
      // entry in kCosmeticUnlockRules → the evaluator falls through to visibleLocked.
      const id = 'frame_balance';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });
  });

  group('CosmeticRevealEvaluator — partial', () {
    test('companion_forest_fox shows partial when level gate met but relics missing', () {
      // Condition 1: atLevel(10) → satisfied
      // Condition 2: ownsCosmetic(relic_moonlit_foxglove) → not satisfied
      // Condition 3: ownsCosmetic(relic_ancient_root) → not satisfied
      const id = 'companion_forest_fox';
      final results = _evaluate(
        snapshot: _snapshot(level: 10),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 3);
    });

    test('companion_ice_wisp shows partial at level 65 without relics', () {
      // Condition 1: atLevel(65) → satisfied
      // Condition 2: ownsCosmetic(relic_polar_lantern) → not satisfied
      // Condition 3: ownsCosmetic(relic_frozen_lake_heart) → not satisfied
      const id = 'companion_ice_wisp';
      final results = _evaluate(
        snapshot: _snapshot(level: 65),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 3);
    });

    test('companion_mountain_gryphon shows partial at level 85 without relics', () {
      // Condition 1: atLevel(85) → satisfied
      // Condition 2: ownsCosmetic(relic_summit_feather) → not satisfied
      // Condition 3: ownsCosmetic(relic_stormcrest_plume) → not satisfied
      const id = 'companion_mountain_gryphon';
      final results = _evaluate(
        snapshot: _snapshot(level: 85),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 3);
    });

    test('partial satisfiedConditions + totalConditions are correct', () {
      // companion_lantern_golem:
      //   cond 1: atLevel(45) → not satisfied (level 0)
      //   cond 2: ownsCosmetic(relic_deep_ember_core) → not satisfied
      //   cond 3: ownsCosmetic(relic_miners_lantern) → satisfied
      const id = 'companion_lantern_golem';
      final results = _evaluate(
        owned: {'relic_miners_lantern'},
        snapshot: _snapshot(
          owned: {'relic_miners_lantern'},
        ),
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 3);
    });
  });

  group('CosmeticRevealEvaluator — full catalog smoke test', () {
    test('every enabled catalog item has a result', () {
      final catalog = const CosmeticCatalog();
      final results = _evaluate();
      for (final def in catalog.enabled) {
        expect(
          results.containsKey(def.id),
          isTrue,
          reason: '${def.id} missing from results',
        );
      }
    });

    test('result states are one of the four valid enum values', () {
      final results = _evaluate();
      for (final result in results.values) {
        expect(CosmeticRevealState.values, contains(result.state));
      }
    });

    test('partial results always have totalConditions >= 2', () {
      // Partial is only meaningful for compound (multi-condition) rules.
      final results = _evaluate(
        snapshot: _snapshot(level: 80, totalQuests: 100),
      );
      for (final result in results.values) {
        if (result.state == CosmeticRevealState.partial) {
          expect(
            result.totalConditions,
            greaterThanOrEqualTo(2),
            reason: '${result.cosmeticId} has partial with < 2 conditions',
          );
        }
      }
    });
  });
}
