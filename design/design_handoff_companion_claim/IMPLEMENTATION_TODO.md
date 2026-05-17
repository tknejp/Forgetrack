# Companion Claim — Implementation TODO

**Status:** Blocked. **Do not implement to high-fidelity until the domain model refactor lands ([docs/domain_model/session_handoff.md](../../docs/domain_model/session_handoff.md))** and at least the `Companion` aggregate is in place.

---

## Why this is blocked

The hi-fi design specifies a `CompanionClaim` component with a strict 4-phase state machine (`ready → forging → morphing → detail`). Building it on top of the current cosmetics/progression-bridge architecture means:

- Threading the four phases through `CosmeticDetailsSheet` + `CompanionClaimReveal` + `CosmeticsScreen` by hand, which we already tried and which produced the bugs (stale `revealResult`, claim screen not flipping after unlock, devtools transitions landing wrong).
- Hard-coding cosmetic-id ⇔ companion-id ⇔ node-id assumptions that the upcoming `Companion` aggregate will encapsulate.
- Building a `morphing` handoff (overlay → sheet position interpolation) without a stable identity owner for the animated companion.

The design will fit cleanly once `Companion` (sealed lifecycle) exists. Starting now means writing throw-away code.

---

## What's already implemented (and stays for reference)

Partial groundwork shipped in current main:

- [`lib/features/cosmetics/presentation/widgets/companion_claim_reveal.dart`](../../lib/features/cosmetics/presentation/widgets/companion_claim_reveal.dart) — single-variant ~1.6s "Orbita-lite": idle pulse + relic orbits + silhouette → real-asset cross-fade. **Treat as a placeholder.** The hi-fi spec wants 5.4s with three selectable variants and a fully separate state machine.
- [`lib/features/cosmetics/presentation/cosmetic_details_sheet.dart`](../../lib/features/cosmetics/presentation/cosmetic_details_sheet.dart) — `_ClaimableCompanionBody` + `_LockedCompanionBody` branches with the silhouette + hidden-name pattern. Aligns with the design's `ready` phase, missing the `morphing` handoff to `detail`.
- l10n keys: `cosmeticCompanionClaimableHiddenName`, `cosmeticCompanionClaimableHint`, `cosmeticCompanionClaimingFlavor`, `cosmeticCompanionCelebrationHint`, `cosmeticCompanionClaimCta`, `cosmeticCompanionClaimableBadge`, `cosmeticRelicConsumedBadge`. Reuse, don't reinvent.
- Bridge fix in [`cosmetic_unlock_bridge.dart`](../../lib/features/progression_engine/application/cosmetic_unlock_bridge.dart) — `companionAvailability` reward grants now translate to cosmetic unlocks. Without this, the claim never actually unlocked. **Keep.**
- Devtools state matrix ([`devtools_cosmetics_section.dart`](../../lib/features/devtools/presentation/sections/devtools_cosmetics_section.dart) + [`companion_dev_controller.dart`](../../lib/features/devtools/application/companion_dev_controller.dart)) — four-state transitions for testing. Will be refactored onto the future `Companion` aggregate but the matrix UI itself survives.

---

## Implementation deltas (design ↔ current code)

These are everything the hi-fi spec asks for that today's code does not deliver. Use this as the implementation checklist **after** `Companion` aggregate lands.

### Animation engine

- [ ] **5.4s total duration** with explicit phase timeline (current: 1.6s flat).
- [ ] **Three variants** (Orbita / Fontána / Náraz) — picker probably as a dev toggle or per-companion authoring field. Current code has no variant concept.
- [ ] **Orbita variant:** fly-in (0–600), orbit + spiral (600–2400), pull-to-center (2400–2700), burst (2700–3100), aura bloom (2700–3300), sprite materialize (2800–4800, blur 14→0, rise 40→0, scale 0.12→1, opacity `pow(x, 1.6)`), converging wisps (2800–4750), settle (4800–5400, sin wobble ±6px, 350ms period).
- [ ] **Fontána variant:** drop → well charge → geyser column → aura bloom → materialize → settle.
- [ ] **Náraz variant:** charge with growing shake → slam → 12 SVG-style rays + ~50 shards → aura → materialize → settle.
- [ ] **No fullscreen flash rings** (explicitly removed in design review).
- [ ] **Status text crossfade** during animation:
  - `t < 600`: `Připravuji rituál…`
  - `t < 2400`: `Spojuji relikvie…`
  - `t < 2900`: hidden
  - `t < 4700`: `Probouzím společníka…`
  - `t ≥ 4700`: companion name (Inter 30/700, white, golden text-shadow) + sub `Tvůj nový společník`

### State machine (4 phases)

