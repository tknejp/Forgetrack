# Firestore Sync — V2 Progression

The V2 progression engine writes through to Firestore so a fresh install
or second device can recover the full claim / completion / reward
history. This document describes the wire format, the write-through
seam, and the known remaining gaps.

Shipped on `main` (commits `eca6817` → `0526a4a`, 2026-05-14).

---

## Wire format

Each `LedgerEvent` maps to one document in a per-user subcollection.
Document IDs are the deterministic `eventKey` (sanitised).

| Event type | Firestore path |
|---|---|
| `RewardGrantEvent` | `users/{uid}/engineRewardGrants/{eventKey}` |
| `NodeClaimEvent` | `users/{uid}/engineNodeClaims/{eventKey}` |
| `NodeCompletionEvent` | `users/{uid}/engineNodeCompletions/{eventKey}` |
| `ObjectiveCompletionEvent` | `users/{uid}/engineObjectiveCompletions/{eventKey}` |
| `NodeAnnouncementEvent` | `users/{uid}/engineNodeAnnouncements/{eventKey}` |
| `QuestOfferedEvent` | `users/{uid}/engineQuestOfferings/{eventKey}` |

Cosmetic grants flow through this same gateway as
`RewardGrantEvent(rewardKind: cosmetic)` — that's the *source* of
truth for unlocks driven by progression. The cosmetics feature itself
also has its own hybrid wrapper (`HybridCosmeticsRepository` +
`FirestoreCosmeticsGateway`) that writes per-user inventory + loadout
to dedicated collections so reinstall / second-device sees equipped
slots and DevTools / manual grants too — see the
[Cosmetics hybrid sync](#cosmetics-hybrid-sync) section below.

Writes use plain `set()` because events are immutable: re-writing the
same event with the same data is data-level idempotent. Pulls are
batched in parallel; wipes are paginated batched deletes.

The legacy `users/{uid}/cosmeticEntitlements` collection remains
**read-only** from the client. That shape is reserved for promotional
grants written by Cloud Functions / external systems.

---

## Implementation seam

Three layers, designed so the engine itself stays Firestore-agnostic:

1. **`FirestoreProgressionEngineGateway`**
   ([../../lib/features/progression_engine/data/firestore_progression_engine_gateway.dart](../../lib/features/progression_engine/data/firestore_progression_engine_gateway.dart))
   Pure Firestore I/O. Maps the sealed `LedgerEvent` hierarchy to the
   subcollections above. Push, pull, wipe.

2. **`HybridProgressionEngineRepository`**
   ([../../lib/features/progression_engine/data/hybrid_progression_engine_repository.dart](../../lib/features/progression_engine/data/hybrid_progression_engine_repository.dart))
   Wraps the Isar local repo. Every accepted `appendEvents` call is
   mirrored to the gateway via fire-and-forget `unawaited` push. Cloud
   failures are logged through `AppLog.sync` but never block local
   commits. Wipe is also mirrored. Receives the active uid via
   `bindUser(uid)` from the provider — null-uid (signed out) skips all
   cloud operations.

3. **Provider binding** in [../../lib/main.dart](../../lib/main.dart).
   The Isar repo is wrapped in the hybrid repository only when
   `socialBackendState.isReady`. Otherwise the engine talks straight to
   Isar exactly as before, so tests and Firestore-disabled environments
   are unchanged.

### Startup pull-and-merge

`ProgressionEngineProvider.bind` takes `authUid`. On the first non-null
uid, `bindCloudUser` calls `HybridProgressionEngineRepository.pullAndMerge`
— pull from Firestore, then `appendEvents` locally — and triggers a
re-evaluation. Idempotent because Isar dedupes via `eventKey`.

After the merge the cosmetic bridge's `reapplyHistoricalCosmetics(LedgerSnapshot)`
walks the ledger and re-fires `cosmetics.unlock` for every cosmetic
reward grant, so the cosmetics inventory converges too (engine
`evaluate` would NOT re-emit grants whose events are already in the
ledger).

---

## Invariants

- Events are append-only with deterministic keys → create-if-not-exists
  semantics, no merge logic.
- Conflict policy: last writer wins on key collision (safe because
  payloads are determined by the key).
- Cloud failures never block local commits.
- Re-running pull-and-merge is idempotent.
- Friend achievements read from `engineNodeCompletions` (legacy V1 read
  path retired, commit `0526a4a`).

---

## Cosmetics hybrid sync

Independent of the engine ledger above, the cosmetics feature ships
its own hybrid wrapper for player inventory + equipped state so a
reinstall / second device picks up DevTools grants, race selection
and equipped slots — not just progression-driven unlocks.

| Wire location | Purpose |
| --- | --- |
| `users/{uid}/cosmeticUnlocks/{cosmeticId}` | One doc per owned cosmetic. Doc ID is the cosmetic id → idempotent `set()`. Fields: `unlockedAt`, `sourceType`, `sourceId`. |
| `users/{uid}/cosmeticState/state` | Single doc with the `Loadout` slots (frame/relic/background/emblem/companion/titleFlair/mapEffect/skin/banner), `selectedRaceId`, `updatedAt`. |

The two layers:

1. **`FirestoreCosmeticsGateway`**
   ([../../lib/features/cosmetics/data/firestore_cosmetics_gateway.dart](../../lib/features/cosmetics/data/firestore_cosmetics_gateway.dart))
   — pure Firestore I/O: `pushUnlock` / `removeUnlock` /
   `wipeUnlocks` / `pushState` / `pull` / `wipeAll`.
2. **`HybridCosmeticsRepository`**
   ([../../lib/features/cosmetics/data/hybrid_cosmetics_repository.dart](../../lib/features/cosmetics/data/hybrid_cosmetics_repository.dart))
   — wraps `IsarCosmeticsRepository`. Every mutating
   `CosmeticsRepository` op (unlock, equip, unequip, revoke,
   selectRace, clearAllUnlocks, saveState) is mirrored to the cloud
   via `unawaited` push after the local write succeeds.

Merge policy on first `loadForUser` per uid (sign-in / cold start):

- **Unlocks**: union by cosmeticId. For collisions, the *earlier*
  `unlockedAt` wins so the audit timestamp reflects the player's
  first-ever acquire across devices. Local `sourceType` / `sourceId`
  stays authoritative (it's the device that actually granted it).
- **Loadout + `selectedRaceId` + `updatedAt`**: whichever side has
  the later `updatedAt` wins as a whole bundle. Cloud `updatedAt`
  null (no state doc yet) → local wins by default.

After the merge the wrapper re-pushes the merged state up to the
cloud so the cloud sees the union too. Subsequent loads short-circuit
to the local Isar repo — steady-state mutations push deltas through
the same gateway.

`socialBackendState.isReady = false` (Firebase init failed,
anonymous session) → wrapper is NOT constructed; service talks
straight to the Isar repo exactly as before.

The legacy `users/{uid}/cosmeticEntitlements` collection (server-pushed
promotional grants) is untouched by this layer — it remains a
one-way read channel via `FirestoreCosmeticEntitlementsSource`.

---

## Known remaining gaps

- **No batching at the engine boundary.** Each `evaluate()` cycle that
  produces N events triggers one batched cloud push of up to N items.
  Devtools advance-day spam or deep combo claims can mean a lot of
  small Firestore writes. If billing telemetry shows it matters,
  coalesce multiple evaluations into one debounced push window inside
  the hybrid repo.
- **Legacy V1 migration not done.** The V1 progression module appears
  to have no live writers in the current build. Decide whether to drop
  the old `progressionClaims` / `achievementUnlocks` collections or
  copy-once into the V2 collections before public release.
- **Goal history not synced.** `GoalsProvider`'s per-day historized
  targets (`progressionDailyStepsForDate`, etc.) live in
  SharedPreferences. On a device swap they reset to the user's
  freshly-entered values; the backfill section then renders past-day
  rows with the *current* goal as target. Granted XP is unaffected —
  it lives in `RewardGrantEvent.xpAmount` in the cloud-synced ledger,
  frozen at claim time. The mismatch is purely cosmetic ("12k / 12k"
  reads as goal-met even if the historical target was 10k). Mitigation
  path if it becomes a problem: append-only goal-revision events in a
  new `userGoalRevisions` collection, mirrored by the existing hybrid
  push path.
- **`joinedAt` prefs not synced directly** but cross-device-correct in
  practice. The prefs key reseeds on a new device from the earliest
  ledger event timestamp (which IS cloud-synced via `pullAndMerge`),
  so the retroactive claim window anchors on the original first-launch
  day without explicit sync code.
- **KT-sourced nutrition goals are read-time, not synced (#98).** When
  the nutrition goal source is `kt`, `GoalsProvider`'s five nutrition
  getters return KT's per-day targets at read time — they are never
  written into the local goal board or the `goal_history` Firestore
  mirror. The source flag itself (`nutrition_goals_source`) lives in
  SharedPreferences and is not cloud-synced, so a second device defaults
  to local until the user re-picks KT. KT remains the source of truth
  for those days while the flag is `kt`.

---

## Related cold-start UX

Shipped in the same audit (commit `2f87e57`):

- `cached_network_image: ^3.4.1` — `SocialAvatar` uses `CachedNetworkImage`
  so the hero header shows the cached photo instantly on subsequent
  launches.
- `lazy: false` on `AuthProvider`, `CosmeticsProvider`,
  `ProgressionEngineProvider`, `SocialProvider` so their hydration
  (Isar load + Firestore round-trip) runs during `MultiProvider` build
  rather than at first widget read on the home screen.
