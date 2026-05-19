import 'package:meta/meta.dart';

import 'ids.dart';

/// Aggregating catalog wrapper for one narrative chapter.
///
/// Phase 13 of the domain refactor extracts this explicit concept
/// from the previously-implicit chain that lived in
/// `chapter_*_content.dart` literal data (where chain ordering was
/// derived ad-hoc from `prerequisiteNodeIds` / `nextNodeIds`).
/// `Chapter` is a *read-only structural view* over the
/// `ProgressionEntry` rows that share a `chapterId`:
///
///   - exactly one [opener] (`ChapterOpener` row),
///   - zero-or-more [steps] in chain order (`ChapterStep` rows),
///   - exactly one [finale] (`ChapterFinale` row),
///   - an optional [completion] node (`ChapterCompletion` row — fires
///     `RewardGrant`s once the finale clears),
///   - zero-or-more [sideQuests] (`ChapterSideQuest` `Quest` rows
///     that participate in the chapter context but stay outside the
///     mandatory chain ordering).
///
/// **Identifier discipline.** Phase 13 honors the same id-only
/// reference pattern Phase 7 / 8 / 10 established for player-side
/// projections: the wrapper carries [ProgressionEntryId] references
/// to chain entries, **not** the catalog row objects themselves. This
/// keeps the wrapper in `lib/domain/progression/catalog/` (per
/// proposal §6) without importing `lib/features/progression_engine/`
/// where the concrete `ChapterOpener` / `ChapterStep` / `ChapterFinale`
/// / `ChapterCompletion` subtypes still live. Consumers that need
/// the catalog row chrome (title / asset / rewards) resolve via
/// `ProgressionEntryCatalog.definitionForId(id.value)` (same pattern
/// `PlayerQuest` / `PlayerAchievement` use).
///
/// **Immutability.** `const` ctor, unmodifiable list views, value
/// equality on the structural fields. The list orderings carry
/// semantic meaning (chain order for [steps], authoring order for
/// [sideQuests]) so equality is order-sensitive.
///
/// **Construction.** Build via `chapterCatalogFromEntries` or
/// `ChapterCatalog.build()` in the progression-engine application
/// layer (`lib/features/progression_engine/application/`). The
/// builder walks `ProgressionEntryCatalog`, groups by `chapterId`,
/// and derives chain ordering from the prerequisite graph. The
/// wrapper itself doesn't know how to build — it's a value carrier.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.3 (Chapter catalog row).
///   - `docs/domain_model/migration_plan.md` §Phase 13.
///   - ADR `chapter-catalog-wrapper` in
///     `docs/site/data/decisions.json`.
@immutable
class Chapter {
  Chapter({
    required this.id,
    required this.opener,
    required List<ProgressionEntryId> steps,
    required this.finale,
    this.completion,
    List<ProgressionEntryId> sideQuests = const [],
  })  : steps = List<ProgressionEntryId>.unmodifiable(steps),
        sideQuests = List<ProgressionEntryId>.unmodifiable(sideQuests);

  /// Stable narrative id (e.g. `'ruins_discipline'`, `'forest_trial'`).
  /// Matches the `chapterId` field on the underlying catalog rows.
  final ChapterId id;

  /// The chapter's opener entry (`ChapterOpener` row id). Always
  /// non-null — a chapter without an opener is malformed and the
  /// builder rejects it at construction.
  final ProgressionEntryId opener;

  /// Chain steps (`ChapterStep` row ids) in chain order. May be
  /// empty for chapters that go straight opener → finale.
  final List<ProgressionEntryId> steps;

  /// The chapter's finale entry (`ChapterFinale` row id). Always
  /// non-null — a chapter without a finale is malformed.
  final ProgressionEntryId finale;

  /// Optional `ChapterCompletion` row id. Null when the chapter
  /// doesn't ship a dedicated completion node (rewards collapsed
  /// onto the finale).
  final ProgressionEntryId? completion;

  /// `ChapterSideQuest` row ids that participate in the chapter
  /// context but stay off the mandatory chain. Authoring order
  /// preserved so screens can render them grouped by chapter
  /// without re-sorting.
  final List<ProgressionEntryId> sideQuests;

  /// Total chain entries (opener + steps + finale). Used by the
  /// chapter card's progress bar denominator before the completion
  /// node fires.
  int get chainLength => 2 + steps.length;

  /// Every chain entry id in chain order. Convenience for traversal
  /// when iteration order is the same for all chain phases.
  Iterable<ProgressionEntryId> get chainEntries sync* {
    yield opener;
    yield* steps;
    yield finale;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Chapter) return false;
    if (other.id != id) return false;
    if (other.opener != opener) return false;
    if (other.finale != finale) return false;
    if (other.completion != completion) return false;
    if (other.steps.length != steps.length) return false;
    for (var i = 0; i < steps.length; i++) {
      if (other.steps[i] != steps[i]) return false;
    }
    if (other.sideQuests.length != sideQuests.length) return false;
    for (var i = 0; i < sideQuests.length; i++) {
      if (other.sideQuests[i] != sideQuests[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        opener,
        finale,
        completion,
        Object.hashAll(steps),
        Object.hashAll(sideQuests),
      );

  @override
  String toString() =>
      'Chapter($id, opener: $opener, steps: ${steps.length}, '
      'finale: $finale, completion: $completion, '
      'sideQuests: ${sideQuests.length})';
}

/// Read-only collection of every authored [Chapter], keyed by id.
///
/// Built once at startup from `ProgressionEntryCatalog` in the
/// progression-engine application layer (see `chapter_catalog_builder.dart`).
/// Stays const-friendly: the underlying map is unmodifiable so
/// callers can stash references without worrying about mutation
/// (matches the [PlayerChapterProgress] / [Inventory] empty-sentinel
/// pattern).
@immutable
class ChapterCatalog {
  factory ChapterCatalog.fromEntries(Iterable<Chapter> entries) {
    final map = <ChapterId, Chapter>{};
    for (final entry in entries) {
      map[entry.id] = entry;
    }
    return ChapterCatalog._(Map.unmodifiable(map));
  }

  const ChapterCatalog._(this._entries);

  /// Sentinel for callers that need a const default before the
  /// builder runs (e.g. test fixtures).
  static const ChapterCatalog empty =
      ChapterCatalog._(<ChapterId, Chapter>{});

  final Map<ChapterId, Chapter> _entries;

  /// Look up a chapter by id.
  Chapter? byId(ChapterId id) => _entries[id];

  /// All chapters in insertion order.
  Iterable<Chapter> get all => _entries.values;

  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;

  /// True iff [id] is present.
  bool contains(ChapterId id) => _entries.containsKey(id);
}
