import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_metric.dart';
import 'package:forgetrack/domain/progression/catalog/objective_operator.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import 'package:forgetrack/features/progression_engine/domain/evaluator/engine_streak_source.dart';
import 'package:forgetrack/features/progression_engine/domain/repository/ledger_snapshot.dart';

void main() {
  // Constant calendar reference — May 20 2026, a Wednesday, well
  // clear of any DST transition so the baseline "happy path" tests
  // can't accidentally pass through dumb luck.
  final today = DateTime(2026, 5, 20);

  Objective objective(String id) => Objective(
        id: ObjectiveId(id),
        domain: ProgressionDomain.steps,
        metric: const StepsMetric(),
        scope: const TodayScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: 1,
      );

  ObjectiveCompletionEvent completionOn(DateTime day, {String id = 'obj'}) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return ObjectiveCompletionEvent(
      eventKey: 'objective|$id|$key|completed',
      timestamp: day,
      objectiveId: id,
      actualValue: 1,
      periodKey: key,
    );
  }

  group('EngineStreakSource — current streak', () {
    test(
      'three consecutive past days plus today yields a 4-day streak',
      () {
        final source = EngineStreakSource(clock: () => today);
        final ledger = LedgerSnapshot(objectiveCompletions: [
          completionOn(DateTime(2026, 5, 17)),
          completionOn(DateTime(2026, 5, 18)),
          completionOn(DateTime(2026, 5, 19)),
          completionOn(DateTime(2026, 5, 20)),
        ]);
        final summary = source.summarizeByObjective(
          ledger: ledger,
          objectives: [objective('obj')],
        )['obj']!;

        expect(summary.currentStreak, 4);
        expect(summary.bestStreak, 4);
      },
    );

    test(
      'one gap day collapses the streak to the post-gap run',
      () {
        // 17 ✓ 18 ✗ 19 ✓ 20 ✓ → current streak is 2, best is 2.
        final source = EngineStreakSource(clock: () => today);
        final ledger = LedgerSnapshot(objectiveCompletions: [
          completionOn(DateTime(2026, 5, 17)),
          completionOn(DateTime(2026, 5, 19)),
          completionOn(DateTime(2026, 5, 20)),
        ]);
        final summary = source.summarizeByObjective(
          ledger: ledger,
          objectives: [objective('obj')],
        )['obj']!;

        expect(summary.currentStreak, 2);
        expect(summary.bestStreak, 2);
      },
    );

    test(
      'yesterday-only streak stays alive (player has not logged today yet)',
      () {
        final source = EngineStreakSource(clock: () => today);
        final ledger = LedgerSnapshot(objectiveCompletions: [
          completionOn(DateTime(2026, 5, 17)),
          completionOn(DateTime(2026, 5, 18)),
          completionOn(DateTime(2026, 5, 19)),
        ]);
        final summary = source.summarizeByObjective(
          ledger: ledger,
          objectives: [objective('obj')],
        )['obj']!;

        // 17 → 18 → 19 with today empty: streak still 3 because the
        // walk anchors at yesterday when today is missing.
        expect(summary.currentStreak, 3);
      },
    );
  });

  group('EngineStreakSource — DST safety', () {
    // CET spring-forward in 2026 happens on Sunday March 29 at 02:00
    // local (clocks jump 02:00 → 03:00). A streak that includes both
    // March 28 and 29 must survive that boundary — earlier
    // implementations subtracted `Duration(days: 1)` (86 400 absolute
    // seconds) and silently lost the day around the transition
    // because the resulting probe landed at 23:00 of the previous
    // local day, missing the midnight-keyed set entry.
    final afterDst = DateTime(2026, 3, 30); // Monday after spring-forward.

    test(
      'spring-forward day pair (March 28–29 CET 2026) reads as a continuous '
      'streak',
      () {
        final source = EngineStreakSource(clock: () => afterDst);
        final ledger = LedgerSnapshot(objectiveCompletions: [
          completionOn(DateTime(2026, 3, 28)),
          completionOn(DateTime(2026, 3, 29)),
          completionOn(DateTime(2026, 3, 30)),
        ]);
        final summary = source.summarizeByObjective(
          ledger: ledger,
          objectives: [objective('obj')],
        )['obj']!;

        expect(
          summary.currentStreak,
          3,
          reason:
              'Calendar-day arithmetic must bridge the DST boundary; using '
              'Duration(days: 1) would clip this to 2 in any local time zone '
              'that observes spring-forward DST.',
        );
        expect(summary.bestStreak, 3);
      },
    );

    test(
      'best-streak scan also bridges the DST boundary',
      () {
        // Three-day run with a gap before the anchor — the best
        // streak scan walks the sorted dates and must treat
        // Mar 27 → 28 → 29 as contiguous even though the run spans
        // the local DST transition. A historical earlier 2-day run
        // confirms `best` actually picks the larger of two
        // candidates rather than the most-recent one.
        final earlierAnchor = DateTime(2026, 4, 5);
        final source = EngineStreakSource(clock: () => earlierAnchor);
        final ledger = LedgerSnapshot(objectiveCompletions: [
          completionOn(DateTime(2026, 3, 20)),
          completionOn(DateTime(2026, 3, 21)),
          completionOn(DateTime(2026, 3, 27)),
          completionOn(DateTime(2026, 3, 28)),
          completionOn(DateTime(2026, 3, 29)),
        ]);
        final summary = source.summarizeByObjective(
          ledger: ledger,
          objectives: [objective('obj')],
        )['obj']!;

        // Current streak is 0 (today + yesterday both empty).
        expect(summary.currentStreak, 0);
        // Best streak must still see Mar 27 → 28 → 29 as contiguous
        // and pick the longer run over the earlier Mar 20–21 pair.
        expect(summary.bestStreak, 3);
      },
    );
  });
}
