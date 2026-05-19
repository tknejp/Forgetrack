// Phase 8 sealed lifecycle pin for PlayerAchievementLifecycle.
//
// Three guarantees to keep tight:
//
// 1. Value semantics per subtype — equality on payload fields so the
//    shelf's change detection works (e.g. Phase 8+ consumer cache
//    invalidation, future Phase 16 evaluator output diffing).
//
// 2. Exhaustive switch contract over the three subtypes — adding a
//    fourth (e.g. AchievementHidden) should fail every consumer at
//    compile time.
//
// 3. No PendingClaim — V2 achievements are ClaimPolicy.automatic per
//    proposal §4.2. The sealed hierarchy is intentionally narrower
//    than PlayerQuestLifecycle.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_lifecycle.dart';

void main() {
  group('PlayerAchievementLifecycle equality', () {
    test('AchievementLocked is a value singleton', () {
      expect(const AchievementLocked(), const AchievementLocked());
      expect(const AchievementLocked().hashCode,
          const AchievementLocked().hashCode);
    });

    test('AchievementInProgress equals on (actual, target)', () {
      const a = AchievementInProgress(actual: 3, target: 10);
      const b = AchievementInProgress(actual: 3, target: 10);
      const c = AchievementInProgress(actual: 5, target: 10);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('AchievementUnlocked equals on (finalXp, unlockedAt)', () {
      final at = DateTime.utc(2026, 5, 18, 10);
      expect(
        AchievementUnlocked(finalXp: 230, unlockedAt: at),
        AchievementUnlocked(finalXp: 230, unlockedAt: at),
      );
      expect(
        const AchievementUnlocked(finalXp: 230),
        isNot(const AchievementUnlocked(finalXp: 240)),
      );
      // Different unlockedAt → unequal even with same finalXp.
      expect(
        AchievementUnlocked(
          finalXp: 230,
          unlockedAt: DateTime.utc(2026, 5, 18),
        ),
        isNot(
          AchievementUnlocked(
            finalXp: 230,
            unlockedAt: DateTime.utc(2026, 5, 19),
          ),
        ),
      );
    });

    test('discrimination across subtypes', () {
      const locked = AchievementLocked();
      const inProgress = AchievementInProgress(actual: 0, target: 10);
      const unlocked = AchievementUnlocked(finalXp: 100);
      expect(locked, isNot(equals(inProgress)));
      expect(inProgress, isNot(equals(unlocked)));
      expect(unlocked, isNot(equals(locked)));
    });
  });

  group('Exhaustive switch contract', () {
    // Compile-time check: pattern matching is exhaustive across the
    // three subtypes. If a future phase adds a 4th subtype, this
    // switch starts failing to compile, forcing a sweep of every
    // widget consumer.
    String label(PlayerAchievementLifecycle lc) => switch (lc) {
          AchievementLocked() => 'locked',
          AchievementInProgress() => 'in-progress',
          AchievementUnlocked() => 'unlocked',
        };

    test('label covers all three subtypes', () {
      expect(label(const AchievementLocked()), 'locked');
      expect(
        label(const AchievementInProgress(actual: 0, target: 1)),
        'in-progress',
      );
      expect(label(const AchievementUnlocked(finalXp: 1)), 'unlocked');
    });
  });
}
