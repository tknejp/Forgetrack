import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/player.dart';
import 'package:forgetrack/features/health_connect/domain/health_snapshot.dart';
import 'package:forgetrack/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:forgetrack/features/progression_engine/application/streak_backfill_service.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/engine_catalog_context.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/evaluator/progression_node_resolver.dart';
import 'package:forgetrack/features/progression_engine/domain/repository/ledger_snapshot.dart';

void main() {
  late StreakBackfillService service;

  setUp(() {
    service = const StreakBackfillService(
      objectiveCatalog: ObjectiveCatalog(),
    );
  });

  final today = DateTime(2026, 5, 20);
  final joined = DateTime(2026, 5, 16);
  final player = Player(
    uid: 'test',
    level: 1,
    totalXp: 0,
    joinedAt: joined,
    rpgModeEnabled: true,
  );

  HealthSnapshot snapshotWithSteps(DateTime date, int steps) => HealthSnapshot(
        evaluatedDate: date,
        stepsToday: steps,
      );

  EngineGoalSet defaultGoals(DateTime _) => const EngineGoalSet(
        dailySteps: 10000,
      );

  test(
    'reproduces #99 — three consecutive past step-goal days appear as a '
    'gap that the backfill closes',
    () async {
      // Player walked 12k steps on May 17, 18, 19 but the engine
      // never recorded a completion event for any of those days
      // (closed app, HC sync caught up later, …). The live engine
      // already wrote today's completion (May 20). Pre-backfill the
      // ledger has one objective event; post-backfill it has four.
      final todayCompletionKey =
          ProgressionNodeResolver.objectiveCompletionEventKey(
        'daily_steps',
        '2026-05-20',
      );
      final ledger = _ledgerFromObjective([
        ObjectiveCompletionEvent(
          eventKey: todayCompletionKey,
          timestamp: today,
          objectiveId: 'daily_steps',
          actualValue: 12000,
          periodKey: '2026-05-20',
        ),
      ]);
      final appended = <JournalEvent>[];

      final result = await service.runBackfill(
        fromDate: joined,
        toDate: today,
        player: player,
        ledger: ledger,
        buildHealthSnapshot: (date) {
          // Steps satisfy the 10 000 target on May 17–19.
          final hits = {
            DateTime(2026, 5, 17),
            DateTime(2026, 5, 18),
            DateTime(2026, 5, 19),
          };
          return snapshotWithSteps(date, hits.contains(date) ? 12000 : 0);
        },
        buildNutritionSnapshot: (date) =>
            NutritionSnapshot(evaluatedDate: date),
        buildGoals: defaultGoals,
        appendEvents: (events) async => appended.addAll(events),
        clock: () => today,
      );

      // joinedAt May 16 → today May 20 exclusive = 4 days scanned.
      expect(result.scannedDays, 4);
      // Three new completion events for steps on May 17/18/19. May
      // 16 didn't hit goal, May 20 is already in ledger.
      expect(result.appendedEvents, 3);
      expect(appended.length, 3);

      // Every appended event is keyed correctly and idempotent.
      final keys = appended
          .whereType<ObjectiveCompletionEvent>()
          .map((e) => e.eventKey)
          .toSet();
      expect(
        keys,
        {
          ProgressionNodeResolver.objectiveCompletionEventKey(
              'daily_steps', '2026-05-17'),
          ProgressionNodeResolver.objectiveCompletionEventKey(
              'daily_steps', '2026-05-18'),
          ProgressionNodeResolver.objectiveCompletionEventKey(
              'daily_steps', '2026-05-19'),
        },
      );
    },
  );

  test('respects existing completion events — re-runs are no-ops', () async {
    // Every past day's completion is already in the ledger. Backfill
    // sees nothing to do.
    final ledger = _ledgerFromObjective([
      for (final day in [
        DateTime(2026, 5, 16),
        DateTime(2026, 5, 17),
        DateTime(2026, 5, 18),
        DateTime(2026, 5, 19),
      ])
        ObjectiveCompletionEvent(
          eventKey: ProgressionNodeResolver.objectiveCompletionEventKey(
            'daily_steps',
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
          ),
          timestamp: today,
          objectiveId: 'daily_steps',
          actualValue: 12000,
          periodKey:
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        ),
    ]);
    final appended = <JournalEvent>[];

    final result = await service.runBackfill(
      fromDate: joined,
      toDate: today,
      player: player,
      ledger: ledger,
      buildHealthSnapshot: (date) => snapshotWithSteps(date, 12000),
      buildNutritionSnapshot: (date) =>
          NutritionSnapshot(evaluatedDate: date),
      buildGoals: defaultGoals,
      appendEvents: (events) async => appended.addAll(events),
      clock: () => today,
    );

    expect(result.appendedEvents, 0);
    expect(appended, isEmpty);
  });

  test('skips non-streak objectives so combos / quests stay live-only',
      () async {
    // Even though the catalog has many objectives, only the
    // main-five daily goals should be backfilled. We assert this by
    // checking no event-key carries a non-streak objective id.
    final ledger = _ledgerFromObjective(const []);
    final appended = <JournalEvent>[];

    await service.runBackfill(
      fromDate: joined,
      toDate: today,
      player: player,
      ledger: ledger,
      buildHealthSnapshot: (date) => snapshotWithSteps(date, 50000),
      buildNutritionSnapshot: (date) => NutritionSnapshot(
        evaluatedDate: date,
        caloriesToday: 5000,
        proteinGramsToday: 500,
        carbsGramsToday: 800,
        fatGramsToday: 200,
        fiberGramsToday: 80,
      ),
      buildGoals: defaultGoals,
      appendEvents: (events) async => appended.addAll(events),
      clock: () => today,
    );

    final ids = appended
        .whereType<ObjectiveCompletionEvent>()
        .map((e) => e.objectiveId)
        .toSet();
    expect(
      ids.every(StreakBackfillService.streakObjectiveIds.contains),
      isTrue,
      reason: 'Backfill must never touch non-streak objectives',
    );
  });

  test('uses periodKey to date — past events stamp the right day',
      () async {
    final ledger = _ledgerFromObjective(const []);
    final appended = <JournalEvent>[];

    await service.runBackfill(
      fromDate: joined,
      toDate: today,
      player: player,
      ledger: ledger,
      buildHealthSnapshot: (date) {
        // Only May 18 hits the step goal.
        return snapshotWithSteps(
          date,
          date == DateTime(2026, 5, 18) ? 12000 : 0,
        );
      },
      buildNutritionSnapshot: (date) =>
          NutritionSnapshot(evaluatedDate: date),
      buildGoals: defaultGoals,
      appendEvents: (events) async => appended.addAll(events),
      clock: () => today,
    );

    final event = appended.single as ObjectiveCompletionEvent;
    expect(event.periodKey, '2026-05-18');
    // Timestamp anchors at "when the backfill ran", not at the past
    // day — keeps the audit trail honest while [periodKey] carries
    // the historical truth.
    expect(event.timestamp, today);
  });

  test('empty / inverted window returns scannedDays = 0', () async {
    final ledger = _ledgerFromObjective(const []);
    final appended = <JournalEvent>[];

    final result = await service.runBackfill(
      fromDate: today,
      toDate: today,
      player: player,
      ledger: ledger,
      buildHealthSnapshot: (date) => snapshotWithSteps(date, 12000),
      buildNutritionSnapshot: (date) =>
          NutritionSnapshot(evaluatedDate: date),
      buildGoals: defaultGoals,
      appendEvents: (events) async => appended.addAll(events),
      clock: () => today,
    );

    expect(result.scannedDays, 0);
    expect(result.appendedEvents, 0);
    expect(appended, isEmpty);
  });
}

/// Builds a [LedgerSnapshot] from a plain list of objective
/// completion events — keeps every test's setup focused on the bug
/// they reproduce instead of fabricating the full sealed event list.
LedgerSnapshot _ledgerFromObjective(List<ObjectiveCompletionEvent> events) =>
    LedgerSnapshot(objectiveCompletions: events);
