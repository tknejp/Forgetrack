# Cosmetics feature

Cosmetic items (frames, relics, backgrounds, emblems, companions, title
flairs, map effects) — their catalog, per-user unlock state, and equipped
loadout. The feature owns its own data and exposes a single
`CosmeticsProvider` that hero / social / progression code can read from or
push unlocks into.

## Goal

* Single source of truth for cosmetic definitions (`CosmeticCatalog`).
* Deterministic, offline-first state model — unlocks and equipped slots are
  pure data; no animations or theming live here.
* Strict feature isolation: **`cosmetics` does not import from `progression`
  or `social`**. The dependency direction is the reverse — progression calls
  `cosmetics.unlock(...)` after a level/quest, hero/social screens read
  `cosmeticsProvider.state.equipped` to render frames and chips.
* Centralised config (`CosmeticsConfig`) — every tunable knob, asset path
  resolver, and flag lives there instead of being scattered.

## Why a separate feature?

Mixing cosmetic state into `progression` would couple two concerns that
evolve at different rates: progression is gameplay logic that fires unlocks,
cosmetics is presentation metadata + storage. Mixing into `social` would
force the social profile screen to own a domain it only wants to read.

Keeping cosmetics standalone means the unlock plumbing has one obvious owner,
the catalog can grow independently of gameplay, and a future feature
(`shop`, `events`, etc.) can grant unlocks via the same single API.

## Current implementation

* Isar-backed local repository (`IsarCosmeticsRepository`). State persists
  across app restarts. Two collections: `CosmeticsUserStateRecord` (one row
  per uid with equipped slot ids) and `CosmeticsUnlockRecord` (one row per
  `(uid, cosmeticId)` pair with audit fields). The in-memory implementation
  is kept for tests.
* Catalog ships with six seed definitions: `frame_pilgrim`,
  `relic_old_compass`, `background_forest_trail`, `emblem_forest_mark`,
  `frame_ruined_bronze`, `relic_old_gate_key`.
* Default unlocks for every fresh user: `frame_pilgrim`,
  `relic_old_compass`, `background_forest_trail`. Seeded into Isar on first
  load for a uid.
* No real artwork yet — widgets render rarity-coloured placeholders when an
  asset file is missing.
* L10n entries for the six seed cosmetics live in `lib/l10n/app_*.arb`.
  Resolve them via `CosmeticsL10n(AppLocalizations.of(context))` and pass
  the helper into `CosmeticEquippedChip` / `CosmeticCollectionTile`.
  Without the helper widgets fall back to `definition.id` so debug builds
  stay readable.
* `CosmeticsProvider` is wired via
  `ChangeNotifierProxyProvider<AuthProvider, CosmeticsProvider>` in
  `main.dart`. `bindUser(auth.user?.id)` fires on every auth notification;
  state is loaded once per uid and cleared on sign-out.

## Folder structure

```
lib/features/cosmetics/
├── domain/
│   ├── cosmetic_models.dart       # enums + immutable data classes
│   ├── cosmetic_catalog.dart      # static seed definitions + helpers
│   └── cosmetic_unlock_rules.dart # baseline unlock set
├── data/
│   ├── cosmetics_repository.dart           # abstract persistence interface
│   ├── in_memory_cosmetics_repository.dart # test/dev implementation
│   ├── isar_cosmetics_repository.dart      # production local persistence
│   └── local/
│       ├── cosmetics_database.dart         # Isar instance owner
│       └── cosmetics_local_models.dart     # @Collection records (+ .g.dart)
├── application/
│   ├── cosmetics_service.dart  # business layer (no Flutter dependency)
│   └── cosmetics_provider.dart # ChangeNotifier for UI binding
├── config/
│   └── cosmetics_config.dart   # asset resolver, slots, flags, validation
├── presentation/
│   ├── cosmetics_l10n.dart     # id-based localiser (name / description / badge)
│   └── widgets/
│       ├── cosmetic_frame_preview.dart
│       ├── cosmetic_equipped_chip.dart
│       └── cosmetic_collection_tile.dart
└── README.md (this file)
```

## Domain model

| Type                 | Purpose                                                |
| -------------------- | ------------------------------------------------------ |
| `CosmeticType`       | enum — frame / relic / background / emblem / companion / titleFlair / mapEffect |
| `CosmeticRarity`     | enum — common / rare / epic / legendary               |
| `CosmeticRegion`     | enum — narrative region (forestTrail, ruinedPass, …)  |
| `CosmeticUnlockSource` | enum — defaultBaseline, progressionLevel, achievement, quest, manual, promotional, other (open-set; sourceType on records is a free string) |
| `CosmeticDefinition` | static metadata for one cosmetic — id, type, rarity, region, l10n keys, asset keys, flags, `metadata` bag |
| `UnlockedCosmetic`   | per-user unlock record — id, timestamp, source        |
| `EquippedCosmetics`  | snapshot of equipped slots; one nullable id per slot  |
| `UserCosmeticsState` | uid + unlocked map + equipped + updatedAt             |
| `CanEquipResult`     | `{ok, reason}` for non-throwing UI checks             |
| `CosmeticsException` | typed exception with stable `code` + human `message`  |

