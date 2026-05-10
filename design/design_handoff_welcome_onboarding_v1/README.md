# Handoff: Forgetrack — Welcome / Onboarding (Variant 1: Multi-step Quest)

## Overview
This is the **Welcome / Onboarding flow** for Forgetrack, a gamified health-tracking app. It replaces the existing single-page settings-dump welcome screen with a friendlier, fokusovaný 4-step flow that introduces the gamification (XP, levels, quests) up front and defers heavy auth work (KT login) into a bottom sheet.

The flow:
1. **Vítej** — character/sigil intro + "your start" preview card
2. **Účet** — optional Google sign-in for cloud sync
3. **Zdraví** — Health Connect permission grant
4. **Hotovo** — KT integration + notifications + first-quests preview

A user can **skip** to the final step at any time. Every integration is optional and changeable later in Settings.

## About the Design Files
The files in `design_files/` are **design references created in HTML/JSX** — a click-prototype showing intended look and behavior, not production code to copy directly. The current implementation uses inline `style={…}` props purely so the prototype renders standalone in a browser; production code should use the target codebase's existing styling solution (Theme/ThemeData in Flutter, styled-components, Tailwind, etc.). The task is to **recreate this design in the target Forgetrack app environment (Flutter)** using its established widgets and patterns.

## Fidelity
**High-fidelity.** Colors, type, spacing, radii, animation timings, and copy are final. Recreate pixel-perfectly.

The only intentional placeholders:
- **Sigil illustration** in step 1 — current SVG is a geometric crystal as a stand-in. Final art will be commissioned; replace with `SvgPicture.asset('assets/sigil_hero.svg')` once delivered.
- **Class/data emoji** in step 3 (👣🔥😴⚔️) and toggle row icons (🔔, 🎯) are placeholders for branded SVG icons — keep emoji until the icon set lands.

## Screens / Views

### Container: `WelcomeScreen`
Full-screen, dark background. Background uses two stacked radial gradients on top of `#0B0F1E`:
- Top: `radial-gradient(ellipse 80% 50% at 50% 0%, rgba(139,92,246,0.20), transparent 60%)`
- Bottom: `radial-gradient(ellipse 60% 30% at 50% 100%, rgba(63,184,175,0.10), transparent 60%)`

Layout (vertical flex):
1. Status bar gap (54px on iOS, OS-managed on Android)
2. **Header strip** (54px tall, padding 14px 20px 8px): progress dots on the left, "Přeskočit" text button on the right (hidden on step 4)
3. **Body** (flex:1, scroll-enabled, padding 8px 20px 12px) — switches between the four step components
4. **Footer** (padding 12px 20px 28px): optional 56×52 back button (`<` chevron), then primary CTA (flex:1, 52px tall)

### Step 1 — `StepWelcome`
- **Sigil cluster**, 124×124px, centered, margin top 8 / bottom 18:
  - 100% radial-gradient glow halo (`rgba(139,92,246,0.5) → transparent`, blur 8px) on outer ring
  - Inner 100×100 circle with `linear-gradient(135deg, #1A1838, #0F1226)` background, 1px `rgba(167,139,250,0.35)` border, drop-shadow `0 12px 32px -8px rgba(139,92,246,0.55)` and inset glow `inset 0 0 30px rgba(139,92,246,0.15)`
  - Inside: 56×64 crystal SVG with linear gradient `#C4B5FD → #7C3AED`, stroke `#EDE9FE` 1.5px
  - 4 tiny gold sparks (★ glyph, 6–9px, color `#F4C152`) positioned absolutely around the halo, animated `wm-spark` 2.4s ease-in-out infinite with staggered delays (0, 0.3, 0.6, 1.2s) — opacity 0 → 1, scale 0.4 → 1
