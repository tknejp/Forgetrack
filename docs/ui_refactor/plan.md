# UI refactor plan — Trello #85

**Status:** Phase 0 shipped 2026-05-22. Phase 1 next.
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
| 1 | EngineCard template extraction | ⏳ pending | — | 4 quest cards (~2600 LoC) → one template + slots |
| 2 | Quest screen split | ⏳ pending | — | Sections to `presentation/sections/` |
| 3 | Large screen splits | ⏳ pending | — | 10 screens > 1000 LoC, in priority order |
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

## Phase 1 — EngineCard template extraction

**Why:** Four "engine card" widgets sum to **~2600 LoC** with heavy structural duplication, and one (chapter) still has a raster jank during expand that needs structural restructure (see Phase 0 known limits below).

| File | LoC | Role |
|---|---|---|
| [engine_chapter_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_chapter_card.dart) | 777 | Chapter progress card |
| [engine_long_term_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_long_term_card.dart) | 696 | Long-term goal card with companions |
| [engine_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_quest_card.dart) | 691 | Daily / weekly quest card |
| [engine_completed_quest_card.dart](../../lib/features/progression_engine/presentation/widgets/engine_completed_quest_card.dart) | 517 | Completed quest read-only card |

All four share: card shell (`AnimatedContainer` with `color: 0xFF111423`, `borderRadius: Tokens.questCardRadius`, animated border colour, a static drop shadow, padding `Tokens.questCardPadding`) + a header row + progress row + `AnimatedSize` expanded body with a `RepaintBoundary` around its content. They diverge in *what goes into the expanded body* and *what chips sit beside the title / under the progress row*.

### Per-card structural notes (from Phase 0 reading)

Use these to bootstrap step 1's tabulation — verify each by re-reading the file, since Phase 0 only walked the top-of-build:

- **Quest card** — main-five daily streak chip in header, optional companion pill stack under XP pill, `_ExpandedDetails` body (description + XP scaling line + locked hint + optional streak info block for main-five cards). Expand only enabled when `_hasNonXpReward`.
- **Chapter card** — has a `DecorationImage(AssetImage(bgAsset), fit: BoxFit.cover, colorFilter: darken)` in the outer container's decoration. **This is the Phase-0.3 raster bottleneck during expand**: as `AnimatedSize` grows the silhouette, the image re-samples to fill the new box each frame. The new template MUST move this background to a **fixed-height header region** (e.g. `SizedBox(height: headerHeight, child: bg image stack)`) that does NOT grow with the body — that way the image rasterizes once per build and only the body region animates. Body is `_ChapterExpandedDetails` (chain finale rewards + chapter title eyebrow). Has its own chain-dot preview row (`EngineChapterChainPreview`).
- **Long-term card** — body is `_LongTermExpanded` (also contains `_AlsoUnlocks` companion list + `_FinaleRewards` block + `_CompanionRow`s). `_AlsoUnlocks` reads `completedNodeIds` once at build to compute `isUnlocked` per row (Phase 0). Has `_CompanionPills` stack under XP pill.
- **Completed card** — read-only, has a fixed gold glow when `entry.hasClaimable`, no glow otherwise (Phase 0.2 froze these to fixed alpha/blur). Body `_ExpandedBody` is much simpler — companion list + chain preview if applicable.

### Invariants the new template MUST preserve (baked in by Phase 0–0.3)

These are the rules that make the current quest-screen perf acceptable. The template must keep them; do not undo them:

1. **Expand state via `ExpandedQuestScope`.** Each card resolves `isExpanded` via `ExpandedQuestScope.isExpanded(context, nodeId)` inside its `build()` — never via a constructor parameter. This is the InheritedModel that makes the toggle update only the two affected cards. See [expanded_quest_scope.dart](../../lib/features/progression_engine/presentation/widgets/expanded_quest_scope.dart) for the contract. The template MUST resolve expand state the same way.
2. **Top-level `RepaintBoundary` per card.** The first widget returned by `build()` (after the `RepaintBoundary` it will live inside) is a `RepaintBoundary` wrapping the card's `GestureDetector` + outer container. This isolates scroll + sibling-expand re-rasterization. Don't drop it in the template.
3. **`AnimatedSize` body with a `RepaintBoundary` *inside* it** around the expanded `Padding(...)` (Phase 0). When `isExpanded` is false the child is a `SizedBox(width: double.infinity)` placeholder so `AnimatedSize` collapses to zero height. Don't change this shape — collapsed state matters for `AnimatedSize`'s height interpolation.
4. **No conditional shadows. No animated shadow params.** The conditional `if (isExpanded) BoxShadow(blurRadius: glowXl=22)` and animated blur/alpha were Phase 0.2's removal — they re-rasterize a 22 px Gaussian blur per frame on a growing silhouette and blow the 120 Hz raster budget. The template can have at most one **static** drop shadow per state (per "is claimable" / static). Use small `blurRadius` (`Tokens.glowSm = 8` or the current per-card 10–14 range — never `glowXl`).
5. **No animated `DecorationImage` re-sampling.** If the chapter background image stays as part of the outer growing container's decoration, the raster jank from Phase 0.3 stays unfixed. See chapter notes above — restructure it.
6. **Border colour interpolation is fine.** The current `AnimatedContainer(duration: 180ms)` animating just the border colour is cheap and should be kept as the "expand affordance" alongside the body slide. Pair this with a non-animated drop shadow (already in place) and we're good.

