// Phase 8 read-model accessor pin for PlayerAchievementShelf.
//
// Mirrors PlayerQuestCatalog test shape (Phase 7) — same accessor
// vocabulary, same sentinel + partition contracts. The named filters
// (.locked, .inProgress, .unlocked) are what hero / journey consumers
// reach for; this test pins their semantics plus the byId / among /
// where contracts.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_achievement.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_lifecycle.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_shelf.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 5, 18, 12);

  PlayerAchievement entry(String id, PlayerAchievementLifecycle lifecycle) {
    return PlayerAchievement(
      id: AchievementId(id),
      lifecycle: lifecycle,
      evaluatedAt: evaluatedAt,
    );
  }

  group('PlayerAchievementShelf.empty sentinel', () {
    test('exposes empty iterables + null lookups', () {
      const shelf = PlayerAchievementShelf.empty;
      expect(shelf.length, 0);
      expect(shelf.isEmpty, isTrue);
      expect(shelf.isNotEmpty, isFalse);
      expect(shelf.all, isEmpty);
      expect(shelf.locked, isEmpty);
      expect(shelf.inProgress, isEmpty);
      expect(shelf.unlocked, isEmpty);
      expect(shelf.unlockedCount, 0);
      expect(shelf.byId(const AchievementId('any')), isNull);
      expect(shelf.contains(const AchievementId('any')), isFalse);
    });
  });

  group('PlayerAchievementShelf.fromEntries', () {
    test('preserves insertion order in .all', () {
      final shelf = PlayerAchievementShelf.fromEntries([
        entry('a', const AchievementLocked()),
        entry('b', const AchievementInProgress(actual: 0, target: 1)),
        entry('c', const AchievementUnlocked(finalXp: 100)),
      ]);
      expect(shelf.all.map((a) => a.id.value).toList(), ['a', 'b', 'c']);
    });

    test('duplicate ids keep the last occurrence', () {
      final shelf = PlayerAchievementShelf.fromEntries([
        entry('a', const AchievementLocked()),
        entry('a', const AchievementUnlocked(finalXp: 230)),
      ]);
      expect(shelf.length, 1);
      expect(
        shelf.byId(const AchievementId('a'))!.lifecycle,
        const AchievementUnlocked(finalXp: 230),
      );
    });
  });

  group('Lifecycle accessors', () {
    final shelf = PlayerAchievementShelf.fromEntries([
      entry('locked-a', const AchievementLocked()),
      entry('locked-b', const AchievementLocked()),
      entry('prog-a', const AchievementInProgress(actual: 3000, target: 10000)),
      entry('unlocked-a', const AchievementUnlocked(finalXp: 230)),
      entry('unlocked-b', const AchievementUnlocked(finalXp: 500)),
    ]);

    test('locked returns only AchievementLocked entries', () {
      expect(
        shelf.locked.map((a) => a.id.value).toList(),
        ['locked-a', 'locked-b'],
      );
    });

    test('inProgress returns only AchievementInProgress entries', () {
      expect(shelf.inProgress.map((a) => a.id.value).toList(), ['prog-a']);
    });

    test('unlocked returns only AchievementUnlocked entries', () {
      expect(
        shelf.unlocked.map((a) => a.id.value).toList(),
        ['unlocked-a', 'unlocked-b'],
      );
    });

    test('unlockedCount matches the unlocked iterable', () {
      expect(shelf.unlockedCount, 2);
    });

    test('the three filters partition .all (no overlap, full coverage)', () {
      final ids = {
        ...shelf.locked.map((a) => a.id),
        ...shelf.inProgress.map((a) => a.id),
        ...shelf.unlocked.map((a) => a.id),
      };
      expect(ids.length, shelf.length);
      expect(ids, shelf.all.map((a) => a.id).toSet());
    });
  });

  group('byId + contains + among', () {
    final shelf = PlayerAchievementShelf.fromEntries([
      entry('a', const AchievementLocked()),
      entry('b', const AchievementUnlocked(finalXp: 100)),
      entry('c', const AchievementUnlocked(finalXp: 200)),
    ]);

    test('byId returns the entry when present', () {
      expect(
        shelf.byId(const AchievementId('a'))!.lifecycle,
        const AchievementLocked(),
      );
    });

    test('byId returns null when absent', () {
      expect(shelf.byId(const AchievementId('missing')), isNull);
    });

    test('contains returns true when present, false when absent', () {
      expect(shelf.contains(const AchievementId('a')), isTrue);
      expect(shelf.contains(const AchievementId('missing')), isFalse);
    });

    test('among filters by ids, skips missing, preserves request order', () {
      final picks = shelf
          .among([
            const AchievementId('c'),
            const AchievementId('missing'),
            const AchievementId('a'),
          ])
          .map((a) => a.id.value)
          .toList();
      expect(picks, ['c', 'a']);
    });
  });

  group('where (generic predicate)', () {
    final shelf = PlayerAchievementShelf.fromEntries([
      entry('low', const AchievementUnlocked(finalXp: 100)),
      entry('high', const AchievementUnlocked(finalXp: 500)),
    ]);

    test('runs predicate and returns matching entries', () {
      final picks = shelf
          .where((a) =>
              a.lifecycle is AchievementUnlocked &&
              (a.lifecycle as AchievementUnlocked).finalXp >= 300)
          .map((a) => a.id.value)
          .toList();
      expect(picks, ['high']);
    });
  });

  group('Shelf equality', () {
    test('shelves with the same entries are equal', () {
      final a = PlayerAchievementShelf.fromEntries([
        entry('a', const AchievementLocked()),
        entry('b', const AchievementUnlocked(finalXp: 100)),
      ]);
      final b = PlayerAchievementShelf.fromEntries([
        entry('a', const AchievementLocked()),
        entry('b', const AchievementUnlocked(finalXp: 100)),
      ]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different entry payloads break equality', () {
      final a = PlayerAchievementShelf.fromEntries([
        entry('a', const AchievementUnlocked(finalXp: 100)),
      ]);
      final b = PlayerAchievementShelf.fromEntries([
        entry('a', const AchievementUnlocked(finalXp: 200)),
      ]);
      expect(a, isNot(b));
    });
  });
}
