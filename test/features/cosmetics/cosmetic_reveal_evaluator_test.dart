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
      // relic_dragonrock_crown has isHidden:true; once owned → unlocked.
      const id = 'relic_dragonrock_crown';
      final results = _evaluate(owned: {id});
      expect(results[id]?.state, CosmeticRevealState.unlocked);
    });
  });

  group('CosmeticRevealEvaluator — hidden items', () {
    test('compound hidden item with 0 conditions met returns hidden', () {
      // companion_forest_fox: ownsCosmetic(emblem_forest_mark) + ownsCosmetic(relic_ancient_root)
      // With no owned items, both conditions fail → hidden.
      const id = 'companion_forest_fox';
      final results = _evaluate(owned: {});
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.hidden);
      expect(result.satisfiedConditions, 0);
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

    test('companion_ember_sprite with non-hidden OR rules returns visibleLocked', () {
      // ember_sprite has two rules, both with isHidden: false.
      const id = 'companion_ember_sprite';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });

    test('frame_balance (perfectPeriod, not hidden) returns visibleLocked', () {
      const id = 'frame_balance';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });
  });

  group('CosmeticRevealEvaluator — partial', () {
    test('companion_forest_fox shows partial when one ownership condition met', () {
      // Condition 1: owns emblem_forest_mark → satisfied
      // Condition 2: owns relic_ancient_root → not satisfied
      const id = 'companion_forest_fox';
      final results = _evaluate(
        owned: {'emblem_forest_mark'},
        snapshot: _snapshot(owned: {'emblem_forest_mark'}),
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 2);
    });

    test('companion_ice_wisp shows partial when frost_shard owned but not frozen_lake_heart', () {
      const id = 'companion_ice_wisp';
      final results = _evaluate(
        owned: {'relic_frost_shard'},
        snapshot: _snapshot(owned: {'relic_frost_shard'}),
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 2);
    });

    test('companion_mountain_gryphon shows partial at level 80 without relic', () {
      // Condition 1: atLevel(80) → satisfied
      // Condition 2: ownsCosmetic(relic_frozen_lake_heart) → not satisfied
      const id = 'companion_mountain_gryphon';
      final results = _evaluate(
        snapshot: _snapshot(level: 80),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 2);
    });

    test('relic_dragonrock_crown shows partial at level 100 with < 250 quests', () {
      // Condition 1: atLevel(100) → satisfied
      // Condition 2: totalQuestsCompletedAtLeast(250) → not satisfied
      const id = 'relic_dragonrock_crown';
      final results = _evaluate(
        snapshot: _snapshot(level: 100, totalQuests: 100),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 2);
    });

    test('partial satisfiedConditions + totalConditions are correct', () {
      // companion_lantern_golem:
      //   cond 1: ownsCosmetic(relic_miners_lantern) → satisfied
      //   cond 2: totalQuestsCompletedAtLeast(75) → not satisfied (60 quests)
      const id = 'companion_lantern_golem';
      final results = _evaluate(
        owned: {'relic_miners_lantern'},
        snapshot: _snapshot(
          totalQuests: 60,
          owned: {'relic_miners_lantern'},
        ),
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 2);
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
