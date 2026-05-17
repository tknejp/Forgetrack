# Configuration system — design plan

Forgetrack today has no unified configuration story. Hardcoded constants,
per-feature `SharedPreferences` keys, and ad-hoc default values are
scattered across the codebase. This plan introduces three explicit
configuration layers, each with its own ownership model, persistence
strategy, and editing surface.

The plan is sequenced: foundation first, then the live remote-tunable
layer once the static values are tidied. No code changes happen until
this document is approved.

## Goals

1. **One source of truth** for every tunable value. No more "the default
   daily steps is 10 000" repeated in three files.
2. **Clear ownership** for every value: is it the developer's, the user's,
   or the operator's to change?
3. **Cross-device user settings** — goals set on one device follow the
   user to the next, the same way progression state already does.
4. **Live content toggles** — ship hidden cosmetics / quests / events
   in a release, flip them on later from a Firebase console without
   another release.
5. **Offline-first** at every layer. The app must boot, evaluate
   progression, and render content with no network access.
6. **Type-safe at every layer.** No stringly-typed lookups in feature
   code. A typo must fail to compile, not at runtime in a user session.

## Non-goals (this iteration)

- Per-user A/B testing via Firebase Remote Config conditions.
- Encrypted / signed remote payload.
- Hot-reloading remote config without an app restart (fetch on cold
  start + opportunistic background refresh is enough).
- A general-purpose admin web UI for editing values. The Firebase
  Remote Config console + a devtools inspector screen are sufficient.
- Forcing admin overrides on top of user settings (e.g. capping user
  calorie goal from a remote value). Out of scope; revisit only if a
  concrete compliance need surfaces.

## Three configuration layers

The system is split into three orthogonal layers. Each has a distinct
audience, persistence story, and change cadence. They do **not** live
behind a unified facade — three small focused APIs beat one polymorphic
one.

| Layer | Audience | Edits via | Persists in | Change cadence | Examples |
| --- | --- | --- | --- | --- | --- |
| `BuildConfig` | Developer | Source edit + release | Compiled into binary | Per release | Sheet tab names, API base URLs, app name |
| `UserSettings` | End user | In-app Settings UI | Isar (local) + Firestore user doc (sync) | User-driven, ad hoc | Daily steps goal, target weight, notification prefs, theme |
| `AdminConfig` | App operator (you) | Firebase Remote Config console | Firebase Remote Config cache (with compiled-in defaults) | Operator-driven, ad hoc | Content visibility flags, balance multipliers, event toggles |

The three layers are independent. A feature might consume from one,
two, or all three depending on what it does. There is no automatic
"override chain" between layers; a consumer that needs the union picks
its precedence explicitly (typically `admin_override ?? user_setting ??
build_default`).

## Layer 1 — `BuildConfig`

**Purpose:** values that are stable for the lifetime of a release and
have no reason to vary per user or per environment beyond debug/release.

**Surface area:** the existing [`AppConstants`](../../lib/core/config/constants.dart),
trimmed of values that belong elsewhere.

**Stays in `BuildConfig` after the cleanup:**

- `appName`, `appVersion`
- Sheet / tab names (`sheetsTitle`, `exportSheetName`, `coachLogSheetName`,
  `stepsSheet`, `activitiesSheet`, `caloriesSheet`)
- `exportDateColumn`
- `prefSpreadsheetId` (this is a *key*, not a tunable value)
- `foodApiBase`, `foodSearchPageSize`
- `defaultHistoryDays` (only because this is a fetch-window default
  used by services, not a user-facing knob — flag for review during audit)

**Moves out of `AppConstants`:**

- `dailyStepGoal`, `weeklyStepGoal`, `monthlyStepGoal` → `UserSettings`
  defaults
- `defaultCalorieGoal`, `defaultWeightGoal` → `UserSettings` defaults

**Action:** rename file/class to `BuildConfig`, group constants by
domain, delete the user-goal block. No new functionality, just a
renaming pass + a deletion. ~1 hour of work, no risk.

