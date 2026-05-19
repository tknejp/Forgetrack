import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_reveal_evaluator.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_reveal_state.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rule.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_rules.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_unlock_snapshot.dart';

// â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

void main() {
  group('CosmeticRevealEvaluator â€” no UI widget dependencies', () {
    test('evaluator is a pure Dart class with no Flutter widget imports', () {
      // This test simply verifies the evaluator can be constructed and called
      // in a plain dart test environment (no WidgetTester, no BuildContext).
      final results = _evaluate();
      expect(results, isNotEmpty);
    });
  });

  group('CosmeticRevealEvaluator â€” unlocked always wins', () {
    test('owned cosmetic returns unlocked regardless of rule state', () {
      // companion_forest_fox has isHidden:true; if owned it must be unlocked.
      const id = 'companion_forest_fox';
      final results = _evaluate(owned: {id});
      expect(results[id]?.state, CosmeticRevealState.unlocked);
    });

    test('unlocked item with compound hidden rule does not show as partial', () {
      // companion_dragonling has isHidden:true; once owned â†’ unlocked.
      const id = 'companion_dragonling';
      final results = _evaluate(owned: {id});
      expect(results[id]?.state, CosmeticRevealState.unlocked);
    });
  });

  group('CosmeticRevealEvaluator â€” hidden items', () {
    test('compound hidden item with 0 conditions met and far level returns hidden', () {
      // companion_ruin_raven: atLevel(25) + relic_ruin_seal + relic_ashen_omen.
      // Level 0 â†’ 0 < 25-10=15 â†’ still hidden (player hasn't reached teaser range).
      const id = 'companion_ruin_raven';
      final results = _evaluate(
        snapshot: _snapshot(level: 0),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.hidden);
      expect(result.satisfiedConditions, 0);
    });

    test('companion_ember_sprite returns visibleLocked at level 0 (always in teaser range)', () {
      // atLevel(5): teaser threshold = 5-10 = -5. Level 0 â‰¥ -5 â†’ visibleLocked.
      const id = 'companion_ember_sprite';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });

    test('hidden item does not surface name, asset, or unlock hint via state', () {
      // The reveal system should return CosmeticRevealState.hidden so UI can
      // substitute ??? â€” the test verifies the state, not the widget.
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

  group('CosmeticRevealEvaluator â€” visibleLocked', () {
    test('tier-1 level reward (no Tier-2 rule) returns visibleLocked', () {
      // frame_wildwood is a level-10 reward with no entry in kCosmeticUnlockRules.
      const id = 'frame_wildwood';
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
      // entry in kCosmeticUnlockRules â†’ the evaluator falls through to visibleLocked.
      const id = 'frame_balance';
      final results = _evaluate(owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });

    test('companion teaser: visibleLocked once level reaches minLevel-10', () {
      // companion_ruin_raven: minLevel=25, teaser threshold=15.
      // At level 15, 0 conditions met but level >= 15 â†’ visibleLocked.
      const id = 'companion_ruin_raven';
      final results = _evaluate(snapshot: _snapshot(level: 15), owned: {});
      expect(results[id]?.state, CosmeticRevealState.visibleLocked);
    });

    test('companion teaser: hidden one level below teaser threshold', () {
      // companion_ruin_raven: teaser threshold=15. Level 14 â†’ still hidden.
      const id = 'companion_ruin_raven';
      final results = _evaluate(snapshot: _snapshot(level: 14), owned: {});
      expect(results[id]?.state, CosmeticRevealState.hidden);
    });

    test('companion teaser has conditionRows populated', () {
      // At teaser threshold, conditionRows must list all 3 conditions.
      const id = 'companion_ruin_raven';
      final results = _evaluate(snapshot: _snapshot(level: 15), owned: {});
      final rows = results[id]?.conditionRows;
      expect(rows, isNotNull);
      expect(rows!.length, 3);
      expect(rows[0].conditionId, 'level_at_least_25');
      expect(rows[0].met, isFalse);
      expect(rows[1].met, isFalse);
      expect(rows[2].met, isFalse);
    });

    test('companion teaser conditionRows reflect owned relic', () {
      // If player owns relic_ruin_seal, that condition row must be met=true.
      const id = 'companion_ruin_raven';
      const relic = 'relic_ruin_seal';
      final results = _evaluate(
        snapshot: _snapshot(level: 15, owned: {relic}),
        owned: {relic},
      );
      final rows = results[id]?.conditionRows;
      expect(rows, isNotNull);
      // owns_relic_ruin_seal row should be met
      final relicRow = rows!.firstWhere((r) => r.conditionId == 'owns_$relic');
      expect(relicRow.met, isTrue);
    });
  });

  group('CosmeticRevealEvaluator â€” partial', () {
    test('companion_forest_fox shows partial when level gate met but relics missing', () {
      // Condition 1: atLevel(15) â†’ satisfied
      // Condition 2: ownsCosmetic(relic_moonlit_foxglove) â†’ not satisfied
      // Condition 3: ownsCosmetic(relic_ancient_root) â†’ not satisfied
      const id = 'companion_forest_fox';
      final results = _evaluate(
        snapshot: _snapshot(level: 15),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 3);
    });

    test('companion_ice_wisp shows partial at level 75 without relics', () {
      // Condition 1: atLevel(75) â†’ satisfied
      // Condition 2: ownsCosmetic(relic_polar_lantern) â†’ not satisfied
      // Condition 3: ownsCosmetic(relic_frost_shard) â†’ not satisfied
      const id = 'companion_ice_wisp';
      final results = _evaluate(
        snapshot: _snapshot(level: 75),
        owned: {},
      );
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      expect(result.satisfiedConditions, 1);
      expect(result.totalConditions, 3);
    });

    test('companion_mountain_gryphon shows partial at level 85 without relics', () {
      // Condition 1: atLevel(85) â†’ satisfied
      // Condition 2: ownsCosmetic(relic_summit_feather) â†’ not satisfied
      // Condition 3: ownsCosmetic(relic_stormcrest_plume) â†’ not satisfied
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
      //   cond 1: atLevel(45) â†’ not satisfied (level 0)
      //   cond 2: ownsCosmetic(relic_deep_ember_core) â†’ not satisfied
      //   cond 3: ownsCosmetic(relic_miners_lantern) â†’ satisfied
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

    test('partial companion has conditionRows with correct met flags', () {
      // companion_forest_fox: level=15 (gate met), no relics.
      // conditionRows: level_at_least_15=true, owns_relic_moonlit_foxglove=false,
      //                owns_relic_ancient_root=false.
      const id = 'companion_forest_fox';
      final results = _evaluate(snapshot: _snapshot(level: 15), owned: {});
      final result = results[id]!;
      expect(result.state, CosmeticRevealState.partial);
      final rows = result.conditionRows;
      expect(rows, isNotNull);
      expect(rows!.length, 3);
      expect(rows.firstWhere((r) => r.conditionId == 'level_at_least_15').met, isTrue);
      expect(rows.firstWhere((r) => r.conditionId == 'owns_relic_moonlit_foxglove').met, isFalse);
      expect(rows.firstWhere((r) => r.conditionId == 'owns_relic_ancient_root').met, isFalse);
    });
  });

  group('CosmeticRevealEvaluator â€” full catalog smoke test', () {
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