# lib/models/ Migration Plan

## Summary

`lib/models/` contains **3 files**. All are pure-Dart value objects with no
external feature imports. The migration is straightforward and low-risk.

| File | Current path | Proposed target | Confidence |
|---|---|---|---|
| `selected_period.dart` | `lib/models/selected_period.dart` | `lib/shared/selected_period.dart` | **Medium** — see note |
| `weight_card_data.dart` | `lib/models/weight_card_data.dart` | `lib/features/health_connect/domain/weight_card_data.dart` | **High** |
| `sync_record.dart` | `lib/models/sync_record.dart` | _Delete or defer_ — dead code | **High** |

---

## File-by-file analysis

### 1. `selected_period.dart`

**Contents:** `PeriodType` enum + `SelectedPeriod` immutable value object.
Represents a navigable date range (day / week / month / custom) with `start`,
`end`, `forward()`, `backward()`, and `withType()` helpers.

**Dependencies:** `package:flutter/foundation.dart` (`@immutable`) only.

**Consumers (3 features):**

| Importer | Layer |
|---|---|
| `lib/features/health_connect/presentation/ft_activities_screen.dart` | presentation |
| `lib/features/home/presentation/ft_overview_screen.dart` | presentation |
| `lib/features/nutrition/presentation/ft_nutrition_screen.dart` | presentation |

Also imported by `weight_card_data.dart` (see below).

**Why not a feature domain:** Three separate features import it — putting it in
any single feature's `domain/` would force the other two to cross feature
boundaries at the domain layer, which the architecture rules prohibit.

**Proposed target:** `lib/shared/selected_period.dart`

> No `lib/shared/domain/` subfolder exists yet. Because this is the only
> cross-feature model, placing it directly in `lib/shared/` keeps things
> simple. If more shared domain objects accumulate, a `lib/shared/domain/`
> subfolder is the natural next step.

**Confidence: Medium.** The file is genuinely shared, but `SelectedPeriod` is
also deeply tied to the "period navigation" UI pattern that the home/health/
nutrition screens share. An alternative would be to introduce a small
`lib/features/home/` domain layer that owns it (since `home` is the top-level
aggregator screen), and have health_connect and nutrition import from
`home/application/` via a public re-export. That coupling is less clean than
`shared/`, so `lib/shared/` is the recommended path.

**Import path change example** (from a feature screen 3 levels deep):
- Before: `'../../../models/selected_period.dart'`
- After: `'../../../shared/selected_period.dart'`

---

### 2. `weight_card_data.dart`

**Contents:** `WeightChartMode` enum, `WeightChartPoint` value object,
`WeightCardData` view-model. All relate to displaying body-weight data in the
weight card widget.

**Dependencies:** `package:flutter/foundation.dart` + `models/selected_period.dart`.

**Consumers (4 files, all inside `health_connect`):**

| Importer | Layer |
|---|---|
| `lib/features/health_connect/application/fitness_provider.dart` | application |
| `lib/features/health_connect/application/fitness_provider/fitness_queries.dart` | application |
| `lib/features/health_connect/presentation/body/widgets/body_cards.dart` | presentation |
| `lib/features/health_connect/presentation/ft_body_screen.dart` | presentation |

**Proposed target:** `lib/features/health_connect/domain/weight_card_data.dart`

After the move, its `selected_period.dart` import becomes:
`'../../../shared/selected_period.dart'` (domain → lib/ → shared/).

**Confidence: High.** Exclusively owned by health_connect; both the application
layer (queries, provider) and the presentation layer (card widget, body screen)
use it. The data is body-weight metrics — solidly health_connect domain.

**Note on layer classification:** `WeightCardData` is more of a presentation
view-model (assembled from raw data for the UI) than a pure domain entity.
Placing it in `domain/` is acceptable here because it has no Flutter widget
imports and is consumed by the application layer. If a stricter separation is
desired later, a `lib/features/health_connect/application/weight_card_data.dart`
location would work too, since `application/` is allowed to define view-models
consumed by `presentation/`.

---

### 3. `sync_record.dart`

**Contents:** `SyncStatus` enum (`idle`, `running`, `success`, `error`) +
`SyncRecord` value object (`timestamp`, `status`, `rowsSynced`, `errorMessage`).

**Dependencies:** None.

**Consumers:** **Zero.** `SyncRecord` and `SyncStatus` are not imported or
referenced anywhere in `lib/` or `test/`. This is dead code.

**Recommendation:** **Delete before migrating.** Moving an unused file would
add noise with no benefit. If a sync status model is needed in the future, the
naming pattern (`rowsSynced`) suggests it was originally intended for the
Sheets export pipeline or KT sync — create it in the appropriate feature at
that time.

If deletion is not desired now, the most likely future home would be
`lib/features/sheets_export/domain/` (sheets export is the only feature that
explicitly tracks "rows synced").

**Confidence: High** (that it is dead code and should be deleted).

---

## Dependency graph after migration

```
lib/shared/selected_period.dart
    ↑ imported by
    ├── lib/features/health_connect/presentation/ft_activities_screen.dart
    ├── lib/features/home/presentation/ft_overview_screen.dart
    ├── lib/features/nutrition/presentation/ft_nutrition_screen.dart
    └── lib/features/health_connect/domain/weight_card_data.dart
            ↑ imported by
            ├── lib/features/health_connect/application/fitness_provider.dart
            ├── lib/features/health_connect/application/fitness_provider/fitness_queries.dart
            ├── lib/features/health_connect/presentation/body/widgets/body_cards.dart
            └── lib/features/health_connect/presentation/ft_body_screen.dart
```

No circular dependencies. `shared/` is a leaf — it imports nothing from
`features/`.

---

## Circular dependency risks

**None** for this migration. All flows are unidirectional:

- `shared/` ← feature presentation / feature domain
- feature `domain/` ← feature `application/` ← feature `presentation/`

The only risk to watch: if `weight_card_data.dart` were placed in
`health_connect/presentation/` instead of `domain/`, the application layer
(`fitness_queries.dart`) would import from presentation — that would violate
the layer ordering. Keeping it in `domain/` avoids this.

---

## Execution order

1. Delete `sync_record.dart` (confirm with user first).
2. Move `selected_period.dart` → `lib/shared/selected_period.dart`.
   Update imports in: `ft_activities_screen.dart`, `ft_overview_screen.dart`,
   `ft_nutrition_screen.dart`, `weight_card_data.dart` (4 files).
3. Move `weight_card_data.dart` → `lib/features/health_connect/domain/weight_card_data.dart`.
   Update its `selected_period` import + update 4 health_connect consumers.
4. Verify `lib/models/` is empty, remove directory.
5. Run `flutter analyze` + `flutter test`.

---

## Architecture doc status

After this migration, `lib/models/` will be removed and the architecture
migration table can be updated to mark it **Done**.
