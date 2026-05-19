/// Time / context window over which an [ObjectiveMetric] is measured.
///
/// Sealed so future scopes (rolling windows, chapter-scoped progress)
/// can be added without touching unrelated evaluator branches.
sealed class ObjectiveScope {
  const ObjectiveScope();
}

/// "Today" — current local-day window for the player.
class TodayScope extends ObjectiveScope {
  const TodayScope();
}

/// "This week" — current ISO week (Monday-anchored) for the player.
class ThisWeekScope extends ObjectiveScope {
  const ThisWeekScope();
}

/// "Lifetime" — sum across all recorded periods.
class LifetimeScope extends ObjectiveScope {
  const LifetimeScope();
}

/// Rolling window of N consecutive days ending today. Used by streak
/// objectives ("3 days in a row") and rolling-volume objectives.
class RollingWindowScope extends ObjectiveScope {
  const RollingWindowScope({required this.days});

  final int days;
}

/// Progress counted from the moment the active chapter started, not
/// player lifetime. Lets chapter quests measure "during this chapter".
class CurrentChapterScope extends ObjectiveScope {
  const CurrentChapterScope();
}
