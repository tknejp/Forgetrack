# Handoff: Avatar Picker — Dedicated Onboarding Step (Variant A)

## Overview

This handoff covers a **dedicated avatar-picker step** that becomes part of the Forgetrack onboarding flow. The user picks a hero avatar from a pool of preset characters OR uploads their own photo. The step lives between the existing **Welcome** and **Account (Google sign-in)** screens, turning the onboarding from 4 steps into 5 steps:

```
1. Vítej, hrdino          (existing — unchanged)
2. Vyber si tvář          ← NEW, this handoff
3. Ulož si svůj postup    (existing — unchanged)
4. Připoj svoje data      (existing — unchanged)
5. Poslední doladění      (existing — unchanged)
```

The step has its own progress dot (2/5) and standard back + primary CTA in the footer. The player chooses an avatar; the selection becomes part of `hero.avatar` and is shown everywhere the player appears (profile header, leaderboard, friends list, notifications).

## About the Design Files

The files in this bundle are **design references created in HTML/React** — interactive prototypes showing the intended look and behavior. **They are not production code to ship.**

Your task is to **recreate the design in the Forgetrack codebase using its existing patterns and libraries** (Flutter widgets, Riverpod/Bloc state, existing onboarding stepper, etc.).

If you genuinely have no existing environment, pick the framework most appropriate for the project. For Forgetrack the assumed target is **Flutter** — the handoff notes call out Flutter-specific component names (`PageView`, `showModalBottomSheet`, `image_picker`, `image_cropper`), but the design itself is framework-agnostic.

## Fidelity

**High-fidelity.** Final colors, typography, spacing, and interaction details are locked. Recreate pixel-perfect within the codebase's component library — colors, type, layout, animation durations should match.

Open `preview.html` in a browser to see the live prototype: it scales to phone width, every avatar tile is clickable, the big preview updates, and the class label below the grid changes accordingly.

## Screens / Views

### Avatar Picker Step (step 2 of 5)

**Purpose** — Let the player establish their on-screen identity before continuing onboarding. The choice should feel like a small ceremony, not a form.

**Layout** — Standard Forgetrack onboarding shell, top-to-bottom:

```
┌────────────────────────────────────────┐
│ Status bar (system, 40px)              │
│                                        │
│ Progress dots ●●●●○  ────  Přeskočit   │  ← 14px 20 8 20px
│                                        │
│  ┌──────────────┐                      │
│  │              │  ← big preview       │
│  │   AVATAR     │     132×132,         │
│  │              │     with glow ring   │
│  │           ⭑  │     and "LVL 1"      │
│  └──────────────┘     badge bottom-r   │
│                                        │
│        Vyber si tvář                   │  ← 24px / 800
│  Takhle tě uvidí ostatní hráči v…      │  ← 14px / 55% white
│                                        │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐                   │
│  │  │ │  │ │  │ │  │                   │
│  └──┘ └──┘ └──┘ └──┘   grid 4×2 + 1    │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐                   │  upload tile is 9th
│  │  │ │  │ │  │ │📷│                   │
│  └──┘ └──┘ └──┘ └──┘                   │
│                                        │
│  ● Vybráno: Pixel hrdino               │  ← class tag card
│                                        │
├────────────────────────────────────────┤
│  [←]  [    Pokračovat  →    ]          │  ← footer 12 20 20
│                                        │
│ Gesture nav bar                        │
└────────────────────────────────────────┘
```

**Specs:**

- **Outer container**: full viewport. Background = radial gradient stack on `#0B0F1E` (see Design Tokens → Backgrounds).
- **Top bar**: progress dots row + skip button. Padding `14px 20px 8px`.
- **Progress dots**: 5 dots, each `height: 4px, border-radius: 2px`. Active dot `width: 22px`, inactive `width: 14px`. Active or earlier = `#A78BFA`; later = `rgba(167,139,250,0.18)`. Transition `all 0.3s`.
- **Skip button**: text "Přeskočit", `font-size: 13px`, `color: rgba(245,243,255,0.55)`, `font-weight: 500`. No background. **Skipping defaults to the pre-selected pixel avatar.**
- **Body content**: vertically scrollable. Horizontal padding `20px`. Top padding `8px`.

**Hero preview block** (centered):

