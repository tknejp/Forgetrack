# Forgetrack — Domain Model Migration Plan

**Status:** Návrh fázovaného plánu. Implementuje [proposal.md](proposal.md) postupnými PR-sized kroky.
**Predecessor:** [proposal.md](proposal.md) (odsouhlasený doménový model).
**Created:** 2026-05-17.

> Tento dokument je **plán implementace**. Konkrétní soubory / edity každé fáze zachycuje vlastní sekce. Žádná fáze se nepouští, dokud nejsou splněny její pre-conditions a DoD předchozí fáze.

---

## 0. Pracovní principy plánu

Plán dodržuje 5 pravidel, která jsou silnější než cokoliv v jednotlivých fázích:

1. **Každá fáze je jeden PR.** Pokud fáze nelze landnout jedním PR (>~300 změněných řádků), rozdělí se na sub-fáze X.a / X.b / X.c. Žádný PR netluče přes víc než 3 dny otevřené review.
2. **Každá fáze končí green main.** `flutter analyze` clean, všechny relevantní testy pass, manuální smoke check klíčových obrazovek prošel. Žádný PR nezpůsobí regresi.
3. **Strangler fig pattern.** Nový model + starý model **koexistují** během fáze. Old code path zůstává funkční, nová cesta se postupně mění v primární, starý wrapper se smaže až po migraci posledního konzumenta. Žádný "big bang merge".
4. **UI je single-reader, žádný computer.** Každá fáze, která zavádí novou doménovou entitu, **současně** updatuje UI tak, aby z ní jen četla. Žádné `widget.build()` neobsahuje logiku nad doménou — vždy `context.watch<XxxProvider>().preComputed`. To je dle proposal §7 anti-pattern #1, #8.
5. **Persistence schemata se nemění.** Isar collections, Firestore subkolekce, SharedPreferences keys — vše zůstává. Aggregaty jsou **read layer** nad event-sourced write side. Dle proposal §11.

---

## 1. Mapa fází (overview)

| Stage | Fáze | Název | Riziko | Velikost (LoC) |
|---|---|---|---|---|
| **A: Foundation** | 0 | Skeleton + lint guardrails | nízké | ~50 |
| | 1 | Identity rename (AuthUser → Identity) | nízké | ~150 |
| | 2 | Journal infrastructure (LedgerEvent → JournalEvent) + PeriodKey UTC | nízké | ~250 |
| | 3 | Catalog rename pass + typed identifier rollout (extension types) | střední | ~700 (mechanický) |
| **B: Player + Lifecycles** | 4 | Player aggregate scaffolding | střední | ~250 |
| | 5 | Player computed level/XP (Player as source-of-truth) | vysoké | ~300 |
| | 6 | PlayerQuestLifecycle (sealed) + NodeState removal | vysoké | ~350 |
| | 7 | PlayerQuestCatalog read projection | střední | ~300 |
| | 8 | PlayerAchievementShelf | nízké | ~250 |
| **C: Cosmetics + Misc aggregates** | 9 | Cosmetic sealed catalog (7 subtypes) | střední | ~400 |
| | 10 | PlayerCosmeticLifecycle + Inventory | vysoké | ~400 |
| | 11 | Companion lifecycle merge (delete CompanionState + CompanionsRegistry) | střední | ~250 |
| | 12 | Loadout + EmblemBoard relocation | nízké | ~200 |
| | 13 | ChapterLifecycle + Chapter catalog wrapper | střední | ~300 |
| **D: Engine + Social + UI** | 14 | GoalBoard extraction | nízké | ~200 |
| | 15 | HealthSnapshot + NutritionSnapshot domain types | střední | ~250 |
| | 16 | Engine signature refactor (EngineEvaluationInput → arg list) | vysoké | ~350 |
| | 17 | SocialPresence aggregate | střední | ~300 |
| | 18 | **Result/Error type hierarchy** (typed errors + sealed AppError) | střední | ~400 |
| | 19 | UI sweep — widgets read-only audit | střední | ~variable |
| **E: Hardening** | 20 | Cache rebuild paths + JournalProjection interface | nízké | ~150 |
| | 21 | Lint rules (domain purity + typed-id + l10n strings) / review checklist | nízké | ~200 |
| **deferred** | 22 | Legacy V1 progression cleanup (`lib/features/progression/`) | mimo scope tohoto plánu | — |

**Celkový odhad:** ~5100 LoC změn napříč ~55 PR (po sub-fázích). Realistický time-frame: **3-6 měsíců** podle volné kapacity.

---

## 2. Per-phase detail

### Stage A — Foundation

---

### Phase 0 — Skeleton + lint guardrails

**Goal:** Vytvořit `lib/domain/` skeleton se 3 podsložkami; přidat lint pravidlo, které zabrání domain layer pollute.

**Pre-conditions:** žádné. První fáze.

**Files touched:**
- New: `lib/domain/player/.gitkeep`, `lib/domain/journal/.gitkeep`, `lib/domain/progression/.gitkeep`.
- Modify: `analysis_options.yaml` — přidat `custom_lint` nebo equivalent rule `domain_purity` (zakazuje `import package:flutter/`, `package:provider/`, `package:firebase_*`, `package:isar/` v `lib/domain/`).

**Implementation steps:**
1. Vytvořit prázdné podsložky s `.gitkeep`.
2. Pokud `analysis_options.yaml` neumí custom rule out-of-the-box, použít `import_lint` nebo dart-side test, který sken `lib/domain/**` přes `dart pub global run import_lint`. Alternativa: write a minimal `test/domain_purity_test.dart`, který grepuje import statements v `lib/domain/` a fail-fastne při nálezu zakázaného importu.

**Test plan:**
- Spustit `flutter analyze` — clean.
- Spustit `dart test test/domain_purity_test.dart` — passes na prázdné doméně. Záměrně přidat `import 'package:flutter/material.dart';` do dummy souboru v `lib/domain/`, ověřit, že test fail-fastne. Smazat dummy import.

**DoD:**
- [ ] `lib/domain/` existuje s 3 podsložkami.
- [ ] Lint pravidlo aktivní a otestované.
- [ ] `flutter analyze` clean.
- [ ] PR popsán jako "Foundation: lib/domain/ skeleton + purity guardrail".

**Rizika:** Žádná funkční změna; nejhorší co se může stát je, že lint pravidlo nevyhne false positive (např. typedef v doméně, který importuje sealed Dart class). Mitigation: dokumentovat whitelist (např. `package:meta/`, `package:collection/`).

**Rollback:** revert PR. Žádný produkční dopad.

---

### Phase 1 — Identity rename (AuthUser → Identity)

**Goal:** Přejmenovat `AuthUser` na `Identity`, přesunout z `application/auth_user.dart` do `lib/features/auth/domain/identity.dart`. Bez funkční změny.

**Pre-conditions:** Phase 0 done.

**Files touched:**
- Move + rename: `lib/features/auth/application/auth_user.dart` → `lib/features/auth/domain/identity.dart`.
- Rename `class AuthUser` → `class Identity`. Static factory `AuthUser.fromGoogle` → `Identity.fromGoogle`, atd.
- Update import a usage v ~10 souborech (grep ukáže — `AuthProvider`, `MainShell`, `SocialProvider`, `OnboardingProvider`, `DevtoolsProvider`, testy).

**Implementation steps:**
1. `git mv` + rename class.
2. `flutter analyze` najde všechny call sajty; oprávit jeden po druhém.
3. Auth tests v `test/features/auth/` upravit na novou class name.
4. Smoke test: spustit appku, sign-in flow, profile header zobrazí display name + photo.

**Test plan:**
- `flutter analyze` clean.
- `flutter test test/features/auth/` passes.
- Manuální smoke test: sign-in → main shell zobrazí avatar a jméno.

**DoD:**
- [ ] `AuthUser` symbol mrtvý (grep `AuthUser` napříč repo vrátí 0 matches).
- [ ] `Identity` v `lib/features/auth/domain/`.
- [ ] Auth tests pass.
- [ ] Smoke check OK.

**Rizika:** Žádná logická změna, jen rename. Risk je v missed call site, který analyzer chytne.

**Rollback:** `git revert`.

---

### Phase 2 — Journal infrastructure (LedgerEvent → JournalEvent)

**Goal:** Přejmenovat `LedgerEvent` na `JournalEvent`, přesunout sealed hierarchii do `lib/domain/journal/`. Zavést `Journal` interface s `Iterable<JournalEvent> events`, query metodama. Bez funkční změny.

**Pre-conditions:** Phase 0 done.

