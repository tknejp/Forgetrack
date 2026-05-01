# UI Cleanup Plan — ForgeTrack

> **Source of truth for the ongoing UI cleanup.**
> Read this document before each implementation phase. Update it after each phase completes.

---

## Naming Conventions

### Class prefix rules
| Context | Old (legacy) | New (target) | Status |
|---|---|---|---|
| Shared design-system widgets | `FtStatCard`, `FtProgressBar` … | No prefix — `StatCard`, `ProgressBar`, or namespace via folder | Pending |
| Screen classes | `FtProgressionScreen`, `FtOverviewScreen` … | Drop prefix: `ProgressionScreen`, `OverviewScreen` | Pending |
| Theme / token class | `FtThemeTokens` | `AppTokens` | Pending |
| Static token container | `FtTokens` | `AppTokens` (merge with above) | Pending |
| Domain palette type | `FtDomain` | `DomainPalette` | Pending |
| Context extension | `context.ft` | `context.tokens` (or keep `context.ft` until full rename) | Pending |
| File names under `shared/widgets/ft/` | `ft_stat_card.dart` | `stat_card.dart` (move to `shared/widgets/`) | Pending |

### File/folder naming rules
- One primary public class per file; file name must match it (snake_case of class name).
- No generic bag files: `helpers.dart`, `shared.dart`, `utils.dart` are banned — name by responsibility.
- Feature-internal private widgets stay in `features/<feature>/presentation/widgets/`.
- Design-system-grade widgets (used by ≥2 features) live in `shared/widgets/`.
- No presentation-layer widget may live in `shared/` if it belongs to a single feature domain.

### Spacing / radius / shadow conventions
- All spacing values must come from `FtTokens` (to be expanded — see Token Migration section).
- `BorderRadius.circular(N)` is only allowed inside `FtTokens` or `AppTheme`; everywhere else use the token constant.
- Inline `BoxShadow` literals are forbidden; define named shadows in tokens.
- `Colors.white`, `Colors.black` with `.withValues(alpha:…)` should use `FtTokens.onSurface` etc.

---

## Token Migration Notes

### What exists today (`ft_design_tokens.dart`)
`FtTokens` already has:
- Full color palette: `bg`, `surface`, `cardBorder`, `divider`, `onSurface`, `onSurfaceMuted`, `onSurfaceFaint`, `accent`, `accentGlow`, `secondary`, `tertiary`, `success`, `warning`, `danger`, `xp`, `xpGlow`
- Achievement difficulty colors: `difficultyEasy`, `difficultyMedium`, `difficultyHard`, `difficultyExtraHard`
- Domain palettes: `steps`, `calories`, `weight`, `sleep`, `active`, `protein`, `fat`, `carbs` (each has `color`, `dim`, `glow`, `gradStart`, `gradEnd`, `.gradient`, `.cardDecoration()`)
- Spacing constants: `spaceXs = 4`, `spaceSm = 8`, `spaceMd = 12`, `spaceLg = 16`, `spaceXl = 20`, `space2xl = 24`, `space3xl = 32`
- Radius constants: `radiusCard = 18`, `radiusInner = 12`, `radiusTile = 14`, `radiusButton = 16`, `radiusIcon = 10`, `radiusProgress = 99`
- Font size constants: `fontSizeTiny = 9`, `fontSizeMicro = 10`, `fontSizeCaption = 11`, `fontSizeSmall = 12`, `fontSizeBody = 14`, `fontSizeTitle = 20`
- `FtRarity` — immutable palette class at bottom of file; `common`, `rare`, `epic`, `legendary` variants with `color` and `gradStart`

**Note on `SizedBox(height: 10)` / `(width: 10)`:** The value 10 appears ~113 times in the codebase and has no clean mapping to the token scale (nearest neighbors are `spaceSm = 8` and `spaceMd = 12`). These were intentionally left unreplaced to preserve visual behavior. A future design decision is needed: normalize to 8 or 12.

