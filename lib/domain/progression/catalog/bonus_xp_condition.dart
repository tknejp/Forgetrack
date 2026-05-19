/// Conditions a [BonusXpReward] checks at grant time to decide
/// whether the bonus actually fires. Sealed so the engine planner's
/// switch is exhaustive — adding a new condition forces every
/// consumer to acknowledge it.
///
/// Conditions read from the current `EngineEvaluationContext`, not
/// the ledger — they're "claim-moment" predicates, evaluated when
/// the engine plans rewards for a newly-completed node.
sealed class BonusXpCondition {
  const BonusXpCondition();
}

/// Bonus fires only when the engine's evaluation timestamp falls
/// strictly before [hour] (24-hour local time). Used to reward
/// players who hit their daily goals early in the day instead of
/// waiting until the last minute. The conventional [hour] cutoff
/// for steps / activity is `18`, for nutrition `14` (around lunch),
/// for morning-leaning quests `12`.
class CompletedBeforeHour extends BonusXpCondition {
  const CompletedBeforeHour(this.hour);

  final int hour;
}

/// Bonus fires only when the player logged at least [minutes] of
/// sleep last night (read from `HealthSnapshot.sleepMinutesToday`).
/// Useful for sleep-themed daily goals where "hitting the goal" is
/// the minimum and "sleeping well" is the bonus.
class SleepAtLeast extends BonusXpCondition {
  const SleepAtLeast({required this.minutes});

  final int minutes;
}
