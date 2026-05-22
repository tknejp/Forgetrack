# Phase 1 — EngineCard template extraction (shipped 2026-05-22)

Archived from `docs/ui_refactor/plan.md` after shipping. Permanent design record — explains why the four engine cards now compose a single shell instead of repeating it.

## Why

Four "engine card" widgets sum to **~2600 LoC** with heavy structural duplication of the same animated container + border interpolation + drop shadow + AnimatedSize body + RepaintBoundary scaffolding. One of them (chapter) also still had a raster jank during expand that needed a structural fix.

| File | LoC (pre-Phase 1) | Role |
|---|---|---|
| `engine_chapter_card.dart` | 777 | Chapter progress card |
| `engine_long_term_card.dart` | 696 | Long-term goal card with companions |
| `engine_quest_card.dart` | 691 | Daily / weekly quest card |
| `engine_completed_quest_card.dart` | 517 | Completed quest read-only card |

All four shared: card shell (`AnimatedContainer` with `color: 0xFF111423`, `borderRadius: Tokens.questCardRadius`, animated border colour, a static drop shadow, padding `Tokens.questCardPadding`) + a header row + progress row + `AnimatedSize` expanded body with a `RepaintBoundary` around its content. They diverged in *what goes into the expanded body* and *what chips sit beside the title / under the progress row*.

## What shipped

### `ExpandableQuestCard` template

New widget at [lib/features/progression_engine/presentation/widgets/expandable_quest_card.dart](../../../lib/features/progression_engine/presentation/widgets/expandable_quest_card.dart) (205 LoC). Slot-based API:

```dart
ExpandableQuestCard(
  nodeId: quest.nodeId,        // subscribes to ExpandedQuestScope
  onToggle: onToggle,
  canExpand: ...,
  header: Row(...),            // icon + title + trailing pills
  chainPreview: ...,           // optional — chapter / long-term / combo
  progressRow: ...,            // optional — bar + label
  expandedBody: ...,           // _FooExpandedDetails widget
  fixedHeader: ...,            // optional — chapter bg image band
  collapsedBorderColor: ...,   // defaults to white 6%
  expandedBorderColor: ...,    // defaults to Tokens.accent 42%
  shadows: [...],              // defaults to single black-26% drop
)
```

The template owns the cross-cutting concerns:

- Top-level `RepaintBoundary` (Phase 0.3 invariant)
- `GestureDetector` + `AnimatedContainer` with 180 ms border tween
- `ClipRRect` so the optional `fixedHeader` band is clipped to the card's rounded corners
- `AnimatedSize` body with inner `RepaintBoundary` around the expanded panel (Phase 0 invariant)
- `ExpandedQuestScope` subscription via `nodeId` (Phase 0.1 invariant)
- A Stack overlay when `fixedHeader != null` so the bg image layer doesn't grow with the body

Slot widgets own their leading whitespace — the template only stacks them. This preserves the per-card vertical rhythm (e.g. the quest card's 4-px-above / 12-px-below combo chain row vs. chapter / long-term cards' uniform 8 px). The caller wraps each slot in the `Padding` it needs.

### Chapter card raster fix (`fixedHeader` slot)

The chapter card's previous `DecorationImage(fit: BoxFit.cover)` on the outer `AnimatedContainer` re-sampled the image every frame of the expand animation, because the container's silhouette grew with `AnimatedSize`. That was the Phase 0.3 raster bottleneck the per-card `RepaintBoundary` couldn't fix on its own.

