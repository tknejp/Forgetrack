# Avatars — Race × Skin System Handoff

**Status (2026-05-23):** in-progress. Domain + persistence + onboarding flow + profile hero card + force-pick gate + compact thumbnail rendering + social wire format extension all shipped. Cosmetics screen "Vzhled" tab still open. Drip-feed skin content is product-pending.

This is the working-state doc for the avatar refactor that replaces the legacy `AvatarSelectionProvider` / `AvatarCatalog` / photo-upload pipeline with a two-axis system:

* **`HeroRace`** — permanent visual identity picked once at onboarding (or via the force-pick gate for legacy saves). NOT a `Cosmetic` subtype; it never flows through the unlock/reward pipeline. 9 fixed entries: 3 species × m/f (Human, Elf, Dwarf) + 3 single-gender (Orc, Spirit, Golem).
* **`Skin`** — `Cosmetic` subtype, drip-fed through the existing `CosmeticReward` → `CosmeticUnlockBridge` → `CosmeticsProvider` pipeline. One catalog entry per *theme* (race-agnostic); the per-race artwork is picked at render time by `SkinAssetResolver` from the player's `selectedRaceId`.

Reading order:

1. This document — design, what's shipped, what's open.
2. `lib/features/cosmetics/domain/cosmetic_models.dart` (`Skin`, `Loadout.skinId`, `UserCosmeticsState.selectedRaceId`) — the canonical types.
3. `lib/features/cosmetics/config/skin_asset_resolver.dart` — the two-arg `(raceId, skinAssetKey) → file path` evaluator.
4. `lib/features/onboarding/presentation/race_picker_view.dart` — the shared race-picker UI used by both onboarding Step 1 and the force-pick screen.

---

## Why this exists

Pre-refactor, "avatar" meant a flat list of 18 preset PNGs plus an optional user-uploaded photo, persisted to `SharedPreferences` and (for the photo) to Firebase Storage. Two issues:

1. **No drip-feed.** Avatars couldn't be earned through gameplay — they were all unlocked from boot.
2. **Identity vs. evolution conflated.** A pixel-art warrior and a Google selfie sat next to each other in the same picker; no notion of "this is *my* character growing through themes."

The new system separates two concerns:

* **Identity** (race) — picked once, locked in, gives the player a consistent silhouette.
* **Evolution** (skins) — themed appearances earned over time, all rendered for the player's specific race.

Per the design map (`Forgetrack Avatar System — Concept Map`, 2026-05-23 product handoff): no modular gear, no random unrelated unlocks, no abrupt identity swaps. Drip-fed skin themes (Pilgrim → Hunter → Frostwalker → …) keep the player's chosen race visually consistent.

---

## What shipped (2026-05-22 → 2026-05-23)

### Photo upload removal

Hard-deleted to avoid two parallel identity systems coexisting:

* `SocialProvider.uploadCurrentProfilePhoto` + `updateCurrentPhotoUrl` + helpers
* `AvatarSelectionProvider` (entire provider + `AvatarCatalog`)
* `assets/avatars/` (18 legacy PNGs)
* `image_picker`, `image_picker_android`, `image_picker_platform_interface`, `firebase_storage` pubspec deps
* `welcomeStep1Gender*`, `welcomeStep1Selected`, `welcomeStep1Upload*`, `socialPhoto*`, `avatarLabel*` ARB keys (en + cs)
* `social_profile_photos` Storage bucket reference in `docs/site/data/`

**Note:** `auth.user.photoUrl` (Google Sign-In identity) is still READ in legacy compact-avatar surfaces. The Storage upload flow is gone; the read path will be migrated to race × skin rendering as part of the compact-thumbnail commit (open).

### Domain skeleton

