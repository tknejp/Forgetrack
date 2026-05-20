/// Single source of truth for the bonus percentages every companion
/// buff in the catalog (or the test suite) references. Catalog rows
/// pass these constants into the buff constructors; tests import
/// them when asserting expected outputs.
///
/// **Why centralise.** Each percent is read in at least three places
/// (catalog row, formatter ARB substitution, balance + UI tests).
/// Inlining the numbers across all of them invites drift the moment
/// balance tuning lands. Pulling them here means a single edit
/// touches every consumer and `flutter test` immediately validates
/// the new tuning across catalog + UI + engine.
///
/// **Naming convention.** `<companionId>` / `<companionId><Tier>` so
/// a `grep CompanionBuffPercents` against any catalog row name
/// surfaces the relevant constants without a separate cross-reference.
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

  /// Lantern Golem — flat streakXp. Currently dormant in production
  /// because no catalog reward is tagged `streakXp` yet (the
  /// taxonomy reserves it for an explicit streak-claim event that
  /// hasn't shipped). Kept on the row + populated here so flipping
  /// the buff live is a content change, not an architecture change.
  static const int lanternGolemStreak = 25;

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

  // ── Ember Sprite (streak-length dynamic) ───────────────────────
  /// Streak 1–3 days (or 0, just reset). Protects fresh streaks so
  /// the buff is never worse than "no buff".
  static const int emberFloor = 5;

  /// Streak 4–7 days.
  static const int emberShort = 10;

  /// Streak 8–14 days.
  static const int emberMedium = 15;

  /// Streak 15+ days. Cap.
  static const int emberLong = 20;

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
