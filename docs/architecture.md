# Forgetrack – Architecture Guide

This is the durable reference for how Forgetrack is organised. Day-to-day
working agreements live in [../CLAUDE.md](../CLAUDE.md); this document
describes the structure, layering, dependency rules, and design-system
foundations that those agreements assume.

---

## Directory layout

```
lib/
  app/                      # App bootstrap wiring (providers, lifecycle, root widget)
  core/                     # Cross-feature technical infrastructure
    config/                 # Environment constants, feature flags
    errors/                 # AppError sealed hierarchy + Firebase / KT classifiers
    logging/                # AppLog, logging setup
    navigation/             # Navigator key, route helpers
    result/                 # Sealed Result<T, E> + Success / Failure
    services/               # Platform services with no single-feature owner
    storage/                # Generic local persistence helpers
    utils/                  # Pure, stateless utility functions
  domain/                   # Cross-aggregate domain layer (pure Dart, no Flutter/I/O)
    journal/                # JournalEvent sealed hierarchy + JournalProjection<T>
                            #   + EventKey / PeriodKey value objects
    player/                 # Player aggregate root + LevelCurve policy
    progression/
      catalog/              # ProgressionEntryId family + EngineEvaluationContext
                            #   + LedgerCounters + EvaluationOverrides
      player/               # Per-aggregate sealed lifecycles + read projections
                            #   (PlayerQuestLifecycle, PlayerQuestCatalog,
                            #   PlayerAchievementLifecycle, PlayerAchievementShelf,
                            #   ChapterLifecycle, PlayerChapterProgress)
  features/                 # One subfolder per product feature
    <feature>/
      application/          # Providers / state notifiers; orchestrate domain + data
      data/                 # Repositories, data sources, API/database adapters
      domain/               # Feature-internal entities, value objects, repository interfaces
      presentation/         # Screens, widgets, navigation wired to this feature
  shared/
    branding/               # App logo, splash, identity assets
    extensions/             # Dart extension methods used across features
    formatters/             # Date, number, unit formatters with no feature owner
    theme/                  # AppTheme, design tokens, time palette
    widgets/                # Reusable widgets with no feature owner (e.g. PlainCard)
  l10n/                     # ARB files and generated localizations
  firebase_options.dart
  main.dart
```

### Domain layer (`lib/domain/`)

Cross-aggregate doménové typy žijí v `lib/domain/`, ne v jednotlivých feature složkách. Patří sem aggregaty / value objects / sealed lifecycles, které se chovají jako cross-cutting kontrakt (Player level/XP, Journal event log, per-aggregate lifecycles read by both progression engine and UI).

Hard rule: **`lib/domain/` se musí dát kompilovat bez Flutter SDK**. Žádný `package:flutter/`, `package:provider/`, `package:firebase_*/`, `package:isar/`, `package:health/`, `package:shared_preferences/`. Vynuceno [`test/domain_purity_test.dart`](../test/domain_purity_test.dart) — strict ratchet (any violation fails the test suite). Feature-internal `lib/features/<f>/domain/` má volnější ratchet (numeric baseline, gradual cleanup).

Per-aggregate convention (proposal §2):

- **Sealed catalog row** (e.g. `ProgressionEntry`, `Cosmetic`) — immutable definition data with subtypes for each kind.
- **Player-side aggregate** (e.g. `Player`, `Inventory`, `EmblemBoard`, `GoalBoard`) — per-user state, immutable VO.
- **Sealed lifecycle** (e.g. `PlayerQuestLifecycle`, `PlayerAchievementLifecycle`, `PlayerCosmeticLifecycle`, `ChapterLifecycle`) — exhaustive states each aggregate can be in; pattern-matched at every consumer (compile-time `switch` exhaustiveness for Dart 3 sealed types).
- **Read projection** (e.g. `PlayerQuestCatalog`, `PlayerAchievementShelf`, `PlayerChapterProgress`) — immutable snapshot built by `ProgressionEngineProvider` once per evaluation; widgets read from the snapshot, never derive lifecycle inline.

Cross-feature pure-Dart types (consumed by two or more features and free of Flutter / feature-internal imports) live under named subfolders of `lib/domain/` — e.g. `lib/domain/cosmetics/cosmetic_region.dart` houses the `CosmeticRegion` enum referenced both by cosmetic catalog rows and (transitively) by the progression engine's companion availability nodes.

For shared **data**, the preferred pattern is *single ownership with derivation* — pick the feature that most naturally owns the data, enrich its catalog row with whatever cross-feature fields are needed, and have the other feature derive its shape from that catalog. The companion catalog is the worked example: `Companion` rows in `lib/features/cosmetics/domain/cosmetic_catalog.dart` carry the level + item gate + audit `sourceId`, and `lib/features/progression_engine/domain/catalog/content/companions_content.dart` derives `CompanionAvailability` nodes from them. This is preferred over introducing a separate "spec" model that all consumers derive from — a parallel spec just relocates the drift opportunity (rarity in catalog vs rarity in spec) instead of removing it. See ADR `companion-catalog-canonical`.