## Layer 2 — `UserSettings`

**Purpose:** per-user values the user controls through the app UI.
Persisted locally (offline-first) and synced across the user's
devices via Firestore.

### Current state

User goals already live in [`GoalsProvider`](../../lib/features/health_connect/application/goals_provider.dart) —
a 585-line `ChangeNotifier` that:

- Holds nine goal fields (steps, calories, protein, carbs, fat, fiber,
  sleep hours, weekly activity minutes, target weight).
- Persists each field to `SharedPreferences` under its own string key.
- Maintains per-field "goal history" (an `effectiveFrom`-keyed list of
  prior values) so progression evaluation can recompute past days
  against the goal value that was active *then*.
- Has **no Firestore sync** — goals set on device A do not appear on
  device B.
- Has heavy boilerplate: each setter is the same 7-line shape repeated
  nine times, and the history-load / migrate flow is hand-rolled per
  field.

Independent partial implementations of the same concept also exist:

- `EngineGoalSet` (in `EngineCatalogContext`) is a typed value object
  carrying the same nine fields — currently built from default constants
  because nothing wires it to `GoalsProvider`.
- Per-feature one-off prefs scattered across the codebase
  ([home_card_order_provider](../../lib/features/home/application/home_card_order_provider.dart),
  [pinned_emblems_store](../../lib/features/social/application/pinned_emblems_store.dart),
  [onboarding_provider](../../lib/features/onboarding/application/onboarding_provider.dart),
  notification preferences, ...). These are user settings in disguise;
  they should be consolidated under the same umbrella over time.

### Target shape

A single `UserSettings` subsystem that:

1. **Defines settings declaratively.** One file (`user_settings_keys.dart`)
   lists every setting as a typed key with its compiled-in default.
   Adding a setting = one line. Consumers read via the typed key, not
   a string.
2. **Persists locally to Isar** — not `SharedPreferences`. Isar gives
   us schema, indexing, and matches the existing storage stack used
   by progression. One `UserSettingsRecord` collection with one row
   per key (or, for the goal-history use case, one row per
   `(key, effectiveFrom)` pair).
3. **Syncs to Firestore** under `users/{uid}/settings/...`. Reuses
   the offline-first pattern from
   [`HybridProgressionRepository`](../../lib/features/progression/data/hybrid_progression_repository.dart):
   read from Isar (instant), write to Isar synchronously, then
   fire-and-forget to Firestore (offline SDK retries).
4. **Preserves goal history.** This is non-negotiable: progression
   evaluation depends on it. The new schema keeps the same shape
   (`effectiveFrom`-keyed entries) but stores it generically per key
   rather than as bespoke fields.
5. **Exposes a `UserSettingsProvider`** (`ChangeNotifier`) as the only
   read/write surface. `GoalsProvider` either becomes a thin typed view
   over `UserSettingsProvider`, or is fully replaced by it (decide
   during implementation based on call-site cost).
