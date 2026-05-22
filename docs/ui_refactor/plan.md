# UI refactor plan — Trello #85

**Status:** Phase 0–1 shipped 2026-05-22. Phase 1.1 next (recurring scroll jank on quest screen).
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
| 1.1 | Quest screen scroll jank investigation | ⏳ pending | — | Recurring 22 ms jank during scroll; 4 BUILDs per jank frame; need to identify what invalidates sections per scroll tick |
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

## Phase 1 — EngineCard template extraction ✅ shipped 2026-05-22

The four engine cards (~2600 LoC) used to repeat the same animated container + border interpolation + drop shadow + AnimatedSize body + RepaintBoundary scaffolding inline. Phase 1 collected all of that into a slot-based [ExpandableQuestCard](../../lib/features/progression_engine/presentation/widgets/expandable_quest_card.dart) template (205 LoC) and rewrote each `Engine*Card.build()` to compose it. Constructor signatures are unchanged — section widgets in [quests_screen.dart](../../lib/features/progression_engine/presentation/quests_screen.dart) are untouched.

The chapter card's bg image moved from a full-card `DecorationImage` (which re-sampled per frame on a growing silhouette — the Phase 0.3 raster bottleneck) to the template's optional `fixedHeader` slot — a constant-height `Positioned` band that doesn't grow with `AnimatedSize`. Visible structural change: the chain dots / progress row now sit on plain dark `0xFF111423` instead of on top of the darkened image. All Phase 0–0.3 perf invariants (top-level `RepaintBoundary`, `ExpandedQuestScope` subscription, no animated shadows, etc.) are baked into the template.

Full design record + per-card override table + LoC outcome: **[archive/phase_1_engine_card_template.md](archive/phase_1_engine_card_template.md)**.

> **Cold-start note for fresh sessions:** when adding a new "engine card" variant, compose `ExpandableQuestCard` — don't reinvent the shell. The template owns the perf invariants and you'll inherit them for free. If you ever need to change the shell (a new affordance, a perf tweak), change it in one place. **Bg images go on the template's `backgroundDecoration` parameter, NEVER on `AnimatedContainer.decoration` directly** — the hero-pattern follow-up to Phase 1 proved that image-bearing decoration on the animated container forces a per-tick `BoxDecoration.lerp` over `DecorationImage` that was the original chapter card's raster jank. Static `DecoratedBox` + `opacity` (not `BlendMode.darken`) is the path that works at 120 Hz.

---

## Phase 1.1 — Quest screen scroll jank investigation

**Why:** After Phase 1 + the hero-pattern follow-up shipped, a fresh DevTools profile-mode trace on the quest screen still shows a **recurring ~22 ms jank frame during scroll** — not a one-time cost when a section first enters the viewport (the original hypothesis), but a **per-scroll-tick** stutter that's visible to the user ("scroll není smooth a zadrhne se, nebo občas úplně zastaví").

### Trace evidence (2026-05-22)

| Slice | Wall (ms) | Occurrences |
|---|---|---|
| `VsyncProcessCallback` | 22.65 | 1 |
| `Animator::BeginFrame` | 22.64 | 1 |
| `LAYOUT (root)` | 21.85 | 1 |
| `LAYOUT` | 21.84 | 1 |
| `BUILD` | 21.14 | **4** |
| `COMPOSITING` | 0.20 | 1 |
| `PAINT` | 0.01 | 1 |

UI thread bound. Raster thread is clean (PAINT + COMPOSITING < 0.5 ms; the Phase 0.x raster invariants are holding). The cost is in **4 BUILD events per jank frame, ~5 ms each**, all inside a single LAYOUT pass.

### Hypothesis space (in priority order)

