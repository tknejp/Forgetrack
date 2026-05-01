import 'cosmetic_unlock_rule.dart';

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

/// Tier-2 unlock rules: conditions the achievement engine cannot express
/// today (category-typed quest counts, active-day counts, perfect periods,
/// compound conditions). The achievement reward table covers Tier-1
/// (level milestones, step totals, streaks, monthly windows).
///
/// Sources:
/// - 'quest'         — quest-based counters, including compound with quest legs
/// - 'activeDays'    — days the player engaged with progression
/// - 'perfectPeriod' — perfect-day / perfect-week placeholders
/// - 'compound'      — anything mixing level + ownership / multi-cosmetic
///
/// OR-style rules (e.g. ember_sprite: 7 active days OR 3 daily quests)
/// are expressed by registering two rules with the same `cosmeticId`.
final List<CosmeticUnlockRule> kCosmeticUnlockRules = <CosmeticUnlockRule>[
  // -- Quest-driven relics --------------------------------------------------
  CosmeticUnlockRule(
    cosmeticId: 'relic_campfire_spark',
    sourceType: 'quest',
    sourceId: 'first_daily_quest',
    conditions: [Cond.firstDailyQuest()],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'relic_pilgrim_cloak',
    sourceType: 'activeDays',
    sourceId: 'active_days_7',
    conditions: [Cond.activeDaysAtLeast(7)],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'relic_trail_compass',
    sourceType: 'quest',
    sourceId: 'daily_quests_7',
    conditions: [Cond.dailyQuestsCompletedAtLeast(7)],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'relic_ruin_seal',
    sourceType: 'quest',
    sourceId: 'first_weekly_quest',
    conditions: [Cond.firstWeeklyQuest()],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'relic_bridge_key',
    sourceType: 'quest',
    sourceId: 'weekly_quests_3',
    conditions: [Cond.weeklyQuestsCompletedAtLeast(3)],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'relic_miners_lantern',
    sourceType: 'quest',
    sourceId: 'total_quests_50',
    conditions: [Cond.totalQuestsCompletedAtLeast(50)],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'relic_dragon_crown',
    sourceType: 'quest',
    sourceId: 'total_quests_250',
    conditions: [Cond.totalQuestsCompletedAtLeast(250)],
  ),
  // Compound: level 100 AND 250 quests completed.
  CosmeticUnlockRule(
    cosmeticId: 'relic_dragonrock_crown',
    sourceType: 'compound',
    sourceId: 'compound_dragonrock_crown',
    conditions: [
      Cond.atLevel(100),
      Cond.totalQuestsCompletedAtLeast(250),
    ],
    isHidden: true,
  ),

  // -- Perfect-period frames (placeholder until evaluator backed) ----------
  CosmeticUnlockRule(
    cosmeticId: 'frame_balance',
    sourceType: 'perfectPeriod',
    sourceId: 'perfect_days_7',
    conditions: [Cond.perfectDaysAtLeast(7)],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'frame_master_routine',
    sourceType: 'perfectPeriod',
    sourceId: 'perfect_weeks_12',
    conditions: [Cond.perfectWeeksAtLeast(12)],
  ),

  // -- Companions ----------------------------------------------------------
  // ember_sprite is OR: 7 active days OR 3 daily quests — register twice.
  CosmeticUnlockRule(
    cosmeticId: 'companion_ember_sprite',
    sourceType: 'activeDays',
    sourceId: 'ember_sprite_active_days',
    conditions: [Cond.activeDaysAtLeast(7)],
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_ember_sprite',
    sourceType: 'quest',
    sourceId: 'ember_sprite_daily_quests',
    conditions: [Cond.dailyQuestsCompletedAtLeast(3)],
  ),

  CosmeticUnlockRule(
    cosmeticId: 'companion_forest_fox',
    sourceType: 'compound',
    sourceId: 'compound_forest_fox',
    conditions: [
      Cond.ownsCosmetic('emblem_forest_mark'),
      Cond.ownsCosmetic('relic_ancient_root'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_ruin_raven',
    sourceType: 'compound',
    sourceId: 'compound_ruin_raven',
    conditions: [
      Cond.ownsCosmetic('emblem_ruin_sigil'),
      Cond.firstWeeklyQuest(),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_lantern_golem',
    sourceType: 'compound',
    sourceId: 'compound_lantern_golem',
    conditions: [
      Cond.ownsCosmetic('relic_miners_lantern'),
      Cond.totalQuestsCompletedAtLeast(75),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_ice_wisp',
    sourceType: 'compound',
    sourceId: 'compound_ice_wisp',
    conditions: [
      Cond.ownsCosmetic('relic_frost_shard'),
      Cond.ownsCosmetic('relic_frozen_lake_heart'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_mountain_gryphon',
    sourceType: 'compound',
    sourceId: 'compound_mountain_gryphon',
    conditions: [
      Cond.atLevel(80),
      Cond.ownsCosmetic('relic_frozen_lake_heart'),
    ],
    isHidden: true,
  ),
  CosmeticUnlockRule(
    cosmeticId: 'companion_dragonling',
    sourceType: 'compound',
    sourceId: 'compound_dragonling',
    conditions: [
      Cond.atLevel(100),
      Cond.ownsCosmetic('relic_dragonrock_crown'),
    ],
    isHidden: true,
  ),
];
