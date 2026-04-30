/// Baseline unlock rules used when a fresh user state is created.
///
/// This file deliberately knows nothing about progression/social features —
/// other features call into the cosmetics service to grant unlocks; cosmetics
/// never reaches into them.
class CosmeticUnlockRules {
  const CosmeticUnlockRules();

  /// Cosmetics every user starts with. Kept small on purpose — most unlocks
  /// should come from progression or quests once those are wired.
  static const Set<String> defaultUnlockedIds = <String>{
    'frame_lvl1',
    'relic_old_compass',
    'background_forest_trail',
  };

  bool isDefaultUnlocked(String cosmeticId) =>
      defaultUnlockedIds.contains(cosmeticId);
}
