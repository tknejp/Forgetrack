// Mapping from progression milestones (achievements / levels) to cosmetic
// ids that should be unlocked when those milestones are reached. Lives in
// `progression/domain` on purpose: this is the seam where progression
// decides "which cosmetic do you get for what" — the cosmetics feature
// knows nothing about achievements.
//
// Adding a new mapping = appending to the right map below + ensuring the
// cosmetic id exists in `CosmeticCatalog`. The dispatcher in
// `application/cosmetic_unlock_dispatcher.dart` consumes this table after
// every progression sync.
class CosmeticRewardTable {
  const CosmeticRewardTable();

  /// Achievement id → cosmetic ids unlocked when the achievement transitions
  /// from locked to unlocked. Achievement ids match
  /// `ProgressionAchievementCatalog`.
  static const Map<String, List<String>> achievementToCosmetics =
      <String, List<String>>{
    'first_reward': ['emblem_forest_mark'],
  };

  /// Player level → cosmetic ids unlocked the moment that level is reached
  /// (i.e. profile.level transitions from `level - 1` to `level`).
  static const Map<int, List<String>> levelToCosmetics = <int, List<String>>{
    1: ['frame_lvl1'],
    10: ['frame_lvl10', 'relic_old_gate_key'],
    25: ['frame_lvl25'],
    40: ['frame_lvl40'],
    60: ['frame_lvl60'],
    80: ['frame_lvl80'],
    100: ['frame_lvl100'],
  };

  List<String> cosmeticsForAchievement(String achievementId) =>
      achievementToCosmetics[achievementId] ?? const <String>[];

  List<String> cosmeticsForLevel(int level) =>
      levelToCosmetics[level] ?? const <String>[];
}
