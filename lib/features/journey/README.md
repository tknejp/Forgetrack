# journey

Hero Journey map and milestone feed. Consumes V2 progression state via
`ProgressionEngineProvider` and renders a map + event feed; produces no
signals back into the engine.

## Layout

```text
lib/features/journey/
├── domain/
│   ├── journey_models.dart  # JourneyCheckpoint, JourneyEventType, JourneyMilestoneAnchor
│   └── journey_levels.dart  # kJourneyMapAnchors — which levels surface as map anchors
└── presentation/
    ├── hero_journey_map_screen.dart  # detail screen
    └── widgets/
        ├── journey_adapter.dart        # ProgressionEngineProvider → JourneyCheckpoint lists
        ├── journey_event_feed.dart     # milestone feed below the map
        ├── journey_interactive_map.dart # pannable, zoomable map
        ├── journey_map_route.dart      # JSON-loaded route data class
        ├── journey_preview_card.dart   # compact preview on hero screen
        └── journey_primitives.dart     # shared visual primitives
```

## Dependencies

- `progression_engine/application/progression_engine_provider.dart` —
  player level, achievement / quest completion ledger.
- `progression_engine/domain/catalog/level_milestone_specs.dart` —
  level-tier metadata (titles, emoji).
- `progression_engine/presentation/adapters/engine_achievement_view.dart` —
  shared view-model for milestone rendering.
- `shared/presentation/achievement_badge_specs.dart` — shared visual
  helper for badge rendering.

Level milestone timestamps come from the matching `level_<N>`
achievement node's completion event in the V2 ledger. There are no
synthesised dates — a milestone without a real timestamp gets `null`,
which the feed sorts after dated entries.