`UserCosmeticsState` is **immutable** — every mutation produces a new value.
Provider listeners always see a stable snapshot.

## Catalog

`CosmeticCatalog` is a stateless wrapper over a `static const` list of
definitions. Helpers:

* `all` — every definition.
* `byId(id)` — nullable lookup.
* `byType(type)` — definitions for one slot.
* `byRegion(region)` — definitions tagged for one region.
* `enabled` — only `isEnabled = true` definitions.
* `validate()` — list of warning strings; empty = healthy. Checks duplicate
  ids, empty l10n keys, malformed asset keys.

## Config

`CosmeticsConfig` (use `CosmeticsConfig.standard()` for production wiring):

* `resolveAssetPath(assetKey)` — maps `cosmetics.frames.pilgrim` →
  `assets/cosmetics/frames/pilgrim.png`. Returns null on unknown bucket; UI
  must handle null with a placeholder.
* `defaultEquipped` — slots equipped on a fresh user (defaults to nothing
  equipped).
* `allowedSlots` — set of `CosmeticType` users can equip in. `mapEffect`
  is opt-in via `experimentalTypesEnabled`.
* `rarityDisplayOrder`, `regionDisplayOrder` — for sorted UI lists.
* `premiumEnabled`, `experimentalTypesEnabled` — feature flags.
* `isUsable(definition)` — `isEnabled && (premiumEnabled || !isPremium) &&
  slot allowed`.
* `validate(catalog)` — list of warnings (e.g. `defaultEquipped` pointing at
  unknown ids).

## Unlock flow

```
caller (progression / quest / manual)
        │
        ▼
cosmeticsProvider.unlock(id, sourceType, sourceId)
        │
        ▼
CosmeticsService.unlock → repository.unlockCosmetic
        │
        ├── catalog lookup (throws cosmetic_not_found / cosmetic_disabled)
        └── adds UnlockedCosmetic to state.unlocked, bumps updatedAt
        │
        ▼
provider notifies listeners
```

## Equip flow

```
UI tap
   │
   ▼
cosmeticsProvider.equip(cosmeticId)
   │
   ▼
CosmeticsService.equip → repository.equipCosmetic
   │
   ├── catalog lookup
   ├── isEnabled check
   ├── type matches slot
   ├── slot allowed by config (allowedSlots / experimentalTypesEnabled)
   ├── cosmetic is in state.unlocked
   │     → throws CosmeticsException with stable code on any failure
   └── updates state.equipped via copyWithSlot, bumps updatedAt
   │
   ▼
provider notifies listeners
```

For non-throwing pre-checks (e.g. greying out a tile in a grid), use
`service.canEquip(state, id)` → `CanEquipResult`.

## How to add a new cosmetic

1. Append a `CosmeticDefinition` to `CosmeticCatalog.definitions` with a
   unique `id` and the right `type` / `rarity` / `region`.
2. Add the artwork file under
   `assets/cosmetics/<bucket>/<id-without-prefix>.png` (see
   `assets/cosmetics/README.md` for naming and sizing). The cosmetic will
   render a placeholder until the file ships.
3. Add the localisation keys (`<id>.name`, `<id>.description`,
   optional `<id>.unlock_hint`) to the `.arb` files when l10n wiring lands.
4. Run `CosmeticCatalog().validate()` in a debug session to confirm no
   warnings.

## How to add a new cosmetic type

1. Add a case to the `CosmeticType` enum in `cosmetic_models.dart`.
2. Add a corresponding nullable id field to `EquippedCosmetics`, plus a
   branch in `slotId` and `copyWithSlot`.
3. Add the type to `CosmeticsConfig.standard()`'s `allowedSlots` (or gate
   it behind a flag like `mapEffect`).
4. Extend `CosmeticsConfig._bucketFolder` with the asset folder name.
5. Add an icon for the type in `CosmeticEquippedChip._iconForType`.
6. Add the asset folder under `assets/cosmetics/<bucket>/` and declare it
   in `pubspec.yaml`.

## Progression integration

Wired as of step 4. `progression` owns the mapping and the dispatch; this
feature just exposes `CosmeticsProvider.unlock(...)` and stays unaware.