* `CosmeticType.skin` enum value (last position, additive).
* `Skin extends Cosmetic` sealed subtype.
* `Loadout.skinId` (new slot, fully wired through `slotId`, `copyWithSlot`, `copyWith`, `==`, `hashCode`).
* `UserCosmeticsState.selectedRaceId` (nullable; `null` pre-onboarding / pre-force-pick).
* Isar `CosmeticsUserStateRecord.{skinId, selectedRaceId}` — schema regenerated via `dart run build_runner build --delete-conflicting-outputs`. Additive nullable fields; Isar opens old records cleanly with both as null.
* `CosmeticsConfig.standard()` allowedSlots += `CosmeticType.skin`; `validate()` and `_bucketFolder` handle the new slot.
* Exhaustive switches updated in 10 UI / celebration surfaces (`cosmetic_asset_thumb`, `cosmetic_collection_tile`, `cosmetic_equipped_chip`, `cosmetics_inventory_section`, `cosmetics_screen`, `cosmetics_screen_internals`, `progression_engine_celebration_adapter`, `hero_screen`, `engine_companion_pill`, plus `cosmetic_models.dart` itself) with placeholder `skin` cases (Icons.person, "Vzhled" label, `CelebrationRewardKind.frame` placeholder).

### Race catalog + resolver

* `HeroRace` model (id, asset folder, name closure, description closure).
* `HeroRaceCatalog` — 9 entries in design grid order: Human m/f → Elf m/f → Dwarf m/f → Orc → Spirit → Golem. Male and female variants of the same species share l10n keys (`heroRaceHumanName` → "Človek" for both); gender is communicated visually, not in labels.
* `SkinAssetResolver` — `(raceId, skinAssetKey, variant)` → `assets/cosmetics/skins/<race.folder>/<skin>_<full|thumb>.png`. Null fallback for pre-onboarding / unknown race / malformed asset key (callers render a silhouette placeholder).
* `SkinAssetVariant { fullBody, thumbnail }` — `_full` for profile hero / onboarding preview, `_thumb` for compact framed surfaces.
* 12 ARB keys × 2 langs for 6 species (name + desc).

### Repository / Service / Provider plumbing

* `CosmeticsRepository.selectRace({uid, raceId})` — abstract; thin persistence boundary, no catalog validation at repo level.
* `IsarCosmeticsRepository.selectRace` — write transaction, seeds default state if missing.
* `InMemoryCosmeticsRepository.selectRace` + `clearAllUnlocks` parity fix (now wipes `selectedRaceId` to match Isar impl).
* `CosmeticsService.selectRace(uid, raceId)` — validates against `HeroRaceCatalog`, throws `CosmeticsException('race_not_found')` on typo.
* `CosmeticsProvider.selectRace(raceId)` — mirror of existing `equip()` flow (try/catch CosmeticsException → errorMessage).
* `CosmeticsProvider.currentRaceId` — convenience getter on `state?.selectedRaceId`.

### Starter skin

* `Skin(id: 'skin_pilgrim', rarity: common, region: neutral, sortOrder: 800)` in `CosmeticCatalog.definitions`.
* `CosmeticCatalog.skins` getter (consistency with frames / backgrounds / etc.).
* 3 ARB keys × 2 langs (Pilgrim / Poutník + desc + unlock hint).

### Asset pipeline (pilgrim set only)

* 9 races × 2 variants = **18 PNGs** at `assets/cosmetics/skins/<race>/pilgrim_{full,thumb}.png`.
* Full: 512×512, transparent background, figure stands ~48 px above bottom edge, head varies by race.
* Thumb: 512×512, square with own background.
* `pubspec.yaml` declares each race folder explicitly.
* Rendered with `FilterQuality.none` for crisp pixel-art downscale.

### Onboarding Step 1 rewrite

* `StepWelcome` is now a lightweight wrapper over the shared `RacePickerView`.
* `WelcomeScreen._draftRaceId` holds local UI draft (seeded from `cosmeticsProvider.currentRaceId` in `didChangeDependencies` for re-entered onboarding, else from `HeroRaceCatalog.definitions.first`).
* `WelcomeScreen._finish()` commits the **atomic trio** once a uid is bound:
  1. `cosmeticsProvider.selectRace(draftRaceId)`
  2. `cosmeticsProvider.unlock('skin_pilgrim', sourceType: defaultBaseline)` if not already owned
  3. `cosmeticsProvider.equip('skin_pilgrim')` if not already equipped