### What is still MISSING
- **Shadow tokens** — add named `BoxShadow` constants for card glow, icon glow, map node shadow.
- **TextStyle presets** — `FtTokens` has font size constants but no `TextStyle` instances; add named presets (e.g. `FtTokens.labelSm`, `FtTokens.labelMd`, `FtTokens.valueLg`).

### `AppThemeTokens` vs `FtThemeTokens` — dual extension problem
`app_theme.dart` defines `AppThemeTokens` (section colors, card/tile radius). `ft_design_tokens.dart` defines `FtThemeTokens` (full palette). Both are registered as theme extensions. This is redundant — the `SectionColors` inside `AppThemeTokens` duplicates data already in `FtThemeTokens.steps/calories/…`. **Decision: consolidate into `FtThemeTokens` only; remove `AppThemeTokens` and migrate `context.tokens` callsites to `context.ft`.**

### Rules for preserving visual behavior during token migration
1. Replace a hardcoded literal only when you can prove the token value is identical or visually equivalent.
2. Never change a color's alpha while migrating — if the hardcoded value is `Color(0x40FBBF24)` and the token is `FtTokens.calories.glow` (`Color(0x40FBBF24)`), they match. If they don't match, log the discrepancy and do not auto-replace.
3. Animations and transitions must not be touched during a token migration — only static decoration values.
4. Screenshot the screen before and after each file's migration; diff visually.
5. Do not batch multiple screens into one commit — one screen per commit.

---

## Feature / Module Boundaries

### Target structure
```
lib/
├── core/              # App bootstrap, router, DI root — no UI
├── shared/
│   ├── theme/         # AppTheme, FtTokens, FtThemeTokens only
│   └── widgets/       # Design-system widgets used by ≥2 features
│       └── (no ft/ subfolder — files live directly here after rename)
└── features/
    ├── app_shell/
    ├── home/
    ├── health_connect/
    ├── nutrition/
    ├── progression/
    │   └── presentation/widgets/  ← ft_progression_xp_style moves here
    ├── social/                    ← must NOT import progression/presentation/
    ├── cosmetics/
    ├── settings/
    ├── sheets_export/
    └── devtools/                  ← allowed to import everything (debug tool)
```

### Known boundary violations
| Violation | Severity | Status |
|---|---|---|
| ~~`social/presentation/` imports `ft_progression_primitives.dart`~~ | ~~High~~ | ✅ Fixed (Phase 6) |
| ~~`social/social_helpers.dart` imports `ft_progression_domain_theme.dart`~~ | ~~High~~ | ✅ Fixed (Phase 6) |
| ~~`ft_progression_xp_style.dart` lives in `shared/widgets/ft/`~~ | ~~Medium~~ | ✅ Fixed (Phase 5) — deleted, was duplicate of `FtTokens.xp`/`xpGlow` |
| `social/` imports `progression_l10n.dart` (4 files) | Low | Accepted — l10n is a shared concern; progression strings are needed to display progression data in social |

---

## Phases

### Phase 1 — Dead code removal ✅ DONE (2026-04-30)
Zero-risk deletions.

| Action | File | Result |
|---|---|---|
| Deleted unused widget | `lib/shared/widgets/ft/ft_xp_bar.dart` | 0 imports; confirmed dead |
| Deleted empty placeholder | `lib/features/profile/` | Was `.gitkeep` only |
| Deleted empty placeholder | `lib/core/utils/` | Was `.gitkeep` only |

---

### Phase 2 — Spacing tokens ✅ DONE (2026-04-30)
Added `spaceXs/Sm/Md/Lg/Xl/2xl/3xl` to `FtTokens`. Swept `SizedBox` literals for values 4, 8, 12, 16, 20, 24, 32 across all 45 files that already imported `ft_design_tokens.dart`. Value `10` intentionally left as literal pending design decision (normalize to 8 or 12).

---

### Phase 3 — Color token adoption ✅ DONE (2026-04-30)

