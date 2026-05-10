# progression_engine

The new progression engine. Built beside the legacy `lib/features/progression/`
module per the phased plan in
[docs/progression_engine_v2_phased_plan.md](../../../docs/progression_engine_v2_phased_plan.md).

## Status

| Phase | Description | Status |
|---|---|---|
| 0.5 | Display Resolver bridge over legacy catalog | done |
| 0.6 | Journey extraction (consumer of resolver) | done |
| 1 | Domain skeleton (objectives, sealed nodes, rewards) | done |
| 2 | Evaluation skeleton | not started |
| 2 | Evaluation skeleton | not started |
| 3 | Catalog port | not started |
| 4 | Persistence (Isar) | not started |
| 5 | Celebration integration | not started |
| 6 | Progression UI integration | not started |
| 7 | Display Resolver swap to new catalog | not started |
| 8 | RPG mode readiness | not started |
| 9 | Legacy removal | not started |

## What lives here today

- `domain/display/` — public, feature-neutral display facade. Other features
  (social, journey, future feed publishers) consume progression metadata
  exclusively through this surface.
- `domain/models/` — V2 core domain types: `ObjectiveDefinition`,
  sealed `ProgressionNode` hierarchy (Quest / Achievement / Milestone /
  LevelMilestone / ChapterCompletion / CompanionAvailability / Relic /
  ContentUnlock), sealed `RewardDefinition` (XP / Cosmetic / Chapter /
  Companion / Title / Emblem / Relic), sealed `UnlockCondition` (with
  AllOf / AnyOf composition), `ContentTag`, `ActivationPolicy`,
  `ClaimPolicy`, `NodeState`, sealed `ObjectiveMetric`, sealed
  `ObjectiveScope`, `ObjectiveOperator`.
- `domain/catalog/` — empty `ObjectiveCatalog` and `ProgressionNodeCatalog`
  with two sample entries each (one shared `sample_steps_today` objective
  proves the "one objective, many nodes" design end-to-end). Real
  catalog port lands in Phase 3. `CatalogValidator` checks duplicate
  ids, missing objective references, missing node references on
  `NodeCompleted` conditions, manual-claim missing `lockedHintKey`,
  and RPG-activation-without-RPG-tag drift.
- `presentation/widgets/level_badge.dart` — generic level badge.

## What does not live here yet

Everything else. Engine, evaluators, catalogs, persistence, celebration
adapter, RPG mode logic — all to be added in subsequent phases. During
coexistence the legacy module at `lib/features/progression/` remains the
source of truth.

## Class-name conflict during coexistence

Both modules will eventually contain a class named `ProgressionEngine`
(legacy in `progression/application/progression_engine.dart`, new in
`progression_engine/application/progression_engine.dart`). Files that need
to import both must use a prefixed import:

```dart
import 'package:forgetrack/features/progression/application/progression_engine.dart' as legacy;
// then refer to: legacy.ProgressionEngine
```

After Phase 9 the legacy file is gone and the prefix can be dropped.
