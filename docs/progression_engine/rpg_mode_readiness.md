# Progression Engine — RPG Mode Readiness

**Status (2026-05-19):** open. Spec ready, no implementation yet.

This is a standalone successor to the V2 phased plan's Phase 8.
The V2 phased plan + its phase-8/9 handoff doc both shipped and were
archived 2026-05-19 (V2 module is canonical on every UI surface;
legacy `lib/features/progression/` deleted under domain refactor
Phase 22). This document carries the one remaining open V2 design
goal — **flip a setting to hide RPG-flavored content without
re-running progression in a different mode** — forward as its own
work item, free of phase-numbering scaffolding.

Reading order:

1. This document — the spec + acceptance criteria.
2. `archive/v2_phased_plan.md` §10 — full RPG mode design + risk
   analysis the original V2 plan worked out.
3. `archive/v2_phased_plan.md` §4 — `ActivationPolicy` + `ContentTag`
   definitions in the V2 domain model. These types already exist in
   the codebase; the work below wires them into the engine + display
   layer.

---

## Why this matters

The product brief is unambiguous: **do not build the toggle UI yet**,
but design the engine so that flipping a single setting can hide
RPG-flavored content (relics, companions, narrative chapters) and let
the player run a pure fitness-tracking experience.

Today every catalog entry is treated the same way regardless of
RPG mode — the engine evaluates everything, the display layer shows
everything, and there's no way to opt out without forking the
catalog. The work below changes that without forking the engine or
duplicating data.

---

## Design — two axes of control

The V2 plan locked these in as Appendix-A decisions; they already
exist as types in `lib/features/progression_engine/domain/`:

- **`ContentTag`** on every node and reward — declarative metadata
  (`fitness`, `rpg`, `relics`, `companions`, …). Hidden by the
  display filter, not by the evaluator.
- **`ActivationPolicy`** on every node — behavioral.

### Activation policy variants

- `always` — eligible no matter what (default for fitness content).
- `onlyWhenRpgEnabled` — engine skips evaluation while RPG off; when
  RPG re-enables, the engine catches the player up as if it had been
  on all along (idempotent ledger pass).
- `onlyWhenRpgEnabledNoBackfill` — missed while off ⇒ stays missed.
  Reserved for time-limited or "ironman"-style modes if they ever
  exist; nothing in the catalog uses this policy yet.

### Behavior matrix

| RPG setting | Node activation | Display filter | Notes |
|---|---|---|---|
| RPG **on** | All policies eligible | Show everything tagged anything | Default for current users |
| RPG **off** | `always` eligible; `onlyWhenRpgEnabled` skipped during evaluation; `onlyWhenRpgEnabledNoBackfill` skipped *and* never granted retroactively | Hide nodes tagged only with `rpg` / `relics` / `companions` / etc. (no `fitness` overlap) | Core fitness progression continues |

### Where the filter lives

- **Engine evaluation** — applies activation policy. Honest about
  what's actually granted to the player ledger.
- **Display layer** — applies content-tag filter for rendering. A
  user who turned RPG off and back on may have RPG ledger entries
  from before the toggle; the display layer hides the RPG section
  while RPG is off, but the ledger keeps the data so re-enabling
  doesn't lose history.
- **Celebration adapter** — uses the same content-tag filter;
  doesn't celebrate RPG events while RPG is off.
- **Social publisher** — same filter; doesn't emit RPG-flavored
  events to friends while RPG is off.

### What does *not* happen

- No `if (rpgModeEnabled) { ... }` checks scattered across UI
  widgets. The setting is one boolean read by the activation
  evaluator + the display filter; everything else is data.
- No second engine, no second catalog, no engine fork.
- No "RPG-aware" copies of node types.

---

## Implementation

1. **`RpgModeProvider`** — a thin `ChangeNotifier` over a
   `SharedPreferences`-backed bool. **No user-facing toggle.**
   Persistence key: `progression_rpg_mode_enabled` (default `true`
   for parity with current behaviour).
2. **`ActivationPolicy` enforcement** in the engine evaluator. The
   resolver already loads policies but doesn't act on the
   "skip-while-off" branches; wire that in `progression_node_resolver`
   + `reward_grant_planner`.
3. **Display-layer content-tag filter.** Add a single
   `RpgVisibilityFilter` helper consumed by `ProgressionDisplayResolver`
   + the journey + quest screens. Filter is applied at the resolver
   boundary so screen widgets stay unaware.
4. **Hidden devtools toggle:** *Devtools → Progression → RPG mode
   (debug)*. Flips `RpgModeProvider.enabled`; lets QA verify the
   matrix without exposing the setting in production UI.
5. **Catalog validator rules** — `CatalogValidator` already inspects
   nodes; extend it to flag content-tag / activation-policy
   combinations that don't make sense (e.g. a `rpg`-tagged node
   with `ActivationPolicy.always` — would render in fitness-only
   mode, defeating the point).
6. **Re-enable backfill** — when `RpgModeProvider.enabled` flips
   from `false` → `true`, the engine should run a one-shot
   evaluation that catches the player up on any
   `onlyWhenRpgEnabled` (non-`NoBackfill`) nodes whose objectives
   are already complete. The mechanism is the same idempotent
   ledger replay used by `JournalProjection.rebuildFromJournal`
   (`RebuildFromJournalReason.factoryReset` is the closest existing
   reason — add `rpgReenabled` if a more specific log makes sense).

---

## Acceptance

- Flipping the devtools toggle hides RPG-tagged nodes from the quest
  screen + journey map without breaking the core fitness display.
- Re-enabling RPG retroactively grants any `onlyWhenRpgEnabled`
  (non-`NoBackfill`) nodes whose objectives are already complete.
  Engine ledger gains the catch-up `RewardGrantEvent` row(s);
  cosmetics + level state update accordingly.
- No `if (rpgModeEnabled)` literals exist in UI files — `grep -r
  "rpgModeEnabled" lib/features/*/presentation/` returns zero hits.
  All RPG-aware decisions flow through the display-resolver filter
  or the engine evaluator.
- Devtools "RPG mode (debug)" toggle is gated by the existing
  devtools-access flag (developer UID allowlist), not visible to
  end users.
- `CatalogValidator` flags any catalog entry whose
  `ContentTag` × `ActivationPolicy` combination is internally
  inconsistent (test fixture covers the mistakes a content author
  could make).

---

## What this work is NOT

- ❌ A user-facing RPG-mode toggle in Settings. That ships when
  product asks for it; this story only builds the engine substrate.
- ❌ A second catalog or a second engine. The whole point is to keep
  the catalog single-source and let the filter live at the boundary.
- ❌ A migration of existing RPG ledger entries. They stay in the
  journal even when RPG is hidden — the display filter does the
  hiding, the ledger is the source of truth.

---

## When to revisit

Pick this up when product asks for an "RPG off" mode, or when the
content catalogue grows enough that hiding optional content becomes a
UX necessity (the current catalogue is small enough that overload
isn't yet a problem).

If product asks for a Settings toggle, that's an additive PR on top
of this substrate — show the existing `RpgModeProvider.enabled`
toggle in the appropriate Settings section, nothing engine-side
changes.
