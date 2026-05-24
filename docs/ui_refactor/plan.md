# UI refactor plan — Trello #85

**Status:** Phase 0–3 + Phase 1.4 shipped (2026-05-22 → 2026-05-24). Phase 4 next (shell lazy pages).
**Scope:** Performance hotfix + structural split of presentation-layer hot-spots (10 screens > 1000 LoC) + extraction of reusable template widgets.
**Out of scope:** Visual design changes, theme token changes (FtTokens / AppTheme stay), cross-feature business logic.
**Pre-conditions:** Domain refactor closed (✅, 2026-05-19). Phase 21 lint baseline `widget-no-logic: 0` (✅) — must not regress during refactor.

This plan is **designed to be picked up by a fresh session at any phase**. Each phase block lists the files involved, what to do, what NOT to do, and verification steps. A cold-start session needs only this file + [docs/architecture.md](../architecture.md) + the Trello card.

---

## Status table

| Phase | Title | Status | Owner | Notes |
|---|---|---|---|---|
| 0 | Quest perf hotfix | ✅ shipped 2026-05-22 | — | See summary below |
| 0.1 | Expand-state scope | ✅ shipped 2026-05-22 | — | `ExpandedQuestScope` (InheritedModel) — only 2 cards rebuild on toggle |
| 0.2 | Card shadow raster cost | ✅ shipped 2026-05-22 | — | Dropped 22 px conditional glow + reduced chapter blur 14→8 |
| 0.3 | Per-card RepaintBoundary | ✅ shipped 2026-05-22 | — | Each `Engine*Card` self-wraps so scroll + sibling-expand don't invalidate the whole section's cache |
| 1 | EngineCard template extraction | ✅ shipped 2026-05-22 | — | `ExpandableQuestCard` template (205 LoC); 4 cards compose it; chapter bg moved to hero-style static `backgroundDecoration` (the `fixedHeader` band was a transitional fix, dropped in the hero-pattern follow-up); collapsed-card layout locked across expand state |
| 1.1 | Quest screen scroll jank investigation | ✅ shipped 2026-05-22 | — | Flattened ListView so each card is its own lazy mount; root cause was `Column`-wrapped sections mounting all N cards in one frame |
| 1.2 | Home screen perf audit | ✅ shipped 2026-05-22 | — | StatCard Phase 0–1 invariants + per-card provider subscriptions on home so a KT tick rebuilds only the calorie card |
| 1.3 | Home card expand animation cost | ✅ shipped 2026-05-22 | — | StatCard bg image moved from `Opacity + Image.asset(BlendMode.darken)` to `DecorationImage(opacity:)` — kills the per-paint `saveLayer`. Hero icon shadow blur 14→8 (Phase 0.2 invariant). Both expand-tick and open-card-scroll repaints are now within the 120 Hz raster budget. |
| 1.4 | Hero screen perf audit | ✅ shipped 2026-05-22 | — | `HeroScreen.build()` no longer watches the provider directly — `Selector<ProgressionEngineProvider, _HeroChrome>` (Dart 3 record) gates rebuilds to loading/error flips. Expensive `buildEngineAchievementViews` + sort moved into `_AchievementsSliverSection` (self-watches). Sliver list children are const. Tile + journey card shadow blur reduced to `Tokens.glowSm` (Phase 0.2). |
| 2 | Quest screen split | ✅ shipped 2026-05-22 | — | `QuestSectionPanel` + helper + `NextChapterLockedTeaser` moved to `presentation/sections/` |
| 3 | Large screen splits | ✅ shipped 2026-05-22 → 2026-05-24 | — | All 10 screens split (3 P1 + 4 P2 + 3 P3). Archived at [archive/phase_3_large_screen_splits.md](archive/phase_3_large_screen_splits.md) |
| 4 | Shell lazy pages | ⏳ pending | — | Replace eager 4-tab PageView |
| 5 | Shared template widgets | ⏳ pending | — | MetricCardWithTrend, UnlockConditionsBlock |
| 6 | Docs + ADR | ⏳ pending | — | Site JSONs, ADR for card template approach |

When a phase ships, **archive its detailed block** to `docs/ui_refactor/archive/phase_N_<title>.md` and replace it in this file with a one-paragraph summary + link. Keep this file living and focused on what's still open.

---

## Cold-start onboarding

If you're starting fresh, read in this order:

1. **This file's Status table** — find the next pending phase.
2. **That phase's block below** — it has everything you need.
3. [docs/architecture.md](../architecture.md) — layering rules, design tokens, dependency rules. Don't violate them in the refactor.
4. [lib/shared/widgets/](../../lib/shared/widgets/) — 26 existing reusable widgets. Reuse before adding new ones. Inventory:
   - **Foundation:** `plain_card`, `stat_card`, `screen_header`, `section_head`, `tab_pill`, `tiny_pill`, `progress_bar`, `screen_link_card`, `dashboard_card_assets`
   - **Domain primitives:** `xp_claim_pill`, `xp_sparkle_overlay`, `macro_row`, `stat_cell`, `stat_components`, `trend_chart`, `activity_row`
   - **Navigation/gestures:** `period_navigator`, `date_nav`, `swipe_period_gesture`, `drag_reveal_pager`, `top_level_app_bar`, `app_logo`, `profile_avatar_action`, `ft_back_button`, `ft_expand_chevron`, `detail_shortcut_button`
