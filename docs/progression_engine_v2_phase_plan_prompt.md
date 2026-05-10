# Progression Engine V2 — Claude Planning Handoff

## Context

Forgetrack currently has a progression system that grew organically around separate concepts:

- quests
- achievements
- milestones
- chapter unlocks
- XP rewards
- cosmetic rewards
- relics
- companions
- social achievement display
- celebration screen logic

The current implementation is becoming hard to reason about because these concepts are partially duplicated, partially overlapping, and partially leaking into other features.

Examples of current issues:

- A quest and an achievement can represent the same goal but have different rewards.
- A long-term goal like "walk 10M steps" can be both a quest with XP and an achievement with cosmetics.
- Milestones behave like achievements, but also unlock chapters or rewards.
- Chapter quest chains give completion rewards such as emblems.
- Companions are a special case: they should become available after requirements are met, but the player should unlock them manually later in inventory.
- The celebration screen currently needs to understand too much about what was completed and what rewards were granted.
- The social feature imports progression achievement catalogs and maps social achievement data back into progression achievement models.
- The current model makes a future "RPG mode on/off" setting harder than it should be.

The app has no production users yet. A full local reset / factory reset is acceptable. Existing unlocked achievements, rewards, cosmetics, ledger keys, and item grants do **not** need to be migrated.

This means the refactor can be treated as a clean redesign, not a backwards-compatible migration.

---

## Strategic Decision

Prefer building a new progression engine module next to the legacy implementation instead of mutating the current engine in place.

The preferred strategy is:

```text
Freeze legacy progression
→ build Progression Engine V2 beside it
→ validate V2 through debug/devtools
→ migrate UI consumers gradually
→ delete legacy implementation
→ perform factory reset of local progression data
```

This is likely safer and cleaner than attempting a large in-place refactor.

Suggested temporary location:

```text
lib/features/progression_engine/
```

or:

```text
lib/features/progression_v2/
```

The exact folder name can be chosen based on the current project structure.

The legacy feature should remain functional during the first implementation phases.

---

## Main Goal

Create a neutral, scalable, maintainable progression engine where quests, achievements, milestones, chapter unlocks, and companions are not separate evaluators.

The new engine should be based around these concepts:

```text
ObjectiveDefinition
ProgressionNodeDefinition
RewardDefinition
UnlockCondition
ProgressionLedgerEvent
ProgressionResolutionResult
```

The engine should evaluate objectives once, resolve all affected progression nodes, grant rewards idempotently, and produce one canonical result that can be consumed by UI, celebration, social feed, debug tools, notifications, and future cloud sync.

---

## Core Domain Model Direction

### 1. ObjectiveDefinition

An objective is a pure machine-readable condition.

It should not contain UI or reward metadata.

Good objective properties:

- id
- metric
- scope
- operator
- target value
- period/window
- optional debug label

Examples:

```text
steps lifetime >= 10,000,000
steps today >= 10,000
sleep today >= 8h
protein today >= 180g
level >= 20
complete daily goals >= 4
complete chapter quest chain
```

Do **not** put these on ObjectiveDefinition:

- rarity
- unlock hint
- title
- description
- icon
- reward preview
- celebration text
- UI priority

Those belong to ProgressionNodeDefinition or RewardDefinition.

---

### 2. ProgressionNodeDefinition

A progression node represents the player-facing meaning of a completed objective or unlock condition.

A node can represent:

- quest
- achievement
- milestone
- chapter quest
- chapter completion
- companion availability
- unlockable content
- level milestone
- future progression event types

Suggested properties:

- id
- type
- objectiveId, if the node is objective-driven
- unlockConditions
- rewards
- claimPolicy
- visibility
- rarity / difficulty
- titleKey
- descriptionKey
- lockedHintKey
- contentTags
- activationPolicy
- chainId / order
- display metadata

The important idea:

```text
Quest, achievement, milestone, chapter completion, and companion availability are different node types, not different engines.
```

---

### 3. RewardDefinition

Rewards should be explicit, editable, and easy to add.

Reward types may include:

- XP
- cosmetic
- relic
- chapter unlock
- companion availability
- emblem
- badge
- title
- future inventory/content unlocks

Reward definitions can be inline in nodes unless the current implementation strongly benefits from a separate reward catalog.

Important:

```text
Milestones unlocking chapters should be modeled as rewards.
Companions should usually receive an "available" reward/state first, then be manually unlocked by the player.
```

---

### 4. UnlockCondition

Unlock conditions determine whether a node can become active, available, visible, or claimable.

Examples:

- level at least X
- objective completed
- node completed
- quest completed
- chapter unlocked
- relic owned
- companion available
- RPG mode enabled
- all of conditions
- any of conditions

Avoid scattering this logic across UI widgets.