Typed identifiers (proposal §3.b, ADR `typed-identifiers`): catalog row ids use Dart 3 extension types declared `implements String` — `QuestId`, `AchievementId`, `MilestoneId`, `ChapterId`, `ObjectiveId`, `CosmeticId`, `ProgressionEntryId`, `EventKey`, `PeriodKey`. Zero runtime cost; compiler refuses construction from raw String at authoring sites, but typed ids auto-coerce into String parameters (so consumer code doesn't cascade-rewrite).

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
| `auth/` | Sign-in, sign-out, session state, `AuthProvider`, `Identity` value object |
| `health_connect/` | Steps, sleep, body weight, activities; `FitnessProvider`; Health Connect adapter; `GoalBoard` + `PlayerGoal` |
| `nutrition/` | Kaloricke Tabulky sync, calorie + macro tracking; `KalorickeTabulkyProvider`; `NutritionSnapshot` |
| `progression_engine/` | V2 progression engine — sealed `ProgressionEntry` catalog, `ProgressionEngineProvider`, evaluator + reward planner, hybrid Isar+Firestore ledger repository. See [progression_engine/README.md](../lib/features/progression_engine/README.md). |
| `journey/` | Hero journey map, chapter/node display |
| `celebration/` | Reward celebration screens and orchestration |
| `cosmetics/` | Sealed `Cosmetic` catalog (7 subtypes), `Inventory`, `Loadout`, `EmblemBoard` |
| `coach_log_export/` | Bushido / coach log Sheets export — see [features/coach_log_export.md](features/coach_log_export.md) |
| `sheets_export/` | Raw Google Sheets date-merge export pipeline |
| `social/` | `SocialPresence` aggregate (friends, friendships, requests, shares, notifications); Firestore backend |
| `home/` | `OverviewScreen` — main dashboard |
| `settings/` | `SettingsScreen` and all settings sections/widgets/dialogs |
| `app_shell/` | `MainShell` — root shell with page controller, bottom nav, top chrome |
| `onboarding/` | First-run flow |
| `devtools/` | Debug panels, internal diagnostics; never shipped to users |

> The V1 `lib/features/progression/` module was deleted in Phase 22 of the doménový refactor (commit `20f7ea7`, 2026-05-19). All reads + writes now route through the V2 engine.

---

## Dependency rules

These rules are hard constraints. Static analysis catches most violations
indirectly through import errors, but a few — especially the
shared→features and application→presentation ones — must be enforced by
review.

1. **`shared/` must not import `features/*`.**
   Shared widgets receive data through constructor parameters. If a
   widget needs `AuthProvider` / `FitnessProvider` / etc., keep it inside
   the relevant feature or pass plain values into it.

2. **`application/` must not import `presentation/`.**
   Providers and use-cases cannot depend on UI files. If a provider is
   currently in `presentation/`, move it to `application/`.

3. **`domain/` must stay pure.**
   No Flutter widgets, `BuildContext`, `Provider`, Firebase, Isar, HTTP,
   `SharedPreferences`, or UI imports. Domain models and logic should be
   testable without Flutter.

4. **`data/` can depend on `domain/`, not on `presentation/`.**
   Data layer handles APIs, DB, parsing, persistence. It must not call
   UI or provider methods directly.

5. **`presentation/` can read providers and build UI.**
   UI can use `context.watch` / `read` / `select`. Keep heavy logic out
   of widgets; move it to provider / query / helper classes.

6. **`core/` is not a god layer.**
   `core/services` may orchestrate cross-cutting work like background
   sync, notifications, logging. If business logic grows there, split it
   into feature-specific services / providers.

7. **No reintroducing legacy top-level folders.**
   `lib/screens/`, `lib/providers/`, `lib/models/`, `lib/services/`,
   `lib/widgets/`, `lib/theme/` are all retired. Use feature-first paths
   instead. Their original homes:

   | Legacy folder | Migrated to |
   |---|---|
   | `lib/screens/` | `lib/features/*/presentation/` |
   | `lib/services/` | `lib/core/services/` |
   | `lib/theme/` | `lib/shared/theme/` |
   | `lib/widgets/` | `lib/shared/widgets/` |
   | `lib/providers/` | `lib/app/` (`locale_provider`) or `lib/features/*/application/` |
   | `lib/models/` | `lib/shared/` (cross-feature value objects) or `lib/features/*/domain/` |

8. **`devtools/` may import anything** — it is a debug-only feature
   and is gated by `kDebugMode` / developer UID allowlist.

### Cross-feature presentation imports

Cross-feature imports between feature `presentation/` layers are a smell
and should be removed when found. The current accepted exception:

- `social/` imports `progression/l10n/progression_l10n.dart` (and reads
  progression labels for level / XP / achievement names). L10n is a
  shared concern; copying the strings would be worse.

---

## Shared vs. feature code

**Use `shared/`** when a widget, formatter, or extension has no single
owning feature and is used by three or more features. Examples:
`PlainCard`, `ScreenHeader`, `TinyPill`, date formatters.

**Keep it in the feature** when it is only used within that feature,
even if it looks generic. Premature promotion to `shared/` creates
coupling without benefit.

## Core vs. feature services

**Use `core/`** for technical infrastructure that has no domain meaning:
logging (`AppLog`), the global navigator key, generic storage helpers,
typed errors.

**Keep it in the feature** when a service encapsulates domain rules for
one feature (e.g. `HealthConnectService` in `health_connect/data/`).

---

## Design system & theming

### Tokens

All design values live in `lib/shared/theme/`:

- `FtThemeTokens` — full palette + typography exposed as a Flutter
  `ThemeExtension`. Accessed in widgets via `context.tokens`.
- `FtTokens` — static constants for compile-time use (painters, static
  contexts, const expressions): spacing, radius, font sizes, semantic
  colors (`success`, `warning`, `danger`, `xp`, `xpGlow`), achievement
  difficulty colors, rarity palette (`Rarity`).
- Per-domain palettes on `FtTokens` (`steps`, `calories`, `weight`,
  `sleep`, `active`, `protein`, `fat`, `carbs`) provide
  `color` / `dim` / `glow` / `gradStart` / `gradEnd` / `gradient` /
  `cardDecoration()`.

### Token usage rules

- `BorderRadius.circular(N)` is only allowed inside `FtTokens` or
  `AppTheme`; everywhere else use the token constant (`radiusCard`,
  `radiusInner`, `radiusTile`, `radiusButton`, `radiusIcon`,
  `radiusProgress`).
- Inline `BoxShadow` literals are forbidden in widget code; define named
  shadows in tokens.
- Avoid `Colors.white` / `Colors.black` with `.withValues(alpha:…)` —
  use `FtTokens.onSurface` / `onSurfaceMuted` / `onSurfaceFaint`.
- Spacing literals (4, 8, 12, 16, 20, 24, 32) must use the
  `FtTokens.space*` constants. Value `10` has no token — it is a known
  gap pending a design decision (normalize to 8 or 12).
- `fontSize:` literals use `FtTokens.fontSize{Tiny,Micro,Caption,Small,Body,Title}`.
- When migrating hardcoded literals to tokens, only replace when the
  token value is identical or visually equivalent. Never change alpha
  while migrating.

### Naming

- Shared design-system widgets live in `shared/widgets/` without an `Ft`
  prefix (e.g. `PlainCard`, `ScreenHeader`, `TinyPill`, `StatCard`).
- Feature-internal private widgets stay in
  `features/<feature>/presentation/widgets/`.
- One primary public class per file; file name must match it
  (snake_case of class name).
- No generic bag files (`helpers.dart`, `shared.dart`, `utils.dart`) —
  name by responsibility.

---

## Health Connect rules

- Treat Health Connect as the external source of truth. Never delete or
  modify user Health Connect data. Local cache may be cleared.
- Do not overwrite valid cached DB data with empty lists after partial
  Health Connect failures.
- Quota errors must preserve DB state and not stamp `lastSyncedAt` as
  successful.
- For range refreshes, use inclusive UI range but **exclusive query
  end**:
  - `start = selected start day 00:00`
  - `endExclusive = selected end day + 1 day`
- After fetching, filter records back to the selected inclusive range
  before saving.
- Be careful with `DateTime` local vs UTC boundaries.

## KT (Kalorické Tabulky) nutrition rules

- Avoid repeated `getRange()` / `avgField()` spam from `build()`
  methods. Compute one range summary once and reuse it in UI.
- Today can legitimately be zero just after midnight if no food is
  logged yet.
- Do not let a past-range refresh accidentally overwrite today's
  provider state with stale or empty values.
- Keep cached data available even if API sync fails.
- HTTP API reference: [integrations/kt_api_reference.md](integrations/kt_api_reference.md).

## Progression rules

- Progression evaluates from provider / DB state, not directly from UI
  widgets.
- Be careful with "today" after midnight — if the current day has no
  nutrition yet, daily nutrition quests will show 0.
- Avoid evaluating progression repeatedly during every rebuild. Prefer
  explicit refresh / recalc triggers or debounced provider-level
  updates.
- Rewards must be idempotent; reward grants use deterministic keys.
- Achievement unlocks are durable events, not recomputed UI-only state.
- The V2 engine writes through to Firestore — see
  [features/firestore_sync.md](features/firestore_sync.md).

---

## DevTools

- DevTools is gated by `kDebugMode` or an explicit developer UID
  allowlist.
- May inspect provider state, DB / cache state, sync history, background
  refresh and notifications.
- Debug actions that mutate real app state require confirmation.
- Debug overrides must not affect production calculations unless
  explicitly requested and safely gated.

## Logging

Use `AppLog` from `lib/core/app_log.dart`. Do not use `print()`. Keep
logs structured and domain-scoped. AppLog levels, scopes, and gating are
documented in the user-level memory index — see
`memory/project_logging.md` if you need the detail.

---

## Adding a new feature

1. Create `lib/features/<name>/` with the four standard layers.
2. Put providers in `application/`, entities in `domain/`, data adapters
   in `data/`, screens in `presentation/`.
3. Register providers in `lib/main.dart` (or `lib/app/app_providers.dart`
   once that file exists).
4. Do not reach into another feature's `data/` or `domain/` directly —
   go through its `application/` layer.
