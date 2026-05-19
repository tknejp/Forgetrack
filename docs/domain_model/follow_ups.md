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

### ~~R.2 NodeState resolver-internal cleanup~~ ✅ Done 2026-05-19

**Shipped** as `R.2: NodeState → NodeResolution cleanup` (commit lands with this entry). Chose the **boolean-derived alternative** over a sealed `NodeResolution` hierarchy after reading the resolver — only one real consumer (`progression_engine.dart`); `reward_grant_planner.dart` doesn't read state, `progression_display_resolver.dart` doesn't use NodeResolution at all. Sealed subtypes for a 6-line consumer would have mirrored the boolean combinations and reintroduced proposal §7 anti-pattern #6 at the type level. See ADR `r2-noderesolution-cleanup` in [docs/site/data/decisions.json](../site/data/decisions.json) for full context + decision + consequences + alternatives.

**What changed:**

- `enum NodeState { locked, available, completed }` deleted.
- `NodeResolution.state: NodeState` replaced with `NodeResolution.completed: bool` (completion-event candidate this run).
- Engine consumer's `switch (r.state) { case _ when r.state.name == 'completed' … }` collapses to a flat `if (r.completed && !ledger.hasEventKey) … else if (!r.completed && r.eligibleByConditions && r.objectiveCompleted == true && r.node.claimPolicy == ClaimPolicy.manual) …`. The `claimPolicy.name == 'manual'` string compare also replaced with `== ClaimPolicy.manual`.
- Stale `NodeState.locked` doc-comment references in `player_chapter_progress_service.dart`, `player_achievement_shelf_service.dart`, `engine_achievement_view.dart`, `player_achievement_lifecycle.dart`, and one test header rephrased to "resolver classified the node as locked".

**DoD:**

- [x] `enum NodeState` smazán; `NodeResolution` discriminates via the `completed` boolean field (alternative chosen).
- [x] Engine consumer migrated (`progression_engine.dart`); reward grant planner + display resolver verified unaffected (neither read `NodeState`).
- [x] `flutter analyze` clean (77 issues, baseline preserved), `flutter test` pass (514 tests).

---

### R.3 Widget consumer migration — journey map + HC screens + chapter

**Why:** Phase 19 (UI sweep) explicitně time-boxed na 2 features (quests + cosmetics). Phase 13 read projection landed `playerChapterProgress` provider getter ale neuhrnula chapter widgets na něj. Lint `widget-no-logic` baseline 46 (post-V1-delete) zachycuje zbytek.

**Scope:**

