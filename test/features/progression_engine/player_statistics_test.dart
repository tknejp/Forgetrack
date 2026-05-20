import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/features/progression_engine/domain/evaluator/engine_streak_source.dart';
import 'package:forgetrack/features/progression_engine/domain/models/ledger_counters.dart';
import 'package:forgetrack/features/progression_engine/domain/models/player_statistics.dart';

void main() {
  group('PlayerStatistics', () {
    test('empty sentinel is safe to read for every domain', () {
      for (final domain in ProgressionDomain.values) {
        expect(PlayerStatistics.empty.streakFor(domain).currentStreak, 0);
        expect(PlayerStatistics.empty.streakFor(domain).bestStreak, 0);
      }
      expect(PlayerStatistics.empty.totalXp, 0);
      expect(PlayerStatistics.empty.level, 1);
    });

    test('streakFor returns the bundled summary when present', () {
      final summary = EngineStreakSummary(
        currentStreak: 7,
        bestStreak: 14,
        latestDate: DateTime(2026, 5, 20),
      );
      final stats = PlayerStatistics(
        streaksByDomain: {ProgressionDomain.steps: summary},
        counters: LedgerCounters.empty,
      );

      expect(stats.streakFor(ProgressionDomain.steps), summary);
      // Missing domains fall back to empty rather than throwing.
      expect(stats.streakFor(ProgressionDomain.body).currentStreak, 0);
    });

    test(
      'domainStreaks emits a row for every main domain in declared order',
      () {
        final stats = PlayerStatistics(
          streaksByDomain: {
            ProgressionDomain.steps: const EngineStreakSummary(
              currentStreak: 3,
              bestStreak: 9,
            ),
            ProgressionDomain.nutrition: const EngineStreakSummary(
              currentStreak: 0,
              bestStreak: 12,
            ),
          },
          counters: LedgerCounters.empty,
        );

        final rows = stats.domainStreaks();
        expect(rows.length, ProgressionDomain.values.length);
        // Order matches ProgressionDomain.values so the UI table
        // doesn't have to sort.
        expect(
          rows.map((r) => r.domain).toList(),
          ProgressionDomain.values,
        );
        // Populated and missing domains coexist — populated ones
        // carry real numbers; missing ones default to 0/0.
        expect(rows[0].currentStreak, 3);
        expect(rows[0].bestStreak, 9);
        expect(rows[1].currentStreak, 0);
        expect(rows[1].bestStreak, 12);
        expect(rows[2].currentStreak, 0);
        expect(rows[2].bestStreak, 0);
      },
    );

    test('forwards counters + level + XP verbatim', () {
      const counters = LedgerCounters(
        distinctActiveDays: 42,
        totalQuestCompletions: 17,
      );
      const stats = PlayerStatistics(
        streaksByDomain: <ProgressionDomain, EngineStreakSummary>{},
        counters: counters,
        totalXp: 12345,
        level: 7,
      );

      expect(stats.counters.distinctActiveDays, 42);
      expect(stats.counters.totalQuestCompletions, 17);
      expect(stats.totalXp, 12345);
      expect(stats.level, 7);
    });
  });
}