1. **A provider notifies during scroll, triggering full `QuestsScreenV2.build()`.** The screen calls `context.watch<...>()` on several providers. If any of them ticks during scroll (e.g. health data polling, time-based UI updates, foreground sync), the whole build runs → all sections rebuild → all visible cards rebuild. The "4 BUILDs per frame" pattern matches "one section with 4 cards rebuilds because its parent invalidated."
   - Files to grep: `lib/features/progression_engine/presentation/quests_screen.dart` — find every `context.watch`, `Consumer`, `Selector`.
   - Providers to investigate (rebuild frequency): `ProgressionEngineProvider`, `HealthConnectProvider`, `FoodTriggerProvider`, `CosmeticsProvider`, `AuthProvider`, `SocialProvider`, plus anything wired through `Provider.of`.
   - **Fix shape:** replace `watch` with `Selector` keyed on the specific fields the screen uses, or push the provider read down into the deepest leaf that actually consumes it.

2. **A periodic timer / animation controller above the ListView ticks.** Could be a `Ticker` somewhere in the section tree (e.g. an animation rebuilding without `AnimatedBuilder`'s `child:` optimization). Check for `setState` calls in section / screen lifecycles.

3. **Sections rebuild because their constructor args change identity per parent build.** E.g. if `_ChapterSection` is constructed with `chainResolver: (id) => ...` (a fresh closure per parent build), the section's element won't equal its previous element and Flutter rebuilds it even when nothing functional changed. Check for inline closures / list literals in section constructor sites in `quests_screen.dart`.

4. **Eager section building is the residual cost.** Less likely given the "every scroll tick" pattern, but check anyway: each section uses `Column(children: [for (var i = 0; ...) Card])` rather than `SliverList.builder`. When a section first enters the viewport, all cards build in one frame. If the user is scrolling through a section that's in-viewport every frame (visible card count varies), the section might be re-built per frame because its `children` list identity changes. Solution: convert sections to `SliverList.builder` so each card builds lazily by index.

### Tasks for the next session

1. **DevTools rebuild stats.** Run quest screen in profile mode, open DevTools → Performance → "Rebuild Stats" tab. Confirm which widgets rebuild per frame during scroll. The "4 BUILDs" should resolve to specific widget classes — that names the culprit.

2. **Grep `quests_screen.dart` for every `context.watch` / `Provider.of` / `Consumer` / `Selector`.** Tabulate what each subscription pulls and how often the source provider notifies. The fix likely lands here.

3. **Audit section constructors** for closure / list args reconstructed per parent build (chainResolver, pillKeyFor, onClaim, etc.). Hoist anything that should be stable into `State` fields or top-level consts.

4. **If steps 1–3 don't fully close the gap**, convert sections from `Column(children: [cards])` to `SliverList.builder` inside `CustomScrollView(slivers: [...])` so card BUILD spreads across frames as they enter / leave the viewport.

5. **Re-trace** after each change. Target: zero recurring jank during steady-state scroll, no frame > 8.3 ms on UI thread (120 Hz budget).

### What NOT to do

- **Don't touch the `ExpandableQuestCard` template or Phase 0/1 invariants.** Cards are not the bottleneck here — they're caching correctly via per-card `RepaintBoundary`. The cost is BUILD (UI thread), not PAINT (raster).
- **Don't add `AutomaticKeepAliveClientMixin` to cards as a first attempt.** It keeps element state alive across viewport scrolls but doesn't fix the underlying "why does this rebuild every frame" question — masks the symptom.
- **Don't preemptively migrate to `CustomScrollView` + `SliverList.builder` until #1–#3 are ruled out.** The structural change is a bigger refactor than a targeted `Selector` swap; do the cheap diagnostic first.
- **Don't break Phase 0.1's `ExpandedQuestScope`.** The aspect-based notify is what makes expand toggle cheap; any new subscription pattern must preserve that.
- **Don't change card visuals** — this is a perf hotfix, not a UX iteration.

### Verification

- DevTools profile-mode trace shows no frames > 8.3 ms on UI thread during steady-state scroll across the entire quest screen.
- Manual: scroll up / down the full quest screen on a real device (where the jank is observable); subjective smooth feel, no visible stutters.
- `flutter analyze` clean, `flutter test test/features/progression_engine/` green (178 tests baseline from Phase 1).
- Lint baseline `widget-no-logic: 0` not regressed.

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
