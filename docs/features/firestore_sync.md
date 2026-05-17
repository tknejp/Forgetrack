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
`RewardGrantEvent(rewardKind: cosmetic)` — there is no separate cosmetic
collection written by the client.

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

## Known remaining gaps

- **Cosmetic equipped state.** Which slot the user equipped (frame,
  background, etc.) lives only in Isar. The social profile snapshot
  (`users/{uid}.equippedCosmetics`) carries the IDs as a derived view,
  but nothing reads them back on a fresh install. A second device sees
  the cosmetic as unlocked in the inventory but with the default slot
  empty until the user re-equips.
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
