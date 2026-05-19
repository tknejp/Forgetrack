# Forgetrack — Domain Refactor Follow-ups

**Status:** ✅ Finalizováno 2026-05-19 po dokončení Phase 22.
**Predecessor:** [archive/migration_plan.md](archive/migration_plan.md) (původní 22-phase plán, completed).
**Target shape:** [proposal.md](proposal.md) (acceptance criteria §4).

> **Tento dokument je konečný plán uzavření refactoru.** Track A je committed scope dalšího (a posledního) implementačního kola; Track B/C jsou explicitně out-of-scope dokud Track A neuzavře. **Nová follow-up položka nesmí během implementace Tracku A vzniknout** — pokud se objeví něco, co nebylo v Track A, je to buď (i) blocker, který se řeší zastavením + diskuzí s uživatelem, nebo (ii) drobnost, kterou vyřeší ten samý PR. Žádné "přidám si to do follow_ups na později" — refactor se uzavírá, ne nafukuje.
>
> Po dokončení Track A se tento dokument archivuje vedle migration_plan.md a doménový refactor je permanently closed.

---

## 1. Refactor closed — co shipla 22-phase plan

| Stage | Phases | Klíčové deliverables | Branch |
|---|---|---|---|
| A | 0-3 | `lib/domain/` skeleton + purity guard, Identity rename, `Journal` interface + `JournalEvent` + `EventKey` + `PeriodKey` (UTC), catalog rename pass + 7 typed extension types | `refactor/domain-model-design` |
| B | 4-8 | `Player` aggregate + `LevelCurve`, `Player.fromJournal` computed level/XP, `PlayerQuestLifecycle` + `PlayerQuestCatalog`, `PlayerAchievementLifecycle` + `PlayerAchievementShelf` | same |
| C | 9-13 | Sealed `Cosmetic` (7 subtypes), `PlayerCosmeticLifecycle` + `Inventory`, `CompanionState`/`CompanionsRegistry` deleted, `Loadout` + `EmblemBoard`, `ChapterLifecycle` + `PlayerChapterProgress` + `Chapter` wrapper | same |
| D | 14-19 | `GoalBoard` + `PlayerGoal`, `HealthSnapshot` + `NutritionSnapshot`, engine signature refactor (`EngineEvaluationContext` + `LedgerCounters` + `EvaluationOverrides`), `SocialPresence`, `Result<T, AppError>` foundation, UI sweep (quests + cosmetics) | same |
| E | 20-21 | `JournalProjection<T>` + `RebuildFromJournalReason`, grep-based lint matchers + ratchet baselines + `docs/contributing.md` | same |
| F | 22 | V1 progression module deleted | same |

**Acceptance criteria** (z migration_plan.md §4) — splněno všech 7:

- ✅ `lib/domain/` exists with `journal/`, `player/`, `progression/catalog/`, `progression/player/`. Lint guard active.
- ✅ Widgets read pre-built read projections; no `.where` / `.firstWhere` derivation in `build()` for quests + cosmetics (other surfaces deferred → Track A R.3).
- ✅ `Player.level` / `Player.totalXp` computed from Journal events.
- ✅ Sealed lifecycles (`PlayerQuestLifecycle`, `PlayerAchievementLifecycle`, `PlayerCosmeticLifecycle`, `ChapterLifecycle`) are the only state-discrimination mechanism for their domains.
- ✅ Catalog ↔ Instance ↔ History triple explicit for every entity kind (proposal §3.2).
- ✅ `EmblemBoard`, `Loadout`, `Inventory`, `GoalBoard`, `SocialPresence` exist as first-class aggregates / VO.
- ✅ Phase 21 lint rules + `docs/contributing.md` checklist active (with baselined cleanup queue → Track A R.6).

**Out-of-bounds during refactor** (blast radius / scope discipline) → addressed in Track A below.

---

## 2. Track A — Next implementation round (bounded, finite)

Po dokončení Track A je doménový refactor **permanently closed**. Žádné nové sub-phases nebudou added during implementation; pokud něco vznikne, řeší se v rámci téhož PR nebo eskaluje k uživateli.

### ~~R.1 Catalog migration do `lib/domain/` + typed cross-references~~ ✅ Done 2026-05-19

