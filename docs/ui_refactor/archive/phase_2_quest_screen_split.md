# Phase 2 — Quest screen split ✅ shipped 2026-05-22

## Context

Before this phase, [quests_screen.dart](../../../lib/features/progression_engine/presentation/quests_screen.dart) was 817 LoC. Phase 1.1 had already deleted the four private section widget classes (`_ChapterSection`, `_LongTermSection`, `_CompletedSection`, `_LockedSection`) by inlining them as `_QuestsScreenV2State` methods returning `List<Widget>` (so each card becomes its own top-level `ListView` lazy entry). What remained mixed into the screen file was:

- `QuestSectionPanel` — public widget kept for [the existing widget test](../../../test/features/progression_engine/quest_section_panel_test.dart) (renders one daily/weekly section in isolation).
- `_NextChapterLockedTeaser` — private "next chapter coming" tile rendered at the tail of the JOURNEY section.
- `buildQuestSectionItems(...)` — top-level free function consumed by both the screen (splatted into the flat ListView) and `QuestSectionPanel` (wrapped in a Column).
- `_QuestSectionHint` — private helper that takes a `BuildContext` so the helper function doesn't have to.

Phase 2 moved these into `lib/features/progression_engine/presentation/sections/`.

## What shipped

1. **New directory** `lib/features/progression_engine/presentation/sections/`.

2. **[sections/quest_section_panel.dart](../../../lib/features/progression_engine/presentation/sections/quest_section_panel.dart)** — moved `buildQuestSectionItems(...)`, `QuestSectionPanel`, and the private `_QuestSectionHint` helper from `quests_screen.dart`. The helper and panel ship together so the helper's only `BuildContext`-touching dependency (`_QuestSectionHint`) lives next to it. Per the plan's Phase 2 question ("free function in sections/quest_section_items.dart or next to the panel"), they're co-located in `quest_section_panel.dart`.

3. **[sections/next_chapter_locked_teaser.dart](../../../lib/features/progression_engine/presentation/sections/next_chapter_locked_teaser.dart)** — moved `_NextChapterLockedTeaser` and made it public as `NextChapterLockedTeaser` (dropped `_` prefix per the plan's "extracted classes become public" rule).

4. **[quests_screen.dart](../../../lib/features/progression_engine/presentation/quests_screen.dart)** — removed the extracted code (lines 463–817), updated imports to consume from `sections/`, and updated the single call site (`_buildChapterItems`) to use `NextChapterLockedTeaser` (no underscore). Dropped now-unused imports: `progression_entry.dart`, `progression_node_catalog.dart`, `companion_buff.dart`, and `app_localizations.dart` is now indirect.

5. **[test/features/progression_engine/quest_section_panel_test.dart](../../../test/features/progression_engine/quest_section_panel_test.dart)** — updated import from `quests_screen.dart` to `sections/quest_section_panel.dart`. The test exercises `QuestSectionPanel` (the widget form), so the new file is the natural home.

## LoC outcome

| File | Before | After |
|---|---|---|
| `quests_screen.dart` | 817 | 462 |
| `sections/quest_section_panel.dart` | — | 195 |
| `sections/next_chapter_locked_teaser.dart` | — | 144 |

The screen sits at 462 LoC vs the plan's < 350 LoC target. The gap is the four `_QuestsScreenV2State` per-section builder methods (`_buildChapterItems`, `_buildLongTermItems`, `_buildCompletedItems`, `_buildLockedItems`) which were inlined into the State during Phase 1.1 because they call instance methods (`_pillKeyFor`, `_toggleExpanded`, `_claimQuest`). Pulling them out would mean either passing those callbacks through new section widgets (which would re-collapse the Phase 1.1 lazy-mount win unless they return `List<Widget>`) or threading them through new free functions — both adding indirection without structural payoff. The current shape keeps the section-shaped helpers next to the state they capture, which is the natural Dart organisation for stateful list builders. Re-targeting at < 500 LoC reflects that.

## What was NOT changed

- **No section behavior changes.** Pure file move + privacy change for `_NextChapterLockedTeaser` → `NextChapterLockedTeaser`.
- **No new lifecycle filtering** — that already lives in the provider (Phase 19 of the domain refactor).
- **No perf changes** — Phase 0–1.3 raster invariants stand.
- **`ExpandableQuestCard`, `ExpandedQuestScope`, `Engine*Card`** not touched.

## Verification

- `flutter analyze` clean for `lib/features/progression_engine/presentation/` and the updated test. Full repo analyze produces the same 95 pre-existing `unnecessary_const` infos in `progression_engine/domain/catalog/content/` baseline that Phase 0–1.3 also accepted.
- `flutter test test/features/progression_engine/ test/widgets/`: 189 tests pass (178 progression_engine + 11 widgets — the `quest_section_panel_test.dart` count is unchanged at 1).
- Manual: quest screen renders identically — same sections, same cards, same ordering, same JOURNEY locked-teaser at chapter tail.

## ADR

None. This is mechanical restructuring; the structural decisions it touches are already covered by the `expandable-quest-card-template` and `flat-listview-children-per-card` ADRs.

## Cold-start note

When extracting a screen-private helper that uses `BuildContext` (e.g. `Theme.of`), keep it next to the helper / widget that consumes it rather than promoting it to a screen-level method — moving the helper to `sections/` then pulls the `Theme.of` indirection with it for free. The opposite case (a section-builder that needs the *State* — pill keys, expansion notifier, claim callback) belongs as a `State` method, not a section widget; promoting it to a widget re-collapses Phase 1.1's per-card lazy mount unless the widget returns `List<Widget>` (which then isn't really a widget). The rule: helpers that touch state stay in State; helpers that take state via parameters move to `sections/`.
