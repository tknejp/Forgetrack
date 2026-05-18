// Phase 7 read-model accessor pin for PlayerQuestCatalog.
//
// The catalog backs every quest-screen lifecycle-filter decision
// from Phase 7 onward and is the read substrate Phase 8
// (PlayerAchievementShelf) and Phase 13 (ChapterLifecycle) will
// follow. The named accessors (.all, .locked, .available, .pendingClaim,
// .claimed, .among, .where) are what screen code reaches for; this
// test pins their semantics + the byId lookup + the empty sentinel.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_quest.dart';
import 'package:forgetrack/domain/progression/player/player_quest_catalog.dart';
import 'package:forgetrack/domain/progression/player/player_quest_lifecycle.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 5, 18, 12);

  PlayerQuest entry(
    String id,
    PlayerQuestLifecycle lifecycle,
  ) {
    return PlayerQuest(
      id: QuestId(id),
      lifecycle: lifecycle,
      evaluatedAt: evaluatedAt,
    );
  }

  group('PlayerQuestCatalog.empty sentinel', () {
    test('exposes empty iterables + null lookups', () {
      const cat = PlayerQuestCatalog.empty;
      expect(cat.length, 0);
      expect(cat.isEmpty, isTrue);
      expect(cat.isNotEmpty, isFalse);
      expect(cat.all, isEmpty);
      expect(cat.locked, isEmpty);
      expect(cat.available, isEmpty);
      expect(cat.pendingClaim, isEmpty);
      expect(cat.claimed, isEmpty);
      expect(cat.byId(const QuestId('any')), isNull);
      expect(cat.contains(const QuestId('any')), isFalse);
    });
  });

  group('PlayerQuestCatalog.fromEntries', () {
    test('preserves insertion order in .all', () {
      final cat = PlayerQuestCatalog.fromEntries([
        entry('a', const QuestLocked()),
        entry('b', const QuestAvailable(actual: 0, target: 1, progress: 0)),
        entry('c', const QuestClaimed(finalXp: 100)),
      ]);
      expect(cat.all.map((q) => q.id.value).toList(), ['a', 'b', 'c']);
    });

    test('duplicate ids keep the last occurrence', () {
      final cat = PlayerQuestCatalog.fromEntries([
        entry('a', const QuestLocked()),
        entry('a', const QuestClaimed(finalXp: 230)),
      ]);
      expect(cat.length, 1);
      expect(cat.byId(const QuestId('a'))!.lifecycle,
          const QuestClaimed(finalXp: 230));
    });
  });

  group('Lifecycle accessors', () {
    final cat = PlayerQuestCatalog.fromEntries([
      entry('locked-a', const QuestLocked()),
      entry('locked-b', const QuestLocked()),
      entry('avail-a', const QuestAvailable(
        actual: 3000,
        target: 10000,
        progress: 0.3,
      )),
      entry('pend-a', const QuestCompletedPendingClaim(previewXp: 230)),
      entry('claimed-a', const QuestClaimed(finalXp: 230)),
      entry('claimed-b', const QuestClaimed(finalXp: 500)),
    ]);

    test('locked returns only QuestLocked entries', () {
      expect(cat.locked.map((q) => q.id.value).toList(),
          ['locked-a', 'locked-b']);
    });

    test('available returns only QuestAvailable entries', () {
      expect(cat.available.map((q) => q.id.value).toList(), ['avail-a']);
    });

    test('pendingClaim returns only QuestCompletedPendingClaim entries', () {
      expect(cat.pendingClaim.map((q) => q.id.value).toList(), ['pend-a']);
    });

    test('claimed returns only QuestClaimed entries', () {
      expect(cat.claimed.map((q) => q.id.value).toList(),
          ['claimed-a', 'claimed-b']);
    });

    test('the four filters partition .all (no overlap, full coverage)', () {
      final ids = {
        ...cat.locked.map((q) => q.id),
        ...cat.available.map((q) => q.id),
        ...cat.pendingClaim.map((q) => q.id),
        ...cat.claimed.map((q) => q.id),
      };
      expect(ids.length, cat.length);
      expect(ids, cat.all.map((q) => q.id).toSet());
    });
  });

  group('byId + contains + among', () {
    final cat = PlayerQuestCatalog.fromEntries([
      entry('a', const QuestLocked()),
      entry('b', const QuestClaimed(finalXp: 100)),
      entry('c', const QuestClaimed(finalXp: 200)),
    ]);

    test('byId returns the entry when present', () {
      expect(cat.byId(const QuestId('a'))!.lifecycle, const QuestLocked());
      expect(cat.byId(const QuestId('b'))!.lifecycle,
          const QuestClaimed(finalXp: 100));
    });

    test('byId returns null when absent', () {
      expect(cat.byId(const QuestId('missing')), isNull);
    });

    test('contains returns true when present, false when absent', () {
      expect(cat.contains(const QuestId('a')), isTrue);
      expect(cat.contains(const QuestId('missing')), isFalse);
    });

    test('among filters by ids and skips missing', () {
      final picks = cat
          .among([
            const QuestId('a'),
            const QuestId('missing'),
            const QuestId('c'),
          ])
          .map((q) => q.id.value)
          .toList();
      expect(picks, ['a', 'c']);
    });

    test('among returns empty for an empty input', () {
      expect(cat.among(const []), isEmpty);
    });
  });

  group('where (generic predicate)', () {
    final cat = PlayerQuestCatalog.fromEntries([
      entry('low', const QuestClaimed(finalXp: 100)),
      entry('high', const QuestClaimed(finalXp: 500)),
    ]);

    test('runs the predicate and returns matching entries', () {
      final picks = cat
          .where((q) =>
              q.lifecycle is QuestClaimed &&
              (q.lifecycle as QuestClaimed).finalXp >= 300)
          .map((q) => q.id.value)
          .toList();
      expect(picks, ['high']);
    });
  });

  group('Catalog equality', () {
    test('two catalogs with the same entries are equal', () {
      final a = PlayerQuestCatalog.fromEntries([
        entry('a', const QuestLocked()),
        entry('b', const QuestClaimed(finalXp: 100)),
      ]);
      final b = PlayerQuestCatalog.fromEntries([
        entry('a', const QuestLocked()),
        entry('b', const QuestClaimed(finalXp: 100)),
      ]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different entry payloads break equality', () {
      final a = PlayerQuestCatalog.fromEntries([
        entry('a', const QuestClaimed(finalXp: 100)),
      ]);
      final b = PlayerQuestCatalog.fromEntries([
        entry('a', const QuestClaimed(finalXp: 200)),
      ]);
      expect(a, isNot(b));
    });
  });
}
