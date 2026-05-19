# Domain Model Refactor — Session Handoff

**Created:** 2026-05-17
**Status:** Kickoff brief for next session. **No code in this session — only analysis + design.**

---

## 1. Why this session exists

The user has spent multiple sessions chasing companion-flow bugs (claim doesn't unlock, identity leaks before claim, devtools matrix lands at wrong state, hint copy mismatches, etc.). Each fix peeled back another layer of the same root cause:

> "Mám pocit, že mi chybí úplně ta nejzákladnější věc, a to je doménový model. Stylem, jakým jsem appku vytvářel, jsem úplně opomněl modely, nabaloval jsem jednu feature za druhou podle feature first architektury, ale úplně mi chybí základní modely, nebo jsou různě roztroušený, nebo poskládány z různých částí, nebo se vytvářejí za běhu jako zde companion."

The bugs are symptoms. **The disease is a missing aggregate / read-model layer.** Truth lives in 3+ stores per entity; views are derived inline in widget `build()`; "models" emerge from runtime composition (e.g. `CompanionsRegistry` factory I built in the last session is still a *view object*, not a domain aggregate).

Previous session ended with a partial Companion refactor (`CompanionState`, `CompanionsRegistry`, sealed lifecycle hints) — leave that **as a sketch, not a foundation**. The next session should design the whole-app domain model from scratch and then evaluate which parts of the partial work survive.

---

## 2. User's intent — verbatim

> "Potřeboval bych navrhnout doménový model celé aplikace. Nejdřív jen návrh, myslím, že by měl existovat nějaká globální entita kontext, od které by se pak odvíjelo vše ostatní. User → Player nebo Profile → Social profile, atd... nebát se extendovat entity, optimalizovat celý model tak, aby se dal využít v katalogu, například quest, ale zároveň pak User nebo Player měl své instance v nějaké historii, stejně tak achievements, items, goals, xp, rewards... pečlivě projít stávající projekt, extrahovat entity, správně je propojit a stavět dále na tom."

Decomposed:

1. **Whole-app scope.** Not just cosmetics. Touch: auth, progression, social, achievements, quests, items, goals, XP, rewards, history.
2. **Global aggregate root** (suggested: `Context` or similar). All entities branch from it: `Context → User → Player → SocialProfile → Inventory → ...`
3. **Catalog ↔ Instance separation.** A `Quest` definition (static, authored) is one entity; the *player's* relationship to that quest (state, progress, history) is another. They must coexist cleanly.
4. **Inheritance is allowed.** "Nebát se extendovat entity." Java DDD style — sealed/abstract base + concrete subclasses.
5. **Reuse across feature boundaries.** A `Quest` model used by both the catalog system and the player history.
6. **Walk the existing project carefully** before designing. Extract — don't invent.

> "Jakožto Java developer, který dělá max javu 17, nejsem dobře obeznámen se všemi funkcemi a know how o dartu a o tom, jak se navrhuje doménový model pro mobilní aplikaci, umím to jen v javě."

He thinks in Java aggregates / records / sealed classes / repository pattern. Dart 3 has analogues (sealed, pattern matching, immutable const, freezed) but idioms differ — esp. around Flutter's `ChangeNotifier` / `Provider`, code generation choices, and persistence frameworks (Isar uses code-gen + collections; Firestore is schemaless). The next session must **bridge Java DDD instincts to Flutter/Dart idioms** without forcing a Java-shaped solution.

---

## 3. Scope of next session

### MUST produce

1. **Domain glossary.** Every "thing" in the app named, defined, classified as Entity / Value Object / Aggregate Root / Catalog Definition / Read Model.
2. **Current fragmentation map.** For each domain concept: where is the catalog, where is the state, where is the history, where is the view-model derived.
3. **Proposed domain model.** ER-style + class hierarchy. Aggregate roots, ownership, references vs containment.
4. **Catalog ↔ Instance pattern.** How `Quest` (static definition) relates to `PlayerQuest` (instance with player progress/history) — name TBD. Same for Achievement, Item, Companion, Goal.
5. **Dart-specific guidance.** Where to use sealed classes vs abstract, when freezed earns its keep, ChangeNotifier composition patterns, pattern-matched exhaustive switches.
6. **Open questions list.** Things the user must decide before implementation starts.

### MUST NOT produce

- ❌ Any production code.
- ❌ Phased migration plan with file-level edits.
- ❌ Catalog of bugs to fix.
- ❌ Companion-only solution (out of scope).
- ❌ **Configuration layer.** See "Out of scope — configuration" below.

### Out of scope — configuration

Player preferences, feature flags, tunables, build-time settings, and environment configuration are **not** part of this proposal. They land in a separate **config model refactor** track ([docs/config_model/](../config_model/) — placeholder created, design session deferred until this domain proposal is accepted).

If a question arises whether a piece of state belongs to the domain model or to config, use this heuristic:

| Belongs to domain | Belongs to config |
|---|---|
| Has history (events / timeline) | Snapshot of "current value" |
| Per-instance (one per player, per item, per quest) | Singleton-ish (one per user / one per app build) |
| Derivable from ledger / event-sourced | Stored as flat key/value (SharedPreferences, secure storage, env) |
| Mutates through use-case operations | Mutates through Settings UI / build flags / remote config |
| Examples: `Player.level`, `Inventory.unlockedItems`, `Quest.progress` | Examples: `rpgModeEnabled` flag, sync interval, locale, KT credentials, `kBackfillClaimLookbackDays` |

Borderline cases (e.g. RPG mode) explicitly belong to config and **must not** sneak into a `Player` or other aggregate. The aggregate may *react* to config (read a flag, branch behaviour) but does not *own* it.

### Output artifact

Single markdown file: `docs/domain_model/proposal.md`. Diagrams in mermaid where useful (the project already uses mermaid in `docs/site/data/glossary.json`).

---

## 4. Pre-reading (next session must read before designing)

### Authoritative architecture docs
- [docs/architecture.md](../architecture.md) — layering rules, dependency direction, design tokens.
- [docs/site/data/glossary.json](../site/data/glossary.json) — every sealed hierarchy currently documented (LedgerEvent, ProgressionNode, RewardDefinition, UnlockCondition, ObjectiveMetric, CosmeticEnums, BackfillModels).
- [docs/site/data/providers.json](../site/data/providers.json) — DI graph.
- [docs/site/data/storage.json](../site/data/storage.json) — every persistence bucket (Isar collections, Firestore subcollections, SharedPreferences keys, secure storage).
- [docs/site/data/dataflows.json](../site/data/dataflows.json) — write/read cycles per feature.
- [docs/site/data/features.json](../site/data/features.json) — feature inventory.
- [docs/progression_engine/v2_phased_plan.md](../progression_engine/v2_phased_plan.md) — full progression engine spec.

### Code surfaces to inventory

Per feature, read `lib/features/<feature>/domain/` first (the "models" that already exist), then `application/` (providers/services), then `data/` (repositories), then `presentation/` only if needed.

Features (mapped to candidate domain entities):

| Feature folder | Candidate entity types |
|---|---|
| `auth/` | User (identity, login state) |
| `progression_engine/` | Player (level, XP), Quest, Achievement, Milestone, Chapter, Companion ref, Relic ref, Reward, Objective, LedgerEvent, **UnlockCondition** |
| `progression/` (V1) | legacy — check if any models survive vs are dead code |
| `cosmetics/` | Item (sealed: Frame, Background, Companion, Relic, Emblem, TitleFlair, MapEffect), Inventory, EquippedSlot |
| `social/` | SocialProfile, SocialFriend, SocialUserStats |
| `health_connect/` | Activity (workout record), Steps, BodyMeasurement, Sleep |
| `nutrition/` | MealEntry, Macronutrient, KTCredentials, KTCatalogItem |
| `celebration/` | CelebrationEvent (view-only, derived from progression result — likely **NOT** a domain entity, but verify) |
| `journey/` | possibly redundant with chapters — verify |
| `coach_log_export/`, `sheets_export/` | export view models — likely NOT domain |
| `home/`, `app_shell/`, `onboarding/`, `settings/`, `devtools/` | UI shells — NOT domain |

### Existing sealed hierarchies (already good DDD-style models, harvest!)

- `LedgerEvent` — 6 subtypes, immutable, event-sourced.
- `ProgressionNode` — 14+ subtypes, sealed at top, then Quest sub-sealed.
- `QuestNode` — 10 subtypes (Daily, Weekly, Chapter*, Combo*, LongTerm, ...).
- `RewardDefinition` — 8 subtypes.
- `UnlockCondition` — 11 subtypes including composite `AllOf`/`AnyOf`.
- `CosmeticType` — 7 enum values.
- `ClaimPolicy`, `ActivationPolicy`, `CelebrationPolicy` — narrow enums.

The codebase has **strong sealed hierarchies already.** The gap is the **aggregate root layer above them** + the **instance/history layer beside them**.

### Existing persistence (write-side, stays untouched)

- **Isar databases (4 separate):** `health`, `nutrition`, `progression_engine` ledger, `cosmetics` (denormalized unlock + equipped).
- **Firestore (12 subcollections per user uid):** mirrors ledger + cosmetic unlocks + social profile + activity backfills.
- **SharedPreferences (11 keys):** preferences, last sync timestamps, joinedAt, RPG flag, locale.
- **flutter_secure_storage (2 keys):** KT credentials.

The proposal must NOT change persistence semantics — only add a read-side aggregate layer over the existing event-sourced write side.

---

## 5. Current fragmentation map (prep work done — don't re-derive)

For each candidate entity, the existing truth surfaces (catalog | runtime | history):

### User
- **Catalog:** n/a (1 user).
- **Runtime:** `AuthUser` ([lib/features/auth/application/auth_user.dart](../../lib/features/auth/application/auth_user.dart)) — id, email, displayName, photoUrl.
- **History:** n/a directly. Login timestamps in Firestore profile.

### Player
- **Catalog:** n/a (1 per user).
- **Runtime:** derived. `level` + `totalXp` come from `ProgressionEngineProvider.profile` (recomputed from ledger every eval). `joinedAt` from SharedPreferences.
- **History:** entire `_ledger` is player's history. No aggregate view.

### SocialProfile
- **Catalog:** n/a.
- **Runtime:** Firestore denormalized snapshot (`SocialUserProfile` in `social_models.dart`). Drift risk vs ledger.
- **History:** none directly; activity feed is per-event.

### Quest
- **Catalog:** sealed `QuestNode` subtypes in `progression_engine/domain/catalog/content/*.dart`.
- **Runtime:** state derived per-eval from ledger (NodeState resolver). No persisted "PlayerQuest" entity.
- **History:** `NodeCompletionEvent`, `NodeClaimEvent`, `QuestOfferedEvent`, `ObjectiveCompletionEvent` in ledger.

### Achievement
- **Catalog:** `Achievement` (sub of `ProgressionNode`).
- **Runtime:** derived. "Unlocked when?" from ledger NodeCompletionEvent. `SocialUnlockedAchievement` in Firestore mirrors it (denormalized).
- **History:** ledger.

### Goal / Objective
- **Catalog:** sealed `ObjectiveMetric` + `Objective` definitions in `progression_engine/domain/catalog/objective_catalog.dart`.
- **Runtime:** evaluated each tick via `ObjectiveEvaluator`. No persisted state per-objective.
- **History:** `ObjectiveCompletionEvent` per period.

### Item (Cosmetic)
- **Catalog:** `Cosmetic` in `cosmetic_catalog.dart` (single class for all 7 types — Frame, Relic, Background, Emblem, Companion, TitleFlair, MapEffect).
- **Runtime:** `UnlockedCosmetic` + `EquippedCosmetics` in cosmetics Isar.
- **History:** unlock timestamp + sourceType/sourceId on `UnlockedCosmetic`. Granular reward grants in ledger.

### Companion (currently the most fragmented)
- **Catalog:** **3 places** — `Cosmetic`, `CompanionAvailability`, `CosmeticUnlockRule` (Tier-2).
- **Runtime:** **3 stores** — `cosmetics.unlocked`, `progression.availableNodeIds`, reveal evaluator.
- **History:** `NodeClaimEvent`, `RewardGrantEvent(companionAvailability)` in ledger.

### Relic
- **Catalog:** `Cosmetic` + `Relic` (older path, may be partially dead — verify) + relics granted as `CosmeticReward` from achievement nodes.
- **Runtime:** `UnlockedCosmetic` in cosmetics Isar.
- **History:** ledger reward grants.

### Reward
- **Catalog:** `RewardDefinition` (sealed, 8 subtypes).
- **Runtime:** n/a (definitions are emitted by nodes).
- **History:** `RewardGrantEvent` in ledger.

### Chapter
- **Catalog:** sealed chapter content in `progression_engine/domain/catalog/content/chapter_*.dart`.
- **Runtime:** `ChapterCompletion` state derived from ledger.
- **History:** ledger + `ChapterUnlockReward` events.

### Activity (workout)
- **Catalog:** activity *types* live in `progression_engine/domain/catalog/content/activity_content.dart` (workout quests). The underlying record types come from Health Connect (`ActivityRecord` model).
- **Runtime:** `ActivityRecord` from HC + claim state from ledger.
- **History:** HC stores activities; ledger stores claim events.

### Inventory
- **Doesn't exist as an entity.** Always derived as `catalog.enabled ∩ state.unlocked`. Cosmetics screen builds the view inline.

---

## 6. Flutter / Dart idioms — and why they differ from Java

**Goal: design a clean Flutter/Dart app following Flutter best practices.** The user is a Java 17 developer, so explaining *why* Flutter departs from Java conventions is helpful, but the proposal must not produce a Java-shaped app with a Dart syntax veneer. The patterns below are what idiomatic Flutter looks like and **why** that idiom won — not a translation table.

### 6.1 No DI container — explicit composition via `provider`

**Java:** `@Autowired`, `@Component`, `@Service`. Container scans annotations at startup and injects dependencies by reflection.

**Flutter:** the [`provider`](https://pub.dev/packages/provider) package (or `riverpod`, `get_it` — all variants) composes objects **explicitly** at the top of the widget tree:

```dart
MultiProvider(
  providers: [
    Provider(create: (_) => CosmeticsRepository(...)),
    ChangeNotifierProvider(create: (ctx) => CosmeticsProvider(ctx.read())),
    ChangeNotifierProxyProvider2<A, B, C>(...),
  ],
  child: const MyApp(),
)
```

**Why it's better here:**
- Dart has **no runtime reflection** (it's compiled AOT for release). A Spring-style container would require code generation — added complexity for a benefit Java needs only because of legacy bean conventions.
- Wiring is searchable: `grep` finds every consumer of a provider. No magic "where did this dependency come from".
- The provider tree mirrors widget scope. A provider above a `Navigator` route is gone when the route pops — automatic lifecycle management without `@Scope` annotations.
- Hot reload works because the graph is plain Dart code, not container metadata.

### 6.2 No streams unless they're genuinely async — `ChangeNotifier` is the default

**Java:** Reactive stacks (Project Reactor, RxJava) push streams everywhere because the JVM thread model needs explicit backpressure / scheduling.

**Flutter:** UI runs on a single event loop. State changes call `notifyListeners()` on a `ChangeNotifier`; listening widgets rebuild on the next frame. No backpressure problem to solve, no schedulers.

```dart
class PlayerProvider extends ChangeNotifier {
  Player _player;
  Player get player => _player;

  Future<void> levelUp() async {
    _player = await _repo.applyLevelUp(_player);
    notifyListeners();        // widgets rebuild
  }
}

// In UI:
final player = context.watch<PlayerProvider>().player;
```

**Why it's better here:**
- Flutter's widget rebuild is the reactive mechanism. Re-implementing it with `Stream<T>` is double-bookkeeping.
- Pure `ChangeNotifier` has no `subscription` / `dispose` ceremony — provider owns the lifecycle.
- Use `Stream<T>` only when the data **genuinely** arrives async over time (Firestore live query, sensor events). Don't wrap synchronous state in a stream "because reactive".

The codebase already follows this: every `Provider` is a `ChangeNotifier`. Continue.

### 6.3 Immutability via `const` constructors — not via Lombok / records / freezed

**Java:** `@Value`, `@Data`, records (Java 14+) — boilerplate-reduction macros.

**Dart:** the language ships with `const` constructors. A class with `final` fields and a `const` constructor is automatically:
- Heap-deduplicated by the compiler (same const instance = same object).
- Comparable as a literal (`MyClass(1, 2) == MyClass(1, 2)` works **if** `==`/`hashCode` are overridden).
- Usable in `const` contexts (compile-time constants).

```dart
@immutable
final class CompanionState {
  const CompanionState({required this.id, required this.lifecycle});

  final String id;
  final CompanionLifecycle lifecycle;

  @override
  bool operator ==(Object other) =>
      other is CompanionState && other.id == id && other.lifecycle == lifecycle;

  @override
  int get hashCode => Object.hash(id, lifecycle);
}
```

**The boilerplate question.** `freezed` (codegen) eliminates `==`/`hashCode`/`copyWith`. Trade-offs:

| | Hand-written (current) | `freezed` |
|---|---|---|
| Boilerplate per class | ~15 lines | ~3 lines |
| Build step | none | `build_runner` (~2-10s incremental) |
| IDE navigation | direct | through generated file |
| Pattern matching on sealed unions | supported by Dart 3 directly | freezed adds `.when` / `.map` helpers |
| Learning curve | zero | non-trivial |

**The codebase is hand-written everywhere.** Don't introduce `freezed` without a real lever — most domain types only need const + `==`. Reach for it only if the proposal lands a union-heavy aggregate that benefits from `.when` and authoring 30+ types feels like a tax.

### 6.4 Sealed classes + pattern matching is the union type

**Java:** `sealed interface` + `permits` + exhaustive `switch` (Java 21).

**Dart 3:** identical mechanic, slightly nicer syntax:

```dart
sealed class CompanionLifecycle {
  const CompanionLifecycle();
}
final class Hidden extends CompanionLifecycle { const Hidden(); }
final class Partial extends CompanionLifecycle {
  const Partial({required this.satisfied, required this.total});
  final int satisfied;
  final int total;
}
final class Claimable extends CompanionLifecycle { const Claimable(); }
final class Claimed extends CompanionLifecycle {
  const Claimed({required this.claimedAt});
  final DateTime claimedAt;
}

// Exhaustive — compiler errors if a case is missing:
String label(CompanionLifecycle l) => switch (l) {
  Hidden() => 'Hidden',
  Partial(:final satisfied, :final total) => '$satisfied/$total',
  Claimable() => 'Ready to claim',
  Claimed(:final claimedAt) => 'Unlocked ${claimedAt.toLocal()}',
};
```

**Why it matters for this refactor:** the bugs the user has been hitting (state flags fighting each other: `isClaimable && !isHidden && isPartial`) literally cannot compile under sealed lifecycles. The compiler refuses incomplete switches. **Use this everywhere a state has more than two states.** Enums are fine only when states carry no data.

### 6.5 Async returns futures — getters stay synchronous

**Java:** `CompletableFuture<T>`, `Mono<T>`, blocking methods, virtual threads (Java 21) — many flavours.

**Dart:** one mechanism. Async work returns `Future<T>` (`async` / `await` like Java's `CompletableFuture` but with linguistic support that reads imperative).

```dart
Future<void> claim() async {
  final result = await _engine.claim(node.id);
  if (result.isSuccess) notifyListeners();
}
```

A `get foo => …` getter must be **synchronous and cheap**. If you need to wait, expose a method (`Future<Foo> loadFoo()`) — the type forces the caller to await.

### 6.6 Repositories: hand-written interfaces, no JPA

**Java:** `interface PlayerRepository extends JpaRepository<Player, String>` — query derivation from method names.

**Dart:** the codebase already follows the right pattern. Define an abstract interface in `data/`, implement with the actual store (Isar, Firestore, in-memory for tests):

```dart
abstract class PlayerRepository {
  Future<Player> load(String uid);
  Future<void> save(Player player);
}

class IsarPlayerRepository implements PlayerRepository { ... }
class FirestorePlayerRepository implements PlayerRepository { ... }
class InMemoryPlayerRepository implements PlayerRepository { ... }  // tests
```

**Why this is enough:** no ORM means no impedance mismatch. The repository is the only place that knows about Isar's `Id` field, Firestore's `DocumentSnapshot`, etc. The domain model stays pure Dart. Existing `lib/features/*/data/` follows this — keep going.

### 6.7 Null safety replaces `Optional<T>`

**Java:** `Optional<T>` is a wrapper that callers must unpack. Java doesn't track nullability in the type system (older code returns nulls anyway).

**Dart:** `T?` is the type. The compiler refuses `value.foo` until you handle null:

```dart
String? nickname;
print(nickname.length);        // compile error
print(nickname?.length);       // ok, evaluates to int?
print(nickname!.length);       // ok, throws if null at runtime
if (nickname != null) print(nickname.length);  // promoted to non-null
```

Don't import or model `Optional` types. The language has the feature.

### 6.8 Cross-aggregate composition — `ChangeNotifierProxyProvider`

When `Player` depends on `Progression` + `Cosmetics` + `Auth`, this is where Flutter shines:

```dart
ChangeNotifierProxyProvider3<AuthProvider, ProgressionEngineProvider,
    CosmeticsProvider, PlayerProvider>(
  create: (_) => PlayerProvider(),
  update: (_, auth, prog, cosm, player) => player!..bind(auth, prog, cosm),
)
```

The `update` callback fires whenever any upstream provider notifies. `PlayerProvider` then exposes a single aggregated view to the UI. **This is the Flutter answer to the "global Context" question** in Section 8 — you don't build a `Context` aggregate, you compose providers at the app root and the framework handles propagation.

### 6.9 Patterns to follow — and why

1. **Aggregates are plain classes.** No marker interface, no annotation. The aggregate is the thing the UI reads from and writes through. Convention, not framework.
2. **State changes go through the aggregate's methods, never reach past it.** `companion.claim()` is fine; the UI calling `progression.claimNode(id)` is not.
3. **Read-side projections are derived in providers, not widgets.** Widgets call `context.watch<XxxProvider>().something` — never compute it themselves.
4. **One catalog file per entity kind.** `lib/domain/items/catalog/companions.dart`. The proposal must reject the current pattern where Companion lives in 3 files.
5. **Immutability via `final` fields + `const` constructors.** Always. Mutation happens by replacing the whole object.
6. **Don't fight the framework.** If something feels harder than Java, the test isn't "how would Java do this" — it's "what does idiomatic Flutter call for". When in doubt, look at how `flutter_bloc`, `riverpod`, or the official samples solve it.

### 6.10 Anti-patterns common when porting from Java

These the next session should explicitly warn against:

- **Reaching for codegen first.** Java muscle memory says "annotate everything". Resist until a real pain point appears.
- **Streamifying synchronous state.** A `Stream<Player>` for state that only changes when the user taps a button is over-engineering.
- **Building DI containers / service locators.** `get_it` exists but is rarely the right answer in Flutter. Stick with `provider` unless you have a clear reason.
- **Mapping domain ↔ persistence via DTOs.** Flutter projects often skip the DTO layer and let the repository convert directly. Add DTOs only if the persistence format actively diverges from the domain.
- **`@Override` everywhere.** Dart has `@override` annotation — it's a hint, not a contract. Use it for clarity but don't burn time enforcing it.
- **Building lifecycle frameworks.** No `@PostConstruct`. Init runs in the constructor (sync) or in `Provider.create` (lazy). Don't model what's already there.

---

## 7. Anti-patterns the proposal must explicitly forbid

These are habits the codebase has accumulated. Call them out so future contributions can't sneak them back in.

1. **State derived inline in widget `build()`.** Every aggregate's state must be observable via provider; widget reads, doesn't compute.
2. **Cross-feature provider reaching** (e.g. cosmetics screen reading `ProgressionEngineProvider` directly to compute companion state). Aggregate facade hides cross-feature dependencies.
3. **String id conventions enforced only by comments** (e.g. "id == companionId == cosmeticId"). Use a single typed identifier or model the relationship explicitly.
4. **Denormalized cloud snapshots that drift from ledger** (e.g. `SocialUserProfile` mirroring level/XP). Treat them as caches with a documented rebuild path, not as a parallel source of truth.
5. **Catalog spread across multiple files for one entity** (Companion = 3 files). One authoring location per entity type.
6. **"Lifecycle as flags"** (`isClaimable`, `isHidden`, `isPartial` as booleans). Use **sealed state classes** so the compiler forces exhaustive handling.
7. **Mutating side-state during widget build** (no `notifyListeners` in build). Future-thunked operations only.

---

## 8. Open questions for the design session

Resolve early — drive the proposal.

1. **Where do shared domain types live?**
   - Option A: `lib/domain/<entity>/` (new top-level, feature-agnostic).
   - Option B: keep `lib/features/<feature>/domain/` per feature.
   - Option C: hybrid — cross-feature aggregates in `lib/domain/`, feature-specific in feature folder.
   - Current convention favours feature-first ([CLAUDE.md](../../CLAUDE.md)). Argue for or against.

2. **Should `Context` (global aggregate) actually exist as code?**
   - Java has `ApplicationContext`. Flutter has `BuildContext` (UI) and the provider graph. Is a `Context` aggregate a useful root, or does it just duplicate the provider graph?
   - Suggest: `Player` as the root, since the app is single-player; `Context` is implicit (= the bound `Player`).

3. **Catalog vs Instance — naming convention.**
   - Java DDD: `QuestDefinition` + `Quest` (instance), or `QuestTemplate` + `PlayerQuest`, or `QuestSpec` + `QuestRecord`. Pick one and apply consistently.

4. **Code-gen tooling.**
   - `freezed` for unions/equality/copyWith?
   - `built_value` (older, similar)?
   - Hand-written (current style)?
   - Trade-off: build time + complexity vs boilerplate reduction.

5. **Repository abstraction depth.**
   - Each aggregate gets its own repository interface (`PlayerRepository`, `InventoryRepository`)?
   - Or providers query existing feature repositories directly?

6. **History modelling.**
   - `Player.completedQuests` — eager list, lazy stream, or paged?
   - History storage stays in the ledger; aggregate exposes a typed view.

7. **What about `RPG mode off`?**
   - The app has an RPG-disabled mode (`RpgModeEnabled` unlock condition). Should domain entities know about it, or should it be a view-layer filter? Probably view-layer, but confirm.

8. **Localization in domain.**
   - Currently catalog entries carry `titleKey: (l10n) => l10n.questFooName` closures. Is that domain concern or presentation concern? Argue.

---

## 9. Suggested working method for next session

1. **First 30%:** read the pre-reading list. No design yet.
2. **Next 20%:** enumerate every entity from code. Update Section 5's map if it's stale.
3. **Next 30%:** sketch the aggregate graph. Start from `Player`. Branch out. Use mermaid for diagrams.
4. **Last 20%:** Java→Dart idiom mapping, open questions, write proposal markdown.

**Stop and ask the user before:**
- Introducing a new top-level folder (`lib/domain/`).
- Recommending `freezed` or any new package.
- Recommending changes to existing persistence schemas.

---

## 10. What survives from previous sessions (so far)

These artifacts exist in the codebase from incremental fixes. The next session can keep or discard them as the new model dictates — **don't treat them as untouchable**:

- `lib/features/cosmetics/domain/companion_state.dart` — `CompanionState` enum + resolver.
- `lib/features/cosmetics/application/companions_registry.dart` — `Companion` value object + factory.
- `lib/features/cosmetics/domain/consumed_relics.dart` — derives consumed relic ids.
- `lib/features/cosmetics/presentation/widgets/companion_claim_reveal.dart` — claim animation (presentation only).
- `lib/features/devtools/application/companion_dev_controller.dart` — devtools matrix.
- `lib/features/progression_engine/application/cosmetic_unlock_bridge.dart` — engine→cosmetics bridge (after my fix that handles companion availability).

The bridge fix and the claim animation are **decoupled enough** to survive. The Companion/CompanionsRegistry sketch is **expected to be redesigned** — it's a view object today; the proposal will likely promote it to an aggregate.

---

## 11. Definition of done for next session

The session output (`docs/domain_model/proposal.md`) is "done" when:

- [ ] Every feature in [lib/features/](../../lib/features/) has been classified (domain-relevant vs UI-shell vs export).
- [ ] Every persisted entity has a catalog/instance/history triple documented.
- [ ] The proposed aggregate graph fits on one mermaid diagram a developer can read in under 2 minutes.
- [ ] Each Java→Dart idiom used in the proposal has a sentence-long mapping for the user.
- [ ] All open questions from Section 8 have a recommended answer (the user can override).
- [ ] No production code has been written.
- [ ] The proposal explicitly identifies which existing code stays, which gets refactored, which gets deleted.

---

## 12. After the proposal lands

Next-next session (not this one): **convert proposal into a phased migration plan** — at that point, one entity at a time, with concrete file-level edits. This handoff is upstream of that.
