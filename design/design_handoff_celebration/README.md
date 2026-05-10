# Handoff: Celebration Screen — Variants C & D

## Overview
A redesigned celebration moment for Forgetrack — the screen that appears when the user reaches a level, unlocks an achievement, completes a quest, or otherwise earns a reward. The original was a simple top-sheet that read OK but didn't feel "wow" and had clashing rarity / type colors.

This handoff covers two variants the team selected to ship:

- **Variant C — Multi-reward stack.** Modal for *bigger* moments (level up, quest finale, multi-reward chests). Shows reward cards in a fanned stack; user advances by tapping or swiping.
- **Variant D — Topsheet (current style + claim).** Refined version of the existing top-sheet for *small* wins (common achievements, daily quest completion). Same overall layout as today, plus an entry animation and a small **"Vyzvednout +XP"** gold pill claim button.

Both variants share the **rarity + type color system** described below.

## About the Design Files
The files in `design_files/` are **design references created in HTML** — JSX-flavored React prototypes that run in-browser via `@babel/standalone`. They are not production code. The job is to **recreate these designs in Forgetrack's Flutter codebase** using existing patterns (BottomSheet / Dialog / Riverpod state, the existing rarity & domain color tokens) and not to ship the HTML.

If you want to look at the prototypes:

1. Open `design_files/Celebration.html` in a browser.
2. Use the **Tweaks** panel (top-right) to switch variant, reward type, rarity, XP amount, multi-reward count, and FX intensity.
3. Use the **Replay animations** button (bottom-left) to re-trigger entry animations.

The on-canvas sections also show static "showroom" examples per variant.

## Fidelity
**High-fidelity.** Final colors, typography, spacing, radii, shadows, and animation timings are intentional. Match them when reasonable; the codebase's existing tokens (already aligned with these — see `tokens.css`) take precedence over hex literals where they exist.

---

## Design Tokens

### Rarity tokens
Rarity drives the *aura, glow, particles, accent label, and reward thumb*. **Type** drives the small icon badge and accent of the topsheet header — never the whole scene. This eliminates the existing teal/green/gold/blue collisions.

| Tier | Label (cs) | Color | Color2 (highlight) | Glow rgba |
|---|---|---|---|---|
| common | OBVYKLÉ | `#9CA3AF` | `#D1D5DB` | `rgba(156,163,175,0.45)` |
| uncommon | NEOBVYKLÉ | `#3FB8AF` | `#6FE3D8` | `rgba(63,184,175,0.55)` |
| rare | VZÁCNÉ | `#60A5FA` | `#93C5FD` | `rgba(96,165,250,0.6)` |
| epic | EPICKÉ | `#A78BFA` | `#C4B5FD` | `rgba(167,139,250,0.7)` |
| legendary | LEGENDÁRNÍ | `#F4C152` | `#FFD980` | `rgba(244,193,82,0.85)` |
| mythic | MYTICKÉ | `#F472B6` | `#FB7185` | `rgba(244,114,182,0.95)` |

Particles per tier and "rays intensity" multipliers live in `design_files/celebration-tokens.jsx` — copy that table 1:1.

### Reward types (drive header icon + kicker label only)
```
level       — LEVEL UP        (icon: star/level)
title       — TITUL ODEMČEN   (icon: crown)
achievement — ÚSPĚCH          (icon: medal)
quest       — QUEST DOKONČEN  (icon: flag)
streak      — SÉRIE           (icon: flame)
location    — NOVÁ LOKACE     (icon: map)
cosmetic    — KOSMETIKA       (icon: gem)
```

Type accent colors used in **Variant D** header icon-square only:
```
achievement = #3FB8AF (teal)
quest       = #34D399 (green)
level       = #F4C152 (gold)
title       = #A78BFA (purple)
streak      = #FB923C (orange)
location    = #60A5FA (blue)
cosmetic    = #A78BFA (purple)
```

### Surface tokens (already in `tokens.css`)
- `--bg-app: #0B0F1E`
- `--text-primary: #F5F3FF`
- `--text-secondary: #C7C2E0`
- `--text-muted: #8A85A8`
- Radii: `--r-sm 10`, `--r-md 16`, `--r-lg 20`, `--r-xl 28`

