# Companion Catalog — Source-of-Truth Consolidation Handoff

**Created:** 2026-05-21
**Shipped:** 2026-05-21
**Status:** Archived — permanent design record. Plan executed per §4 Option C (recommended) + §4 Option D (validator-only safety net). Sealed `CompanionSpec` (with `ProgressionCompanionSpec` + `DevOnlyCompanionSpec` subtypes for the Monster Energy carve-out) lives in `lib/domain/cosmetics/companion_spec.dart`; the three feature-side files now derive from `kCompanionSpecs`. Consistency validator in `test/features/cosmetics/companion_consistency_test.dart`. See ADR `companion-spec-canonical` for context + alternatives.
**Triggering commit:** `6cac3d4` (achievements: rarity + granter rebalance, dual-source-of-truth fixes)

---

## 1. Why this session exists

The user does not want duplicate definitions of companion data:

> "Druhý paralelní zdroj pravdy? Chci pouze 1 zdroj pravdy. Stejně tak místa, kde se definuje rarity společníka."

Two recent bugs surfaced because there are currently three files that each own a slice of the same companion shape:

1. **Swap not visible bug.** After swapping `relic_polar_lantern` ↔ `relic_frozen_lake_heart` in `companions_content.dart` (engine progression nodes), the companion detail screen still showed the old pre-swap relics, because the screen actually reads `cosmetic_unlock_rules.dart` (cosmetics service) and that file was missed in the swap.
2. **Companion rarity mismatch bug.** `companion_lantern_golem` displayed as `rare` in the inventory (from `cosmetic_catalog.dart`) but was carried as `epic` in the progression engine node (`companions_content.dart`). The user spotted this because both of `lantern_golem`'s relics are epic and the pair "didn't make sense" against a rare companion. Same drift existed for `ember_sprite`, `forest_fox`, and `ruin_raven`.

Both were fixed in commit `6cac3d4` by editing every file. The fixes are correct but fragile — the next companion-shape edit can break the invariant again because nothing in the codebase enforces consistency.

---

## 2. The three sources of truth — current state

For each of the 10 companions, the same data lives in three places:

### A. `lib/features/cosmetics/domain/cosmetic_catalog.dart`

**Owns:** Companion as a cosmetic — `rarity`, `region`, `name`, `description`, `assetKey`, `buff`, `metadata`. UI inventory + reveal-state evaluator read from here.

```dart
Companion(
  id: const CosmeticId('companion_aurora_stag'),
  rarity: Rarity.epic,
  region: CosmeticRegion.frostlands,
  // ... name, asset, sortOrder, buff: FlatCompanionBuff(...)
)
```

### B. `lib/features/progression_engine/domain/catalog/content/companions_content.dart`

**Owns:** `CompanionAvailability` progression nodes. Engine's evaluation pipeline uses these to fire `NodeCompletionEvent` when level + relics are owned. Has its own `rarity` field (for journal display / engine surfaces). Carries `rewards` + `unlockConditions` + `lockedHintKey`.

```dart
CompanionAvailability(
  id: const ProgressionEntryId('companion_aurora_stag'),
  companionId: CosmeticId('companion_aurora_stag'),
  rewards: const [
    CompanionAvailabilityReward(companionId: CosmeticId('companion_aurora_stag')),
  ],
  unlockConditions: const [
    LevelAtLeast(65),
    OwnsCosmetic(CosmeticId('relic_polar_lantern')),
    OwnsCosmetic(CosmeticId('relic_aurora_thread')),
  ],
  rarity: Rarity.epic,
)
```

### C. `lib/features/cosmetics/domain/cosmetic_unlock_rules.dart`

**Owns:** `CosmeticUnlockRule` entries in `kCosmeticUnlockRules`. The cosmetics service walks these to decide when to grant a companion to the inventory (after relics + level land). Also consumed by `cosmetic_reveal_evaluator` for "this is X / Y conditions satisfied" UI text on the companion detail screen.

```dart
CosmeticUnlockRule(
  cosmeticId: CosmeticId('companion_aurora_stag'),
  sourceType: 'compound',
  sourceId: 'compound_polarni_jelen',
  conditions: [
    Cond.atLevel(65),
    Cond.ownsCosmetic('relic_polar_lantern'),
    Cond.ownsCosmetic('relic_aurora_thread'),
  ],
  isHidden: true,
)
```

### Shared shape, in plain language