- **Title**: "Vítej, hrdino." — 28px / 800 / -0.03em / line-height 1.15 / center / `#F5F3FF`
- **Subtitle**: "Forgetrack udělá ze tvého zdraví **cestu plnou questů** — kroky, spánek a jídlo se mění v XP, levely a tituly." — 15px / 400 / line-height 1.45 / center / `rgba(245,243,255,0.55)`. Bold span colored `#A78BFA`, font-weight 600.
- **"Tvůj start" card** (margin-top 22, padding 14, radius 18, background `linear-gradient(135deg, rgba(40,38,76,0.55), rgba(22,22,46,0.85))`, border 1px `rgba(148,130,220,0.22)`):
  - Section label: "✦ TVŮJ START" — 10px / 800 / 0.14em / `#A78BFA`
  - Row (margin-top 10, gap 12):
    - 44×44 level badge, radius 12, `linear-gradient(135deg, #8B5CF6, #7C3AED)`, drop-shadow `0 4px 14px -2px rgba(139,92,246,0.55)`, white "1" centered, 16px / 800
    - Middle column (flex:1): "NOVÁČEK" 11px / 700 / 0.06em / `#F4C152`, then "0 / 500 XP do dalšího levelu" 13px / `rgba(245,243,255,0.6)`
    - Pill: "+50 XP" — 10px / 800 / 0.06em / `#F4C152`, padding 4px 10px, radius 999, background `rgba(244,193,82,0.15)`, border 1px `rgba(244,193,82,0.35)`

### Step 2 — `StepAccount`
- `StepIcon`: 72×72, radius 22, gradient `${tint}33 → ${tint}11` (tint = `#A78BFA`), 1px `${tint}44` border, drop-shadow `0 8px 24px -8px ${tint}66`. Centered emoji: 🛡️ 32px.
- `StepHeading`: title "Ulož si svůj postup" (24px/800/-0.02em), subtitle "Přihlas se přes Google a tvé levely, série a achievementy zůstanou bezpečně v cloudu — i když přejdeš na nový telefon." (14px / `rgba(245,243,255,0.55)` / line-height 1.5)
- **Google sign-in button**: full width, padding 16px, radius 16, white background, drop-shadow `0 4px 18px rgba(0,0,0,0.25)`, label "Přihlásit se přes Google" 15px / 600 / `#1F1F1F`, with 20×20 Google "G" SVG (4-color logo) at left.
- **Bullet list card** (margin-top 18, padding 12px 14px, radius 14, background `rgba(167,139,250,0.06)`, border 1px `rgba(167,139,250,0.16)`):
  - Three rows with green checkmark in 18×18 circle (`rgba(52,211,153,0.18)` bg, `rgba(52,211,153,0.35)` border, `#34D399` ✓), gap 10, padding 6px 0:
    - "Synchronizace mezi tvými zařízeními"
    - "Zálohovaný postup a achievementy"
    - "Funguje i offline"
  - 13px / `rgba(245,243,255,0.75)` text
- **Footnote** (margin-top 14, center): "Nemusíš se rozhodovat hned — funguje to i bez účtu." 12px / `rgba(245,243,255,0.4)`

### Step 3 — `StepHealth`
- `StepIcon` ❤️ tint `#3FB8AF`
- `StepHeading`: "Připoj svoje data" / "Forgetrack čte z Health Connectu kroky, spánek a aktivitu — a proměňuje je v XP. Tvoje záznamy z toho ven nejdou; jen se z nich čte."
- **Data icon grid**: 4 columns, gap 8, margin-top 22. Each cell padding 10px 6px, radius 14, background `rgba(28,30,56,0.45)`, border 1px `${color}33`, center-aligned. Emoji 22px, label 10px / 600 / `rgba(245,243,255,0.7)`:
  - 👣 Kroky `#34D399`
  - 🔥 Kalorie `#FBBF24`
  - 😴 Spánek `#A89BFF`
  - ⚔️ Aktivita `#2DD4BF`
- **Permission button**: "Povolit Health Connect" — full width, padding 14px 16px, radius 16, gradient `linear-gradient(180deg, rgba(63,184,175,0.30), rgba(63,184,175,0.45))`, 1px `rgba(63,184,175,0.55)` border, white 14px / 700, drop-shadow `0 8px 22px -6px rgba(63,184,175,0.45)`.
- **Privacy hint** (margin-top 12, padding 10px 12px, radius 12, background `rgba(167,139,250,0.05)`, border 1px `rgba(167,139,250,0.10)`): shield SVG (14×14, `#A78BFA` stroke) + text "Tvá data zůstávají v Health Connectu — Forgetrack je nikdy nekopíruje ani neupravuje." (11px / `rgba(245,243,255,0.5)` / line-height 1.45).