### Typography
Inter / SF Pro Text. Weights 700–900 for titles, 800 for labels with `letter-spacing: 0.16–0.24em` and uppercase. Body 13/14px at 400-600.

---

## Variant D — Topsheet (small wins, common rewards)

### When to show
Default for: common/uncommon achievements, daily quests, streak milestones, level-ups under N levels (tunable). Anything where a full-screen modal would feel too heavy.

### Layout (top-anchored sheet)
- **Position:** 14 px from top, 12 px side margins, free width.
- **Surface:** dark panel, `linear-gradient(180deg, rgba(15,18,38,0.92), rgba(11,15,30,0.95))`, `backdrop-filter: blur(14px)`, `border-radius: 22 px`.
- **Border + shadow tint:** the **type accent** color (NOT rarity) — `1.5px solid {typeAccent}55` with outer glow `0 14px 40px -10px {typeAccent}66`.
- **Inner aura:** radial gradient from top, `{typeAccent}33 → transparent`.
- A few soft particles inside (count 8, `intensity * 0.5`) — subtle, not confetti.

### Header row
- **Icon square** 64×64, radius 14, gradient `{typeAccent}33 → {typeAccent}11`, 1px `{typeAccent}66` border, drop-shadow `0 0 18px -4px {typeAccent}99`. Centered type icon (32px, color = type accent).
- **Kicker** (e.g. "ÚSPĚCH ODEMČEN") — 11px / 800 / `letter-spacing: 0.18em` / uppercase / color = type accent.
- **Title** — 22px / 800 / `#F5F3FF`, line-height 1.15, `text-wrap: balance`.
- **Description** — 13px / `#8A85A8`, line-height 1.4.
- **Close button** — 36×36, radius 10, 1px `rgba(255,255,255,0.08)`, color `#8A85A8`.

### Rewards section
- Section label "ODMĚNY" — 11px / 800 / 0.16em / uppercase / color = type accent.
- Each reward row:
  - 42×42 thumb, radius 10, gradient `{rarityColor}26 → {rarityColor}0a`, 1px `{rarityColor}55` border, type-thumb icon at 22px in `{rarityColor}`.
  - Name 14/700 `#F5F3FF`, single-line ellipsis.
  - Rarity label 10/800/0.16em/uppercase/color = `{rarityColor}`.
  - Row container: `rgba(255,255,255,0.03)` bg, 1px `{rarityColor}33` border, radius 12.
- Multiple rewards stack vertically with 8px gap; entry animations stagger 80ms each.

### Claim CTA (the new bit)
A **small gold pill**, right-aligned, 34 px tall, padding `0 14`, radius 999.
- Background `linear-gradient(180deg, #FFD980, #E5A833)`.
- Text `#0B0F1E`, 13/800 with leading lightning-bolt icon.
- Shadow: `0 4px 12px -4px rgba(244,193,82,0.7), inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1.5px 0 rgba(0,0,0,0.12)`.
- **Idle animation:** `celClaimPulse 2.2s ease-in-out infinite` (subtle box-shadow ring) + diagonal shine sweep `celShine 2.8s` (translate `-30% → 110%`, skew `-18deg`, white→transparent gradient).
- **Press:** instantly switch to "claimed" state — teal text on `rgba(63,184,175,0.14)` background, no shadow, animation off; copy becomes "Vyzvednuto · +205 XP". This is one-way (no un-claim).

### Entry animation
- Sheet slides + fades in from above: `translateY(-30px) → 0`, `opacity 0 → 1`, 0.7 s `cubic-bezier(.16,1,.3,1)`.
- Header icon-square pop: scale `0.6 → 1.08 → 1`, rotate `-8 → 2 → 0`, 0.6 s with 0.1 s delay.
- Reward rows stagger in 80 ms apart starting at 0.25 s.

### Reference example
Common achievement "Získej první odměnu":
```
type: 'achievement', rarity: 'common', xp: 205
title: 'První odměna'
desc:  'Získej svou první progression odměnu.'
rewards: [{ kind:'gem', name:'Jiskra táborového ohně', rarity:'common' }]
```

---

## Variant C — Multi-reward stack (big moments, multi-reward)

### When to show
Quest-finale chests, level-up that grants both a frame+background, anything where there are 2+ rewards or a single legendary/mythic reward. Use the **highest-rarity** reward in the bundle to drive the screen's aura ("headRarity").