### Tasks

1. **Read all four files** end-to-end. Tabulate per-card differences in:
   - Header composition (icon kind, title rows, optional eyebrow, chip strip)
   - Progress-row composition (`_ProgressRow` vs chain-dot row vs none)
   - What sits under the XP pill (streak chip, companion pill stack, nothing)
   - Expanded-body sections (description, chain preview, companion list, finale rewards, streak info)
   - Claim flow (active claim button vs read-only XP pill)
   - Any tap targets beyond the whole-card toggle (companion-pill taps that open sheets, etc.)

2. **Design `ExpandableQuestCard`** under `lib/features/progression_engine/presentation/widgets/expandable_quest_card.dart` (feature-scoped — depends on `EngineQuestProgress` and friends, do NOT put it in `lib/shared/widgets/`). Slot-based API. Sketch:
   ```dart
   ExpandableQuestCard(
     accent: accent,
     nodeId: quest.nodeId,        // for ExpandedQuestScope subscription
     onToggle: onToggle,
     header: ...,                 // icon + title + eyebrow + chips
     progressRow: ...,            // _ProgressRow OR chain dots OR null
     trailingPill: ...,           // XP pill + optional companion buff chip
     belowPill: ...,              // companion pill stack (long-term/quest)
     fixedHeader: ...,            // OPTIONAL fixed-height region BEFORE body — chapter bg image lives here
     expandedBody: ...,           // _FooExpandedDetails widget
   )
   ```
   Resolve `isExpanded` inside the template via `ExpandedQuestScope.isExpanded(context, nodeId)`. The `fixedHeader` slot is what fixes the chapter card's raster jank — it sits in a `SizedBox(height: const)` that does NOT grow with the body.

3. **Rewrite each `Engine*Card` to compose `ExpandableQuestCard`** with its slots. Target: ~150-250 LoC per card after rewrite. Card constructors stay unchanged for callers (sections still call `EngineQuestCard(quest: …, onToggle: …, …)`).

4. **Consolidate `AnimatedSize` + inner `RepaintBoundary` + top-level `RepaintBoundary` + drop shadow + `AnimatedContainer` border animation** inside the template — Phase 0 added them per-card; Phase 1 collects them in one place.

5. **Re-trace after** to confirm chapter expand raster comes down to <8.3 ms / frame.

### What NOT to do

- **Don't change the public API of `Engine*Card` constructors.** Sections in [quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart) (`_ChapterSection`, `QuestSectionPanel`, `_LongTermSection`, `_CompletedSection`) must continue to work unchanged. The cards' `build()` internals change; their `super.key`, named parameters, and behaviour stay.
- **Don't reintroduce conditional shadows or `Tokens.glowXl` blur in the template.** See invariants above.
- **Don't move `ExpandableQuestCard` to `lib/shared/widgets/`.** Feature-scoped. Phase 5 handles cross-feature widgets.
- **Don't change claim flow semantics or which widget owns `onClaim` wiring.** Card just passes the callback through to the XP pill / claim button.
- **Don't read providers in the template.** All provider data is already resolved by the caller (sections) and passed in as constructor parameters / slot widgets. Lint baseline `widget-no-logic: 0` must not regress.
- **Don't break the `ExpandedQuestScope` subscription contract.** Each card's `nodeId` is what the scope keys off; keep the existing nodeIds (`quest.nodeId` for active cards, `entry.representative.nodeId` for completed cards).

### Verification

- `flutter analyze` clean (the 95 pre-existing `unnecessary_const` infos in `domain/catalog/content/` are unrelated and should stay)
- `flutter test test/features/progression_engine/` green (178 tests as of Phase 0.3). No test constructs `Engine*Card` directly — confirmed by Phase 0.1 grep — so card API changes are safe.
- Visual diff: open each card type before/after, expand, claim — no behavioural changes. The chapter card's bg image now lives in a fixed-height header that doesn't animate, which is a visible structural change.
- Re-trace in DevTools profile mode: chapter expand raster frames < 8.3 ms (was ~23 ms post-Phase-0.2). Other cards stay in budget. UI thread unchanged (still benefits from Phase 0.1 `ExpandedQuestScope`).
- LoC budget per card: < 300 each. `ExpandableQuestCard` < 400.

