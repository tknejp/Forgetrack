import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/chapter.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/chapter_lifecycle.dart';
import 'package:forgetrack/domain/progression/player/player_chapter_progress.dart';
import 'package:forgetrack/features/progression_engine/application/chapter_catalog_builder.dart';
import 'package:forgetrack/features/progression_engine/application/player_chapter_progress_service.dart';

void main() {
  final stamp = DateTime.utc(2026, 5, 18, 12);
  const service = PlayerChapterProgressService();

  // Build a minimal in-test ChapterCatalog so the lifecycle matrix
  // doesn't depend on whichever production chapter authoring lands
  // next. Two chapters with distinct shapes — one with a completion
  // node and one without — exercise both completion paths.
  final catalog = ChapterCatalog.fromEntries([
    Chapter(
      id: const ChapterId('test_chapter_a'),
      opener: const ProgressionEntryId('chapter_a_open'),
      steps: const [
        ProgressionEntryId('chapter_a_step1'),
        ProgressionEntryId('chapter_a_step2'),
      ],
      finale: const ProgressionEntryId('chapter_a_finale'),
      completion: const ProgressionEntryId('chapter_a_complete'),
      sideQuests: const [
        ProgressionEntryId('chapter_a_side1'),
      ],
    ),
    Chapter(
      id: const ChapterId('test_chapter_b_nofinaleclose'),
      opener: const ProgressionEntryId('chapter_b_open'),
      steps: const [
        ProgressionEntryId('chapter_b_step1'),
      ],
      finale: const ProgressionEntryId('chapter_b_finale'),
      // No completion node — finale firing is the terminal event.
    ),
  ]);

  DateTime? Function(String) makeLookup(Map<String, DateTime> at) =>
      (nodeId) => at[nodeId];

  group('PlayerChapterProgressService — ChapterLifecycle derivation',
      () {
    test('opener locked → ChapterLocked', () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {},
        lockedNodeIds: const {'chapter_a_open'},
        earliestCompletionAt: makeLookup(const {}),
        evaluatedAt: stamp,
      );
      final entry = progress.byId(const ChapterId('test_chapter_a'))!;
      expect(entry.lifecycle, isA<ChapterLocked>());
    });

    test('opener completed, no steps done → ChapterUnlockedNotStarted',
        () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {'chapter_a_open'},
        lockedNodeIds: const {},
        earliestCompletionAt: makeLookup({
          'chapter_a_open': DateTime.utc(2026, 5, 10),
        }),
        evaluatedAt: stamp,
      );
      final entry = progress.byId(const ChapterId('test_chapter_a'))!;
      expect(entry.lifecycle, isA<ChapterUnlockedNotStarted>());
      expect(
        (entry.lifecycle as ChapterUnlockedNotStarted).unlockedAt,
        DateTime.utc(2026, 5, 10),
      );
    });

    test('opener + one step done → ChapterInProgress with '
        '(currentChainNode, 1/2)', () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {
          'chapter_a_open',
          'chapter_a_step1',
        },
        lockedNodeIds: const {},
        earliestCompletionAt: makeLookup(const {}),
        evaluatedAt: stamp,
      );
      final entry = progress.byId(const ChapterId('test_chapter_a'))!;
      expect(entry.lifecycle, isA<ChapterInProgress>());
      final lifecycle = entry.lifecycle as ChapterInProgress;
      expect(lifecycle.stepsCompleted, 1);
      expect(lifecycle.stepsTotal, 2);
      expect(
        lifecycle.currentChainNodeId,
        const ProgressionEntryId('chapter_a_step2'),
      );
    });

    test('every step done, finale not yet → ChapterInProgress with '
        'finale as current chain node', () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {
          'chapter_a_open',
          'chapter_a_step1',
          'chapter_a_step2',
        },
        lockedNodeIds: const {},
        earliestCompletionAt: makeLookup(const {}),
        evaluatedAt: stamp,
      );
      final entry = progress.byId(const ChapterId('test_chapter_a'))!;
      final lifecycle = entry.lifecycle as ChapterInProgress;
      expect(lifecycle.stepsCompleted, 2);
      expect(lifecycle.stepsTotal, 2);
      expect(
        lifecycle.currentChainNodeId,
        const ProgressionEntryId('chapter_a_finale'),
      );
    });

    test('completion node fired → ChapterCompleted (with terminal '
        'timestamp from completion node, not finale)', () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {
          'chapter_a_open',
          'chapter_a_step1',
          'chapter_a_step2',
          'chapter_a_finale',
          'chapter_a_complete',
        },
        lockedNodeIds: const {},
        earliestCompletionAt: makeLookup({
          'chapter_a_complete': DateTime.utc(2026, 5, 15),
          'chapter_a_finale': DateTime.utc(2026, 5, 14),
        }),
        evaluatedAt: stamp,
      );
      final lifecycle =
          progress.byId(const ChapterId('test_chapter_a'))!.lifecycle
              as ChapterCompleted;
      // Completion node wins as the terminal event when present.
      expect(lifecycle.completedAt, DateTime.utc(2026, 5, 15));
    });

    test('chapter without completion node → finale firing is the '
        'terminal event', () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {
          'chapter_b_open',
          'chapter_b_step1',
          'chapter_b_finale',
        },
        lockedNodeIds: const {},
        earliestCompletionAt: makeLookup({
          'chapter_b_finale': DateTime.utc(2026, 5, 17),
        }),
        evaluatedAt: stamp,
      );
      final lifecycle = progress
          .byId(const ChapterId('test_chapter_b_nofinaleclose'))!
          .lifecycle as ChapterCompleted;
      expect(lifecycle.completedAt, DateTime.utc(2026, 5, 17));
    });

    test('PlayerChapterProgress partitions: locked + unlockedNotStarted '
        '+ inProgress + completed = all', () {
      final progress = service.build(
        chapters: catalog,
        completedNodeIds: const {'chapter_b_open'}, // unlockedNotStarted
        lockedNodeIds: const {'chapter_a_open'}, // locked
        earliestCompletionAt: makeLookup(const {}),
        evaluatedAt: stamp,
      );
      final sum = progress.locked.length +
          progress.unlockedNotStarted.length +
          progress.inProgress.length +
          progress.completed.length;
      expect(sum, progress.length);
      expect(progress.length, catalog.length);
    });
  });

  group('Chapter catalog wrapper', () {
    test('Chapter.chainLength = opener + steps + finale', () {
      final chapter = catalog.byId(const ChapterId('test_chapter_a'))!;
      expect(chapter.chainLength, 4); // 1 opener + 2 steps + 1 finale
    });

    test('Chapter.chainEntries yields opener → steps → finale '
        'in order', () {
      final chapter = catalog.byId(const ChapterId('test_chapter_a'))!;
      expect(
        chapter.chainEntries.toList(),
        const [
          ProgressionEntryId('chapter_a_open'),
          ProgressionEntryId('chapter_a_step1'),
          ProgressionEntryId('chapter_a_step2'),
          ProgressionEntryId('chapter_a_finale'),
        ],
      );
    });

    test('Chapter equality is order-sensitive on steps + sideQuests',
        () {
      final a = Chapter(
        id: const ChapterId('x'),
        opener: const ProgressionEntryId('o'),
        steps: const [
          ProgressionEntryId('s1'),
          ProgressionEntryId('s2'),
        ],
        finale: const ProgressionEntryId('f'),
      );
      final b = Chapter(
        id: const ChapterId('x'),
        opener: const ProgressionEntryId('o'),
        steps: const [
          ProgressionEntryId('s2'),
          ProgressionEntryId('s1'),
        ],
        finale: const ProgressionEntryId('f'),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('PlayerChapterProgress accessors', () {
    test('empty sentinel returns empty iterables', () {
      expect(PlayerChapterProgress.empty.length, 0);
      expect(PlayerChapterProgress.empty.all, isEmpty);
      expect(
        PlayerChapterProgress.empty.byId(const ChapterId('x')),
        isNull,
      );
    });
  });

  group('ChapterCatalogBuilder.build()', () {
    test('produces a non-empty catalog over the production '
        'ProgressionEntryCatalog (smoke)', () {
      // Phase 13 invariant: the production catalog has at least one
      // authored chapter (Forest Trial / Ruins Discipline / …). The
      // builder must materialise at least one Chapter from it.
      const builder = ChapterCatalogBuilder();
      final result = builder.build();
      expect(result.isNotEmpty, isTrue,
          reason: 'Production catalog should yield ≥ 1 chapter.');
      // Each chapter must have non-empty opener + finale ids.
      for (final chapter in result.all) {
        expect(chapter.opener.value, isNotEmpty);
        expect(chapter.finale.value, isNotEmpty);
      }
    });
  });
}
