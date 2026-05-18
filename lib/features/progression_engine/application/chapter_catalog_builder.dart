import 'package:forgetrack/domain/progression/catalog/chapter.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';

import '../domain/catalog/progression_node_catalog.dart';
import '../domain/models/progression_node_definition.dart';

/// Walks [ProgressionEntryCatalog] once and produces a
/// [ChapterCatalog] aggregating every authored chapter's chain
/// entries (opener, steps, finale, optional completion, side-quests)
/// by `chapterId`.
///
/// Phase 13 introduces this builder as the bridge between the
/// feature-internal `ProgressionEntry` subtype hierarchy (in
/// `lib/features/progression_engine/`) and the pure-domain
/// [Chapter] / [ChapterCatalog] wrappers (in
/// `lib/domain/progression/catalog/`). The wrapper holds typed-id
/// references only — see the Chapter doc comment for the dependency
/// rationale.
///
/// **Chain ordering.** `ChapterStep` rows carry `chainOrder` (1-based
/// rank within the chapter chain). The builder sorts by that field
/// to produce a stable chain even if catalog literals are authored
/// out of order. Opener / finale slots are inferred from the
/// `ChapterOpener` / `ChapterFinale` subtype, not from chainOrder.
///
/// **Completion node lookup.** `ChapterCompletion` rows carry
/// `chapterId` directly. The builder picks the first match per
/// chapter id — there is exactly one per chapter today (chapter
/// content invariant; the validator enforces it elsewhere).
///
/// **Side-quests.** `ChapterSideQuest` `Quest` rows carry
/// `chapterId` via the inherited `Quest.chapterId` field. The
/// builder filters by subtype + chapter id; ordering follows
/// authoring order (catalog insertion).
///
/// **Stateless + side-effect free.** Const constructor; multiple
/// builders produce the same `ChapterCatalog` value. Cache the
/// output at the provider layer once per catalog version.
class ChapterCatalogBuilder {
  const ChapterCatalogBuilder({
    this.entryCatalog = const ProgressionEntryCatalog(),
  });

  final ProgressionEntryCatalog entryCatalog;

  /// Build the full [ChapterCatalog] from the entry catalog.
  /// Iterates the entry list once, groups by chapter id, then emits
  /// one [Chapter] per group.
  ChapterCatalog build() {
    final openersById = <String, ChapterOpener>{};
    final finalesById = <String, ChapterFinale>{};
    final completionsById = <String, ChapterCompletion>{};
    final stepsByChapter = <String, List<ChapterStep>>{};
    final sideQuestsByChapter = <String, List<ChapterSideQuest>>{};
    final orderedChapterIds = <String>[];

    void rememberChapter(String chapterId) {
      if (!orderedChapterIds.contains(chapterId)) {
        orderedChapterIds.add(chapterId);
      }
    }

    for (final entry in entryCatalog.build()) {
      switch (entry) {
        // ChapterOpener subtype's constructor requires `chapterId`,
        // but the Quest parent declares it nullable so destructuring
        // surfaces String?. Guard so the analyser stays happy.
        case ChapterOpener(:final chapterId):
          if (chapterId != null) {
            openersById[chapterId] = entry;
            rememberChapter(chapterId);
          }
        case ChapterFinale(:final chapterId):
          if (chapterId != null) {
            finalesById[chapterId] = entry;
            rememberChapter(chapterId);
          }
        case ChapterCompletion(:final chapterId):
          completionsById[chapterId] = entry;
          rememberChapter(chapterId);
        case ChapterStep(:final chapterId):
          if (chapterId != null) {
            stepsByChapter.putIfAbsent(chapterId, () => []).add(entry);
            rememberChapter(chapterId);
          }
        case ChapterSideQuest(:final chapterId):
          if (chapterId != null) {
            sideQuestsByChapter.putIfAbsent(chapterId, () => []).add(entry);
            rememberChapter(chapterId);
          }
        // Anything else is not chapter material and is ignored here.
        case _:
          break;
      }
    }

    final out = <Chapter>[];
    for (final chapterId in orderedChapterIds) {
      final opener = openersById[chapterId];
      final finale = finalesById[chapterId];
      if (opener == null || finale == null) {
        // Chapter without an opener or finale is malformed; skip
        // silently rather than throwing so a partially-authored
        // chapter doesn't crash the catalog build at app boot. The
        // separate catalog_validator surfaces the warning.
        continue;
      }
      final steps = (stepsByChapter[chapterId] ?? const <ChapterStep>[])
          .toList()
        ..sort((a, b) => (a.chainOrder ?? 0).compareTo(b.chainOrder ?? 0));
      out.add(
        Chapter(
          id: ChapterId(chapterId),
          opener: ProgressionEntryId(opener.id.value),
          steps: [
            for (final s in steps) ProgressionEntryId(s.id.value),
          ],
          finale: ProgressionEntryId(finale.id.value),
          completion: completionsById[chapterId] == null
              ? null
              : ProgressionEntryId(completionsById[chapterId]!.id.value),
          sideQuests: [
            for (final sq in sideQuestsByChapter[chapterId] ??
                const <ChapterSideQuest>[])
              ProgressionEntryId(sq.id.value),
          ],
        ),
      );
    }
    return ChapterCatalog.fromEntries(out);
  }
}
