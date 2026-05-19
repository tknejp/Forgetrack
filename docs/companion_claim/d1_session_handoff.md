# D.1 Companion Claim Flow — Session Handoff

**Status:** branch created, plan approved, implementation not yet started.
**Created:** 2026-05-19, end-of-context. Handoff for the next session to pick up D.1 cleanly without re-deriving the plan.

---

## TL;DR — what to do

Implement the 4-phase companion-claim animation (state machine `ready → forging → morphing → detail`) per the hi-fi design handoff. **D.1 ships the Orbita forging variant + the morphing handoff + a scope-limited detail phase.** Fontána / Náraz variants, perk badge, and the Přivolat / reset actions are deferred to D.2 ([#89](https://trello.com/c/rf8JTUet)) and D.3 ([#90](https://trello.com/c/ydLXWbM7)) — do **not** ship them in D.1.

The branch is fresh from `main` (which already has #76 + #77 + #92 merged). Work in 4 atomic commits in the order below. After C4 lands, propose move-to-Hotovo and close [#88](https://trello.com/c/4rlo5IiS).

---

## Bootstrap reading (in order, no skimming)

1. **Trello card [#88 — D.1](https://trello.com/c/4rlo5IiS)** — scope, deferred items, risks, refs.
2. **`design/design_handoff_companion_claim/README.md`** — full hi-fi spec. Time tables, easings, tokens, animation curves. Source of truth for fidelity.
3. **`design/design_handoff_companion_claim/IMPLEMENTATION_TODO.md`** — explicit delta between design and current code. Ignore the "wait for Companion aggregate" banner — Companion aggregate landed in Track A; D.1 is now unblocked per #88's premise.
4. **`design/design_handoff_companion_claim/claim.jsx`** — runnable React prototype of the ClaimOverlay (3 variants + MorphTransition). The Orbita timeline in `claim.jsx` is the timing reference; copy the timing constants verbatim.
5. **Current entry points in the codebase:**
   - `lib/features/cosmetics/presentation/widgets/companion_claim_reveal.dart` — the existing ~1.6s "Orbita-lite" placeholder. **D.1 deletes this in C4** once the new flow absorbs its responsibilities.
   - `lib/features/cosmetics/presentation/cosmetic_details_sheet.dart` — `_ClaimableCompanionBody` hosts the claim widget today (search for `CompanionClaimReveal(`). Replace with the new flow in C1.
   - `lib/features/cosmetics/presentation/widgets/cosmetic_asset_thumb.dart` — reusable thumb widget; use for relic / companion images.
6. **`CLAUDE.md`** + **`docs/architecture.md`** — project rules, layering, design tokens. Same as always.

---

## Decisions already made (do not re-litigate)

| # | Question | Answer |
|---|---|---|
| 1 | Tap-anywhere skip during forging? | **Yes, including production.** Tap on the overlay collapses the timeline to the final frame and immediately advances to `morphing`. |
| 2 | Haptic feedback hooks? | **Yes.** `HapticFeedback.mediumImpact()` at: (a) CTA tap on Vyzvedni, (b) burst peak `t ≈ 2700`, (c) reveal moment `t ≈ 4700`. |
| 3 | Engine ↔ animation timing — when does `progression.claimNode()` fire? | **Deferred — call at `t ≈ 4800` (sprite materialize complete) instead of at CTA tap.** Smooth UX is the priority; the engine write is sequenced AFTER the visual reveal, not concurrent with it. The sheet's `context.watch<CosmeticsProvider>()` already rebuilds the body once `cosmetics.unlock` lands, so this re-ordering is safe. |
| 4 | Asset @1×/@2×/@3× variants? | **No.** Use the existing single-resolution assets in `assets/cosmetics/companions/` + `assets/cosmetics/relics/`. Spawn a separate card if density variants become a problem post-launch. |

---

## Branch state

- **Branch:** `feat/companion-claim-flow-d1`
- **Base:** `main` @ `22af42a` (Merge `fix/companion-claim-eval-trigger`). All of #76, #77, #92 are already in.
- **Working tree:** clean (only this handoff doc as an addition).
- **Baseline verify before first edit:** `flutter analyze` → 77 issues, `flutter test` → 496 passing, all 5 lint ratchets at 0. **If those don't match, stop and reconcile — something drifted on main.**

---

## Implementation plan — 4 atomic commits

### File structure (target)

```
lib/features/cosmetics/presentation/widgets/
  companion_claim_flow.dart          ← NEW (C1).  State-machine entry widget; replaces CompanionClaimReveal at the call site.
  companion_claim_forging.dart       ← NEW (C2).  Fullscreen Orbita overlay with the 5.4 s timeline.
  companion_claim_morph.dart         ← NEW (C3).  1.15 s overlay → detail-slot handoff.
  companion_claim_reveal.dart        ← DELETE (C4). Old ~1.6 s placeholder, fully absorbed by C1–C3.
```

### C1 — State machine + `ready` phase reuse

**Goal:** refactor target with no visual diff. The new flow's `ready` body is a 1:1 copy of today's `_ClaimableCompanionBody` content (silhouette + breathing ring + two relic tiles + primary CTA). The forging / morphing / detail branches return placeholders (a plain `SizedBox.shrink()` or the existing `CompanionClaimReveal` for forging to keep the screen alive during C2 dev). No `claimNode` call moves yet — keep the old wiring as-is so the build still works.

**Touches:**
- `companion_claim_flow.dart` (new) — `enum CompanionClaimPhase { ready, forging, morphing, detail }` (local; not a domain concept). `StatefulWidget` owning the phase + an `AnimationController` (durations driven by phase). Exhaustive switch in build().
- `cosmetic_details_sheet.dart` — `_ClaimableCompanionBody` replaces `CompanionClaimReveal(...)` with `CompanionClaimFlow(...)`.

**Risk:** Low. **Verify:** identical visual on debug build + `flutter analyze` 77 + `flutter test` 496.

### C2 — Orbita forging timeline (5.4 s)

**Goal:** the full forging phase per spec §"Stav 2 Varianta A". Single `AnimationController(duration: Duration(milliseconds: 5400))`. Sub-phase progress derived via `Interval` curves.

**Timeline (verbatim from design):**

| t (ms) | sub-phase |
|---|---|
| 0 – 600 | fly-in (relics move from sheet positions to orbit ±80 px) |
| 600 – 2400 | orbit + spiral (turns ≈ 2.5, radius `lerp(80, 0, easeInOut)`) |
| 2400 – 2700 | pull-to-center (relic scale 1 → 0.3) |
| 2700 – 3100 | burst (60 × intensity particles, **no fullscreen ring shockwave**) |
| 2700 – 3300 | aura bloom |
| 2800 – 4800 | sprite materialize (scale 0.12→1 easeOut, opacity `pow(t, 1.6)`, blur 14→0 px, rise 40→0 px) |
| 2800 – 4750 | converging wisps (~12 wisps fly in from 150 px out) |
| 4800 – 5400 | settle (sin wobble ±6 px, 350 ms period) |

**Status text crossfade** (centered, ~18 % from bottom):
- `t < 600`: `Připravuji rituál…` (Inter 15/500, `#9AA0BF`)
- `t < 2400`: `Spojuji relikvie…`
- `t < 2900`: hidden
- `t < 4700`: `Probouzím společníka…`
- `t ≥ 4700`: companion name (Inter 30/700, white, `textShadow 0 0 20px rgba(255,180,80,0.4)`) + sub `Tvůj nový společník`

ARB keys already exist for the loading copy: `cosmeticCompanionClaimingFlavor`, `cosmeticCompanionClaimableHiddenName`. Add new keys as needed: `cosmeticCompanionClaimStepRitual`, `cosmeticCompanionClaimStepBinding`, `cosmeticCompanionClaimStepAwakening`, `cosmeticCompanionClaimRevealSubtitle` (run `flutter gen-l10n` after each ARB edit).

**Haptics:** call `HapticFeedback.mediumImpact()` at `t = 2700` (burst peak) and `t = 4700` (reveal). Wire the CTA-tap haptic in C1.

**Particles:** `CustomPainter` redrawing 60 sprites per frame. Spec is explicit — no shock-ring overlays, only particles + wisps. Acceptable to start with simple coloured discs (`Tokens.emberBright` = `#FFD166`); polish to actual textured particles only if performance budget allows.

**Skip:** GestureDetector covering the overlay calls `_controller.value = 1.0` (jumps to settle) then immediately advances to `morphing` after one frame. Per decision (1) this is available in production.

**Touches:**
- `companion_claim_forging.dart` (new).
- `companion_claim_flow.dart` — wires phase=forging → renders the overlay.
- ARB files + l10n regen.

**Risk:** Medium (timing precision + custom paint perf). **Verify:** run on debug build, watch the full 5.4 s, confirm particle perf > 50 fps. Add a structural widget test (overlay mounts, controller runs, status text crossfades through the four labels at expected progress points).

### C3 — Morphing handoff (1.15 s)

**Goal:** the companion sprite seamlessly travels from the forging-overlay center to the detail-sheet's avatar slot. Spec §"Stav 3":
- Source: screen center, 220 × 220 px, drop-shadow 12 px.
- Destination: detail-sheet slot at `(87, sheet_top + 35 + 65)` px, 130 × 130 px, drop-shadow 8 px.
- Curve: `cubic-bezier(.22, .8, .2, 1)` for 1150 ms.
- Detail sheet slides up over 1100 ms with same curve, with `hideCompanion=true` so its slot is empty until morph completes.

**Render-order requirement (the hard part):** the morph layer must render **above** the rising sheet. With `showModalBottomSheet`, the sheet IS the topmost route — anything inside its `builder` renders below the sheet's frosted backdrop. Three viable approaches:

- **(a) `Overlay.of(context).insert(OverlayEntry(...))`** — Flutter's `Overlay` widget sits above modal routes by default. Add an `OverlayEntry` for the morph layer at C2's end; the entry persists until C3 ends.
- **(b) Custom route** — replace `showModalBottomSheet` with a `PageRouteBuilder` that draws both the sheet + the morph layer in a single `Stack` we control. Most flexible but largest blast radius (changes the route lifecycle the existing sheet relies on).
- **(c) Reparent the morph child via a `GlobalKey`** — render the sprite once in the overlay route, then move it to the detail sheet via `KeyedSubtree`. Subtle but fragile; element-tree pinning across routes is undocumented.

**Recommended: (a)** — `Overlay.of` is well-supported, the lifecycle is explicit (`OverlayEntry.remove()` is the cleanup), and it works above any modal route. Sheet rebuilds normally; overlay renders on top.

**Touches:**
- `companion_claim_morph.dart` (new). Holds the morphing widget + its `OverlayEntry` plumbing.
- `companion_claim_flow.dart` — on phase=forging → insert overlay; on phase=detail → remove overlay.
- `cosmetic_details_sheet.dart` — `_ClaimableCompanionBody` exposes a `hideCompanion` flag via a `ValueNotifier` that the morph layer reads. (The flag is on the body's State, NOT on the widget — the sheet is the same widget instance across the phase transition.)

**Slot position lookup:** wrap the detail-sheet's companion-image slot in a `RenderBox` with a known `GlobalKey`; on phase transition, read `key.currentContext.findRenderObject() as RenderBox` → `localToGlobal(Offset.zero)`. That gives the absolute destination. Don't hardcode `(87, sheet_top + 35 + 65)` — derive from the actual rendered slot.

**Risk:** **High.** Render-order is the single hardest part of D.1. **Verify:** run the flow end-to-end on debug build; the companion sprite must travel smoothly through the morph with no z-fighting (sheet briefly above), no jumps. Add a structural test that the morph widget mounts + dismounts at the expected timings (no pixel test).

### C4 — `detail` phase (scope-limited) + cleanup

**Goal:** ship the detail phase per spec §"Stav 4" minus what's deferred:
- IN: companion image (130 × 130, idle float `companionIdle` 3.2 s), title (Inter 26/700), tags (`Společník` + rarity name in rounded-100 pills), unlock date (`Odemčeno {dnes}.` — hard-code "dnes" or use a new ARB key `cosmeticCompanionUnlockedToday`), description, **Vybavit** primary button (flex-1).
- OUT (deferred): **perk badge → #89 D.2**; **Přivolat + reset action buttons → #90 D.3**. The action row in D.1 is just the Vybavit button (full-width).

**Delete `companion_claim_reveal.dart`** — its responsibilities are now fully owned by the new flow. Verify with `grep -rn "CompanionClaimReveal" lib/` returns no matches.

**Touches:**
- `companion_claim_flow.dart` — wires phase=detail → renders the detail body.
- Optionally factor the detail body into its own widget if it grows.
- ARB key for "Odemčeno {dnes}." if not already present.
- Delete `companion_claim_reveal.dart`.

**Risk:** Low. **Verify:** the flow goes ready → forging → morphing → detail cleanly on debug build; `flutter analyze` 77 ✓; `flutter test` 496 ✓ (no test count change expected — tests added in C2/C3 balance the deleted file's surface).

---

## Trello cards

- **D.1 — this card** ([#88](https://trello.com/c/4rlo5IiS)) — state machine + Orbita + morphing + scope-limited detail.
- **D.2** ([#89](https://trello.com/c/rf8JTUet)) — per-companion perk metadata + perk badge in detail. Pick option (a) cosmetic-only flavor for the first pass per card description.
- **D.3** ([#90](https://trello.com/c/ydLXWbM7)) — Summon (Přivolat) action + reset/replay. **High risk — design needs to settle on which of 4 semantic options (a)–(d) before implementation.** Do not start D.3 without a design conversation on the card.

---

## What's already shipped on main (context for the new session)

- **#77** ([Hotovo](https://trello.com/c/d2GYcOum)) — companion catalog cleanup (every-10 level ladder, 3 unobtainable companions fixed, dead CosmeticUnlockEvaluator deleted).
- **#76** ([Hotovo](https://trello.com/c/dpLm2EKM)) — claim-flow phase A (devtools/late-gate bug), B (teaser visibility), C (locked card visual + rarity pulse), E (navigation post-unlock audit), F (level badge + tappable relic tiles in details sheet). 16 commits.
- **#92** ([Hotovo](https://trello.com/c/Eg5m1yg0)) — devtools companion state matrix: `clearEventsForNode` primitive landed on both Isar + Firestore so devtools "Set Claimable" reset survives cloud pull.

**Key recent architectural decisions** the new session should know about (ADRs in `docs/site/data/decisions.json`):

- `r7-companion-catalog-audit-correction` — all 10 companions use `CompanionAvailability` engine nodes (no whitelist split).
- `companion-availability-owns-cosmetic` — companion gates use `OwnsCosmetic(relic_id)` reading the cosmetics inventory directly, not `NodeCompleted(achievement_id)`. Engine + reveal evaluator agree on relic ownership.

---

## Anti-protocols (carry over from #76 handoff)

- **No scope creep.** Anything outside D.1's checklist that surfaces during work → blocker (stop + ask) OR new Trello card. Never expand #88 mid-implementation.
- **No persistence schema changes.** D.1 is pure presentation work. Isar `.g.dart` diff must be empty; Firestore wire format frozen; SharedPreferences keys frozen.
- **No new production dependencies.** Dev-deps OK only if a clearly motivated test addition needs one.
- **Lint ratchets at 0.** New violations either fixed in-place or land with explicit `lint-ignore: <rule> — <reason>` markers. Never raise the baseline.

---

## Per-commit verification ritual

Run after every commit:
1. `flutter analyze` — clean at 77-issue baseline (the existing `unnecessary_const` infos in catalog content files are pre-existing, ignore).
2. `flutter test test/features/cosmetics/ test/lint/production_scan_test.dart` — green; all 5 lint ratchets pass.
3. (At C2 + C3 + C4) `flutter test` full suite — must stay at 496+ green.

After C2 + C3 land: smoke check on a debug build (devtools matrix → Set Claimable → tap Vyzvedni → walk through forging → morphing → detail). Document outcomes in a Trello comment per commit.

---

## When this handoff stops being useful

After C4 lands and #88 moves to Hotovo, archive this doc to `docs/companion_claim/archive/d1_session_handoff.md`. Don't accumulate stale handoffs — see CLAUDE.md §"Closing out a finished plan".