* Pre-sign-in path (skip button at Step 2) logs a warn and proceeds — degraded mode without persistence, by design.
* `lib/main.dart`, `FactoryResetService`, `FactoryResetDeps`, `DevToolsFactoryResetSection` — drop all `AvatarSelectionProvider` wiring. Race wipe goes through the existing `cosmeticsProvider.bindUser(null)` → Isar `clearAll` cleanup path.

### `RacePickerView` shared widget

* Public `StatefulWidget` in `lib/features/onboarding/presentation/race_picker_view.dart`.
* Owns its own sparkle `AnimationController` so callers don't manage lifecycle.
* Props: `draftRaceId`, `onPickRace`, `title`, `subtitle`, `subtitleAccent`, `levelLabel`.
* Internal layout: hero preview (168 outer halo + 132 inner figure framed in 3 px accent ring + 4 sparkles + level pill) → title → subtitle → fixed **3×3 grid** of race tiles (72 px max cap) → race tag.
* Hero preview uses the **thumbnail** variant — square framed composition reads better at 132 px than the full-body silhouette.
* Used by `StepWelcome` (inside onboarding PageView) AND `ForcePickRaceScreen` (full-screen modal).

### Profile hero card redesign

`lib/features/social/presentation/widgets/profile_detail_hero_card.dart`:

| Element | Before (pre-2026-05) | After |
|---|---|---|
| Identity block | left of avatar, top:24 | **top-left, top:16** |
| Emblem grid | bottom-left, 4·4·3 layout, 52 px tiles | **top-right, 3·3·3·2 layout, 44 px tiles** |
| Avatar | top-left, 140 px tilted framed | **bottom-left, 200 px no-frame full-body** (1.5× companion) |
| Companion | bottom-right | unchanged |

* `_FramedAvatar` class deleted (frame border reserved for compact thumbnail surfaces).
* New `_HeroBodyAvatar` widget — `SkinAssetResolver(fullBody)` → `Image.asset(filterQuality: none)` → `_HeroSilhouette` fallback.
* Props: dropped `photoUrl`, added `raceId` + `skinId` (nullable).
* `social_user_profile_screen.dart` derives both from `CosmeticsProvider` for own profile; friend profiles pass null (silhouette fallback — wire format extension pending).

### Compact thumbnail rendering

Every UI surface that previously read `photoUrl` (Google identity avatar) now renders the race × skin thumbnail inside the equipped Frame cosmetic border:

* `lib/shared/widgets/profile_avatar_action.dart` (top app bar) — watches `CosmeticsProvider` for raceId / skinId / frameId, falls back to a Material person icon pre-onboarding or signed out.
* `lib/features/social/presentation/widgets/social_avatar.dart` — primitive accepts `raceId` + `skinId`; resolves via `SkinAssetResolver(thumbnail)` and paints the asset. `photoUrl` kept ONLY as a transitional fallback for legacy share-actor snapshots that predate the race system. Initials are the final fallback.
* `lib/features/social/presentation/widgets/social_cosmetic_avatar.dart` — composes the inner skin thumb with the Frame border via `CosmeticFramePreview`. Reads `raceId` + `equippedCosmetics.skinId` + `equippedCosmetics.frameId` from `profile` by default, or honors explicit overrides for own-user callsites that source identity from `CosmeticsProvider` directly.
* `lib/features/social/presentation/widgets/hero_progression_header.dart` — reads own race / skin from `CosmeticsProvider` and threads through `_HeaderBody` → `_IdentityRow` so the header never paints the Google identity selfie.
* `lib/features/settings/presentation/sections/settings_header_section.dart` — Google-account card swaps its `NetworkImage(photoUrl)` chip for the framed skin thumb (with person-icon fallback pre-pick).
* `social_feed_card.dart`, `social_notification_card.dart`, `social_profile_friends_section.dart`, `social_leaderboard_tab.dart`, `social_friends_tab.dart` — unchanged at the callsite level; they pass `profile:` and the avatar primitive now auto-derives raceId/skinId from the wire format extension below.

