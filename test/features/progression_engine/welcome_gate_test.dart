import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';

import '_engine_test_helpers.dart';

ProgressionEngineProvider _provider({bool evaluationEnabled = true}) {
  final repo = InMemoryProgressionEngineRepository();
  final engine = ProgressionEngine(
    repository: repo,
    runIdGenerator: () => 'test',
  );
  return ProgressionEngineProvider(
    engine: engine,
    repository: repo,
    evaluationEnabled: evaluationEnabled,
  );
}

void main() {
  group('Welcome evaluation gate', () {
    // The gate suppresses the ambient `refresh()` path so the
    // condition-less `welcome_to_journey` achievement can't auto-mint at
    // boot (before the cloud ledger merges a returning player's prior
    // completion). It is intentionally NOT applied to `evaluateWith`,
    // which tests + devtools call directly — so the rest of the engine
    // test-suite is unaffected.

    test('defaults to enabled so existing callers + tests are unaffected', () {
      expect(_provider().evaluationEnabled, isTrue);
    });

    test('can be constructed gated (fresh-install / reinstall path)', () {
      expect(_provider(evaluationEnabled: false).evaluationEnabled, isFalse);
    });

    test('setEvaluationEnabled toggles the gate', () {
      final provider = _provider(evaluationEnabled: false);
      provider.setEvaluationEnabled(true);
      expect(provider.evaluationEnabled, isTrue);
      provider.setEvaluationEnabled(false);
      expect(provider.evaluationEnabled, isFalse);
    });

    test(
        'activateAfterOnboarding opens the gate (safe with no bound source / '
        'no cloud sync)', () async {
      final provider = _provider(evaluationEnabled: false);
      // No source bound + no cloud-sync wrapper → the awaited pull is a
      // no-op and the internal refresh early-returns; the call must still
      // flip the gate open for the rest of the session.
      await provider.activateAfterOnboarding();
      expect(provider.evaluationEnabled, isTrue);
    });

    test('devToolsWipeLedger re-arms the gate so a re-run of onboarding stays '
        'gated until its finalize re-opens it', () async {
      final provider = _provider(evaluationEnabled: true);
      await provider.devToolsWipeLedger();
      expect(provider.evaluationEnabled, isFalse);
    });

    test(
        'evaluateWith is NOT gated — it still mints + queues a celebration '
        'while the ambient gate is closed', () async {
      final provider = _provider(evaluationEnabled: false);
      // Direct evaluateWith bypasses the gate (the engine test-suite + the
      // devtools wipe path rely on this). The condition-less welcome
      // achievement fires on the first evaluation against an empty ledger.
      final result = await provider.evaluateWith(
        context: buildTestContext(evaluatedAt: DateTime(2026, 5, 29, 12)),
      );
      expect(result, isNotNull);
      expect(
        provider.completedNodeIds.contains('welcome_to_journey'),
        isTrue,
        reason: 'welcome_to_journey is condition-less and mints on first eval',
      );
      expect(
        provider.pendingCelebrations,
        isNotEmpty,
        reason: 'a non-empty result is queued for the celebration host',
      );
    });
  });
}
