# progression_engine

The V2 progression engine. Owns objective evaluation, the
node/reward/unlock catalog, the append-only ledger, and the display
facade other features consume.

## Layout

```text
domain/
├── catalog/
│   ├── content/                 # Per-domain catalog content (chapters, daily,
│   │                            #   long-term, companions, level milestones,
│   │                            #   side-quest chains, etc.)
│   ├── objective_catalog.dart   # Goal definitions consumed by ObjectiveEvaluator
│   ├── progression_node_catalog.dart  # Sealed-node catalog (quest / achievement /
│   │                                  #   milestone / level-milestone / chapter-
│   │                                  #   completion / companion-availability /
│   │                                  #   relic / content-unlock)
│   ├── level_milestone_specs.dart     # Level-tier metadata (title, emoji, anchors)
│   └── catalog_validator.dart   # Duplicate ids, dangling node refs, RPG-tag drift
├── display/
│   ├── progression_display_resolver.dart  # Public, feature-neutral display facade
│   └── progression_display_models.dart    # DTOs other features consume
├── evaluator/                   # Pure evaluators (no I/O, no Flutter)
│   ├── objective_evaluator.dart       # metric × scope × operator → outcome
│   ├── unlock_condition_resolver.dart # recursive AllOf / AnyOf
│   ├── progression_node_resolver.dart # objective + unlock + claim + ledger → NodeState
│   ├── reward_grant_planner.dart      # newly completed nodes → planned grants
│   └── engine_streak_source.dart      # derives streak summaries from the ledger
├── models/                      # Sealed hierarchies: ProgressionNode,
│   │                            #   RewardDefinition, UnlockCondition,
│   │                            #   ObjectiveMetric / Scope / Operator,
│   │                            #   LedgerEvent, ContentTag, etc.
├── policy/
│   └── level_policy.dart        # XP ↔ level table
└── repository/
    ├── ledger_snapshot.dart
    └── progression_engine_repository.dart

application/
├── progression_engine.dart           # Orchestrator. Single entry: evaluate(input, reason)
├── progression_engine_provider.dart  # ChangeNotifier the UI binds to
├── reward_grant_service.dart         # Builds reward events with XP scaling
├── daily_section_resolver.dart       # Builds daily section view-model
├── cosmetic_unlock_bridge.dart       # Engine grants → cosmetics unlocks
└── cosmetic_reveal_snapshot_builder.dart  # Builds the reveal-state snapshot

data/
├── isar_progression_engine_repository.dart    # Local persistence
├── in_memory_progression_engine_repository.dart  # Tests
├── firestore_progression_engine_gateway.dart  # Cloud I/O
├── hybrid_progression_engine_repository.dart  # Local-first, fire-and-forget cloud
├── provider_engine_input_source.dart          # Maps fitness/nutrition providers → engine input
└── local/                       # Isar collection records (+ generated .g.dart)

presentation/
├── quests_screen.dart                 # V2 quests screen
├── adapters/engine_achievement_view.dart  # Shared view-model for achievement rendering
└── widgets/                     # Quest cards, chapter cards, companion pills,
                                 #   reward chips, level badge, etc.
```

## Core principles

- **Deterministic.** Same input + same ledger → same result.
- **Idempotent.** Re-running `evaluate` produces the same accepted
  events; duplicates land as `skippedEvents`.
- **Append-only ledger.** Events have deterministic `eventKey`s; the
  ledger is the source of truth for "what happened".
- **Display facade.** Other features (`social`, `journey`,
  `celebration`, `home`) consume progression metadata exclusively
  through `ProgressionDisplayResolver`. They do not import catalog,
  evaluators, or ledger types directly.
- **Cloud sync.** Ledger events write through to Firestore via the
  hybrid repository — see [../../../docs/features/firestore_sync.md](../../../docs/features/firestore_sync.md).

## How to extend

- **Add a new objective** (a new metric / scope / operator combination):
  define an `Objective` in
  `domain/catalog/content/<domain>_content.dart`.
- **Add a new node** (quest / achievement / milestone): define a
  `ProgressionNodeDefinition` referencing one or more objectives.
- **Add a new reward type**: extend the sealed `RewardDefinition`
  hierarchy and handle it in `RewardGrantService` and the relevant
  bridge (e.g. `cosmetic_unlock_bridge.dart` for cosmetic rewards).
- **Add a new unlock condition**: extend the sealed `UnlockCondition`
  hierarchy; `UnlockConditionResolver` handles `AllOf` / `AnyOf`
  composition.

Validate any catalog change by running `CatalogValidator` — it checks
duplicate ids, missing objective references, missing node references on
`NodeCompleted` conditions, manual-claim nodes missing `lockedHintKey`,
and RPG-activation-without-RPG-tag drift.