**Design path locked: Path A.** Thumbnails keep their own baked-in background. The Frame border surrounds the existing self-contained square card. The equipped Background cosmetic does NOT show through in compact surfaces (only the profile hero card scene shows it). Rationale: faster to ship; the only requirement to switch to Path B would be reshooting all 9 race thumbs as transparent face crops, which is significant art rework deferred until product locks the look.

### Social wire format extension

`SocialUserProfile.raceId` + `SocialEquippedCosmetics.skinId` now flow over the Firestore wire format so friend profiles render the same race × skin treatment as own profile.

* `SocialUserProfile.raceId` (nullable), `SocialEquippedCosmetics.skinId` (nullable), and `SocialProfileSyncPayload.{raceId, equippedCosmetics.skinId}` extended in `lib/features/social/domain/social_user_profile.dart`.
* `SocialProfileInputs.raceId` added; `SocialProfileProjection.buildPayload` threads it through.
* `SocialProvider._collectProfileInputs` reads `_cosmeticsProvider?.currentRaceId` and `_buildEquippedCosmeticsSnapshot` includes `skinId`. The proxy provider re-fires `bind()` whenever cosmetics state changes, so `_syncProfileIfNeeded()` republishes on race-pick / skin-equip.
* `_buildProfileSignature` includes both fields, so the dedupe debounce republishes on change.
* `FirestoreSocialRepository._profileData` writes `raceId` (top-level) + `equippedCosmetics.skinId`; `_mapUserProfile` reads them back. Legacy docs without the fields hydrate with null and fall through to silhouette / initials.
* No Firestore rules change required — the existing per-uid write rule does not validate equippedCosmetics field shape, so additive subfields land cleanly.

Friend devices that haven't republished yet appear with initials in compact surfaces. The first state change on their end (force-pick run, skin equip, level-up) triggers a re-upsert that fills both fields.

### Force-pick gate

Existing players with completed onboarding but `selectedRaceId == null` (game state predates the race system) are routed through `ForcePickRaceScreen` before MainShell.

`lib/app.dart` routing:
```
!onboarding.isHydrated                                     → _RoutingSplash
!onboarding.isCompleted                                    → WelcomeScreen
signed in && cosmetics.state == null                       → _RoutingSplash
signed in && cosmetics.state.selectedRaceId == null        → ForcePickRaceScreen
otherwise                                                  → MainShell
```

The two splash branches prevent a ~100–500 ms flash of MainShell (and the Google identity avatar leaking through unmigrated compact surfaces) during async hydration. The previous gate had a race condition where MainShell rendered first, then snapped back to ForcePickRaceScreen once state arrived.

`ForcePickRaceScreen` (`lib/features/onboarding/presentation/force_pick_race_screen.dart`):
* `PopScope(canPop: false)` blocks swipe-back + system back.
* Header: "JEŠTĚ JEDEN KROK" / "ONE MORE STEP".
* Body: `RacePickerView` with force-pick-specific copy ("Tvoje cesta začala dřív, než hrdinové měli tvář…").
* CTA: same atomic trio as onboarding `_finish()`. Provider notifies → `app.dart` rebuilds → gate sees non-null raceId → swap to MainShell.

---

## What's open

### Cosmetics screen "Vzhled" tab

A new tab in `CosmeticsScreen` for browsing owned + locked skins, with a details sheet matching the Frames pattern. Today the only way to swap the equipped skin is to use DevTools — there's no in-game UI for it. Low risk; pattern is well-established.

### Skin reward content

