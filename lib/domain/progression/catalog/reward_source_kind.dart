/// Source-of-XP taxonomy used by the companion buff system.
///
/// Every [XpReward] / [BonusXpReward] in the catalog is tagged with one
/// of these so the engine can match it against the player's equipped
/// companion buff at grant time:
///
///   companion.buff.kind == reward.sourceKind  →  apply multiplier
///   companion.buff.kind == allXp              →  apply to every kind
///
/// The taxonomy is intentionally distinct from [ProgressionDomain]:
///   * `ProgressionDomain` describes the *objective* (steps, nutrition,
///     sleep, …) and is used for chrome / aggregation.
///   * `RewardSourceKind` describes the *granting context* and mixes
///     two axes — domain (nutritionXp / activityXp / sleepXp / bodyXp)
///     and claim cadence (streakXp / questXp / chapterXp). Companion
///     buffs target the granting context, not the domain.
///
/// `allXp` is reserved for endgame mythic companions and applies on
/// top of any other kind.
enum RewardSourceKind {
  /// Activity-domain XP — daily activity goals + any per-recorded-
  /// activity grants (workouts, training sessions). Steps fall under
  /// this kind as well; the buff doesn't distinguish the underlying
  /// objective domain. Body / weight-log claims are intentionally
  /// excluded — they live under [bodyXp] so movement-themed companion
  /// buffs (Bridge Gargoyle, Mountain Gryphon, …) don't bleed onto
  /// weight logging.
  activityXp,

  /// Nutrition-domain XP — daily macro / calorie goal claims.
  nutritionXp,

  /// Sleep-domain XP — sleep claim grants.
  sleepXp,

  /// Body-domain XP — daily weight-log claim (presence-only event
  /// that contributes to the body streak). Distinct from [activityXp]
  /// so movement-themed companions don't silently buff weight logging
  /// despite the flavor mismatch.
  bodyXp,

  /// Streak claim XP — daily streak completion rewards.
  streakXp,

  /// Quest XP — daily quest + weekly quest claims. Sub-cadence
  /// (daily vs weekly) is read off the granting node by dynamic
  /// buff rules (e.g. Ruin Raven weekly emphasis).
  questXp,

  /// Chapter quest XP — chapter finale claims. Chapter chain depth
  /// is read off ledger state by dynamic buff rules (e.g. Cave
  /// Lynx depth scaling).
  chapterXp,

  /// Universal — applies on top of every other kind. Reserved for
  /// the mythic-rarity Dragonling.
  allXp,
}