- [ ] `ready` — bottom sheet at design size, breathing outer ring (2.6s ease-in-out), inner paw silhouette, two relics with `floatA`/`floatB` 3.4s, relic chips with ✓, primary CTA `Vyzvedni společníka`.
- [ ] `forging` — fullscreen overlay (one of three variants).
- [ ] `morphing` — **critical handoff phase (1.15s).** Companion morphs from overlay centre (220×220) to detail-sheet slot (130×130 at `(87, sheet_top + 35 + 65)`). Easing `cubic-bezier(.22, .8, .2, 1)`. Detail sheet slides up simultaneously with `hideCompanion=true` until morph completes. Render order: morph layer must be above the rising sheet.
- [ ] `detail` — full companion details sheet (left column 130×130 with idle float, right column with title + tags + unlock date, description, perk badge, action row with `reset / 56×56 ghost`, `přivolat / 56×56 ember-tinted`, `Vybavit / flex-1 primary`).

### Detail sheet layout

- [ ] **Perk badge** — rounded 14, bg `rgba(123,122,251,0.08)`, border `rgba(123,122,251,0.18)`, sparkle + perk description (e.g. `+5 % zkušeností za dokončené denní úkoly`). **No equivalent in current `CosmeticDetailsSheet` claimed branch.** Requires per-companion perk metadata — open question whether perks live in catalog or are derived from companion lifecycle.
- [ ] **"Přivolat" (summon) action** — companion-specific ember-tinted button (`rgba(255,140,42,0.12)`, color `#FF8C2A`, flame icon). Today there's no summon concept in the codebase.
- [ ] **Reset / replay action** — 56×56 ghost button with refresh icon. Probably devtools-only in prod (replay claim animation). Decide where it surfaces.
- [ ] **Tags layout** — rounded-100 pills (`Společník` + `Běžné`), border `rgba(255,255,255,0.08)`, padding `5 12`. Current sheet uses `_TinyPill` — close but not identical; verify against design tokens.
- [ ] **Unlock date format** — `Odemčeno {dnes}.` (Czech "today" word, not the medium date format `cosmeticUnlockedAt` currently uses). Decide whether to add a relative-time helper.

### Assets

- [ ] Real ember-sprite + relic artwork. The design references `ember_sprite.png`, `campfire_spark.png`, `warm_kindling.png` in [assets/](assets/). Today only one companion (`companion_ember_sprite`) plus the relic prototypes exist as drafts. Other 6 companions need analogous artwork before their claim flow ships.
- [ ] Particle textures for `burst` / `geyser` / `shards` — not yet authored. Decide between hand-painted PNG, procedurally drawn (Custom Painter), or imported (Rive / Lottie).

### Cross-cutting

- [ ] **Render order discipline** — current Flutter sheet uses `showModalBottomSheet`; the morphing handoff requires the overlay to render *above* the rising sheet. Likely needs a custom `Navigator` page or a stacked overlay above the sheet's `Scaffold`. Worth a quick proof-of-concept early.
- [ ] **Reset path** — design has explicit `reset → ready` arrow. In production, "reset" means re-running the animation; the underlying cosmetic stays unlocked. Need a non-destructive way to replay.
- [ ] **Engine ↔ animation timing** — `progression.claimNode()` currently runs *during* the animation. Spec implies claim writes happen at `t ≥ 4800` (sprite materialize complete). Decide whether the engine call should be deferred or whether the visual order is independent of the engine write.

---

## Sequence

1. **Wait for** [`docs/domain_model/proposal.md`](../../docs/domain_model/) to be accepted.
2. **Wait for** `Companion` aggregate (sealed `CompanionLifecycle` states) to be implemented as the first aggregate from the proposal.
3. Then revisit this TODO. The `ready` phase ports directly onto `Claimable` lifecycle, `forging` is a transient overlay driven by `Companion.claim()` use case, `morphing` is a presentation concern over the lifecycle transition, `detail` is the `Claimed` state rendering.
4. Decide on animation tech (custom Flutter `AnimationController` + `CustomPainter` vs Rive vs Lottie) — defer until step 3.

## What NOT to do

- ❌ Build the morphing handoff or fullscreen overlay before the aggregate exists. It will leak into the bridge code and we'll repeat the previous bugs.
- ❌ Introduce per-companion perk authoring into `CosmeticDefinition` today. Wait for the catalog-consolidation decision in the domain proposal.
- ❌ Author additional companion artwork before the design tech choice is made (PNG vs vector — different export pipelines).

---

## References

- [README.md](README.md) — full hi-fi spec (states, timings, easings, tokens).
- [app.jsx](app.jsx), [claim.jsx](claim.jsx), [sheets.jsx](sheets.jsx), [tweaks-panel.jsx](tweaks-panel.jsx) — runnable HTML/React prototype to play with timings & variants.
- [Companion Claim.html](Companion%20Claim.html) — bundles the prototype for a single-file preview.
