/// Generic backfill window for retroactive claims. Used per-activity in
/// the home expanded activity card today; designed to be applied later
/// to every daily quest (steps / calories / macros / sleep / weight)
/// so the player can claim a day they forgot about within a bounded
/// window.
///
/// Window is `[earliest, latest]` inclusive at day granularity:
///   * `latest`  = today (the day at `now`)
///   * `earliest` = `max(today - (lookbackDays - 1), joinDay)`
///
/// `joinedAt` clamps the window so a fresh install can never claim
/// "days before the player joined" — those wouldn't have data anyway,
/// and surfacing them as claimable would look broken.
library;

class HistoricalClaimWindow {
  const HistoricalClaimWindow({
    required this.earliest,
    required this.latest,
  });

  /// Earliest day inclusive (00:00 local on that day).
  final DateTime earliest;

  /// Latest day inclusive (00:00 local on that day).
  final DateTime latest;

  /// True when [day] is within `[earliest, latest]` at day granularity.
  bool contains(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(earliest) && !d.isAfter(latest);
  }
}

/// Returns the inclusive day-granularity window for retroactive claims.
///
/// [lookbackDays] is the number of days the window spans **including
/// today** — so `lookbackDays: 14` lets the player claim today plus
/// the previous 13 days. Defaults to 14, matching the unified backfill
/// view the quest screen surfaces.
HistoricalClaimWindow makeHistoricalClaimWindow({
  required DateTime now,
  required DateTime joinedAt,
  int lookbackDays = 14,
}) {
  assert(lookbackDays >= 1, 'lookbackDays must be at least 1 (today).');
  final today = DateTime(now.year, now.month, now.day);
  final joinDay = DateTime(joinedAt.year, joinedAt.month, joinedAt.day);
  final lookbackStart = today.subtract(Duration(days: lookbackDays - 1));
  final earliest = lookbackStart.isAfter(joinDay) ? lookbackStart : joinDay;
  return HistoricalClaimWindow(earliest: earliest, latest: today);
}