**Files touched:**
- Move + rename: `lib/features/progression_engine/domain/models/ledger_event.dart` → `lib/domain/journal/journal_event.dart`. Rename sealed class `LedgerEvent` → `JournalEvent`. 6 subtypů zachovává jméno (`ObjectiveCompletionEvent` → `ObjectiveCompletionEvent`, ne `ObjectiveCompletion` — kvůli `Event` discriminator suffixu).
- New: `lib/domain/journal/journal.dart` — abstract class `Journal` s metodama:
  ```
  Iterable<JournalEvent> get events;
  Iterable<JournalEvent> eventsForNode(String nodeId);
  Iterable<JournalEvent> eventsInRange(DateTime from, DateTime to);
  Future<void> append(JournalEvent event);  // delegated to repository
  ```
- New: `lib/domain/journal/event_key.dart` — `EventKey` VO (typed alias kolem String pro deterministic dedupe; jen typedef + helpers).
- New: `lib/domain/journal/period_key.dart` — `PeriodKey` VO. **UTC-enforced**: factory `PeriodKey.day(DateTime)` přijme libovolný `DateTime` a normalizuje na `yyyy-MM-dd` v UTC; factory `PeriodKey.isoWeek(DateTime)` stejně. Konstruktor s raw String je private — externí kód musí jít přes factories. Adresuje timezone-collision risk identifikovaný v auditu (long-offline + cross-TZ → duplicate periodKey claims).
- Modify: `progression_engine/data/` repository implementuje `Journal` interface a forwarduje na existující Isar reads.
- Update call sajty v `progression_engine_provider`, `hybrid_progression_engine_repository`, `daily_section_resolver`, `firestore_*_gateway`, atd. (~15 souborů).

**Implementation steps:**
1. Vytvořit `Journal` interface + 4 VO.
2. ~~Implementovat `IsarJournalAdapter` v `lib/features/progression_engine/data/` — wraps existující collections.~~ **Deferred** — see `follow_ups.md §2.13`. Stage A landed Journal as a standalone interface without concrete implementation; consumer migration happens incrementally per strangler-fig, so the adapter can be written when the first consumer needs it.
3. Rename `LedgerEvent` → `JournalEvent` + move.
4. ~~Existující `HybridProgressionEngineRepository` implementuje `Journal` (extends abstract class).~~ **Deferred** alongside IsarJournalAdapter — same reason.
5. Postupně migrate consumery — místo `repository.queryRewardGrants(...)` zavolají `journal.eventsForNode(id).whereType<RewardGrantEvent>()`. **Deferred** — first consumer wave happens in Stage B+.

**Test plan:**
- `flutter analyze` clean.
- `flutter test test/features/progression/` + `test/features/progression_engine/` passes — existující testy pokrývají ledger reads.
- ~~New test `test/domain/journal/journal_adapter_test.dart`~~ — Deferred with the adapter itself (see follow_ups.md §2.13).
- New test `test/domain/journal/period_key_test.dart` — `PeriodKey.day(localDateTime)` z různých timezone vrátí stejnou hodnotu pro stejný UTC den. Cross-TZ collision test.

**DoD (Stage-A-landing scope, partial):**

- [x] `LedgerEvent` symbol mrtvý (renamed `JournalEvent`).
- [x] `Journal` interface žije v `lib/domain/journal/`. ~~Implementace v progression_engine/data/.~~ **Deferred — see follow_ups.md §2.13.** Interface scaffolded as standalone abstraction; concrete adapter ships when first consumer migrates.
- [ ] ~~Všichni konzumenti čtou přes `Journal` interface, ne přes raw Isar.~~ **Deferred — incremental consumer migration starts Stage B+.**
- [x] Tests pass + manuální evaluation cycle smoke check.

**Rizika:** Některé call sajty mají ledger-specific query API (`queryRewardGrants(domain: X)`), které není v generic `Journal` interface. Mitigation: rozšířit interface o tyto query metody nebo mapovat via `events.whereType<RewardGrantEvent>().where((e) => …)`. Pokud query je hot-path (např. evaluator volá per-tick), zachovat indexované metody na interface.

**Rollback:** `git revert` + smazat `lib/domain/journal/`.

---

### Phase 3 — Catalog rename pass + typed identifier rollout

**Goal:** Dva paralelní mechanické refactor passy v jednom Stage:

(a) Rename `ProgressionNode` → `ProgressionEntry`, drop `Node` suffix u všech subtypů, `Objective` → `Objective`, `Cosmetic` → `Cosmetic`. `RewardDefinition` zachován (proposal §2.3 disambiguation).

(b) **Typed identifier rollout** přes `extension type` (Dart 3, zero runtime cost). `String` ids dostávají typové wrappers: `QuestId`, `AchievementId`, `ChapterId`, `CosmeticId`, `ObjectiveId`, `MilestoneId`. Zero-overhead, ale kompilátor refusne `Inventory.byId(quest.id)` typo.

**Pre-conditions:** Phase 2 done (Journal exists tak, abychom mohli referencovat).

**Sub-fáze (rozdělit na sub-PR pokud roste přes ~300 LoC):**

- **3.a:** Mechanický class rename (Node suffix drop + Definition drop). ✓ landed.
- **3.b.1:** Typed identifier definitions (lib/domain/progression/catalog/ids.dart) + Journal interface adoption. ✓ landed.
- **3.b.2:** Field signature migration (ProgressionEntry.id, Objective.id, Cosmetic.id) + catalog literal wraps. ✓ landed.
- **3.c:** UI + provider call site sweep. **Effectively no-op** — the Phase 3.b.2 design refinement (`implements String` rather than `implements Object`) made typed ids auto-coerce into String parameters, so no cascade sweep was needed for compilation. Stylistic refinements (e.g. wrapping `quest.id == 'literal'` equality checks with `const ProgressionEntryId('literal')`) are opt-in and **deferred — see follow_ups.md §2.14.** Inner-catalog reference fields (Quest.objectiveId / chainId / chapterId / comboPoolId / prerequisiteNodeIds / nextNodeIds) stay String — **see follow_ups.md §2.15.**

**Files touched:**

(a) Rename:

- `lib/features/progression_engine/domain/models/progression_node_definition.dart` — rename všechny classes.
- `lib/features/progression_engine/domain/catalog/content/*.dart` (~12 files) — update všechny subtype call sites.
- `lib/features/progression_engine/domain/catalog/progression_node_catalog.dart` → `progression_entry_catalog.dart`. Rename `ProgressionEntryCatalog` → `ProgressionEntryCatalog`.
- `lib/features/progression_engine/domain/models/objective_definition.dart` — class rename.
- `lib/features/cosmetics/domain/cosmetic_models.dart` — `Cosmetic` → `Cosmetic` (single class for now; sealing přijde v Phase 9).

(b) Typed ids:

- New: `lib/domain/progression/catalog/ids.dart` — definice `extension type QuestId(String value) implements Object`, atd.
- Modify: catalog row constructors přijímají `QuestId` / `AchievementId` (ne `String`). Catalog factories používají typed.
- Modify: `Journal.eventsForNode(QuestId | AchievementId | ...)` — sjednocený typ `ProgressionEntryId` jako sealed (?) nebo overloaded API.
- Modify: ~50+ call sites napříč evaluators, presenters, tests.

**Implementation steps:**

1. (3.a) Mechanická rename — IDE-driven refactor "Rename Symbol".
2. (3.a) Update všechny string-id konvence v komentářích (ne v kódu — id stringy zachovat na úrovni serializace).
3. (3.b) Definovat extension types. Decided: použít `extension type Xxx(String value)` (Dart 3.3+). **Nepoužít** `typedef` — ten neposkytuje typovou izolaci.
4. (3.b) Migrovat catalog row signatures — `class Quest { final QuestId id; ...}`.
5. (3.c) Provider + UI call sajt — kde se id z UI předává do API, zabalit do `QuestId(rawString)`.
6. **Persistence boundary:** Isar a Firestore stále serializují/deserializují jako raw `String`. Mappers konvertují `QuestId.value` ↔ `String` na hranici. Tj. typed ids zůstávají v doméně + application; data layer zná raw String.
7. Run `flutter analyze` — fixnout pozůstatky.
8. `lib/domain/progression/catalog/` zatím **prázdná** pro classes — fyzický move přijde až v Phase 4+. Ale `ids.dart` už tam žije (typed ids jsou pure domain).

**Implementation note:** Tato fáze **nepřesouvá** classes do `lib/domain/`. Jen renamuje + zavádí typed ids uvnitř `lib/features/progression_engine/domain/`. Cíl: oddělit renaming + typed-id risk od move-and-restructure risk.

**Test plan:**

- `flutter analyze` clean. Typed ids zachytí typo, který by se předtím zkompiloval.
- All test suites pass (`flutter test`).
- New test `test/domain/progression/ids_test.dart` — typed ids equality, fromJson/toJson, can't construct from another typed id (compiler check via expected-fail test fixture).
- Manuální smoke test: spustit appku, otevřít každou progression-aware obrazovku (Home progression card, Quests V2, Achievements, Journey).

**DoD:**