| Action | Detail |
|---|---|
| Added `FtRarity` class to `ft_design_tokens.dart` | `common`/`rare`/`epic`/`legendary` palettes with `color` + `gradStart` |
| Added `success`, `warning`, `danger` as static consts to `FtTokens` | Were instance fields on `FtThemeTokens` only; promoted so painters/static contexts can use them |
| Added `fontSizeSmall = 12.0` to `FtTokens` | Was missing from the font size scale |
| Added `difficultyEasy/Medium/Hard/ExtraHard` | Achievement difficulty colors tokenised (also serves Phase 6) |
| Created `lib/features/cosmetics/presentation/cosmetics_palette.dart` | `CosmeticsPalette.forRarity(rarity)` maps `CosmeticRarity` → `FtRarity` |
| Patched `cosmetic_collection_tile.dart` | Replaced local `_rarityColor` with `CosmeticsPalette.forRarity(definition.rarity).color` |
| Patched `cosmetic_equipped_chip.dart` | Same; also replaced `BorderRadius.circular(12)` → `FtTokens.radiusInner` |
| Patched `cosmetic_frame_preview.dart` | Replaced local `_gradientColors` with `CosmeticsPalette.forRarity(rarity)` palette |
| Patched `cosmetics_screen.dart` | `_rarityColor` helper updated to use `FtTokens.difficulty*` tokens; `foregroundColor: FtTokens.bg` |
| Patched `ft_overview_screen.dart` | `Color(0xFFF87171)` → `FtTokens.danger`; `Color(0x08FFFFFF)` → `context.ft.surfaceSubtle` |

**Remaining known hardcoded colors (intentionally left):**
- `Color(0xCCFFFFFF)` in `ft_overview_screen` — 80% white, no semantic token; needs design input
- `Color(0xFFEF4444)` badge in `ft_main_shell` — slightly different red than `FtTokens.danger`; left to avoid silent color change

---

### Phase 4 — BorderRadius token sweep ✅ DONE (2026-04-30)
Added `radiusInner = 12`, `radiusTile = 14`, `radiusButton = 16` to `FtTokens`. Swept `BorderRadius.circular(N)` and `Radius.circular(N)` for values 10, 12, 14, 16, 18, 99 across the same 45 files. Value `20` intentionally not replaced — it maps to `AppThemeTokens.cardRadius` (different domain).

---

### Phase 5 — `FtProgressionXpStyle` elimination ✅ DONE (2026-04-30)
`FtProgressionXpStyle` was a 6-line class that duplicated `FtTokens.xp` and `FtTokens.xpGlow` exactly. Added `xp`/`xpGlow` as static consts to `FtTokens`, replaced all 4 call sites, deleted the file.

Also added `xp` and `xpGlow` as static consts to `FtTokens` (they already existed as instance fields on `FtThemeTokens.dark` but were not available as compile-time consts for use in painters and static contexts).

---

### Phase 6 — Social → Progression boundary violation ✅ DONE (2026-04-30)

| Action | Detail |
|---|---|
| Added `FtTokens.difficultyEasy/Medium/Hard/ExtraHard` | 4 achievement difficulty colors now in token system |
| Updated `FtProgressionDomainTheme` constants | Now reference `FtTokens.difficulty*` instead of raw hex |
| Created `shared/widgets/ft/ft_tiny_pill.dart` | `FtTinyPill` (renamed from `FtProgTinyPill`) moved out of progression |
| Deleted `FtProgTinyPill` from `ft_progression_primitives.dart` | All 10 call sites updated to `FtTinyPill` |
| Moved `progression_badge_specs.dart` → `shared/presentation/achievement_badge_specs.dart` | Stripped `ft_progression_domain_theme` dependency; uses `FtTokens.difficulty*` directly |
| Patched `social_helpers.dart` | Removed `ft_progression_domain_theme` import; uses `FtTokens.difficulty*` |
| Patched `social_user_profile_sheet.dart` | Removed `ft_progression_primitives` import; uses shared `FtTinyPill` + `achievement_badge_specs` |
| Patched `social_feed_card.dart` | Import updated to shared `achievement_badge_specs` |