---

### 5. ClaimPolicy

Some nodes should complete automatically, others should become available and wait for manual user action.

Suggested policies:

```text
automatic
manual
```

Examples:

- normal quest completed: automatic
- achievement unlocked: automatic
- milestone reached: automatic
- companion available: manual
- inventory unlock: manual
- maybe special rewards: manual

---

## Canonical Evaluation Flow

The target engine flow should be:

```text
Input data / user state / changed metrics
→ ObjectiveEvaluator
→ completed objective ids
→ ProgressionNodeResolver
→ completed nodes / available nodes
→ RewardGrantService
→ immutable ledger events
→ ProgressionResolutionResult
```

The celebration screen, social feature, debug tools, and UI should not re-evaluate progression logic.

They should consume the canonical result or display metadata derived from it.

---

## ProgressionResolutionResult

The new engine should produce a canonical result for each evaluation run.

Suggested shape:

```text
ProgressionResolutionResult
- evaluationRunId
- reason
- completedObjectives
- completedNodes
- availableNodes
- grantedRewards
- skippedEvents / warnings if useful
```

Suggested reasons:

```text
liveUpdate
manualRefresh
backgroundSync
historicalResync
devTool
factoryResetSeed
```

The result should make it easy to decide:

- whether to show celebration
- whether to show compact summary
- whether to enqueue social events
- whether to suppress noise during historical sync
- what to log in devtools
- what to sync later to Firestore

---

## Celebration Screen Direction

Celebration should be a renderer of resolved progression events, not an evaluator.

Bad:

```text
Celebration screen looks up objectives, quests, achievements, rewards and merges them itself.
```

Good:

```text
ProgressionEngine returns ProgressionResolutionResult.
ProgressionCelebrationMapper maps the result to a CelebrationPayload.
CelebrationScreen renders the payload.
```

Recommended display ordering:

1. level up
2. milestone reached
3. chapter/content unlocked
4. quest completed
5. achievement unlocked
6. rewards granted
7. companion available

XP can be aggregated for display, with optional source breakdown.

Cosmetics, relics, emblems, chapters, and companions should be shown individually.

---

## Social Feature Leakage

The current social feature imports progression achievement internals and maps social achievements back into progression achievement models.

This is a leaky dependency.

Target direction:

```text
Social should not depend on achievement-specific progression internals.
Social should consume generic progression display metadata or generic progression unlock events.
```

Eventually replace achievement-specific social models with generic progression social events.

Possible direction:

```text
SocialProgressionEvent
- id
- userId
- eventType
- nodeId
- rewardId
- title/display snapshot
- description/display snapshot
- domain
- rarity
- createdAt
```

But do not necessarily implement the full social rewrite in the first phase.

During migration, keep social working and isolate the leak behind a resolver/facade if needed.

Suggested abstraction:

```text
ProgressionDisplayResolver
```

It can resolve node display metadata without exposing internal catalog/evaluation models directly to social.

---

## RPG Mode Future Requirement

The progression engine should be neutral and support a future user setting:

```text
RPG mode enabled / disabled
```

Do not implement the full toggle UI yet unless it is already trivial, but design for it.

Important rules:

```text
Objective progress should be able to run independently of RPG mode.
Core progression should continue even when RPG mode is disabled.
RPG-specific nodes and rewards should be hideable or disableable without changing the engine.
The UI should not be full of hardcoded if (rpgModeEnabled) checks.
Filtering should live in application/display services.
```

Suggested concepts:

```text
ProgressionContentTag
- core
- rpg
- fitness
- journey
- cosmetics
- relics
- companions
- social

NodeActivationPolicy
- always
- onlyWhenRpgEnabled
- onlyWhenRpgEnabledNoBackfill
```

Rewards may also need content tags or visibility policies.

Examples:

- daily steps XP quest: core
- lifetime steps achievement: core
- fantasy relic reward: RPG
- chapter unlock: RPG
- companion availability: RPG
- simple level badge: core
- journey map milestone: RPG

---

## Scaling and Catalog Design

Scalability is important.

The new system should make it simple to:

- add a new quest
- add a new achievement
- add a milestone
- edit rewards
- attach multiple rewards to one node
- share one objective across multiple nodes
- add RPG-only content
- add core non-RPG content
- validate catalog consistency
- display progression in different contexts

Avoid designs where adding one achievement requires edits in many unrelated switch statements.

Prefer catalog definitions that are explicit, readable, and easy to validate.

Suggested catalogs:

```text
ObjectiveCatalog
ProgressionNodeCatalog
CosmeticCatalog
RelicCatalog
CompanionCatalog
ChapterCatalog
```

Reward definitions may be inline in nodes unless a separate reward catalog is clearly better.

---