5. **Naming convention** in `lib/shared/widgets/`: no `Ft` prefix, one primary class per file, `snake_case` filename. New extractions follow this.

**General rules across phases:**

- **Per-screen refactor carries its own perf fix**, not a separate pass. If a screen has expensive getters, memoize them in the same commit that splits it.
- **No business-logic changes in widgets.** Phase 21 lint enforces `widget-no-logic: 0`. New extractions must stay pure presentation.
- **`AppLog` for sync / claim / progression steps.** Never `print()`.
- **Localization:** strings in [lib/l10n/app_en.arb](../../lib/l10n/app_en.arb) + [lib/l10n/app_cs.arb](../../lib/l10n/app_cs.arb). After edits, run `flutter gen-l10n`.
- **Verification per phase:** `flutter analyze` clean, relevant `flutter test` files green, manual smoke for affected screens.

---

## Phase 0 — Quest perf hotfix ✅ shipped 2026-05-22

DevTools traces showed two jank events: quest screen expand (~53 ms) and overview→quest swipe (~45 ms). The dominant cost was the expensive `currentLongTermQuests` / `currentChapterQuests` getters being called per frame during the PageView swipe (re-lays out both pages) and on every quest-screen rebuild.

**Changes shipped:**

- **Memoization** of three hot getters in [progression_engine_provider.dart](../../lib/features/progression_engine/application/progression_engine_provider.dart) — `currentLongTermQuests`, `currentChapterQuests`, `completedNodeIds` — using the same `Object.hash(identityHashCode(_ledger), _devDayOffset)` cache-key pattern as the existing `playerQuestCatalog` (cache fields declared at line 488). `completedNodeIds` now returns `Set.unmodifiable` to make the shared instance safe.
- **`RepaintBoundary`** around the `AnimatedSize` expanded body of [engine_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_quest_card.dart), [engine_chapter_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_chapter_card.dart), [engine_long_term_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_long_term_card.dart), [engine_completed_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_completed_quest_card.dart). Stops the parent ListView sliver from being marked dirty during expansion.
- **Hoisted `completedNodeIds` lookup** out of `_CompanionRow.build()` ([engine_long_term_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_long_term_card.dart)). `_AlsoUnlocks` now resolves the completion set once per build and passes `isUnlocked` as a constructor parameter to each companion row.
- **`_ImageFilterRenderObject` source identified:** not celebration (those are route-mounted) — it was `ColorFiltered` greyscale on **locked chapter art** in [quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart) (4 thumbnails × ~13 ms per matrix multiply = the trace's 52 ms / 4 occurrences). Wrapped in `RepaintBoundary` so Impeller caches the filtered output as a layer.

**Verification:** `flutter analyze` clean for touched files (95 pre-existing `unnecessary_const` infos in domain catalog content unrelated to this work). All 178 progression_engine tests green, drag_reveal_pager widget tests green.

**Re-trace expectation (next DevTools profile run):** `currentLongTermQuests` and `_LongTermSection` should drop out of the top wall-duration slices. Quest expand frame < 16 ms (was 53 ms). Swipe per-frame < 16 ms (was 45 ms peak).

> **Cold-start note for fresh sessions:** the memoization cache fields rely on the `_ledger` reference being **replaced** (not mutated in place) whenever quest state changes — the same assumption `playerQuestCatalog` already encodes. If a day rollover or new evaluation ever fails to invalidate (e.g. cached chapter chain shows yesterday's pin), check that `evaluateWith` actually reseats `_ledger` rather than mutating, and look at `_devDayOffset` flips for devtools day-advance.

## Phase 0.1 — Expand-state scope ✅ shipped 2026-05-22

A second DevTools trace after Phase 0 still showed jank on quest-card expand: `BUILD = 91 ms / 11 occurrences` per frame even though `LAYOUT (root)` had dropped to 1.5 ms (Phase 0 memoization fixed that). The new bottleneck: tapping a card called `setState(() => _expandedNodeId = …)` on `QuestsScreenV2`, which invalidated the entire screen build — every section, every card — even though at most two cards (previously- and newly-expanded) actually changed visual state.

**Changes shipped:**

- **New widget** [expanded_quest_scope.dart](../../lib/features/progression_engine/presentation/widgets/expanded_quest_scope.dart) — an `InheritedModel<String>` whose aspect is the per-card `nodeId`. `updateShouldNotifyDependent` marks dirty only the cards whose `nodeId` was either the old or new expanded id; every other dependent stays clean.
- **`QuestsScreenV2`** ([quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart)) — `_expandedNodeId` is now a `ValueNotifier<String?>` (disposed in `dispose()`); `_toggleExpanded` mutates the notifier instead of calling `setState`. The whole `ListView` is now wrapped in a `ValueListenableBuilder<String?>` whose `child:` parameter holds the stable ListView tree. When the notifier ticks, only the builder runs — it rebuilds the `ExpandedQuestScope` wrapper around the same untouched child. The scope's inherited-model machinery then marks only the affected cards dirty.
- **5 section classes** (`_ChapterSection`, `QuestSectionPanel` ×2 use sites, `_LongTermSection`, `_CompletedSection`) — dropped `expandedNodeId` constructor field and the `isExpanded: expandedNodeId == card.nodeId` derivation in their card-loop bodies. Sections no longer touch expansion state at all; they just pass `onToggleExpanded`.
- **4 `Engine*Card` classes** — dropped `isExpanded` constructor field. Each `build()` now resolves expansion via `final isExpanded = ExpandedQuestScope.isExpanded(context, quest.nodeId);` (or `entry.representative.nodeId` for completed). `EngineLongTermCard._buildCompanionPills` takes `isExpanded` as an extra parameter since helper methods don't have a `BuildContext`.

**Verification:** `flutter analyze` clean for all touched files (same 95 pre-existing `unnecessary_const` infos in domain catalog content unrelated). All 178 progression_engine tests green. No test constructed `Engine*Card` with `isExpanded:` directly, so the API change was safe.

**Re-trace expectation:** quest-card expand frame should drop from ~90 ms (post-Phase-0) to a handful of ms (just the two affected cards' builds), since `BUILD` count per frame goes from 11 down to ~2.

> **Cold-start note:** the pattern is now: the screen owns a `ValueNotifier<String?>`; an `InheritedModel<String>` wraps the children via `ValueListenableBuilder.child:`; child widgets call `ExpandedQuestScope.isExpanded(context, myId)` to subscribe to their own aspect. If you ever need to add another piece of cross-tree state that has the same "at most 2 widgets actually change" shape (e.g. focused tab, highlighted item), reuse this exact pattern — don't `setState` on a parent that's miles above the affected children.

## Phase 0.2 — Card shadow raster cost ✅ shipped 2026-05-22

A third DevTools trace after Phase 0.1 showed UI thread fast (light-blue bars short) but **raster thread janking for ~7 consecutive frames** during chapter expand. Diagnosis: each `Engine*Card` had a conditional `BoxShadow` with `blurRadius: Tokens.glowXl` (22 px) that activated on expand, plus the chapter card's static drop shadow was `blurRadius: 14`. During the `AnimatedSize` expand animation the card's silhouette changes per frame, so the box-shadow has to be re-rasterized fresh each frame — and a 22 px Gaussian blur on a card-sized rect doesn't fit in the 8.3 ms raster budget at 120 Hz.

**Changes shipped:**

- **[engine_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_quest_card.dart) + [engine_long_term_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_long_term_card.dart)** — dropped the conditional `if (isExpanded) BoxShadow(blurRadius: Tokens.glowXl, ...)` from the `AnimatedContainer` decoration. Cards keep their single static drop shadow (alpha 0.26, blur 10). The expand affordance now comes purely from the body sliding open + the `AnimatedContainer`'s border-colour interpolation (cheap, no blur).
- **[engine_completed_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_completed_quest_card.dart)** — dropped the `else if (isExpanded)` accent glow entirely. For claimable entries the gold glow is preserved but its alpha + blur params are now **fixed** (`alpha: 0.14`, `blur: 16`) instead of animating between collapsed and expanded states. Claimable vs claimed split still reads visually; the expand state no longer drives an animated 16→22 px blur per frame.
- **[engine_chapter_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_chapter_card.dart)** — static drop shadow `blurRadius` reduced from `14` to `Tokens.glowSm` (`8`). Chapter card has no conditional glow but the larger static blur was still expensive to re-rasterize each frame of expand (the card has a `DecorationImage` background that's redrawn at the new size on every tick, so per-frame cost stacked up). Halving the blur radius is the cheapest visual change that brings it under budget.

**Verification:** `flutter analyze` clean for the 4 cards (same 95 pre-existing `unnecessary_const` infos in domain catalog content unrelated). All 178 progression_engine tests green.

**Re-trace expectation:** raster bars during chapter expand should drop from ~7 red frames at >8.3 ms each to staying under the 120 Hz budget. The UI-thread bars were already fine after Phase 0.1; the goal here was getting the raster thread to keep up.

> **Cold-start note for fresh sessions:** the rule baked in by Phases 0–0.2 is _the raster thread's per-frame budget is the bottleneck at 120 Hz, not the UI thread_. When sizing or animating widgets that grow under `AnimatedSize`, avoid `BoxShadow(blurRadius: ≥ 12)` and avoid animating shadow params at all — both force Flutter to re-rasterize a Gaussian blur every frame on a changing silhouette. Prefer cheap visual flourishes for expand cues: border-colour interpolation (cheap), opacity fade-ins on a `RepaintBoundary` overlay (cheap once the boundary is cached), or sliding content via `AnimatedSize` (already chosen here).

## Phase 0.3 — Per-card RepaintBoundary ✅ shipped 2026-05-22

A fourth DevTools trace showed two remaining patterns: occasional UI jank (~12–30 ms) when scrolling the quest screen, and raster jank (~5 frames at ~20 ms) during chapter expand even after Phase 0.2's shadow trims. The trace's `RenderRepaintBoundary = 11.2 ms / 1 occurrence` plus `RenderViewport = 11.27 ms / 1` confirmed that the viewport was repainting a single large repaint-boundary layer per frame.

`ListView(children: […])` auto-inserts a `RepaintBoundary` around each **top-level child** (each section), but **not** around the cards inside each section. So when one card expanded, the whole section's cache invalidated and every sibling card re-rasterized too. Scroll inside a tall section repainted the entire section's layer each tick because the section straddled the viewport boundary.

**Changes shipped:**

- **Each `Engine*Card` self-wraps its returned widget in a `RepaintBoundary`** ([engine_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_quest_card.dart), [engine_chapter_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_chapter_card.dart), [engine_long_term_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_long_term_card.dart), [engine_completed_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_completed_quest_card.dart)). The boundary lives inside the card's `build()` so callers don't have to remember to add it.

**Effect:**

- **Scroll:** card layers are translated by the compositor (cheap GPU operation) instead of being re-rasterized. The section's outer boundary only re-rasterizes when its child layer references change, not on every scroll tick.
- **Expand of one card in a section:** only the expanding card's layer invalidates. Sibling cards stay cached. Section's outer boundary re-composites the per-card layers (cheap) instead of re-rasterizing every card.

**Memory trade-off:** each card now owns one extra rasterized layer (~ card dimensions × 4 bytes RGBA). For ~20 cards visible at peak that's a few MB of GPU memory, well within budget on a modern flagship.

**Verification:** `flutter analyze` clean for the 4 cards. All 178 progression_engine tests green.

**Re-trace expectation:** scroll frames should consistently fit the 8.3 ms / 120 Hz budget except when a previously-off-screen section first enters the viewport (one-time rasterization cost — unavoidable without further restructuring). Chapter expand raster cost should also drop: the chapter card's layer still re-rasterizes per frame (silhouette grows), but **only that card's** ~card-sized region, not the whole section's region.

> **Cold-start note for fresh sessions:** when adding new card-style widgets to a scrollable feed, **wrap their `build()` return in `RepaintBoundary`** by default. `ListView`/`SliverList` auto-wraps only at the top-level section granularity; cards inside sections need their own boundary to benefit from layer caching during scroll and to isolate their own animations from siblings. The rule of thumb: any widget that (1) gets repeated in a list, (2) has its own internal animation, or (3) is non-trivial to rasterize should self-wrap in `RepaintBoundary`.

---

## Phase 1 — EngineCard template extraction ✅ shipped 2026-05-22

The four engine cards (~2600 LoC) used to repeat the same animated container + border interpolation + drop shadow + AnimatedSize body + RepaintBoundary scaffolding inline. Phase 1 collected all of that into a slot-based [ExpandableQuestCard](../../lib/features/progression_engine/presentation/widgets/expandable_quest_card.dart) template (205 LoC) and rewrote each `Engine*Card.build()` to compose it. Constructor signatures are unchanged — section widgets in [quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart) are untouched.

The chapter card's bg image moved from a full-card `DecorationImage` (which re-sampled per frame on a growing silhouette — the Phase 0.3 raster bottleneck) to the template's optional `fixedHeader` slot — a constant-height `Positioned` band that doesn't grow with `AnimatedSize`. Visible structural change: the chain dots / progress row now sit on plain dark `0xFF111423` instead of on top of the darkened image. All Phase 0–0.3 perf invariants (top-level `RepaintBoundary`, `ExpandedQuestScope` subscription, no animated shadows, etc.) are baked into the template.

Full design record + per-card override table + LoC outcome: **[archive/phase_1_engine_card_template.md](archive/phase_1_engine_card_template.md)**.

> **Cold-start note for fresh sessions:** when adding a new "engine card" variant, compose `ExpandableQuestCard` — don't reinvent the shell. The template owns the perf invariants and you'll inherit them for free. If you ever need to change the shell (a new affordance, a perf tweak), change it in one place. **Bg images go on the template's `backgroundDecoration` parameter, NEVER on `AnimatedContainer.decoration` directly** — the hero-pattern follow-up to Phase 1 proved that image-bearing decoration on the animated container forces a per-tick `BoxDecoration.lerp` over `DecorationImage` that was the original chapter card's raster jank. Static `DecoratedBox` + `opacity` (not `BlendMode.darken`) is the path that works at 120 Hz.

---

## Phase 1.1 — Quest screen scroll jank investigation ✅ shipped 2026-05-22

A 2026-05-22 profile-mode trace showed `LAYOUT (root) = 21.85 ms / 1 occurrence` with `BUILD = 21.14 ms / 4 occurrences` per scroll-jank frame on the quest screen, raster thread clean. Root cause: `ListView(children: [...sections])` made each section a single child of `SliverChildListDelegate`, and each section wrapped its N cards in a `Column`. `SliverChildListDelegate` creates Elements lazily per top-level child, but `Column` is a `MultiChildRenderObjectWidget` that eagerly mounts all children in one pass — so a section entering the cache extent during scroll cascaded into mounting all of its cards in the same frame.

Fix: flattened the screen so each card is its own top-level `ListView` child. Section widgets (`_ChapterSection`, `_LongTermSection`, `_CompletedSection`, `_LockedSection`) became `_QuestsScreenV2State` methods returning `List<Widget>`. A shared free function `buildQuestSectionItems(...)` produces daily / weekly items; both `QuestSectionPanel` (kept as a widget for the existing test) and the screen call it. Card BUILDs now spread across many scroll ticks at ~1 card per cache-boundary crossing instead of clustering at section boundaries.

Full design record + diagnosis path + rejected hypotheses: **[archive/phase_1_1_quest_scroll_jank.md](archive/phase_1_1_quest_scroll_jank.md)**.

> **Cold-start note for fresh sessions:** inside a scrollable feed, each card must be its own top-level child of the scrollable, **not** a child of an inner `Column` inside a "section" wrapper widget. Wrapping cards in a `Column` defeats `SliverChildListDelegate` / `SliverChildBuilderDelegate` lazy-element mounting because `Column` is a `MultiChildRenderObjectWidget` that mounts all its children in one pass. The pattern: per-section helper methods return `List<Widget>` of flat items (header, hint, cards interleaved with spacers); the screen splats them into the ListView's children list with `...`. Keeps section-level encapsulation while preserving lazy mounting at card granularity. If migrating to `CustomScrollView`, the equivalent is `SliverList.builder` per section — same rule, same trap to avoid.

---

## Phase 1.2 — Home screen perf audit ✅ shipped 2026-05-22

User reported "more janks on home than on quest screen" after Phase 1.1 closed the quest scroll case. Audit found three issues: (1) `OverviewScreen.build()` was watching 6 providers, so every fitness/KT tick rebuilt the whole tree + all 5 dashboard cards; (2) `ReorderableListView.builder(shrinkWrap: true)` defeated its own laziness (accepted — only 5 cards, low magnitude); (3) `StatCard` was missing the Phase 0–1 invariants (no top-level `RepaintBoundary`, no inner boundary on the expanded `AnimatedSize` body), so a card expand re-rasterized the whole sliver per tick.

Fixed: added the Phase 0–1 invariants to `StatCard` in [lib/shared/widgets/stat_card.dart](../../lib/shared/widgets/stat_card.dart) (the win covers every screen composing it). Refactored [lib/features/home/presentation/overview_screen.dart](../../lib/features/home/presentation/overview_screen.dart) so each dashboard card is its own widget with its own `context.watch`; layout decisions (HC prompt collapsing, KT prompt collapsing, card order) sit in a `_HomeCardList` parent using `Selector2` on a Dart 3 record of derived values. A `KalorickeTabulkyProvider` food-log tick now only rebuilds the calorie card; steps/weight/activity/sleep stay cached.

Full design record + rebuild table: **[archive/phase_1_2_home_perf_audit.md](archive/phase_1_2_home_perf_audit.md)**.

> **Cold-start note for fresh sessions:** when a screen renders N cards each consuming different provider subsets, do NOT `context.watch` at the screen level — that fans every notify out to every card. Push each card into its own `StatelessWidget` that watches only what it reads. Keep screen-level layout decisions in a separate widget that uses `Selector` (or `Selector2`/`Selector3`) on a small derived value — a Dart 3 record gives structural equality for free. The pattern paired with the `StatCard` Phase 0–1 invariants (top-level + inner `RepaintBoundary`) generalizes across any multi-card dashboard. Don't reach for `AutomaticKeepAliveClientMixin` to "freeze" a card — that masks the cascade without fixing it.

---

## Phase 1.3 — Home card expand animation cost ✅ shipped 2026-05-22

Post-Phase-1.2 the user captured a 120 Hz profile-mode trace that showed frames in the 10–13 ms range for the full 260 ms `AnimatedSize` expand (8.3 ms budget) plus raster janks up to ~20 ms when scrolling past an already-open card. Closed-card scroll was fine — Phase 1.2's `RepaintBoundary` already handled that case.

The "scroll over open card janks too" pattern was the diagnostic: it's steady-state with no animation running, so per-tick relayout couldn't explain it. The actual cost was per-paint raster ops inside `StatCard`'s repaint boundary. Two fixes landed in [lib/shared/widgets/stat_card.dart](../../lib/shared/widgets/stat_card.dart): (1) `_buildBackgroundImage()` moved from `Positioned.fill + IgnorePointer + Opacity + Image.asset(color, BlendMode.darken)` to `Positioned.fill + IgnorePointer + DecoratedBox(decoration: BoxDecoration(image: DecorationImage(opacity:)))` — `Opacity`'s per-paint `saveLayer` was the single biggest cost, and `BlendMode.darken` was a redundant pipeline op (Phase 1 hero-pattern lesson); (2) hero icon shadow `blurRadius` reduced from 14 to `Tokens.glowSm` (8) per the Phase 0.2 invariant for widgets that re-rasterize per frame.

`AnimatedSize`→`SizeTransition` was considered but rejected: it would only help the expand case, not the open-scroll case, and the bg-image fix addresses both. Reserved as next lever if a future trace shows residual UI-bound jank during expand specifically.

Full design record + verification + lessons codified: **[archive/phase_1_3_home_card_expand_cost.md](archive/phase_1_3_home_card_expand_cost.md)**.

> **Cold-start note for fresh sessions:** when authoring a reusable card widget with a background image (`StatCard`, `ExpandableQuestCard`, anything that lives in a scrollable feed), use `DecorationImage(opacity:)` for the dimming — never wrap the image in an `Opacity` widget, and never use `colorBlendMode` for a darken pass. `Opacity`'s `saveLayer` is paid every paint, which compounds with `AnimatedSize` ticks and with overscroll repaints into raster jank. The wider rule for any widget inside an `AnimatedSize`-driven expand: the card's whole layer re-rasterizes per tick, so every `saveLayer`, every blur ≥ 12 px, every `BackdropFilter`, and every `ColorFiltered` (without its own boundary) is paid ~16× over a 260 ms animation. Audit each before merging.

---

## Phase 1.4 — Hero screen perf audit ✅ shipped 2026-05-22

User reported visible scroll jank on the hero tab at 120 Hz without needing a profiler. Audit found the same Phase 1.2-style cascade we already fixed on home: `HeroScreen.build()` was watching `ProgressionEngineProvider` at the screen level AND calling `buildEngineAchievementViews(progression, l10n)` + two list-comprehension sorts on every notify. `ProgressionOverviewSection` and `JourneyPreviewCard` (both inside the same `SliverList`) each had their own `context.watch` too — so a single engine tick fanned out into three independent recomputes plus the screen-level achievement build, and the `SliverList` delegate identity changed each time.

Fixed in [lib/features/progression_engine/presentation/hero_screen.dart](../../lib/features/progression_engine/presentation/hero_screen.dart) and [lib/features/journey/presentation/widgets/journey_preview_card.dart](../../lib/features/journey/presentation/widgets/journey_preview_card.dart):

- `HeroScreen.build()` now wraps everything in a `Selector<ProgressionEngineProvider, _HeroChrome>` where `_HeroChrome` is a Dart 3 record `({bool showLoading, String? error})`. The selector skips rebuild unless loading/error chrome actually flips — engine XP / claim / journal ticks no longer rerun `HeroScreen.build()`. `RefreshIndicator.onRefresh` switched to `context.read` so the screen doesn't watch for it.
- Achievement-view computation + sort + section header moved into `_AchievementsSliverSection`, which now self-watches via `context.watch<ProgressionEngineProvider>()` and reads `context.l10n` directly. Section returns a `SliverMainAxisGroup` so the header + grid (or empty state) live in the same sliver block. Drops `unlocked` / `inProgress` / `l10n` constructor params; `_AchievementsSliverSection()` is now a const widget.
- The top `SliverList`'s children are now const (`const ProgressionOverviewSection()`, `const JourneyPreviewCard()`, spacers). `SliverChildListDelegate.fixed` so the delegate itself is also const — engine notify doesn't churn this sliver.
- `_AchievementTile` `boxShadow.blurRadius` 12 → `Tokens.glowSm` (8) per the Phase 0.2 invariant: tiles re-rasterize when they first enter the viewport during scroll, so even a static shadow ≥ 12 px adds visible first-paint cost on the row crossing the cache extent.
- `JourneyPreviewCard` outer-card `boxShadow.blurRadius` 16 → `Tokens.glowSm` (8). Same first-paint-cost reason; the spread offset stays so the visual depth is preserved.

**Not done (rejected):** Memoizing `buildEngineAchievementViews` / `JourneyAdapter.buildMilestoneMap` as Phase 0 getter caches. These functions only run on the provider's notify (not per scroll frame) and the Selector + per-section watch already kills the cascade. Re-trace before adding a cache — premature.

**Verification:** `flutter analyze` clean for both files (same 95 pre-existing `unnecessary_const` infos baseline). 178 progression_engine tests + 11 widget tests green.

> **Cold-start note for fresh sessions:** the home/hero pattern generalises to _any_ screen where a top-level `StatefulWidget.build()` watches a provider AND composes per-section widgets that watch the same provider AND runs a non-trivial derivation (`buildXxxViews`, sort, filter) in the same build. Three rebuilds happen instead of one, and the screen's slivers get a new delegate identity per tick. The fix shape: (a) screen-level `Selector<P, R>` with a Dart 3 record of _only the discriminators that drive control flow_ (loading / error / route gates), (b) per-section widgets that own their `context.watch` and any expensive derivation, (c) const sliver children + `SliverChildListDelegate.fixed` wherever possible. `Selector` rebuilds only when the record's structural equality changes; const children skip parent-driven rebuilds; per-section watches mean a notify only wakes the affected section.

---

## Phase 2 — Quest screen split ✅ shipped 2026-05-22

The screen file shrank from 817 → 462 LoC. `QuestSectionPanel`, the `buildQuestSectionItems(...)` helper, and the `_QuestSectionHint` privacy-helper moved together into [sections/quest_section_panel.dart](../../lib/features/progression_engine/presentation/sections/quest_section_panel.dart); `_NextChapterLockedTeaser` moved to [sections/next_chapter_locked_teaser.dart](../../lib/features/progression_engine/presentation/sections/next_chapter_locked_teaser.dart) and lost its `_` prefix. The four `_QuestsScreenV2State._build*Items` methods stayed on State — they capture instance callbacks (`_pillKeyFor`, `_toggleExpanded`, `_claimQuest`) and returning `List<Widget>` directly is what preserves Phase 1.1's per-card lazy mount. Pulling them into section widgets would either thread the callbacks through new widget constructors (clutter) or re-collapse mounting back to "all cards in one Column" (regression).

Full design record + LoC table + lessons: **[archive/phase_2_quest_screen_split.md](archive/phase_2_quest_screen_split.md)**.

> **Cold-start note for fresh sessions:** when adding a new section helper to `quests_screen.dart`, decide by capture: if it needs `State` instance methods, leave it as a State method returning `List<Widget>`; if it takes everything via parameters, put it in `presentation/sections/`. The split file already shows the pattern — `buildQuestSectionItems` (free function, fully parameterised) is in `sections/`; `_buildChapterItems` (calls `_pillKeyFor`, `_toggleExpanded`, `_claimQuest`) stays on `_QuestsScreenV2State`. Don't promote a State method into a widget just to extract a file — the Phase 1.1 flat-ListView win is what determines this rule, not file size.

---

## Phase 3 — Large screen splits ✅ shipped 2026-05-22 → 2026-05-24

All 10 screens > 1000 LoC have been split, one screen per commit, with parent < 600 LoC and each extracted widget < 400 LoC. Visual design + theme tokens + animations unchanged across the whole phase; `widget-no-logic: 0` lint baseline held. Each split applied the Phase 0–1.3 raster-budget invariants (per-card `RepaintBoundary`, inner `RepaintBoundary` inside `AnimatedSize` bodies, no animated shadows ≥ 12 px on growing silhouettes, `DecorationImage(opacity:)` instead of `Opacity` widget for backgrounds). Permanent design record + per-file before/after LoC + pattern notes in [archive/phase_3_large_screen_splits.md](archive/phase_3_large_screen_splits.md).

---

## Phase 4 — Shell lazy pages

**Why:** [main_shell.dart:182](../../lib/features/app_shell/presentation/main_shell.dart#L182) instantiates a vanilla `PageView` with all 4 tabs (`OverviewScreen`, `QuestsScreenV2`, `HeroScreen`, `SocialScreen`) eagerly. Cold start builds all four. During swipe, both visible pages relayout per frame because `_RenderSliverFractionalPadding` in `PageView`'s viewport.

### Tasks

1. **Read [main_shell.dart](../../lib/features/app_shell/presentation/main_shell.dart)** to confirm current shape — `PageView` vs `PageView.builder`, `AutomaticKeepAliveClientMixin` usage, custom physics, edge handoff.

2. **Choose between two strategies:**
   - **A. `PageView.builder` + `IndexedStack` keepalive** — defer build until first visit, then keep in memory.
   - **B. Lazy `PageView` children** — wrap each tab in `Builder` returning `SizedBox.shrink()` until first focused, then real screen.
   
   Decision criteria: how cheap is the swap between pages once both are built (raster cost), and how much memory each kept-alive page holds. Investigate before deciding.

3. **Preserve `EdgePageHandoff`** ([drag_reveal_pager.dart:206](../../lib/shared/widgets/drag_reveal_pager.dart#L206)) — overview→quest edge swipe must keep working.

4. **Smoke the first-swipe latency.** A lazy strategy means the first visit to each tab pays the build cost. Compare against the steady-state win.

### What NOT to do

- **Don't break `EdgePageHandoff` semantics.** Existing widget tests under `test/widgets/drag_reveal_pager_test.dart` must pass.
- **Don't add tab persistence across app restarts** unless explicitly scoped — that's a separate feature.

### Verification

- `flutter analyze` + all widget tests under `test/widgets/`
- Cold start time measured before/after (use `flutter run --profile --trace-startup`)
- Swipe latency measured before/after
- Manual: navigate all 4 tabs, swipe, verify edge handoff still triggers overview→quest

---

## Phase 5 — Shared template widgets

**Why:** Phase 3's per-screen extractions will surface repeating patterns. Common candidates identified in pre-audit:

1. **`MetricCardWithTrend`** — StatCard + TrendChart + period nav + optional expanded modal. Used by `sleep_screen.dart`, `body_screen.dart`, `nutrition_screen.dart`.
2. **`UnlockConditionsBlock`** — level gate + relic gate + rule block. Used by `cosmetic_details_sheet.dart`, `engine_backfill_section.dart`, companion claim flow.
3. **Section header with right-aligned action** — `screen_header` + `section_head` cover simple cases, but headers with dropdown/action button are inline today.
4. **Empty state / error state / loading shimmer** — currently ad-hoc per screen.

### Tasks

1. **Wait until Phase 3 is partially done** before extracting. Pre-extracting before seeing the repetition leads to over-fitted abstractions.

2. For each candidate above, identify ≥ 3 call sites with near-identical structure. Only then extract.

3. **Place in `lib/shared/widgets/`** following naming convention: snake_case, one primary class per file, no `Ft` prefix.

4. **No business logic.** Widgets accept data + callbacks; they don't fetch providers.

### Verification

- `flutter analyze` clean
- Each new widget has its own widget test in `test/widgets/`
- Lint baseline `widget-no-logic: 0` does not regress

---

## Phase 6 — Docs + ADRs

**Why:** Per [CLAUDE.md](../../CLAUDE.md) "Closing out a finished plan" — refactor docs land permanent records.

### Tasks

1. **Archive each shipped phase** to `docs/ui_refactor/archive/phase_N_<title>.md`. Replace its block in this file with a 1-paragraph summary.

2. **ADR in `docs/site/data/decisions.json`** capturing the card-template approach (context: 4× ~700 LoC cards with structural duplication; decision: slot-based `ExpandableQuestCard`; consequences: easier visual consistency, harder one-off variants; alternatives considered: keep separate, use composition mixins).

3. **Update `docs/site/data/features.json`** if new features are surfaced (probably not — this is presentation-layer refactor).

4. **Update [docs/architecture.md](../architecture.md)** with a "Presentation layer composition" section: card template pattern, section file convention, screen LoC budget rule (< 600 LoC).

5. **Top-level [README.md](../../README.md)** doesn't change — refactor is invisible to users.

---

## Appendix: pattern reference

### Memoization pattern (from `playerQuestCatalog`)

```dart
PlayerQuestCatalog? _cachedPlayerQuestCatalog;
int? _playerQuestCatalogCacheKey;

PlayerQuestCatalog get playerQuestCatalog {
  final l = _ledger;
  if (l == null) return PlayerQuestCatalog.empty;
  final cacheKey = Object.hash(identityHashCode(l), _devDayOffset);
  final cached = _cachedPlayerQuestCatalog;
  if (cached != null && _playerQuestCatalogCacheKey == cacheKey) {
    return cached;
  }
  // ... compute ...
  _cachedPlayerQuestCatalog = result;
  _playerQuestCatalogCacheKey = cacheKey;
  return result;
}
```

The cache implicitly invalidates whenever `_ledger` is replaced (which happens on every `evaluateWith` tick) or `_devDayOffset` changes. No manual invalidation needed.

### RepaintBoundary placement

Wrap the child of an `AnimatedSize` (or any size-animating widget) in `RepaintBoundary` so the parent scroll viewport doesn't repaint when the child animates:

```dart
AnimatedSize(
  duration: ...,
  child: RepaintBoundary(
    child: expandedContent,
  ),
)
```

### File / directory naming

- New widgets in feature: `lib/features/<feature>/presentation/widgets/<name>.dart`
- Sections (a.k.a. screen-level composables that aren't reused outside the screen): `lib/features/<feature>/presentation/sections/<name>.dart`
- Cross-feature shared widgets: `lib/shared/widgets/<name>.dart` (no `Ft` prefix, snake_case filename, one primary class per file)