- Container 132×132 with `display: grid; place-items: center; position: relative`.
- **Glow halo**: `position: absolute; inset: -8px; border-radius: 50%`. Background `radial-gradient(circle, <accent>55 0%, transparent 70%)`, `filter: blur(14px)`. Accent color is the avatar's hue if monogram, else `#A78BFA`.
- **Avatar badge**: 112×112 squircle (`border-radius: 35.84px` ≈ 32% of side). Image avatars use `object-fit: cover` on the photo; pixel images use `image-rendering: pixelated`. Monogram avatars show a single letter, `font-size: 44px, weight: 800`, centered on a 135° gradient from the hue to `<hue>aa`.
- **Level badge** (overlay): positioned bottom-right `(right: -2px, bottom: -2px)`. Pill `padding: 4px 10px, border-radius: 999px`. Background `linear-gradient(180deg, #1B1B3C, #0F1226)`. Border `1px solid rgba(244,193,82,0.45)`. Text "LVL 1", `font-size: 10px, weight: 800, color: #F4C152, letter-spacing: 0.06em`. Shadow `0 6px 14px -4px rgba(0,0,0,0.6)`.

**Title + subtitle:**

- Title "Vyber si tvář": `margin-top: 14px (from preview), font-size: 24px, weight: 800, letter-spacing: -0.02em, text-align: center, line-height: 1.2, color: #F5F3FF`.
- Subtitle "Takhle tě uvidí ostatní hráči v žebříčku. **Nemůžeš se rozhodnout?** Změníš to kdykoliv v profilu.": `margin-top: 6px, font-size: 14px, color: rgba(245,243,255,0.55), text-align: center, line-height: 1.45, padding: 0 8px`. The phrase "Nemůžeš se rozhodnout?" is colored `#A78BFA` inline.

**Avatar grid:**

- `margin-top: 18px`. Grid `4 columns, gap: 12px`. Each tile centered in its column.
- Each tile is a tappable button with no background/border, just the `AvatarBadge` inside.
- The 9th tile in the grid is the **upload tile** (see "Upload tile" below) — same size as avatar tiles.

**AvatarBadge** (each grid tile, size 'lg' = 72×72):

- Container 72×72, `border-radius: 23.04px` (72 × 0.32).
- Image avatars: `<img>` with `width/height: 100%, object-fit: cover, display: block`. `image-rendering: pixelated` for `pixel` ID.
- Monogram avatars: `display: grid; place-items: center`. Letter `font-size: 28px (for size lg), weight: 800, letter-spacing: -0.02em, color: #fff, text-shadow: 0 1px 2px rgba(0,0,0,0.35)`. Background `linear-gradient(135deg, <hue>, <hue>aa)`.
- **Selected state**: outer ring `box-shadow: 0 0 0 3px <accent>`, plus inner punch `inset 0 0 0 2px #0B0F1E` (background color), plus glow `0 6px 18px -4px <accent>`. Accent = avatar hue (for mono) or `#A78BFA` (for image).
- **Unselected state**: just a subtle drop shadow `0 2px 8px rgba(0,0,0,0.35)`.
- The ring is **outside** the squircle, so it creates a colored band around the tile with a tight breathing gap.

**Upload tile** (last position in grid, when no photo uploaded):

- 72×72, `border-radius: 23.04px`. Background `rgba(28,30,56,0.55)`. **Border: dashed 1px** `rgba(167,139,250,0.45)`.
- Centered content: 22×22 camera icon (see SVG below) above a small "Foto" label (`font-size: 9px, color: rgba(167,139,250,0.85), weight: 600, letter-spacing: 0.4px`).
- Camera icon SVG (24×24 viewBox, stroke `#A78BFA`, stroke-width 1.6):
  ```svg
  <rect x="3" y="6" width="18" height="13" rx="2"/>
  <circle cx="12" cy="13" r="3.5"/>
  <path d="M9 6l1.2-2h3.6L15 6"/>
  ```

**Upload tile** (when photo IS uploaded):

- Same dimensions, `border-radius: 23.04px`.
- Background changed to `#0B0F1E`. Border solid `1px rgba(167,139,250,0.45)`.
- Content = the uploaded photo, `width/height: 100%, object-fit: cover`.
- Tapping again should re-open the picker / cropper (replace photo).

**Class tag** (below grid):

