import 'package:meta/meta.dart';

import '../../../domain/journal/journal_event.dart';
import '../../../domain/player/player.dart';
import '../../../domain/journal/in_memory_journal.dart';
import '../../health_connect/domain/goal_board.dart';
import '../../health_connect/domain/health_snapshot.dart';
import '../../nutrition/domain/nutrition_snapshot.dart';
import '../domain/catalog/engine_catalog_context.dart';
import '../domain/catalog/objective_catalog.dart';
import '../domain/evaluator/objective_evaluator.dart';
import '../domain/evaluator/progression_node_resolver.dart';
import '../domain/models/evaluation_overrides.dart';
import '../domain/models/ledger_counters.dart';
import '../domain/models/engine_evaluation_context.dart';
import '../domain/repository/ledger_snapshot.dart';

/// Backfills [ObjectiveCompletionEvent]s for past days where the
/// player met a main-five daily goal but the live engine never had
/// a chance to record it (Health Connect sync caught up, app was
/// closed, device was off, …).
///
/// **Why this exists.** [ObjectiveEvaluator] only ever evaluates the
/// current snapshot — `health.stepsToday`, `nutrition.caloriesToday`,
/// etc. — and tags the resulting [ObjectiveCompletionEvent] with
/// `evaluatedAt`'s periodKey. There is no path for "today's snapshot
/// also reveals that yesterday's goal was met" to land in the
/// ledger. Without that, [EngineStreakSource] correctly sees a gap
/// for past days the engine never witnessed and collapses the streak
/// to 1 (or 0). This service walks past days against per-day
/// snapshots + per-day goal targets and appends the events the live
/// engine missed.
///
/// **Idempotency.** Each appended event uses the same eventKey shape
/// the engine emits via [ProgressionNodeResolver.objectiveCompletionEventKey]
/// — repository-level dedup makes re-runs safe. The caller can run
/// the backfill on every refresh; subsequent calls beyond the first
/// after a midnight rollover are effectively no-ops.
///
/// **Scope is hardcoded to the main-five streak objectives** by id.
/// The streak buff's target set is a design decision and adding a
/// new streak domain should be an explicit edit here, not silently
/// picked up from the catalog. Non-streak objectives (combos,
/// chapter steps, achievements, meta) keep their live-only emission
/// behaviour.
///
/// **Source of truth for past targets is the per-date goal lookup.**
/// Callers wire [buildGoals] to [GoalsProvider]'s `progression*ForDate`
/// API which resolves the goal active on that specific calendar day
/// — so a player who raised their step goal to 12 000 last week
/// still has earlier 10 000-step days counted under the rule they
/// were playing at the time.
class StreakBackfillService {
  const StreakBackfillService({
    required ObjectiveCatalog objectiveCatalog,
    ObjectiveEvaluator evaluator = const ObjectiveEvaluator(),
  })  : _objectiveCatalog = objectiveCatalog,
        _evaluator = evaluator;

  final ObjectiveCatalog _objectiveCatalog;
  final ObjectiveEvaluator _evaluator;

  /// Ids of the daily-scoped objectives the streak chip + streak
  /// buffs read. Kept as a literal set rather than derived from the
  /// catalog so adding a new streak domain is a single-file change
  /// and `flutter analyze` flags any rename mismatch.
  static const Set<String> streakObjectiveIds = {
    'daily_steps',
    'daily_calories',
    'daily_protein',
    'daily_carbs',
    'daily_fat',
    'daily_fiber',
    'daily_sleep',
    'daily_activity',
    'daily_weight_log',
  };

  /// Walks `[fromDate, toDate)` (inclusive lower, exclusive upper —
  /// the live engine still owns today) and emits a missing
  /// [ObjectiveCompletionEvent] for every main-five daily goal the
  /// player met on that day. Returns the number of events appended.
  ///
  /// `clock()` controls the `timestamp` baked into each new event;
  /// it points at "when the backfill ran", not at the historical
  /// day. Timeline-style consumers see "this completion was recorded
  /// today" while [EngineStreakSource] reads the historical day off
  /// `periodKey` — that split keeps the audit trail honest without
  /// rewriting the past.
  Future<BackfillResult> runBackfill({
    required DateTime fromDate,
    required DateTime toDate,
    required Player player,
    required LedgerSnapshot ledger,
    required HealthSnapshot Function(DateTime date) buildHealthSnapshot,
    required NutritionSnapshot Function(DateTime date) buildNutritionSnapshot,
    required EngineGoalSet Function(DateTime date) buildGoals,
    required Future<void> Function(List<JournalEvent> events) appendEvents,
    required DateTime Function() clock,
  }) async {
    final from = _dateOnly(fromDate);
    final to = _dateOnly(toDate);
    if (!from.isBefore(to)) {
      return const BackfillResult(scannedDays: 0, appendedEvents: 0);
    }

    final newEvents = <JournalEvent>[];
    final now = clock();
    var scannedDays = 0;

    for (var day = from;
        day.isBefore(to);
        day = DateTime(day.year, day.month, day.day + 1)) {
      scannedDays += 1;

      final goals = buildGoals(day);
      final objectives = _objectiveCatalog.build(
        EngineCatalogContext(goals: goals),
      );

      // Anchor evaluatedAt at the end of the day so today-scope
      // period keys (`yyyy-MM-dd`) land on `day` regardless of the
      // local zone offset details.
      final evaluatedAt =
          DateTime(day.year, day.month, day.day, 12);
      final context = EngineEvaluationContext(
        player: player,
        healthSnapshot: buildHealthSnapshot(day),
        nutritionSnapshot: buildNutritionSnapshot(day),
        goalBoard: GoalBoard.empty,
        journal: InMemoryJournal(const []),
        counters: LedgerCounters.empty,
        overrides: const EvaluationOverrides(),
        evaluatedAt: evaluatedAt,
      );

      for (final objective in objectives) {
        if (!streakObjectiveIds.contains(objective.id)) continue;
        final outcome = _evaluator.evaluate(objective, context);
        if (!outcome.completed) continue;

        final eventKey = ProgressionNodeResolver.objectiveCompletionEventKey(
          objective.id,
          outcome.periodKey,
        );
        if (ledger.hasEventKey(eventKey)) continue;

        newEvents.add(ObjectiveCompletionEvent(
          eventKey: eventKey,
          timestamp: now,
          objectiveId: objective.id,
          actualValue: outcome.actualValue,
          periodKey: outcome.periodKey,
        ));
      }
    }

    if (newEvents.isNotEmpty) {
      await appendEvents(newEvents);
    }
    return BackfillResult(
      scannedDays: scannedDays,
      appendedEvents: newEvents.length,
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Outcome of a single [StreakBackfillService.runBackfill] pass.
/// Surfaced for AppLog telemetry and tests so callers don't have to
/// inspect the appended events themselves.
@immutable
class BackfillResult {
  const BackfillResult({
    required this.scannedDays,
    required this.appendedEvents,
  });

  /// Number of calendar days the loop walked. Useful for sanity
  /// checking ("did we actually look at the expected window").
  final int scannedDays;

  /// Number of [ObjectiveCompletionEvent]s appended to the ledger
  /// by this run. Zero means every past completion was already
  /// recorded; non-zero on a no-input day means the backfill closed
  /// a real gap.
  final int appendedEvents;

  bool get isEmpty => scannedDays == 0 && appendedEvents == 0;
}
