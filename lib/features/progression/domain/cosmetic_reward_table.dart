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
//
// Tier-2 rewards (compound conditions, quest counts, perfect days/weeks)
// live in `lib/features/cosmetics/domain/cosmetic_unlock_rules.dart` —
// the rule evaluator there fires after this table on every dispatch.
class CosmeticRewardTable {
  const CosmeticRewardTable();

  /// Achievement id → cosmetic ids unlocked when the achievement transitions
  /// from locked to unlocked. Achievement ids match
  /// `ProgressionAchievementCatalog`.
  static const Map<String, List<String>> achievementToCosmetics =
      <String, List<String>>{
    // Visible welcome reward — fires on first sync.
    'welcome_to_journey': ['background_camp', 'emblem_pilgrim_mark'],

    // Step total milestones.
    'steps_total_100k': ['relic_ravine_stone'],
    'steps_total_1000000': ['relic_frozen_lake_heart'],
    'steps_total_10000000': ['frame_worldwalker'],

    // Step streaks. The 7-day streak grants both a relic and a frame.
    'steps_streak_7': ['relic_ancient_root', 'frame_discipline'],
    'steps_streak_30': ['frame_endurance'],
    'steps_streak_50': ['frame_steel'],
    'steps_streak_100': ['frame_eternal_flame'],

    // Rolling 30-day step window. Copy reads "within 30 days" — see
    // cosmeticFrameEndlessTrailDesc.
    'steps_month_600k': ['frame_endless_trail'],
  };

  /// Player level → cosmetic ids unlocked the moment that level is reached
  /// (i.e. profile.level transitions from `level - 1` to `level`).
  ///
  /// Level 1 is intentionally absent — the welcome reward
  /// (`background_camp` + `emblem_pilgrim_mark`) is granted via the
  /// `welcome_to_journey` achievement so the player sees a celebratory
  /// unlock rather than a silent baseline grant. `frame_lvl1` and
  /// `relic_old_compass` remain in `CosmeticUnlockRules.defaultUnlockedIds`.
  static const Map<int, List<String>> levelToCosmetics = <int, List<String>>{
    5: ['background_forest_trail'],
    10: ['frame_lvl10', 'emblem_forest_mark'],
    15: ['background_ravine', 'relic_old_gate_key'],
    20: ['emblem_ruin_sigil'],
    25: ['frame_lvl25', 'background_ruins'],
    30: ['emblem_gatekeeper_mark'],
    35: ['background_bridge_crossing'],
    40: ['frame_lvl40', 'emblem_mine_crest'],
    45: ['background_mines'],
    50: ['emblem_underways_mark'],
    55: ['relic_polar_lantern'],
    60: ['frame_lvl60', 'background_frostlands', 'emblem_frost_sigil'],
    65: ['relic_frost_shard'],
    70: ['emblem_icewalker_mark'],
    75: ['background_frozen_lake'],
    80: ['frame_lvl80', 'background_rocky_mountains', 'emblem_mountain_crest'],
    85: ['relic_dragon_scale'],
    90: ['emblem_dragon_mark'],
    95: ['background_dragonrock_fortress'],
    100: ['frame_lvl100', 'emblem_dragonrock_emblem'],
  };

  List<String> cosmeticsForAchievement(String achievementId) =>
      achievementToCosmetics[achievementId] ?? const <String>[];

  List<String> cosmeticsForLevel(int level) =>
      levelToCosmetics[level] ?? const <String>[];
}