### Layout (centered modal, fullscreen)
- **Backdrop:** `radial-gradient(ellipse at 50% 25%, {head.color}22 0%, #0B0F1E 55%, #02030B 100%)`. Behind it, the rest of the app is dimmed/blurred.
- **FX layers (back-to-front):** Aura (intensity 0.7), Rays (0.5, conic-gradient sun rays slowly rotating), Particles (count 14, rising from bottom).
- **Close button:** top-right, 36×36 round, `rgba(11,15,30,0.6)`.

### Header
- Eyebrow "VELKÁ ODMĚNA" — 11/800/0.24em/uppercase, color = head rarity, text-shadow glow.
- Title "Získal jsi {N} {odměnu/odměny/odměn}" — 24/800/`#F5F3FF`. Use Czech plural rules (1 → odměnu, 2–4 → odměny, 5+ → odměn).

### Card stack
- Cards 240×300, radius 24, centered. The active card is index 0 of the visual stack.
- **Card surface:** `linear-gradient(180deg, {rarity.color}38 0%, rgba(20,22,46,0.96) 60%, rgba(15,18,38,0.98))`. **Less transparent than first iteration** — these cards must read as solid even over particles.
- **Border:** 1.5px `{rarity.color}88`.
- **Shadow (active):** `0 0 0 1px {rarity.color}66, 0 18px 40px -12px {rarity.glow}, inset 0 1px 0 rgba(255,255,255,0.08)`.
- **Shadow (inactive):** `0 10px 24px -10px rgba(0,0,0,0.55), inset 0 1px 0 rgba(255,255,255,0.04)`.
- Inner radial glow: `{rarity.glow} → transparent`, opacity 0.6 active / 0.22 inactive.

### Card content
- Top-left corner: small **type badge** pill (icon + label like "ACHIEVEMENT") — used here to communicate type.
- Centered 108 px reward disc — `linear-gradient(180deg, {color2}, {color})`, 2px `{rim}` border, big shadow `0 0 30px {glow}` plus inset highlights/shadows. Reward thumb icon 52 px in `#0B0F1E`.
- Rarity label below disc — 10/800/0.22em color = rarity.
- Reward name 18/800 centered, `text-wrap: balance`.
- Reward sub 11/`#C7C2E0`.

### Card stack physics
For each card with `offset = i - active`:
```
transform: translateX(offset * 40 + dragNudge) px
           translateY(|offset| * 8) px
           rotate(offset * 4 deg + tilt-from-drag)
           scale(active ? 1 : 0.92)
opacity:   |offset| > 2 ? 0 : 1
zIndex:    10 - |offset|
transition: 'transform .45s cubic-bezier(.2,.9,.3,1)' (0 while dragging)
```
Inactive cards translate at `0.4×` of drag (they trail the active one).

### Interactions (this is what changed in the latest pass)
- **Tap inactive card** → focus that card (advance `active` to that index).
- **Tap focused card** → advance to next reward.
- **Swipe left/right** → advance/retreat. Threshold 45 px on touch end; under threshold snaps back.
- **Pagination dots** below cards remain — also clickable. Active dot is 26×8 in rarity color with glow; others 8×8 at 25% opacity.
- **Hint label** under cards: "Tapni nebo přejeď →" while there's a next card; "Hotovo" on the last.
- **Primary CTA** at bottom: "Další odměna" (when more remain) → "Pokračovat" (last). Style = head-rarity gradient pill, 52 px tall.
- **Secondary text button** under the primary CTA: **"Otevřít inventář →"**. Plain text button (no fill, no border), color `#C7C2E0`, 13/600. Tapping should dismiss the celebration and route to the user's inventory/cosmetics screen so they can equip a frame/background/emblem they just got.

### Decent FX (after the latest pass)
The previous version was too noisy. Keep it dialed back:
- Particles count 14 (was 22), intensity multiplier 0.7.
- Rays intensity multiplier 0.5 (was 0.9).
- Aura intensity multiplier 0.7.

### Entry animation
- Whole modal: `celEnter` 0.7 s `cubic-bezier(.16,1,.3,1)` — fade + slight `translateY(16px) → 0` + `scale(.94) → 1`.
- No confetti by default (reserve confetti for legendary/mythic; not part of Variants C/D as shipped).

