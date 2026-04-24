# Handoff: Forgetrack RPG

## Overview
Forgetrack is a Czech-language health-tracking mobile app with an RPG/gamification layer. Users log steps, calories, weight, and sleep; the app rewards consistency with XP, quests, achievements, levels, and social features (friends, leaderboard, activity feed). This handoff covers the full four-screen mobile UI: **Přehled (Overview)**, **Questy (Quests)**, **Hero**, and **Social**.

## About the Design Files
The files in this bundle are **design references created in HTML + React (via Babel inline)** — they are prototypes showing the intended look and behavior, not production code to copy directly. The task is to **recreate these designs in the target codebase's existing environment** (the Forgetrack mobile app — presumably React Native, SwiftUI, or native Android/iOS) using its established patterns, component libraries, navigation stack, and design tokens.

If no environment exists yet, **React Native + Expo** is the recommended starting point since the designs are mobile-first and the prototype is already in JSX.

## Fidelity
**High-fidelity (hifi).** All colors, typography, spacing, and interactions are final. The prototype supports both dark and light themes with a live toggle. Implement pixel-perfectly using the codebase's existing libraries.

## Key Design Principles
- **Mobile iPhone 14 Pro frame** — 393 × 852 CSS px logical viewport
- **RPG visual language** — Press Start 2P pixel font for level labels, emoji icons (👟🔥🌙⚖️⚡✨🛡️), sparkle decorations, gold XP bars, colored domain cards
- **Unified sticky headers** — every screen uses the same `UnifiedHeader` pattern: supra-label (uppercase, purple) + bold title + right-aligned action(s), including a theme toggle (☀️/🌙)
- **Domain-coded colors** — each health metric has its own color family used consistently across cards, icons, and progress bars
- **Dark-first theme** with light parchment-inspired alternative

## Screens / Views

### 1. Přehled (Overview / Dashboard) — `DashboardScreen`
- **Purpose**: Daily snapshot + entry point to all metrics
- **Layout** (top to bottom):
  - Sticky header ("Dnes, Tomáš" / "Přehled" / shield icon + theme toggle)
  - Sticky `ExpandableHeroCard`:
    - Collapsed: Level badge (20) + "LEVEL 20 · IRON WARDEN" label + gold XP progress bar + `5 675 / 9 125 XP` + two stat pills (⚡ 26 Aktivita / 🛡 25 Úspěchy) + chevron-down toggle
    - Expanded: adds 4-up mini stat row (Celkem XP / Do dalšího / Úspěchy / Questy) + active quest preview
  - `RangeDateRow` — tab switcher (Den / Týden / Měsíc) + date navigation (‹ Pá 24. dubna ›) + "Synced 23:20"
  - Scrollable `MetricCard` list (Kroky, Kalorie dnes, Váha, Spánek)
- **MetricCard structure**:
  - Rounded 16px card with domain-colored gradient bg + 1px border + glow shadow
  - 2px horizontal shimmer line at top (gradient fade)
  - Row 1: 44px emoji icon box + metric name + `%` badge + `🔒 XP` badge + `›` chevron
  - Row 2: Large value (40px, 900 weight, domain color) + small unit suffix
  - Row 3: Uppercase bottom label, right-aligned (KROKY / PŘIJATO / AKTUÁLNÍ / POSLEDNÍ)
  - 3px progress bar flush to bottom edge

### 2. Questy (Quests) — `QuestsScreen`
- **Purpose**: Browse daily/weekly challenges and claim rewards
- **Layout**:
  - Sticky header ("Questy" / "Tvoje questy")
  - Global gold XP strip (`LevelStrip` — LV20 label + gold progress bar)
  - Horizontal filter pills (Vše / Aktivní / Dokončené / Uzamčené)
  - Quest cards grouped by type (Denní / Týdenní)
- **Quest card**: icon box + quest name + description + progress bar + XP reward badge + state (active/claimable/locked)

### 3. Hero — `HeroScreen`
- **Purpose**: Hero profile, stats detail, achievements showcase
- **Layout**:
  - Sticky header ("Hero profil" / "Tvoje hero cesta" / settings gear)
  - `HeroInfoCard` detailed view: large avatar (with 📷 pencil badge opening photo sheet), name "Tomáš", handle, LV20 gold XP bar with full label
  - Stats 2×2 grid (Celkem XP / Série / Úspěchy / Questy)
  - Achievements grid — locked cards grayed out, unlocked cards use domain color