- [ ] Žádný symbol s `Node` suffixem v `progression_engine/domain/` (kromě `_node_` v Isar `.g.dart` files, které nepatří doméně).
- [ ] `Cosmetic` (ne `Cosmetic`) napříč repo.
- [ ] `Objective` (ne `Objective`) napříč repo.
- [ ] `QuestId`, `AchievementId`, `ChapterId`, `CosmeticId`, `ObjectiveId` definovány a používány v catalog + repository signatures.
- [ ] Persistence boundary explicitně dokumentován — Isar/Firestore mappers konvertují na/z `String`.
- [ ] Build green; all tests pass.

**Rizika:**

- Generic rename collisions. Např. `CompanionAvailability` → `CompanionAvailability` (catalog node), `Cosmetic` typu `companion` → bude `Companion` (catalog cosmetic) až v Phase 9.
- Extension type adoption má learning curve — v týmovém kontextu by potřebovala doc. Solo developer (uživatel) tomu rozumí rychle.
- Mass-id wrap může explodovat PR size — proto sub-fáze 3.a/3.b/3.c.

**Rollback:** `git revert`. Stable point.

---

### Stage B — Player + Lifecycles

---

### Phase 4 — Player aggregate scaffolding

**Goal:** Definovat `Player` class v `lib/domain/player/player.dart`. Pro tuto fázi je Player **read-through wrapper** nad existujícím `ProgressionEngineProvider.profile`. Žádná změna source-of-truth — jen nový API surface.

**Pre-conditions:** Phase 3 done.

**Files touched:**
- New: `lib/domain/player/player.dart` — class `Player` s fields `uid`, `level`, `totalXp`, `joinedAt`, `rpgModeEnabled`, `displayName`, `photoUrl`. Immutable, `const` ctor.
- New: `lib/domain/player/player_repository.dart` — abstract interface `Future<Player> load(String uid)`, `Stream<Player> watch(String uid)`.
- New: `lib/domain/player/level_curve.dart` — extrahovat `level_policy.dart` policy do pure-Dart class. Beze změny logiky.
- New: `lib/app/player_provider.dart` (or `lib/features/auth/application/`) — `ChangeNotifierProxyProvider2<AuthProvider, ProgressionEngineProvider, PlayerProvider>` — fabricates `Player` ze stávajících providerů.
- Modify: `main.dart` provider tree — append PlayerProvider after ProgressionEngineProvider.

**Implementation steps:**
1. Create `Player` value class.
2. Create `LevelCurve` (move from `progression_engine/domain/policy/level_policy.dart` to `lib/domain/player/level_curve.dart`). Existing file ponechat jako re-export pro backwards compat během fáze.
3. Implement `PlayerProvider` jako proxy — `update` rebuilds Player ze 2 upstream providerů.
4. Wire up v `main.dart`.

**Test plan:**
- `test/domain/player/player_test.dart` — unit test `Player` equality, copyWith, levelFor edge cases.
- `test/integration/player_provider_test.dart` — provider rebuilds Player when ProgressionEngineProvider.profile changes.
- `flutter analyze` clean.
- Manuální smoke: hero card zobrazuje stejnou úroveň přes nový + starý API.

**DoD:**
- [ ] `Player` v `lib/domain/player/`, importovatelné odkudkoli.
- [ ] `PlayerProvider` exposed v main.dart.
- [ ] **Žádný consumer ještě nečte přes Player** — to je úkol Phase 5+. Tady jen scaffolding.
- [ ] Tests pass.

**Rizika:** Nový Player může dříve drift od `ProgressionEngineProvider.profile`, pokud update timing nesedí. Mitigation: PlayerProvider má `update` callback, který fires kdykoli upstream notifies. Verify via stress test (rychlé sekvence claim events).

**Rollback:** `git revert`.

---

### Phase 5 — Player computed level/XP (Player as source-of-truth)

**Goal:** `Player.level` + `Player.totalXp` přestávají být input do enginu. Player je computed property z `Journal` (sumace XP events) + `LevelCurve`. Engine si Player čte, ne naopak.

**Pre-conditions:** Phase 4 done.

**Files touched:**
- Modify: `lib/domain/player/player.dart` — Player drží `Journal` reference (or Player má static factory `Player.fromJournal(uid, journal, levelCurve)`).
- Modify: `lib/features/progression_engine/domain/models/engine_evaluation_input.dart` — fields `level: int`, `totalXp: int` zůstávají jako redundant inputs pro tuto fázi (deprecated comment); nová logika čte z Player.
- Modify: `lib/features/progression_engine/application/progression_engine_provider.dart` — `evaluate()` čte level/XP z Player provideru, ne z profile.
- Modify: `lib/features/progression_engine/application/progression_engine.dart` — interní evaluator beze změny zatím; jen producer changes.

**Implementation steps:**
1. Implementovat `Player.fromJournal(uid, journal, levelCurve)` — static factory. Sumuje XP přes journal.events.whereType<RewardGrantEvent>(), aplikuje `LevelCurve`.
2. PlayerProvider `update` callback rebuilds Player z (uid, journal). Already from Phase 4 — jen mění source dataflow.
3. Engine evaluator nadále přijímá `EngineEvaluationInput` (s level/totalXp fieldy). Provider, který input plní, čte z Player.
4. Verify: existující eval-cycle behavior nezměněno. Same set of `ObjectiveCompletionEvent` + `NodeCompletionEvent` produced.
5. Performance check: Player rebuild musí být cheap. Cache derivace levelu mezi append'y do Journalu. Lazy invalidace `_cachedLevel == null` při `journal.append`.

**Test plan:**
- New test `test/domain/player/player_from_journal_test.dart` — golden: feed sequence of XP events, expect computed level matches LevelCurve.
- Existing `flutter test test/features/progression_engine/` passes — evaluation cycle nezměněno.
- Stress test: 1000 XP events → Player.level latency < 10ms.
- Manuální smoke: claim quest → hero card level updates immediately.

**DoD:**
- [ ] Player.level / Player.totalXp jsou computed z Journal.
- [ ] PlayerProvider rebuilds Player při Journal.append signal.
- [ ] Existing eval cycle behavior identical.
- [ ] Performance regression test passes.

**Rizika:** **Vysoké riziko** — toto je první phase, která mění source-of-truth dataflow. Misalignment mezi "Player.level dnes" a "Player.level po nové derivaci" může vést k off-by-one bug, kde achievement čte starou hodnotu. Mitigation: side-by-side comparison test — pro každý existující test seed feed → ověřit Player.level == old profile.level.

**Rollback:** revert + dočasně přepnout PlayerProvider zpět na read-through ze starého profile.

---

### Phase 6 — PlayerQuestLifecycle (sealed) + NodeState removal

**Goal:** Definovat sealed `PlayerQuestLifecycle` (4 stavy: Locked / Available / CompletedPendingClaim / Claimed). Nahradit `NodeState` enum v progression engine output. Všechny UI screens migrate na exhaustive switch.

**Pre-conditions:** Phase 5 done.

**Files touched:**
- New: `lib/domain/progression/player/player_quest_lifecycle.dart` — sealed class + 4 subtypy.
- Modify: `lib/features/progression_engine/domain/evaluator/progression_node_resolver.dart` — return `PlayerQuestLifecycle`, ne `NodeState` pro quest nodes. (Achievement / Milestone / Chapter zatím dál na `NodeState` — to migruje samostatně Phase 8 + Phase 13.)
- Modify: `lib/features/progression_engine/presentation/widgets/quest_*.dart` — pattern-match na new lifecycle. Konec booleans `isClaimable`, `isCompletedPendingClaim`.
- Delete (later, Phase 8): `node_state.dart` — zatím **necháváme** pro achievements / chapters.

**Implementation steps:**
1. Create `PlayerQuestLifecycle` sealed class.
2. `progression_node_resolver.dart` přidat method `resolveQuestLifecycle(QuestNode, ledgerSnapshot, outcomes) → PlayerQuestLifecycle` vedle stávající `resolve(...) → NodeState`.
3. Quest screen widgets migrate jeden po druhém:
   - `quest_card.dart` — switch na lifecycle.
   - `quest_section_panel.dart`
   - `quest_detail_view.dart`
   - `daily_quest_section.dart`
4. Jakmile poslední consumer migrate, smazat questovou cestu z `resolve(...)`.

**Test plan:**
- New test `test/domain/progression/player/player_quest_lifecycle_test.dart` — golden states pro každý subtype.
- New test `test/features/progression_engine/quest_resolver_lifecycle_test.dart` — kompletní state transition (Locked → Available → CompletedPendingClaim → Claimed).
- Existing UI tests (`test/features/progression/quest_screen_sections_test.dart`) update na new lifecycle, assertions na sealed types.
- Manuální smoke: claim flow projít manuálně přes každý quest typ.

