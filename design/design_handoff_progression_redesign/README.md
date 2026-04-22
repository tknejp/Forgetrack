# Handoff: Forgetrack — Progression UI Redesign

## Overview

This package covers a redesign of two surfaces in the Forgetrack app:

1. **Home Screen Progression Card** — A collapsible card on the Dashboard/Overview screen showing the player's current level, XP, and progression highlights. Has a compact state (always visible) and an expanded state (tap to reveal).
2. **Progression Profile Screen** — A full dedicated screen for the player's long-term progression journey: level, XP, streaks, quests, achievements, and recent reward history.

The redesign focuses on visual hierarchy, premium RPG feel, and clear information architecture — not architectural changes to the app.

---

## About the Design Files

Files in this bundle are **HTML design references** — interactive prototypes built to show look, feel, and behavior. Do not ship the HTML directly. Recreate these designs in the Forgetrack mobile codebase (React Native, Swift, Kotlin, etc.) using its established patterns. Open `Progression UI Redesign.html` in a browser to interact with both surfaces side by side.

---

## Fidelity

**High-fidelity.** Colors, spacing, border radii, gradients, typography, animations, and card hierarchy are all final and should be implemented as shown. Glow effects and sparkles should be tied to a reduced-motion / battery-saver preference and can be toggled off.

---

## Design Tokens

### Colors
```
Background:           #0D0F1C
Surface card:         rgba(255,255,255,0.03)
Border default:       rgba(255,255,255,0.07)
Border subtle:        rgba(255,255,255,0.04)

Accent / Level:       #7C6FFF
Accent dim:           rgba(124,111,255,0.18)
Accent glow:          rgba(124,111,255,0.35)
Violet light:         #A89BFF   ← used for +XP reward labels

Teal (activity/streak):  #2DD4BF  /  dim: rgba(45,212,191,0.18)  /  glow: rgba(45,212,191,0.25)
Amber (steps/best):      #FBBF24  /  dim: rgba(251,191,36,0.18)  /  glow: rgba(251,191,36,0.25)
Green (quests):          #34D399  /  dim: rgba(52,211,153,0.18)  /  glow: rgba(52,211,153,0.25)

Text primary:         rgba(255,255,255,0.95)
Text secondary:       rgba(255,255,255,0.60)
Text tertiary:        rgba(255,255,255,0.35)
Text muted:           rgba(255,255,255,0.20)
```

### Domain Color Map
| Domain | Color | Dim | Glow | Label |
|---|---|---|---|---|
| steps | `#34D399` | `rgba(52,211,153,0.18)` | `rgba(52,211,153,0.25)` | Kroky |
| nutrition | `#FBBF24` | `rgba(251,191,36,0.18)` | `rgba(251,191,36,0.25)` | Výživa |
| sleep | `#A89BFF` | `rgba(168,155,255,0.18)` | `rgba(168,155,255,0.25)` | Spánek |
| activity | `#2DD4BF` | `rgba(45,212,191,0.18)` | `rgba(45,212,191,0.25)` | Aktivita |
| xp / level | `#7C6FFF` | `rgba(124,111,255,0.18)` | `rgba(124,111,255,0.35)` | XP |

### Typography (Inter)
| Role | Size | Weight | Notes |
|---|---|---|---|
| Screen large title | 18–22px | 800 | letter-spacing: -0.03em |
| Screen label / nav label | 10px | 700 | uppercase, letter-spacing: 0.10em, accent color |
| Card title | 13–14px | 700–800 | letter-spacing: -0.01em |
| Section header label | 11px | 700 | uppercase, letter-spacing: 0.10em |
| Big stat number | 24–30px | 900 | letter-spacing: -0.04em, tabular-nums |
| Level orb | 14–22px | 900 | — |
| Highlight pill value | 16px | 900 | — |
| Mini stat grid value | 18px | 900 | letter-spacing: -0.03em |
| Badge | 10px | 700 | border-radius: 99px |
| Body / desc | 11px | 500 | color: text-tertiary |
| Timestamp / meta | 9–10px | 500 | color: text-muted |