**Shipped** in commits `537335b` (R.1.a — move + cross-reference typing) and `da44091` (R.1.b — lifecycle field enrichment + `PlayerQuest.quest` accessor). See ADR `r1-catalog-domain-migration` in [docs/site/data/decisions.json](../site/data/decisions.json) for the full context + decision + consequences + alternatives. Lint baselines lowered: `domain-purity` (lib/features/*/domain/) 33→25; `untyped-id` (lib/features/*/domain/) 58→36.

**Why:** Phase 3.b.2 migrated **primary** catalog `.id` fields to typed wrappers, ale catalog row classes (Quest, Achievement, Milestone, ChapterCompletion, CompanionAvailability, Relic, ContentUnlock, UnlockCondition) i jejich cross-reference fields zůstaly v `lib/features/progression_engine/domain/`. Proposal §6 vocabulary chce `Quest` v `lib/domain/progression/catalog/`; Phase 6/8/13 zanechaly tři placeholder DoD items (`QuestLocked.remaining`, `AchievementLocked.remaining`, `ChapterLocked.gate`) které nemůžou landnout bez UnlockCondition migration. Tady to uzavřeme jednou pro vždy.

**Scope:**

- Move catalog row hierarchy do `lib/domain/progression/catalog/`:
  - `progression_node_definition.dart` → `lib/domain/progression/catalog/progression_entry.dart` (with sealed `Quest` + 10 subtypes, `Achievement`, `Milestone`, `LevelMilestone`, `ChapterCompletion`, `CompanionAvailability`, `Relic`, `ContentUnlock`).
  - `unlock_condition.dart` → `lib/domain/progression/catalog/unlock_condition.dart` (sealed 11 subtypes).
  - `objective_definition.dart` → `lib/domain/progression/catalog/objective.dart`.
  - `objective_metric.dart`, `objective_scope.dart`, `objective_operator.dart` likewise.
  - `reward_definition.dart` → `lib/domain/progression/catalog/reward_definition.dart`.
  - `claim_policy.dart` / `activation_policy.dart` / `quest_policies.dart` / `quest_display_bucket.dart` / `progress_start_policy.dart` likewise.
  - `content_tag.dart` likewise.
