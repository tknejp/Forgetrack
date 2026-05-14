# Firestore Sync Audit — V2 Progression, Cosmetics, Profile

Status: 2026-05-14. Originally captured the gap after the V2 refactor;
updated the same day with the write-through implementation on
`feature/v2-progression-firestore-sync`.

## Status (2026-05-14, post-implementation)

**Shipped on `feature/v2-progression-firestore-sync`:**

- **Phase A** — `FirestoreProgressionEngineGateway`
  ([lib/features/progression_engine/data/firestore_progression_engine_gateway.dart](../lib/features/progression_engine/data/firestore_progression_engine_gateway.dart)).
  Maps the sealed `LedgerEvent` hierarchy to five Firestore subcollections
  under `users/{uid}/`: `engineObjectiveCompletions`,
  `engineNodeCompletions`, `engineNodeClaims`, `engineNodeAnnouncements`,
  `engineRewardGrants`. Document IDs are the deterministic `eventKey`
  (sanitised). Writes use plain `set()` because events are immutable —
  re-writing the same event with the same data is data-level idempotent.
  Pulls are batched in parallel; wipes are paginated batched deletes.

- **Phase B** — `HybridProgressionEngineRepository`
  ([lib/features/progression_engine/data/hybrid_progression_engine_repository.dart](../lib/features/progression_engine/data/hybrid_progression_engine_repository.dart)).
  Wraps the Isar local repo, mirrors every accepted `appendEvents` call
  to the gateway via fire-and-forget `unawaited` push (cloud failures
  logged through `AppLog.sync` but never block local commits). Wipe is
  also mirrored. Receives the active uid via `bindUser(uid)` from the
  provider — null-uid (signed out) skips all cloud operations.

  Wired in [main.dart](../lib/main.dart): the Isar repo is wrapped only
  when `socialBackendState.isReady`; otherwise the engine talks straight
  to Isar exactly as before, so tests and Firestore-disabled
  environments are unchanged.

- **Phase C** — Startup pull-and-merge. `ProgressionEngineProvider.bind`
  now also accepts `authUid`; its proxy in `main.dart` was upgraded to
  `ChangeNotifierProxyProvider5` to receive `AuthProvider`. On the first
  non-null uid `bindCloudUser` calls `HybridProgressionEngineRepository.pullAndMerge`
  — pull-then-`appendEvents`-locally — and triggers a re-evaluation.
  Idempotent because Isar dedupes via `eventKey`. After the merge the
  cosmetic bridge's new `reapplyHistoricalCosmetics(LedgerSnapshot)`
  walks the ledger and re-fires `cosmetics.unlock` for every cosmetic
  reward grant, so the cosmetics inventory converges too (engine
  evaluate would NOT re-emit grants whose events are already in the
  ledger).

**Phase B.2 (separate cosmetic entitlement writer): not implemented.**
Engine cosmetic grants flow through the same ledger gateway as
`RewardGrantEvent(rewardKind: cosmetic)`, so they're already synced.
The legacy `users/{uid}/cosmeticEntitlements` collection remains
read-only — that's the right shape for promotional grants written
by Cloud Functions / external systems.

**Phase D (legacy V1 migration): not started.** The V1 progression
module appears to have no live writers in the current build (the
`FirestoreProgressionGateway` says so itself). Decide whether to drop
it or copy-once before public release.

## Known remaining gaps

- **Cosmetic equipped state.** Which slot the user equipped (frame /
  background / etc.) lives only in Isar today. The social profile
  snapshot (`users/{uid}.equippedCosmetics`) carries the IDs as a
  derived view, but nothing reads them back on a fresh install. A
  second device sees the cosmetic as unlocked in the inventory but with
  the default slot empty until the user re-equips.
- **No batching at the engine boundary.** Each `evaluate()` cycle that
  produces N events triggers one batched cloud push of up to N items.
  For high-frequency evaluation runs (devtools advance-day spam, deep
  combo claims) this can mean a lot of small Firestore writes. If
  billing telemetry shows it matters, coalesce multiple evaluations
  into one debounced push window inside the hybrid repo.
- **No conflict policy beyond "last writer wins on key collision".**
  Engine events are append-only with deterministic keys, so this is
  fine for the engine. If the equipped-state sync lands later it'll
  need an actual policy (timestamp-based merge, server-authoritative).

## Original audit (kept for context)

## TL;DR

- **Profile image cold-start UX** is fixed in this session: `SocialAvatar`
  now uses `CachedNetworkImage` (persistent disk cache between launches)
  and `AuthProvider` / `CosmeticsProvider` / `ProgressionEngineProvider` /
  `SocialProvider` are constructed eagerly via `lazy: false` so Firestore
  hydration starts during `MultiProvider` build instead of at first widget
  read.

- **V2 progression does NOT push to Firestore.** Claims, quest
  completions, achievement unlocks, and cosmetic unlocks all live in
  Isar only. The legacy `FirestoreProgressionGateway` (V1) is also not
  wired (its own header comment confirms it). The only thing reaching
  Firestore is `SocialProvider.upsertProfile` which writes a derived
  **summary** (level, totalXp, counts, equipped cosmetic ids) — enough
  for friends to see your stats, NOT enough to restore individual
  rewards / unlocks on a fresh install or second device.

- **Multi-device parity is broken.** Reinstall = full progress wipe.
  This is acceptable during dev (per CLAUDE.md "the app can be reset")
  but must be addressed before public release.