- `margin-top: 16px, padding: 10px 14px, border-radius: 14px`.
- Background `rgba(167,139,250,0.08)`. Border `1px solid rgba(167,139,250,0.22)`.
- Inside: small dot (6×6 circle, `#A78BFA`, `box-shadow: 0 0 8px #A78BFA`) + text "Vybráno: **{avatarLabel}**".
- Text: `font-size: 12px, color: rgba(245,243,255,0.7)`. The label part is `color: #F5F3FF, weight: 700`.

**Footer:**

- `padding: 12px 20px 20px`. Flex row with `gap: 10px`.
- **Back button** (left): `width: 56px, height: 52px, border-radius: 16px`. Background `rgba(28,30,56,0.45)`. Border `1px solid rgba(167,139,250,0.22)`. Color `#C7C2E0`. Centered chevron-left SVG (`<path d="M9 2L4 7l5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>`).
- **Primary CTA** "Pokračovat" (flex: 1): `height: 52px, border-radius: 16px`. Background `linear-gradient(180deg, #8B5CF6 0%, #7C3AED 100%)`. Color `#fff`. `font-size: 15px, weight: 700`. Centered content with optional `→` chevron at the end (`<path d="M5 2l5 5-5 5" stroke="#fff" stroke-width="2" stroke-linecap="round"/>`). Shadow `0 8px 24px -6px rgba(139,92,246,0.65), inset 0 1px 0 rgba(255,255,255,0.18)`.

## Avatar Pool

Eight presets ship with the design. Two are image-backed (real PNG assets), six are monogram placeholders to be replaced by illustrator-drawn character portraits in production.

| ID         | Kind  | Label          | Hue / Source                    | Notes                                    |
|------------|-------|----------------|----------------------------------|------------------------------------------|
| `pixel`    | img   | Pixel hrdino   | `assets/avatar_pixel.png`        | Default. Pixel art, render with `image-rendering: pixelated`. |
| `fox`      | img   | Liška          | `assets/forest_fox.png`          | Painterly fox illustration.              |
| `poutnik`  | mono  | Poutník        | `#8B5CF6` (purple)               | Monogram "P". To be replaced by illustration. |
| `kovar`    | mono  | Kovář          | `#F4C152` (gold)                 | Monogram "K". To be replaced.            |
| `mudrc`    | mono  | Mudrc          | `#3FB8AF` (teal)                 | Monogram "M". To be replaced.            |
| `bard`     | mono  | Bard           | `#F472B6` (rose)                 | Monogram "B". To be replaced.            |
| `lukos`    | mono  | Lukostřelec    | `#FB923C` (orange)               | Monogram "L". To be replaced.            |
| `mag`      | mono  | Mág            | `#A78BFA` (light purple)         | Monogram "É". To be replaced.            |

The **default selection** must be `pixel`. Never null. If the user taps "Přeskočit" or backgrounds the app mid-flow, the default carries through.

## Interactions & Behavior

**On enter:**
- The pre-selected avatar (`pixel` by default, or whatever was previously persisted) shows in the big preview.
- The matching grid tile shows its selected ring.
- Class tag at the bottom shows the matching label.

**Tap a preset avatar:**
- Update local state `pickedId`.
- Big preview swaps to the new avatar with a subtle animation: scale `0.92 → 1.0` over `220ms`, ease-out. The previous avatar fades out as the new fades in (use `AnimatedSwitcher` in Flutter).
- Glow halo color transitions to the new accent — `AnimatedContainer` `250ms` ease-out.
- "LVL 1" badge stays visible throughout.
- Class tag label updates with `AnimatedSwitcher` fade `160ms`.
- Grid tile that was previously selected loses its ring. New tile gains ring + glow.

**Tap upload tile (no photo yet):**
1. Show OS picker via `image_picker` (allow gallery + camera).
2. After image returned, open `image_cropper` with **circular crop** locked to a 1:1 aspect ratio.
3. After crop, save the cropped result to `getApplicationSupportDirectory()` as a PNG, target size **256×256** (resize on save).
4. Set `hero.avatar = { kind: 'photo', photoUrl: <path> }`. Set selection to the photo (so it appears in the big preview and the upload tile shows the thumbnail).
5. On permission denied: stay on the avatar grid, show a snackbar/toast: *"Bez fotky to taky půjde — vyber si tvář z poolu."*
6. On crop cancelled: no-op, keep previous selection.

**Tap upload tile (photo already uploaded):**
- Re-open picker → cropper. Replacing the previous photo overwrites the file in app dir.