**DoD:**
- [ ] PlayerQuestLifecycle exists + 4 subtypes documented.
- [ ] Quest screens use exhaustive switch.
- [ ] Žádný widget čte `quest.isClaimable` boolean — všechno přes pattern matching.
- [ ] Tests pass.

**Rizika:** Edge case states — quest in Available state with `progress: 100%` ale `ClaimPolicy.automatic` claimnut během stejného eval cycle. Mitigation: `progression_node_resolver` tests pokrývají všechny ClaimPolicy × NodeState combinations.

**Rollback:** keep NodeState path alive; revert sealed lifecycle introduction.

---

### Phase 7 — PlayerQuestCatalog read projection

**Goal:** Aggregate read model `PlayerQuestCatalog` (Map<Quest.id, PlayerQuest>). Provider expose ji jako pre-computed snapshot; UI screens čtou `playerQuestCatalog.byId(id)` nebo `.available.toList()`. Žádný widget už nepočítá lifecycle inline.

**Pre-conditions:** Phase 6 done.

**Files touched:**
- New: `lib/domain/progression/player/player_quest.dart` — `PlayerQuest { Quest quest; PlayerQuestLifecycle lifecycle; DateTime evaluatedAt; }`.
- New: `lib/domain/progression/player/player_quest_catalog.dart` — `PlayerQuestCatalog { Map<String, PlayerQuest> entries; … }`.
- New: `lib/features/progression_engine/application/player_quest_catalog_service.dart` — `build(Player, Journal, ObjectiveOutcomes) → PlayerQuestCatalog`.
- Modify: `progression_engine_provider.dart` — expose `PlayerQuestCatalog get questCatalog` (rebuild on each eval).
- Modify: quest screens — čtou z `context.watch<ProgressionEngineProvider>().questCatalog`.

**Implementation steps:**
1. Define `PlayerQuest` value class.
2. Define `PlayerQuestCatalog` collection.
3. Implement service that builds catalog from Player + Journal + Outcomes.
4. Wire to provider — provider holds latest `PlayerQuestCatalog`.
5. Migrate widgets: `quest_card.dart` receives `PlayerQuest`, not raw `(Quest, NodeState)`.
6. After last widget migrated: delete obsolete inline derivations in widgets.

**Test plan:**
- Unit test `PlayerQuestCatalogService` — given (player, journal, outcomes) returns expected map.
- Widget test — given pre-built PlayerQuestCatalog, screen renders correctly.
- Integration test: full eval cycle → catalog matches manual expectation.

**DoD:**
- [ ] `PlayerQuestCatalog` is the only API quest screens read.
- [ ] No widget contains `.where(...)` / `.firstWhere(...)` over raw quest list to derive state.
- [ ] Tests pass.

**Rizika:** Eager rebuild každý tick může být drahý při 50+ quests. Mitigation: PlayerQuestCatalog je immutable, rebuild jednou per eval. Pokud performance problem, switch to `LazyMap`-like pattern.

**Rollback:** revert; quest screens dočasně padají zpět na old derivation.

---

### Phase 8 — PlayerAchievementShelf

**Goal:** Same pattern as Phase 6+7 pro Achievements. Sealed `PlayerAchievementLifecycle` (3 stavy: Locked / InProgress / Unlocked). `PlayerAchievement` + `PlayerAchievementShelf`. Achievement screens migrate.

**Pre-conditions:** Phase 7 done.

**Files touched:**
- New: `lib/domain/progression/player/player_achievement_lifecycle.dart`.
- New: `lib/domain/progression/player/player_achievement.dart` + `player_achievement_shelf.dart`.
- New: `lib/features/progression_engine/application/player_achievement_shelf_service.dart`.
- Modify: progression_engine_provider — expose `PlayerAchievementShelf get achievementShelf`.
- Modify: achievement screen widgets.
- Delete: `node_state.dart` — pokud po Phase 6 + 8 už nemá konzumenty (Chapters drží paralelní enum dál; rozhodnout v Phase 13).

**Implementation steps:**
1. Mirror Phase 6 + 7 strukturu pro Achievement.
2. Single difference: `ClaimPolicy.automatic` → achievementy nemají `PendingClaim` stav (proposal §2.5).
3. UI smoke: achievement detail screen, unlock animation, social-tab "friend unlocked X" stránka.

**Test plan:** mirror Phase 6 + 7.

**DoD:**
- [ ] PlayerAchievementShelf exists; achievement screens read from it.
- [ ] Tests pass.
- [ ] `NodeState` enum stále existuje (chapters), ale není použit v quest/achievement codepath.

**Rizika:** Nízké — pattern už ověřený v Phase 6 + 7.

**Rollback:** `git revert`.

---

### Stage C — Cosmetics + Misc aggregates

---

### Phase 9 — Cosmetic sealed catalog (7 subtypes)

**Goal:** Refactor `Cosmetic` ze single class s `CosmeticType type` enum diskriminátor na sealed hierarchii: `Frame`, `Background`, `Companion`, `RelicCosmetic`, `Emblem`, `TitleFlair`, `MapEffect`. Catalog factories per-typ.

**Pre-conditions:** Phase 3 done (Cosmetic rename z Cosmetic).

**Files touched:**
- Modify: `lib/features/cosmetics/domain/cosmetic_models.dart` — convert `class Cosmetic` na `sealed class Cosmetic` + 7 subtypů.
- Modify: `lib/features/cosmetics/domain/cosmetic_catalog.dart` — factory metody per-typ.
- Modify: `cosmetics_provider.dart` — query API per-typ (`cosmeticCatalog.companions`, `.frames`, ...).
- Modify: `cosmetics_screen.dart`, `cosmetic_details_sheet.dart`, social profile widgets — switch from `type == CosmeticType.companion` na `is Companion` pattern matching.

**Implementation steps:**
1. Sealed hierarchy refactor — `Cosmetic` parent abstract, 7 concrete subtypů.
2. Migrate catalog content files (`companions_content.dart`, atd.) — every const Cosmetic literal updated.
3. Pattern matching sweeps — search-replace `type == CosmeticType.X` → `is X`.
4. `CosmeticType` enum **zachovat** pro slot identification (`EquippedCosmetics.slotId(CosmeticType.frame)` → returns frame id). Subtypy už nemají potřebu `type` getter, takže delete `final CosmeticType type` field.

**Test plan:**
- Unit test: každý subtype const-konstruovatelný; equality holds.
- Catalog integrity test: pro každý subtype, `cosmeticCatalog.byId(id) is Subtype` returns true.
- Existing cosmetics widget tests update na pattern matching.

**DoD:**
- [ ] Cosmetic je sealed parent + 7 subtypes.
- [ ] No `cosmetic.type == CosmeticType.X` check zůstává — všechno is-pattern.
- [ ] Tests pass.

**Rizika:** Cosmetic catalog má 100+ entries. Rename pass je rozsáhlý. Mitigation: rozdělit na sub-fáze 9.a/9.b/9.c per cosmetic-type batch (Frames first, Companions second, etc.) jestli PR roste přes 300 řádků.

**Rollback:** keep enum-driven discrimination as fallback path; revert sealed split.

---

### Phase 10 — PlayerCosmeticLifecycle + Inventory

**Goal:** Sealed `PlayerCosmeticLifecycle` (Hidden / Teased / Claimable / Owned). `PlayerCosmetic` value class. `Inventory` aggregate collection. CosmeticsProvider expose `Inventory get inventory`.

**Pre-conditions:** Phase 9 done.

**Files touched:**
- New: `lib/features/cosmetics/domain/player_cosmetic_lifecycle.dart`.
- New: `lib/features/cosmetics/domain/player_cosmetic.dart`, `inventory.dart`.
- Modify: `cosmetics_provider.dart` — Inventory rebuilt z (CosmeticCatalog, UnlockedCosmetic map, reveal evaluator output).
- Modify: cosmetic screen widgets.

**Implementation steps:**
1. Define lifecycle sealed.
2. Define PlayerCosmetic + Inventory.
3. Service that builds Inventory ze stávajících sources.
4. Widgets migrate — switch on lifecycle.
5. `UserCosmeticsState.unlocked` **zachovat** jako backing storage; Inventory derivuje. Real removal přijde v Phase 12.

**Test plan:**
- Unit: each lifecycle state correctly derived from inputs.
- Integration: unlock event → Inventory[id] transitions Hidden → ... → Owned through events.

**DoD:**
- [ ] Inventory exposed via CosmeticsProvider.
- [ ] No widget references CosmeticRevealState directly — uses PlayerCosmeticLifecycle.
- [ ] CosmeticRevealEvaluator zachován jako infrastructure; output type updated.

**Rizika:** State machine complexity — 4 lifecycle states × cosmetic types = matrix of cases. Mitigation: per-type integration tests.

**Rollback:** revert.

---

### Phase 11 — Companion lifecycle merge