**Remaining accepted soft violations** (`progression_l10n.dart` imported by 4 social files):
Social displays progression concepts (level, XP, achievement labels) so it legitimately needs progression l10n strings. These imports are noted but not treated as violations requiring a fix — l10n is a shared concern.

---

### Phase 7 — fontSize literal sweep ✅ DONE (2026-04-30)
Replaced all inline `fontSize: N` literals with `FtTokens.fontSizeXxx` references across every file that already imported `ft_design_tokens.dart` (37 files changed, 0 new imports added).

| Literal | Token |
|---|---|
| `fontSize: 9` | `FtTokens.fontSizeTiny` |
| `fontSize: 10` | `FtTokens.fontSizeMicro` |
| `fontSize: 11` | `FtTokens.fontSizeCaption` |
| `fontSize: 12` | `FtTokens.fontSizeSmall` |
| `fontSize: 14` | `FtTokens.fontSizeBody` |
| `fontSize: 20` | `FtTokens.fontSizeTitle` |

`dart analyze lib/` showed zero errors after the sweep (only pre-existing generated-file warnings in Isar/HealthConnect `.g.dart` files).

**TextStyle presets (named instances)** were identified as a follow-on sub-phase but not implemented here — they require a design audit of the 350+ remaining `TextStyle(...)` call sites. Tracked as a "MISSING" item in the Token Migration Notes section.

---

### Phase 8 — Oversized file splits (✅ DONE 2026-04-30)
Files over ~500 lines that contained unrelated widgets:

| File | Before | After | New files | Notes |
|---|---|---|---|---|
| `ft_progression_screen.dart` | 3,054 | 1,215 | `ft_quests_screen.dart` (1,599), `progression_internals.dart` (292) | Shared helpers extracted to internals file |
| `social_user_profile_sheet.dart` | 1,282 | ~780 | `social_profile_achievement_grid.dart`, `social_profile_friends_section.dart` | Achievement grid + friends list extracted |
| `social_profile_header.dart` | 1,039 | 796 | `social_edit_handle_sheet.dart` | Edit handle sheet extracted |
| `cosmetics_screen.dart` | 991 | 617 | `cosmetic_details_sheet.dart`, `cosmetics_screen_internals.dart` | Shared badge/label helpers in internals |
| `journey_interactive_map.dart` | 1,669 | — | — | **Skipped** — canvas painting + collision detection tightly coupled; high risk |
| `ft_progression_home_card.dart` | 990 | — | — | **Skipped** — all private classes tightly coupled within single card widget |

---

### Phase 9 — Confusing name fixes (✅ DONE 2026-04-30)
| File | Action | Result |
|---|---|---|
| `stat_display.dart` | Renamed | → `stat_components.dart` |
| `journey_shared.dart` | Renamed | → `journey_primitives.dart` |
| `social_helpers.dart` | Renamed | → `social_profile_utils.dart` |
| `settings_helpers.dart` | Renamed | → `settings_tile_builders.dart` (part file, `part of` directive unchanged) |
| `app_theme.dart` | **Skipped** | `SectionColors`, `AppThemeTokens`, and `AppTheme` are tightly coupled with inline text style definitions — no clean split boundary. Phase 10 plans to consolidate `AppThemeTokens` into `FtThemeTokens`; splitting now would only create churn. |

---

### Phase 10 — `Ft` prefix rename (✅ DONE 2026-04-30)

