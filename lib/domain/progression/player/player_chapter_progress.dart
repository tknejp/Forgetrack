import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import 'chapter_lifecycle.dart';
import 'player_chapter.dart';

/// Read-only projection of every Chapter catalog row + its current
/// [ChapterLifecycle] state for the active player.
///
/// Phase 13 mirror of [PlayerQuestCatalog] / [PlayerAchievementShelf]
/// / [Inventory]: same construction contract (factory from entries,
/// immutable map wrapped unmodifiable), same accessor vocabulary,
/// same empty sentinel. Naming follows the proposal (`docs/domain_model
/// /proposal.md` §2.4) — "progress" reads as the natural collection
/// noun for chapter-state aggregation.
///
/// **Construction.** Build via `PlayerChapterProgressService` in
/// `lib/features/progression_engine/application/`. The service takes
/// primitive inputs (chapter wrappers + completed node id set +
/// earliest completion lookup + chain helpers) so this surface stays
/// pure-domain — no Flutter / l10n / provider imports.
///
/// **Empty state.** [PlayerChapterProgress.empty] is the sentinel
/// for the pre-first-evaluation window. Returns empty iterables and
/// null lookups so widgets don't need null checks at every site.
///
/// **Iteration order.** [all] returns values in catalog insertion
/// order (Dart `Map` insertion-order guarantee); lifecycle-filtered
/// iterables preserve that order.
@immutable
class PlayerChapterProgress {
  /// Construct from an iterable of [PlayerChapter] entries.
  /// Duplicate ids keep the last occurrence — matches Dart's
  /// `Map.fromEntries` semantics and the service contract.
  factory PlayerChapterProgress.fromEntries(
    Iterable<PlayerChapter> entries,
  ) {
    final map = <ChapterId, PlayerChapter>{};
    for (final entry in entries) {
      map[entry.id] = entry;
    }
    return PlayerChapterProgress._(Map.unmodifiable(map));
  }

  const PlayerChapterProgress._(this._entries);

  /// Sentinel for the pre-first-evaluation state. Exposed as `const`
  /// so callers default to it without allocations.
  static const PlayerChapterProgress empty =
      PlayerChapterProgress._(<ChapterId, PlayerChapter>{});

  final Map<ChapterId, PlayerChapter> _entries;

  /// Look up a single chapter projection by its typed id. Returns
  /// null when the id isn't in the progression map.
  PlayerChapter? byId(ChapterId id) => _entries[id];

  /// All chapter projections in catalog insertion order.
  Iterable<PlayerChapter> get all => _entries.values;

  /// Number of chapter rows in the projection. O(1).
  int get length => _entries.length;

  /// True when the projection has zero entries — typically the
  /// sentinel [PlayerChapterProgress.empty] before the first
  /// evaluation completes.
  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  /// True iff [id] is present (regardless of lifecycle).
  bool contains(ChapterId id) => _entries.containsKey(id);

  /// Chapters currently in [ChapterLocked]. Journey map renders these
  /// with a "Zamčeno" hint when they are within revealing distance.
  Iterable<PlayerChapter> get locked =>
      _entries.values.where((c) => c.lifecycle is ChapterLocked);

  /// Chapters in [ChapterUnlockedNotStarted] — opener fired but no
  /// chain step yet. Quest screen surfaces them as "Chapter X — start
  /// here" cards.
  Iterable<PlayerChapter> get unlockedNotStarted => _entries.values
      .where((c) => c.lifecycle is ChapterUnlockedNotStarted);

  /// Chapters in [ChapterInProgress] — at least one chain step done
  /// but the chapter is not finalised. Hero map highlight + chapter
  /// card progress bar consume this set.
  Iterable<PlayerChapter> get inProgress =>
      _entries.values.where((c) => c.lifecycle is ChapterInProgress);

  /// Chapters in [ChapterCompleted]. Quest screen / journey timeline
  /// render these as "Splněno dd.mm.yyyy".
  Iterable<PlayerChapter> get completed =>
      _entries.values.where((c) => c.lifecycle is ChapterCompleted);

  /// Count of completed chapters. Reads the iterable once. Backs the
  /// hero header "X / Y kapitol splněno" pill.
  int get completedCount => completed.length;

  /// Subset of [all] keyed by [ids] (filters out missing entries).
  /// Lets screen consumers pull a known bucket and ask the progress
  /// map for the matching projection slice in one pass.
  Iterable<PlayerChapter> among(Iterable<ChapterId> ids) sync* {
    for (final id in ids) {
      final entry = _entries[id];
      if (entry != null) yield entry;
    }
  }

  /// Apply [predicate] against every entry in insertion order.
  Iterable<PlayerChapter> where(bool Function(PlayerChapter) predicate) =>
      _entries.values.where(predicate);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayerChapterProgress) return false;
    if (other._entries.length != _entries.length) return false;
    for (final entry in _entries.entries) {
      if (other._entries[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
        _entries.entries.map((e) => Object.hash(e.key, e.value)),
      );

  @override
  String toString() => 'PlayerChapterProgress(length: $length)';
}