- **Photo upload sheet**: slides up from bottom with Fotoaparát / Galerie / Odebrat fotku options

### 4. Social — `SocialScreen`
- **Purpose**: Friends, leaderboard, activity feed
- **Layout**:
  - Sticky header ("Social" / "Přátelé & výzvy")
  - Tab row: **Feed** (default) · **Přátelé** (with red request-count badge) · **Žebříček**
  - **Feed tab**: chronological list of friend activities (level-ups, quest completions, achievements)
  - **Přátelé tab**: collapsible "Žádosti o přátelství" section, search input, "Online" section, "Všichni přátelé" section
  - **Žebříček tab**: podium top-3 (visually raised, gold/silver/bronze) + flat ranked list with user highlighted

## Interactions & Behavior
- **Tab navigation**: bottom tab bar with 4 tabs (Přehled / Questy / Hero / Social), persists selection in `localStorage` (`rpg_screen`)
- **Theme toggle**: ☀️/🌙 button in every header, persists to `localStorage` (`rpg_dark`), instantly swaps all tokens
- **Hero card expand**: click anywhere on collapsed row → toggles expanded view with slide animation
- **Range tabs** (Den/Týden/Měsíc): `React.useState`, no data wiring in prototype
- **Photo sheet**: click pencil badge on avatar → full-width bottom sheet slides up, tap backdrop to dismiss
- **Animations**:
  - `rpg-card-in` — 0.3s ease card entry (fade + slide up)
  - `rpg-spark` — 2.4s sparkle pulse (scale + opacity)
  - Level badge pulse — gold glow breathing
  - XP progress bar — 0.6s cubic-bezier(.4,0,.2,1) width transition on value change

## State Management
Local React state only in prototype. For production:
- **User profile**: level, XP, title, avatar, streak
- **Daily metrics**: steps, calories, weight, sleep — each with value + XP reward + progress %
- **Quests**: id, domain, name, description, progress, reward XP, state (locked/active/claimable/completed)
- **Achievements**: id, name, domain, unlock condition, unlocked boolean
- **Social**: friends list, pending requests, leaderboard rankings, feed events
- **Preferences**: theme (dark/light), selected screen — persist locally

## Design Tokens

### Dark theme (`DARK_T`)
| Token | Value |
|---|---|
| `bg` | `#0D0F1C` |
| `bgDeep` | `#080A14` |
| `surface` | `rgba(255,255,255,0.04)` |
| `surfaceMid` | `rgba(255,255,255,0.07)` |
| `border` | `rgba(255,255,255,0.08)` |
| `borderBright` | `rgba(255,255,255,0.14)` |
| `accent` | `#7C6FFF` |
| `accentDim` | `rgba(124,111,255,0.18)` |
| `accentGlow` | `rgba(124,111,255,0.4)` |
| `gold` | `#FBBF24` |
| `goldDim` | `rgba(251,191,36,0.18)` |
| `goldGlow` | `rgba(251,191,36,0.28)` |
| `orange` | `#F97316` |
| `red` | `#EF4444` |
| `emerald` | `#10B981` |
| `t1` (primary text) | `rgba(255,255,255,0.95)` |
| `t2` | `rgba(255,255,255,0.65)` |
| `t3` | `rgba(255,255,255,0.38)` |
| `t4` | `rgba(255,255,255,0.2)` |

### Light theme (`LIGHT_T`)
| Token | Value |
|---|---|
| `bg` | `#F4EFE6` (warm parchment) |
| `bgDeep` | `#EAE3D6` |
| `surface` | `rgba(0,0,0,0.04)` |
| `surfaceMid` | `rgba(0,0,0,0.07)` |
| `border` | `rgba(0,0,0,0.1)` |
| `borderBright` | `rgba(0,0,0,0.18)` |
| `accent` | `#6B5CE7` |
| `accentDim` | `rgba(107,92,231,0.14)` |
| `accentGlow` | `rgba(107,92,231,0.28)` |
| `gold` | `#F59E0B` (light orange — matches daylight feel) |
| `goldDim` | `rgba(245,158,11,0.16)` |
| `goldGlow` | `rgba(245,158,11,0.3)` |
| `orange` | `#C2560A` |
| `red` | `#DC2626` |
| `emerald` | `#059669` |
| `t1` | `rgba(14,10,36,0.92)` |
| `t2` | `rgba(14,10,36,0.62)` |
| `t3` | `rgba(14,10,36,0.4)` |
| `t4` | `rgba(14,10,36,0.22)` |