### Step 4 — `StepFinal`
- `StepIcon` 🎯 tint `#F4C152`
- `StepHeading`: "Poslední doladění" / "Volitelné — všechno můžeš nastavit i později v aplikaci."
- **`ToggleRow` × 2** (margin-top 12 each). See spec below.
  - **Kalorické Tabulky** — icon = `kt-logo.png` (provided), tint `#7BA42B`, subtitle when off "Importovat výživu a váhu z KT deníku", subtitle when on shows the user's email. Tap when off opens **`KTLoginSheet`** (modal bottom sheet); tap when on disconnects.
  - **Notifikace** — icon 🔔 tint `#A78BFA`, defaults ON, free toggle.
- **First-quests summary card** (margin-top 18, padding 14, radius 16, background `linear-gradient(135deg, rgba(244,193,82,0.12), rgba(167,139,250,0.10))`, border 1px `rgba(244,193,82,0.25)`):
  - Header: "✦ PRVNÍ QUESTY" 10px / 800 / 0.14em / `#F4C152`
  - 3 quest rows, gap 10, padding 7px 0, divider `1px rgba(255,255,255,0.06)` between (none on last):
    - 6×6 gold dot (`#F4C152` with `0 0 8px #F4C152` glow)
    - Quest text 13px / `rgba(245,243,255,0.85)`
    - XP pill: 10px / 800 / `#F4C152`, padding 2px 7px, radius 999, background `rgba(244,193,82,0.12)`, border 1px `rgba(244,193,82,0.30)`
  - Quests:
    - "Ujít 10 000 kroků" — `+50 XP`
    - "Spát 7 hodin" — `+30 XP`
    - "Otevřít aplikaci 3 dny v řadě" — `+100 XP`

## Reusable Components

### `ToggleRow`
Full-width tappable row.
- Padding 14px 14px, radius 16
- When **inactive**: background `rgba(28,30,56,0.45)`, border 1px `rgba(148,130,220,0.18)`
- When **active**: background `linear-gradient(135deg, ${tint}22, ${tint}0d)`, border 1px `${tint}66`
- Layout: 38×38 icon container (radius 12, dimmed background `${tint}22` when active else `rgba(255,255,255,0.04)`, border `${tint}55`/`rgba(255,255,255,0.06)`, fontSize 18 if emoji, or hosts an `<img>` with radius 10) → flex:1 text column → iOS-style toggle on the right
- Text: title 14px/700/-0.01em/`#F5F3FF`, subtitle 11px / `rgba(245,243,255,0.5)`
- iOS toggle: 42×24 pill, `tint` color when on (with `0 0 12px ${tint}66` glow) else `rgba(255,255,255,0.10)`. White 20×20 thumb at left:2 / right:20, 0.2s linear transition.

### `KTLoginSheet`
Modal bottom sheet, slides up from bottom. Anchored to absolute parent (the phone frame).
- Backdrop: `rgba(0,0,0,0.55)`, fade-in 0.18s. Tap dismisses.
- Sheet: full width, background `linear-gradient(180deg, #1A1838 0%, #0F1226 100%)`, top radius 24, top border 1px `rgba(167,139,250,0.25)`, padding 14px 20px 28px, slides up 20px / fades 0.6→1 over 0.22s with `cubic-bezier(.2,.7,.3,1)`.
- Drag-handle: 38×4, radius 2, `rgba(255,255,255,0.18)`, centered, margin-bottom 14.
- Header row (gap 12, margin-bottom 16): 44×44 KT logo (radius 12, overflow hidden) + title block ("Kalorické Tabulky" 16/800/`#F5F3FF`, "Přihlas se ke svému KT účtu" 11 / `rgba(245,243,255,0.5)`)
- Email field (`KTField`, type=email, placeholder "E-mail KT")
- 8px gap
- Password field (`KTField`, type=password by default; trailing eye icon toggles visibility)
- "Přihlásit a propojit" button — margin-top 14, full width, 50px tall, radius 14. Disabled until email contains `@` and password length ≥ 4. Active style: `linear-gradient(180deg, #8FBE3D 0%, #6E9527 100%)`, drop-shadow `0 8px 24px -6px rgba(123,164,43,0.55)`. Disabled: `rgba(123,164,43,0.25)`, text `rgba(255,255,255,0.5)`, cursor not-allowed.
- Footnote (margin-top 10, center): "Forgetrack používá tvé přihlášení jen ke čtení deníku z KT." 11px / `rgba(245,243,255,0.4)`

