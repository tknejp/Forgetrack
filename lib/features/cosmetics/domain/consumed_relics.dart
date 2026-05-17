import 'cosmetic_models.dart';
import 'cosmetic_unlock_rule.dart';
import 'cosmetic_unlock_rules.dart';

const _ownsPrefix = 'owns_';

/// Returns the set of relic ids that have been "consumed" by a companion
/// claim — relics referenced by an `ownsCosmetic` condition of a
/// companion-unlock rule whose companion the user already owns.
///
/// Derived purely from cosmetics state + unlock rules so no schema or
/// migration is required: a relic is considered consumed iff the
/// companion it gates is unlocked. Relics themselves are never removed
/// from the unlocked set — the "consumed" flag drives a visual mark
/// ("Použito" pill, dimmed thumb) so the player understands which
/// relics fed which companion.
Set<String> consumedRelicIds(
  UserCosmeticsState state, {
  List<CosmeticUnlockRule>? rules,
}) {
  final effective = rules ?? kCosmeticUnlockRules;
  final out = <String>{};
  for (final rule in effective) {
    if (!state.unlocked.containsKey(rule.cosmeticId)) continue;
    for (final cond in rule.conditions) {
      if (!cond.id.startsWith(_ownsPrefix)) continue;
      out.add(cond.id.substring(_ownsPrefix.length));
    }
  }
  return out;
}

/// Returns the relic ids that gate [companionId] per the unlock rules.
/// Used by the claim animation to render the "joining" relic thumbs.
List<String> companionRelicGateIds(
  String companionId, {
  List<CosmeticUnlockRule>? rules,
}) {
  final effective = rules ?? kCosmeticUnlockRules;
  for (final rule in effective) {
    if (rule.cosmeticId != companionId) continue;
    return [
      for (final cond in rule.conditions)
        if (cond.id.startsWith(_ownsPrefix))
          cond.id.substring(_ownsPrefix.length),
    ];
  }
  return const [];
}
