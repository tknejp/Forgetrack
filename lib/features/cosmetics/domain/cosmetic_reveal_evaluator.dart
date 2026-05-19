import 'cosmetic_catalog.dart';
import 'cosmetic_models.dart';
import 'cosmetic_reveal_state.dart';
import 'cosmetic_unlock_rule.dart';
import 'cosmetic_unlock_snapshot.dart';

/// Derives [CosmeticRevealResult] for every enabled cosmetic from static
/// catalog data, Tier-2 unlock rules, the player's owned cosmetics, and the
/// current progression snapshot.
///
/// Pure — no I/O, no Flutter imports. Safe to call from domain tests without
/// a widget tree.
///
/// ## Reveal policy
///
/// 1. **Unlocked** — player already owns the cosmetic. Always takes priority.
/// 2. **Hidden (no reveal)** — `isPremium` or `metadata['devOnly'] == true`.
///    These never appear in the player-facing grid regardless of progress.
/// 3. **visibleLocked** — no matching Tier-2 rule, OR the cosmetic has at
///    least one non-hidden rule. Tier-1 (level/achievement) rewards fall here
///    because they have no entry in [kCosmeticUnlockRules]. The player can see
///    the name and the generic unlock hint.
/// 4. **hidden (??? placeholder)** — all matching rules have `isHidden: true`
///    AND zero conditions are satisfied. The player has made no progress at
///    all toward this cosmetic; nothing is surfaced — not the name, not the
///    silhouette, not a checklist.
/// 5. **partial** — all matching rules have `isHidden: true` AND the player
///    has satisfied at least one condition of the best-matching rule
///    (Trello #76 sub-issue 5: the teaser appears the moment the player
///    earns the first signal of progress, e.g. crosses the level gate OR
///    acquires the first of the relics — any single satisfied condition
///    flips the cosmetic from `hidden` to a visible silhouette with the
///    requirements checklist). Shows "{satisfied}/{total} conditions met"
///    with the condition rows for companion cosmetics.
///
/// Partial reveal is only meaningful for compound rules with genuinely
/// independent conditions. Rules that are NOT suitable for partial reveal
/// should be registered with `isHidden: true` and kept as a single rule —
/// they will naturally stay in state 4 (hidden) until at least one
/// condition fires. The current ruleset was reviewed per-item; see
/// `cosmetic_unlock_rules.dart`.
class CosmeticRevealEvaluator {
  const CosmeticRevealEvaluator._();

  /// Returns reveal results for every item in [catalog] that is enabled.
  ///
  /// [rules] is typically [kCosmeticUnlockRules].
  /// [ownedIds] is the set of cosmetic ids the player currently owns.
  /// [snapshot] is the current progression snapshot; pass a minimal snapshot
  /// (all numeric fields zero, [CosmeticUnlockSnapshot.ownedCosmeticIds] from
  /// owned cosmetics) when full progression data is not yet available.
  static Map<String, CosmeticRevealResult> evaluateAll({
    required CosmeticCatalog catalog,
    required List<CosmeticUnlockRule> rules,
    required CosmeticUnlockSnapshot snapshot,
    required Set<String> ownedIds,
  }) {
    final results = <String, CosmeticRevealResult>{};
    for (final def in catalog.enabled) {
      results[def.id] = _evaluateOne(def, rules, snapshot, ownedIds);
    }
    return results;
  }

  static CosmeticRevealResult _evaluateOne(
    Cosmetic def,
    List<CosmeticUnlockRule> rules,
    CosmeticUnlockSnapshot snapshot,
    Set<String> ownedIds,
  ) {
    // 1. Unlocked always wins. For companion cosmetics we still build
    //    the requirements checklist (with every row ticked) so the
    //    details sheet can render the same checklist surface it shows
    //    for `partial` / `visibleLocked` — the player sees a clean
    //    list of "what I needed to earn this" instead of a stripped
    //    layout that drops the only summary of the unlock chain.
    if (ownedIds.contains(def.id)) {
      List<CosmeticRevealConditionRow>? conditionRows;
      if (def is Companion) {
        for (final rule in rules) {
          if (rule.cosmeticId != def.id) continue;
          conditionRows = _buildConditionRows(rule, snapshot);
          break;
        }
      }
      return CosmeticRevealResult(
        cosmeticId: def.id,
        state: CosmeticRevealState.unlocked,
        conditionRows: conditionRows,
      );
    }

    // 2. Premium and dev-only items are never surfaced.
    if (def.isPremium || def.metadata['devOnly'] == true) {
      return CosmeticRevealResult(
        cosmeticId: def.id,
        state: CosmeticRevealState.hidden,
      );
    }

    final matchingRules = rules.where((r) => r.cosmeticId == def.id).toList();

    // 3. No Tier-2 rule → Tier-1 (level/achievement reward) → visible locked.
    if (matchingRules.isEmpty) {
      return CosmeticRevealResult(
        cosmeticId: def.id,
        state: CosmeticRevealState.visibleLocked,
      );
    }

    // 4. Any non-hidden rule → always visible locked.
    if (matchingRules.any((r) => !r.isHidden)) {
      return CosmeticRevealResult(
        cosmeticId: def.id,
        state: CosmeticRevealState.visibleLocked,
      );
    }

    // 5. All rules are hidden — evaluate best partial progress.
    //    For OR-style hidden rules: pick the rule with the most conditions
    //    satisfied. Break ties by preferring the rule with fewer total
    //    conditions (highest progress ratio = closest to unlock).
    int bestSatisfied = 0;
    int bestTotal = 999; // larger than any rule's condition count — first rule always wins first pass
    CosmeticUnlockRule? bestRule;
    for (final rule in matchingRules) {
      final satisfied = rule.satisfiedCount(snapshot);
      final total = rule.conditions.length;
      if (satisfied > bestSatisfied ||
          (satisfied == bestSatisfied && total < bestTotal)) {
        bestSatisfied = satisfied;
        bestTotal = total;
        bestRule = rule;
      }
    }

    if (bestSatisfied == 0) {
      // Trello #76 sub-issue 5: a compound-hidden cosmetic with zero
      // satisfied conditions stays fully hidden — no silhouette, no
      // checklist, no name leak. The previous "within 10 of the
      // companion's level gate" teaser branch is gone: level proximity
      // alone no longer reveals the existence of a companion the
      // player has made no real progress toward. The teaser appears
      // the moment the first condition fires (level crossed OR first
      // relic acquired), via the `partial` return below.
      return CosmeticRevealResult(
        cosmeticId: def.id,
        state: CosmeticRevealState.hidden,
      );
    }

    return CosmeticRevealResult(
      cosmeticId: def.id,
      state: CosmeticRevealState.partial,
      satisfiedConditions: bestSatisfied,
      totalConditions: bestTotal,
      conditionRows: def is Companion && bestRule != null
          ? _buildConditionRows(bestRule, snapshot)
          : null,
    );
  }

  /// Builds a checklist row for every condition in [rule].
  static List<CosmeticRevealConditionRow> _buildConditionRows(
    CosmeticUnlockRule rule,
    CosmeticUnlockSnapshot snapshot,
  ) {
    return rule.conditions
        .map((cond) => CosmeticRevealConditionRow(
              conditionId: cond.id,
              met: cond.test(snapshot),
            ))
        .toList(growable: false);
  }
}