### `KTField`
Text input wrapped in styled container.
- Padding 4px 12px, radius 12, background `rgba(11,15,30,0.6)`
- Border: 1px `rgba(167,139,250,0.18)` default, transitions to `rgba(143,190,61,0.55)` on focus (150ms)
- Input: flex:1, 38px tall, transparent, no border/outline, `#F5F3FF` 14px Inter, placeholder `rgba(245,243,255,0.45)`
- Optional trailing slot (used for password-eye toggle)

### `PrimaryBtn`
Footer CTA. flex:1, 52px tall, radius 16, `linear-gradient(180deg, #8B5CF6 0%, #7C3AED 100%)`, white 15/700, drop-shadow `0 8px 24px -6px rgba(139,92,246,0.65)` + inset `0 1px 0 rgba(255,255,255,0.18)`. Optional leading "✦" wand icon on final step. Optional trailing 14×14 right-arrow on intermediate steps.

### `BackBtn`
Footer. 56×52, radius 16, background `rgba(28,30,56,0.45)`, 1px `rgba(167,139,250,0.22)` border, color `#C7C2E0`, contains `<` chevron 14×14 / 2px stroke.

### Header `ProgressDots`
4 horizontal dots, gap 6:
- Each 4px tall, radius 2
- 22px wide if active, 14px otherwise
- `#A78BFA` if index ≤ current step, `rgba(167,139,250,0.18)` otherwise
- 0.3s linear transition on width and background

## Interactions & Behavior

| Trigger | Result |
|---|---|
| Tap "Začít cestu" / "Pokračovat" | `step++`. On step 4 it should commit onboarding and navigate to Dashboard. |
| Tap back chevron | `step--` (clamped at 0). Hidden on step 0. |
| Tap "Přeskočit" | Jump to step 4. Hidden on step 4. |
| Tap KT row when off | Open `KTLoginSheet` |
| Tap KT row when on | Disconnect (clear stored creds, set `kt = false`) |
| Tap notification toggle | Flip flag. On enable, request OS-level permission. |
| Tap sheet backdrop or drag down | Dismiss sheet without connecting |
| Type into email/password | Live validation; submit button enables when both pass |
| Tap eye icon | Toggle password visibility |
| Tap "Přihlásit a propojit" (enabled) | Call KT auth API, on success: store token, set `kt = true`, set `ktEmail = email`, dismiss sheet |
| Tap "Vstoupit do hry" (step 4 CTA) | Mark `onboarding.completed = true` in persistent storage, navigate to Dashboard. Recommended: trigger a brief confetti burst before navigation. |

### Animations
| Element | Spec |
|---|---|
| Progress dot width / color | 0.3s linear |
| Sigil sparks | `wm-spark`: 2.4s ease-in-out infinite, opacity 0→1, scale 0.4→1, with stagger 0/0.3/0.6/1.2s |
| Toggle row state | 0.2s linear on background and border |
| iOS toggle thumb position | 0.2s linear `left` |
| Sheet backdrop | 0.18s ease-out fade |
| Sheet slide-up | 0.22s cubic-bezier(.2,.7,.3,1), translateY 20→0, opacity 0.6→1 |
| Field focus border | 0.15s linear |
| Submit button enable/disable | 0.15s linear |

## State Management

```
onboardingState {
  step: 0..3
  google: bool             // synced with Google auth status
  health: bool             // synced with Health Connect permission grant
  kt: bool                 // synced with KT auth token presence
  ktEmail: string | null   // displayed as KT row subtitle when connected
  notif: bool = true       // synced with OS notification permission
  sheet: 'kt' | null
}
```

Persist `onboarding.completed` (bool) plus the four flags in the same store the app already uses for Settings — Settings becomes the single source of truth; onboarding is a thin write-through. KT credentials should be stored in Keychain/EncryptedSharedPreferences, not plain prefs.

After step 4's CTA: `onboarding.completed = true`, route replace to `/dashboard` (no back stack).

## Design Tokens