**Tap "Přeskočit":**
- Persist current `hero.avatar` (default `pixel` if nothing changed).
- Skip to the **final** onboarding step (matching existing onboarding behavior — skip jumps to the final summary step, not to the next step).

**Tap back chevron:**
- Return to step 1 (Welcome) without resetting selection.

**Tap "Pokračovat":**
- Persist `hero.avatar` to local store (Hive box, or whatever Forgetrack already uses).
- Advance to step 3 (Google sign-in / Account).

## State Management

```dart
// Within the onboarding flow:
state.pickedAvatarId    : String           // default: 'pixel'
state.uploadedPhotoPath : String?          // null until upload

// Persisted to hero domain on continue:
hero.avatar : Avatar    // see model below
```

**Avatar model:**

```dart
sealed class Avatar {
  const Avatar();
}

class PresetAvatar extends Avatar {
  final String id;   // 'pixel', 'fox', 'poutnik', ...
  const PresetAvatar(this.id);
}

class PhotoAvatar extends Avatar {
  final String photoPath;  // absolute path in app support dir
  const PhotoAvatar(this.photoPath);
}

// Default:
const defaultAvatar = PresetAvatar('pixel');
```

The `AvatarBadge` widget takes an `Avatar` and renders accordingly. It's shared across:
- Onboarding picker (this handoff)
- Hero profile header
- Leaderboard rows
- Friend cards
- Any place the player appears

## Design Tokens

From `tokens.css` — re-declare these in your design system if not already present:

```
/* Backgrounds */
--bg-app:      #0B0F1E
--bg-card:     rgba(28, 30, 56, 0.65)

/* Onboarding gradient (apply to step container as background) */
background:
  radial-gradient(ellipse 80% 50% at 50% 0%,   rgba(139,92,246,0.20), transparent 60%),
  radial-gradient(ellipse 60% 30% at 50% 100%, rgba(63,184,175,0.10), transparent 60%),
  #0B0F1E;

/* Text */
--text-primary:   #F5F3FF   (titles, avatar names, button labels)
--text-secondary: #C7C2E0   (back button icon)
--text-muted:     rgba(245,243,255,0.55)  (subtitles, skip)
--text-dim:       rgba(245,243,255,0.4)   (footnote text)

/* Brand purple */
--purple-300: #C4B5FD
--purple-400: #A78BFA   ← progress dot active, accent links, default image accent
--purple-500: #8B5CF6   ← primary button gradient top
--purple-600: #7C3AED   ← primary button gradient bottom

/* Accents */
--gold:  #F4C152        ← LVL badge text, gold sparks
--teal:  #3FB8AF        ← mudrc avatar
--rose:  #F472B6        ← bard avatar
--orange: #FB923C       ← lukos avatar

/* Borders */
--border-soft:   rgba(148, 130, 220, 0.12)
--border-mid:    rgba(148, 130, 220, 0.22)
--border-strong: rgba(167, 139, 250, 0.45)

/* Radii */
--r-sm: 10px
--r-md: 16px
--r-lg: 20px
--r-xl: 28px

/* Type */
font-family: 'Inter' (preferred, fallback to system sans-serif)
weights used: 500, 600, 700, 800
```

**Avatar tile radius rule**: tile `border-radius` is `tileSize * 0.32` (squircle-ish). For a 72px tile, that's `23.04px`.

## Assets

The bundle includes:

- `assets/avatar_pixel.png` — pixel-art hero. Default avatar. Render with `image-rendering: pixelated` (CSS) / `FilterQuality.none` (Flutter).
- `assets/forest_fox.png` — painterly fox.

In production you'll need:

- **Illustrated portraits** for the 6 monogram-based slots (Poutník, Kovář, Mudrc, Bard, Lukostřelec, Mág). Match the existing portrait style — same crop, same lighting direction, transparent or solid background. Spec to illustrator: 512×512 PNG, character portrait waist-up, consistent palette per character archetype.
- **Crop dialog UI** — if you don't use an off-the-shelf `image_cropper`, design specifies a **circular** crop window, no rectangle option.

## Animation Spec