---

## Phase 2 — Quest screen split

**Why:** [quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart) is 802 LoC with five private section widgets crammed in (`_ChapterSection`, `QuestSectionPanel`, `_LongTermSection`, `_CompletedSection`, `_LockedSection`).

### Tasks

1. Create `lib/features/progression_engine/presentation/sections/` directory.

2. Extract each section to its own file:
   - `sections/chapter_section.dart` ← `_ChapterSection`
   - `sections/quest_section_panel.dart` ← `QuestSectionPanel` (already public-named)
   - `sections/long_term_section.dart` ← `_LongTermSection`
   - `sections/completed_section.dart` ← `_CompletedSection`
   - `sections/locked_section.dart` ← `_LockedSection`

3. Make extracted classes public (drop the `_` prefix). They become part of the progression_engine feature's section API.

4. Update [quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart) to import + use them. Target: < 350 LoC.

### What NOT to do

- **Don't change section behavior.** Pure file move + privacy change.
- **Don't add new lifecycle filtering** — that lives in the provider (Phase 19 of the domain refactor closed this).

### Verification

- `flutter analyze` clean
- `flutter test test/features/progression_engine/` green
- Manual: quest screen renders identically

---

## Phase 3 — Large screen splits

**Why:** 10 screens > 1000 LoC (Trello canonical list).

| Priority | File | LoC | Extract |
|---|---|---|---|
| P1 | [nutrition_screen.dart](../../lib/features/nutrition/presentation/nutrition_screen.dart) | 1925 | `_MacroTrendCard`, `_BalanceCard`, `_MealsCard`, `_TodayHeaderCard` to `widgets/` |
| P1 | [cosmetic_details_sheet.dart](../../lib/features/cosmetics/presentation/cosmetic_details_sheet.dart) | 1514 | `_UnlockConditionsSection`, `_RuleBlock`, claim bodies (`_ClaimableCompanionBody`, `_LockedCompanionBody`) |
| P1 | [overview_screen.dart](../../lib/features/home/presentation/overview_screen.dart) | 1403 | `_DayContent` out to its own file (was 470-1058 in scan) |
| P2 | [sleep_screen.dart](../../lib/features/health_connect/presentation/sleep_screen.dart) | 1571 | Already well-sectioned — extract `_SleepMetricTrendCard`, `_ExpandedSleepBody` |
| P2 | [journey_interactive_map.dart](../../lib/features/journey/presentation/widgets/journey_interactive_map.dart) | 1670 | Already well-sectioned — extract custom painters + collision helpers |
| P2 | [devtools_progression_engine_section.dart](../../lib/features/devtools/presentation/sections/devtools_progression_engine_section.dart) | 1208 | Each collapsible card into its own file |
| P2 | [engine_backfill_section.dart](../../lib/features/progression_engine/presentation/widgets/engine_backfill_section.dart) | 1146 | Progress tracker + award grid + action buttons |
| P3 | [cosmetics_screen.dart](../../lib/features/cosmetics/presentation/cosmetics_screen.dart) | 1077 | Tab content widgets per gear category |
| P3 | [profile_detail_hero_card.dart](../../lib/features/social/presentation/widgets/profile_detail_hero_card.dart) | 1067 | Hero card sections |
| P3 | [body_screen.dart](../../lib/features/health_connect/presentation/body_screen.dart) | 1063 | Body metric tiles + expanded modals |

**Per-screen rules:**

- Target: parent screen < 600 LoC after split.
- Extracted widgets land in `widgets/` next to the screen, not in `lib/shared/widgets/` (those are cross-feature).
- **Take the perf hit during the split:** memoize any expensive getters the screen calls, add `RepaintBoundary` to heavy paint nodes, ensure no `Opacity`/`BackdropFilter` over large areas without `if (sigma > 0)` gating.
- Each screen is its own commit. Title prefix: `quest-ui:`, `nutrition:`, `cosmetics:`, etc. (project convention).

### What NOT to do

- **Don't refactor multiple screens in one commit.** One screen per PR / commit.
- **Don't touch `lib/shared/widgets/`.** Phase 5 handles that.
- **Don't change visual design.** Same theme tokens, same layout, same animations.

### Verification per screen

- `flutter analyze` clean
- `flutter test test/features/<area>/` green (where coverage exists)
- Manual: smoke the screen — open, scroll, interact with primary action
- Confirm LoC budget: split screen < 600, each extracted widget < 400

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
