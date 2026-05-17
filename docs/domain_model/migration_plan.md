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
| | 2 | Journal infrastructure (LedgerEvent → JournalEvent) | nízké | ~200 |
| | 3 | Catalog rename pass (ProgressionNode → ProgressionEntry + suffix drop) | střední | ~500 (mechanický) |
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
| | 18 | UI sweep — widgets read-only audit | střední | ~variable |
| **E: Hardening** | 19 | Cache rebuild paths + JournalProjection interface | nízké | ~150 |
| | 20 | Lint rules / review checklist | nízké | ~100 |
| **deferred** | 21 | Legacy V1 progression cleanup (`lib/features/progression/`) | mimo scope tohoto plánu | — |

**Celkový odhad:** ~4500 LoC změn napříč ~50 PR (po sub-fázích). Realistický time-frame: **3-6 měsíců** podle volné kapacity.

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
- New: `lib/domain/journal/period_key.dart` — `PeriodKey` VO.
- Modify: `progression_engine/data/` repository implementuje `Journal` interface a forwarduje na existující Isar reads.
- Update call sajty v `progression_engine_provider`, `hybrid_progression_engine_repository`, `daily_section_resolver`, `firestore_*_gateway`, atd. (~15 souborů).

**Implementation steps:**
1. Vytvořit `Journal` interface + 4 VO.
2. Implementovat `IsarJournalAdapter` v `lib/features/progression_engine/data/` — wraps existující collections.
3. Rename `LedgerEvent` → `JournalEvent` + move.
4. Existující `HybridProgressionEngineRepository` implementuje `Journal` (extends abstract class).
5. Postupně migrate consumery — místo `repository.queryRewardGrants(...)` zavolají `journal.eventsForNode(id).whereType<RewardGrantEvent>()`.

**Test plan:**
- `flutter analyze` clean.
- `flutter test test/features/progression/` + `test/features/progression_engine/` passes — existující testy pokrývají ledger reads.
- New test `test/domain/journal/journal_adapter_test.dart` — IsarJournalAdapter vrátí stejné events jako přímý Isar read pro stejný `uid`. Golden test.

**DoD:**
- [ ] `LedgerEvent` symbol mrtvý.
- [ ] `Journal` interface žije v `lib/domain/journal/`, implementace v progression_engine/data/.
- [ ] Všichni konzumenti (engine, daily_section_resolver, cosmetic_unlock_bridge, social) čtou přes `Journal` interface, ne přes raw Isar.
- [ ] Tests pass + manuální evaluation cycle smoke check.

**Rizika:** Některé call sajty mají ledger-specific query API (`queryRewardGrants(domain: X)`), které není v generic `Journal` interface. Mitigation: rozšířit interface o tyto query metody nebo mapovat via `events.whereType<RewardGrantEvent>().where((e) => …)`. Pokud query je hot-path (např. evaluator volá per-tick), zachovat indexované metody na interface.

**Rollback:** `git revert` + smazat `lib/domain/journal/`.

---

### Phase 3 — Catalog rename pass

**Goal:** Mechanický rename `ProgressionNode` → `ProgressionEntry`, drop `Node` suffix u všech subtypů, `ObjectiveDefinition` → `Objective`, `CosmeticDefinition` → `Cosmetic`. `RewardDefinition` zachován (proposal §2.3 disambiguation).

**Pre-conditions:** Phase 2 done (Journal exists tak, abychom mohli referencovat).

**Files touched:**
- `lib/features/progression_engine/domain/models/progression_node_definition.dart` — rename všechny classes.
- `lib/features/progression_engine/domain/catalog/content/*.dart` (~12 files) — update všechny subtype call sites.
- `lib/features/progression_engine/domain/catalog/progression_node_catalog.dart` → `progression_entry_catalog.dart`. Rename `ProgressionNodeCatalog` → `ProgressionEntryCatalog`.
- `lib/features/progression_engine/domain/models/objective_definition.dart` — class rename.
- `lib/features/cosmetics/domain/cosmetic_models.dart` — `CosmeticDefinition` → `Cosmetic` (single class for now; sealing přijde v Phase 9).
- ~50+ call sites napříč evaluators, presenters, tests.

**Implementation steps:**
1. Pure mechanická rename — IDE-driven refactor "Rename Symbol" zvládne většinu.
2. Update všechny string-id konvence v komentářích (ne v kódu — id stringy zachovat).
3. Update `progression_node_catalog.dart` filename + class name.
4. Run `flutter analyze` — fixnout pozůstatky.
5. `lib/domain/progression/catalog/` zatím **prázdná** — fyzický move přijde až v Phase 4+.

**Implementation note:** Tato fáze **nepřesouvá** soubory do `lib/domain/`. Jen renamuje uvnitř `lib/features/progression_engine/domain/`. Cíl: oddělit renaming risk od move-and-restructure risk.

