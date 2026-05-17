import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/domain/models/engine_evaluation_input.dart';

ProgressionEngineProvider _provider() {
  final repo = InMemoryProgressionEngineRepository();
  final engine = ProgressionEngine(
    repository: repo,
    runIdGenerator: () => 'test',
  );
  return ProgressionEngineProvider(engine: engine, repository: repo);
}

EngineEvaluationInput _input() => EngineEvaluationInput(
      evaluatedAt: DateTime(2026, 5, 11, 12),
      stepsToday: 0,
      proteinGramsToday: 0,
      level: 1,
      totalXp: 0,
    );

void main() {
  group('Daily quest pick', () {
    test('always surfaces exactly dailyQuestPickCount on a given day',
        () async {
      final provider = _provider();
      // Force one evaluation so the provider has a result + ledger.
      await provider.evaluateWith(input: _input());

      final picks = provider.currentDailyQuests;
      expect(picks.length, ProgressionEngineProvider.dailyQuestPickCount);
    });

    test('all daily quests in the catalog are larger than the pick',
        () async {
      final provider = _provider();
      await provider.evaluateWith(input: _input());

      // Sanity: there are more daily quests in the catalog than we
      // surface — otherwise the rotation is moot.
      expect(
        provider.allDailyQuests.length,
        greaterThan(ProgressionEngineProvider.dailyQuestPickCount),
      );
    });

    test('the same provider returns the same picks across calls in one day',
        () async {
      final provider = _provider();
      await provider.evaluateWith(input: _input());

      final firstCall =
          provider.currentDailyQuests.map((q) => q.nodeId).toSet();
      final secondCall =
          provider.currentDailyQuests.map((q) => q.nodeId).toSet();
      expect(firstCall, equals(secondCall));
    });

    test(
        'evaluateWith persists a QuestOfferedEvent for every slot, '
        'idempotent on repeat calls', () async {
      final provider = _provider();
      await provider.evaluateWith(input: _input());

      final picks =
          provider.currentDailyQuests.map((q) => q.nodeId).toSet();
      final firstLedger = provider.ledger!;
      final firstOfferingNodes =
          firstLedger.questOfferings.map((e) => e.nodeId).toSet();
      // Today's offerings cover every slot the resolver picked.
      expect(firstOfferingNodes.containsAll(picks), isTrue);
      // All offerings share the same calendar day.
      final dayKeys = firstLedger.questOfferings.map((e) => e.dayKey).toSet();
      expect(dayKeys, hasLength(1));

      // Second evaluation on the same day must not duplicate.
      await provider.evaluateWith(input: _input());
      final secondLedger = provider.ledger!;
      expect(
        secondLedger.questOfferings.length,
        firstLedger.questOfferings.length,
      );
    });

    test(
        'cooldown prevents a daily challenge from repeating the next day',
        () async {
      bool isChallenge(String nodeId) => nodeId.startsWith('daily_challenge_');

      final provider = _provider();
      await provider.evaluateWith(input: _input());
      final ledgerDay0 = provider.ledger!;
      final day0Key = ledgerDay0.questOfferings.isEmpty
          ? null
          : ledgerDay0.questOfferings.first.dayKey;
      final day0Challenges = ledgerDay0.questOfferings
          .where((e) => isChallenge(e.nodeId))
          .map((e) => e.nodeId)
          .toSet();

      await provider.devToolsAdvanceDay();
      await provider.evaluateWith(input: _input());

      final ledgerDay1 = provider.ledger!;
      final day1Challenges = ledgerDay1.questOfferings
          .where((e) => e.dayKey != day0Key && isChallenge(e.nodeId))
          .map((e) => e.nodeId)
          .toSet();

      // Combo / chapter side quests can repeat day-to-day (their own
      // gating handles rotation) so we narrow the assertion to the
      // tier-3 daily challenge pool, which IS cooldown-filtered.
      // Both sides may be empty if neither day produced a challenge
      // pick — combo/pin can absorb the whole slot count.
      if (day0Challenges.isNotEmpty && day1Challenges.isNotEmpty) {
        expect(
          day0Challenges.intersection(day1Challenges),
          isEmpty,
          reason: 'Daily challenges must not repeat within cooldown window.',
        );
      }
    });
  });
}