### Spacing & Radii
```
Screen horizontal padding:    14–16px
Section gap:                  16px
Card inner padding:           13–16px
Card gap within section:      6–8px
Row inner padding:            10–11px vertical, 12–13px horizontal

Border radius — screen cards:        18px
Border radius — quest/achiev cards:  14px
Border radius — summary cells:       16px
Border radius — mini stat cells:     12px
Border radius — icon squares:        ~30% of size
Border radius — pills / badges:      99px
Border radius — progress bars:       99px
```

### Shadows / Glow
```
Home card container:        0 4px 24px rgba(124,111,255,0.18)
Hero card (profile):        0 4px 28px rgba(124,111,255,0.22)
Active quest cards:         0 3px 16px {domain.glow}
Unlocked achievement cards: 0 3px 16px {domain.glow}
Streak duel cards:          0 3px 14px {domain.glow}
Level orb CTA button:       0 4px 18px rgba(124,111,255,0.35)
Level orb pulse (animated): 0 0 14px → 0 0 26px rgba(124,111,255,0.4–0.65)
```

### Animations
| Name | Description | Values |
|---|---|---|
| `card-in` | Cards enter on mount | `opacity 0→1, translateY 10→0px`, `0.32–0.35s ease`. Stagger `0.05–0.06s` per card |
| `expand-in` | Elements inside expanded card | `opacity 0→1, translateY -6→0px`, `0.28s ease`. Stagger `0.04s` |
| `spark` | Ambient sparkle dots | `opacity 0.5↔1, scale 1↔1.35`, `2.4s ease-in-out infinite` |
| `badge-pop` | Unlocked achievement badge | `scale 0.75→1.08→1`, `0.4s ease` |
| `glow-pulse` | Level orb box-shadow breathe | `0 0 14px → 0 0 26px`, `3s ease-in-out infinite` |
| Progress bar fill | Width transition | `0.6s cubic-bezier(0.4, 0, 0.2, 1)` |
| Chevron rotate | Expand/collapse indicator | `transform: rotate(0 ↔ 180deg)`, `0.2s ease` |

---

## Surface 1: Home Screen Progression Card

### Placement
Lives on the Overview/Dashboard screen, between the date navigation and the domain stat cards (Steps, Calories, etc.). This is a card within a scrollable feed — not a fixed header.

### Compact State (always visible)

**Container:**
- `border-radius: 18px`
- `background: linear-gradient(145deg, rgba(124,111,255,0.14), rgba(124,111,255,0.04))`
- `border: 1px solid rgba(124,111,255,0.165)`
- `box-shadow: 0 4px 24px rgba(124,111,255,0.18), 0 1px 0 rgba(255,255,255,0.05) inset`
- `padding: 14px`
- Entire card is tappable to expand/collapse

**Level Orb + XP Bar row (flex, gap 10px):**

1. **Level Orb** — `36×36px, border-radius: 11px`
   - `background: linear-gradient(135deg, #7C6FFF, rgba(124,111,255,0.53))`
   - `border: 1.5px solid rgba(124,111,255,0.4)`
   - `box-shadow: 0 0 14px rgba(124,111,255,0.35)` (glow on)
   - `animation: glow-pulse 3s ease-in-out infinite` (glow on)
   - Content: level number, `font-size: 14px, font-weight: 900, color: #fff`

2. **XP bar column** (flex: 1):
   - Top row: label left `"LEVEL 16 · FORGE KNIGHT"` in `#7C6FFF, font-size: 10px, font-weight: 700, uppercase, letter-spacing: 0.07em`; value right `"120 / 250 XP"` in text-tertiary
   - Progress bar: `height: 5px`

**Highlight Pills row (flex, gap 6px) — visible in compact state only:**

Left pill — Streak:
- `background: rgba(45,212,191,0.18), border: 1px solid rgba(45,212,191,0.2), border-radius: 99px, padding: 4px 10px 4px 7px`
- Star icon `12×12px` in `#2DD4BF` + value `font-size: 11px, font-weight: 700, color: #2DD4BF` + domain label `font-size: 10px, color: rgba(45,212,191,0.6)`

