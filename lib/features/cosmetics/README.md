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
* Catalog ships with the current journey cosmetic set across frames, relics,
  backgrounds, emblems, and companions.
* Default unlocks for every fresh user are defined by
  `kDefaultCosmeticUnlockIds`. They are seeded into Isar on first load for
  a uid.
* No real artwork yet — widgets render rarity-coloured placeholders when an
  asset file is missing.
* Cosmetic player-facing text lives in `lib/l10n/app_*.arb` and is wired
  directly in `CosmeticCatalog` through generated `AppLocalizations` getters
  such as `name: (l10n) => l10n.cosmeticFramePilgrimName`. There is no
  separate id-based localization switch. Widgets receive `AppLocalizations`
  and resolve text from the catalog definition; without l10n they fall back
  to `definition.id` so debug builds stay readable.
* `CosmeticsProvider` is wired via
  `ChangeNotifierProxyProvider<AuthProvider, CosmeticsProvider>` in
  `main.dart`. `bindUser(auth.user?.id)` fires on every auth notification;
  state is loaded once per uid and cleared on sign-out.

## Folder structure

```
lib/features/cosmetics/
├── domain/
│   ├── cosmetic_models.dart                 # sealed Cosmetic + 7 subtypes,
│   │                                        # enums, Loadout, UnlockedCosmetic,
│   │                                        # UserCosmeticsState
│   ├── cosmetic_catalog.dart                # static seed definitions + helpers
│   ├── cosmetic_unlock_rules.dart           # baseline unlock set
│   ├── ids.dart                             # CosmeticId extension type
│   ├── player_cosmetic_lifecycle.dart       # sealed 4-state lifecycle (Phase 10)
│   ├── player_cosmetic.dart                 # CosmeticId + lifecycle VO
│   ├── inventory.dart                       # Map<CosmeticId, PlayerCosmetic> projection
│   ├── cosmetic_lifecycle_helpers.dart      # hidesIdentity + showsChecklist (proposal §4.3)
│   ├── companion_availability_lookup.dart   # cosmeticId → CompanionAvailability node (Phase 11)
│   ├── emblem_board.dart                    # 11-slot profile showcase VO (Phase 12)
│   ├── cosmetic_reveal_state.dart           # evaluator output enum + checklist row VO
│   └── consumed_relics.dart                 # relic-by-companion derivation
├── data/
│   ├── cosmetics_repository.dart            # abstract persistence interface
│   ├── in_memory_cosmetics_repository.dart  # test/dev implementation
│   ├── isar_cosmetics_repository.dart       # production local persistence
│   └── local/
│       ├── cosmetics_database.dart          # Isar instance owner
│       └── cosmetics_local_models.dart      # @Collection records (+ .g.dart)
├── application/
│   ├── cosmetics_service.dart                  # business layer (no Flutter dependency)
│   ├── cosmetics_provider.dart                 # ChangeNotifier for UI binding
│   ├── player_cosmetic_lifecycle_service.dart  # builds Inventory from primitives (Phase 10)
│   └── emblem_board_provider.dart              # 11-slot showcase persistence (Phase 12)
├── config/
│   └── cosmetics_config.dart   # asset resolver, slots, flags, validation
├── presentation/
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
| `Cosmetic` | **sealed** parent (Phase 9) — id, rarity, region, localized text resolvers, asset keys, flags, `metadata` bag, derived `CosmeticType get type` |
| `Frame / Background / Companion / RelicCosmetic / Emblem / TitleFlair / MapEffect` | 7 concrete subtypes of `Cosmetic` — pattern-match discriminator (`def is Companion`) replaces the legacy `cosmetic.type ==` enum check |
| `UnlockedCosmetic`   | per-user unlock record — id, timestamp, source        |
| `Loadout` (Phase 12 rename ex-`EquippedCosmetics`) | snapshot of 7 worn cosmetic slots; one nullable id per slot |
| `UserCosmeticsState` | uid + unlocked map + equipped Loadout + updatedAt     |
| `PlayerCosmetic` + `PlayerCosmeticLifecycle` (Phase 10) | sealed 4-state lifecycle (Hidden / Teased / Claimable / Owned) + immutable VO carrying CosmeticId + lifecycle |
| `Inventory` (Phase 10) | per-user `Map<CosmeticId, PlayerCosmetic>` read projection — `CosmeticsProvider.buildInventory(claimableNodeIds:)` |
| `EmblemBoard` + `EmblemBoardProvider` (Phase 12) | 11-slot profile-header showcase VO + per-device SharedPrefs persistence (`pinned_emblems_{uid}`); distinct from `Loadout.emblemId` (worn) |
| `CanEquipResult`     | `{ok, reason}` for non-throwing UI checks             |
| `CosmeticsException` | typed exception with stable `code` + human `message`  |

`UserCosmeticsState` is **immutable** — every mutation produces a new value.
Provider listeners always see a stable snapshot.

## Catalog

`CosmeticCatalog` is a stateless wrapper over an unmodifiable `static final`
list of definitions. Helpers:

* `all` — every definition.
* `byId(id)` — nullable lookup.
* `byType(type)` — definitions for one slot.
* `byRegion(region)` — definitions tagged for one region.
* `enabled` — only `isEnabled = true` definitions.
* `validate()` — list of warning strings; empty = healthy. Checks duplicate
  ids and malformed asset keys. Localization getter references are checked
  by the Dart compiler.

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

1. Append a `Cosmetic` to `CosmeticCatalog.definitions` with a
   unique `id` and the right `type` / `rarity` / `region`.
2. Add the artwork file under
   `assets/cosmetics/<bucket>/<id-without-prefix>.png` (see
   `assets/cosmetics/README.md` for naming and sizing). The cosmetic will
   render a placeholder until the file ships.
3. Add the localization keys to `lib/l10n/app_en.arb` and every supported
   locale, then wire the generated getters in the catalog entry:
   `name: (l10n) => l10n.cosmeticExampleName`,
   `description: (l10n) => l10n.cosmeticExampleDesc`,
   and optional `unlockHint: (l10n) => l10n.cosmeticExampleUnlockHint`.
4. Run `CosmeticCatalog().validate()` in a debug session to confirm no
   warnings.

## How to add a new cosmetic type

1. Add a case to the `CosmeticType` enum in `cosmetic_models.dart`.
2. Add a corresponding nullable id field to `Loadout`, plus a
   branch in `slotId` and `copyWithSlot`.
3. Add the type to `CosmeticsConfig.standard()`'s `allowedSlots` (or gate
   it behind a flag like `mapEffect`).
4. Extend `CosmeticsConfig._bucketFolder` with the asset folder name.
5. Add an icon for the type in `CosmeticEquippedChip._iconForType`.
6. Add the asset folder under `assets/cosmetics/<bucket>/` and declare it
   in `pubspec.yaml`.

## Emblem XP buffs

Each `Emblem` in the catalog may carry a non-null `EmblemBuff`
([domain/emblem_buff.dart](domain/emblem_buff.dart)). When the player
pins an emblem into an `EmblemBoard` slot, its buff contributes a
percent bonus to XP claims that match the buff's `EmblemTarget`. The
progression engine consumes the equipped set; cosmetics itself stays
unaware of XP math.

* **`EmblemBuff` (sealed)** — `PerTargetEmblemBuff(target, percent)`
  matches a single `EmblemTarget`; `BlanketEmblemBuff(percent)` applies
  to any target covered by some `PerTargetEmblemBuff` in the active
  catalog. The covered-target list is a `static const` on
  `BlanketEmblemBuff` — hand-maintained, must stay in lockstep with
  the per-target catalog entries.
* **`EmblemTarget` (sealed)** — `DailyGoalTarget(GoalMetric)` for daily
  goal claims (kcal / steps / macros / sleep / activity / weight),
  `ComboQuestTarget()` for combo-bucket quests. Resolution per claim is
  done by `emblemTargetForNode` in the progression engine.
* **`EmblemBuffContext`** — built per claim from the target +
  `RewardSourceKind`; passed to every equipped buff's
  `resolvePercent(ctx)`.
* **Source of truth = equipped, not owned.** The engine reads
  `EmblemBoardProvider.boardForUserOrAutoFill(uid, unlockedIds)`,
  maps pinned slot ids to catalog `Emblem.buff`, and forwards them as
  `EngineEvaluationContext.equippedEmblemBuffs`. Auto-fill keeps fresh
  users (who never opened the picker) benefiting from their unlocks.
* **Math.** `RewardGrantService` combines companion% and emblem%
  additively into a single multiplier:
  `final = base × (1 + (companionPct + emblemPct) / 100)`. There is no
  per-day cap. Bonus XP is split proportionally for telemetry and
  persisted on `RewardGrantEvent.emblemBuffBonusXp`.
* **RPG mode gate.** When `!player.rpgModeEnabled` the engine passes
  `const []`, so emblem buffs contribute zero — mirrors companion buff
  gating.
* **Discoverability.** Inventory tiles render a one-line buff label
  (`emblemBuffPerTarget` / `emblemBuffBlanket` ARB keys) and an
  equipped-badge adornment for pinned emblems. The XP claim pill and
  reward toast surface an emblem bonus sub-line whenever
  `event.emblemBuffBonusXp > 0`. Pre-claim projection uses
  `ProgressionEngineProvider.projectedEmblemBuffBonusFor(nodeId, baseXp)`.
* **Telemetry.** Every buffed claim emits an `AppLog` line under the
  `progression.claim.buff` scope with nodeId, sourceKind, companionPct,
  emblemPct, companionBonusXp, emblemBonusXp, finalXp.

## Progression integration

`progression` owns the dispatch loop; this feature exposes
`CosmeticsProvider.unlock(...)` and stays unaware. Two tiers cover the unlock
surface:

### Tier 1 — Inline rewards on catalog entries

Cosmetic rewards live as a `cosmeticRewards: [...]` field on each
achievement, quest, and level milestone in the progression catalog
(`lib/features/progression/domain/catalog/`) and on
`ProgressionLevelTier` in
`progression/domain/policy/level_config.dart`. Adding a reward = adding
the cosmetic id to the entry's list. The dispatcher iterates every
currently-unlocked achievement, every level from 1 to current, and every
claimed quest per call (catch-up semantics), so a new mapping is granted
retroactively on the next sync without a migration script. Idempotency
at the repository layer keeps repeat passes a no-op.

### Tier 2 — Compound condition declarations (display-only)

Compound conditions like "owns relic_X AND owns relic_Y AND level ≥ N"
(used by every companion). Lives entirely in `cosmetics/domain` so
progression doesn't grow rule-evaluation logic.

* Rules: `lib/features/cosmetics/domain/cosmetic_unlock_rules.dart`
  exposes `kCosmeticUnlockRules` — a declarative `List<CosmeticUnlockRule>`.
  Each rule has 1-N named `CosmeticUnlockCondition`s joined with logical
  AND. OR is expressed by registering two rules with the same `cosmeticId`.
* Snapshot: `cosmetic_unlock_snapshot.dart` is the read-only DTO the rules
  inspect.
* **Consumer:** `CosmeticRevealEvaluator` (in the same folder). The rules
  drive the partial-reveal hint checklist UI (rows like "Owns Oathbound
  Mark — ✓" on the companion details sheet); they no longer trigger
  unlocks themselves. Actual companion claims route through
  `CompanionAvailability` progression-engine nodes in
  `progression_engine/domain/catalog/content/companions_content.dart`
  → `engine.claimNode`. The standalone `CosmeticUnlockEvaluator` class
  that previously walked these rules was removed once it became clear
  it had no production callers post-Phase-11.

### Dispatcher

`lib/features/progression/application/cosmetic_unlock_dispatcher.dart` runs
four passes per call:

1. Tier-1 achievement catch-up — reads `cosmeticRewards` off every
   currently-unlocked achievement.
2. Tier-1 level catch-up (1..currentLevel) — reads `cosmeticRewards`
   off `ProgressionLevelTier` and the decorative-level map.
3. Tier-1 quest catch-up — reads `cosmeticRewards` off every claimed
   quest grant.
4. Tier-2 rule evaluator in a bounded fixed-point loop (max 3 iterations)
   so compound rules whose dependencies were granted by passes 1–3 fire
   in the same dispatch — e.g. `relic_dragon_scale` granted in pass 1
   then `companion_dragonling` (which requires that relic) in pass 4.

Logs: `[COSMETICS][dispatch]` and `[COSMETICS][provider]` scopes; every
unlock attempt, no-op (already unlocked), rejection, and crash is logged
via `AppLog`.

Idempotence: `cosmetics.unlock` is a no-op if the cosmetic is already
unlocked, so the catch-up loops are safe to run on every sync.

## How to add a new unlock condition

Pick a tier:

* **Tier 1 (already-tracked metric)** — add the cosmetic id to the
  `cosmeticRewards` list on the relevant achievement / quest / level
  tier in the progression catalog. If a suitable achievement does not
  exist yet, add one to
  `progression/domain/catalog/achievement_catalog.dart` first — the
  achievement engine will start tracking and unlocking it, and the
  dispatcher will grant the cosmetic on the next sync.

* **Tier 2 (engine can't express it)** — extend `kCosmeticUnlockRules`
  in `cosmetics/domain/cosmetic_unlock_rules.dart`:
  1. If the condition needs a snapshot field that doesn't exist yet, add
     it to `CosmeticUnlockSnapshot` in
     `cosmetics/domain/cosmetic_unlock_snapshot.dart` and populate it in
     `progression/application/cosmetic_unlock_snapshot_extractor.dart`
     from a **durable** source (the progression ledger, not transient
     provider state).
  2. Add a `Cond.<name>(...)` builder to `cosmetic_unlock_rule.dart` that
     returns a `CosmeticUnlockCondition` reading the new field. The `id`
     of the condition should be stable across releases — future UI uses it
     to render hints.
  3. Append a `CosmeticUnlockRule` to `kCosmeticUnlockRules`. Compound
     rules just list multiple `CosmeticUnlockCondition`s — they are joined
     with logical AND. Set `isHidden: true` for prestige rewards that
     should not surface partial-progress hints.

Tier 1 is preferred whenever the metric is a simple aggregate the
achievement engine already evaluates — the rule evaluator should not
duplicate persistence concerns.

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
* Premium gating UI / paywall — `isPremium` and `premiumEnabled` exist on
  the data layer but there is no purchase flow.
* Animations — frames render statically.
