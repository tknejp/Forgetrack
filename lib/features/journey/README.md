# journey

Hero Journey map and milestone feed. Lives outside the progression engine
because it is a pure consumer of progression state — it reads `level`,
`achievements`, and `completedQuests`, and renders a map / event feed.
It produces no signals back into the engine.

## Status

Phase 0.6 — extracted from `lib/features/progression/presentation/journey/`
and `lib/features/progression/domain/journey_models.dart` per the phased
plan in [docs/progression_engine_v2_phased_plan.md](../../../docs/progression_engine_v2_phased_plan.md).

## Layout

```
lib/features/journey/
├── domain/
│   └── journey_models.dart           # JourneyCheckpoint, JourneyEventType, JourneyMilestoneAnchor
└── presentation/
    ├── hero_journey_map_screen.dart  # detail screen
    └── widgets/
        ├── journey_adapter.dart      # ProgressionProvider → JourneyCheckpoint lists
        ├── journey_event_feed.dart   # milestone feed below the map
        ├── journey_interactive_map.dart # pannable, zoomable map
        ├── journey_map_route.dart    # JSON-loaded route data class
        ├── journey_preview_card.dart # compact preview on hero screen
        └── journey_primitives.dart   # shared visual primitives
```

## Current dependencies on progression

- `ProgressionProvider` — state (player level, achievements, quests).
  Will be swapped to the new engine's provider in Phase 6.
- `kProgressionLevelTiers` / `tierForLevel` / `kJourneyMapAnchors` /
  `kJourneyTitleBreakpoints` from
  `progression/domain/policy/level_config.dart` — level-tier metadata.
  Will be sourced from `ProgressionDisplayResolver.levelMilestones()`
  in Phase 6 (resolver methods extended in Phase 7's pre-work).
- `ProgressionAchievement` type from
  `progression/domain/progression_models.dart` — passed through from
  `provider.achievements`. Goes away with the provider swap.
- `achievement_badge_specs.dart` from `lib/shared/presentation/` — shared
  visual helper. Stays in shared/ until the new engine collapses
  Difficulty into Rarity.

## What does not live here

Progression evaluation, catalog, persistence, claim flow — all in
`lib/features/progression/` (legacy) and incrementally in
`lib/features/progression_engine/` (V2).