- Catalog content files (~14 in `lib/features/progression_engine/domain/catalog/content/`) keep their location (they're feature-scoped *assembly* of the cross-aggregate types), but their imports flip to `lib/domain/progression/catalog/`.
- Tighten cross-reference field types:
  - `Quest.objectiveId: String` → `ObjectiveId`.
  - `Quest.chainId`, `Quest.chapterId`, `Quest.comboPoolId`, `Quest.dailyTierGroupId` → typed (introduce `ChainId`, `ComboPoolId`, `DailyTierGroupId` extension types).
  - `Quest.prerequisiteNodeIds: List<String>` → `List<ProgressionEntryId>`.
  - `Quest.nextNodeIds` likewise.
  - `Achievement.objectiveId: String?` → `ObjectiveId?`.
  - `Milestone.objectiveId: String` → `ObjectiveId`.
  - `ChapterCompletion.chapterId: String` → `ChapterId`.
  - `CompanionAvailability.companionId: String` → `CosmeticId`.
  - `Relic.relicId: String` → `CosmeticId`.
  - `RewardGrantEvent.{cosmeticId, chapterId, companionId, titleId, emblemId, relicId}` → typed nullable.
- Restore proposal §4 spec on Locked lifecycle variants (waited on UnlockCondition migration):
  - `PlayerQuestLifecycle.QuestLocked` gains `remaining: List<UnlockCondition>` field.
  - `PlayerAchievementLifecycle.AchievementLocked` gains `remaining: List<UnlockCondition>` field.
  - `ChapterLifecycle.ChapterLocked` gains `gate: UnlockCondition` field.
- Restore proposal §2.4 spec on `PlayerQuest`:
  - `PlayerQuest.id: QuestId` → `PlayerQuest.quest: Quest` (full catalog reference; consumers drop the `ProgressionEntryCatalog.definitionForId(id) as Quest` dance).
- Update Phase 21 lint baselines (`test/lint/production_scan_test.dart`) for `untyped-id` after the typed cross-reference rollout — expect ~50-70 line baseline reduction.

**DoD:**

- [x] Žádný progression catalog symbol v `lib/features/progression_engine/domain/models/` ani `domain/catalog/` (kromě catalog content `content/*.dart` files které zůstávají feature-scoped assembly).
- [x] All cross-reference fields are typed (`ObjectiveId`, `ChapterId`, `CosmeticId`, `ProgressionEntryId`, `ChainId`, `ComboPoolId`, `DailyTierGroupId`).
- [x] `QuestLocked.remaining`, `AchievementLocked.remaining`, `ChapterLocked.gate` populated by their respective services.
- [x] `PlayerQuest.quest: Quest` accessor available; `id` getter remains for backwards compat (forwarded as `QuestId(quest.id.value)`).
- [x] Lint baseline `untyped-id` v `lib/features/*/domain/` snížený (58 → 36).
- [x] `flutter analyze` clean (77 issues, baseline), `flutter test` pass (514 tests).

**Risk:** Vysoké. Touches sealed hierarchy + ~30 catalog content files + ~20 widget readers. Doporučení: split do R.1.a (move + cross-reference typing) and R.1.b (lifecycle field enrichment + PlayerQuest.quest accessor). Side-by-side test: existing test fixtures must produce identical evaluation outcomes pre/post migration.

**Estimated size:** 800-1200 LoC, 2-3 days solo. Largest single item in Track A.

---

### R.2 NodeState resolver-internal cleanup

**Why:** Phase 13 inlinovala `NodeState` enum do `progression_node_resolver.dart` jako resolver-internal vocabulary. Engine consumer matches via `r.state.name == 'completed'` string compare. To je remnant z V2 origin design — když existing PlayerXxxLifecycle hierarchy už pokrývá player-facing state, resolver-internal enum je perpetuated technical debt.

**Scope:**

- Convert `enum NodeState` → sealed `NodeResolution` hierarchy uvnitř `progression_node_resolver.dart`:
  - `NodeResolutionLocked(eligibleByConditions: false, ...)`
  - `NodeResolutionAvailable(eligibleByConditions: true, objectiveCompleted: false/true, ...)`
  - `NodeResolutionCompleted(eligibleByConditions: true, alreadyCompleted: true, ...)`
- Engine consumer (`progression_engine.dart`) přechodí z `r.state.name == 'completed'` na `r is NodeResolutionCompleted` is-checks (exhaustive `switch`).
- Alternative if sealed is overkill: drop enum, derive transitions inline from `(eligibleByConditions, objectiveCompleted, alreadyCompleted, alreadyClaimed)` booleans on `NodeResolution`.

**DoD:**

- [ ] `enum NodeState` smazán; `NodeResolution` carries discrimination via subtypes (or via boolean fields if alternative chosen).
- [ ] Engine consumer + reward grant planner + display resolver all migrated.
- [ ] `flutter analyze` clean, `flutter test` pass.

**Risk:** Střední. Resolver internals — well-tested by existing engine idempotency suite.

**Estimated size:** ~200-300 LoC, 1 day solo. Can fold into R.1 if appetite allows.

---

### R.3 Widget consumer migration — journey map + HC screens + chapter

**Why:** Phase 19 (UI sweep) explicitně time-boxed na 2 features (quests + cosmetics). Phase 13 read projection landed `playerChapterProgress` provider getter ale neuhrnula chapter widgets na něj. Lint `widget-no-logic` baseline 46 (post-V1-delete) zachycuje zbytek.

**Scope:**

- **R.3.a — Journey map sweep** (was Phase 19.c follow-up §2.18):
  - `lib/features/journey/presentation/widgets/journey_interactive_map.dart` (1200 LoC, 5 hits).
  - Extract checkpoint filter projections (`unlocked / pathAnchors / visibleCheckpoints`) na `JourneyProvider` nebo `playerChapterProgress` derivace.
  - Per Phase 19 STOP threshold convention: bigger architectural pass than quests/cosmetics, dedicated PR.
- **R.3.b — HC screens sweep** (was Phase 19.d follow-up §2.18):
  - `body_screen.dart` (3 hits), `activities_screen.dart` (3 hits), `sleep_screen.dart` (2 hits).
  - Determine per-hit whether filter is domain-derived (move to provider) or UI-driven (stay + `lint-ignore`).
- **R.3.c — Chapter widget migration** (was §2.19, Phase 13.b):
  - `engine_chapter_card.dart` (752 LoC) consume `playerChapterProgress.byId(chapterId).lifecycle` instead of deriving inline.
  - `quests_screen.dart` `_ChapterSection` consume `progress.inProgress / progress.completed` accessors.
  - Drop redundant chain-derivation utilities from view models.
- Update Phase 21 lint baselines — expect `widget-no-logic` baseline drop to <20.

**DoD:**

- [ ] No `.where(` / `.firstWhere(` / `.singleWhere(` / `.indexWhere(` over domain collections in `journey/presentation/`, `health_connect/presentation/`, chapter-related `progression_engine/presentation/` (intentional lint-ignore lines documented).
- [ ] Chapter widgets pattern-match on `ChapterLifecycle` exhaustively.
- [ ] Phase 21 baseline `widget-no-logic` lowered + commit ratchet update.
- [ ] `flutter analyze` clean, `flutter test` pass, manuální smoke check journey + chapter screens.

**Risk:** Střední. Journey map je velký legacy widget; chapter migration zasahuje quest screen rendering.

**Estimated size:** R.3.a ~2-3 days; R.3.b ~1 day; R.3.c ~2 days. Can split into 3 PRs.

---

### R.4 Repository contracts hardening

**Why:** Phase 18 shipla `Result<T, AppError>` foundation + outermost data layer wrappy (hybrid progression repo + BackgroundSync). Repository **interfaces** (`SocialPresenceRepository`, `PlayerRepository`, `InventoryRepository`, gateway services) zůstaly s `Future<T>` return types. Cascade do ~12 widget consumers byla vědomě deferred. R.4 to dokončí.

**Scope:**

- Migrate repository interface methods returning `Future<T>` (where failure is meaningful) na `Future<Result<T, AppError>>`:
  - `SocialPresenceRepository` (16 methods × 12 SocialProvider call sites + downstream widget readers — biggest cascade).
  - `KalorickeTabulkyService` HTTP methods.
  - `HealthConnectService` quota-prone methods.
  - `FirestoreCosmeticEntitlementsSource.loadForUser`.
  - `ProgressionEngineRepository.loadLedger` / `appendEvents` hot-path — verify performance acceptable with Result wrapping.
- Provider consumer migration: pattern-match on Result, expose `.error` for widget UX where needed.
- Concrete `IsarJournalAdapter` (was §2.13): write the adapter when first consumer (cosmetic_unlock_bridge or PlayerQuestCatalogService) routes through Journal. Phase 20 `JournalProjection<T>` framework is the natural caller — but its existing implementations (`CosmeticUnlockBridge`, `SocialProfileProjection`) read from `LedgerSnapshot` directly. Decision: keep direct LedgerSnapshot reads (Journal interface remains a documented capability, not a forced abstraction) OR introduce adapter + migrate the two existing projections.

**DoD:**

- [ ] Repository interfaces return `Future<Result<T, AppError>>` where failure is non-trivial. Sign-out happy-path methods (e.g., `PlayerRepository.load` returns `Player.anonymous`) stay un-wrapped.
- [ ] All provider consumers handle Result via exhaustive switch or `Result.when(success, failure)`.
- [ ] Widget UX surfaces error states via `provider.lastError: AppError?` getter or equivalent.
- [ ] Decision on IsarJournalAdapter: either ship adapter + migrate 2 existing projections, or document `LedgerSnapshot` as the canonical Journal-read API and retire the Journal interface goal.
- [ ] Phase 21 lint baseline `domain-purity` snížený (typed errors live in `lib/core/`, not feature `domain/`).
- [ ] `flutter analyze` clean, `flutter test` pass.

**Risk:** Vysoké. Repository contracts touch every provider method that returns data. Off-by-one in Result mapping silently propagates. Mitigation: side-by-side fixture comparison.

**Estimated size:** 600-800 LoC, 2-3 days solo. Largest after R.1.

---

### R.5 Test pyramid hardening

**Why:** Refactor finished with 514 tests but the pyramid stays unit-heavy (`Player.fromJournal`, lifecycles, projections, engine idempotency). Coverage gaps the audit and Phase 9-13 explicitly flagged:

**Scope:**

- **R.5.a — Phase 9-13 retroactive smoke check** (was §2.22):
  - Dev pass through Cosmetics screen tabs / companion claim journey / cosmetic_details_sheet checklist / Loadout slot equip / EmblemBoard 11-slot grid / chapter screens. Validate behavior parity against pre-refactor expectations. ~1-2 hod manual work.
  - Document outcomes in this file under "completed" once done.
- **R.5.b — Celebration widget golden tests** (was §2.5):
  - 3 golden tests: topsheet (single XP), fullscreen (chapter completion legendary), companion claim reveal (fullscreen with animation final frame).
  - Adopt `golden_toolkit` or `flutter_test` built-in matchers.
- **R.5.c — Firebase Emulator integration tests** (was §2.4):
  - 1-2 integration tests using Firestore Emulator + Isar in-memory: full pull-and-merge flow on cold install, hybrid repo write-through under simulated network failure.
  - Add `integration_test` dev-dependency.

**DoD:**

- [ ] R.5.a smoke pass complete; outcomes recorded (no regressions OR list of regression fixes that follow).
- [ ] R.5.b: 3 golden tests pass; pixel-diff baseline committed.
- [ ] R.5.c: 1-2 emulator integration tests green; CI setup documented in `docs/contributing.md`.
- [ ] Total test count ≥ 540 (current 514 + ≥ 26 new).

**Risk:** Nízké. Test addition can't regress existing behavior.

**Estimated size:** R.5.a ~½ den, R.5.b ~1 den, R.5.c ~2 dny. Total ~3-4 days.

---

### R.6 Phase 21 lint baseline cleanup

**Why:** Phase 21 shipla matchers + ratchet but pre-existing violations (post-V1-delete baselines: `domain-purity` 33, `untyped-id` 7+58, `l10n-literal` 19, `widget-no-logic` 46) zůstávají. R.1, R.3, R.4 sníží některé naturally; R.6 dorazí zbytek nebo intentionally-acknowledge přes `lint-ignore` markers.

**Scope:**

- After R.1, R.3, R.4 land, run `flutter test test/lint/production_scan_test.dart` and capture new baselines.
- For each remaining violation:
  - Option (a): fix it (extract logic, type the id, ARB the string, refactor the domain import) → lower baseline by 1.
  - Option (c): mark `// lint-ignore: <rule> — <reason>` if intentional design (e.g., `JournalEvent.eventKey: String` storage boundary) → lower baseline by 1.
- Aim for terminal state: every baseline ≤ 5, where remaining = documented intentional design choices.

**DoD:**

- [ ] All four lint baselines lowered to terminal acceptable values.
- [ ] Remaining violations have `lint-ignore` comments with one-line reasons.
- [ ] `docs/contributing.md` updated if a new acceptable-violation pattern emerges.

**Risk:** Nízké. Each fix is per-file mechanical. Ratchet prevents accidental re-introduction.

**Estimated size:** ~2 days solo, opportunistic (touches many files lightly).

---

### R.7 Companion catalog audit closure

**Why:** Phase 11 reverse-parity test odhalil 3 companions claim via `RewardGrant(CosmeticReward)` from other progression nodes (not via dedicated `CompanionAvailability` row): `companion_bridge_gargoyle`, `companion_cave_lynx`, `companion_aurora_stag`. To je content-authoring inconsistency, ne regression — ale necháno nedořešené.

**Scope:** Pick one of:

- **(a) Add explicit `CompanionAvailability` row pro každý companion** → uniform claim flow přes `claimNode` for all. Catalog change in `companions_content.dart` (~30 LoC).
- **(b) Add `Cosmetic.metadata['instantClaim'] = true` flag** for the 3 affected companions → devtools matrix + claim sheet skip them. Catalog metadata change.
- **(c) Status quo + explicit doc** v `companions_content.dart` comment that reward-tabular claim is acceptable for cosmetic-only grants without availability gating.

**DoD:**

- [ ] Decision documented in catalog + (a)/(b)/(c) implemented consistently.
- [ ] Forward parity test (every Companion → has either CompanionAvailability node OR instantClaim flag OR explicit-doc whitelist) added to catalog validator.
- [ ] `flutter test` pass.

**Risk:** Nízké. Content-only change.

**Estimated size:** ~½ day solo.

---

### R.8 Periphery cleanup bundle

Drobnosti, které stojí samostatně, ale fit do jednoho PR pokud appetite:

- **§2.12 Daily quest periodKey legacy data audit:** Phase 2 UTC enforcement applies to new code. Existing Firestore `engineQuestOfferings` + `engineObjectiveCompletions` documents may carry pre-UTC periodKeys. Devtools "ledger consistency check" panel: walk per-user collections, flag entries whose periodKey doesn't match `PeriodKey.fromRaw(stored).raw`. Manual cleanup tooling if drift entries exist.
- **§2.14 Phase 3.c stylistic refinements:** `quest.id == 'literal'` → `quest.id == const ProgressionEntryId('literal')`. Opportunistic, not a sweep — fix at file-touch time. R.6 lint cleanup naturally surfaces remaining hot spots.
- **§2.24 PlayerQuestLifecycle timestamp enrichment:** `QuestCompletedPendingClaim.completedAt` + `QuestClaimed.claimedAt` populated by `PlayerQuestCatalogService` from ledger event timestamps. Only do this when a UI surface actually requests relative-time hints ("claimed 2h ago"); otherwise the `null` placeholder is fine.

**DoD:** Each item either landed (with PR commit) or explicitly documented as "won't do — not actionable until a concrete trigger fires".

**Risk:** Nízké. Mechanical or skip-if-not-needed.

**Estimated size:** ~1 day if all three done; less if any skipped.

---

### Track A summary

| Item | Estimated size | Risk | Bundled with |
|---|---|---|---|
| ~~R.1 Catalog migration + typed cross-references~~ | ✅ 2026-05-19 (`537335b` + `da44091`) | High | — |
| R.2 NodeState cleanup | 1 day | Medium | Optionally R.1 |
| R.3 Widget consumer migration (a/b/c) | 5-6 days total | Medium | Split into 3 PRs |
| R.4 Repository contracts Result hardening | 2-3 days | High | — |
| R.5 Test pyramid hardening (a/b/c) | 3-4 days total | Low | Split into 3 PRs |
| R.6 Lint baseline cleanup | 2 days | Low | After R.1, R.3, R.4 |
| R.7 Companion catalog audit | ½ day | Low | — |
| R.8 Periphery bundle | 1 day | Low | Optional |

**Total realistic time-frame:** 3-4 týdny part-time (mirrors original Stage estimate proportionally). After Track A closes, this document moves alongside `migration_plan.md` into `archive/`.

---

## 3. Track B — Long-term initiatives (explicitně out-of-scope Track A)

Tyto položky jsou **přijaté jako out-of-scope tohoto refactoru**. Mají vlastní lifecycle a samostatné design exercises. Pokud uživatel chce některý z nich pustit, je to **nová iniciativa**, ne pokračování doménového refactoru.

### B.1 Cloud-hosted catalogs / configs (původně §2.1)

Catalog content (Quests, Cosmetics, Achievements, Chapters) přesun do Firestore (`config/catalogs/{kind}/{id}`). App pull-and-cache; změna obsahu = Firestore update bez release.

**Velikost:** ~1-2 měsíce solo. Schema versioning, offline fallback, l10n closure serialization, cache invalidation.

**Pre-conditions:** Domain refactor closed. `QuestCatalog` / `CosmeticCatalog` / `AchievementCatalog` interfaces (which Track A R.1 puts in `lib/domain/`) become swap points.

**Related:** [memory/project_config_system.md](../../memory/project_config_system.md).

### B.2 Three-layer Config System (původně §2.2)

`BuildConfig` (compile-time) / `UserSettings` (per-user cloud-synced) / `AdminConfig` (server feature flags).

**Velikost:** ~3-4 týdny solo. Cross-cutting, touches every preference store.

**Pre-conditions:** Track A R.1 completion — `Player.rpgModeEnabled` + `GoalBoard.goals` become natural UserSettings layer candidates.

**Related:** [memory/project_config_system.md](../../memory/project_config_system.md), [docs/config_model/](../config_model/).

### B.3 Persistence schema migration framework (původně §2.3)

Schema-versioned Isar collections + Firestore deterministic migrations. `MigrationRunner` per database. Each collection gets `schemaVersion: int` field.

**Velikost:** ~1-2 týdny design + ongoing per-migration tax.

**Pre-conditions:** First time you genuinely need to change a stored field. Until then `flutter pub run build_runner build --delete-conflicting-outputs` + factory reset on dev devices is acceptable.

### B.4 V2 background quest + achievement notifications (původně §2.26)

WorkManager background sync detects newly-granted quest rewards + newly-unlocked achievements via V2 engine, pushes push-style notifications.

**Velikost:** ~150-200 LoC + headless-isolate integration test.

**Pre-conditions:** Product feedback explicitly asks for it. Current behavior (notifications when user opens app, V2 engine evaluates on bind) is acceptable for personal-use scope.

---

## 4. Track C — Decided-against (until triggered)

Tyto items **nebudeme proaktivně řešit**. Pokud konkrétní trigger nastane (jank, real-user bug report, schema drift), revisit jako one-off PR. Jinak žádná akce.

### C.1 Provider rebuild granularity (původně §2.6)

Switch `context.watch<XxxProvider>()` → `Selector<XxxProvider, T>` nebo split provider tree. Perf optimization.

**Trigger:** Jank odhalen v reálném použití nebo v Track A R.3 widget sweep.

### C.2 Cosmetic entitlements eventual consistency (původně §2.8)

`FirestoreCosmeticEntitlementsSource.loadForUser()` is read-once on init. Promotional Cloud Function grants visible až after app restart.

**Trigger:** Cloud Function-based promo grants become real feature (today hypothetical).

### C.3 Firestore codec strict mode (původně §2.9)

`firestore_progression_engine_gateway.dart` silently maps unknown `rewardKind: "alien"` → `RewardGrantKind.xp` via `orElse`. Optional `strict: bool` mode for dev/CI.

**Trigger:** Externí Cloud Functions ever write to engine collections (today hypothetical) OR observed silent schema drift.

### C.4 BackgroundSync sophistication beyond Result classification (původně §2.11 partial)

Phase 18 landed transient/permanent error classification + WorkManager retry decision based on `error.isTransient`. Full exponential backoff per error category + alert escalation for permanent errors není done.

**Trigger:** BackgroundSync failure reports show real user-visible degradation. Current "transient → WorkManager native retry, permanent → return false + log" is acceptable.

---

## 5. Track D — Completed during refactor (archive)

Tyto items se shipped pre-refactor nebo as side-effect of phases — closed before Track A starts.

| Original § | What | Where | Status |
|---|---|---|---|
| §2.7 | Explicit Firestore persistence + `cacheSizeBytes: CACHE_SIZE_UNLIMITED` | `lib/main.dart:131-138` | ✅ commit `98eb58b` (2026-05-18) |
| §2.10 | Promote `engine ledger push` log level debug→info | `firestore_progression_engine_gateway.dart:70` | ✅ commit `98eb58b` (2026-05-18) |
| §2.11 partial | AppError-typed sync errors + WorkManager retry decision based on `isTransient` | `lib/core/errors/`, `hybrid_progression_engine_repository.dart`, `background_sync_service.dart` | ✅ Phase 18 (`c09db65`, 2026-05-18). Full backoff sophistication moved to Track C.4. |
| §2.12 partial | PeriodKey UTC enforcement v factory (new code) | `lib/domain/journal/period_key.dart` | ✅ Phase 2 (`1935f7b`, 2026-05-17). Legacy data audit moved to Track A R.8. |

---

## 6. Cross-references

- **Smell items v kódu** (TODO markers): [sheet_export_field.dart](../../lib/features/sheets_export/domain/sheet_export_field.dart#L1), [bushido_export_config.dart](../../lib/features/coach_log_export/domain/bushido_export_config.dart#L1), [activity_record.dart](../../lib/features/health_connect/domain/activity_record.dart#L10).
- **Memory notes:** [project_config_system.md](../../memory/project_config_system.md), [project_logging.md](../../memory/project_logging.md).
- **Architecture:** [architecture.md](../architecture.md), [proposal.md](proposal.md), [archive/migration_plan.md](archive/migration_plan.md).
- **Lint:** [docs/contributing.md](../contributing.md), [test/lint/production_scan_test.dart](../../test/lint/production_scan_test.dart).