### Domain colors

Each health metric has its own color family. Dark values are vivid on dark bg; light values are darker/more saturated for contrast on the parchment bg.

| Domain | Emoji | Dark color | Light color |
|---|---|---|---|
| steps | 👟 | `#34D399` | `#059669` |
| calories | 🔥 | `#FBBF24` | `#B45309` |
| sleep | 🌙 | `#A89BFF` | `#6D28D9` |
| weight | ⚖️ | `#60A5FA` | `#1D4ED8` |
| activity | ⚡ | `#2DD4BF` | `#0F766E` |
| xp | ✨ | `#7C6FFF` | `#6B5CE7` |
| protein | 🥩 | `#F472B6` | `#BE185D` |

Each domain has a `bg` gradient (dark: saturated dark tint e.g. `linear-gradient(135deg,#0d2e22,#0a1a15)`; light: subtle pastel e.g. `linear-gradient(135deg,#e6faf4,#f0fdf9)`), plus `dim`/`rich`/`glow` opacity variants. See `rpg-ui.jsx` for full `DARK_DOM` and `LIGHT_DOM` objects.

### Typography
- **Body**: `Inter, sans-serif` (antialiased)
- **Pixel accent**: `Press Start 2P, monospace` — used for `LV20 · IRON WARDEN` labels, section headers, and any RPG-flavored mono strings
- **Scale** (inline values in prototype — codify these into a scale in production):
  - 40px / 900 — metric values
  - 16px / 800 — screen titles
  - 14–15px / 700 — card names
  - 11px / 700 uppercase — supra labels, badges
  - 10px / 700 uppercase — section heads
  - 9px / 500 — helper text
  - 7–8px Press Start 2P — pixel level labels
- Letter-spacing: `-0.04em` on large values, `.06–.1em` on uppercase labels

### Spacing & radius
- Card radius: **16–18px**
- Pill/badge radius: **8–9px**
- Card padding: `12px 14px 10px`
- Gap between cards: **10px**
- Screen horizontal padding: **12px**

### Shadows
- Card glow: `0 4px 20px ${domainColor}40` (dark) / `${domainColor}25` (light)
- Hero card: `0 4px 24px ${T.accentGlow}`
- No shadow on buttons/pills — rely on borders

## Assets
- **Emoji** — system emoji, no custom assets needed
- **SVG icons** — small inline (chevrons, shield, sparkle stars) — all defined inline in `rpg-ui.jsx` / `rpg-assets.jsx`
- **Avatar placeholder** — initials on colored gradient circle (see `AvatarPlaceholder` component)
- **Fonts** — `Press Start 2P` and `Inter` should be loaded from Google Fonts or bundled locally

## Files Included
- `Forgetrack RPG.html` — entry HTML, loads React + Babel + scripts
- `rpg-ui.jsx` — main UI file with all screens, components, and theme tokens (DARK_T, LIGHT_T, DARK_DOM, LIGHT_DOM)
- `rpg-assets.jsx` — supplementary illustrated SVG assets (may be unused in final version — emoji-first approach took over)
- `ios-frame.jsx` — phone bezel starter component (not needed in production — native devices provide their own chrome)

## Implementation Notes for the Developer
1. **Theme**: Use a single `ThemeProvider` / Context — don't recreate the mutable-global pattern from the prototype. All tokens should flow through context.
2. **Animations**: Use Reanimated (RN), CSS transitions (web), or Core Animation (iOS) — the keyframes in the prototype (`rpg-card-in`, `rpg-spark`) are documented inline in the `<style>` tag at the top of `Forgetrack RPG.html`.
3. **Persistence**: Replace `localStorage` with AsyncStorage (RN) / UserDefaults (iOS) / SharedPreferences (Android) for theme + last-opened screen.
4. **Czech strings**: All copy is in Czech (cs). Make sure i18n pipeline preserves accented characters (áéíóúčďěňřšťůýž).
5. **Accessibility**: All interactive elements need hit targets ≥ 44px. The theme toggle, chevrons, and photo badge are currently 28–32px — bump up in production.
6. **Gestures**: The prototype uses click-only. In production, add swipe-back on photo sheet and pull-to-refresh on overview.