Every companion has exactly:
- An ID (string)
- A level gate (integer)
- Two relic IDs that gate unlock
- A rarity tier
- A display bundle (name, region, asset, sortOrder, description, locked hint)
- A buff (or null)
- An optional metadata blob (e.g. `devOnly: true`)

Today this shape is split across A/B/C. Every new companion (or every relic swap, rarity tweak, level adjustment) must touch all three to stay consistent. There is no validator and no shared origin — drift is invisible until a user spots it in the UI.

---

## 3. Why does each consumer exist?

Before consolidating, understand who needs what — to avoid breaking a consumer by removing data they actually use.

| Consumer | Reads from | What it needs | Notes |
|---|---|---|---|
| Cosmetics inventory screen | A (`cosmetic_catalog`) | name, rarity, region, asset, sortOrder, buff | Display of equipped + owned cosmetics |
| Cosmetic reveal evaluator | C (`kCosmeticUnlockRules`) | conditions (level + relics) + `sourceType` / `sourceId` | Computes "this companion is X / Y conditions met" for partial reveal |
| Cosmetics service grant pipeline | C (`kCosmeticUnlockRules`) | conditions, target id | Walks rules to dispatch unlocks |
| Companion detail screen | C (`kCosmeticUnlockRules`) | conditions list (rendered as "needs X + Y") | This is what surfaced the swap bug |
| Progression engine evaluator | B (`companions_content`) | `CompanionAvailability` nodes (objectiveId is null; unlockConditions drive completion) | Fires `NodeCompletionEvent` + `CompanionAvailabilityReward` |
| Granting-achievement lookup test | B + A | walks `CosmeticReward` references across all progression content | Asserts every relic has a granter |
| Journal projection / celebration | B | nodeId, rarity, badgeEmoji, contentTags | Achievement-like surfacing of companion availability |

**Key observation:** B and C carry essentially identical data — level + 2 relic conditions, keyed by companion id. A carries everything *display-related* and the rarity. There is no shape that lives in C and not in B; the inverse is also true once you ignore the engine-specific metadata (badgeEmoji, contentTags, lockedHintKey).

---

## 4. Proposed approach (sketch — confirm direction before implementing)

### Option C (recommended): Extract a shared companion spec

New file (e.g. `lib/features/cosmetics/domain/companion_spec.dart`) that holds, per companion id, a const-constructed spec:

```dart
const kCompanionSpecs = <CompanionSpec>[
  CompanionSpec(
    id: 'companion_aurora_stag',
    levelGate: 65,
    relicA: 'relic_polar_lantern',
    relicB: 'relic_aurora_thread',
    rarity: Rarity.epic,
    region: CosmeticRegion.frostlands,
    sourceId: 'compound_polarni_jelen',
  ),
  // ...
];
```

Then:
- `cosmetic_catalog.dart` derives `Companion(...)` rows from `kCompanionSpecs` (preserving `name`, `assetKey`, `buff`, `description` as decorations layered on top of the spec).
- `cosmetic_unlock_rules.dart` `kCosmeticUnlockRules` becomes `kCompanionSpecs.map(_toRule).toList()`.
- `companions_content.dart` `companionNodes()` becomes `kCompanionSpecs.map(_toAvailabilityNode).toList()`, keeping the engine-specific decorations (badgeEmoji, contentTags, lockedHintKey) layered on top.

One `CompanionSpec` per companion; three derivations. Any future swap or rarity tweak touches one row.

### Option D (recommended as safety net during transition): Validator-only

Add a startup or test-time validator that asserts cross-file consistency:

```dart
test('companion catalog consistency: rarity matches across catalog + progress node', () {
  for (final companion in CosmeticCatalog().companions) {
    final node = companionNodes().firstWhere((n) =>
      n is CompanionAvailability &&
      n.companionId == companion.id) as CompanionAvailability;
    expect(node.rarity, companion.rarity,
      reason: 'rarity drift for ${companion.id}: '
              'catalog=${companion.rarity}, node=${node.rarity}');
  }
});

test('companion catalog consistency: unlock conditions match across kCosmeticUnlockRules + progress node', () {
  // For each companion, walk both lists and assert level + relic ids match.
});
```

Cheap to add. Catches the exact two bug families that hit during this rebalance. **Land this first, regardless of which consolidation option you pick** — it's the safety net for the refactor itself.

### Options ruled out

- **Make C derived from B.** Requires `cosmetics` to depend on `progression_engine` domain. Likely violates the layering rules in `docs/architecture.md` — cosmetics is the lower-level feature here.
- **Make B derived from C.** Inverts the dependency the other way. Possible but `CompanionAvailability` carries engine-specific metadata (rewards definition, contentTags, badgeEmoji) that don't belong in cosmetics.
- **Live with duplication, add no validation.** Already cost two user-visible bugs in one session. Don't.

