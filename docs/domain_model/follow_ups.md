# Forgetrack — Domain Refactor Follow-ups

**Status:** Tracked items mimo aktivní migration plan. Catalogue všeho, co nemělo úplný fit do refactoru, ale stojí to za zaznamenání.
**Created:** 2026-05-17.
**Related:** [proposal.md](proposal.md), [migration_plan.md](migration_plan.md).

> Tento dokument je **living checklist**, ne plán. Položky se přesunou do migration plánu, samostatného feature dokumentu, nebo do `archive/` podle toho, jak se jejich osud rozhodne.

---

## 1. Co bylo zfoldováno do migration plánu (v této session)

Tyto věci původně vznikly jako "follow-ups", ale uživatel se rozhodl zapojit je rovnou do refactoru:

| Položka | Žije v | Důvod foldu |
|---|---|---|
| **Stringly-typed identifiers** (QuestId, CosmeticId, ChapterId, ObjectiveId) | [Phase 3.b](migration_plan.md#phase-3--catalog-rename-pass--typed-identifier-rollout) | Silně propojené s rename passem; extension types v Dart 3 = zero overhead. Catch refactoring typos by construction. |
| **L10n strings lint** (žádný `Text('...')` literal) | [Phase 21](migration_plan.md#phase-21--lint-rules--review-checklist) | Lint sweep stejně přijde; přidat 1 pravidlo navíc. |
| **Result/Error type hierarchy** | [Phase 18 (nová)](migration_plan.md#phase-18--resulterror-type-hierarchy) | Audit ukázal silent error swallowing v BackgroundSync + Firestore gateway. Stačí scopovat na domain + repository contracts, ne celý codebase. |
| **PeriodKey UTC enforcement** | [Phase 2](migration_plan.md#phase-2--journal-infrastructure-ledgerevent--journalevent) | Existing Phase 2 zavádí PeriodKey VO; přidat UTC normalizaci v factory řeší timezone-collision bug. |

---

## 2. Deferred — tracked, ale ne v refactoru

### 2.1 Cloud-hosted catalogs / configs

**Současný stav:** Catalogs (Quests, Cosmetics, Achievements, Chapters) jsou immutable Dart const literály v `lib/features/*/domain/catalog/content/*.dart`. Změna obsahu = release nové verze aplikace.

**Cílový stav (vlastní návrh uživatele):** Catalog content žije v Firestore (např. `config/catalogs/quests/{questId}`). App pull-and-cache. Změna questu nebo cosmeticu = Firestore update, žádný release.

**Proč není v refactoru:**

- Vysoká komplexita: schema versioning, offline fallback, cache invalidation, l10n closures (jak je serializovat?).
- Uživatel sám deferoval kvůli nákladu.
- Domain refactor se chová správně bez ohledu, kde catalog fyzicky žije — interface `QuestCatalog` může být local-only nebo cloud-backed; consumeři vidí to samé.

**Kdy to řešit:** Po dokončení domain refactoru. Catalog interface je čistý, takže swap implementation bude tractable. Velikost: ~1-2 měsíce solo, hlavně schema design + migration tooling.

**Související:** [memory/project_config_system.md](../../memory/project_config_system.md) (driver use-case je hidden content + cross-device goal sync).

---

### 2.2 Three-layer Config System (BuildConfig / UserSettings / AdminConfig)

**Současný stav:** Config je rozházený přes `core/config/`, `SharedPreferences` (11 keys), `LocaleProvider`, `GoalsProvider`, `NotificationPreferencesProvider`. Žádná unifikace, žádný cross-device sync goals.

**Cílový stav (uživatelův plán):** Tři vrstvy:

1. `BuildConfig` — compile-time constants (Firebase project ID, env-specific endpoints).
2. `UserSettings` — per-user preference cloud-synced (locale, RPG mode, goals, notification prefs).
3. `AdminConfig` — server-side feature flags (release-gated content, A/B test groups).

**Proč není v refactoru:**

- Cross-cutting, peer-level magnitude k samotnému doménovému refactoru.
- Snazší navrhnout **po** domain refactoru — Player.rpgModeEnabled, GoalBoard.goals jsou jasné kandidáty na UserSettings layer, ale dnes ještě nemají typed shape.
- Reverse order (config first) by design pod nedefinovanou doménou.

**Kdy to řešit:** Po Phase 17 (SocialPresence). V té době máme Player + všechny aggregaty jako stabilní shape; UserSettings sync layer je natural extension.

**Související:** [memory/project_config_system.md](../../memory/project_config_system.md).

---

### 2.3 Persistence schema migration framework

**Současný stav:** CLAUDE.md říká "No migrations unless explicitly requested — app can be reset during development". Žádná schema versioning infrastructure pro Isar (4 DB) ani Firestore.

**Cílový stav:** Schema-versioned collections + `MigrationRunner` (Isar) + Firestore deterministic migrations (idempotent batches). Each collection has `schemaVersion: int` field; app reads max version on startup, runs forward migrations.

**Proč není v refactoru:**

- Refactor explicitně nemění persistence schema (proposal §11 hard constraint).
- Akutní potřeba zatím malá — hobby app, factory reset acceptable.
- Cost: 1-2 týdny design + ongoing tax per migration.

**Kdy to řešit:** Až poprvé budeš potřebovat změnit existující stored field (např. po Phase 9 Cosmetic sealed refactor, pokud bys chtěl přejmenovat `companion_*` ids). Mitigation v migration plánu: současné refactor PR explicitně zakazují schema changes, takže problém se odsouvá.

---

### 2.4 Firebase Emulator integration tests

**Audit finding:** Test pyramid je inverted — ~35 unit tests, **0 widget integration tests, 0 golden tests, 0 Firebase Emulator tests, 0 Isar integration tests**. Pouze `flutter_test` built-in, žádný mocktail/mockito.

**Cílový stav:** Test pyramidu vyvážit:

- Unit (domain pure) — pokrývají sealed lifecycles, Player.fromJournal, ObjectiveEvaluator. Refactor naturally posílí.
- Repository (faked + real) — Isar in-memory tests + Firestore Emulator tests.
- Widget tests s pre-built domain state — verify lifecycle rendering.
- Golden tests pro celebration sheets + companion claim reveal (proposal flagged celebration jako bug-prone).
- End-to-end happy path (1-2 testy across full provider tree).

**Proč není v refactoru:**

- Samostatné úsilí (~2-3 týdny setup).
- Refactor sám sebou produkuje testable domain (Phase 0 lint + sealed types).
- Skoková priorita po Phase 11 (companion bug elimination) — pokud lifecycle merge proběhne hladce, testy nejsou critical; pokud regresuje, testy chybí.

**Kdy to řešit:** Paralelně s Phase 9-11 (Cosmetic + Companion refactor) — to je nejvíc bug-prone území. Konkrétně přidat golden tests pro companion claim reveal + per-state details sheet.

---

### 2.5 Celebration widget tests (zero coverage today)

**Audit finding:** `celebration_router_test.dart` (154 lines) pokrývá jen routing logic. **Žádný widget test** pro topsheet / fullscreen / modal celebration variants. Proposal §1 specificky flagoval celebration jako "bug-prone".

**Cílový stav:** ~3 golden tests pro celebration sheets:

1. Topsheet — small win (single XP reward).
2. Fullscreen — chapter completion (multi-reward, legendary rarity).
3. Companion claim reveal — fullscreen variant with claim animation.

**Proč není v refactoru:** Test coverage gap je samostatný concern, ne struktura. Refactor produkuje cleaner inputs do celebration (`CelebrationEvent` zůstává view payload, viz proposal §2.6).

**Kdy to řešit:** Paralelně s Phase 11 (Companion lifecycle merge) — bug regrese chytá nejvíce pravděpodobně tam.

---

### 2.6 Provider rebuild granularity

**Současný stav:** `context.watch<ProgressionEngineProvider>()` watchuje celý provider. Každý ledger append → rebuild všech downstream widgetů.

**Cílový stav:** `Selector<ProgressionEngineProvider, T>` nebo split provider tree (`PlayerLevelProvider`, `PlayerQuestCatalogProvider` separate). Fine-grained subscriptions.

**Proč není v refactoru:**

- Není to bug, je to perf optimization.
- Refactor naturally redukuje rebuild scope skrz read projections (Phase 7+) — `PlayerQuestCatalog` je immutable snapshot, rebuilds jen když se something changes.
- Pokud Phase 17 (UI sweep) odhalí jank, řešit cíleně tam.

**Kdy to řešit:** Až pocítíš UI jank. Nejpravděpodobnější trigger: 100+ cosmetics screen, 50+ quests screen. Dnes počet entit je menší, tj. neakutní.

---

### 2.7 Offline-first Firestore config (`enablePersistence()`)

**Audit finding:** `enablePersistence()` se v `main.dart` nevolá. Offline queries fall back na network → timeout místo cached serve.

**Cílový stav:** Volat `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true)` v `main.dart` před first usage.

**Proč není v refactoru:** Trivální change (1 řádek). Není to architektonický concern.

**Kdy to řešit:** Lze udělat kdykoliv — netýká se refactoru. Doporučení: udělej to teď před Phase 0, je to 1 PR.

**Akce:** Single-PR side-task. Mimo refactor cestu.

---

### 2.8 Cosmetic entitlements eventual consistency

**Audit finding:** `FirestoreCosmeticEntitlementsSource.loadForUser()` je read-once on init. Cloud Function grant je viditelný až po next app restart.

**Cílový stav:** `Stream<List<CosmeticEntitlement>>` subscription, refresh entitlements live.

**Proč není v refactoru:** Domain refactor neřeší realtime subscription model.

**Kdy to řešit:** Pokud uživatel reálně dostane promotional cosmetic mimo standardní progression. Dnes Cloud Functions side je hypotetický (storage.json says "externí — Cloud Functions"). Nepriorita.

---

### 2.9 Firestore codec strict mode

**Audit finding:** `firestore_progression_engine_gateway.dart:361` mapuje neznámý `rewardKind: "alien"` na `RewardGrantKind.xp` přes `orElse: () => RewardGrantKind.xp`. Schema drift z Cloud Functions je silent.

**Cílový stav:** Optional `strict: bool` mode (dev/CI) — throws on unknown enum. Default loose (current).

**Proč není v refactoru:** Drift edge-case, není root cause refactoru.

**Kdy to řešit:** Pokud někdy Cloud Functions začneš psát externí systém (dnes hypotetické). Test fixture s "alien" enum v strict mode by chytl regrese.

---

### 2.10 AppLog verbosity asymmetry

**Audit finding:** Cloud pull errors at `info` level, push errors at `debug` level. Push failures jsou silent v normal logu.

**Cílový stav:** Push failures at `warn` level minimálně. User v DevTools vidí "sync hanging" symptom.

**Proč není v refactoru:** Trivial 1-line change. Resolved automatically v Phase 18 (Result/Error) — typed errors will surface explicitly.

**Akce:** Před Phase 18 promote push error log level na `warn`. Trivial.

---

### 2.11 BackgroundSync sophistication (retry/backoff/transient classification)

**Audit finding:** `BackgroundSyncService` swallows errors, returns `true` aby zabránil WorkManager retry. Žádný backoff, žádná transient/permanent classification.

**Cílový stav:** Exponential backoff pro transient errors (Firestore offline, KT 401 retry-able), permanent error → return false + alert.

**Proč není v refactoru:** Phase 18 (Result/Error) řeší **error type system**. Sophistication implementation je downstream concern.

**Kdy to řešit:** Phase 22 (V1 cleanup) je natural co-location — background sync se stejně přepisuje (V1 → V2). Foldnout retry/backoff tam.

---

### 2.12 Daily quest periodKey timezone audit (post-Phase 2)

**Audit finding:** Bez UTC normalizace `periodKey: "2026-05-10"` může driftovat při cross-TZ.

**Cílový stav:** Phase 2 v migration_plan.md UTC enforcement vyřeší to **for new code**. Ale existující ledger eventy s drift periodKeys už mohou být ve Firestore.

**Akce:** Po Phase 2 landne — single audit pass `engineQuestOfferings` + `engineObjectiveCompletions` collections per-user pro consistency. Pokud najdeme drift entries, manuální cleanup tooling v devtools.

**Kdy to řešit:** Po Phase 5 (Player computed level/XP), když máme stabilní Journal interface. Devtools "ledger consistency check" panel.

---

### 2.13 Concrete IsarJournalAdapter (deferred from Phase 2)

**Stage A status:** Phase 2 landed the `Journal` abstract interface in `lib/domain/journal/journal.dart` but **did not** ship the concrete `IsarJournalAdapter` that the migration plan originally listed. The interface is currently standalone — no production code calls it yet.

**Cílový stav:** `IsarJournalAdapter` implementuje `Journal` interface a forwarduje na existující `ProgressionEngineDatabase` reads. `HybridProgressionEngineRepository` může implementovat `Journal` přímo (composition) nebo expozovat adapter. First consumer migrates a hot-path read (e.g. cosmetic_unlock_bridge's `eventsForCosmetic`) to use the adapter.

**Proč deferred:** Stage A scope discipline — adapter without a consumer is dead code. Strangler-fig pattern (migration_plan.md §0): write the adapter when the first consumer needs it, not preemptively.

**Kdy to řešit:** Když Stage B nebo C první consumer (typicky `PlayerQuestCatalog` service nebo `cosmetic_unlock_bridge`) potřebuje Journal-style read. Velikost: ~100-150 LoC + integration test.

**Související:** [migration_plan.md Phase 2](migration_plan.md#phase-2--journal-infrastructure-ledgerevent--journalevent).

---

### 2.14 Phase 3.c stylistic refinements (UI / equality)

**Stage A status:** Phase 3.c byla v migration plánu jako "UI + provider call site sweep", ale Phase 3.b.2 design refinement (`implements String` rather than `implements Object`) made typed ids auto-coerce — žádný compile-error cascade nebyl. Sweep tedy efektivně rozpuštěn.

**Co zbývá:** Stylistic improvements:

- `quest.id == 'literal_string'` equality checks → `quest.id == const ProgressionEntryId('literal_string')` pro type-safe comparison.
- `nodeId: someVariable` arguments kde caller drží `String` ale callee chce typed id — explicit wrap `const ProgressionEntryId(someVariable)` pro self-documenting intent.
- `Map<String, X>` → `Map<ProgressionEntryId, X>` v doménových collections kde key reprezentuje catalog row.

**Proč deferred:** Žádný compile error → žádný blocker. `implements String` znamená že existing String-typed code funguje. Refinement je čistě o čitelnosti a explicit typing intent.

**Kdy to řešit:** Lze dělat opportunistic-PR (when touching a file for other reasons, tighten its id types). Nebo dedicated cleanup sweep před Phase 21 (lint rules) — lint pak může enforce "no raw String literals where typed id is appropriate".

---

### 2.15 Inner-catalog reference fields stay String

**Stage A status:** Phase 3.b.2 migrated **primary** catalog row id fields (`ProgressionEntry.id`, `Objective.id`, `Cosmetic.id`) na typed wrappers. **Cross-reference fields uvnitř catalog rows zůstaly String:**

- `Quest.objectiveId` — should be `ObjectiveId`.
- `Quest.chainId` — chain identifier (could be new `ChainId` extension type, or `String`).
- `Quest.chapterId` — should be `ChapterId`.
- `Quest.comboPoolId` — could be `ComboPoolId`.
- `Quest.prerequisiteNodeIds`, `Quest.nextNodeIds` — should be `List<ProgressionEntryId>`.
- `Quest.dailyTierGroupId` — could be typed.
- `AchievementNode.objectiveId` — should be `ObjectiveId?`.
- `Milestone.objectiveId` — should be `ObjectiveId`.
- `ChapterCompletion.chapterId` — should be `ChapterId`.
- `CompanionAvailability.companionId` — should be `CosmeticId` (companion is a Cosmetic).
- `Relic.relicId` — should be `CosmeticId`.
- `RewardGrantEvent.cosmeticId / chapterId / companionId / titleId / emblemId / relicId` — should be typed.

**Cílový stav:** Cross-reference fields use the appropriate typed wrapper for compile-time discrimination.

**Proč deferred:** Phase 3.b.2 scope discipline — primary `.id` field migration was already ~30 catalog files + cascade. Cross-references touch the same files but add another ~50 wrapper insertions. Doable mechanically, but a separate PR keeps blast radius small.

**Kdy to řešit:** Standalone sub-phase 3.b.3 anytime — no Stage B dependency. Or fold into the catalog rollout when touching catalog content files for unrelated reasons.

---

### 2.16 Companions bez `CompanionAvailability` gate (Phase 11 audit gap)

**Phase 11 status:** Phase 11 zrušila `CompanionsRegistry` a zavedla `companionAvailabilityFor(String id)` lookup v `lib/features/cosmetics/domain/companion_availability_lookup.dart`. Reverse parity test (každý node → catalog companion) prošel zelený, ale forward parity (každý cosmetic-side Companion → node) odhalil 3 companions bez explicit gating node:

- `companion_bridge_gargoyle`
- `companion_cave_lynx`
- `companion_aurora_stag`

**Současný stav:** Tyto 3 companions claimují přes `RewardGrant(CosmeticReward)` v reward tables jiných progression nodes, ne přes vlastní `CompanionAvailability` row. Phase 11 to neopravuje protože není to regression — je to authoring-style choice z předchozího catalog designu.

**Možná řešení:**
- (a) Přidat explicit `CompanionAvailability` row pro každý companion → uniformní claim flow přes claimNode pro všechny.
- (b) Označit chybějící 3 companions jako "instant-claim" v `cosmetic_models.dart` metadata flag → matrice + claim sheet by je skipovala.
- (c) Status quo: nechat reward-tabular claim model pro tyto 3, dokumentovat v companions_content.dart.

**Proč deferred:** Phase 11 mandate byl symbol delete (CompanionState/CompanionsRegistry), ne catalog refactor. Audit gap je content-side concern, ne refactor.

**Kdy to řešit:** Před Phase 13 (Chapter catalog wrapper) — pokud chapter chain references companions, uniformní claim flow se hodí. Jinak deferable indefinitely.

---

### 2.17 Phase 18.b — repository contracts return `Result<T, AppError>` (deferred from Phase 18)

**Phase 18 status:** Phase 18 (`c09db65`, 2026-05-18) shipla foundation (sealed `AppError` + `Result<T,E>` v `lib/core/`) + Firebase / KT classifiers + Result-based wrapping na **outermost data layer** (`HybridProgressionEngineRepository` push/pull/wipe + `BackgroundSyncService.backgroundSyncCallback`). DoD audit `grep "catch (.*) {" lib/core/services/` ukázal 0 untyped swallows v sync codepath.

**Co Phase 18 vynechala:** Plan §Phase 18 'Files touched' list explicitně počítal s migrací **domain repository interfaces** (`JournalRepository`, `PlayerRepository`, `InventoryRepository`, `SocialPresenceRepository`) na `Future<Result<T, AppError>>` return types. User explicit scope-directive na Phase 18 ('SCOPE TIGHTLY') vyloučila widget try/catch — ale provider metody, které widgety volají, jsou tou samou hranicí. Migrate repository contracts = cascade do call sites:

- `SocialPresenceRepository` má 16 metod × ~12 SocialProvider call sites + downstream widget readers = ~400 LoC blast radius.
- `PlayerRepository.load` vrací `Player.anonymous` jako sign-out happy case (no error path); migration je no-op + symbolic.
- `JournalRepository` a `InventoryRepository` v plánu jako interfaces **dnes neexistují** ([§2.13 deferred IsarJournalAdapter](#213-concrete-isarjournaladapter-deferred-from-phase-2); Inventory je read projection z Phase 10, ne repository).
- `ProgressionEngineRepository.loadLedger / appendEvents` jsou hot-path každého engine evaluate; každý call site by se musel pattern-matchovat.

**Co dnes funguje bez Phase 18.b:** Outermost data layer audit splněn (hybrid repo + BackgroundSync). Existing AppError + Result types jsou usable adoptovat opportunisticky kdykoli (např. `HybridProgressionEngineRepository.pullEventsClassified()` už je veřejné). Phase 20 JournalProjection landne JournalRepository jako natural place to introduce typed errors at the contract level.

**Kdy to řešit:** Volitelně. Pokud Phase 21 lint pass odhalí silent error sites v provider methods, batch je. Nebo počkat až vznikne konkrétní production issue, kde untyped error swallowing hurts (např. Social profile sync silently failing). Velikost: ~1-2 dny solo per repository.

**Není blocking pro:** Phase 19 (UI sweep — shipped 2026-05-18), Phase 20 (JournalProjection — Stage E entry).

---

### 2.18 Phase 19 leftovers — journey map + Health Connect screens (deferred from Phase 19)

**Phase 19 status:** Phase 19 (`daf5ca6`, 2026-05-18) shipla 2 features (quests_screen + cosmetics_screen) per user scope-directive 'time-box max 3 features'. Anti-pattern audit `grep .where(/.firstWhere(` napříč `lib/features/*/presentation/` identifikoval čtyři další kandidáty které Phase 19 explicitně vynechala:

**Deferred screens (s reason per Phase 19 ADR `ui-sweep-quests-cosmetics`):**

| Soubor | Hits | Důvod deferru |
|---|---|---|
| `lib/features/journey/presentation/widgets/journey_interactive_map.dart` | 5 | Na user-defined STOP threshold (`> 5 instances same anti-pattern v jednom widgetu`). 1200-line file s multiple stateful widget scopes (checkpoints filter v build + map state lifecycle methods) — needs bigger architectural pass. |
| `lib/features/health_connect/presentation/body_screen.dart` | 3 | HC-specific, domain ownership unclear mezi FitnessProvider helpers + view models. |
| `lib/features/health_connect/presentation/activities_screen.dart` | 3 | Same. |
| `lib/features/health_connect/presentation/sleep_screen.dart` | 2 | Same. |

**Explicitně NEdoporučeno k migraci (analyzed, false positive / skip):**

- `lib/features/progression/presentation/quests/quest_screen_sections.dart` (5 hits) — V1 progression, delete-candidate per proposal §9.3.
- `lib/features/social/presentation/widgets/social_feed_card.dart` (2 hits) — UI-only reaction emoji filters per per-interaction sheet rendering, not domain state.

**Návrh sub-phases:**

- **Phase 19.c — Journey map:** dedicated pass on `journey_interactive_map.dart`. Extract checkpoint filter projections (`unlocked / pathAnchors / visibleCheckpoints`) na `JourneyProvider`. Time-box: ~2-3 dny solo.
- **Phase 19.d — Health Connect screens:** body / activities / sleep screens — analyze whether filters are domain-derived (move) or UI-driven (stay). Time-box: ~1 den solo.

**Není blocking pro:** Phase 20 (JournalProjection — Stage E entry). UI sweep je continuous-improvement, ne prerequisite.

---

### 2.19 Phase 13.b — Chapter widget migration (deferred from Phase 13)

**Phase 13 status:** Phase 13 (`b0f982b`, 2026-05-18) shipla read projection foundation: `ChapterLifecycle` sealed (4 stavy), `PlayerChapter` VO, `PlayerChapterProgress` collection, `Chapter` catalog wrapper, `ChapterCatalogBuilder`, `PlayerChapterProgressService`, `ProgressionEngineProvider.playerChapterProgress` lazy getter. Migration plan §Phase 13 'Files touched' list zahrnoval **'Modify: chapter screens, journey map, hero map screen'** — to Phase 13 NEsmysmela.

**Co dnes funguje bez Phase 13.b:** Chapter screens (`engine_chapter_card.dart`, `quests_screen.dart`) čtou pořád z `EngineQuestProgress.state` per-node, derivují chain state ad-hoc. Funkční, ale propaguje chain-state-derivation logic napříč view modely. Provider getter `playerChapterProgress` existuje a je usable opportunisticky kdykoli.

**Co Phase 13.b udělá:** Migrate consumer surfaces na `progression.playerChapterProgress.byId(chapterId).lifecycle` pattern-match + drop redundant chain-derivation utilities ve view modelech. Files identified:

- `lib/features/progression_engine/presentation/widgets/engine_chapter_card.dart` (752 LoC) — hlavní chapter card view, derives ChapterInProgress numerics inline.
- `lib/features/progression_engine/presentation/quests_screen.dart` (907 LoC) — `_ChapterSection` lists chapters; would consume `progress.inProgress / progress.completed` accessors.
- `lib/features/journey/presentation/widgets/journey_interactive_map.dart` — chapter anchors derived from completed-node set. Per [§2.18 deferred Phase 19.c](#218-phase-19-leftovers--journey-map--health-connect-screens-deferred-from-phase-19) journey map needs bigger architectural pass; chapter consumption migration is natural part of that scope.

**Proč deferred:** Phase 7 precedent — `PlayerQuestCatalog` shipped jako read projection v Phase 7; quest widget migration se rozjela opportunisticky later. Phase 13 honors stejný "foundation first, consumer migration opportunistic" pattern. User feedback z Phase 19 ("time-box max 3 features") signalizuje že full-sweep widget migrations stojí samostatnou time-box.

**Kdy to řešit:** Volitelně. Pokud Phase 19.c (journey map sweep) landne, fold chapter consumption tam. Nebo dedikovaná Phase 13.b ~2-3 dny solo.

**Není blocking pro:** Phase 14+ (Stage D), Phase 20 (JournalProjection).

---

### 2.20 NodeState enum eliminace (deferred to Phase 16+ engine signature refactor)

**Phase 13 status:** Phase 13 inlinovala `NodeState` enum (locked / available / completed) z `lib/features/progression_engine/domain/models/node_state.dart` přímo do `progression_node_resolver.dart`. Soubor smazán, enum žije dál jako resolver-internal vocabulary. Engine consumer (`progression_engine.dart`) používá `r.state.name == 'completed'` string compare, takže typ unchanged.

**Co Phase 13 NEzkusila:** Nahradit enum sealed `NodeResolution` hierarchií (Locked / Available / Completed) nebo redukovat na booleany `(eligible, objectiveCompleted, alreadyCompleted, alreadyClaimed)`. Důvod: engine consumer's string-compare už detachly Phase 6 + Phase 8 groundwork; refactoring resolveru je samostatná scope, která zaslouží Phase 16+ engine signature refactor (proposal §16 — `EngineEvaluationInput` → explicit args).

**Co dnes funguje bez Phase 16 changes:** Resolver enum produkuje 3 hodnoty s named string compare. Engine matchuje. Žádný cross-feature import problem (enum žije v resolver file, nikdo nimprtuje).

**Možné cílové stavy:**
- (a) `enum NodeState` → `sealed class NodeResolution` s 3 subtypy v resolver file. Engine consumer přejde z `.name ==` na is-checks.
- (b) Smazat enum úplně, `NodeResolution` value class má jen `(eligibleByConditions, objectiveCompleted, alreadyCompleted, alreadyClaimed)` booleany; engine derivuje completion/availability transitions inline.

**Kdy to řešit:** Phase 16 (engine signature refactor) — natural place where resolver internals get a rework anyway.

**Není blocking pro:** Stage C / D / E phases. Phase 13 DoD ('node_state.dart deleted') splněna; enum jako resolver-internal symbol není 'domain model' anymore.

---

### 2.21 `ChapterLocked.gate` field (Phase 13 spec deferral)

**Phase 13 status:** Proposal §4.4 specifikuje `ChapterLocked(gate: UnlockCondition)` field. Phase 13 ShipLA `ChapterLocked` **parameterless** (žádný field).

**Důvod:** Stejný cross-feature import problem jako Phase 6 `QuestLocked.remaining` a Phase 8 `AchievementLocked.remaining`. `UnlockCondition` sealed hierarchy žije v `lib/features/progression_engine/domain/models/unlock_condition.dart`; `lib/domain/progression/player/` ho nemůže importovat (architecture rule §3).

**Cílový stav:** Až `UnlockCondition` migruje do `lib/domain/progression/catalog/` (separate phase), pridat `gate` field na `ChapterLocked`. Mirror pattern bude aplikován také na `QuestLocked.remaining` a `AchievementLocked.remaining`.

**Co dnes funguje bez gate field:** UI hint pro Locked chapter je v EngineQuestProgress view model (`titleKey`, `descriptionKey`, `lockedHintKey`) — chrome cesta. Lifecycle drží jen 'I'm locked', což stačí na branching.

**Kdy to řešit:** Pre-condition: `UnlockCondition` migrace do `lib/domain/progression/catalog/`. Velikost: 11 subtypů sealed + ~30 call sites where UnlockCondition is constructed. Standalone sub-phase candidate.

**Není blocking pro:** Stage D / E. Lifecycle discrimination funguje bez gate detail.

---

### 2.22 Phase 9-13 manuální smoke checks (deferred from každé fáze)

**Stage C status:** Phase 9 (Cosmetic sealed) / Phase 10 (PlayerCosmeticLifecycle) / Phase 11 (companion merge) / Phase 12 (Loadout + EmblemBoard) / Phase 13 (ChapterLifecycle) shipped pure refactors — code path topology beze změny. Unit + service-level tests pokrývají derivation matrix (576 tests pass at Phase 13 close). **Žádný end-to-end smoke check UI flows nebyl proveden v rámci žádné z fází.**

**Co konkrétně nebylo ověřeno:**

- **Phase 9 (Cosmetic sealed):** Cosmetics screen tabs render (Rámečky / Pozadí / Reliky / Emblems / Companions / Titulky / Map effects); devtools cosmetic matrix.
- **Phase 10 (PlayerCosmeticLifecycle):** Companion claim journey end-to-end (Hidden → progress → claimable → claimed UI transitions); cosmetic_details_sheet partial-progress chip + checklist render.
- **Phase 11 (companion merge):** Companion details sheet alternate bodies (Hidden / Teased / Claimable / Owned); devtools companion matrix transitions; identity-hide rule before claim.
- **Phase 12 (Loadout + EmblemBoard):** Profile header 11-slot grid render; drag-to-pin / emblem-slot-sheet write flow; cross-user emblem isolation (sign out + sign in jiný uid); legacy `pinned_emblems_<uid>` wire format roll-forward na existing devices.
- **Phase 13 (ChapterLifecycle):** Žádná widget consumption Phase 13 lifecycle, takže smoke check není actionable do Phase 13.b. Provider getter return value nicméně neexerciseed v UI tree.

**Proč deferred:** User explicit pattern napříč Phase 9-13: ship refactor + tests, smoke check deferred na manual dev pass. Phase 11 high-risk byl mitigated by sealed switch (compile-time exhaustive coverage), takže behavior parity je structurally guaranteed; smoke check je validation, ne discovery.

**Možná řešení:**
- (a) Dev smoke pass napříč Phase 9-13 surface area najednou (~1-2 hod). Doporučeno před Phase 14 start.
- (b) Per-area smoke when first user-visible regression report lands. Reactive.
- (c) Phase 13.b widget migration zahrne smoke jako součást migration validation.

**Není blocking pro:** Phase 14+ technicky. Doporučení: smoke pass před Stage D (Phase 14-19) protože Phase 14 GoalBoard / Phase 15 HealthSnapshot začnou shipping new domain types; pokud Phase 9-13 mají hidden regrese, smoke je odhalí teď než se kupí další vrstvy.

---

### 2.23 PlayerQuest full `Quest quest` reference (deferred from Phase 7)

**Phase 7 status:** Proposal §2.4 spec specifies `PlayerQuest { Quest quest; PlayerQuestLifecycle lifecycle; DateTime evaluatedAt; }`. Phase 7 (`lib/domain/progression/player/player_quest.dart`) shipped with a narrower **`final QuestId id`** field instead of `Quest quest`.

**Důvod:** Same root cause as [§2.21 `ChapterLocked.gate`](#221-chapterlockedgate-field-phase-13-spec-deferral) and the parallel for `QuestLocked.remaining` / `AchievementLocked.remaining` — `Quest` catalog row sealed hierarchy lives in `lib/features/progression_engine/domain/models/progression_node_definition.dart`; `lib/domain/progression/player/` cannot import features per architecture rule §3 + the `test/domain_purity_test.dart` guard. `QuestId` reference is proposal-aligned minimum until Quest itself moves.

**Cílový stav:** When `Quest` migrates to `lib/domain/progression/catalog/` (part of the broader catalog rename, separate phase from any individual Stage A-E entry), replace the `id` field with `final Quest quest` per proposal. Consumers stop doing the `ProgressionEntryCatalog.definitionForId(...)` lookup dance.

**Co dnes funguje bez plné Quest reference:** Application + presentation consumers resolve the full row via `ProgressionEntryCatalog.definitionForId(playerQuest.id.value) as Quest`. Phase 7 ADR `player-quest-catalog-projection` alternative (A) documents this explicitly. PlayerQuest API stays stable across the future migration — adding a `final Quest quest` field next to the existing `final QuestId id` is non-breaking.

**Kdy to řešit:** Pre-condition: Quest sealed hierarchy migrate do `lib/domain/progression/catalog/`. Same migration scope as [§2.21](#221-chapterlockedgate-field-phase-13-spec-deferral) and Phase 6 `QuestLocked.remaining` — bundle all three at once. Velikost: ~10 sealed Quest subtypes + ~30 catalog content files referencing them.

**Není blocking pro:** Stage C / D / E phases. PlayerQuestCatalog accessors (`byId`, `available`, `pendingClaim`, `claimed`, `locked`, `among`, `where`) work without the field.

---

### 2.24 PlayerQuestLifecycle timestamp enrichment (`completedAt` / `claimedAt`, deferred from Phase 6 + Phase 7)

**Phase 6 + 7 status:** Phase 6 defined `QuestCompletedPendingClaim({ required int previewXp, DateTime? completedAt })` and `QuestClaimed({ required int finalXp, DateTime? claimedAt })`. The nullable timestamps are explicitly placeholders — proposal §4.1 spec carries them on the subtype, Phase 6 left them as `null` because the bridge getter on `EngineQuestProgress` doesn't have ledger access. Phase 7 `PlayerQuestCatalogService.build` doesn't populate them either — service still routes through the same Phase 6 bridge, only the projection shape changed.

**Cílový stav:** `PlayerQuestCatalogService` reads the Journal's `NodeCompletionEvent.timestamp` and `NodeClaimEvent.timestamp` for each PlayerQuest entry. UI could then render relative-time hints ("claimed 2h ago", "completed today at 14:32") that today's view-models lack — `EngineCompletedQuestCard` shows `entry.lastEventAt` from a different code path (the completed-section rollup), which could route through the same source.

**Co dnes funguje bez timestamps:** Lifecycle discrimination (Locked / Available / PendingClaim / Claimed) drives every Phase 6+ widget switch. Timestamps were never read — `null` is a no-op for UI today. Phase 6 widget tests + Phase 7 service tests pin the lifecycle payload shape with `evaluatedAt` on the wrapping `PlayerQuest`; per-event timestamps are not on the test surface yet.

**Možná řešení:**

- (a) `PlayerQuestCatalogService` ingests `LedgerSnapshot` alongside `Iterable<EngineQuestProgress>` and indexes `nodeCompletions` + `nodeClaims` by nodeId for O(1) lookup during build. ~30 LoC service change + 1 plumbing tweak in the provider getter.
- (b) Lazy: `QuestClaimed.claimedAt` becomes a getter computed from a `Journal` reference held on `PlayerQuest`. Cleaner per-quest API, but ties PlayerQuest to a live Journal which contradicts the immutable VO shape.

**Proč deferred:** Phase 6 scope discipline (sealed type + widget pattern-match, no Journal read). Phase 7 scope discipline (read projection shape, no payload enrichment). Both phases kept the surface small; timestamps are additive and can land independently when a UI surface actually consumes them.

**Kdy to řešit:** When a UI feature requests relative-time hints on quest cards, or when `EngineCompletedQuestCard`'s standalone `lastEventAt` source consolidates through the catalog. Velikost: ~30-50 LoC service + test update.

**Není blocking pro:** Stage C / D / E phases. The `null` timestamps are a stable contract; consumers reading them today must already null-check.

---

### 2.25 Phase 21 lint baseline cleanup queue (deferred from Phase 21)

**Phase 21 status:** Lint matchers shipped + ratchet-tested 2026-05-19 (commit forthcoming). Each rule has a numeric baseline captured in [test/lint/production_scan_test.dart](../../test/lint/production_scan_test.dart). The ratchet prevents new violations; pre-existing ones remain.

**Baseline snapshot (2026-05-19):**

| Rule slug | Scope | Baseline | Hot spots |
|---|---|---|---|
| `domain-purity` | `lib/features/*/domain/` | 35 | catalog content files importing `flutter/material show Color/Icons`, `health_connect/domain/activity_record.dart` importing `package:health/`, `auth/domain/identity.dart` importing firebase_auth + google_sign_in. |
| `untyped-id` | `lib/domain/` | 7 | almost all in `lib/domain/journal/journal_event.dart` — these are storage-boundary fields holding raw persisted strings. Probably stay; revisit if/when typed-id wrappers cross the persistence layer cleanly. |
| `untyped-id` | `lib/features/*/domain/` | 72 | progression_engine + cosmetics + social aggregates. Each is a 2-5 line typed-wrapper swap, but mass-touching aggregates is risky outside a dedicated phase. |
| `l10n-literal` | `lib/features/*/presentation/` | 29 | scattered hard-coded Czech / English strings in dialogs, error banners, devtools. Each is a 2-line ARB add + Text() rewrite. |
| `widget-no-logic` | `lib/features/*/presentation/` | 60 | `.where(` / `.firstWhere(` for theme/style lookup + collection filtering. Some are legitimate (`// lint-ignore: widget-no-logic`); most need extraction into a provider getter. |

**Co dnes funguje bez cleanup:** Existing code compiles + behaves correctly. The ratchet is preventive — new code can't add to the debt. Existing screens look the same.

**Možná řešení:**

- (a) **Opportunistic, file-by-file.** Touch a file for unrelated work → fix the violations in it → lower baselines by the delta. No dedicated PR needed; cleanup compounds.
- (b) **Per-rule sweep PRs.** One PR per rule slug clearing the whole baseline. Smallest risk per PR is `l10n-literal` (29 mechanical Text() swaps + ARB additions). `untyped-id` sweep is highest risk (touches aggregate constructors → every callsite).
- (c) **Rule retirement.** Some violations may turn out to be intentional design (`untyped-id` in journal_event.dart storage-boundary fields). For those, mark the line with `// lint-ignore: <rule>` + a one-line reason, and lower the baseline accordingly. Net effect: lint ratchet stays accurate, intent stays documented.

**Proč deferred:** Phase 21 ships the discipline (matcher + ratchet + checklist + docs). Mass cleanup of 169 pre-existing violations is its own multi-PR effort, outside the "lint rules / review checklist" goal of Phase 21.

**Kdy to řešit:** Opportunistically. Each ratchet failure ("shrank") in a future PR is a free baseline lower — encourage that pattern.

**Není blocking pro:** Phase 22 (V1 cleanup), or any future feature work. The ratchet is silent until violations grow.

**Update 2026-05-19 (post-Phase-22):** baselines lowered as a side-effect of the V1 delete:

| Rule slug | Scope | Old baseline | New baseline | Delta |
|---|---|---|---|---|
| `domain-purity` | `lib/features/*/domain/` | 35 | 33 | -2 |
| `untyped-id` | `lib/features/*/domain/` | 72 | 58 | -14 |
| `l10n-literal` | `lib/features/*/presentation/` | 29 | 19 | -10 |
| `widget-no-logic` | `lib/features/*/presentation/` | 60 | 46 | -14 |

V1 deletion alone wiped ~30% of the typed-id + l10n debt + ~23% of the widget-logic debt. Remaining hot spots are now squarely in V2 progression-engine + cosmetics + social.

---

### 2.26 V2 background quest + achievement notifications (deferred from Phase 22)

**Phase 22 status:** V1 progression module deleted 2026-05-19. As part of that cleanup, `lib/core/services/background_sync_service.dart` lost its `engine.sync(source)` + quest/achievement notification block — the V1 engine had been writing to a divergent ledger ever since V2 plan Phase 6 made V2 the canonical foreground engine, so those background notifications had been firing off stale state (or not firing at all for V2-completed quests).

**Cílový stav:** WorkManager background sync detects newly-granted quest rewards + newly-unlocked achievements via the V2 engine and pushes push-style notifications (`NotificationService.showQuestCompleted` / `showAchievementUnlocked`).

**Co dnes funguje bez tohoto featuru:** HC + KT data refresh + daily goal reminder still fire from background sync. Quest/achievement state updates the moment the user opens the app (V2 engine evaluates on bind). Background notifications were always best-effort — WorkManager only runs every ~15 min on a battery-friendly schedule, so the gap is small in practice.

**Možná řešení:**

- (a) **Direct V2 engine bootstrap in the WorkManager isolate.** Construct `ProgressionEngineDatabase` + `ProgressionEngineRepository` + `ProgressionEngine`, build `EngineEvaluationContext` from in-process HC + KT + Goals state, call `engine.evaluate()`, diff `result.grantedRewards` against the pre-sync snapshot by event key, push notifications. Sizing: ~150-200 LoC. Risk: need to also derive `LedgerCounters` + `Player.fromJournal` in the isolate (`ProgressionEngineProvider` does both for free in the foreground, but the headless isolate can't reuse a ChangeNotifier graph).
- (b) **Lift only the diff out to a separate service.** Run the existing foreground `ProgressionEngineProvider` cold (without listeners) in the isolate, treating it as a one-shot evaluator. Less code duplication but heavier per-tick cost.
- (c) **Skip the feature.** Push notifications for in-flight quests are a delight, not a contract. If product feedback doesn't ask for them, leave the background sync at HC/KT/goal-reminder scope.

**Proč deferred:** Phase 22 scope was "delete V1", not "build a V2 background notification pipeline." The migration plan's original Phase 22 spec ("Modify `background_sync_service.dart` — migrate na V2 ProgressionEngineProvider") underestimated the bootstrap cost in the WorkManager headless isolate — proper V2 wiring needs more design than the cleanup deserved. Decoupling unblocks the V1 delete; the notification feature itself is its own scoped story.

**Kdy to řešit:** When product feedback asks for it, or when a related feature (e.g. scheduled daily reminders driven by completion state) needs the same pipeline. Velikost: ~150-200 LoC + a headless-isolate integration test.

**Není blocking pro:** any current refactor or feature work. The push-notification surface (`NotificationService.showQuestCompleted` / `showAchievementUnlocked`) is untouched and ready to receive calls from a future V2 publisher.

---

## 3. Audit findings že NEJSOU folded ani deferred

Tyto byly raised v audit reportu, ale nepřevedeny na action item — buď jsou false positive nebo z natury povahy doménového refactoru řeší.

| Finding | Status | Důvod |
|---|---|---|
| WorkManager 15-min interval re-inicializuje Firebase + 3 DBs + state machines | informational | Performance acceptable. Pokud později vadí, single PR optimization. |
| No reentrancy locking v BackgroundSync | low risk | WorkManager serializes na Androidu. Nehrozí concurrent fire. |
| 3 quest + 3 achievement notification cap per run | by design | Spam guard. Acceptable. |
| Cosmetic entitlements expiry checked na load not eval time | edge case | Cosmetic expiry je rare; pokud někdy enable, drobný fix. |
| Hybrid_progression_repository `_pushSafely` swallows | by design | Local-first semantic. Phase 18 Result/Error explicit-uje, ale fail-and-continue zůstává. |

---

## 4. Cross-references

- Smell items v code (TODO markers): [sheet_export_field.dart](../../lib/features/sheets_export/domain/sheet_export_field.dart#L1), [bushido_export_config.dart](../../lib/features/coach_log_export/domain/bushido_export_config.dart#L1), [activity_record.dart](../../lib/features/health_connect/domain/activity_record.dart#L10).
- Memory notes: [project_config_system.md](../../memory/project_config_system.md), [project_logging.md](../../memory/project_logging.md).
- Architecture: [architecture.md](../architecture.md), [proposal.md §1.1](proposal.md), [proposal.md §7](proposal.md).

---

## 5. Workflow

- **Když přidám něco do follow-up listu:** kategorizovat (folded / deferred / not-action).
- **Když promote položku do plan:** přesunout do `migration_plan.md` jako nová fáze nebo sub-fáze; v této tabulce updatovat status na "→ folded into Phase X".
- **Když resolvnu deferred item samostatně:** zapsat datum vyřešení + odkaz na PR; archivovat položku do "completed" pod fold-cí na konec souboru.
- **Když item přestane být relevant:** označit jako "obsolete" + datum + důvod. Nemazat — historie je informativní.
