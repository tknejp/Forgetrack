# Phase 1.2 — Home screen perf audit ✅ shipped 2026-05-22

## Why

After Phase 1.1 closed the quest screen's recurring scroll jank, the user reported that the home screen had **more visible janks than the quest screen**. Two-part audit answered both "does the home have a quest-screen-like lazy-mount issue?" and "do the home cards themselves carry the Phase 0–1 invariants the quest cards do?".

## Findings

**Outer scrollable: not the same shape as the quest screen.** [overview_screen.dart](../../../lib/features/home/presentation/overview_screen.dart) — `CustomScrollView` with two slivers (period nav + `DragRevealPager` builder returning the whole day's content). The entire day content sits in one `SliverToBoxAdapter`, so `CustomScrollView` lazy mounting can't subdivide it. Different jank shape than the quest screen.

**[drag_reveal_pager.dart](../../../lib/shared/widgets/drag_reveal_pager.dart) is already optimized** (commit ab4613d) — side pages are lazy, current page wrapped in `RepaintBoundary`, `AnimatedBuilder` only re-translates per tick. Not the bottleneck.

**Three concrete jank sources identified:**

1. **`OverviewScreen.build()` watches 6 providers** → every notify rebuilds the whole `_DayContent`. `FitnessProvider` step ticks, `KalorickeTabulkyProvider` food-log ticks, and similar steady-state events all cascade through ~500 lines of derived-value computation + all 5 `StatCard` slot widgets. Compared to the quest screen (one provider with signature-guarded notifies), the home was rebuilding far more frequently.

2. **`ReorderableListView.builder(shrinkWrap: true, physics: NeverScrollable)`** — `shrinkWrap` forces the list to lay out every item to compute its own intrinsic height, defeating the builder's laziness. Magnitude: small (5 cards), accepted as-is for this round.

3. **`StatCard` was missing Phase 0–1 invariants.** No top-level `RepaintBoundary`, no inner `RepaintBoundary` around the `AnimatedSize` expanded body. So when a `StatCard` user tapped to expand, the sliver above the card had to re-rasterize the card layer (including its decorative `Image.asset` with `BlendMode.darken`) every tick of the 260 ms `AnimatedSize`. Sibling cards in the same `ReorderableListView` were affected too.

## Changes shipped

### Fix 1 — StatCard now carries Phase 0–1 invariants

[lib/shared/widgets/stat_card.dart](../../../lib/shared/widgets/stat_card.dart):

- **Top-level `RepaintBoundary`** wrapping the `GestureDetector`. Scroll = compositor translation of the cached card layer; a sibling card's expand animation no longer invalidates this card's raster.
- **Inner `RepaintBoundary`** around the `AnimatedSize` expanded body. The expanded subtree's silhouette interpolates inside its own layer without re-rasterizing the outer card every tick.

Same shape `ExpandableQuestCard` bakes in for engine cards. `StatCard` lives in `lib/shared/widgets/`, so any other screen composing it (sleep, body, nutrition) inherits the fix.

### Fix 2 — Per-card provider subscriptions on the home screen

[lib/features/home/presentation/overview_screen.dart](../../../lib/features/home/presentation/overview_screen.dart) restructured top-to-bottom (helper widgets at the bottom unchanged):

- **`OverviewScreen.build()` watches no providers.** Previously: `context.watch<>` on FitnessProvider, KalorickeTabulkyProvider, GoalsProvider, ProgressionEngineProvider, ConnectivityProvider, HomeCardOrderProvider. Now: pure chrome (EdgePageHandoff + RefreshIndicator + CustomScrollView). State (`_period`, `_showCachedHcAnyway`, `_showCachedKtAnyway`) stays. Provider reads via `context.read` where needed (refresh, HC permission action).
- **`_PeriodNavigatorBar`** — `Selector<FitnessProvider, DateTime?>` scoped to `lastSyncedAt`. Step ticks no longer rebuild the nav.
- **`_HomeOfflineBanner`** — `Selector<ConnectivityProvider, bool>` scoped to `isOnline`. Connectivity ticks that don't flip the bool are silently absorbed.
- **`_HomeCardList`** — owns the reorderable list and layout decisions. Uses `Selector2<FitnessProvider, KalorickeTabulkyProvider, _CardVisibility>` (a Dart 3 record with structural equality) to subscribe only to the small set of fields that decide which slots collapse into prompts. A steps update flips no field in `_CardVisibility` → `Selector2` skips its builder → reorderable list stays cached.
- **5 new per-card slot widgets** (`_StepsSlot`, `_CaloriesSlot`, `_WeightSlot`, `_ActivitySlot`, `_SleepSlot`) — each `context.watch`es only the providers it needs:
  - Steps / Weight / Activity / Sleep — `FitnessProvider`, `GoalsProvider`, `ProgressionEngineProvider`.
  - Calories — `KalorickeTabulkyProvider`, `GoalsProvider`, `ProgressionEngineProvider`. **Does not watch fitness.**
- **Free helper functions** (`_xpPillForQuest`, `_streakInfoBlockForQuest`, `_findDailyQuest`, `_weightForPeriod`, `_previousWeightForPeriod`, `_hasCachedHcData`, `_fmtSleep`) extracted from `_OverviewScreenState` — slot widgets call them without needing State-method access.
- **Bottom helpers unchanged** (`_NutritionDetailTile`, `_DataSourcePromptCard`, `_OfflineSourceBanner`, `_ActivityClaimsList`, `_ActivityClaimRow`, `_activityGoalForPeriod`).

## Effect

| Provider notify | Before | After |
|---|---|---|
| `KalorickeTabulkyProvider` (food log) | Whole screen rebuild + 5 cards | Only `_CaloriesSlot` rebuilds. Steps/weight/activity/sleep stay cached. |
| `FitnessProvider` (steps update) | Whole screen rebuild + 5 cards | `_StepsSlot`, `_WeightSlot`, `_ActivitySlot`, `_SleepSlot` rebuild. `_CaloriesSlot` and chrome stay cached. |
| `FitnessProvider` (access state grants) | Whole screen rebuild + 5 cards | `_HomeCardList`'s `Selector2` rebuilds (layout decision changes); slot widgets reconstruct as needed. Correct behavior. |
| `ConnectivityProvider` (rare) | Whole screen rebuild + 5 cards | Only `_HomeOfflineBanner` rebuilds. |
| `ProgressionEngineProvider` (claim) | Whole screen rebuild + 5 cards | All 5 slot widgets rebuild (they all surface XP pills). Same as before — claim affects every card. |
| Card expand tap | Whole sliver re-rasterizes per tick | Only the tapped card's layer re-rasterizes; inner `RepaintBoundary` keeps the expanded body in its own layer. |

The KT data-entry path is the biggest practical win — typing meals into KT triggers frequent `KalorickeTabulkyProvider` notifies, and post-refactor those only touch the calorie card.

## Verification

- `flutter analyze` clean for both touched files. Project baseline of 95 pre-existing `unnecessary_const` infos in domain catalog content unchanged.
- All 178 `flutter test test/features/progression_engine/` tests green.
- All 11 `flutter test test/widgets/` tests green, including `drag_reveal_pager_test.dart` which exercises the swipe behavior `OverviewScreen` depends on.
- Manual smoke deferred to the user's device session.

## Cold-start note for fresh sessions

Two patterns now apply broadly across the codebase:

**1. `StatCard` invariants (lib/shared/widgets/stat_card.dart).** Top-level `RepaintBoundary` + inner `RepaintBoundary` on the `AnimatedSize` body. Treat these as Phase 0–1 invariants — any widget composing the same shape (animated container + expandable body) should self-wrap. If you ever add another reusable expandable card in `lib/shared/widgets/`, mirror this pattern.

**2. Per-card provider subscriptions on multi-card screens.** When a screen renders N cards in a list and each card reads only a subset of providers, do NOT `context.watch` at the screen level — that fans every notify out to all N cards. Instead:
- Push each card to its own `StatelessWidget` with a `context.watch` for the specific providers it consumes.
- Keep screen-level layout decisions in a separate widget that uses `Selector` (or `Selector2`/`Selector3`) on a small derived value (a Dart 3 record gives structural equality for free).
- Only widgets whose subscribed values actually changed rebuild. Cards that don't read the noisy provider stay cached.

This is the pattern that lets a `KalorickeTabulkyProvider` food-log tick rebuild only the calorie card on the home screen, and similar isolations elsewhere.

If a future screen has a card that reads many providers (so its build is genuinely expensive) and you want to skip rebuilds when *only one specific field* on a provider changed, escalate to `Selector` *inside* the card too — narrow the watch to a derived value. Don't reach for `AutomaticKeepAliveClientMixin` to "freeze" the card — that masks the symptom (the card holds an Element forever) without fixing the cascade.
