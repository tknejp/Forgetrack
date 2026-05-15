# Handoff: Social · friend's view (Forgetrack profile header)

## Overview

This handoff documents the **Social profile header** for Forgetrack — the
cinematic, identity-first header that other users see when they open
someone else's profile. It's a 4 × 400px hero card built around the
hero's **cosmetic loadout** (background scene, avatar frame, companion,
emblem collection) — the cosmetics ARE the visual identity, so the
header is designed to show them off rather than to surface raw stats.

This package covers **only** the Social header (the `SocialHeader`
component) plus its enclosing demo screen (`SocialScreen`). The
own-profile "Hero · own progression" header is intentionally **not**
included.

## About the Design Files

The `SocialHeader.reference.jsx` file in this bundle is a **design
reference written as inline-styled React** — a prototype showing the
intended look and structural decomposition, not production code to
copy directly. Your task is to **recreate this design in the target
codebase's existing environment** (React + your styling system,
SwiftUI, Flutter, etc.) using its established patterns: tokens,
component primitives, theming, image-asset pipeline. If no environment
exists yet, pick the most appropriate framework for the project and
implement there.

The inline styles in the reference file are the source of truth for
exact values, but the *organisation* of the component (sub-components,
layering order, absolute-positioned overlays) is what matters. Lift
the values, drop the inline-style pattern.

## Fidelity

**High-fidelity.** All colours, spacing, type sizes and shadow values
in the reference file are final. The developer should recreate the UI
pixel-perfectly, swapping in the codebase's existing tokens / colour
palette where they map cleanly.

## Screens / Views

### `SocialScreen` — full mobile screen wrapper

The reference file wraps `SocialHeader` in a `PhoneChrome` shell and
adds a few demo stat blocks underneath so you can see the header in
context. **Only the header itself (`SocialHeader`) ships** — the stat
cards, friends row and "Připnuté achievementy" copy below it are
placeholders representing whatever the real profile screen contains.

### `SocialHeader` — the actual deliverable

