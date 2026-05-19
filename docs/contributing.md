# Forgetrack — contributing & review checklist

Working agreements for adding or changing code in this repo. Most of
the discipline below is enforced by the Phase 21 lint test suite
(`test/lint/`); the rest is review-time judgement and lives here so
nobody has to rediscover it.

Scope: this file documents the **lint matchers**, the **review
checklist**, and the **anti-pattern catalogue** that Phase 21 ratchets.
Architectural rules (layering, dependency direction, design tokens)
live in [docs/architecture.md](architecture.md).

---

## 1. Lint matchers (automated)

All four matchers live in
[test/lint/lint_matchers.dart](../test/lint/lint_matchers.dart). They
are pure-Dart grep-based functions — no custom_lint plugin, no
analyzer plugin, no codegen — so they add **zero dev dependencies +
zero build-time impact**. The rationale is in
[docs/domain_model/archive/migration_plan.md §Phase 21](domain_model/migration_plan.md).

Each matcher has a one-line predicate
(`isXxxViolation(String line) -> bool`) covered by inline fixtures in
[test/lint/lint_fixtures_test.dart](../test/lint/lint_fixtures_test.dart),
plus a directory walker that produces a sorted violation list. The
**production scan** in
[test/lint/production_scan_test.dart](../test/lint/production_scan_test.dart)
asserts each violation count against a numeric baseline — the
**ratchet**: you cannot add a new violation; you may freely remove
them (and lower the baseline in the same commit).

### Rule slugs + scope

| Rule slug          | Scope                                          | What it catches                                                                                       |
| ------------------ | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `domain-purity`    | `lib/domain/` (strict) + `lib/features/*/domain/` (ratchet) | Forbidden imports: Flutter, Firebase, Isar, SharedPreferences, HTTP, etc. — anything that breaks pure-Dart testability. |
| `untyped-id`       | `lib/domain/` + `lib/features/*/domain/`       | `String questId;` / `String achievementId;` field declarations. Should use typed VOs (`QuestId`, `AchievementId`, ...). |
| `l10n-literal`     | `lib/features/*/presentation/`                 | `Text('Hard-coded copy')`. Every visible string flows through `AppLocalizations` (gen_l10n).          |
| `widget-no-logic`  | `lib/features/*/presentation/`                 | `.where(`, `.firstWhere(`, `.singleWhere(`, `.indexWhere(` in widget code. State derivation belongs in `application/`. |

### Per-line opt-out

Append `// lint-ignore: <rule-slug>` to the offending line when the
rule genuinely does not apply. Examples:

```dart
final String rawEventKey; // lint-ignore: untyped-id — storage boundary
Text('°C') // lint-ignore: l10n-literal — unit symbol, locale-invariant
items.where((x) => x.isOdd); // lint-ignore: widget-no-logic — already memoised upstream
```

Write the **reason** after the marker so the next reviewer doesn't
have to guess.

### Lowering the baseline

When you fix a violation, the ratchet test fails with a "shrank"
message. Open
[test/lint/production_scan_test.dart](../test/lint/production_scan_test.dart),
lower the relevant `_baseline*` constant by the same amount, and
commit the constant change alongside the fix. The single-int diff is
intentional — it makes cleanup PRs visible in `git log`.

### Sealed exhaustive switch

Dart 3 auto-enforces exhaustiveness on `switch` statements + `switch`
expressions whose subject is a `sealed class`. Non-exhaustive cases
are a **compile error**, not a lint warning — there is nothing extra
to enable for sealed hierarchies.

For **enums** the analyzer needs `exhaustive_cases: true` (already
enabled in [analysis_options.yaml](../analysis_options.yaml)). Missing
cases become an analyzer warning that `flutter analyze` reports.

When you add a new variant to a sealed type or enum, `flutter
analyze` + `flutter build` will surface every switch that needs a new
arm.

---

## 2. PR review checklist

The lint matchers cover what a grep can see. The list below is for
the parts that need human judgement.

### Domain layer

- [ ] **Pure-Dart imports only** in `lib/domain/`. `lib/features/*/domain/`
  is on the ratchet — don't grow it.
- [ ] **Sealed lifecycles, not boolean flags.** New entity states get
  a sealed `XxxLifecycle` subclass + pattern-matched derivations
  (`hidesIdentity`, `showsChecklist`, etc.). Adding an `isXxx` bool
  to an entity is an anti-pattern.
- [ ] **Final fields + `const` ctor.** Mutations = whole-object
  replacement + `notifyListeners()` upstream.
- [ ] **No `toSheetRow()` / `toFirestore()` / serialization** on
  domain entities. Mappers live in `data/` adapters or feature-side
  exporters.
- [ ] **Catalog ↔ Instance separation.** A `Quest` definition
  (static, authored) is one entity; the player's relationship to
  that quest (`PlayerQuest` + lifecycle) is another. Don't conflate.

