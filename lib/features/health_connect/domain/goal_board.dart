import 'package:meta/meta.dart';

import 'player_goal.dart';

/// Per-Player collection of [PlayerGoal] entries, one per
/// [GoalMetric].
///
/// Phase 14 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 14) extracts this aggregate out of `GoalsProvider` so the
/// domain types live next to the other health-connect domain rows
/// (`HealthSnapshot` lands in Phase 15 alongside). The provider
/// remains as the persistence + `ChangeNotifier` façade — every goal
/// edit ultimately calls [withGoal] and persists the resulting board.
///
/// Immutable value object — every mutation returns a new [GoalBoard]
/// with the updated goal substituted in.
///
/// **Persistence shape (unchanged).** The board is **not** persisted
/// as a single blob. Each [PlayerGoal] is stored under two existing
/// SharedPreferences keys: the scalar `goal_<metric>` (current target,
/// e.g. `goal_daily_steps`) + the JSON `goal_<metric>_history` (revision
/// timeline, e.g. `goal_daily_steps_history`). `targetWeight` has no
/// history key. See `GoalsProvider` for the read/write code.
@immutable
class GoalBoard {
  const GoalBoard({required this.goals});

  /// Per-metric goal map. Always contains exactly one entry per
  /// [GoalMetric] after [GoalsProvider.init()] has run.
  final Map<GoalMetric, PlayerGoal> goals;

  /// Empty board fallback — every [GoalMetric] gets a [PlayerGoal]
  /// with target `0.0` and no history. Used as a sentinel before
  /// hydration; production code never sees this state because
  /// `GoalsProvider.init()` populates the board before exposing it.
  static final GoalBoard empty = GoalBoard(
    goals: {
      for (final metric in GoalMetric.values)
        metric: PlayerGoal(metric: metric, target: 0),
    },
  );

  /// Looks up the goal for [metric]. Always non-null after
  /// hydration — falls back to a zero-target [PlayerGoal] otherwise so
  /// reads can stay null-safe at the call site.
  PlayerGoal goalFor(GoalMetric metric) =>
      goals[metric] ?? PlayerGoal(metric: metric, target: 0);

  /// Returns a new [GoalBoard] with [goal] substituted under its own
  /// [PlayerGoal.metric] key.
  GoalBoard withGoal(PlayerGoal goal) {
    final next = Map<GoalMetric, PlayerGoal>.from(goals);
    next[goal.metric] = goal;
    return GoalBoard(goals: next);
  }

  /// Stable order-sensitive fingerprint of every history-tracked
  /// metric. Exposed via `GoalsProvider.progressionHistorySignature`
  /// so retroactive-evaluation consumers (Progression V1
  /// `ProgressionProvider`, engine V2 backfill resolver) invalidate
  /// their caches when any tracked goal's history changes.
  ///
  /// [GoalMetric.targetWeight] is excluded — it has no history.
  String get progressionHistorySignature => GoalMetric.values
      .where((m) => m != GoalMetric.targetWeight)
      .map((m) => goalFor(m).historySignature)
      .join('|');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GoalBoard) return false;
    if (other.goals.length != goals.length) return false;
    for (final entry in goals.entries) {
      if (other.goals[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final entries = goals.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    return Object.hashAll([
      for (final e in entries) Object.hash(e.key, e.value),
    ]);
  }

  @override
  String toString() => 'GoalBoard(goals: ${goals.length})';
}