- **Name:** Social profile header (a.k.a. friend's profile hero)
- **Purpose:** Establish who this person is at a glance. Their avatar,
  name, level, title and cosmetic loadout all visible in the first
  fold.
- **Size:** Full screen width (designed at 412 px wide for an iPhone
  14 viewport), **400 px tall**, no rounded outer corners (sits
  flush at the top of the profile page, under the status bar).

#### Layout

The header is one absolutely-positioned 400 px tall block layered as
follows (bottom → top):

1. **Background image** — `forest_trail.png` (or the hero's chosen
   "background" cosmetic), `object-fit: cover`, `object-position:
   center 30%`. Fills the full 412 × 400 box.
2. **Radial darken** — `radial-gradient(ellipse at 50% 35%,
   transparent 0%, rgba(10,14,28,0.45) 70%, rgba(10,14,28,0.95)
   100%)`. Pulls focus to the centre and dims the edges.
3. **Vertical fade** — `linear-gradient(180deg,
   rgba(10,14,28,0.5) 0%, transparent 22%, transparent 55%,
   rgba(10,14,28,0.96) 100%)`. Darkens the top so the status bar
   reads, and darkens the bottom so it can transition smoothly into
   the next section of the profile page (no hard seam).
4. **Avatar block (top-left)** — see *Components* below.
5. **Identity block (top, right of avatar)** — name, handle, title pill.
6. **Companion (bottom-right)** — the hero's chosen companion image.
7. **Ground glow** — soft warm radial ellipse under the companion, sells
   the standee.
8. **Emblem collection (bottom-left)** — 4 × 4 × 3 grid of 52 px slots.

#### Components

##### `FramedAvatar` (top-left, size = 140, tilt = −3°, levelPin = true)

- **Position:** `left: 16, top: 16`.
- **Outer wrapper:** 140 × 140 px square, `rotate(-3deg)`,
  `filter: drop-shadow(0 14px 20px rgba(0,0,0,0.55))`.
- **Inner pixel-art avatar:** the avatar image inset by 10% on all
  sides (so the wildwood frame visually surrounds it), with
  `object-fit: cover`, `image-rendering: pixelated`, `border-radius: 6 px`.
- **Wildwood frame:** decorative PNG `wildwood_frame.png`,
  full-size, `object-fit: contain`, sits on top of the avatar.
- **LVL pin** (only when `levelPin === true`):
  - Position: `bottom: -8px, left: 50%, transform: translateX(-50%) rotate(3deg)` (counter-rotates the parent tilt so the pin sits horizontal).
  - Padding `3px 12px`, `border-radius: 999px`.
  - Background `linear-gradient(180deg, #5A5871, #36344A)` — neutral
    gray (in future this gets tinted by level rarity).
  - Text `LVL {level}` — `font-size: 11px`, `font-weight: 800`,
    `letter-spacing: 0.08em`, colour `#E4E1F0`.
  - Shadow `0 4px 10px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.18)`,
    border `1px solid rgba(255,255,255,0.10)`.

##### Camera edit button (only on own profile — keep hidden in friend's view)

The reference file includes a small camera button at the corner of the
avatar for editing your photo. **In the friend's view of the Social
header, this button is hidden.** Only render it if `viewer.id === profile.id`.

##### Identity block (top, right of avatar)

- **Position:** `left: 172, top: 24, right: 16`.
- **Name** — `Tomáš Knejp` (placeholder).
  - `font-size: 26px`, `font-weight: 800`, `color: #F5F3FF`,
    `letter-spacing: -0.02em`, `line-height: 1.05`.
  - `text-shadow: 0 4px 16px rgba(0,0,0,0.65)` for legibility against
    the photo.
- **Handle** — `@sigisere`.
  - `font-size: 12px`, `font-weight: 500`, `color: #9C8FE0`.
  - 3 px below name, 12 px above title pill.
- **Title pill** — `TitleRow` with `size="md"`, `hideEmblem`.
  - Inline-flex pill, `padding: 4px 10px`, `border-radius: 999px`.
  - Background `rgba(255,255,255,0.05)`, border `1px solid rgba(255,255,255,0.10)`.
  - Text `PRŮZKUMNÍK STEZEK` — `font-size: 11px`, `font-weight: 700`,
    `color: #C7C2E0`, `letter-spacing: 0.16em`, `text-transform: uppercase`.
  - **Note:** `hideEmblem` is true in this position because the emblem
    medallion has been moved into the bottom-left collection; the pill
    is text-only.

##### Companion (bottom-right)

- The hero's chosen companion image (`forest_fox.png`).
- 134 × 134 px, `object-fit: contain`.
- Position `right: 6, bottom: 14`.
- `filter: drop-shadow(0 12px 14px rgba(0,0,0,0.55))`.
- Behind it, a `GroundGlow` — a 120 × 14 px radial ellipse
  `rgba(244,193,82,0.45)` at `right: 20, bottom: 10`, `filter: blur(4px)`.
  This sells the companion as a standee with light coming from below.

##### Emblem collection (bottom-left)

- 11 slots, laid out as a **4 · 4 · 3 grid** (3 rows; last row is short
  by one to keep the end-game emblem in its own resting spot).
- Each slot is **52 × 52 px**, with a **6 px gap**.
- Position: `left: 16, bottom: 16`.
- Slot states:
  - **Unlocked + pinned** — the emblem image with a purple radial
    halo behind it (`rgba(124,111,255,0.35)`, blur 4 px,
    inset −12%) and a stronger drop shadow:
    `drop-shadow(0 2px 6px rgba(63,184,175,0.55)) drop-shadow(0 3px 6px rgba(0,0,0,0.5))`.
  - **Unlocked, not pinned** — just the emblem with
    `drop-shadow(0 2px 4px rgba(0,0,0,0.5))`.
  - **Locked, regular slot** — empty dashed square, 9 px radius,
    background `rgba(255,255,255,0.025)`, border `1px dashed rgba(255,255,255,0.09)`,
    with a 4 × 4 px dot at the centre (`rgba(255,255,255,0.18)`).
  - **Locked, end-game slot (slot 11)** — same dashed square, but the
    centre dot is replaced by a faint 4-point star glyph (see SVG path
    in the reference file). This signals "rare" without yelling
    "missing".

## Interactions & Behavior

The Social header itself is mostly static — it's a presentation
surface, not interactive. Interactions live on the surrounding profile
screen (friend / unfriend, message, report, etc.) which is **out of
scope** for this handoff.

- **Avatar:** no tap action in the friend's view (it's not your photo).
- **Emblem slot:** tappable in the live app — opens a sheet showing
  emblem name, unlock condition, rarity. Not modelled in the reference
  file; treat as a `onPress` on each `EmblemSlot`.
