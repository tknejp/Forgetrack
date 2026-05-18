// Phase 6 sealed lifecycle + bridge mapping pin.
//
// Two guarantees to keep tight:
//
// 1. **Sealed value semantics.** The four PlayerQuestLifecycle
//    subtypes are immutable value objects with == based on payload.
//    Widgets reach for `is QuestX` checks plus destructuring; both
//    paths need stable behaviour for the exhaustive-switch contract.
//
// 2. **Bridge mapping.** EngineQuestProgress.lifecycle derives the
//    sealed discriminator from the existing engine flags
//    (`isCompleted`, `isAvailableForClaim`, `isLockedByConditions`).
//    Phase 6 is a UI-behavior-preserving migration — any drift
//    between the old flag-based widget code and the new pattern-
//    matched widget code shows up here first. The mapping table
//    covers all 2^3 = 8 flag combinations so unintended precedence
//    changes get caught immediately.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_quest_lifecycle.dart';
import 'package:forgetrack/features/progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_node_definition.dart';

void main() {
  group('PlayerQuestLifecycle equality', () {
    test('QuestLocked is a value singleton', () {
      expect(const QuestLocked(), const QuestLocked());
      expect(const QuestLocked().hashCode, const QuestLocked().hashCode);
    });

    test('QuestAvailable equals on (actual, target, progress)', () {
      const a = QuestAvailable(actual: 1, target: 10, progress: 0.1);
      const b = QuestAvailable(actual: 1, target: 10, progress: 0.1);
      const c = QuestAvailable(actual: 2, target: 10, progress: 0.2);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('QuestCompletedPendingClaim equals on (previewXp, completedAt)', () {
      final completedAt = DateTime.utc(2026, 5, 18, 10);
      expect(
        QuestCompletedPendingClaim(previewXp: 230, completedAt: completedAt),
        QuestCompletedPendingClaim(previewXp: 230, completedAt: completedAt),
      );
      expect(
        const QuestCompletedPendingClaim(previewXp: 230),
        isNot(const QuestCompletedPendingClaim(previewXp: 240)),
      );
    });

    test('QuestClaimed equals on (finalXp, claimedAt)', () {
      final claimedAt = DateTime.utc(2026, 5, 18, 11);
      expect(
        QuestClaimed(finalXp: 230, claimedAt: claimedAt),
        QuestClaimed(finalXp: 230, claimedAt: claimedAt),
      );
      expect(
        const QuestClaimed(finalXp: 230),
        isNot(const QuestClaimed(finalXp: 240)),
      );
    });

    test('discrimination across subtypes', () {
      const locked = QuestLocked();
      const available =
          QuestAvailable(actual: 0, target: 10, progress: 0);
      const pending = QuestCompletedPendingClaim(previewXp: 100);
      const claimed = QuestClaimed(finalXp: 100);
      expect(locked, isNot(equals(available)));
      expect(available, isNot(equals(pending)));
      expect(pending, isNot(equals(claimed)));
      expect(claimed, isNot(equals(locked)));
    });
  });

  group('EngineQuestProgress.lifecycle bridge mapping', () {
    // The bridge collapses three booleans into one sealed
    // discriminator. The mapping table below enumerates all 8 flag
    // combinations and asserts the resulting subtype. Precedence
    // (isLockedByConditions wins over isCompleted wins over
    // isAvailableForClaim) is what keeps the chapter rollup +
    // daily-section resolver semantics intact: a locked-by-conditions
    // side-quest that the player finished before the chapter window
    // closed must still surface as Locked.

    EngineQuestProgress progress({
      bool isCompleted = false,
      bool isAvailableForClaim = false,
      bool isLockedByConditions = false,
    }) {
      return EngineQuestProgress(
        node: const DailyQuest(
          id: QuestId('q'),
          titleKey: _titleStub,
          descriptionKey: _descStub,
          objectiveId: 'obj',
          rewards: [],
        ),
        actualValue: 3,
        targetValue: 10,
        progress: 0.3,
        isCompleted: isCompleted,
        isAvailableForClaim: isAvailableForClaim,
        baseXp: 100,
        previewXp: 230,
        domain: ProgressionDomain.steps,
        isLockedByConditions: isLockedByConditions,
      );
    }

    test('(F,F,F) → QuestAvailable carrying live progress numbers', () {
      final p = progress();
      final lc = p.lifecycle;
      expect(lc, isA<QuestAvailable>());
      final available = lc as QuestAvailable;
      expect(available.actual, 3);
      expect(available.target, 10);
      expect(available.progress, 0.3);
    });

    test('(F,T,F) → QuestCompletedPendingClaim(previewXp)', () {
      final p = progress(isAvailableForClaim: true);
      final lc = p.lifecycle;
      expect(lc, isA<QuestCompletedPendingClaim>());
      expect((lc as QuestCompletedPendingClaim).previewXp, 230);
    });

    test('(T,F,F) → QuestClaimed(finalXp == previewXp)', () {
      final p = progress(isCompleted: true);
      final lc = p.lifecycle;
      expect(lc, isA<QuestClaimed>());
      expect((lc as QuestClaimed).finalXp, 230);
    });

    test('(T,T,F) → QuestClaimed wins over claim-pending', () {
      // isCompleted means the ledger has the completion event; the
      // claim-pending bit is a stale read in this combo. Bridge
      // resolves to Claimed so widgets show the muted "splněno"
      // pill, not the gold "vyzvednout" pill.
      final p = progress(isCompleted: true, isAvailableForClaim: true);
      expect(p.lifecycle, isA<QuestClaimed>());
    });

    test('(F,F,T) → QuestLocked', () {
      final p = progress(isLockedByConditions: true);
      expect(p.lifecycle, const QuestLocked());
    });

    test('(F,T,T) → QuestLocked wins over claim-pending', () {
      // Locked-by-conditions wins because the row is no longer
      // claimable from the player's perspective (e.g. chapter window
      // closed mid-claim). Drop the gold pill.
      final p = progress(
        isAvailableForClaim: true,
        isLockedByConditions: true,
      );
      expect(p.lifecycle, const QuestLocked());
    });

    test('(T,F,T) → QuestLocked wins over completed', () {
      // The chapter rollup + daily resolver rely on Locked taking
      // precedence so a finished side-quest of a closed chapter
      // doesn't keep advertising itself as completed in the active
      // surface.
      final p = progress(isCompleted: true, isLockedByConditions: true);
      expect(p.lifecycle, const QuestLocked());
    });

    test('(T,T,T) → QuestLocked wins over both', () {
      final p = progress(
        isCompleted: true,
        isAvailableForClaim: true,
        isLockedByConditions: true,
      );
      expect(p.lifecycle, const QuestLocked());
    });
  });

  group('Exhaustive switch contract', () {
    // Compile-time check: pattern matching on PlayerQuestLifecycle is
    // exhaustive across the four subtypes. If a future phase adds a
    // 5th subtype, this switch starts failing to compile and forces a
    // sweep of every widget consumer.
    String label(PlayerQuestLifecycle lc) => switch (lc) {
          QuestLocked() => 'locked',
          QuestAvailable() => 'available',
          QuestCompletedPendingClaim() => 'pending-claim',
          QuestClaimed() => 'claimed',
        };

    test('label maps all four subtypes', () {
      expect(label(const QuestLocked()), 'locked');
      expect(
        label(const QuestAvailable(actual: 0, target: 1, progress: 0)),
        'available',
      );
      expect(
        label(const QuestCompletedPendingClaim(previewXp: 1)),
        'pending-claim',
      );
      expect(label(const QuestClaimed(finalXp: 1)), 'claimed');
    });
  });
}

// Test-local localisation stubs. LocalizedText is
// `String Function(AppLocalizations l10n)`; the AppLocalizations
// import would drag flutter_localizations into the domain-side test,
// so we accept Object? and ignore it — the catalog row's title /
// description closures aren't exercised by the lifecycle tests.
String _titleStub(Object? _) => 'q';
String _descStub(Object? _) => 'q-desc';
