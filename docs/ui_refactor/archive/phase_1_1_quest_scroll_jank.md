# Phase 1.1 — Quest screen scroll jank investigation ✅ shipped 2026-05-22

## Why

After Phase 1 + the hero-pattern follow-up shipped, a fresh DevTools profile-mode trace on the quest screen still showed a **recurring ~22 ms jank frame during scroll** — not a one-time cost when a section first enters the viewport (the original Phase 0.3 hypothesis), but a per-scroll-tick stutter visible to the user ("scroll není smooth a opakovaně zadrhne se, nebo občas úplně zastaví").

## Trace evidence (2026-05-22)

| Slice | Wall (ms) | Occurrences |
|---|---|---|
| `VsyncProcessCallback` | 22.65 | 1 |
| `Animator::BeginFrame` | 22.64 | 1 |
| `LAYOUT (root)` | 21.85 | 1 |
| `LAYOUT` | 21.84 | 1 |
| `BUILD` | 21.14 | **4** |
| `COMPOSITING` | 0.20 | 1 |
| `PAINT` | 0.01 | 1 |

UI thread bound. Raster thread clean (PAINT + COMPOSITING < 0.5 ms — Phase 0.x raster invariants hold). The cost is 4 BUILD events per jank frame, ~5 ms each, all inside a single LAYOUT pass.

## Diagnosis

Rejected hypotheses (#1–#3 in the original plan block):

- **Provider notify during scroll.** Cards subscribe to nothing per-frame; only `ExpandedQuestScope` (aspect-gated InheritedModel). The engine provider's `_onSourceChanged` signature-checks before re-evaluating, and there are no timer / polling notifiers in the engine, fitness, nutrition, or goals providers that would fire during steady-state scroll.
- **Periodic timer / animation controller.** None in the section tree.
- **Section constructor closure churn.** Closures *would* matter if parent rebuilds were happening, but with no provider notify during scroll, the screen build doesn't re-run; the section widget instances stay identity-stable; cards aren't reconciled.

Root cause (hypothesis #4): **`ListView(children: [...sections])` makes each section a single child of `SliverChildListDelegate`, and each section wraps its N cards in a `Column`.** `SliverChildListDelegate` creates Elements *lazily per top-level child*, but a `Column` is a `MultiChildRenderObjectWidget` that eagerly mounts all of its children in one pass. So when a section's slot enters the cache extent during scroll, the section's Element creation cascades into eager mounting of all N card Elements in the same frame.

Trace pattern matches exactly: 1 LAYOUT pass = 1 section newly mounted; 4 BUILDs = the 4 cards inside that section all built in the same frame. ~5 ms per card × 4 = ~22 ms = the jank frame.

## Changes shipped

[lib/features/progression_engine/presentation/quests_screen.dart](../../../lib/features/progression_engine/presentation/quests_screen.dart):

1. **Section widget classes deleted** (`_ChapterSection`, `_LongTermSection`, `_CompletedSection`, `_LockedSection`) — these were private and only used by this screen. Replaced with `_QuestsScreenV2State` instance methods (`_buildChapterItems`, `_buildLongTermItems`, `_buildCompletedItems`, `_buildLockedItems`) that return `List<Widget>`.

2. **Top-level helper `buildQuestSectionItems(...)`** extracted as a free function returning `List<Widget>` for daily / weekly sections. The screen calls it; `QuestSectionPanel.build()` (kept as a widget for the existing widget test) wraps its result in a `Column` for stand-alone use.

3. **`_QuestsScreenV2State.build()` now composes a single flat `items: List<Widget>` list** containing every section header, hint, empty-line, card, and inter-card / inter-section spacer as top-level entries. That list becomes `ListView(children: items)`. Each card is now its own `SliverChildListDelegate` slot — element creation is lazy per-card.

4. **`_NextChapterLockedTeaser` widget kept** (private, unchanged) — it's already a single ListView entry under the new structure.

The visible UI is identical to before. The structural change is invisible to the user.

## Effect

- **Per-scroll-tick cost** drops from "one section's worth of cards (4× ~5 ms = ~22 ms)" to "one card (~5 ms)" as the cache boundary moves across the screen. Frame budget at 120 Hz is 8.3 ms — a single card fits, four didn't.
- **Card BUILDs spread across many scroll ticks** instead of clustering at section boundaries. Steady-state scroll has at most one card mounting per frame in the typical case.
- **No change to the cards themselves** — Phase 0.3 per-card `RepaintBoundary` still caches PAINT; cards remain pure `StatelessWidget` driven by constructor args + `ExpandedQuestScope` aspect.

## Re-trace expectation

Steady-state scroll frames should consistently fit the 8.3 ms / 120 Hz budget. The one-time "first scroll past a previously-unseen section" cost still exists (cards must mount the first time the user reaches them) but is now spread across multiple frames as each card crosses the cache boundary individually. Manual: scroll quest screen on a real device — no visible stutter, no "completely stops" moments.

## Verification

- `flutter analyze` clean for [lib/features/progression_engine/presentation/quests_screen.dart](../../../lib/features/progression_engine/presentation/quests_screen.dart) (project-wide baseline of 95 pre-existing `unnecessary_const` infos in domain catalog content — unrelated, unchanged).
- All 178 `flutter test test/features/progression_engine/` tests green, including `quest_section_panel_test.dart` (`QuestSectionPanel` widget kept stable for that test).
- Manual smoke (deferred to the user's device session — the perf characteristic is only observable on a real device).

## Cold-start note for fresh sessions

The rule baked in by Phase 1.1 is: **inside a scrollable feed, each card must be its own top-level child of the scrollable, not a child of an inner `Column` inside a "section" wrapper widget.** Wrapping cards in a `Column` defeats `SliverChildListDelegate`'s (and `SliverChildBuilderDelegate`'s) lazy-element mounting because a `Column` is a `MultiChildRenderObjectWidget` that mounts all its children in one pass.

When you want a logical "section" (header + cards) inside a scrollable list, structure it as a flat sequence of ListView entries — section header, then card, then card, then card, then a spacer — instead of one ListView entry per section. The screen build owns the flattening; per-section helper methods return `List<Widget>` of flat items, and the screen splats them into the ListView's children list with the spread operator (`...`). This pattern keeps section-level encapsulation while preserving lazy mounting at card granularity.

If you ever need to do the same thing in a `CustomScrollView`, the equivalent is `SliverList.builder` per section — each card is a separate index in the builder delegate so its Element + build run lazily as it crosses the cache extent. The `Column`-inside-`ListView`-child trap exists for any sliver-backed scrollable; the rule is the same.

`QuestSectionPanel` is kept as a `StatelessWidget` for the existing widget test that renders it stand-alone, but the screen no longer composes it — it composes `buildQuestSectionItems(...)` directly. Both paths share the same item-builder helper so they can't drift visually.
