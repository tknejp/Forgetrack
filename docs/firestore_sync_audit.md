# Firestore Sync Audit — V2 Progression, Cosmetics, Profile

Status: 2026-05-14. Captures the current state of Firestore reads/writes
after the V2 progression refactor and the cold-start UX work in this
session (image caching + eager provider hydration).

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