- **No hover states** — primary target is mobile touch.
- **No animations on mount.** The header is a static card; the only
  movement in the live app is parallax on scroll (background image
  scrolls at ~0.6× the foreground), which is optional.

## State Management

The Social header is a pure presentational component. It needs:

```ts
type SocialProfileProps = {
  name: string;            // 'Tomáš Knejp'
  handle: string;          // '@sigisere'
  level: number;           // 5
  title: string;           // 'Průzkumník stezek'
  cosmetics: {
    avatar:    string;     // path or URL
    frame:     string;     // path or URL — currently 'wildwood_frame.png'
    background:string;     // path or URL — currently 'forest_trail.png'
    companion: string;     // path or URL — currently 'forest_fox.png'
    emblem:    string;     // path or URL — currently 'forest_mark.png'
  };
  emblems: {
    unlockedCount: number; // 0–11
    pinnedIndex:   number; // 0–10, or null if nothing pinned
  };
  isOwnProfile: boolean;   // hides the camera edit button in friend's view
};
```

No data fetching from inside the component — props in, view out. The
profile screen above fetches and passes everything in.

## Design Tokens

### Colours

| Token              | Hex / value                       | Used for                                  |
|--------------------|-----------------------------------|-------------------------------------------|
| Surface base       | `#0A0E1C`                         | Phone screen / page bg under the header   |
| Identity light     | `#F5F3FF`                         | Name text                                 |
| Identity purple    | `#9C8FE0`                         | Handle text                               |
| Identity muted     | `#C7C2E0`                         | Title pill text                           |
| Title pill bg      | `rgba(255,255,255,0.05)`          | Title pill background                     |
| Title pill border  | `rgba(255,255,255,0.10)`          | Title pill border                         |
| LVL pin top        | `#5A5871`                         | LVL pin gradient top                      |
| LVL pin bottom     | `#36344A`                         | LVL pin gradient bottom                   |
| LVL pin text       | `#E4E1F0`                         | LVL N label                               |
| LVL pin border     | `rgba(255,255,255,0.10)`          | LVL pin outline                           |
| Pinned emblem halo | `rgba(124,111,255,0.35)`          | Radial behind pinned emblem               |
| Pinned emblem glow | `rgba(63,184,175,0.55)`           | Outer drop-shadow on pinned emblem        |
| Locked slot bg     | `rgba(255,255,255,0.025)`         | Empty emblem slot                         |
| Locked slot border | `rgba(255,255,255,0.09)`          | Empty emblem slot dashed border           |
| Locked slot dot    | `rgba(255,255,255,0.18)`          | Centre dot in regular locked slot         |
| Locked end-game    | `rgba(255,255,255,0.22)`          | Faint star glyph in end-game locked slot  |
| Companion glow     | `rgba(244,193,82,0.45)`           | Warm radial under the companion           |
| Vignette dark      | `rgba(10,14,28,0.45)`–`0.96`      | Radial + linear darkening gradients       |