## Catalog Validator

Add a validator early.

It should check things like:

- duplicate objective ids
- duplicate node ids
- missing objective references
- missing reward item references
- invalid chain ordering
- invalid chapter references
- invalid companion references
- invalid cosmetic references
- invalid relic references
- node with manual claim but no meaningful availability state
- achievement with XP reward if the project decides achievements should never give XP
- companion node without manual claim policy, if that is a rule
- RPG-only reward attached to a core-only node without explicit policy
- hidden nodes with missing hints if needed
- display metadata missing for visible nodes

Fail fast in debug/dev mode.

---

## Persistence / Ledger Direction

Because there are no production users, preserving old ledger keys is not required.

It is acceptable to redesign:

- local Isar records
- ledger event records
- claim keys
- reward grant keys
- achievement unlock records
- local progression state

Still, V2 should be idempotent by design.

Suggested key ideas:

```text
objective|{objectiveId}|completed
node|{nodeId}|claim
reward|{nodeId}|{rewardId}|grant
node|{nodeId}|{periodKey}|claim
reward|{nodeId}|{rewardId}|{periodKey}|grant
```

Exact key design can be adapted to the current code.

The important thing is that repeated evaluations do not double-grant XP, cosmetics, relics, chapters, companions, or other rewards.

---

## Edge Cases to Consider

### Shared Objective

One objective can complete multiple nodes.

Example:

```text
Objective: lifetime steps >= 10M
Quest: gives XP
Achievement: gives cosmetic
Milestone: unlocks chapter
```

The objective should be evaluated once. Each node should resolve independently. Rewards should be granted idempotently.

---

### Quest and Achievement With Same Goal

Do not duplicate evaluation logic.

Both should reference the same ObjectiveDefinition.

---

### Milestone as Achievement-Like Node

A milestone should not require a totally separate evaluator.

It should be a node type with special display behavior and possibly important rewards.

---

### Chapter Unlock as Reward

Unlocking a chapter should be modeled as a reward/content unlock.

Chapter quest nodes can then depend on:

```text
chapter unlocked
```

---

### Chapter Quest Chain Completion

Completing a full chapter chain can be modeled as a node whose unlock conditions require all chapter quest nodes to be completed.

It can grant:

- emblem
- relic
- cosmetic
- XP
- next chapter unlock
- other content

---

### Companion Availability vs Unlock

Companions should support at least:

```text
locked
available
unlocked/equipped
```

Requirements can make the companion available, but the actual unlock should be manual if desired.

Do not immediately equip or fully unlock companions just because conditions are met.

---

### Historical Resync / Factory Reset

If a large amount of historical data is evaluated at once, avoid spamming the user with dozens of full-screen celebrations.

The result reason should allow compact summaries.

---

### Background Sync

Background sync may resolve progression while the app is not foregrounded.

The engine should produce events/results that can be logged and later surfaced safely.

Do not make the engine depend on UI availability.

---

### RPG Disabled

When RPG mode is disabled in the future:

- core objectives can still progress
- core XP/level/achievement can still work
- RPG chapters/relics/companions/journey map can be hidden or disabled
- social publisher should not emit RPG-flavored events unless appropriate
- celebration should use non-RPG display mapping

---

### Social Feed Snapshot

Consider whether social feed events should store display snapshots.

If social events only store node IDs, old feed items may change when node titles or descriptions are edited.

This may or may not be desired.

A hybrid approach may be best:

```text
nodeId + event type + display snapshot metadata
```

---

## Recommended Implementation Strategy

Do not start by rewriting every UI.

Recommended sequence:

### Phase 0 — Read-only audit

Claude should inspect the current implementation and identify:

- current progression folders/files
- quest catalog
- achievement catalog
- reward catalog
- rule catalog
- milestone/chapter logic
- cosmetics integration
- companion/relic placeholders if any
- ledger persistence
- Isar records
- progression provider
- celebration flow
- social imports and dependencies
- devtools/debug consumers
- UI screens consuming progression state

No code changes in this phase unless explicitly requested.

Output a concrete implementation plan into a new markdown file.

---

### Phase 1 — Create V2 domain module

Create the new module beside legacy progression.

Add:

- ObjectiveDefinition
- ProgressionNodeDefinition
- RewardDefinition
- UnlockCondition
- ClaimPolicy
- content tags / activation policy
- ProgressionResolutionResult
- catalog validator skeleton

Add a few sample migrated nodes/objectives only.

Keep the app compiling.

---

### Phase 2 — Implement V2 evaluation skeleton

Add:

- ObjectiveEvaluator
- ProgressionNodeResolver
- RewardGrantService skeleton
- in-memory or local repository abstraction
- deterministic keys
- debug logging

Do not connect to production UI yet.

