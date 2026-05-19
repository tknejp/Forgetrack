import 'cosmetic_unlock_rule.dart';
import 'cosmetic_unlock_snapshot.dart';

/// Pure result tuple emitted by the evaluator for each rule that fires.
class CosmeticUnlockTuple {
  const CosmeticUnlockTuple({
    required this.cosmeticId,
    required this.sourceType,
    required this.sourceId,
  });

  final String cosmeticId; // lint-ignore: untyped-id — mirrors CosmeticId in the evaluator tuple
  final String sourceType;
  final String sourceId; // lint-ignore: untyped-id — opaque rule-author-supplied source key (quest/achievement/level/...)

  @override
  bool operator ==(Object other) =>
      other is CosmeticUnlockTuple &&
      other.cosmeticId == cosmeticId &&
      other.sourceType == sourceType &&
      other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(cosmeticId, sourceType, sourceId);
}

/// Walks a list of [CosmeticUnlockRule]s and returns the cosmetics that
/// should be unlocked for the given snapshot.
///
/// Pure — no I/O, no async. The dispatcher is responsible for calling
/// `cosmeticsProvider.unlock(...)` for each tuple, in a fixed-point loop
/// when compound rules depend on each other.
class CosmeticUnlockEvaluator {
  const CosmeticUnlockEvaluator(this.rules);

  final List<CosmeticUnlockRule> rules;

  /// Returns rules that should fire (cosmetic not in `alreadyOwned` AND all
  /// conditions met). Deduplicates by cosmeticId so OR-style rules
  /// (multiple rules / same cosmetic) produce a single unlock tuple.
  Set<CosmeticUnlockTuple> evaluate(
    CosmeticUnlockSnapshot snapshot,
    Set<String> alreadyOwned,
  ) {
    final out = <String, CosmeticUnlockTuple>{};
    for (final rule in rules) {
      if (alreadyOwned.contains(rule.cosmeticId)) continue;
      if (out.containsKey(rule.cosmeticId)) continue;
      if (rule.isSatisfied(snapshot)) {
        out[rule.cosmeticId] = CosmeticUnlockTuple(
          cosmeticId: rule.cosmeticId,
          sourceType: rule.sourceType,
          sourceId: rule.sourceId,
        );
      }
    }
    return out.values.toSet();
  }

  /// Future UI hook: returns satisfied/total per rule for a given cosmetic.
  /// Not wired to UI in this iteration — exposed so the data is reachable
  /// when the hidden/partial-reveal feature lands.
  ({int satisfied, int total})? progressFor(
    String cosmeticId,
    CosmeticUnlockSnapshot snapshot,
  ) {
    for (final rule in rules) {
      if (rule.cosmeticId != cosmeticId) continue;
      return (
        satisfied: rule.satisfiedCount(snapshot),
        total: rule.conditions.length,
      );
    }
    return null;
  }
}