| Element                 | Trigger              | Animation                                       |
|-------------------------|----------------------|-------------------------------------------------|
| Hero preview swap       | Tap new avatar       | `AnimatedSwitcher`, scale 0.92→1.0, 220ms ease-out |
| Glow halo color         | Tap new avatar       | `AnimatedContainer`, 250ms ease-out             |
| Class tag label         | Tap new avatar       | `AnimatedSwitcher`, fade 160ms                  |
| Grid tile ring          | Selection change     | `AnimatedContainer`, 200ms ease-out             |
| Progress dot width      | Step change          | 300ms ease                                      |
| Primary button press    | Tap                  | Standard Material InkWell ripple                |
| Sparks around preview   | Idle (continuous)    | Opacity 0→1→0 + scale 0.4→1, 2.4s loop, staggered (optional; design adds 3-4 gold sparks orbiting the preview — see hybrid variant for reference; in step variant they're omitted for focus) |

## Component Map

How the design files map to Flutter widgets you'll build:

| Design file (this bundle)        | Flutter widget                          |
|----------------------------------|-----------------------------------------|
| `AvatarStep.jsx`                 | `AvatarPickerStep` (StatefulWidget; child of onboarding `PageView`) |
| `AvatarPickerShared.jsx` → `AvatarBadge`       | `AvatarBadge` (shared, reusable everywhere player shows) |
| `AvatarPickerShared.jsx` → `UploadTile`        | `UploadAvatarTile` (handles picker + cropper + permission flow) |
| `AvatarPickerShared.jsx` → `AvatarGrid`        | `AvatarGrid` (`GridView.count` crossAxisCount: 4) |
| `AvatarPickerShared.jsx` → `OnboardingShell`   | Existing onboarding shell — pass step index 1, total 5 |
| `AvatarPickerShared.jsx` → `APPrimaryBtn`      | Existing primary button — reuse, don't rebuild |
| `AvatarPickerShared.jsx` → `APBackBtn`         | Existing back chevron — reuse |
| `AvatarPickerShared.jsx` → `ProgressDots`      | Existing progress dots — pass total: 5 (was 4) |

## Files in this bundle

```
design_handoff_avatar_picker_step/
├── README.md                    ← you are here
├── preview.html                 ← open in browser to see live design
├── AvatarStep.jsx               ← variant A screen
├── AvatarPickerShared.jsx       ← AvatarBadge, AvatarGrid, UploadTile, OnboardingShell, primary/back buttons, AvatarSheet (bonus — Settings reuse)
├── android-frame.jsx            ← Android device frame for preview only (NOT for production)
├── tokens.css                   ← all design tokens used
└── assets/
    ├── avatar_pixel.png
    └── forest_fox.png
```

`AvatarPickerShared.jsx` exports an `AvatarSheet` component used by other variants (modal bottom sheet with the same grid). You **don't need it for this step**, but if/when Forgetrack adds "change avatar" in Settings, reuse it — same grid, same upload behavior, just opened as `showModalBottomSheet`.

## Implementation Checklist

- [ ] Bump onboarding step count from 4 → 5 in the `ProgressDots` / shell.
- [ ] Insert `AvatarPickerStep` as page index 1 in the onboarding `PageView`.
- [ ] Build `AvatarBadge` widget (image + monogram + selected states). Make it shared.
- [ ] Build `AvatarGrid` (4 cols, includes upload tile as last cell).
- [ ] Build `UploadAvatarTile` with `image_picker` + `image_cropper` (circle crop, 256×256 output).
- [ ] Wire up `hero.avatar` persistence (Hive box / SharedPreferences / whatever Forgetrack already uses).
- [ ] Default `pixel` selected on first entry. Never null.
- [ ] "Přeskočit" jumps to final step (matches existing skip behavior elsewhere).
- [ ] Hook up all shared callsites (profile header, leaderboard, etc.) to read `hero.avatar` via the shared `AvatarBadge`.
- [ ] Replace the 6 monogram avatars with illustrated portraits (separate ticket — illustrator).

## Open Questions for PM / Design

1. **Avatar = aesthetic only, or does it map to a class with gameplay impact?** If gameplay-relevant, the labels (Poutník / Kovář / Mudrc) need to be more prominent and the choice less reversible. If aesthetic-only, the current design is right.
2. **Sync of uploaded photo across devices?** Currently local-only. Sync via Google Drive backup or Firestore needs a separate spec.
3. **Moderation of uploaded photos?** If leaderboards are public, NSFW/abuse moderation may be needed. Out of scope for this step but flag for product.