- ~~**R.3.a — Journey map sweep**~~ ✅ Done 2026-05-19. Shipped as `R.3.a: journey map widget consumer migration`. All 9 `.where` / `.firstWhere` / `.indexWhere` hits in `journey_interactive_map.dart` annotated with per-line `// lint-ignore: widget-no-logic — <reason>` markers (collision-free layout pick, route-JSON filter, collapsed mini-preview slice, route-line anchor set, current-route-point reduction, post-frame focus index). No `JourneyProvider` extraction — journey has no `application/` layer and `JourneyAdapter` (in `presentation/widgets/`) already builds the `JourneyCheckpoint` presentation VOs with display-state flags from `ProgressionEngineProvider`; the widget filters those pre-built VOs for UI-mode slicing only, no domain derivation. Baseline `widget-no-logic` lowered 46 → 37. See ADR `r3a-journey-map-projections` in [docs/site/data/decisions.json](../site/data/decisions.json) for context + decision + alternatives (incl. why a `JourneyProvider` is deferred until journey grows a second data source).
- ~~**R.3.b — HC screens sweep**~~ ✅ Done 2026-05-19. Shipped as `R.3.b: health-connect screens widget consumer migration`. All 8 hits annotated with `// lint-ignore: widget-no-logic — <reason>`: `body_screen.dart` × 3 (drops records missing optional `bodyFat`/`bodyWater` columns for chart aggregation), `activities_screen.dart` × 3 (UI date filters for today / period selector + bulk-claim eligibility subset), `sleep_screen.dart` × 2 (UI period range + stage-data display filter). Per-hit decision: every filter is either an on-screen period selector slice or a missing-data display skip — no domain state derivation in widgets. Baseline `widget-no-logic` lowered 37 → 29. See ADR `r3b-hc-screens-display-filters` in [docs/site/data/decisions.json](../site/data/decisions.json).
- ~~**R.3.c — Chapter widget migration**~~ ✅ Already shipped (no-op for R.3.c sub-PR). Phase 13 introduced the `playerChapterProgress` read projection (`ProgressionEngineProvider.playerChapterProgress`); Phase 19 (UI sweep) moved chapter quest filtering off `quests_screen.dart` into provider projections `currentChapterQuests` + `nextLockedChapter` (see Phase 19 comment at quests_screen.dart:165-172). `_ChapterSection` consumes the pre-built `chapters` list with zero inline derivation; `EngineChapterCard` reads its `EngineQuestProgress` shape directly with no `.where` hits. Re-verified during R.3.b — `lib/features/progression_engine/presentation/widgets/engine_chapter_card.dart` (752 LoC) and `quests_screen.dart` `_ChapterSection` carry **0 widget-no-logic violations**. The redundant chain-derivation cleanup from the original §2.19 scope landed alongside the Phase 19 sweep (chain quests come from `provider.chainQuestsFor(chainId)`). No additional code change needed; this sub-PR closes by acknowledgement.
- Update Phase 21 lint baselines — expect `widget-no-logic` baseline drop to <20.

**DoD:**

- [ ] No `.where(` / `.firstWhere(` / `.singleWhere(` / `.indexWhere(` over domain collections in `journey/presentation/`, `health_connect/presentation/`, chapter-related `progression_engine/presentation/` (intentional lint-ignore lines documented).
- [ ] Chapter widgets pattern-match on `ChapterLifecycle` exhaustively.
- [ ] Phase 21 baseline `widget-no-logic` lowered + commit ratchet update.
- [ ] `flutter analyze` clean, `flutter test` pass, manuální smoke check journey + chapter screens.

**Risk:** Střední. Journey map je velký legacy widget; chapter migration zasahuje quest screen rendering.

**Estimated size:** R.3.a ~2-3 days; R.3.b ~1 day; R.3.c ~2 days. Can split into 3 PRs.

---

### ~~R.4 Repository contracts hardening~~ ✅ Done 2026-05-19

**Shipped** as `R.4: repository contracts Result hardening` (single commit, no a/b/c split — SocialPresenceRepository alone landed ~250 LoC, total R.4 ~600 LoC, well under the 800 LoC STOP threshold). See ADRs `r4-repository-result-hardening` + `r4-isar-journal-adapter` in [docs/site/data/decisions.json](../site/data/decisions.json) for full context + decision + consequences + alternatives.

**What changed:**