The starter pilgrim is the only skin shipped. The drip-feed plan from the concept map (Hunter, Frostwalker, Dragonrock Ascendant, prestige themes, achievement themes) is product-pending:

* Per-skin milestone mapping (which achievement / level / chapter grants which theme).
* Per-race artwork for non-pilgrim themes — 9 race variants × 2 file variants per theme = 18 PNGs per skin. Art-heavy.
* Per-skin availability metadata (`metadata['shippedForRaces']: Set<HeroRaceId>`) so a half-shipped skin shows as locked with "Coming soon for your race" hint instead of breaking on unresolved assets.

Discuss when ready to lock the first non-pilgrim theme.

### Edge cases / polish

* **Companion + avatar overlap on narrow phones.** Avatar 200 px (x: 16→216) and companion 134 px (x: ~210→344) may collide on <360 px screens. If reported, shrink `_kHeroAvatarSize` or shift companion right edge.
* **Variable figure height in hero card.** Tall races (Orc, Golem?) may reach into the emblem grid in the top-right. Audit visually once all 9 race assets land in their final form.
* **Celebration treatment for skin unlocks.** Today `progression_engine_celebration_adapter.dart` maps `CosmeticType.skin` to `CelebrationRewardKind.frame` as a placeholder. When the first non-pilgrim skin reward ships, design a dedicated celebration animation.

### Tech debt

* `design/design_handoff_avatar_picker_step/` — stale design folder referencing the photo-upload era. Delete or replace with race-picker design notes.
* `docs/site/data/glossary.json` — add `HeroRace`, `Skin`, `SkinAssetResolver`.
* `docs/site/data/decisions.json` — ADR "Avatars promoted to race × skin system" (context: photo upload removal, decision: split identity vs. evolution, alternatives considered).
* `docs/site/data/storage.json` — `CosmeticsUserStateRecord` new fields (`skinId`, `selectedRaceId`).
* `lib/features/cosmetics/README.md` + `lib/features/onboarding/README.md` — update to reflect race × skin model.
* `isar_generator 3.1.0+1` parser issue with `extension type` syntax (pre-existing). Adding new Isar fields requires `build_runner` to walk the package — it crashes on `ids.dart` extension types. The crash is recoverable because the Isar codegen pass completes before the crash and the resulting `.g.dart` is correct; commit it manually. Long-term: bump `isar_generator` once a version with newer analyzer ships.

### Long-term (post-MVP)

* **Re-pick race UI.** Today: race is locked, only DevTools factory reset can clear it. If we later let players re-roll their hero, design a dedicated Settings flow with confirmation.
* **Locked-skin previews per race.** The cosmetics screen could show "what your race would look like" previews for un-owned skins — strong drip-feed motivation.

---

## Key architectural decisions (record)

1. **Race is NOT a Cosmetic.** It never flows through `CosmeticReward` / `CosmeticUnlockBridge`. It's a one-time persistent identity field, alongside (not inside) the cosmetic state record. Rationale: the reward pipeline is for things you earn; race is something you *are*.

2. **Skin catalog entries are race-agnostic.** A single `Skin('skin_pilgrim', ...)` row handles all 9 races. The per-race file path is composed at render time by `SkinAssetResolver`. Avoids a 9× catalog explosion and keeps reward grants uniform across races (one `CosmeticReward(CosmeticId('skin_xxx'))` regardless of who unlocks it).

3. **Two asset variants per skin (`_full` + `_thumb`), no other slots.** Full-body is for profile hero / onboarding preview; thumbnail is for compact framed surfaces. No "head only" or "torso" sub-crops — the artist controls composition for each variant.

4. **Frame border is reserved for compact surfaces.** Profile hero card (and onboarding hero preview) render the skin standalone, without the equipped Frame cosmetic surrounding it. Frames apply on top-app-bar, social feed, friend-chip thumbnails, etc. Composition rule: full body = scene, thumbnail = inventory item.