## Current Firestore footprint

### Reads
- `users/{uid}` — `SocialProvider.watchProfileById` for hero header,
  `fetchProfilesByIds` for friends. Live stream.
- `users/{uid}/cosmeticEntitlements` — `FirestoreCosmeticEntitlementsSource.loadForUser`
  on cosmetics provider bind. One-shot.
- `users/{uid}/notifications`, `friend_requests`, `friendships`,
  `achievement_shares` — social streams.
- `users/{uid}/progressionClaims` and `users/{uid}/achievementUnlocks` —
  read paths exist on the legacy gateway but never invoked by V2.

### Writes
- `users/{uid}` upsert (display name, handle, photoUrl, stats summary,
  unlockedAchievements snapshot, equipped cosmetics) via
  `FirestoreSocialRepository.upsertProfile` from `SocialProvider._syncProfileIfNeeded`.
- `social_profile_photos/{uid}/profile_{ts}.{ext}` upload to Firebase
  Storage from `SocialProvider.uploadCurrentProfilePhoto`.
- `friend_requests`, `friendships`, `achievement_shares`, reactions,
  notifications — social mutations.
- **No V2 progression writes. No cosmetic entitlement writes from the
  client.**

## Gap matrix

| Domain | Local (Isar) | Firestore (per-event) | Firestore (summary) |
|---|---|---|---|
| Reward grants (XP) | yes | **no** | counter only (`grantedRewardCount`) |
| Node claims | yes | **no** | no |
| Quest completions | yes | **no** | no |
| Objective completions / streaks | yes | **no** | best-streak summary on profile |
| Achievement unlocks | yes | **no** | id list snapshot on profile |
| Cosmetic unlocks | yes | **no** | equipped slot ids only |
| Cosmetic equipped state | yes | **no** | yes |

The "summary" column shows what a fresh install / second device can
recover. Today: level, totalXp, list of unlocked achievement ids
(without timestamps), and currently equipped cosmetic ids. Everything
else is gone.

## Recommended path: write-through

Aligned with CLAUDE.md ("rewards must be idempotent, deterministic
keys, durable events not recomputed UI-only state") and the existing
V1 `FirestoreProgressionGateway` pattern.

### Phase A — V2 Firestore gateway (new)
New `FirestoreProgressionEngineGateway` writing to:
- `users/{uid}/engineRewardGrants/{deterministicKey}` — `RewardGrantEvent`
- `users/{uid}/engineNodeClaims/{nodeId}_{periodKey}` — `NodeClaimEvent`
- `users/{uid}/engineNodeCompletions/{nodeId}_{periodKey}` — `NodeCompletionEvent`
- `users/{uid}/engineObjectiveCompletions/{objectiveId}_{periodKey}` — `ObjectiveCompletionEvent`
- `users/{uid}/cosmeticEntitlements/{cosmeticId}` — write-through from `CosmeticsService.unlock`

All writes create-if-not-exists (transactions like the V1 gateway), so
retries and offline-replay are safe.

### Phase B — write-through wiring
- In `ProgressionEngine.evaluate` and `ProgressionEngine.claim`, after
  the local `_repository.append(events)` succeeds, fan out the same
  events to the gateway. Best-effort, fire-and-forget; failures logged
  via `AppLog.progression` but never block the local write (offline
  must work).
- In `CosmeticsService.unlock`, mirror the new entitlement to Firestore
  (current source is read-only).
- `CosmeticsProvider.equip` already mutates Isar — also write a
  per-slot doc (`users/{uid}/cosmeticEquipped/{type}`) so equipped
  state is restorable.

### Phase C — startup pull / reconcile
On `bindUser(uid)`, before playing forward, the engine repository
should:
1. Pull all `engine*` collections in parallel.
2. Merge into Isar using deterministic keys (idempotent — duplicates
   are ignored).
3. Then evaluate / claim as today.

This makes a second device or reinstall converge to the cloud state on
first sign-in.

### Phase D — migrate the legacy V1 collections
Either drop them (if V1 has no live users) or one-shot copy
`progressionClaims` + `achievementUnlocks` into the new V2 collections
on first run, then ignore.

### Open questions
- **Cost.** Every objective evaluation writing one Firestore doc per
  ledger event would add up. Consider batching: collect all events
  produced by a single `evaluate()` cycle into one batched write.
- **Where to put orchestration.** The cleanest seam is a new
  `HybridProgressionEngineRepository` that wraps Isar and dispatches to
  the gateway after each local commit, mirroring V1's
  `HybridProgressionRepository`. Keeps the engine itself
  Firestore-agnostic.
- **Conflict resolution.** Engine events are append-only with
  deterministic keys, so create-if-not-exists is sufficient — no
  merging logic needed.

## Out of scope (this session)
- Implementing Phases A–D. Audit only, per the user's choice.
- Moving cosmetic entitlement writes server-side via Cloud Functions —
  keeps the client simple but is a separate decision.

## Cold-start UX changes shipped today
- `cached_network_image: ^3.4.1` added; `SocialAvatar` now uses
  `CachedNetworkImage` so the hero header shows the cached photo
  instantly on subsequent launches and doesn't re-download from CDN.
- `lazy: false` on `AuthProvider`, `CosmeticsProvider`,
  `ProgressionEngineProvider`, `SocialProvider` so their hydration
  (Isar load + Firestore round-trip) runs during `MultiProvider` build
  rather than at first widget read on the home screen.