### Read projections / caches

- [ ] **Denormalised caches carry a documented rebuild path.** Every
  cache class (cosmetics inventory replay, social profile mirror,
  …) implements
  [`JournalProjection<T>`](../lib/domain/journal/journal_projection.dart)
  or links to the path that does. The
  [glossary entry](site/data/glossary.json) under `journal-projection`
  is the canonical list.
- [ ] **No O(n) journal walks in widget `build()`.** Cache the
  derivation in the provider, invalidate on the right `notifyListeners`.

### Persistence

- [ ] **No persistence schema changes** unless the PR explicitly
  scopes one. `git diff` on `*.g.dart` is expected to be empty.
  SharedPreferences keys, Isar collection names, Firestore subcollection
  shapes — all frozen by default.
- [ ] **Firestore wire format frozen** post-Phase-17. Renaming or
  re-shaping a `SocialUserProfile` / `SocialProfileSyncPayload` field
  is a wire-format break — needs explicit ADR + migration story.

### Cross-feature reach

- [ ] **No `context.read<OtherFeatureProvider>()` from a screen** if
  an aggregate facade exists. Aggregates exist so feature screens
  read through a single contract instead of importing peers'
  internals.
- [ ] **No `lib/features/progression/` (V1) imports in new code.** V1
  is delete-candidate (Phase 22). New widgets read V2 only.

### Localization

- [ ] **Strings live in `lib/l10n/app_en.arb` + `lib/l10n/app_cs.arb`.**
  After editing either, run `flutter gen-l10n`.
- [ ] **Catalog closures** — `name: (l10n) => l10n.cosmeticXxxName`. The
  catalog never embeds resolved strings; the resolver runs in
  `presentation/`.

### Logs + observability

- [ ] **`AppLog` from `lib/core/logging/app_log.dart`**, never
  `print()`. Use the right domain + scope (`AppLog.sync.warn`,
  `AppLog.social.debug`, ...).

### Docs & site

- [ ] **CLAUDE.md "Adding a new feature" triggers** ticked off — any
  new provider / Isar collection / Firestore subcollection / sealed
  type / data flow / ADR has its `docs/site/data/*.json` update in
  the same PR (per
  [migration plan §7.4](domain_model/migration_plan.md)).
- [ ] **READMEs in `lib/features/<feature>/`** describe **current
  state only**. Plans, phase status, work logs belong under `docs/`.

---

## 3. Anti-pattern catalogue (proposal §7)

These are the rules the lint matchers + checklist exist to enforce.
Full discussion in
[docs/domain_model/proposal.md §7](domain_model/proposal.md).

1. State derived inline in widget `build()`.
2. Cross-feature provider reaching (skip the aggregate facade).
3. String id conventions enforced only by comments / naming.
4. Denormalised cloud snapshots treated as parallel sources of truth.
5. One catalog entity spread across multiple files.
6. "Lifecycle as flags" (`isClaimable`, `isHidden`, `isPartial`).
7. Mutating side-state during widget `build()`.
8. O(n) journal walks called from `build()`.
9. Direct widget access to legacy `progression/` V1 models.
10. `toSheetRow()` / serialization on domain entities.
11. Multiple lifecycles for the same entity (`CompanionState` +
    `CosmeticRevealState`).
12. Mutable aggregate fields.

The lint matchers cover rules 1, 3, 8 (widget-no-logic + l10n-literal
+ untyped-id + domain-purity). Rules 4, 5, 6, 11, 12 are review-only
and live in §2 above.

---

## 4. Verification before merging

From the project root:

```sh
flutter analyze              # must be clean (pre-existing unnecessary_const infos in catalog content/*.dart are accepted)
flutter test                 # full suite, including test/lint/
flutter gen-l10n             # only if ARB files changed
```

When you touched UI: actually drive the screen in a debug build (the
PR description's test plan section is where you record what you
poked).

### Integration tests

`test/integration/` holds repository-level integration tests that
exercise the hybrid local + cloud paths against a `fake_cloud_firestore`
backing plus the in-memory progression engine repository. They run as
part of the regular `flutter test` invocation — no Node.js, no Firebase
CLI, no emulator process required.

```sh
flutter test test/integration/       # run only the integration suite
```

Adding a new integration test:

- prefer `FakeFirebaseFirestore` over wiring a real Firebase Emulator —
  it covers the same wire codec without the CI tax;
- use `InMemoryProgressionEngineRepository` for the local backing rather
  than spinning up an Isar instance — the local repo's contract is
  identical (eventKey dedupe, append-only), so an Isar-specific bug is
  out of scope for these tests.

The ADR `r5c-emulator-integration-tests` documents the choice; revisit
it if a wire-format regression slips past `fake_cloud_firestore` and a
real emulator becomes the only way to catch it.
