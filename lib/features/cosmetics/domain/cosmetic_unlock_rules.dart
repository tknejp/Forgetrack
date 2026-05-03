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

/// Tier-2 unlock rules: companion unlocks gated on level + two relic ownership
/// conditions. Relics themselves flow exclusively from Tier-1 (achievement
/// reward table) — there are no Tier-2 relic rules.
///
/// Pattern for every companion:
///   Cond.atLevel(N) + Cond.ownsCosmetic(relic_a) + Cond.ownsCosmetic(relic_b)
///
/// Unlocks are idempotent and non-destructive: relics remain in inventory after
/// a companion is granted.
///
/// The fixed-point dispatcher (pass 3) handles the timing: achievement unlock
/// grants relics in pass 1, then pass 3 iteration 1 grants companions that now
/// see the relics in ownedCosmeticIds.
final List<CosmeticUnlockRule> kCosmeticUnlockRules = <CosmeticUnlockRule>[
  // -- Companions: relic gate + level gate, idempotent, no consumption -------
  CosmeticUnlockRule(
    cosmeticId: 'companion_ember_sprite',
    sourceType: 'compound',
    sourceId: 'compound_jiskricka',
    conditions: [
      Cond.atLevel(5),
      Cond.ownsCosmetic('relic_campfire_spark'),
      Cond.ownsCosmetic('relic_warm_kindling'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_forest_fox',
    sourceType: 'compound',
    sourceId: 'compound_lesni_liska',
    conditions: [
      Cond.atLevel(10),
      Cond.ownsCosmetic('relic_moonlit_foxglove'),
      Cond.ownsCosmetic('relic_ancient_root'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_ruin_raven',
    sourceType: 'compound',
    sourceId: 'compound_havran_ruin',
    conditions: [
      Cond.atLevel(25),
      Cond.ownsCosmetic('relic_ruin_seal'),
      Cond.ownsCosmetic('relic_ashen_omen'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_lantern_golem',
    sourceType: 'compound',
    sourceId: 'compound_lucernovy_golem',
    conditions: [
      Cond.atLevel(45),
      Cond.ownsCosmetic('relic_deep_ember_core'),
      Cond.ownsCosmetic('relic_miners_lantern'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_ice_wisp',
    sourceType: 'compound',
    sourceId: 'compound_ledovy_prizrak',
    conditions: [
      Cond.atLevel(65),
      Cond.ownsCosmetic('relic_polar_lantern'),
      Cond.ownsCosmetic('relic_frozen_lake_heart'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_mountain_gryphon',
    sourceType: 'compound',
    sourceId: 'compound_horsky_gryf',
    conditions: [
      Cond.atLevel(85),
      Cond.ownsCosmetic('relic_summit_feather'),
      Cond.ownsCosmetic('relic_stormcrest_plume'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_dragonling',
    sourceType: 'compound',
    sourceId: 'compound_draci_mlade',
    conditions: [
      Cond.atLevel(100),
      Cond.ownsCosmetic('relic_dragon_scale'),
      Cond.ownsCosmetic('relic_dragonrock_heart'),
    ],
    isHidden: true,
  ),
];