### Colors
| Role | Hex / Value |
|---|---|
| App background | `#0B0F1E` |
| Card 1 | `linear-gradient(180deg, rgba(40,38,76,0.55), rgba(22,22,46,0.85))` |
| Card 2 | `rgba(28,30,56,0.45)` |
| Border soft | `rgba(148,130,220,0.18)` |
| Border mid | `rgba(167,139,250,0.22)` |
| Text primary | `#F5F3FF` |
| Text secondary | `rgba(245,243,255,0.55)` |
| Text muted | `rgba(245,243,255,0.40)` |
| Purple primary | `#8B5CF6` |
| Purple deep | `#7C3AED` |
| Purple accent | `#A78BFA` |
| Purple light | `#C4B5FD` |
| Gold | `#F4C152` |
| Teal | `#3FB8AF` |
| Green | `#34D399` |
| KT brand green primary | `#8FBE3D` |
| KT brand green deep | `#6E9527` |
| KT tint (subtle) | `#7BA42B` |

### Spacing
4 / 6 / 8 / 10 / 12 / 14 / 18 / 20 / 22 / 28 px — used freely; no rigid 4/8 grid.

### Radii
- Pill / toggle thumb: 999
- Field, badge: 12
- Button: 14 / 16
- Card: 16 / 18
- Sheet top corners: 24
- StepIcon: 22

### Typography
**Inter** (400/500/600/700/800) — load via Google Fonts or bundle.

| Style | Size / Weight / Tracking / Line-height |
|---|---|
| Display title (step 1) | 28 / 800 / -0.03em / 1.15 |
| Step heading | 24 / 800 / -0.02em / 1.2 |
| Section label (✦ ALL CAPS) | 10–11 / 800 / 0.14em / 1 |
| Pill / badge label | 10 / 800 / 0.06em |
| Body | 14 / 400 / 1.5 |
| Subtitle | 15 / 400 / 1.45 |
| Caption | 12–13 / 400 / 1.4 |
| Footnote | 11 / 400 / 1.45 |

### Shadows
- Purple CTA: `0 8px 24px -6px rgba(139,92,246,0.65)` + inset `0 1px 0 rgba(255,255,255,0.18)`
- Teal CTA: `0 8px 22px -6px rgba(63,184,175,0.45)`
- KT green CTA: `0 8px 24px -6px rgba(123,164,43,0.55)`
- Sigil halo: `0 12px 32px -8px rgba(139,92,246,0.55)` + inset `0 0 30px rgba(139,92,246,0.15)`
- Level badge: `0 4px 14px -2px rgba(139,92,246,0.55)`
- Google button: `0 4px 18px rgba(0,0,0,0.25)`

## Assets
| File | Purpose | Source |
|---|---|---|
| `assets/kt-logo.png` | Kalorické Tabulky brand mark used in toggle row icon and sheet header | Provided by stakeholder; do not modify |

Sigil illustration, class/data icons, and notification icon are emoji placeholders awaiting illustrator assets — see Fidelity section.

## Files
| File | Purpose |
|---|---|
| `design_files/WelcomeMultiStep.jsx` | Authoritative component — 4-step flow + KT login sheet. Inline styles are illustrative; port to Flutter widgets. |
| `design_files/tokens.css` | Color/spacing/type tokens lifted from the rest of the app. Use as cross-reference. |
| `design_files/ios-frame.jsx` | Phone frame used by the prototype only — NOT part of the production screen. Ignore. |
| `design_files/assets/kt-logo.png` | KT logo asset. |

## Implementation Notes for Claude Code (Flutter)
- Wrap the flow in a single `WelcomeScreen` widget; use a `PageView` with `physics: NeverScrollableScrollPhysics()` so steps only advance via the CTA / back chevron / "Přeskočit" link.
- Use `AnimatedSwitcher` for sheet enter/exit; `AnimatedContainer` for toggle rows and progress dots.
- KT login sheet → `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.transparent, ...)` so the rounded-corner gradient surface paints correctly.
- Read SafeArea insets manually rather than wrapping in `SafeArea` — the dark gradient must extend behind the status bar.
- Provide a small `ConfettiController` on step 4 — fire on CTA tap, then route-replace.
- The `IntegrationToggleRow`, `KTLoginSheet`, and `KTField` widgets should live in `lib/features/onboarding/widgets/` and be reusable from Settings (the same KT login sheet should appear if a user reconnects later).
- Do NOT copy the inline style objects verbatim — translate each into the app's `ThemeData` (colors → `colorScheme`/extension, type → `textTheme`, radii/spacing → constants).