Right pill — Achievements:
- Same structure, color `#7C6FFF`, bg `rgba(124,111,255,0.18)`
- Target icon + value + `"úspěchů"` label

**Chevron button** (expand/collapse):
- `position: absolute, top: 14px, right: 14px`
- `28×28px, border-radius: 8px, background: rgba(255,255,255,0.07)`
- SVG chevron rotates `0 ↔ 180deg` on state change, `0.2s ease`

**Ambient sparkles** (glow on): 3 dots, positions `(90%, 8%), (4%, 75%), (88%, 85%)`, animated with `spark`

---

### Expanded State

Revealed below the compact section via a border-top separator. All inner elements use `expand-in` animation with stagger.

**4-column mini stat grid (flex, gap 6px):**

Each mini stat cell — `flex: 1, border-radius: 12px, padding: 11px 10px`:
- `background: rgba(255,255,255,0.04), border: 1px solid rgba(255,255,255,0.07)`
- Icon SVG `16×16px` at top
- Value: `font-size: 18px, font-weight: 900, letter-spacing: -0.03em, tabular-nums`
- Label: `font-size: 9px, font-weight: 600, color: text-muted, uppercase, letter-spacing: 0.07em`

| Cell | Color | Value | Label |
|---|---|---|---|
| Celkem XP | `#7C6FFF` | `3,87` + `"tis."` unit | CELKEM XP |
| Do dalšího | `#A89BFF` | `130` + `"XP"` unit | DO DALŠÍHO |
| Úspěchy | `#7C6FFF` | `5` | ÚSPĚCHY |
| Questy | `#34D399` | `6` | QUESTY |

**Streak Duel (flex, gap 8px, 2 equal cards):**

Left — Aktuální série:
- `flex: 1, border-radius: 12px, padding: 11px 12px`
- `background: linear-gradient(135deg, rgba(45,212,191,0.18), transparent)`
- `border: 1px solid rgba(45,212,191,0.165), box-shadow: 0 2px 14px rgba(45,212,191,0.25)`
- Domain icon `24×24px` + label `"AKTUÁLNÍ SÉRIE"` in `#2DD4BF, 9px, 700, uppercase`
- Value: `font-size: 24px, font-weight: 900, color: #2DD4BF` + `"dní"` suffix
- Sub-label: domain name, `9px, rgba(45,212,191,0.42), uppercase`

Right — Nejlepší série:
- Same structure, color `#FBBF24`, dim `rgba(251,191,36,0.18)`, glow `rgba(251,191,36,0.25)`

**Active Quests Preview:**
- Container: `border-radius: 12px, background: rgba(0,0,0,0.2), border: 1px solid rgba(255,255,255,0.05), padding: 4px 10px 2px`
- Sub-label `"AKTIVNÍ QUESTY"`: `9px, font-weight: 700, text-muted, uppercase`
- Each quest row (flex, gap 9px, padding 8px 0, border-bottom between rows):
  - Domain icon `26×26px`
  - Title: `12px, font-weight: 700, color: text-primary, overflow: ellipsis`
  - Progress bar: `height: 3px` (thinner than normal — compact context)
  - Percentage right: `10px, font-weight: 700, domain.color`

**CTA Button — "Otevřít progression profil →":**
- `width: 100%, height: 42px, border-radius: 12px`
- `background: linear-gradient(135deg, rgba(124,111,255,0.8), rgba(124,111,255,0.53))`
- `box-shadow: 0 4px 18px rgba(124,111,255,0.35)` (glow on)
- `font-size: 13px, font-weight: 700, color: #fff`
- Arrow icon right `14×14px`

---

### State Variants — Home Card