---

## Shared animation reference
All keyframes in `design_files/Celebration.html` `<style>`:

| Name | Use |
|---|---|
| `celEnter` | generic fade-up entry, 0.7–0.9 s |
| `celRise2` | bigger entry with blur (cinematic only — not used in C/D) |
| `celTop` | topsheet slide-down `translateY(-30px) → 0` |
| `celBreathe` | aura/disc breathing 3 s |
| `celPulse` | XP pill pulse |
| `celShine` | diagonal sheen sweep across CTA |
| `celShimmer` | thumb-card surface shimmer |
| `celRotate` | slow 24 s rotation for ray cone |
| `celRise` | particles rising from bottom |
| `celClaimPulse` | CTA box-shadow ring pulse |
| `celBadgePop` | header icon-square scale+rotate pop |

---

## State management

### Variant D
- `claimed: bool` — flips true on first tap of the gold pill, persists for the lifetime of the sheet. Don't reverse it. Real implementation: dispatch `ClaimXpEvent(reward.id)` on tap, update local state optimistically, sync with backend; on failure, revert and show toast.
- Backend should idempotently award XP — server is source of truth for "already claimed".

### Variant C
- `active: int` — which reward card is focused (0-indexed).
- `drag: number` — current drag delta in px; reset to 0 on touch-end.
- On `active === rewards.length - 1` and primary tap, dismiss the modal.
- Track `viewedRewards: Set<id>` if you want analytics on whether users actually browse all rewards.

---

## Flutter implementation notes (this is a Flutter app)

- **Variant D** → reuse the existing top-sheet widget (probably a `showModalBottomSheet` with `isScrollControlled: true` and a custom shape). The "claim" pill is a `TextButton` styled with `MaterialStateProperty` for the claimed state, wrapped in an `AnimatedSwitcher` for the label change. The pulse + shine are best done with two stacked `AnimationController`s and a `ClipRRect` mask for the shine.
- **Variant C** → `Dialog.fullscreen` (or a custom route with `transitionsBuilder` for the fade-up). The card stack is a `Stack` of `AnimatedPositioned` / `AnimatedContainer` cards driven by `_active` and a `GestureDetector` for `onPanUpdate`/`onPanEnd`. For particles: a `CustomPainter` with a single `AnimationController` is overkill-but-fine; for production, prefer a finite `List<_Particle>` driven by `Ticker`.
- **Rays**: a single conic-gradient is hard in Flutter. Use either an `AnimatedRotation` of an `Image.asset` (pre-baked PNG) or a `CustomPainter` with `Path` segments — the rays don't need to match the CSS conic-gradient exactly, only the visual rhythm (12 spokes, 24 s full rotation, masked by a radial fade).
- **Backdrop blur**: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14))` inside a `ClipRect`.
- All rarity / type tokens already live in the codebase as constants — wire to those, not hard-coded hex.

---

## Files in this bundle (`design_files/`)

- `Celebration.html` — entrypoint; load this in a browser to see the prototype.
- `celebration-tokens.jsx` — **canonical token table.** RARITY (6 tiers), REWARD_TYPE, sample rewards. Copy this 1:1 into the codebase's reward token module.
- `celebration-icons.jsx` — inline SVG icons used in cards/badges. The codebase already has equivalents; use those.
- `celebration-fx.jsx` — `Aura`, `Rays`, `Particles`, `Confetti`, `RewardChip`, `RewardThumb` shared FX.
- `celebration-variants.jsx` — **the actual layouts.** `VariantC` and `VariantD` (also contains the now-cut `VariantA`/`VariantB` for reference; do not implement A/B).
- `celebration-app.jsx` — design-canvas wiring + Tweaks. Not relevant to implementation.
- `tokens.css` — Forgetrack global tokens already shipping in the app (here for reference of variable names).
- `tweaks-panel.jsx`, `design-canvas.jsx` — prototype scaffolding only; ignore for implementation.

---

## Out of scope / future
- Variants A (centered modal, single reward) and B (cinematic fullscreen for legendary+) were explored but **cut**. They live in `celebration-variants.jsx` for reference only; do not ship.
- Sound design.
- Haptics on claim / card swipe — recommend medium-weight haptic on claim, light tick on each card focus change.
- Persistence: claim state needs server source-of-truth (see "State management").
