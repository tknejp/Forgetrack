# Phase 1.3 — Home card expand animation cost ✅ shipped 2026-05-22

## Symptoms

After Phase 1.2 closed the home-screen rebuild cascade (per-card `context.watch`, `StatCard` Phase 0–1 invariants), a 120 Hz profile-mode trace still showed:

- **Expand animation:** frames in the 10–13 ms range for the full 260 ms `AnimatedSize` duration (8.3 ms budget at 120 Hz).
- **Scroll over an OPEN card:** raster janks up to ~20 ms.
- **Scroll over a CLOSED card:** noticeably fewer janks (Phase 1.2 `RepaintBoundary` covers that case).

The pattern — janks on *both* the expand animation *and* steady-state scroll of an open card — was the diagnostic. Per-tick relayout (the `AnimatedSize`→`SizeTransition` candidate) would explain the expand jank but **not** the steady-state scroll jank. That ruled out a UI-thread bottleneck and pointed at per-paint raster cost inside the card layer.

## Root causes

Two per-paint raster ops inside the card's repaint boundary, paid every frame the card needs to be re-rasterized (= every tick of `AnimatedSize`, and every scroll-induced repaint of a card whose layer cache doesn't catch — which happens when the card is large enough that its own boundary repaints during overscroll bursts):

1. **`Opacity` widget around the background image.** `_buildBackgroundImage()` wrapped the `Image.asset` in an `Opacity` widget. `Opacity` calls `saveLayer` before painting its child and `restore()` after — an off-screen buffer the size of the card, allocated and composited each paint. This is the single most expensive op in `StatCard`. Phase 1's hero-pattern follow-up already established this exact lesson for the chapter card (commit `171dc25`).

2. **`BlendMode.darken` colour overlay on the same image.** `Image.asset(color: black-18%, colorBlendMode: BlendMode.darken)` adds a pipeline op per paint. Phase 1 lesson: opacity alone is enough for readability; the blend mode duplicates the dimming effect.

3. **Hero icon's 14 px blur shadow.** `_buildHeroIcon()` had a `BoxShadow(blurRadius: 14)` behind a 54×54 circle. The icon's silhouette is fixed-size, but it lives inside the card's `RepaintBoundary` layer which re-rasterizes per `AnimatedSize` tick (card bounds grow). Phase 0.2 banned `blurRadius ≥ 12` on widgets in this position — `Tokens.glowSm` (8) is the validated value.

## Changes shipped

[lib/shared/widgets/stat_card.dart](../../../lib/shared/widgets/stat_card.dart):

- **`_buildBackgroundImage()`** — replaced `Positioned.fill → IgnorePointer → Opacity → Image.asset(color, colorBlendMode)` with `Positioned.fill → IgnorePointer → DecoratedBox(decoration: BoxDecoration(image: DecorationImage(image: AssetImage(...), fit, alignment, opacity)))`. The opacity is now baked into the same draw call as the image sample — no `saveLayer`. `BlendMode.darken` dropped entirely. `errorBuilder` removed (DecorationImage silently no-paints on missing asset — equivalent UX).
- **`_buildHeroIcon()`** — `BoxShadow.blurRadius` reduced from `14` to `Tokens.glowSm` (`8`). Alpha + spread unchanged; visual change is minimal (glow halo slightly tighter).

No public API change. `StatCard`'s constructor is unchanged. Visual fidelity preserved (background image dim level untouched — `backgroundOpacity` in `DashboardCardAssetResolver` already encodes the 0.28–0.30 alpha; the dropped `BlendMode.darken` was a redundant 18% black on top that the eye barely registered).

## What was NOT changed (and why)

- **Top-level + inner `RepaintBoundary`** (added in Phase 1.2) — kept. They don't help during a card's own expand (the layer bounds change per tick), but they load-bear for scroll + sibling-expand isolation.
- **`AnimatedSize` → `SizeTransition`** — not pursued. The hypothesis was UI-thread relayout cost per tick, but the user-reported "scroll over OPEN card janks too" pattern is steady-state with no animation running, so per-tick relayout can't explain it. The actual root cause was per-paint raster ops, which the fixes above address for both the expand and the open-scroll cases. If a future trace shows residual UI jank during expand specifically (and not during open-scroll), the `SizeTransition` rewrite is the next lever — but it's bigger surgery and shouldn't be done speculatively.
- **`StatCard` public API** — unchanged. Sleep, body, nutrition screens compose it unchanged.
- **`domain.cardDecoration()`** in `design_tokens.dart` — out of scope (shared across many widgets).

## Verification

- `flutter analyze lib/shared/widgets/stat_card.dart` — clean.
- `flutter test test/widgets/` — 11/11 green (covers `XpClaimPill`, `FtDragRevealPager`, `CelebrationTopsheet` / `CelebrationFullscreen`; `StatCard` itself has no dedicated widget test, so visual verification is manual).
- **Re-trace target (next user-side profile run):** zero frames > 8.3 ms during the 260 ms expand animation; scroll over an open card should fit budget the same as scroll over a closed card.

## Lessons codified

The pattern from Phase 0.2 / Phase 1 hero-pattern extends one more notch:

> When a card sits in a scrollable feed and has any kind of background image, **never wrap the image in an `Opacity` widget** and **never use `colorBlendMode`** for dimming. Use `DecorationImage(opacity:)`. The `Opacity` widget's `saveLayer` is paid every paint, which compounds with `AnimatedSize` expand and with overscroll repaints into raster jank. This rule generalizes beyond progression_engine — it applies to any reusable card widget (`StatCard`, `ExpandableQuestCard`, future templates).

The wider invariant for any widget that lives inside an `AnimatedSize`-driven expand:

> The card's whole layer re-rasterizes per tick. Inside that layer, every `saveLayer`, every blur ≥ 12 px, every `BackdropFilter`, and every `ColorFiltered` (without its own boundary) is paid 16× over the 260 ms animation. Audit each one before merging.
