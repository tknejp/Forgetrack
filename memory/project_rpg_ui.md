---
name: RPG UI implementation
description: Forgetrack RPG dark-fantasy UI from handoff bundle — status, files, and integration notes
type: project
---

New RPG UI layer built from `claude design budle/` handoff. App is wired to use it now via `app.dart`.

**Why:** Design handoff with new dark RPG aesthetic — violet accent, domain-colored stat cards, XP bar, achievements. UI-first phase; no logic/data yet.

**How to apply:** When working on UI/screens, use the new FT layer. When adding real data logic back, wire providers into the FtXxx screens (not the old HomeScreen-based screens).

## File structure

**Tokens:**
- `lib/theme/ft_design_tokens.dart` — `FtTokens` (colors, radii, font sizes) + `FtDomain` (per-domain color sets: steps/calories/weight/sleep/active/protein/fat/carbs)

**Shared widgets (`lib/widgets/ft/`):**
- `ft_progress_bar.dart` — `FtProgressBar` (animated, glowing)
- `ft_stat_cell.dart` — `FtStatCell` (value + unit + label, centered)
- `ft_stat_card.dart` — `FtStatCard` (expandable card, badge/XP/trophy, progress bar) + `FtStatStat`
- `ft_tab_pill.dart` — `FtTabPill` (Day/Week/Month pill selector)
- `ft_date_nav.dart` — `FtDateNav` (prev/next date arrows)
- `ft_xp_bar.dart` — `FtXpBar` (RPG level bar, visual placeholder)
- `ft_screen_header.dart` — `FtScreenHeader` (greeting + sword avatar)
- `ft_plain_card.dart` — `FtPlainCard` (plain or domain-gradient card)
- `ft_activity_row.dart` — `FtActivityRow` (walking/strength row with XP)
- `ft_macro_row.dart` — `FtMacroRow` (macro progress row, red when over)
- `ft_trend_chart.dart` — `FtTrendChart` + `FtChartBar` (bar chart, today highlighted)

**Screens:**
- `lib/screens/ft_overview_screen.dart` — `FtOverviewScreen`
- `lib/screens/ft_activities_screen.dart` — `FtActivitiesScreen`
- `lib/screens/ft_nutrition_screen.dart` — `FtNutritionScreen`
- `lib/screens/ft_body_screen.dart` — `FtBodyScreen`
- `lib/screens/ft_main_shell.dart` — `FtMainShell` (shell + RPG bottom nav)

**Entry:** `lib/app.dart` → `home: const FtMainShell()`

## Old screens
Still exist and compile — `HomeScreen`, `ActivitiesScreen`, `NutritionScreen`, `BodyScreen` — kept for logic reintegration later.

## Mock data
All screens use hardcoded demo data. When real providers are ready, replace the `static const` lists/values in each screen with provider reads.
