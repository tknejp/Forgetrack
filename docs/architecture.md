# Forgetrack – Architecture Guide

## Directory layout

```
lib/
  app/                      # App bootstrap wiring (providers, lifecycle, root widget)
  core/                     # Cross-feature technical infrastructure
    config/                 # Environment constants, feature flags
    errors/                 # Typed error hierarchy, result types
    logging/                # AppLog, logging setup
    navigation/             # Navigator key, route helpers
    services/               # Platform services with no single-feature owner
    storage/                # Generic local persistence helpers
    utils/                  # Pure, stateless utility functions
  features/                 # One subfolder per product feature
    <feature>/
      application/          # Providers / state notifiers; orchestrate domain + data
      data/                 # Repositories, data sources, API/database adapters
      domain/               # Entities, value objects, repository interfaces
      presentation/         # Screens, widgets, navigation wired to this feature
  shared/
    branding/               # App logo, splash, identity assets
    extensions/             # Dart extension methods used across features
    formatters/             # Date, number, unit formatters with no feature owner
    theme/                  # AppTheme, design tokens, time palette
    widgets/                # Reusable widgets with no feature owner (e.g. FtPlainCard)
  l10n/                     # ARB files and generated localizations
  firebase_options.dart
  main.dart
```

## Feature layer responsibilities

| Layer | What belongs here |
|---|---|
| `domain/` | Pure Dart: entities, value objects, repository interfaces. No Flutter, no I/O. |
| `data/` | Implements domain interfaces. Talks to Health Connect, Firestore, SQLite, REST APIs. |
| `application/` | `ChangeNotifier` / `Provider` classes that own UI-facing state. Calls domain + data. |
| `presentation/` | Screens, page widgets, dialogs, feature-specific sub-widgets. Reads from `application/`. |

## Feature index

| Feature folder | What it owns |
|---|---|
| `auth/` | Sign-in, sign-out, session state, `AuthProvider`, `AuthUser` |
| `health_connect/` | Steps, sleep, body weight, activities; `FitnessProvider`; Health Connect adapter |
| `nutrition/` | Kaloricke Tabulky sync, calorie + macro tracking; `KalorickeTabulkyProvider` |
| `progression/` | XP engine, quests, achievements, level policy; `ProgressionProvider` |
| `sheets_export/` | Google Sheets date-merge export pipeline; `SheetsExportProvider` |
| `social/` | Friends, leaderboard, push notifications; `SocialProvider`; Firestore backend |
| `home/` | `FtOverviewScreen` — main dashboard showing steps, calories, weight, sleep |
| `settings/` | `SettingsScreen` and all settings sections/widgets/dialogs |
| `app_shell/` | `FtMainShell` — root shell with page controller, bottom nav, top chrome |
| `devtools/` | Debug panels, internal diagnostics; never shipped to users |

## Shared vs. feature code

**Use `shared/`** when a widget, formatter, or extension has no single owning feature and is
used by three or more features. Examples: `FtPlainCard`, `FtScreenHeader`, date formatters.

**Keep it in the feature** when it is only used within that feature, even if it looks generic.
Premature promotion to `shared/` creates coupling without benefit.

## Core vs. feature services

**Use `core/`** for technical infrastructure that has no domain meaning: logging (`AppLog`),
the global navigator key, generic storage helpers, typed errors.

**Keep it in the feature** when a service encapsulates domain rules for one feature (e.g.
`HealthConnectService` in `health_connect/data/`).

## Legacy folders (being gradually emptied)

The following folders are legacy and should not receive new code. Existing code will be
migrated feature-by-feature as part of normal development, not a big-bang rewrite.

| Legacy folder | Migration target |
|---|---|
| `lib/screens/` | **Done** — all files moved to `lib/features/*/presentation/` |
| `lib/services/` | **Done** — moved to `lib/core/services/` |
| `lib/theme/` | **Done** — moved to `lib/shared/theme/` |
| `lib/widgets/` | **Done** — moved to `lib/shared/widgets/` |
| `lib/providers/` | **Done** — see table below |
| `lib/models/` | **Done** — see table below |

### Providers migration

| File | New location | Reason |
|---|---|---|
| `locale_provider.dart` | `lib/app/locale_provider.dart` | App-level locale state, no feature affinity |
| `goals_provider.dart` | `lib/features/health_connect/application/goals_provider.dart` | Manages health/activity/body/nutrition goals; majority of consumers are health_connect screens |

### Models migration

| File | New location | Reason |
|---|---|---|
| `selected_period.dart` | `lib/shared/selected_period.dart` | Cross-feature value object used by health_connect, home, and nutrition presentations |
| `weight_card_data.dart` | `lib/features/health_connect/domain/weight_card_data.dart` | Exclusively consumed by health_connect application and presentation layers |
| `sync_record.dart` | _Deleted_ — zero consumers (dead code) | |

## Adding a new feature

1. Create `lib/features/<name>/` with the four standard layers.
2. Put providers in `application/`, entities in `domain/`, data adapters in `data/`, screens in `presentation/`.
3. Register providers in `lib/app/app_providers.dart` (once that file exists; for now, `main.dart`).
4. Do not reach into another feature's `data/` or `domain/` directly — go through its `application/` layer.
