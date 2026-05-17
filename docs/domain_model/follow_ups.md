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