### Spacing

| Token         | Value | Used for                                |
|---------------|-------|-----------------------------------------|
| Header height | 400 px| Total card height                       |
| Edge padding  | 16 px | Distance from card edge to content      |
| Avatar size   | 140 px| `FramedAvatar` outer width / height     |
| Avatar inset  | 10 %  | Frame visual inset from outer wrapper   |
| Identity left | 172 px| Where name/handle/title column starts   |
| Identity top  | 24 px | Top offset for the name                 |
| Emblem slot   | 52 px | Each slot in the 4·4·3 grid             |
| Emblem gap    | 6 px  | Gap between slots in both axes          |
| Companion sz  | 134 px| Companion image width / height          |
| Pill padding  | 4×10  | Title pill / LVL pin inner padding      |
| Pill radius   | 999 px| All pills                               |

### Typography

Single family: **Inter**, fallbacks `"SF Pro Text", system-ui, sans-serif`.

| Role          | Size | Weight | Letter-spacing | Line-height | Color    |
|---------------|------|--------|----------------|-------------|----------|
| Name          | 26   | 800    | -0.02em        | 1.05        | #F5F3FF  |
| Handle        | 12   | 500    | normal         | normal      | #9C8FE0  |
| Title pill    | 11   | 700    | 0.16em         | normal      | #C7C2E0  |
| LVL pin text  | 11   | 800    | 0.08em         | normal      | #E4E1F0  |

### Border radius

- Pills (title pill, LVL pin): **999 px**.
- Avatar inner image: **6 px** (so the wildwood frame can overlap a
  square interior).
- Emblem locked slot: **9 px**.

### Shadows

- **Avatar drop-shadow:** `drop-shadow(0 14px 20px rgba(0,0,0,0.55))`.
- **LVL pin shadow:** `0 4px 10px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.18)`.
- **Companion drop-shadow:** `drop-shadow(0 12px 14px rgba(0,0,0,0.55))`.
- **Pinned emblem drop-shadow:** `drop-shadow(0 2px 6px rgba(63,184,175,0.55)) drop-shadow(0 3px 6px rgba(0,0,0,0.5))`.
- **Unlocked unpinned emblem drop-shadow:** `drop-shadow(0 2px 4px rgba(0,0,0,0.5))`.
- **Name text-shadow:** `0 4px 16px rgba(0,0,0,0.65)`.

## Assets

The following cosmetic assets are referenced by the design but **are
not included in this bundle**. You'll source them from the app's
existing cosmetic catalogue or asset pipeline:

| Asset key   | Reference name        | Purpose                              |
|-------------|-----------------------|--------------------------------------|
| `bg`        | `forest_trail.png`    | Background scene fill (412×400)      |
| `frame`     | `wildwood_frame.png`  | Decorative frame around avatar       |
| `avatar`    | `avatar_pixel.png`    | The hero's chosen pixel-art avatar   |
| `companion` | `forest_fox.png`      | Standing companion in bottom-right   |
| `emblem`    | `forest_mark.png`     | Per-emblem icon for unlocked slots   |

**Each of these is a swappable cosmetic** — the API will return per-user
URLs for the four loadout slots (background / frame / avatar /
companion) plus an array of unlocked emblem icon URLs. Don't hard-code
the names above; the values in `COSMETICS` in the reference file are
placeholder paths.

## Files

- `README.md` — this document.
- `SocialHeader.reference.jsx` — the design reference. Contains only
  the components needed for the Social view:
  - `FramedAvatar`, `TitleRow`, `GroundGlow`
  - `EmblemSlot`, `EmblemCollection`
  - `SocialHeader` (the deliverable)
  - `SocialScreen` (demo wrapper, optional reference for surrounding
    page context — feel free to ignore)
  - `PhoneChrome` (status-bar wrapper — only for the demo, not part of
    the deliverable)

Open the reference file alongside this README; numerical values map
one-to-one.