**Goal:** Smazat `CompanionState` enum a `CompanionsRegistry` factory. Companion-specific UI behavior derivuje pattern-matching na `(Cosmetic catalog, PlayerCosmeticLifecycle)`.

**Pre-conditions:** Phase 10 done.

**Files touched:**
- Delete: `lib/features/cosmetics/domain/companion_state.dart`.
- Delete: `lib/features/cosmetics/application/companions_registry.dart`.
- Modify: companion details sheet, companion claim reveal widget, devtools companion section — všechny switchují na `is Companion && lifecycle is CosmeticHidden` pattern.
- New helpers (pure functions, ne třídy): `bool hidesIdentity(Cosmetic c, PlayerCosmeticLifecycle l)`, `bool showsChecklist(PlayerCosmeticLifecycle l)`.

**Implementation steps:**
1. Define helper functions (top-level or extension on PlayerCosmetic).
2. Replace each `CompanionState.X` usage one by one.
3. Test companion claim flow end-to-end.
4. Delete `companion_state.dart` + `companions_registry.dart` when call count = 0.

**Test plan:**
- New widget test: `companion_details_sheet_test.dart` for each lifecycle state, verify visible / hidden elements.
- Integration: claim flow → animation → state transition to Owned.
- Manual smoke: kompletní companion claim journey (Hidden → Teased → Claimable → Owned) přes devtools matrix + real progression.