6. **Wires `EngineGoalSet`** to read from the provider, eliminating the
   triple-default problem ([constants.dart:35](../../lib/core/config/constants.dart#L35),
   [goals_provider.dart:25](../../lib/features/health_connect/application/goals_provider.dart#L25),
   [engine_catalog_context.dart:10](../../lib/features/progression_engine/domain/catalog/engine_catalog_context.dart#L10)
   all currently say "10 000" independently).

### Firestore schema

```text
users/{uid}/settings/{settingId}
  value:           <typed>
  updatedAt:       Timestamp
  history:         [ { effectiveFrom: Timestamp, value: <typed> }, ... ]   // optional, only for history-tracked settings
```

Last-write-wins on `updatedAt` for cross-device merge. History merge
unions entries by `effectiveFrom` (with the later `updatedAt` winning
on conflicts).

### Migration from `SharedPreferences`

One-shot on first launch of the new build:

1. Read every existing `SharedPreferences` goal key.
2. Write each into the new Isar table.
3. Set a migration flag (`prefs_migrated_to_user_settings = true`).
4. Leave the prefs entries in place (don't risk data loss on rollback);
   delete them in a follow-up release once the new path is proven.

## Layer 3 — `AdminConfig` (Firebase Remote Config)

**Purpose:** values you (the operator) want to change without shipping
a new release. The audience is *you*, not the user.

**Built on:** the [`firebase_remote_config`](https://pub.dev/packages/firebase_remote_config) package.

### Core principles

These six rules apply to every value that lives in `AdminConfig`:

1. **The default lives in the code.** Every `AdminConfig` key declares
   its default value in Dart. Remote merely overrides. Offline / first
   launch / Firebase down → app works on defaults.
2. **Hidden content defaults to `false`.** A new cosmetic shipped
   pre-built for a Christmas event has `content_xmas_2026_enabled =
   false` in code. Remote flips it to `true` on December 1. The reverse
   pattern (`default true`, remote disables) is forbidden — it leaves
   offline users showing seasonal content out of season.
3. **Fetch is non-blocking.** Cold start triggers a fetch with a short
   timeout. While the fetch is in flight, the app uses the cached
   previous values (or defaults on first ever launch).
4. **Type-safe keys.** A sealed `AdminConfigKey<T>` hierarchy:
   `AdminConfigBool`, `AdminConfigDouble`, `AdminConfigInt`,
   `AdminConfigString`. Consumers read with `adminConfig.get(MyKeys.x)`
   — the return type is `T`, no casting at the call site.
5. **Every key is registered in one place.** `admin_config_keys.dart`
   is the schema. The catalog validator (see "Catalog integration"
   below) verifies that every flag referenced by a cosmetic / objective
   is registered.
6. **A devtools inspector ships from day one.** A new section in the
   existing devtools screen lists every key, shows
   `default → remote → effective` for each, and offers "force refresh".
   Without this, debugging "did my flag change reach the device?"
   becomes a guessing game.

### Initial keys to ship

The first-wave audit ([audit.md](audit.md)) surfaced four families of
operator-tunable values already hardcoded today. The shipping order
follows the value/risk ratio: the cheapest, most-impactful knobs first.

**Family A — Single isolated tunables (Phase 5 day 1):**

| Key | Type | Default | Source today |
| --- | --- | --- | --- |
| `nutrition_tolerance_ratio` | double | 0.10 | [`nutrition_content.dart:19`](../../lib/features/progression_engine/domain/catalog/content/nutrition_content.dart#L19) |
| `daily_activity_target_minutes` | int | 30 | [`activity_content.dart:18`](../../lib/features/progression_engine/domain/catalog/content/activity_content.dart#L18) |
| `background_sync_interval_minutes` | int | 15 | [`background_sync_service.dart:36`](../../lib/core/services/background_sync_service.dart#L36) |
| `xp_event_multiplier` | double | 1.0 | (none yet — new) |

**Family B — Quest XP rewards (Phase 5 day 2-3):**

30+ values across `catalog/content/*.dart` (steps, nutrition, activity,
sleep, body, long-term milestones). Each is independently tunable.
Naming scheme: `xp_<quest_id>` (e.g. `xp_daily_steps_base`,
`xp_daily_steps_bonus`, `xp_long_term_steps_100k`). The catalog reads
`adminConfig.get(XpKeys.dailySteps)` instead of the inline literal.
Single search-replace pass through each content file.

**Family C — Level policy (Phase 5 day 3-4):**

11 parameters from [`level_policy.dart:12-21`](../../lib/features/progression_engine/domain/policy/level_policy.dart#L12-L21):
`baseDailyRewardXp`, `baseWeeklyRewardXp`, five `level<N>RewardMultiplier`
values, five `level<N>DaysToAdvance` values. Together they shape the
*entire* level progression curve. Shipping these as remote knobs is the
single biggest insurance policy for post-launch pacing changes.

**Family D — Content visibility flags (Phase 6, content-driven):**

| Key | Type | Default | Source today |
| --- | --- | --- | --- |
| `content_xmas_2026_enabled` | bool | false | (none yet — new) |
| `content_<event_id>_enabled` | bool | false | (per future event) |
| `content_<cosmetic_set>_enabled` | bool | false | (per future cosmetic drop) |

Added on demand. Each new hidden cosmetic or quest set defines its own
flag; the `CatalogValidator` ensures the flag is registered.

**Deliberately not migrated to AdminConfig:**

- `defaultHistoryDays` (Health Connect fetch window) and per-feature
  refresh intervals (5-minute app-open debounces) — these are stability
  parameters where the cost of "tune live and break sync" outweighs the
  benefit. Stay in `BuildConfig`.
- `prefSpreadsheetId` and other persistence keys — these aren't values,
  they're identifiers. `BuildConfig`.

### Catalog integration — hidden content

The reason `AdminConfig` exists (and the most user-visible payoff) is
the "ship hidden content, unlock later" pattern.

Add an optional `visibilityFlag` to content definitions:

```dart
CosmeticDefinition(
  id: 'frame_xmas_2026',
  // ...
  visibilityFlag: AdminConfigKeys.xmasCosmeticsEnabled,  // optional, null = always visible
)
```

The display layer filters the catalog: any definition whose
`visibilityFlag` resolves to `false` is hidden from cosmetics screens,
quest lists, and reveal celebrations. The progression engine itself
keeps full access to the catalog — unlock state is computed normally,
just not shown. This means flipping a flag off after launch does not
*destroy* an already-unlocked cosmetic; it just hides it again,
preserving inventory integrity.

The existing [`CatalogValidator`](../../lib/features/progression_engine/domain/catalog/catalog_validator.dart)
gains one check: every `visibilityFlag` referenced from the catalog
must exist in `AdminConfigKeys`. Broken references fail the build, same
as today for objective and reward ids.

## Decision matrix — where does a value belong?

Use this checklist whenever introducing a new tunable value:

1. **Does it vary per user?**
   - Yes → `UserSettings`.
   - No → continue.
2. **Do you want to change it between releases without shipping a new
   build?**
   - Yes → `AdminConfig`.
   - No → `BuildConfig`.

Worked examples:

- *"Default daily steps goal for a new user"* — varies per user
  (user can change it) → `UserSettings`, with the default declared on
  the key. (The *default itself* could also be made `AdminConfig`-tunable
  in a second iteration, so onboarding picks up a new default without a
  release. Defer until needed.)
- *"Nutrition macro tolerance ratio"* — does not vary per user, but you
  want to tune it from analytics → `AdminConfig`.
- *"Google Sheets tab name for coach log"* — does not vary per user,
  changing it would break existing exports anyway → `BuildConfig`.
- *"Christmas cosmetics enabled"* — does not vary per user, must flip
  without a release → `AdminConfig`.
- *"Notifications on/off"* — varies per user → `UserSettings`.
- *"Maximum allowed daily calorie goal"* (hypothetical safety cap) —
  out of scope; would require an admin-overrides-user mechanism we
  explicitly punted on.

## Developer ergonomics — how to consume config in feature code

The decision matrix tells you *where* a value belongs. This section
governs *how* a feature reads it. Without an explicit ergonomic
contract, each layer would grow its own access pattern and we would
end up with the same fragmentation in a new costume.

Six rules apply uniformly across all three layers:

1. **One import per layer.** When you need a `BuildConfig` value:
   `import 'package:forgetrack/core/config/build_config.dart'` and read
   `BuildConfig.x`. When you need a `UserSettings` value: read via the
   `UserSettingsProvider` from `Provider.of` / `context.read` /
   `context.watch`. When you need an `AdminConfig` value: read via the
   `AdminConfigProvider`. One canonical access path per layer, no
   alternates.
2. **Typed key per identifier.** No stringly-typed lookups in feature
   code: `userSettings.get(UserSettingsKeys.dailyStepsGoal)`, not
   `userSettings.get('daily_steps_goal')`. The key carries its own
   type; the return type is inferred. Typos fail to compile.
3. **Default lives next to the key.** Every key declares its
   compiled-in default on the same line as the key itself, not in a
   separate "defaults" file. `UserSettingsKey<int>('dailyStepsGoal',
   defaultValue: 10000)`. A value cannot exist without its default
   right beside it. This makes "what does the app do with no overrides
   anywhere?" answerable by reading one file per layer.
4. **Provider-injected, not global singleton.** `BuildConfig` is the
   one exception (it is a class of `static const` fields, no state).
   `UserSettingsProvider` and `AdminConfigProvider` are registered in
   `MultiProvider` and accessed through `context.read` / `watch`.
   Tests fake them through the same DI seam used everywhere else.
   No `getIt`, no top-level `userSettings` variable.
5. **Reads are O(1) and offline-safe.** Every read returns from an
   in-memory cache hydrated at startup. No `await` at the call site.
   `UserSettings` reads from the Isar mirror; `AdminConfig` reads from
   the Remote Config cache (or compiled-in default if the cache is
   empty). Network refreshes are background fire-and-forget and notify
   listeners — they do not block the read path. A consumer that asks
   for a value with no network, no prior fetch, and a fresh install
   still gets the compiled-in default — never `null`, never an
   exception.
6. **Refactoring playbook for migrating a hardcoded value.** For every
   tunable you discover in feature code: (a) classify it via the
   decision matrix; (b) add a typed key with its current value as the
   `defaultValue`; (c) replace the literal at every call site with the
   keyed read; (d) delete the original `const`. Done in a single
   commit per value family (e.g. "migrate all nutrition tolerances")
   so reviewers see the change end-to-end and rollback is one revert.

These rules apply to *every* tunable, including the ones that stay in
`BuildConfig`. Rule 1 (canonical import) and rule 4 (no globals beyond
`BuildConfig`) jointly mean a new contributor never has to guess where
a value lives — they grep the value name in the appropriate `*_keys.dart`
file.

## Target module layout

```text
lib/core/config/
  build_config.dart                  # renamed from constants.dart, trimmed
  user_settings/
    user_settings_keys.dart          # typed keys + defaults
    user_settings_provider.dart      # ChangeNotifier facade
    user_settings_record.dart        # Isar collection
    user_settings_local_store.dart   # Isar read/write
    user_settings_cloud_gateway.dart # Firestore read/write
    user_settings_repository.dart    # hybrid (mirrors HybridProgressionRepository)
  admin_config/
    admin_config_keys.dart           # typed keys + defaults
    admin_config_key.dart            # sealed AdminConfigKey<T>
    admin_config_source.dart         # firebase_remote_config wrapper
    admin_config_provider.dart       # ChangeNotifier, fetch on start
```

Dependencies between layers:

- `BuildConfig` depends on nothing.
- `UserSettings` may read `BuildConfig` for static defaults (rare).
- `AdminConfig` depends on nothing.
- Feature code may depend on all three; layers do not depend on each
  other.

## Migration plan — phased

Each phase is independently shippable and reversible. The user-stated
sequencing is followed: full hardcoded-value cleanup before
`AdminConfig` lands.

### Phase 0 — Approve this document (½ day)

Walk through with stakeholders (i.e. you). Open questions resolved.
ADRs drafted (see below).

### Phase 1 — `BuildConfig` rename + trim (½ day)

- Rename [`AppConstants`](../../lib/core/config/constants.dart) →
  `BuildConfig`. File moves to `lib/core/config/build_config.dart`.
- Group constants by domain section.
- Remove the user-goal block. Defaults move into the next phase's
  `UserSettingsKeys`.
- Update all imports.

No new functionality. Pure rename. `flutter analyze` + tests stay green.

### Phase 2 — Hardcoded-value audit (½–1 day to complete)

First-wave audit shipped: [audit.md](audit.md). Surfaced ~80 hardcoded
values across 18 files, classified into the three layers, with 11
duplicates flagged. The largest single concentration is the progression
catalog (XP rewards across 5 content files + 11 level-policy parameters).

**Known coverage gaps in the first-wave audit** (worth closing before
Phase 5 ships):

- Notification / FCM cadence in
  [`fcm_service.dart`](../../lib/core/services/fcm_service.dart) and
  [`notification_service.dart`](../../lib/core/services/notification_service.dart)
- Coach log export timing / window defaults in `coach_log_export/`
- Backfill window in
  [`backfill_config.dart`](../../lib/features/progression_engine/domain/backfill/backfill_config.dart)
- Social feature pagination / refresh intervals in `social/`
- Hybrid sync stale-duration constants (e.g. `_kStaleDuration` in
  [`hybrid_progression_repository.dart`](../../lib/features/progression/data/hybrid_progression_repository.dart))

**Critical reconciliation to handle during Phase 3** (surfaced by the
audit): the goal defaults are duplicated across three files (see
"Duplicate defaults across files" in audit.md), and at least one
duplicate is *not* identical — `targetWeight` is 75.0 in
`goals_provider.dart` but 70.0 in `EngineGoalSet`. The Phase 3 migration
must explicitly pick one canonical value per setting, not just relocate
all three independently.

### Phase 3 — `UserSettings` foundation (3-4 days)

- New module per the target layout.
- Migrate `GoalsProvider`'s nine goal fields first (highest-value
  consolidation, eliminates the triple-default problem and the
  copy-paste boilerplate).
- One-shot migration from `SharedPreferences` → Isar.
- Wire `EngineGoalSet` to read from `UserSettingsProvider`.
- Settings UI ([`SettingsGoalsSection`](../../lib/features/settings/presentation/sections/settings_goals_section.dart))
  rewires to the new provider.
- Goal-history semantics preserved.

Acceptance: changing daily steps on device A, opening app on device B
(same account), value matches. Progression evaluation against
historical days still uses the historical goal value.

### Phase 4 — Consolidate stragglers into `UserSettings` (2-3 days, optional / opportunistic)

Per the audit, move other per-user prefs into `UserSettings`:
notification preferences, home card order, pinned emblems, onboarding
flags, theme. Driven by audit, can be deferred or done one feature at
a time. Not blocking for Phase 5.

### Phase 5 — `AdminConfig` infrastructure (3-5 days)

- Add `firebase_remote_config` to `pubspec.yaml`.
- New module per the target layout. Typed keys, sealed key hierarchy,
  fetch-on-start, cached fallback.
- Wire the first batch of audit-identified values through `AdminConfig`
  (numeric tunables that consumers currently read as hardcoded
  constants — e.g. `_nutritionTol`).
- New devtools section showing default → remote → effective for every
  key + "force refresh" button.

Acceptance: change `nutrition_tolerance_ratio` in Firebase console,
trigger refresh from devtools, see value update in the inspector and
the next progression evaluation use the new value.

### Phase 6 — Content visibility integration (2 days)

- Add `visibilityFlag: AdminConfigKey<bool>?` to `CosmeticDefinition`
  and the analogous catalog entries.
- Display layer filters by flag (cosmetics screen, quest screens,
  reveal celebrations).
- `CatalogValidator` checks that every referenced flag is registered.
- Document the "pre-ship hidden content" workflow.

Acceptance: ship a release containing a cosmetic with `visibilityFlag:
xmasCosmeticsEnabled = false`. The cosmetic is invisible in-app. Flip
the flag on in Firebase console, force refresh; the cosmetic appears.
Flip it off again; the cosmetic disappears but inventory state for any
user who unlocked it is preserved.

## Open questions

1. **Should Phase 4 happen at all in this iteration?** Consolidating
   non-goal prefs is good hygiene but not required to deliver the
   user-stated value (hidden content + cross-device goal sync). Could
   be punted to a separate post-foundation cleanup.
2. **Isar vs. `SharedPreferences` for `UserSettings`?** Isar fits the
   existing storage stack, gives us schema, and matches the
   progression pattern. `SharedPreferences` would be a smaller diff.
   This plan picks Isar; revisit if implementation cost balloons.
3. **Firestore document layout — one doc per setting vs. one doc
   containing all settings?** One-doc-per-setting (the plan above)
   is more granular but means more reads on cold start. One-doc-all
   is cheaper to read but harder to evolve. Defer the call to
   implementation time.
4. **Should `BuildConfig` itself become `AdminConfig`-overridable for
   the values that are stable-but-could-theoretically-change**
   (e.g. `foodSearchPageSize`)? Default answer: no. If you ever want
   to tune one of these live, promote it to `AdminConfig` deliberately
   at that point.
5. **A/B testing readiness.** Firebase Remote Config supports per-user
   conditions (random buckets, country, app version). This plan
   ignores them. If/when an A/B test becomes a real requirement,
   `AdminConfig` can grow that capability — the key registration and
   consumer API stay unchanged.

## Architectural decisions to record (in `docs/site/data/decisions.json`)

After Phase 0 approval, add ADR entries for each of these:

1. **Three-layer config with no unified facade.** Context: every
   tunable has a different audience and persistence story. Decision:
   three separate APIs (`BuildConfig`, `UserSettings`, `AdminConfig`)
   rather than a polymorphic config service. Consequences: each layer
   stays simple; consumers pick their own precedence when combining.
   Alternatives considered: single `Config` facade with layered
   sources — rejected because the layers have incompatible semantics
   (sync model, ownership, change cadence).
2. **`UserSettings` syncs via Firestore.** Context: users have
   multiple devices; goals already feel like cross-device state.
   Decision: Isar-first with fire-and-forget Firestore sync, mirroring
   `HybridProgressionRepository`. Consequences: offline-first preserved;
   one more Firestore subcollection to manage; last-write-wins on
   `updatedAt`. Alternatives: local-only (rejected, breaks user
   expectation of "my app remembers me") or Firestore-first (rejected,
   would block UI on network on every read).
3. **`AdminConfig` is Firebase Remote Config with code-side defaults.**
   Context: need live-tunable values without losing offline support.
   Decision: defaults always declared in Dart; Remote Config only
   overrides. Consequences: app boots offline with sensible values;
   forgetting to declare a default fails at compile time; hidden
   content defaults to false. Alternatives: Firestore document
   (rejected, no built-in caching for this use case) or self-hosted
   config endpoint (rejected, infra cost not justified for a solo dev
   project).
4. **Hidden content defaults to false, remote enables.** Context:
   seasonal content shipped pre-release must not appear out of season
   for offline users. Decision: every `visibilityFlag` default is
   `false`; remote flips to `true` when the event is live; reverse
   pattern is forbidden. Consequences: a small bit of process
   discipline; eliminates an entire class of "Christmas content
   showing in March" bugs.

## Risks

- **Migration of goal history.** The history-tracking semantics in
  `GoalsProvider` are load-bearing for progression evaluation. The
  Phase 3 migration must preserve every existing history entry
  exactly. Test coverage for "past-day goal resolution" is the gate.
- **Firebase Remote Config quotas / refresh limits.** Free tier:
  fetch throttling defaults to 12 hours minimum between server calls
  in release builds. Devtools "force refresh" must use the explicit
  zero-throttle path. Document this so we don't lose hours wondering
  why a value isn't updating.
- **Catalog validator coupling.** Adding the `visibilityFlag` check
  in Phase 6 means a release that references an unregistered flag
  fails the build. Good outcome, but the failure mode must be loud.