* Mapping table:
  `lib/features/progression/domain/cosmetic_reward_table.dart` — two const
  maps, one keyed by achievement id, one keyed by player level. Adding a
  reward = appending to the right map.
* Dispatcher:
  `lib/features/progression/application/cosmetic_unlock_dispatcher.dart` —
  diffs `previous` vs `current` `ProgressionEngineState` after each
  `engine.sync()` and calls `cosmeticsProvider.unlock(...)` for any newly
  unlocked achievement or level transition.
* Wiring: `ProgressionProvider.bind(..., cosmeticsProvider: ...)` plumbs
  the cosmetics provider in; `main.dart` uses
  `ChangeNotifierProxyProvider4` to inject `CosmeticsProvider` into
  `ProgressionProvider`.
* Logs: `[COSMETICS][dispatch]` and `[COSMETICS][provider]` scopes; every
  unlock attempt, no-op (already unlocked), rejection, and crash is logged
  via `AppLog`.

Idempotence: `cosmetics.unlock` is a no-op if the cosmetic is already
unlocked, so re-running a sync that produced no state change is harmless.

Backfill: only deltas after the first hydrate are dispatched. Pre-existing
unlocked achievements from before this version shipped do **not**
retroactively grant cosmetics — add a one-shot migration if that becomes
desirable. `cosmetic_unlock_rules.dart` (in cosmetics domain) is the right
file to grow into a richer "rule engine" if the mapping should ever live
inside cosmetics instead.

## Future: social / hero UI integration

Hero and social screens read equipped cosmetics through the provider:

```dart
final state = context.watch<CosmeticsProvider>().state;
if (state == null) return const SizedBox.shrink();
final service = context.read<CosmeticsProvider>().service;
final equipped = service.getEquippedDefinitions(state);
```

Wrap an avatar with `CosmeticFramePreview(definition: equippedFrame, child: avatar)`,
or render a row of `CosmeticEquippedChip` widgets on the profile page. None
of those widgets reach back into `social` or `progression`.

## Asset key rules

* Format: `cosmetics.<bucket>.<name>` — three or more dot-separated parts;
  first part **must** be `cosmetics`.
* Buckets accepted by the resolver: `frames`, `relics`, `backgrounds`,
  `emblems`, `companions`, `title_flairs`, `map_effects`.
* The `<name>` is joined with underscores if the asset key has more than
  three parts (e.g. `cosmetics.frames.ruined_bronze` →
  `ruined_bronze.png`).
* `previewAssetKey` is optional; if absent, widgets fall back to
  `assetKey`. If both are absent, the rarity-coloured placeholder is shown.

## Validation rules

Run both validators on app startup in debug mode (e.g. via a
`assert(...)` or DevTools button):

```dart
final catalog = const CosmeticCatalog();
final config = CosmeticsConfig.standard();
final warnings = [
  ...catalog.validate(),
  ...config.validate(catalog),
];
assert(warnings.isEmpty, 'Cosmetics warnings: $warnings');
```

`CosmeticsService.validateState(state)` is the runtime equivalent — it
catches drift between a persisted state and the current catalog (e.g. a
removed cosmetic still equipped).

## Debug / equip UI (temporary)

`presentation/cosmetics_debug_screen.dart` is an end-to-end smoke screen
for the cosmetics engine. Lists every catalog entry grouped by type,
shows locked tiles greyed out, lets you tap an unlocked tile to equip
it (or tap an equipped tile to unequip), and renders a chip row for
currently equipped slots with an X-button per slot.

It is **not the final wardrobe UI** — once that lands, delete this
file or hide it behind a debug flag. There is no navigation entry on
purpose; push it ad-hoc from any screen, e.g. as a temporary `ListTile`
in the settings screen:

```dart
ListTile(
  leading: const Icon(Icons.style_outlined),
  title: const Text('Cosmetics — debug'),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const CosmeticsDebugScreen(),
    ),
  ),
),
```

The screen safely handles missing assets (rarity-coloured placeholder),
loading state (spinner), and a signed-out user (helpful hint about
`ChangeNotifierProxyProvider` + AuthProvider binding).

## Not yet implemented

* Firestore sync. Local persistence is in place (Isar); a remote
  implementation should mirror the progression hybrid pattern
  (`HybridProgressionRepository` + `FirestoreProgressionGateway`).
* Real artwork — every asset folder is empty.
* Hero / social UI — only placeholder widgets exist; no screen consumes
  them yet.
* L10n for `descriptionKey` and `unlock_hint` is wired in the helper but
  the `.arb` files only ship name + description today. Add hints when a
  cosmetic actually needs one.
* Premium gating UI / paywall — `isPremium` and `premiumEnabled` exist on
  the data layer but there is no purchase flow.
* Animations — frames render statically.