The new chapter card supplies a `Container(height: 112, decoration: BoxDecoration(image: ...))` as `fixedHeader`. The template puts it in a `Positioned(top: 0, left: 0, right: 0)` layer behind the padded content. The Stack sizes to the padded content (positioned children don't contribute), so the bg band is structurally locked at 112 px regardless of how tall the card grows.

**Visible structural change:** the bg image now anchors the header row (~icon + title + description) and stops there. The chain dots and progress row sit on plain dark `0xFF111423` instead of on top of the darkened image. Acceptable trade — the image was already darkened to alpha 0.42 / 0.62 so the visual contribution beyond the title block was subtle.

### Per-card rewrites

Each `Engine*Card.build()` now composes the template with its slots. Constructor signatures are unchanged — every section in [quests_screen.dart](../../../lib/features/progression_engine/presentation/quests_screen.dart) still calls `EngineQuestCard(quest: …, onToggle: …, …)` etc. with the same named parameters.

Per-card overrides:

| Card | `collapsedBorderColor` | `expandedBorderColor` | `shadows` | `fixedHeader` |
|---|---|---|---|---|
| Quest | default (white 6%) | default (accent 42%) | default (black 26%, blur 10) | — |
| Chapter | white 8% | default | black 32%, blur 8 (`Tokens.glowSm`), offset (0, 6) | bg image band (112 px) |
| Long-term | default | default | default | — |
| Completed | gold 32% when claimable / white 6% otherwise | gold 42% when claimable / accent 32% otherwise | drop + optional gold glow (only when `hasClaimable`) | — |

The completed card's gold glow stays a **static** second `BoxShadow` (alpha 0.14, blur 16) on the `hasClaimable` branch — never animated, per Phase 0.2's hard rule.

## What did NOT change

- Public API of `Engine*Card` constructors — section widgets in `quests_screen.dart` are untouched.
- Claim flow semantics — cards still pass `onClaim` through to the `XpClaimPill`.
- Visual design — the only intended visible change is the chapter bg image moving from full-card backdrop to a header band.
- `ExpandedQuestScope` subscription contract — each card subscribes via the same `nodeId` it always used.
- Lint baseline `widget-no-logic: 0` — template reads no providers; all data flows in through constructor args / slot widgets.

## Performance invariants preserved (Phase 0–0.3)

The template was designed to **bake in** the invariants Phase 0 series established so the cards can't accidentally drop them:

1. `ExpandedQuestScope.isExpanded(context, nodeId)` resolved inside the template (and each card, for its own per-slot needs like asset size).
2. Top-level `RepaintBoundary` around the gesture detector — every card gets one for free.
3. `AnimatedSize` body with inner `RepaintBoundary` around the expanded panel — built into the template's `AnimatedSize` branch.
4. **No conditional shadows. No animated shadow params.** The template's `shadows` parameter is a static `List<BoxShadow>`; there's no way to vary it across collapsed / expanded states.
5. **No animated `DecorationImage` re-sampling.** The `fixedHeader` slot is the structural answer — the bg image sits in a constant-height layer that never grows with `AnimatedSize`.
6. Border-colour interpolation in `AnimatedContainer(duration: 180ms)` is the only animation on the outer container, paired with the static drop shadow.

## LoC outcome

| File | Before | After | Δ |
|---|---|---|---|
| `expandable_quest_card.dart` (new) | — | 205 | +205 |
| `engine_quest_card.dart` | 691 | 642 | -49 |
| `engine_chapter_card.dart` | 777 | 776 | -1 |
| `engine_long_term_card.dart` | 696 | 661 | -35 |
| `engine_completed_quest_card.dart` | 517 | 499 | -18 |
| **Sum** | **2681** | **2783** | **+102** |

The raw LoC went up by ~100 lines because each card now imports the template and threads its slots through named parameters. The win is structural: each `build()` method is ~50% shorter (the duplicated decoration / RepaintBoundary / AnimatedSize / AnimatedContainer scaffolding lives in one place), and any future change to the card shell (Phase 0.x-class perf fix, a new affordance) lands in one file instead of four.

The plan's "< 300 LoC per card" target wasn't achievable in Phase 1 alone — most of each card's remaining LoC is private helper widgets (`_ProgressRow`, `_ExpandedDetails`, `_ChapterExpandedDetails`, `_LongTermExpanded`, `_AlsoUnlocks`, `_FinaleRewards`, `_CompanionRow`, `_NextStepHint`, `_ChainNode`, `_Connector`, etc.) that were never part of the duplication. Phase 2 / 3 (section + screen extraction) can carve those out further.

## Verification

- `flutter analyze` — 95 issues, all pre-existing `unnecessary_const` infos in `lib/features/progression_engine/domain/catalog/content/`. No new issues from the four touched cards or the new template.
- `flutter test test/features/progression_engine/` — all 178 tests green (same count as Phase 0.3).
- `flutter test test/widgets/drag_reveal_pager_test.dart` — all 4 widget tests green.
- No test constructed `Engine*Card` directly (confirmed by Phase 0.1 grep), so API-safe.

## What this unblocks

- **Phase 2 (quest screen split):** sections now read `EngineQuestCard(...)` etc. with stable APIs; moving each section to its own file in `presentation/sections/` is a pure file move.
- **Future card variants:** any new "engine card" can compose `ExpandableQuestCard` and inherit the perf invariants for free.
- **Cross-feature template (Phase 5):** if a similar shell shows up outside the progression_engine feature (e.g. a profile-detail expandable card), the same slot pattern can be lifted into `lib/shared/widgets/` after we see ≥ 3 call sites.

## Re-trace expectation

DevTools profile run on the quest screen should show chapter expand raster frames consistently under the 120 Hz 8.3 ms budget (was ~23 ms post-Phase-0.2, because the bg image was re-sampling per frame on a growing silhouette). UI-thread cost stays the same — Phase 1 didn't touch the `ExpandedQuestScope` perf win or the per-card `RepaintBoundary` work.