- `SocialPresenceRepository` (16 Future-returning methods) → `Future<Result<T, AppError>>`. FirestoreSocialRepository wraps every call in a shared `_classify('endpoint', () => ...)` helper that routes Firestore failures through `classifyFirebaseError`; DisabledSocialRepository returns `Failure(PermissionError(scope: 'social.<method>'))` for mutating methods + `Success(empty list)` for reads.
- `CosmeticEntitlementsSource.loadForUser` → `Future<Result<List<CosmeticEntitlement>, AppError>>`. CosmeticsProvider's `_applyEntitlements` pattern-matches on the result: transient outage logs `warn` (self-heal on next bind), permanent failure logs `error` with full payload.
- `SocialProvider.lastError: AppError?` added as typed counterpart to the legacy `error: String?` (Czech UI strings unchanged). `_recordError(operation, Object, StackTrace)` now classifies via `classifyFirebaseError` before storing on `_lastError`; `_recordAppError(operation, AppError)` is the direct path for Result.Failure call sites. `_clearError()` resets both surfaces uniformly.
- Stream methods (6 in SocialPresenceRepository) stay raw — `onError:` callbacks already feed `_recordError` which now classifies, so `lastError` populates for stream failures without wrapping every emit in `Success(...)`.
- `ProgressionEngineRepository.loadLedger / appendEvents`, `HealthConnectService` (50+ methods), `KalorickeTabulkyService` HTTP methods — **stay bare** with per-class `// R.4:` rationale comments. Local progression repo never produces a meaningful failure (cloud is wrapped at hybrid outer layer); HC + KT raise typed exceptions classified at the orchestrating provider (FitnessProvider, BackgroundSyncService).
- **IsarJournalAdapter decision: retired.** `LedgerSnapshot` is documented as the canonical Journal-read API for projections + bridges; the abstract `Journal` interface stays as a single-callsite argument shape for `engine.evaluate(InMemoryJournal(ledger.all))`. No new adapter, no migration of existing JournalProjection callers.

**DoD:**

- [x] Repository interfaces return `Future<Result<T, AppError>>` where failure is non-trivial. Sign-out happy-path / pure-domain construction methods stay un-wrapped (documented per-class with `// R.4:` comments — ProgressionEngineRepository, HealthConnectService, KalorickeTabulkyService).
- [x] All provider consumers handle Result via exhaustive `switch`. Result.when() not added — switch pattern matching is the idiomatic Dart 3 form; `if (result case Failure(error: final e))` covers the void-success cases concisely.
- [x] Widget UX surfaces error states via `SocialProvider.lastError: AppError?` getter; existing `error: String?` (Czech messages) continues to flow through `_describeError(originalError)` for backwards compat. CosmeticsProvider doesn't add a typed surface (single internal call site, no widget consumer reads it).
- [x] IsarJournalAdapter decision landed: **retired** per ADR `r4-isar-journal-adapter`. LedgerSnapshot is canonical Journal-read; Journal interface stays for engine.evaluate() argument shape only.
- [x] `flutter analyze` clean (77 issues, baseline preserved), `flutter test` pass (514 tests).
- [x] Lint baselines unchanged — domain-purity / untyped-id / l10n-literal / widget-no-logic all match their 2026-05-19 calibration. The DoD-anticipated drop in `lib/features/*/domain/` domain-purity (25 → ?) doesn't materialise because typed errors already lived in `lib/core/`; R.4 didn't move anything out of feature domain/. R.6 remains the home for the 25 remaining hits.
- [ ] Manual smoke check (airplane mode mid-sync transient failure + revoked Firestore rule permanent failure) is the operator's verification step — code-level wiring verified via tests + the AppError classifier round-trip; the smoke run happens on a debug build before the next session opens.

---

### R.5 Test pyramid hardening

**Why:** Refactor finished with 514 tests but the pyramid stays unit-heavy (`Player.fromJournal`, lifecycles, projections, engine idempotency). Coverage gaps the audit and Phase 9-13 explicitly flagged:

**Scope:**

- **R.5.a — Phase 9-13 retroactive smoke check** (was §2.22) — see rubric below. Operator pass on debug build; outcomes recorded inline.
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

#### R.5.a Smoke check rubric — Phase 9-13 retroactive verification

Per-screen checklist derived from the Test plan + DoD blocks in [archive/migration_plan.md](archive/migration_plan.md) Phase 9-13. Operator pass on a debug build; tick each row as **PASS** / **FAIL — &lt;note&gt;**. Any FAIL with a domain root cause is fixed in the same sub-PR; UI polish regressions get bullet-listed in the closing block (no new follow-ups, per Track A discipline §2 intro).

**Phase 9 — Cosmetic sealed catalog (7 subtypes)** — Cosmetics screen