**Test plan:**
- `flutter analyze` clean.
- All test suites pass (`flutter test`).
- Manuální smoke test: spustit appku, otevřít každou progression-aware obrazovku (Home progression card, Quests V2, Achievements, Journey).

**DoD:**
- [ ] Žádný symbol s `Node` suffixem v `progression_engine/domain/` (kromě `_node_` v Isar `.g.dart` files, které nepatří doméně).
- [ ] `Cosmetic` (ne `CosmeticDefinition`) napříč repo.
- [ ] `Objective` (ne `ObjectiveDefinition`) napříč repo.
- [ ] Build green; all tests pass.

**Rizika:** Generic rename collisions. Např. `class Companion` (po renamingu z `CompanionAvailabilityNode → CompanionAvailability` … počkat — `CompanionAvailability` zachovává disambiguator. Re-check: per proposal §2.3, `CompanionAvailabilityNode` → `CompanionAvailability` (catalog node), zatímco `Cosmetic` typu `companion` → bude `Companion` (catalog cosmetic) až v Phase 9. Tady v Phase 3 jen rename `CompanionAvailabilityNode` → `CompanionAvailability`.

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

**Pre-conditions:** Phase 3 done (Cosmetic rename z CosmeticDefinition).

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

### Phase 18 — UI sweep: widget read-only audit

**Goal:** Audit pass napříč všemi widgety. Cíl: žádný `build()` neobsahuje **logiku nad doménou** (žádné `.where`, `.firstWhere`, `_isXxx`, `_resolveYyy`, žádné komputované booleans). Widget jen čte hotový `PlayerXxx` z provideru a switchuje na lifecycle.

**Pre-conditions:** Phase 13 + Phase 17 done — všechny aggregates exposed.

**Files touched:** All widgets in `lib/features/*/presentation/`. Variabilní rozsah.

**Implementation steps:**
1. `grep -r "\.where(" lib/features/*/presentation/`.
2. `grep -r "\.firstWhere(" lib/features/*/presentation/`.
3. `grep -r "bool _" lib/features/*/presentation/` (private bool methods on widget state).
4. Pro každý hit: rozhodnout — je to UI-only logic (např. layout-driven filter) nebo domain-derived? Pokud domain-derived, **přesunout do read projection** v provideru.
5. Track findings v interní checklist; landovat per-feature batch PR (Phase 18.a — Quests UI, 18.b — Cosmetics UI, atd.).

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

---

### Phase 19 — Cache rebuild paths + JournalProjection interface

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
- [ ] JournalProjection interface exists.
- [ ] Both caches use it.
- [ ] Rebuild scenarios documented + tested.

**Rizika:** Nízké.

**Rollback:** `git revert`.

---

### Phase 20 — Lint rules / review checklist

**Goal:** Pevně zabudovat anti-patterns z proposal §7 jako lint pravidla nebo PR review checklist.

**Pre-conditions:** Phase 19 done.

**Files touched:**
- New: `analysis_options.yaml` rules nebo `tools/lints/`.
- New: `docs/contributing.md` (or `CLAUDE.md` extension) — review checklist.

**Implementation steps:**
1. Identify which anti-patterns can be linted (most: domain purity, widget no-logic) and which require review (denormalized cache treatment).
2. Add machine-checked rules.
3. Document non-machine rules.

**Test plan:**
- Lint catches deliberate violations in test fixtures.
- Review checklist on next PR.

**DoD:**
- [ ] Lint rules active.
- [ ] Review checklist in repo docs.

**Rollback:** `git revert`.

---

### Phase 21 — Legacy V1 progression cleanup (deferred)

**Goal:** Delete `lib/features/progression/`. Migrate `background_sync_service.dart` to V2 engine. Migrate devtools sections. Delete legacy tests.

**Pre-conditions:** Phases 0-20 done. Out of scope této session.

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
| **Legacy V1 contaminuje new path** | Some test inadvertently exercises V1 evaluator. | Phase 21 is deferred precisely because V1 cleanup is a separate concern. Until then, isolate V1 in its folder. |
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

- Phase 21 (V1 cleanup) — execution.
- Phase changes to persistence schema.
- New feature work — refactor je infrastructure, ne nová funkčnost.
- Performance optimization beyond what naturally falls out of read-projection caching.
- L10n cleanup (proposal §1.1 smell items 1+2 — sheets_export, bushido_export_config).

Tyto byly explicit označeny v code (TODO comments add v této session).

---

## 6. Communication patterns mezi fázemi

- **Každá fáze startuje** novou session s pre-conditions check (verify předchozí fáze landla a tests pass).
- **Každá fáze končí** updatem [docs/site/data/](../site/data/) JSONs per CLAUDE.md instrukce (nové providery, nové sealed types, nové ADRs).
- **Migration progress** se trackuje v dedicated `docs/domain_model/migration_status.md` (created v Phase 0) — checklist phases + landed PR links.
- **Po Phase 21** je tento `migration_plan.md` archivován do `docs/domain_model/archive/` per CLAUDE.md "closing out a finished plan" workflow.
