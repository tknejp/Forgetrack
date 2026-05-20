/// Single source of truth for the bonus percentages and streak
/// thresholds every companion buff in the catalog (or the test suite)
/// references. Catalog rows pass these constants into the buff
/// constructors; tests import them when asserting expected outputs.
///
/// **Why centralise.** Each percent / threshold is read in at least
/// three places (catalog row, formatter ARB substitution, balance +
/// UI tests). Inlining the numbers across all of them invites drift
/// the moment balance tuning lands. Pulling them here means a single
/// edit touches every consumer and `flutter test` immediately
/// validates the new tuning across catalog + UI + engine.
///
/// **Naming convention.** `<companionId><Tier>` for the percent
/// values, `<companionId><Tier>Threshold` for the streak length at
/// which that tier first activates. A `grep CompanionBuffPercents`
/// against any catalog row surfaces both the percent and the
/// threshold without a cross-reference.
///
/// Adding a companion → append a new constant (or constant block for
/// dynamic mechanics). Adjusting balance → change the number and
/// let the test suite report the downstream consequences.
abstract final class CompanionBuffPercents {
  // ── Flat-percent companions ────────────────────────────────────
  /// Forest Fox — nutritionXp on every nutrition daily-goal claim.
  static const int forestFoxNutrition = 10;

  /// Bridge Gargoyle — activityXp on every activity / steps grant.
  static const int bridgeGargoyleActivity = 20;

  /// Aurora Stag — sleepXp on the single 1×/day sleep claim. Loud
  /// per-claim because the source is narrow (one grant per day);
  /// daily-total contribution still well under the 25 % share cap.
  static const int auroraStagSleep = 80;

  /// Ice Wisp — questXp across every quest-bucket claim (daily +
  /// weekly + combo + long-term + daily-challenge).
  static const int iceWispQuest = 30;

  /// Mountain Gryphon — activityXp, the legendary-tier upgrade over
  /// Bridge Gargoyle.
  static const int mountainGryphonActivity = 50;

  /// Dragonling — `allXp` universal multiplier. Mythic-only.
  static const int dragonlingAll = 15;

  // ── Ember Sprite (streak-length dynamic, per main-5 streak) ────
  // Tiers stack as five visible brackets that the player learns by
  // watching the chip climb on each of the main-5 daily-goal cards
  // independently. The buff applies only when the granting reward
  // carries a streakDomain (i.e. daily goals); quests / combos /
  // chapters / meta resolve to 0.
  //
  // Cap +20 % at 21+ matches the rare-tier flat ceiling
  // (Bridge Gargoyle) for the player's strongest streaks; the
  // common-tier floor stays 0 so the chip does *something* visible
  // only once the player crosses the 2-day "this is a streak now"
  // boundary.
  /// Streak 0–1 days. Buff sits dormant — the chip surfaces the
  /// streak count itself but adds no XP percent until the player
  /// crosses the tier-1 threshold.
  static const int emberTier0 = 0;

  /// Streak 2–6 days.
  static const int emberTier1 = 5;

  /// Streak 7–13 days.
  static const int emberTier2 = 10;

  /// Streak 14–20 days.
  static const int emberTier3 = 15;

  /// Streak 21+ days. The advertised cap.
  static const int emberTier4 = 20;

  /// Streak 100+ days. Secret legendary tier — intentionally absent
  /// from player-facing copy, banners, and detail sheets. The
  /// catalog row carries it so the buff math actually pays out when
  /// the player reaches the milestone.
  static const int emberLegendary = 100;

  /// Streak length (inclusive) at which Ember enters tier 1.
  static const int emberTier1Threshold = 2;

  /// Streak length (inclusive) at which Ember enters tier 2.
  static const int emberTier2Threshold = 7;

  /// Streak length (inclusive) at which Ember enters tier 3.
  static const int emberTier3Threshold = 14;

  /// Streak length (inclusive) at which Ember enters tier 4 (cap).
  static const int emberTier4Threshold = 21;

  // ── Lantern Golem (streak-threshold flat) ──────────────────────
  /// Lantern Golem — flat percent applied to every main-5 daily-goal
  /// claim *once that domain's streak reaches the threshold*. The
  /// threshold guarantees the rare-tier buff isn't an instant 30 %
  /// the moment the companion is equipped — the player has to earn
  /// the lantern's warmth first.
  static const int lanternGolemPercent = 30;

  /// Streak length (inclusive) at which the Golem first activates
  /// on a given domain. Below this the chip surfaces a locked
  /// variant ("aktivace od 7d"); at or above, the full percent.
  static const int lanternGolemThreshold = 7;

  /// Streak 100+ days. Secret legendary tier mirroring Ember — kept
  /// silent in copy, paid out by the buff math when the milestone
  /// arrives.
  static const int lanternLegendary = 100;

  // ── Shared legendary milestone ─────────────────────────────────
  /// Streak length (inclusive) at which both streak buffs flip into
  /// their secret legendary tier. Single constant so the easter egg
  /// stays consistent across companions and tests.
  static const int streakLegendaryThreshold = 100;

  // ── Ruin Raven (weekly-emphasis dynamic) ───────────────────────
  /// Daily quest claim — intentionally dampened so the weekly close
  /// reads as a satisfying spike instead of "another claim".
  static const int ravenDaily = 5;

  /// Weekly quest claim — the headline payoff.
  static const int ravenWeekly = 30;

  // ── Cave Lynx (chapter-depth dynamic) ──────────────────────────
  /// Chapter opener (chain position 0 or 1).
  static const int lynxOpener = 20;

  /// Mid-chain steps (positions 2–3).
  static const int lynxMid = 50;

  /// Deep steps + finale (position 4+).
  static const int lynxDeep = 80;
}
