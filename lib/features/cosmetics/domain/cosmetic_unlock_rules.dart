/// Baseline unlock rules used when a fresh user state is created.
///
/// This file deliberately knows nothing about progression/social features —
/// other features call into the cosmetics service to grant unlocks; cosmetics
/// never reaches into them.
class CosmeticUnlockRules {
  const CosmeticUnlockRules();

  /// Cosmetics every user starts with. Kept small on purpose — most unlocks
  /// should come from progression or quests once those are wired.
  ///
  /// `background_forest_trail` was previously a default; it now unlocks at
  /// player level 5 via [CosmeticRewardTable]. Existing users who already
  /// own it keep it (the unlock record is durable; the catalog mapping move
  /// is idempotent).
  ///
  /// `background_camp` and `emblem_pilgrim_mark` are the welcome reward —
  /// granted via the `welcome_to_journey` achievement so the player visibly
  /// earns them on first sync rather than receiving them silently.
  static const Set<String> defaultUnlockedIds = <String>{
    'frame_lvl1',
    'relic_old_compass',
  };

  bool isDefaultUnlocked(String cosmeticId) =>
      defaultUnlockedIds.contains(cosmeticId);
}
