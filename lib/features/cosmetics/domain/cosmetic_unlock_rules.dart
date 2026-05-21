import 'cosmetic_catalog.dart';
import 'cosmetic_models.dart';
import 'cosmetic_unlock_rule.dart';

/// Baseline unlock rules used when a fresh user state is created.
///
/// This file deliberately knows nothing about progression/social features —
/// other features call into the cosmetics service to grant unlocks; cosmetics
/// never reaches into them.
class CosmeticUnlockRules {
  const CosmeticUnlockRules();

  /// Cosmetics every user starts with silently.
  ///
  /// Kept empty on purpose: starting cosmetics are granted through the visible
  /// `welcome_to_journey` achievement so the player sees the first unlock.
  static const Set<String> defaultUnlockedIds = <String>{};

  bool isDefaultUnlocked(String cosmeticId) =>
      defaultUnlockedIds.contains(cosmeticId);
}

/// Tier-2 unlock rules: companion unlocks gated on level + item ownership.
/// Relics themselves flow exclusively from Tier-1 (achievement reward table)
/// — there are no Tier-2 relic rules.
///
/// Pattern for every companion with a non-null `levelGate`:
///   Cond.atLevel(companion.levelGate) +
///   one Cond.ownsCosmetic per item in companion.requiredItems
///
/// Unlocks are idempotent and non-destructive: relics remain in inventory
/// after a companion is granted.
///
/// The fixed-point dispatcher (pass 3) handles the timing: achievement unlock
/// grants relics in pass 1, then pass 3 iteration 1 grants companions that now
/// see the relics in ownedCosmeticIds.
///
/// Derived directly from [CosmeticCatalog] — the catalog is the single source
/// of truth for which companions exist and their level + item gate.
/// Companions whose `levelGate` is null (today only DevTools-granted items
/// like Monster Energy) are skipped here — they are not surfaced through the
/// unlock pipeline. Rules carry no `sourceId`: the `(cosmeticId, sourceType:
/// 'compound')` pair is already 1:1 with the rule, so a separate source
/// reference would just duplicate the cosmetic id.
final List<CosmeticUnlockRule> kCosmeticUnlockRules = CosmeticCatalog()
    .companions
    .where((c) => c.levelGate != null)
    .map(_toCompanionUnlockRule)
    .toList(growable: false);

CosmeticUnlockRule _toCompanionUnlockRule(Companion companion) {
  // levelGate and requiredItems are non-null together by construction
  // (catalog rows pair them); the bang operator documents that invariant.
  return CosmeticUnlockRule(
    cosmeticId: companion.id.value,
    sourceType: 'compound',
    conditions: [
      Cond.atLevel(companion.levelGate!),
      for (final item in companion.requiredItems) Cond.ownsCosmetic(item.value),
    ],
    isHidden: true,
  );
}
