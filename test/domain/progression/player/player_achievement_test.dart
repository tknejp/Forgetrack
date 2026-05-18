// Phase 8 VO contract pin for PlayerAchievement.
//
// PlayerAchievement is the projection unit inside
// PlayerAchievementShelf. Equality across (id, lifecycle, evaluatedAt)
// is load-bearing for the shelf's diff detection — Phase 8+ consumers
// (cosmetic UI, social profile sync) use shelf equality to skip
// downstream rebuilds.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_achievement.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_lifecycle.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 5, 18, 12);

  PlayerAchievement make({
    String id = 'first_steps',
    PlayerAchievementLifecycle lifecycle =
        const AchievementInProgress(actual: 5000, target: 10000),
    DateTime? when,
  }) {
    return PlayerAchievement(
      id: AchievementId(id),
      lifecycle: lifecycle,
      evaluatedAt: when ?? evaluatedAt,
    );
  }

  group('PlayerAchievement equality + hashCode', () {
    test('identical fields → equal', () {
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('differing id breaks equality', () {
      expect(make(id: 'a'), isNot(make(id: 'b')));
    });

    test('differing lifecycle breaks equality', () {
      expect(
        make(lifecycle: const AchievementLocked()),
        isNot(make(lifecycle: const AchievementUnlocked(finalXp: 100))),
      );
    });

    test('differing evaluatedAt breaks equality', () {
      expect(
        make(when: DateTime.utc(2026, 5, 18, 12)),
        isNot(make(when: DateTime.utc(2026, 5, 18, 13))),
      );
    });

    test('lifecycle payload diff propagates through equality', () {
      // Two AchievementInProgress with different actual are unequal,
      // so PlayerAchievement wrapping them is unequal — the shelf's
      // change detection sees per-tick progress updates.
      expect(
        make(lifecycle: const AchievementInProgress(actual: 3000, target: 10000)),
        isNot(
          make(lifecycle: const AchievementInProgress(actual: 6000, target: 10000)),
        ),
      );
    });
  });

  group('PlayerAchievement.copyWith', () {
    test('no override returns an identical value', () {
      final base = make();
      expect(base.copyWith(), base);
    });

    test('lifecycle override preserves id + evaluatedAt', () {
      final base = make();
      final swapped = base.copyWith(
        lifecycle: const AchievementUnlocked(finalXp: 250),
      );
      expect(swapped.lifecycle, const AchievementUnlocked(finalXp: 250));
      expect(swapped.id, base.id);
      expect(swapped.evaluatedAt, base.evaluatedAt);
    });
  });
}