| State | Description |
|---|---|
| **Compact** | Level orb + XP bar + highlight pills. Chevron down. |
| **Expanded** | Compact row (pills hidden) + separator + stat grid + streak duel + quest preview + CTA. Chevron up. |
| **Loading / skeleton** | Skeleton shimmer replacing orb (`36×36`), XP bar (`100% × 5px`), two pills (`40% × 24px each`). Use background `linear-gradient(90deg, rgba(255,255,255,0.04) 25%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.04) 75%)`, `background-size: 200%`, animated with `shimmer 1.6s ease-in-out infinite`. |
| **No active quests** | Quest preview section hidden in expanded state. Quest count stat cell shows `0`. |

---

## Surface 2: Progression Profile Screen

Full-screen scrollable view. Navigation: back chevron + `"PROGRESSION PROFIL"` label + `"Tvá dlouhodobá cesta"` large title.

**Section order (top → bottom):**
1. Hero Card
2. Přehled postupu (Summary Grid)
3. Série (Streak Highlights)
4. Questy (Active → Completed)
5. Úspěchy (Unlocked → In Progress)
6. Nedávné odměny (History Feed)

---

### A · Hero Card

See previous handoff (`design_handoff_progression_profile/README.md`) — unchanged from v1. Key values:
- Level orb: `52×52px, border-radius: 16px`, glow-pulse animation
- XP bar container: `background: rgba(0,0,0,0.22), border-radius: 12px, padding: 8px 11px`
- Highlight pills: teal (streak) + violet (achievements)
- Last sync: `font-size: 10px, color: text-muted, text-align: center`

---

### B · Summary Grid

Same as v1 — 2×2 grid, `border-radius: 16px` cells, `background: rgba(255,255,255,0.03)`.

| Cell | Color | Value |
|---|---|---|
| Aktuální série | `#2DD4BF` | 5 dní |
| Nejlepší série | `#FBBF24` | 12 dní |
| Dokončené questy | `#34D399` | 6 |
| Úspěchy | `#7C6FFF` | 5 |

---

### C · Streak Highlights (NEW section — added in this redesign)

**Section header:** `"SÉRIE"`, sub: `"Aktuální a nejlepší série napříč doménami"`

Two side-by-side duel cards (same pattern as home expanded state but larger):
- Value: `font-size: 30px, font-weight: 900`
- Domain icon: `26×26px`
- Sub-label: domain name, `9px, color: {domain.color}42`

This section sits between Summary and Quests to give streaks their own dedicated moment — they were previously buried in the summary grid.

---

### D · Quests Section

Unchanged from v1. Two sub-containers:

**Active Quests container** (`background: rgba(0,0,0,0.2)`):
- Active Quest Card: gradient bg + domain color border + glow + `"Aktivní"` badge + `5px` progress bar + `current / target` footer
- Empty state: centered card with `"Žádné aktivní questy."` / `"Prošel jsi aktuální katalog questů."`

**Completed Quests container** (`background: rgba(0,0,0,0.15)` — visually quieter):
- Compact row: domain icon + title (muted) + source label (domain color) + timestamp + `"Hotovo"` badge
- Collapsed to first 3 by default; `"Zobrazit vše (N) →"` button expands

---

### E · Achievements Section

Unchanged from v1. Two sub-containers:

**Unlocked** (`rgba(0,0,0,0.2)`): full-color gradient cards + sparkles + `"Odemčeno"` badge + `4px` progress bar
**In Progress** (`rgba(0,0,0,0.15)`): muted cards + percentage label + `4px` progress bar + `"zbývá N"` note

---

### F · History Feed

Unchanged from v1. Compact list rows:
- Domain icon `30×32px` + title + domain label + `"+N XP"` in `#A89BFF` + timestamp
- Separator: `1px solid rgba(255,255,255,0.05)` between rows
- No outer padding on container — rows flush to border

---

## Reusable Components