**Widget files** — moved from `shared/widgets/ft/` to `shared/widgets/`, `ft_` prefix dropped from filename and class name:
| Old class | New class | File |
|---|---|---|
| `FtActivityRow` | `ActivityRow` | `activity_row.dart` |
| `FtDateNav` | `DateNav` | `date_nav.dart` |
| `FtDetailShortcutButton` | `DetailShortcutButton` | `detail_shortcut_button.dart` |
| `FtDragRevealPager` / `FtEdgePageHandoff` | `DragRevealPager` / `EdgePageHandoff` | `drag_reveal_pager.dart` |
| `FtMacroRow` | `MacroRow` | `macro_row.dart` |
| `FtPlainCard` | `PlainCard` | `plain_card.dart` |
| `FtProgressBar` | `ProgressBar` | `progress_bar.dart` |
| `FtScreenHeader` | `ScreenHeader` | `screen_header.dart` |
| `FtStatCard` / `FtStatStat` | `StatCard` / `StatStat` | `stat_card.dart` |
| `FtStatCell` | `StatCell` | `stat_cell.dart` |
| `FtTabPill` | `TabPill` | `tab_pill.dart` |
| `FtTinyPill` | `TinyPill` | `tiny_pill.dart` |
| `FtTrendChart` / `FtTrendCard` / `FtTrendMetric` / `FtChartBar` | `TrendChart` / `TrendCard` / `TrendMetric` / `ChartBar` | `trend_chart.dart` |
| `FtXpClaimPill` / `FtXpClaimPillData` | `XpClaimPill` / `XpClaimPillData` | `xp_claim_pill.dart` |
| `FtXpSparkleOverlay` / `FtXpSparkleLauncher` | `XpSparkleOverlay` / `XpSparkleLauncher` | `xp_sparkle_overlay.dart` |

**Screen classes** — class names renamed in place (files keep `ft_` prefix for now):
| Old | New |
|---|---|
| `FtMainShell` | `MainShell` |
| `FtActivitiesScreen` | `ActivitiesScreen` |
| `FtBodyScreen` | `BodyScreen` |
| `FtSleepScreen` | `SleepScreen` |
| `FtOverviewScreen` | `OverviewScreen` |
| `FtNutritionScreen` | `NutritionScreen` |
| `FtProgressionScreen` | `ProgressionScreen` |
| `FtQuestsScreen` | `QuestsScreen` |
| `FtSocialScreen` | `SocialScreen` |
| `FtProgressionCard` | `ProgressionCard` |

**Deferred — token renames** (high risk, every file, needs dedicated commit):
| Old | New | Status |
|---|---|---|
| `FtThemeTokens` | `AppTokens` | Pending — ThemeExtension used in every widget |
| `FtTokens` | merged into `AppTokens` | Pending — static constants in every file |
| `FtDomain` | `DomainPalette` | Pending — depends on FtTokens merge |
| `context.ft` | `context.tokens` | Pending — depends on FtThemeTokens rename |

---

## Risky Areas — Extra Care Required

| Area | Risk | Mitigation |
|---|---|---|
| `journey_interactive_map.dart` | Canvas painting + gesture + animation tightly coupled | Split only after full test coverage; keep painter in one file |
| `ft_progression_screen.dart` | Navigation state, tab coordination, XP claim flow entangled | Extract tabs one at a time; test XP claim flow after each |
| `social_user_profile_sheet.dart` | Cross-feature data (progression + social) | Fix boundary first (Phase 6) before splitting (Phase 8) |
| Any `FtThemeTokens` / `FtTokens` rename | Referenced in nearly every widget | Generate import list before starting; do as one atomic commit |
| Design token migration across all screens | If a token value changes, all screens affected | Match hex values exactly; screenshot before/after |
| `AppThemeTokens` consolidation | `context.tokens` callsites exist across features | Grep all `context.tokens` before removing the extension |

---