5. **Race lock is a UI contract, not a repository check.** `CosmeticsRepository.selectRace` accepts overwrites. The lock is enforced by routing (no UI shows after first commit) and by the `PopScope(canPop: false)` on `ForcePickRaceScreen`. Rationale: keeps the repository thin and lets factory-reset → fresh-pick reuse the same code path.

6. **Pre-sign-in race pick is local-only.** Onboarding Step 1 doesn't persist until `_finish()`, because `CosmeticsProvider` writes are uid-keyed and sign-in happens in Step 2. If a user skips sign-in entirely, the race choice is dropped (degraded mode). Documented limitation; not a bug.

7. **Force-pick gate splash is mandatory.** Without `_RoutingSplash` during the hydration window, `MainShell` flashes for ~100–500 ms while the Google identity avatar leaks through unmigrated compact surfaces. The splash is uglier than instant content but cleaner than a visible swap.

---

## Smoke test path

Cold-start with no Isar state (fresh install / factory reset, signed in via Google):

1. **Splash** (~ms) while onboarding prefs + cosmetics state hydrate.
2. **WelcomeScreen** → Step 1 race picker. Tap a tile → hero preview swaps with framed thumbnail of that race's pilgrim.
3. Step 2 sign-in → Step 3 health → Step 4 final → CTA "Hotovo".
4. `_finish()` commits race + starter skin atomically. Onboarding flag flips.
5. **Profile screen** (via top-app-bar avatar tap) → hero card with 200 px full-body pilgrim bottom-left, identity top-left, emblem grid top-right, companion bottom-right.

Existing player (Isar state from before race system, signed in):

1. Splash → `ForcePickRaceScreen` (no swipe back, no system back).
2. Pick race + Potvrdit → atomic trio commits.
3. App returns to **MainShell** (gate sees raceId non-null).

DevTools factory reset → onboarding flag wiped + cosmetics `selectedRaceId` cleared → next app open routes back to WelcomeScreen.

---

## Cold-start file map

For someone new picking up this work:

```
Domain                 lib/features/cosmetics/domain/
                         cosmetic_models.dart       — Skin, Loadout.skinId, UserCosmeticsState.selectedRaceId
                         hero_race.dart             — HeroRace + HeroRaceId extension type
                         hero_race_catalog.dart     — 9 entries
                         cosmetic_catalog.dart      — skin_pilgrim row
Config                 lib/features/cosmetics/config/
                         skin_asset_resolver.dart   — (raceId, skinAssetKey, variant) → path
                         cosmetics_config.dart      — allowedSlots, bucket folder
Persistence            lib/features/cosmetics/data/
                         cosmetics_repository.dart           — selectRace interface
                         isar_cosmetics_repository.dart      — selectRace impl + round-trip
                         in_memory_cosmetics_repository.dart — selectRace impl + clear parity
                         local/cosmetics_local_models.dart   — Isar record fields
Application            lib/features/cosmetics/application/
                         cosmetics_service.dart     — selectRace validation
                         cosmetics_provider.dart    — selectRace API + currentRaceId getter
Onboarding             lib/features/onboarding/presentation/
                         welcome_screen.dart        — draft race + atomic trio in _finish()
                         onboarding_steps.dart      — StepWelcome wraps RacePickerView
                         race_picker_view.dart      — shared picker UI (hero preview + 3×3 grid)
                         force_pick_race_screen.dart — gate screen for legacy saves
Routing                lib/app.dart                  — 5-branch gate with _RoutingSplash
Profile UI             lib/features/social/presentation/widgets/
                         profile_detail_hero_card.dart       — new layout + _HeroBodyAvatar
                         social_user_profile_screen.dart     — passes raceId + skinId from CosmeticsProvider
Assets                 assets/cosmetics/skins/<race>/pilgrim_{full,thumb}.png  — 9×2 PNGs
                       pubspec.yaml asset entries
L10n                   lib/l10n/app_{en,cs}.arb     — heroRace*, cosmeticSkinPilgrim*, forcePickRace*, cosmeticTypeSkin
```
