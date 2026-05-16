/// Tunable knobs for the retroactive-claim subsystem.
///
/// Lives in one file so balancing changes (window size, audit-log
/// depth, paginate chunk) can be tweaked without hunting through the
/// engine + presentation layers.
library;

/// How many calendar days back from today (inclusive of today) a
/// daily-goal / per-activity claim can fire. Anything older than this
/// renders as a locked audit pill — the value is still surfaced for
/// reference but the pill is not tappable.
///
/// Going wider trades player goodwill ("oh nice, I still get the
/// rewards") against retroactive-claim grind potential. 7 days =
/// "one missed week" feels lenient enough without letting the player
/// catch up months at a time.
const int kBackfillClaimLookbackDays = 7;

/// Number of days the quest-screen backfill section initially lists.
/// Defaults higher than [kBackfillClaimLookbackDays] so the player
/// sees one week of claimable days **plus** an extra week of
/// already-locked audit days for context ("ah, that's how I did two
/// weeks ago").
const int kBackfillVisibleInitialDays = 14;

/// "Show more" chunk size — every tap extends the visible range by
/// this many days, until the list reaches the player's join date.
const int kBackfillVisibleIncrementDays = 14;