## Decisions Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-04-30 | Consolidate `AppThemeTokens` into `FtThemeTokens` | Redundant dual extension; `SectionColors` data already exists in `FtDomain` |
| 2026-04-30 | Add spacing tokens before doing the token sweep | Sweeping literals without tokens creates new hardcoding |
| 2026-04-30 | Rename `Ft` prefix as the last phase | Prefix rename touches every import; safer after all structural work is done |
| 2026-04-30 | `ft_progression_xp_style.dart` deleted rather than moved | Its two values were exact duplicates of `FtTokens.xp`/`xpGlow`; deletion is cleaner than a move |
| 2026-04-30 | `SizedBox(height: 10)` left unreplaced in spacing sweep | 10 has no semantic token (nearest: spaceSm=8, spaceMd=12); replacing would silently change layout |
| 2026-04-30 | `BorderRadius.circular(20)` left unreplaced in radius sweep | 20 belongs to `AppThemeTokens.cardRadius` domain, not `FtTokens.radiusCard = 18` |
| 2026-04-30 | `FtXpBar` deleted (Phase 1) | 0 imports, fully unused; confirmed by repo-wide grep |
| 2026-04-30 | Social boundary fix before social file split | Splitting a file with a boundary violation embeds the violation deeper |
| 2026-04-30 | `progression_l10n.dart` cross-feature import accepted in social | Social legitimately displays progression labels (level, XP, achievement names); l10n is a shared concern by nature |
| 2026-04-30 | `FtProgTinyPill` renamed to `FtTinyPill` on move to shared | "Prog" prefix was feature-specific branding inappropriate for a shared widget |

---

## Components Renamed

_(none yet — Phase 10 pending)_

---

## Files Already Refactored

| File | Phase | Change |
|---|---|---|
| `lib/shared/widgets/ft/ft_xp_bar.dart` | 1 | Deleted (unused dead code) |
| `lib/features/profile/` | 1 | Deleted empty placeholder folder |
| `lib/core/utils/` | 1 | Deleted empty placeholder folder |
| `lib/shared/theme/ft_design_tokens.dart` | 2+4+5 | Added spacing tokens (spaceXs–space3xl), radius tokens (radiusInner/Tile/Button), and static `xp`/`xpGlow` consts |
| `lib/shared/widgets/ft/ft_progression_xp_style.dart` | 5 | Deleted (duplicate of FtTokens.xp/xpGlow) |
| 45 files across features + shared | 2+4 | SizedBox and BorderRadius literals replaced with FtTokens constants |
| `lib/shared/theme/ft_design_tokens.dart` | 6 | Added `difficultyEasy/Medium/Hard/ExtraHard` and `xp`/`xpGlow` static consts |
| `lib/shared/widgets/ft/ft_tiny_pill.dart` | 6 | New shared pill widget (moved from `ft_progression_primitives.dart`, renamed from `FtProgTinyPill`) |
| `lib/shared/presentation/achievement_badge_specs.dart` | 6 | Moved from `progression/presentation/badges/`; stripped `ft_progression_domain_theme` dependency |
| `lib/features/progression/presentation/widgets/ft_progression_primitives.dart` | 6 | Removed `FtProgTinyPill` (moved to shared) |
| `social_helpers.dart`, `social_user_profile_sheet.dart`, `social_feed_card.dart` | 6 | All cross-feature progression presentation imports removed |
| `lib/shared/theme/ft_design_tokens.dart` | 3 | Added `FtRarity` class, `fontSizeSmall`, `success`/`warning`/`danger` static consts |
| `lib/features/cosmetics/presentation/cosmetics_palette.dart` | 3 | New file — `CosmeticsPalette.forRarity()` maps `CosmeticRarity` → `FtRarity` |
| `lib/features/cosmetics/presentation/widgets/cosmetic_collection_tile.dart` | 3 | Replaced local `_rarityColor` with `CosmeticsPalette` |
| `lib/features/cosmetics/presentation/widgets/cosmetic_equipped_chip.dart` | 3 | Replaced `_rarityColor` + hardcoded radius 12 |
| `lib/features/cosmetics/presentation/widgets/cosmetic_frame_preview.dart` | 3 | Replaced `_gradientColors` with `CosmeticsPalette` palette |
| `lib/features/cosmetics/presentation/cosmetics_screen.dart` | 3 | `_rarityColor` uses `FtTokens.difficulty*`; `foregroundColor: FtTokens.bg` |
| `lib/features/home/presentation/ft_overview_screen.dart` | 3 | `FtTokens.danger` + `context.ft.surfaceSubtle` |
| 37 files across features + shared | 7 | `fontSize: N` literals replaced with `FtTokens.fontSizeXxx` constants |