**DoD:**
- [ ] CompanionState symbol mrtvý.
- [ ] CompanionsRegistry symbol mrtvý.
- [ ] Bug pool z předchozích sessions (claim doesn't unlock, identity leaks before claim) eliminated by construction — compiler refuses incomplete switches.

**Rizika:** Companion bugs původně motivovaly celý refactor (handoff §1). Mitigation: explicit smoke checklist with each Hidden/Teased/Claimable/Owned UI render path.

**Rollback:** **Pokud regrese**, keep CompanionState alive a treat tuto fázi jako "in progress". Lifecycle merge je vyžadovaný outcome, ale ne urgent.

---

### Phase 12 — Loadout + EmblemBoard relocation

**Goal:** `Loadout` (renamed `EquippedCosmetics`) extracted to first-class VO. `EmblemBoard` relocated z `social/application/pinned_emblems_store.dart` do `lib/features/cosmetics/domain/emblem_board.dart` + cosmetics-side provider. Persistence keys (`pinned_emblems_{uid}`) **zachovány**.

**Pre-conditions:** Phase 10 done.

**Files touched:**
- Rename: `EquippedCosmetics` → `Loadout`.
- Move: `pinned_emblems_store.dart` z social/ do cosmetics/.
- New: `lib/features/cosmetics/domain/emblem_board.dart` — `EmblemBoard` VO + slot operations.
- New: `lib/features/cosmetics/application/emblem_board_provider.dart` — state owner.
- Modify: social profile header widgets read `cosmeticsProvider.emblemBoard` namísto `pinnedEmblemsStore`.

**Implementation steps:**
1. Rename pass `EquippedCosmetics` → `Loadout` (mechanická).
2. Move PinnedEmblemsStore — git mv + update imports.
3. Refactor jeho contents na EmblemBoard VO + state provider split.
4. Persistence layer (SharedPreferences) reads same `pinned_emblems_{uid}` key.

**Test plan:**
- Existing pinned-emblems behavior test pass.
- Profile header smoke: 11-slot grid renders, drag-to-pin works.

**DoD:**
- [ ] Loadout + EmblemBoard in cosmetics/.
- [ ] Social no longer owns emblem-collection state.

**Rizika:** Low.

**Rollback:** `git revert`.

---

### Phase 13 — ChapterLifecycle + Chapter catalog wrapper

**Goal:** Sealed `ChapterLifecycle` (Locked / UnlockedNotStarted / InProgress / Completed). `Chapter` catalog wrapper aggregating chain (`ChapterOpener` → steps → `ChapterFinale`) + `ChapterCompletion` reference + side-quests. `PlayerChapter`. Delete `NodeState` (last consumer gone).

**Pre-conditions:** Phase 8 done.

**Files touched:**
- New: `lib/domain/progression/catalog/chapter.dart` — wrapper class aggregating chain entries by `chapterId`.
- New: `lib/domain/progression/player/chapter_lifecycle.dart` + `player_chapter.dart` + `player_chapter_progress.dart`.
- New: chapter service in progression_engine application.
- Modify: chapter screens, journey map, hero map screen.
- Delete: `lib/features/progression_engine/domain/models/node_state.dart` (last consumer).

**Implementation steps:**
1. Define ChapterLifecycle.
2. Build Chapter wrapper from chapter_*_content.dart literal data — provide `Chapter.byId(chapterId).openerNode`, `.stepNodes`, `.finaleNode`, `.completionNode`, `.sideQuests`.
3. PlayerChapterProgress derived service.
4. Migrate widgets.
5. After last NodeState consumer migrates, delete file.

**Test plan:**
- ChapterLifecycle state machine test (gating → opener → step → ... → finale → completion).
- Chapter screen widget test per state.

**DoD:**
- [ ] ChapterLifecycle / PlayerChapterProgress in `lib/domain/progression/player/`.
- [ ] node_state.dart deleted.
- [ ] Tests pass.

**Rizika:** Chapter chain is data-heavy (3 chapters × ~5 nodes × side-quests). Catalog wrapper must derive chain from prereq graph correctly. Mitigation: derive at startup, cache; verify chain ordering via test.

**Rollback:** `git revert`.

---

### Stage D — Engine + Social + UI

**Status:** ✅ closed 2026-05-19. All 4 phases shipped:

- Phase 16 (engine signature refactor) — `57a9f6e` 2026-05-18
- Phase 17 (SocialPresence aggregate) — `35b40b8` 2026-05-18
- Phase 18 (Result/AppError — foundation + outermost layer) — `c09db65` 2026-05-18, with Phase 18.b (repository contracts) deferred per [follow_ups.md §2.17](follow_ups.md#217-phase-18b--repository-contracts-return-resultt-apperror-deferred-from-phase-18).
- Phase 19 (UI sweep — quests + cosmetics) — `daf5ca6` 2026-05-18, with Phase 19.c (journey map) + 19.d (HC screens) deferred per [follow_ups.md §2.18](follow_ups.md#218-phase-19-leftovers--journey-map--health-connect-screens-deferred-from-phase-19).

Stage E (Hardening) opens with Phase 20 (JournalProjection); deferred sub-phases are non-blocking and can land opportunistically.

---

### Phase 14 — GoalBoard extraction

**Goal:** `GoalBoard` + `PlayerGoal` přesunout z `goals_provider.dart` mixed-state do `lib/features/health_connect/domain/`. GoalsProvider zůstává jako thin wrapper.

**Pre-conditions:** Phase 4 done (Player aggregate exists pro reference).

**Files touched:**
- New: `lib/features/health_connect/domain/goal_board.dart`, `player_goal.dart`.
- Modify: `goals_provider.dart` — extract domain logic do entit, provider drží `GoalBoard get board`.
- Modify: settings goals section, home cards reading goals.

**Implementation steps:**
1. Extract domain classes.
2. Provider rewrites as thin façade.
3. Persistence keys (`goal_daily_steps` atd. v SharedPreferences) **zachovány**.

**Test plan:**
- Unit: PlayerGoal equality, revision history append/lookup.
- Integration: goal change → backfill retroactive evaluation still correct.

**DoD:**
- [ ] GoalBoard exists in domain.
- [ ] GoalsProvider 50% smaller — only orchestration left.

**Rizika:** Low.

**Rollback:** `git revert`.

---

### Phase 15 — HealthSnapshot + NutritionSnapshot domain types

**Goal:** Define domain types `HealthSnapshot` + `NutritionSnapshot` that wrap fitness / KT reads in pure-Dart immutable structure. Engine evaluator + objective evaluator čtou tyto types, ne raw provider state.

**Pre-conditions:** Phase 5 done.

**Files touched:**
- New: `lib/features/health_connect/domain/health_snapshot.dart`.
- New: `lib/features/nutrition/domain/nutrition_snapshot.dart`.
- Modify: progression engine evaluator path — engine evaluation input populated from snapshots, ne přímo z FitnessProvider / KalorickeTabulkyProvider.

**Implementation steps:**
1. Define snapshot value classes.
2. FitnessProvider / KalorickeTabulkyProvider expose `HealthSnapshot get snapshot` / `NutritionSnapshot get snapshot` methods that fabricate snapshot.
3. ProgressionEngineProvider reads snapshots to build EngineEvaluationInput (still flat — final refactor Phase 16).

**Test plan:**
- Snapshot equality / copyWith unit tests.
- Integration: eval cycle produces same outcomes pre/post snapshot wrapper.

**DoD:**
- [ ] Snapshot domain types exist.
- [ ] No cross-feature provider import in engine evaluator — snapshots passed through.

**Rizika:** Snapshot rebuild cost. Mitigation: snapshot je `const` constructible, rebuild jen na podstatnou změnu dat.

**Rollback:** `git revert`.

---

### Phase 16 — Engine signature refactor (EngineEvaluationInput → arg list)

**Goal:** Eliminovat `EngineEvaluationInput` flat record. Engine evaluator signature: `evaluate(player, healthSnapshot, nutritionSnapshot, goalBoard, journal) → ProgressionResolutionResult`.

**Pre-conditions:** Phase 14 + 15 done.

**Files touched:**
- Modify: `progression_engine.dart` — new evaluate() signature.
- Modify: ObjectiveEvaluator — accepts Player + snapshots + GoalBoard + Journal directly.
- Delete: `engine_evaluation_input.dart`.
- Modify: progression_engine_provider — calls evaluate() with structured args.

**Implementation steps:**
1. Add new `evaluate(...)` method alongside existing `evaluate(input)`.
2. Migrate ObjectiveEvaluator interní logic na new signature, internally calling old by wrapping.
3. Migrate provider call site.
4. Delete old signature + EngineEvaluationInput class.

**Test plan:**
- Existing evaluation tests pass.
- New signature integration test pokrývá all known evaluation scenarios.

**DoD:**
- [ ] EngineEvaluationInput symbol mrtvý.
- [ ] Engine evaluate() takes structured args.
- [ ] No flat record between provider and evaluator.

**Rizika:** **Vysoké** — heart of progression. Mitigation: side-by-side test comparison pro existing test fixtures.

**Rollback:** restore EngineEvaluationInput; revert.

---

### Phase 17 — SocialPresence aggregate

**Status:** ✅ shipped 2026-05-18 (`35b40b8`). See ADR `social-presence-aggregate-extraction`.

**Goal:** `SocialPresence` aggregate s `Handle` / `Friendship` / `FriendRequest` / `AchievementShare` / `SocialNotification` components. Rename `SocialRepository` → `SocialPresenceRepository`. `SocialUserProfile` zůstává jako documented read model.

**Pre-conditions:** Phase 11 done (Cosmetic Loadout exists — SocialPresence reference equipped cosmetics).

**Files touched:**
- Reorganize: `social/domain/social_models.dart` → split do per-entity souborů.
- New: `social/domain/social_presence.dart` — aggregate facade.
- Rename: `SocialRepository` → `SocialPresenceRepository`.
- Modify: `social_provider.dart` — expose `SocialPresence get presence`.
- Cache documentation (in code comments + proposal §5 reference): `SocialUserProfile` rebuild path z Player + Journal.

**Implementation steps:**
1. Split `social_models.dart` into per-entity files.
2. Define `SocialPresence` aggregate facade.
3. Rename repository interface (mechanical).
4. Document `SocialUserProfile` jako read model + dotument rebuild trigger.
5. Migrate UI tabs.

**Test plan:**
- Existing social tab integration tests pass.
- Friend request flow smoke test.

**DoD:**
- [ ] SocialPresence aggregate exposed.
- [ ] SocialUserProfile dokumentovaný cache + rebuild path.
- [ ] Tests pass.

**Rizika:** Social tab je production-critical. Mitigation: per-tab smoke check (Friends / Leaderboard / Feed / Notifications).

**Rollback:** `git revert`.

---

### Phase 18 — Result/Error type hierarchy

**Status:** ⚠️ partially shipped 2026-05-18 (`c09db65`). Foundation + outermost data layer done; repository contract migrations explicitly deferred as **Phase 18.b** ([follow_ups.md §2.17](follow_ups.md#217-phase-18b--repository-contracts-return-resultt-apperror-deferred-from-phase-18)). See ADR `result-app-error-foundation`.

**Goal:** Zavést `sealed AppError` hierarchii a `Result<T, AppError>` return type na **domain layer + repository contracts + Firestore gateway**. Eliminuje silent error swallowing (`try/catch (e) → AppLog.warn(e)` patterny) v sync codepath. Není totální rewrite — scope se omezuje na external-boundary kontrakt.

**Pre-conditions:** Phase 17 done — všechny repositories existují jako domain interfaces.

**Background:** Audit (viz `follow_ups.md`) odhalil že `BackgroundSyncService` swallows errors at line 232, vrací `true` aby zabránil WorkManager retry. Firestore gateway loguje pull errors at `info` a push errors at `debug` — chyby z cloud push jsou v podstatě neviditelné. **Žádná retry/backoff classification, žádné typed errors.** Tato fáze adresuje root cause na úrovni kontraktů.

**Files touched:**

- New: `lib/core/errors/app_error.dart` — sealed `AppError` + 5 subtypů:
  - `NetworkError(originalError, isTransient: bool)` — Firestore offline, KT 401, HC quota.
  - `ValidationError(reason)` — invalid input.
  - `PermissionError(scope)` — HC permission denied, Firestore rule rejection.
  - `NotFoundError(entityType, id)` — quest/cosmetic/user not found.
  - `UpstreamError(originalError, stackTrace)` — catch-all unknown.
- New: `lib/core/result/result.dart` — sealed `Result<T, E>` s `Success(T value)` a `Failure(E error)`. Helper extension `.map`, `.flatMap`, `.unwrapOr(fallback)`.
- Modify: domain repository interfaces (`JournalRepository`, `PlayerRepository`, `InventoryRepository`, `SocialPresenceRepository`) — methods vrací `Future<Result<T, AppError>>` namísto `Future<T>` (kde failure je možný).
- Modify: `firestore_progression_engine_gateway.dart` — wrap push/pull v Result. Map known Firestore errors na typed subtypes.
- Modify: `kaloricke_tabulky_service.dart` — wrap HTTP errors. 401 → `NetworkError(isTransient: true)` triggers re-login retry.
- Modify: `background_sync_service.dart` — explicit Result-based decision: transient → return true (WorkManager retries), permanent → return false + log warn.

**Implementation steps:**

1. Definice `AppError` sealed + `Result<T, E>` sealed.
2. Repository interfaces — change one at a time. Start with `JournalRepository` (most critical, most error-prone).
3. Firestore gateway — explicit error categorization na `FirebaseException.code` (`unavailable` → transient, `permission-denied` → permanent, atd.).
4. BackgroundSync — refactor sync callback na `Future<Result<SyncSummary, AppError>>`. WorkManager retry decision je pattern-match na error severity.
5. Cosmetic entitlements source, social repository — same pattern.
6. **NEDĚLAT:** widget `try/catch` bloky, UI snackbar handling. Toto je scope follow-up phase 19+ pokud potřeba.

**Test plan:**

- Unit test `test/core/result/result_test.dart` — Success / Failure pattern matching exhaustive.
- Integration test: simulate `FirebaseException(code: 'unavailable')` → assert returns `Failure(NetworkError(isTransient: true))`.
- Integration test: BackgroundSync gets transient error → return true; permanent → return false.
- Existing tests — repositoryReadCallback() now returns Result, update assertions.

**DoD:**

- [ ] `AppError` sealed hierarchy + `Result<T, E>` exist v `lib/core/`.
- [ ] All cross-boundary repository methods (Firestore push/pull, KT HTTP, HC quota-prone) return Result.
- [ ] BackgroundSync explicitně pattern-matchuje na error severity.
- [ ] Audit: `grep "catch (.*) {" lib/core/services/` ukazuje 0 untyped swallows v sync codepath.
- [ ] Tests pass; specifically new error-categorization tests.

**Rizika:** Scope creep — pokušení typecastnout všechny errors v codebase. Mitigation: explicit scope statement v PR description: "Domain + repository + outermost data layer only. Widget try/catch je out of scope."

**Rollback:** `git revert`. Stable point pokud bude Result API mít sub-optimální shape.

---

### Phase 19 — UI sweep: widget read-only audit

**Status:** ⚠️ partially shipped 2026-05-18 (`daf5ca6`). 2 features (quests + cosmetics) migrated; journey map + HC screens explicitly deferred as **Phase 19.c / 19.d** ([follow_ups.md §2.18](follow_ups.md#218-phase-19-leftovers--journey-map--health-connect-screens-deferred-from-phase-19)). See ADR `ui-sweep-quests-cosmetics`.

**Goal:** Audit pass napříč všemi widgety. Cíl: žádný `build()` neobsahuje **logiku nad doménou** (žádné `.where`, `.firstWhere`, `_isXxx`, `_resolveYyy`, žádné komputované booleans). Widget jen čte hotový `PlayerXxx` z provideru a switchuje na lifecycle.

**Pre-conditions:** Phase 13 + Phase 17 done — všechny aggregates exposed.

**Files touched:** All widgets in `lib/features/*/presentation/`. Variabilní rozsah.

**Implementation steps:**
1. `grep -r "\.where(" lib/features/*/presentation/`.
2. `grep -r "\.firstWhere(" lib/features/*/presentation/`.
3. `grep -r "bool _" lib/features/*/presentation/` (private bool methods on widget state).
4. Pro každý hit: rozhodnout — je to UI-only logic (např. layout-driven filter) nebo domain-derived? Pokud domain-derived, **přesunout do read projection** v provideru.
5. Track findings v interní checklist; landovat per-feature batch PR (Phase 19.a — Quests UI, 19.b — Cosmetics UI, atd.).

**Test plan:**
- Visual regression — golden screenshots na klíčových obrazovkách před/po sweepu.
- Existing widget tests pass.

**DoD:**
- [ ] Žádný widget `build()` obsahuje `.where()` nebo equivalent over domain collections.
- [ ] Read projections živé v provider/application layer.
- [ ] UI ↔ doména contract documented.

**Rizika:** Variabilní rozsah — může objevit hidden complexity v některých screenech. Mitigation: time-box audit (max 1 týden); pokud screen je gnarly, hide jako TODO + samostatný follow-up PR.

**Rollback:** Per-widget; lokalizovat změny.

---

### Stage E — Hardening

**Status (2026-05-19):** Phase 20 + Phase 21 shipped (see commit log). Phase 21 lint matchers ratchet existing violations (baselines documented in [follow_ups.md §2.25](follow_ups.md#225-phase-21-lint-baseline-cleanup-queue-deferred-from-phase-21)). Phase 22 (legacy V1 progression cleanup) remains — non-blocking, can land opportunistically.

---

### Phase 20 — Cache rebuild paths + JournalProjection interface

**Goal:** Promote `cosmetic_unlock_bridge.dart` pattern na first-class `JournalProjection<T>` interface. Document `SocialUserProfile` + `CosmeticsUnlockRecord` cache rebuild triggers explicitly. Each cache má `RebuildFromJournalReason` enum.

**Pre-conditions:** Phase 17 done.

**Files touched:**
- New: `lib/domain/journal/journal_projection.dart` — abstract interface.
- Modify: `cosmetic_unlock_bridge.dart` implementuje `JournalProjection`.
- New: `social_profile_projection.dart` — rebuild Social profile cache from Player + Journal.

**Implementation steps:**
1. Define interface + enum.
2. Migrate existing bridge na nový pattern.
3. Implement social profile projection.

**Test plan:**
- Factory reset → fresh install → projections rebuild caches correctly.
- Pull-and-merge → projections reapply historical data.

**DoD:**
- [x] JournalProjection interface exists (`lib/domain/journal/journal_projection.dart`).
- [x] Both caches use it — `CosmeticUnlockBridge implements JournalProjection<int>`, `SocialProfileProjection implements JournalProjection<SocialProfileSyncPayload?>`.
- [x] Rebuild scenarios documented (glossary entry `journal-projection`, ADR `journal-projection-cache-rebuild-contract`, dataflow `journal-projection-rebuild`) + tested (`test/features/progression_engine/cosmetic_unlock_bridge_projection_test.dart`: factory reset, pull-and-merge, idempotency, no-binding safe).

**Rizika:** Nízké.

**Rollback:** `git revert`.

---

### Phase 21 — Lint rules / review checklist

**Goal:** Pevně zabudovat anti-patterns z proposal §7 jako lint pravidla nebo PR review checklist. Tři kategorie rules: doménová puritu, typed-id usage, l10n string discipline.

**Pre-conditions:** Phase 20 done.

**Files touched:**

- New: `analysis_options.yaml` rules nebo `tools/lints/` (custom_lint package).
- New: `docs/contributing.md` (or `CLAUDE.md` extension) — review checklist.

**Implementation steps:**

1. **Domain purity** (already in Phase 0 skeleton; promote z test-based check na proper lint).
2. **Typed-id usage check** — lint nebo grep-based test, který fail-fastne při `String questId = ...` v doménové vrstvě. Mělo by být `QuestId questId = QuestId('...')`.
3. **L10n strings lint** — žádné string literally v widget text-bearing positions (`Text('...')`, `AppBar(title: Text('...'))`, atd.). Whitelist: `Text('')` (empty placeholder), debug-only assertions, asset paths. Implementace přes [`custom_lint`](https://pub.dev/packages/custom_lint) nebo [`flutter_lints`](https://pub.dev/packages/flutter_lints) extension.
4. **Widget no-logic check** — grep-based test, který skenuje `lib/features/*/presentation/` na `.where(`, `.firstWhere(`, `_isXxx` patterns. Fail-fast pokud match nad domain collection.
5. **Sealed exhaustive switch** — z analysis_options povolit Dart compiler exhaustive switch checking (`switch_expression_exhaustive` rule).
6. Document non-machine rules (denormalized cache treatment, persistence-schema-no-change) v review checklist.

**Test plan:**

- Lint catches deliberate violations v `test/lint_fixtures/` (přidat fixture per pravidlo: bad domain import, untyped id, string literal v Text, .where v build).
- Review checklist used na následující PR (smoke test of doc usability).

**DoD:**

- [x] Domain purity lint active — `test/domain_purity_test.dart` (strict on `lib/domain/`) + ratchet on `lib/features/*/domain/` v `test/lint/production_scan_test.dart`.
- [x] Typed-id usage grep-test active — `findUntypedIdDeclarations` matcher + ratchet (baselines: 7 v `lib/domain/`, 72 v `lib/features/*/domain/`).
- [x] L10n string lint active s documented whitelist — `findRawTextLiterals` matcher (skips empty `Text('')`, interpolated strings, `// lint-ignore: l10n-literal`); ratchet baseline 29.
- [x] Widget no-logic grep-test active — `findWidgetCollectionLogic` matcher (`.where(`, `.firstWhere(`, `.singleWhere(`, `.indexWhere(` v presentation/); ratchet baseline 60.
- [x] Exhaustive switch enforcement — `exhaustive_cases: true` v `analysis_options.yaml` (sealed types already enforced by Dart 3 compiler).
- [x] Review checklist v [docs/contributing.md](../contributing.md) — covers lint matchers, per-line opt-out marker syntax, ratchet protocol, and review-only rules (denormalised caches, persistence-schema-no-change, cross-feature reach).

**Rizika:** Custom lint packages přidávají dev dependency a build time. Mitigation: kde lint je heavy, použít grep-based test runnable in CI (cheap). Lint package adoption gradual.

**Rollback:** `git revert`.

---

### Phase 22 — Legacy V1 progression cleanup (deferred)

**Goal:** Delete `lib/features/progression/`. Migrate `background_sync_service.dart` to V2 engine. Migrate devtools sections. Delete legacy tests.

**Pre-conditions:** Phases 0-21 done. Out of scope této session.

**Files touched:**
- Delete: `lib/features/progression/` (full folder, 30+ files).
- Modify: `lib/core/services/background_sync_service.dart` — migrate na V2 ProgressionEngineProvider.
- Modify: 3 devtools sections.
- Delete: `test/features/progression/` (5 files).

**Implementation steps:**
1. Migrate background sync to V2.
2. Migrate devtools to V2.
3. Verify zero remaining imports from `features/progression/`.
4. Delete folder.

**Test plan:**
- Background sync runs successfully (manual + integration test).
- Devtools sections work.
- Test suite passes without legacy folder.

**DoD:**
- [ ] `lib/features/progression/` deleted.
- [ ] No regressions.

**Rizika:** Mitigation: separate PR, deferred until other phases stable.

**Rollback:** revert + restore folder.

---

## 3. Cross-cutting risks & mitigations

| Risk | Manifestace | Mitigation |
|---|---|---|
| **Player.level drift mezi old + new path** | Hero card zobrazuje L41, achievement screen L42. | Side-by-side test in Phase 5 — feed identical sequence, assert Player.level == old profile.level. |
| **Stale provider not rebuilding on Journal append** | Claim quest, no UI update. | ProgressionEngineProvider notifies _všechny_ downstream při `Journal.append`. Unit test smoke. |
| **Companion identity leak before claim** | Original motivace refactoru. | Phase 11 odstraňuje by construction — pattern matching `is Companion && lifecycle is! CosmeticOwned`. |
| **Persistence schema accidentally migrated** | Isar `.g.dart` re-generated, breaks existing DB. | Plan explicitly forbids schema changes. Each PR checks `git diff` on `.g.dart` — should be unchanged. |
| **PR-size creep** | Phases X.a/X.b/X.c balloon over 500 LoC. | Hard 300-LoC limit per PR. If a phase blows the limit, split into sub-fáze. Plan revision allowed. |
| **Legacy V1 contaminuje new path** | Some test inadvertently exercises V1 evaluator. | Phase 22 is deferred precisely because V1 cleanup is a separate concern. Until then, isolate V1 in its folder. |
| **freezed / build_runner introduced via PR drift** | Some helper PR adds dependency. | Phase 0 lint rule blocks unknown pubspec deps. Review checklist. |

---

## 4. Acceptance criteria — "refactor complete"

Refactor je hotový, když platí všech 7:

1. **`lib/domain/`** existuje a obsahuje Player, Journal, ProgressionEntry catalog, lifecycly. Lint rule chrání purity.
2. **Žádný widget `build()`** nevolá `.where` / `.firstWhere` na collection of domain objects pro derivaci stavu. Audit grep ukáže 0 hits.
3. **Player.level / totalXp** jsou computed z Journal events (ne input). `EngineEvaluationInput` symbol smazán.
4. **Sealed lifecycly** (PlayerQuestLifecycle, PlayerAchievementLifecycle, PlayerCosmeticLifecycle, ChapterLifecycle) jsou jediný způsob, jak UI rozlišuje stavy. Žádné `isXxx` boolean property.
5. **Catalog ↔ Instance ↔ History** triple je explicit pro každou entity kind. Catalog read-only, Instance derived per-Player, History event-sourced in Journal.
6. **EmblemBoard, Loadout, Inventory, GoalBoard, SocialPresence** existují jako first-class aggregates / VO.
7. **Anti-patterns z proposal §7** chytá lint nebo review checklist.

---

## 5. Out of scope této session

- Phase 22 (V1 cleanup) — execution.
- Phase changes to persistence schema.
- New feature work — refactor je infrastructure, ne nová funkčnost.
- Performance optimization beyond what naturally falls out of read-projection caching.
- L10n cleanup (proposal §1.1 smell items 1+2 — sheets_export, bushido_export_config).
- Items v `follow_ups.md` označené jako "Deferred" — cloud-hosted catalogs/configs, persistence migration framework, three-layer Config System, atd.

Tyto byly explicit označeny v code (TODO comments add v této session) nebo v `follow_ups.md`.

---

## 6. Communication patterns mezi fázemi

- **Každá fáze startuje** novou session s pre-conditions check (verify předchozí fáze landla a tests pass).
- **Každá fáze končí** updatem [docs/site/data/](../site/data/) JSONs per CLAUDE.md instrukce (viz §7.4 níž — explicit triggers a soubory).
- **Migration progress** se trackuje v dedicated `docs/domain_model/migration_status.md` (created v Phase 0) — checklist phases + landed PR links.
- **Po Phase 22** je tento `migration_plan.md` archivován do `docs/domain_model/archive/` per CLAUDE.md "closing out a finished plan" workflow.

---

## 7. Per-phase session protocol (fresh-session execution)

**Klíčové pravidlo:** Každá fáze musí být plně proveditelná v nové Claude session **bez kontextu z předchozích sessions**. Implementace fáze čerpá výhradně z trvalých artefaktů v repu: `proposal.md`, tento `migration_plan.md`, `follow_ups.md`, `CLAUDE.md`, kód, `git log`. Žádné spoléhání na "to už víme z minula" — to už víme z dokumentů.

### 7.1 Bootstrap pro novou session

Implementující session na začátku **musí** projít tento protokol:

1. **Identifikuj cílovou fázi.** Uživatel ji řekne (např. "implementuj Phase 3.a") nebo vyber nejnižší `pending` v `migration_status.md`.
2. **Přečti v tomto pořadí, celé (žádné skimování):**
   - `docs/domain_model/proposal.md` — celý dokument. Definuje cílový tvar doménového modelu.
   - `docs/domain_model/migration_plan.md` — celý dokument (§1-7), s důrazem na sekci cílové fáze.
   - `docs/domain_model/follow_ups.md` — § 1 (folded items) a §2 (deferred — vědět, co **není** scope).
   - `CLAUDE.md` (root) — pracovní pravidla projektu.
   - `docs/architecture.md` — layering rules + design tokens.
3. **Verify pre-conditions cílové fáze.** Pro každou předchozí fázi uvedenou v `Pre-conditions` zkontroluj:
   - `git log --grep "Phase N" --oneline` ukazuje merged commit.
   - `git diff origin/main..HEAD` ukazuje **prázdné** (jsme na čisté main).
   - `flutter analyze` clean.
   - Relevantní testy z té fáze pass (`flutter test test/...` z DoD předchozí fáze).
4. **Přečti všechny soubory v `Files touched` sekci cílové fáze** Read toolem **před** jakoukoli edicí. Bez čtení `Edit` nefunguje a riskujeme blind edits.
5. **Zaregistruj TodoWrite checklist** podle `Implementation steps` cílové fáze. Každý step jako todo item.

### 7.2 Implementační smyčka

- Po každém Implementation step → mark todo `completed`.
- Po každém logickém commitu → push to `refactor/phase-N-<slug>` branch.
- Pokud step ukáže nový problém mimo scope fáze → **zapsat do `follow_ups.md`**, ne fixnout teď. Scope discipline.
- Pokud step blokuje další progress → STOP a zeptat se uživatele (per CLAUDE.md).

### 7.3 Closing checklist (DoD verification)

Před PR open:

- [ ] Všechny `DoD` checkboxy cílové fáze v migration plánu zaškrtnuty.
- [ ] `flutter analyze` clean.
- [ ] `Test plan` items zaškrtnuté, výsledky v PR description.
- [ ] Manuální smoke check kde fáze vyžaduje (UI obrazovky).
- [ ] **docs/site/data/ updates** dle §7.4 — pokud fáze přidala providery / sealed types / Isar collections / Firestore subcollections / ADRs.
- [ ] **migration_status.md** updated — cílová fáze přesunuta z `pending` do `done`, link na PR.
- [ ] No persistence schema change (`git diff` na `.g.dart` files je prázdný).
- [ ] No new pubspec.yaml dependency (kromě explicitně schválených ve fázi).

### 7.4 docs/site/data/ update triggers

Per CLAUDE.md "Adding a new feature" workflow — každá fáze musí ověřit, jestli některý z těchto triggerů kvalifikuje. Pokud ano, update **ve stejném commitu** jako produkční změny.

| Trigger | Update soubor |
| --- | --- |
| Nová feature složka v `lib/features/` | `docs/site/data/features.json` |
| Nový provider / přidaná DI edge | `docs/site/data/providers.json` |
| Nová Isar collection / Firestore subcollection / SharedPreferences key / secure storage key | `docs/site/data/storage.json` |
| Nový externí system (HTTP API, OS integration) | `docs/site/data/integrations.json` |
| Nový významný data flow | `docs/site/data/dataflows.json` |
| Nový sealed type / významný enum / hierarchie value object | `docs/site/data/glossary.json` |
| Nové architektonické rozhodnutí (alternative considered, trade-off chosen) | `docs/site/data/decisions.json` (ADR) |
| User-visible feature change | top-level `README.md` |

**Příklady aplikace:**

- Phase 2 (Journal infrastructure) → `glossary.json` (přidat `Journal`, `JournalEvent`, `EventKey`, `PeriodKey` jako sealed/VO), `providers.json` (Journal interface visible v DI grafu). `decisions.json` — ADR "Why event-sourced read layer over relational projection".
- Phase 4 (Player aggregate) → `glossary.json` (`Player`, `LevelCurve`), `providers.json` (`PlayerProvider`), `decisions.json` — ADR "Single-player app: Player as root aggregate, no Context".
- Phase 6 (PlayerQuestLifecycle) → `glossary.json` (sealed lifecycle, 4 stavy).
- Phase 9 (Cosmetic sealed catalog) → `glossary.json` (Cosmetic sealed + 7 subtypy nahrazuje 1 class s discriminator enum), `decisions.json` — ADR "Sealed hierarchy nad single-class enum-discriminated".
- Phase 11 (Companion lifecycle merge) → `decisions.json` — ADR "Pattern matching nad paralelními enum hierarchiemi" + revoke předchozí companion-specific ADR pokud existoval.
- Phase 18 (Result/Error type hierarchy) → `glossary.json` (`Result<T, E>`, `AppError` sealed), `decisions.json` — ADR.
- Phase 20 (JournalProjection) → `glossary.json`, `dataflows.json` (rebuild from journal flow), `decisions.json` — ADR.

**Pokud fáze žádný trigger neaktivuje** (např. čistě rename pass v Phase 3.a) — pak no-op, ale **explicitně to v PR description uveď**: "No docs/site/ update — pure rename without architectural change".

### 7.5 Anti-protocols (co NEDĚLAT)

- ❌ Nereferenovat "minulou session" v PR description nebo commit message. Reference je code + docs.
- ❌ Necitovat decisions, které nejsou v `proposal.md` / `migration_plan.md` / `follow_ups.md` / ADR. Pokud rozhodnutí existuje jen v paměti, dokumentuj ho.
- ❌ Nebackport-ovat scope z pozdějších fází ("when I was at it, I also did Phase 5 changes"). Drž PR atomické.
- ❌ Nepřejíždět follow-up items "by the way". `follow_ups.md` items mají vlastní lifecycle.