- [ ] All 7 tabs render without crash: Frame / Background / Companion / Relic / Emblem / TitleFlair / MapEffect.
- [ ] Tab swap is instant; catalog count per tab matches devtools matrix.
- [ ] Inspect any single cosmetic — `is Frame` / `is Companion` / etc. pattern-matched UI (rarity badge + type tag) renders the correct subtype label, **not** the old enum value.

**Phase 10 — PlayerCosmeticLifecycle + Inventory** — `cosmetic_details_sheet`

- [ ] `CosmeticHidden` — sheet refuses to open (or renders the silhouette-only placeholder, per current UX). No name, no portrait, no rarity badge.
- [ ] `CosmeticTeased(rows)` — checklist rows match what the pre-refactor `CosmeticRevealState.rows` would have produced for the same input (no row drift). Identity stays hidden for companions.
- [ ] `CosmeticClaimable(claimVia)` — claim CTA present; "available via &lt;source&gt;" hint shows the resolver's claimVia label.
- [ ] `CosmeticOwned` — claim CTA gone; full identity visible; equip / inspect buttons present per type's loadout slot.

**Phase 11 — Companion lifecycle merge** — companion claim journey

- [ ] Open devtools companion matrix; pick a Hidden companion → details sheet shows silhouette only (`hidesIdentity == true`).
- [ ] Transition the companion to Teased — checklist sheet opens; identity still hidden.
- [ ] Meet the listed requirements; sheet flips to Claimable — claim button enables; identity still hidden.
- [ ] Tap claim — reveal animation plays; sheet ends in Owned; **identity (name + portrait) now visible**.
- [ ] No leftover references to `CompanionState` or `CompanionsRegistry` in the visible UI strings / log payloads.

**Phase 12 — Loadout + EmblemBoard relocation**

- [ ] Loadout: each of 7 slots (frame / relic / background / emblem / companion / titleFlair / mapEffect) accepts an Owned cosmetic of the matching subtype and rejects mismatched types.
- [ ] Swap an equipped cosmetic; profile header / avatar preview updates without a manual refresh.
- [ ] EmblemBoard: 11-slot grid renders in 4+4+3 layout on profile header; pin / unpin an emblem; verify SharedPreferences key `pinned_emblems_{uid}` persists across app restart (sign out + back in is acceptable proxy).

**Phase 13 — ChapterLifecycle + Chapter catalog wrapper** — `_ChapterSection` in `quests_screen.dart` + `EngineChapterCard`

- [ ] `ChapterLocked(gate)` — chapter card shows the locked state with the gate's `UnlockCondition` summary; no underlying quest rows leak through.
- [ ] `ChapterUnlockedNotStarted` — chapter card shows opener entry as next action; no in-progress badge.
- [ ] `ChapterInProgress` — current step quest highlighted; chain progress (X / Y) accurate.
- [ ] `ChapterCompleted` — finale + completion node display as done; side-quests (if any remain unclaimed) still shown as auxiliary.

**Operator outcomes (R.5.a closing block):** *to be filled in after the pass.*

- Pass date: *yyyy-mm-dd*
- Build: *debug, branch `refactor/domain-model-design` @ &lt;sha&gt;*
- Result: *PASS overall* / *FAIL — see fixes below*
- Fixes landed in this sub-PR: *list*
- Code-driven smoke supplement: **none.** Doc-only variant chosen — the lifecycle-state pattern-matching widget tests that would constitute the code-driven smoke layer naturally arrive in R.5.b (celebration reward states) and the existing per-lifecycle widget tests under `test/widgets/`. Adding a parallel smoke layer here would duplicate that coverage for no orthogonal signal.

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
| ~~R.2 NodeState cleanup~~ | ✅ 2026-05-19 | Medium | — |
| ~~R.3 Widget consumer migration (a/b/c)~~ | ✅ 2026-05-19 (a, b shipped; c was already shipped via Phase 13 + Phase 19) | Medium | — |
| ~~R.4 Repository contracts Result hardening~~ | ✅ 2026-05-19 (single commit, ~600 LoC, no a/b/c split) | High | — |
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