Add dev/debug method to run V2 evaluation and inspect result.

---

### Phase 3 — Port catalogs

Move/convert current quest/achievement/milestone ideas into V2 catalogs.

Because no migration is needed, catalog IDs can be cleaned up if necessary.

Keep definitions explicit and readable.

Add validator coverage.

---

### Phase 4 — Persistence

Implement V2 local persistence.

It is acceptable to create new Isar records/tables and later delete the legacy ones.

No migration required.

Factory reset can clear old state.

---

### Phase 5 — Celebration integration

Connect celebration to ProgressionResolutionResult through a mapper.

Celebration should no longer manually merge quest/achievement/reward logic.

---

### Phase 6 — Progression UI integration

Migrate:

- quest screen
- achievement screen
- progression overview
- journey/milestone display
- rewards display
- cosmetics unlock display

Use V2 display models/resolvers.

---

### Phase 7 — Social integration

Remove direct dependency on achievement catalog internals.

Introduce generic progression social events or a display resolver/facade.

Keep social UI working during migration.

---

### Phase 8 — RPG mode readiness

Do not necessarily build the UI toggle yet.

Ensure content tags, activation policies, and display filters make future RPG enable/disable straightforward.

---

### Phase 9 — Remove legacy

After V2 is fully connected:

- delete legacy catalogs/evaluators/models
- delete old persistence records if appropriate
- remove compatibility adapters
- clean imports
- run full analyzer/tests
- perform factory reset

---

## Claude Prompt

Use this prompt with Claude Code / Opus.

```text
You are working on the Forgetrack Flutter app.

Read the file `progression_engine_v2_phase_plan_prompt.md` and inspect the current codebase.

Goal:
Evaluate the current progression implementation and prepare a concrete phased implementation plan for building a new Progression Engine V2 beside the legacy implementation, then migrating consumers gradually.

Important context:
- The app has no production users.
- A full factory reset is acceptable.
- Existing unlocked achievements, rewards, cosmetics, local progression state, and ledger keys do NOT need to be migrated.
- You may redesign catalog IDs, ledger keys, Isar records, and persistence models if it improves the architecture.
- Still preserve existing app behavior conceptually where it makes sense.
- Keep the legacy progression system working during the early V2 buildout.
- Do not perform a big-bang rewrite.
- Keep the app compiling after each implementation phase.
- Prefer explicit, readable, imperative Dart code over clever abstractions.
- Avoid streams or complex reactive abstractions unless the existing architecture clearly requires them.
- Do not touch Health Connect, nutrition fetching, authentication, or unrelated features except where needed to connect progression inputs/outputs.
- Be especially careful with social feature leakage: social currently imports progression achievement internals. The target direction is a generic display resolver or generic progression social events.
- Design the new engine to be neutral and future-proof for an RPG mode on/off setting.
- Objective progress should be independent of RPG mode.
- RPG-specific content such as chapters, relics, companions, journey map milestones, and fantasy celebration should be hideable/disableable without creating a separate engine.
- Scalability matters: adding quests, achievements, milestones, and editing rewards should be simple and localized.

First task:
Do a read-only architecture audit. Do not modify code yet.

Please inspect:
- current progression feature structure
- quest catalog
- achievement catalog
- reward catalog
- rule catalog
- milestone/chapter logic
- progression provider/engine/evaluators
- ledger/persistence/Isar records
- celebration screen/result flow
- cosmetics integration
- social feature imports/dependencies on progression
- devtools/debug/progression diagnostics
- UI consumers of progression state

Then create a new markdown file, for example:

`docs/progression_engine_v2_phased_plan.md`

or another appropriate project location.

The markdown should contain:
1. Current architecture summary.
2. Main problems and dependency leaks.
3. Proposed V2 module structure.
4. Proposed core domain model.
5. Proposed evaluation flow.
6. Proposed persistence/ledger design.
7. Catalog design and validator rules.
8. Celebration integration plan.
9. Social integration plan.
10. RPG mode readiness plan.
11. Factory reset / no-migration assumptions.
12. Risk list.
13. Concrete implementation phases with expected files and acceptance criteria per phase.

Do not implement the refactor yet. Only audit and write the phased plan.
```

---

## Success Criteria for the Refactor

The refactor is successful when:

- objectives are defined once and reused
- quest/achievement/milestone/chapter/companion are unified as node types
- rewards are explicit and easy to edit
- celebration consumes canonical resolution results
- social no longer imports achievement internals directly
- RPG mode can be added mostly through filtering/settings, not by forking the engine
- catalog validation catches broken definitions early
- factory reset can clear old progression data safely
- adding a new quest/achievement/reward is localized and predictable
- the engine is UI-neutral and can be used by devtools, notifications, social, cloud sync, and UI
