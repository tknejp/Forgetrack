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