---

## 5. Suggested execution order

1. **Read `docs/architecture.md`** to confirm layering rules (which feature can depend on which). Anchor the consolidation direction in those rules.
2. **Land the validator (Option D) first.** Two tests — one for rarity drift across A vs B, one for unlock-condition drift across B vs C. They must pass on `main` today (the catalog is already in sync after commit `6cac3d4`).
3. **Land `CompanionSpec`** (Option C). Const list, no derivations yet. Just hold the canonical data alongside the existing definitions.
4. **Switch one consumer at a time** to derive from `CompanionSpec`:
   - First `cosmetic_unlock_rules.dart` (smallest, easiest — `Cond.atLevel` + 2× `Cond.ownsCosmetic` straight from the spec).
   - Then `companions_content.dart` `CompanionAvailability` nodes (engine side).
   - Then `cosmetic_catalog.dart` `Companion` rows (most metadata to preserve; do last when spec model is mature).
5. **Delete duplicated literals** as each consumer flips to derivation.
6. **Update `docs/architecture.md`** to declare `CompanionSpec` the canonical source. Update `docs/site/data/glossary.json` if a new sealed type appears.

Tests that must stay green throughout:

- `test/features/progression_engine/companion_availability_late_gate_test.dart`
- `test/features/cosmetics/cosmetic_reveal_evaluator_test.dart`
- `test/features/cosmetics/cosmetic_sealed_catalog_test.dart`
- `test/features/cosmetics/companion_availability_lookup_test.dart`
- `test/features/progression_engine/granting_achievement_lookup_test.dart`
- `test/features/cosmetics/companion_claim_forging_test.dart`

---

## 6. Open questions for the next session

1. **Layering:** is `cosmetics` allowed to define `CompanionSpec`, or should it live in `lib/domain/` (cross-feature shared)? Check `docs/architecture.md`.
2. **Does the spec model own the buff?** The buff is currently expressed via subclasses of `CompanionBuff` (e.g. `FlatCompanionBuff`, `StreakLengthCompanionBuff`). Keeping the buff out of `CompanionSpec` (layered on top in `cosmetic_catalog.dart`) keeps the spec a pure data record. Recommended.
3. **Localization closures:** `Companion` rows reference `(l10n) => l10n.cosmeticCompanionAuroraStagName` closures. Those closures stay in `cosmetic_catalog.dart` — the spec only carries IDs. No ARB changes needed by consolidation itself.
4. **Dev-only companions:** `companion_monster_energy` (mythic, `devOnly: true`) does NOT have a `CompanionAvailability` node and NOT a `CosmeticUnlockRule` entry — it's granted via DevTools. The spec list should mark it as `availability: devToolsOnly` or exclude it from `_toRule` / `_toAvailabilityNode` derivations.
5. **Should the spec also include the relic pair's expected rarities?** That would let the validator catch *"companion is rare but relic A is epic"* drift too (the user's original concern). Cheap addition.

---

## 7. Relevant files (line refs at time of writing, may drift)

- `lib/features/cosmetics/domain/cosmetic_catalog.dart` — `Companion(...)` rows ≈ lines 805–998
- `lib/features/cosmetics/domain/cosmetic_unlock_rules.dart` — `kCosmeticUnlockRules` lines 36–154
- `lib/features/progression_engine/domain/catalog/content/companions_content.dart` — `companionNodes()` lines 42–209
- `lib/features/cosmetics/domain/cosmetic_unlock_rule.dart` — `CosmeticUnlockRule` model
- `lib/features/cosmetics/domain/cosmetic_reveal_evaluator.dart` — consumes `kCosmeticUnlockRules`
- `lib/domain/progression/catalog/progression_entry.dart` — defines `CompanionAvailability`
- `docs/architecture.md` — layering rules
- `docs/site/data/glossary.json` — sealed type registry (update when `CompanionSpec` lands)

---

## 8. What is NOT in scope for this consolidation

- Rarity / pacing rebalance. Done in `6cac3d4`. Future tweaks ride on the new spec.
- Relic-to-achievement granter logic. Lives in `meta_content.dart`, `steps_content.dart`, etc. — not part of the spec.
- Companion buff definitions. Stay in `cosmetic_catalog.dart`.
- Dev-only companions (Monster Energy etc.) — flag in spec or exclude, don't redesign their flow.