| Component | Description |
|---|---|
| `ProgressionCard` | Home card with compact/expanded state. Props: `expanded: bool`, `onOpen: () => void`, `tweaks: Tweaks` |
| `CardCompact` | Always-visible XP bar row inside progression card |
| `CardHighlights` | Streak + achievement pills (compact state only) |
| `CardExpanded` | Stat grid + streak duel + quest preview + CTA |
| `MiniStat` | Single cell in the 4-column stat grid |
| `StreakDuel` | Side-by-side streak cards (used in both card and profile) |
| `MiniQuestRow` | Compact quest row in home card (3px bar) |
| `HeroCard` | Profile screen hero with orb, XP bar, pills |
| `SummaryGrid` | 2×2 stat summary |
| `StreakSection` | Profile streak duel (larger, full-width) |
| `ActiveQCard` | Full quest card with gradient bg, 5px bar |
| `CompQRow` | Compact completed quest row |
| `UnlockedACard` | Unlocked achievement card with sparkles |
| `InProgressACard` | In-progress achievement card, muted |
| `HistoryRow` | Single reward row in history feed |
| `DomIco` | Domain icon square — takes `domain` enum, renders colored SVG icon |
| `PBar` | Progress bar — props: `value (0-1), color, glow, h` |
| `SectionHead` | Star icon + uppercase label + optional sub-label |

---

## Interactions & Behavior

- **Home card expand/collapse:** Tap anywhere on card body or the chevron button to toggle. Use `height` animation or `LayoutAnimation` (RN). Chevron SVG rotates `0 ↔ 180deg` with `0.2s ease`.
- **"Zobrazit vše" (Show all):** Expands completed quests list from 3 to all. One-way — no collapse needed in this iteration.
- **CTA button → profile:** Navigates to Progression Profile screen via standard stack navigator push.
- **Back navigation:** Chevron pops back to previous screen.
- **Scroll:** Single scroll column on profile; no inner scroll regions.
- **Glow / sparkles:** Both should respect `prefers-reduced-motion` / app-level battery saver setting.

---

## Empty & Loading States

| Surface | State | Treatment |
|---|---|---|
| Home card | Loading | Skeleton shimmer: orb + XP bar + pills |
| Home card expanded | No active quests | Quest preview section hidden; quests stat cell shows `0` |
| Profile active quests | Empty | Placeholder card: `"Žádné aktivní questy."` |
| Profile in-progress achievements | Empty | `"Vše v aktuálním katalogu je odemčeno."` |
| Profile history | Empty | `"Zatím žádné odměny."` with muted sub-text |
| Profile (new user) | Sparse | Level 1, XP bar at ~0, only first quest visible, achievements all locked |

---

## What Changed vs. Previous Design

| Surface | Before | After |
|---|---|---|
| Home card compact | XP bar only, no highlight | Level orb + XP bar + streak + achievements pills |
| Home card expanded | Scattered data boxes, plain text rows | 2×2 stat grid → streak duel → quest preview → CTA |
| Profile streaks | Buried in summary grid | Own dedicated section between summary and quests |
| Profile hero | Identical to v1 | Minor refinement (spacing, ambient shimmer) |

---

## Files in This Bundle

| File | Purpose |
|---|---|
| `Progression UI Redesign.html` | **Main reference.** Both surfaces side by side, interactive. Open in browser. |
| `ft-tokens.jsx` | Color tokens and domain definitions |
| `ft-components.jsx` | Shared Forgetrack UI components |
| `ios-frame.jsx` | iOS frame (prototype only — not needed in production) |

---

## Notes for Implementation

1. The `DomIco` component (domain icon square) is the building block of the entire card language — pass a `domain` enum and derive all colors from the token map.
2. The streak duel pattern (two equal side-by-side cards) appears in both the home card expanded state and the profile streak section — implement it as one reusable component.
3. Progress bars are `3px` (home card quest preview), `4px` (achievements), or `5px` (quests, hero XP bar) — keep these distinct to reinforce hierarchy.
4. All glow effects are `box-shadow` — straightforward in React Native via `shadow*` props or `elevation` on Android (though Android glow is limited; test carefully).
5. Sparkle dots are absolutely positioned SVG stars with opacity animation — can be simplified to a subtle particle effect on native, or omitted for reduced-motion users.
