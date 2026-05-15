# Progression Engine — Phased Implementation Plan

> **Module name decision (post-revision):** the new module is `lib/features/progression_engine/`. The legacy module stays at `lib/features/progression/` until Phase 9, then is deleted entirely. No rename of the new folder needed afterwards.
>
> **Class-name conflict during coexistence:** both modules contain a class named `ProgressionEngine` (legacy in `progression/application/progression_engine.dart`, new in `progression_engine/application/progression_engine.dart`). Files that need to import both must use a prefixed import: `import '.../features/progression/application/progression_engine.dart' as legacy;` and refer to `legacy.ProgressionEngine`. After Phase 9 the legacy file is gone and the prefix can be dropped.
>
> The shorthand "V2" used throughout this document refers to the new engine in prose only — there is no `_v2` suffix on any class or file in the actual implementation.

**Status:** Read-only audit + plan. No code changes proposed in this document.
**Authoring constraints:** No production users, full factory reset acceptable, no
migration of existing ledger keys, achievements, cosmetics, or unlocks. Legacy
progression must keep working through the early V2 phases.
**Source brief:** [progression_engine_v2_phase_plan_prompt.md](progression_engine_v2_phase_plan_prompt.md)

---

## 1. Current Architecture Summary

The legacy progression system lives under [lib/features/progression/](../lib/features/progression/) and is composed of five conceptually clean layers that have grown blurry at the edges.

### 1.1 Domain models — five parallel concept families

- **Rules** ([rule_models.dart](../lib/features/progression/domain/models/rule_models.dart)): `ProgressionRuleDefinition`, `ProgressionEvaluation`, `ProgressionRewardGrant`, `ProgressionSnapshot`, `ProgressionProfile`. Daily/weekly metric goals (steps, kcal, protein…). Repeatable.
- **Quests** ([quest_models.dart](../lib/features/progression/domain/models/quest_models.dart)): `ProgressionQuestDefinition`, `ProgressionQuest`, `ProgressionQuestRewardGrant`, `ProgressionChapterStartRecord`. Carries display metadata, status state machine (locked/available/active/completed), chains, chapters, daily sequences, combo pools, achievement pairing, cosmetic rewards.
- **Achievements** ([achievement_models.dart](../lib/features/progression/domain/models/achievement_models.dart)): `ProgressionAchievementDefinition`, `ProgressionAchievement`, `ProgressionAchievementUnlockEvent`, `ProgressionAchievementCompositeCondition`. 14 criterion types, two parallel grading axes (`difficulty` enum + `rarity` enum + optional `difficultyScore` 1.0–10.0).
- **Levels / Tiers** ([level_config.dart](../lib/features/progression/domain/policy/level_config.dart)): `ProgressionLevelTier` and the `kProgressionLevelTiers` constant — emoji, difficulty, rarity, journey-map flags, title, cosmetic rewards. Achievement catalog *generates* synthetic `level_<N>` achievements off this list.
- **Cosmetic rewards**: declared inline as `List<String> cosmeticRewards` on quests, achievements, and tiers. The dispatcher reads them all and unlocks via the cosmetics feature.

### 1.2 Catalogs — large, mostly hand-authored

- [quest_catalog.dart](../lib/features/progression/domain/catalog/quest_catalog.dart) — **1918 lines**, ~100+ quest definitions across journey/chapter/daily/weekly/chain categories.
- [achievement_catalog.dart](../lib/features/progression/domain/catalog/achievement_catalog.dart) — **605 lines**, mix of hand-authored entries + dynamic level-achievement synthesis from `kProgressionLevelTiers`.
- [rule_catalog.dart](../lib/features/progression/domain/catalog/rule_catalog.dart) — 196 lines, ~15–20 rules, version-stamped (`_version = '2026-04-defaults-v1'`).

### 1.3 Evaluators — three stateless services

- [progression_evaluator.dart](../lib/features/progression/domain/evaluator/progression_evaluator.dart): rule × snapshot → evaluation.
- [quest_evaluator.dart](../lib/features/progression/domain/evaluator/quest_evaluator.dart) — **1607 lines**. Status state machine, chapter gating, active-set computation, combo pool rotation, daily sequences, prerequisite resolution.
- [achievement_evaluator.dart](../lib/features/progression/domain/evaluator/achievement_evaluator.dart) — **650 lines**. One `currentValue` branch per criterion, hard-coded combo/triple-combo quest id sets mirroring the quest catalog.
- [perfect_period_evaluator.dart](../lib/features/progression/domain/evaluator/perfect_period_evaluator.dart) — shared utility used by both achievement evaluator and cosmetic snapshot extractor so counts can never disagree.

### 1.4 Policies

- [level_policy.dart](../lib/features/progression/domain/policy/level_policy.dart) — XP↔level table, per-level XP multiplier for rewards.
- [streak_policy.dart](../lib/features/progression/domain/policy/streak_policy.dart) — `summarizeByRule()`, `summarizeByDomain()` from evaluations.
- [reward_finalization_policy.dart](../lib/features/progression/domain/policy/reward_finalization_policy.dart) — claim-time XP scaling.
- [level_config.dart](../lib/features/progression/domain/policy/level_config.dart) — `kProgressionLevelTiers` and helpers (`tierForLevel`, `cosmeticsForLevel`, `levelHasTitleBreakpoint`, `levelFromAchievementId`).

### 1.5 Engine orchestrator

[progression_engine.dart](../lib/features/progression/application/progression_engine.dart) wires everything together. Surface:

- `load()` / `sync(ProgressionSource)` — main flow: evaluate → persist evaluations → derive state → diff & persist new quest grants → diff & persist active-quest set → diff & persist chapter starts → diff & persist achievement unlocks → return [progression_engine.dart:170](../lib/features/progression/application/progression_engine.dart#L170).
- `claimReward()` / `claimAllRewards()` / `claimQuestReward()` / `claimAllQuestRewards()` — idempotent XP claims, scaled by current level [progression_engine.dart:216](../lib/features/progression/application/progression_engine.dart#L216).
- `devToolsResetLedger()`, `devToolsSetTotalXp()`, `devToolsGrantAchievement()` — escape hatches that require a `ProgressionLocalRepository` (Isar-backed) [progression_engine.dart:93](../lib/features/progression/application/progression_engine.dart#L93).
- Returns `ProgressionEngineState` — derived view bundling profile, evaluations, grants, quests, achievements, chapter starts, streaks.

### 1.6 Provider, source, queueing

[progression_provider.dart](../lib/features/progression/application/progression_provider.dart) — **829 lines**, `ChangeNotifier`. Owns:

- Engine state cache (`_state`).
- `bind(goalsProvider, fitnessProvider, nutritionProvider, cosmeticsProvider)` constructs a `ProviderProgressionSource` and triggers the first refresh [progression_provider.dart:397](../lib/features/progression/application/progression_provider.dart#L397).
- `refresh()` runs `engine.sync()`, dispatches cosmetics, queues celebrations, emits notifications when backgrounded, logs to devtools.
- `_queueCelebrations()` does **all the diffing** between previous and current states to decide what celebrates [progression_provider.dart:650](../lib/features/progression/application/progression_provider.dart#L650): level-up cosmetics, achievement unlocks (with paired quest grants when `quest.achievementId` matches a fresh achievement), orphan cosmetic unlocks, standalone quest completions.
- ~30 derived getters: `pendingRewards`, `activeQuests`, `dailyQuests`, `weeklyQuests`, `chapterQuests`, `journeyQuests`, `waitingChapterQuests`, `streakForRule`, `streakForDomain`, etc.

### 1.7 Persistence (Isar)

[progression_local_models.dart](../lib/features/progression/data/local/progression_local_models.dart) defines six collections, all keyed by stable deterministic strings:

| Collection | Key | Purpose |
|---|---|---|
| `ProgressionEvaluationRecord` | `evaluationKey = $ruleId\|$version\|$periodKind\|$anchorKey` | Per-period rule outcomes |
| `ProgressionRewardGrantRecord` | `rewardKey = $evaluationKey\|reward` | Rule reward grants (claimable) |
| `ProgressionQuestRewardGrantRecord` | `rewardKey = quest\|$id\|reward` or `quest\|$id\|$dateKey\|reward` for repeatables | Quest reward grants |
| `ProgressionActiveQuestRecord` | `questId` | Current active quest set (display) |
| `ProgressionAchievementUnlockRecord` | `unlockKey = achievement\|$id` | Achievement unlock history |
| `ProgressionChapterStartLocalRecord` | `startKey = chapter\|$id\|start` | Chapter availability |

Repository abstraction: [progression_repository.dart](../lib/features/progression/domain/progression_repository.dart) → impl [progression_repository_impl.dart](../lib/features/progression/data/progression_repository_impl.dart) (Isar) → optional cloud overlay [hybrid_progression_repository.dart](../lib/features/progression/data/hybrid_progression_repository.dart) → Firestore mappers [data/firestore/](../lib/features/progression/data/firestore/).

### 1.8 Cosmetic dispatch (the one explicit seam)

[cosmetic_unlock_dispatcher.dart](../lib/features/progression/application/cosmetic_unlock_dispatcher.dart) — four-pass dispatch on every state diff:

1. Achievement catch-up (read `achievement.cosmeticRewards`)
2. Level catch-up (`cosmeticsForLevel(level)` for 1..currentLevel)
3. Quest catch-up (claimed grants → `quest.cosmeticRewards`)
4. Tier-2 rule evaluator (cosmetics-feature-internal rules), bounded fixed-point loop (max 3 iterations)

This is the **only** place progression directly mutates cosmetics state. Direction is uni-: progression → cosmetics. Cosmetics knows nothing about progression.

### 1.9 Celebration

[celebration/](../lib/features/celebration/) is a *new* feature created in the recent refactor (the old `progression_celebration_overlay.dart` was deleted, see git status).

- [celebration_event.dart](../lib/features/celebration/domain/models/celebration_event.dart) — UI-shaped event (eyebrow, title, rewards, headRarity, optional claim). Uses closures for localized text.
- [progression_celebration_adapter.dart](../lib/features/celebration/application/progression_celebration_adapter.dart) — pure transformer from `ProgressionCelebrationEvent` (provider's queue item) to `CelebrationEvent` (UI). Handles 4 kinds: levelMilestone, achievementUnlocked, cosmeticUnlocked, questCompleted (+ a combined achievement+quest variant when paired).
- Variant routing (topsheet/fullscreen) via [celebration_router.dart](../lib/features/celebration/domain/services/celebration_router.dart) and overlay host.

### 1.10 UI consumers (29 files)

`ProgressionProvider` is read by main shell, home overview, hero screen, hero journey map, quests screen, devtools sections, social profile widgets, social provider, social leaderboard, onboarding step, cosmetics provider (for unlock callbacks). See grep results in audit notes.

---

## 2. Main Architectural Problems and Dependency Leaks

### 2.1 Three parallel "what counts as progress?" models

Quests, achievements, and rules all carry their own `criterionType` enums:

- `ProgressionRuleDefinition` has metric/comparator (low-level: "steps >= 10000 today")
- `ProgressionQuestCriterionType` has 10 values, of which several overlap with achievements (`totalXpAtLeast`, `rewardCountAtLeast`, `bestStreakAtLeast`, `totalRuleValueAtLeast`, `achievementUnlocked`, `ruleCompletionsAtLeast`, `domainRewardCountAtLeast`)
- `ProgressionAchievementCriterionType` has 14 values, partially overlapping with quests (`totalXpAtLeast`, `rewardCountAtLeast`, `bestStreakAtLeast`, `totalRuleValueAtLeast`)

**Cost:** Adding a new "lifetime steps >= 10M" achievement requires either reusing or duplicating the quest's criterion logic, and the two evaluators implement it with subtly different code paths. The user's brief explicitly cites this overlap.

### 2.2 Quest definition is a "kitchen sink" of 35+ optional fields

[quest_models.dart:102–198](../lib/features/progression/domain/models/quest_models.dart#L102-L198) — `ProgressionQuestDefinition` has fields for chapter membership, chain step labels, daily sequences, combo pools, achievement pairing, prerequisite quests, asset keys, visual domain, source labels, display buckets, display groups, two priority axes (`sortOrder`, `priority`), repeatable-vs-one-shot reward keying, etc. Nothing distinguishes "this is a chapter finale" from "this is a daily" except a category enum and the presence/absence of a half-dozen optional fields.

**Cost:** The quest evaluator is 1607 lines partly because it must handle every possible combination of those optional fields. Adding a new node type means either bending the quest model or adding yet another pseudo-kind through fields.

### 2.3 Milestone, chapter, companion, relic, level — same engine?

The brief explicitly asks for these to be unified as **node types** rather than separate evaluators. Currently:

- **Levels** are not real nodes — they're synthesized as achievements via `kProgressionLevelTiers` and dispatched as cosmetic unlocks per-level inside the dispatcher.
- **Milestones** don't exist as a first-class concept; the journey map flag (`isJourneyMapAnchor`) is the closest thing.
- **Chapters** are pseudo-nodes — a "chapter open" quest with `criterionType: chapterStarted` plus a "chapter finale" quest gated on prerequisites + a sidecar `ProgressionChapterStartRecord` table tracking when each chapter became available.
- **Companions / relics** don't exist yet — they're aspirational `CosmeticType.companion` and `CosmeticType.relic` enum values that today behave the same as any other cosmetic (auto-equipped on unlock, no manual-claim distinction).

**Cost:** Implementing companions properly today means either adding a fifth pseudo-kind to quests, a side table, or fighting the cosmetic dispatcher's auto-grant assumption.

### 2.4 Reward attachment is structurally inconsistent

| Producer | Reward attachment |
|---|---|
| Rule | `rewardXp` int on definition; cosmetics not supported |
| Quest | `rewardXp` int + `cosmeticRewards: List<String>` |
| Achievement | `cosmeticRewards: List<String>` (XP not supported by design — confirmed via achievement evaluator code) |
| Level tier | `cosmeticRewards: List<String>` (XP implicit via the level itself) |

There's no first-class "reward bundle" — XP, cosmetics, future relics/companions/chapters/titles each ride on a different field of a different parent. Adding a new reward type (e.g. "title", "emblem") requires touching every model that grants rewards, plus the dispatcher, plus the celebration adapter.

### 2.5 Celebration queue knows too much

[progression_provider.dart:650 `_queueCelebrations()`](../lib/features/progression/application/progression_provider.dart#L650) — 145 lines that:

- Iterate `previous.profile.level + 1 .. current.profile.level` to synthesize per-level events
- Diff achievement unlocked sets and filter out level achievements via a string regex (`levelFromAchievementId`)
- Cross-reference each new achievement against `quest.achievementId` to detect pairs and consume one quest grant per achievement
- Diff cosmetic dispatch results against the already-attached cosmetic id set so orphans don't double-celebrate
- Re-iterate quest grants for standalone celebrations

This logic is **part evaluator, part presenter**. The brief calls it out as "celebration knows too much"; today it's also the only place that knows how to pair a quest+achievement into one event, which is presentation logic leaking into the data layer.

### 2.6 Social → progression leak (the most cited problem)

15 distinct imports from [lib/features/social/](../lib/features/social/) into [lib/features/progression/](../lib/features/progression/) (grep: `import.*progression`):

| Social file | What it imports |
|---|---|
| `social_profile_utils.dart` | `ProgressionAchievementCatalog`, `progression_models.dart`, `ProgressionRuleCatalog` |
| `social_provider.dart` | `progression_models.dart`, `progression_provider.dart` |
| `social_profile_achievement_grid.dart` | `progression_models.dart`, `ProgressionRuleCatalog` |
| `social_profile_header.dart` | `progression_provider.dart`, `level_config.dart`, `progression_level_badge.dart` |
| `social_user_profile_sheet.dart` | `level_config.dart`, `progression_models.dart`, `progression_level_badge.dart` |
| `social_friends_tab.dart` | `level_config.dart` |
| `social_profile_friends_section.dart` | `level_config.dart` |
| `social_feed_card.dart` | `achievement_catalog.dart` |
| `social_lv_badge.dart` | `progression_level_badge.dart` |
| `social_leaderboard_tab.dart` | `progression_provider.dart` |

The hot spot is [social_profile_utils.dart `mapSocialAchievementsToProgression()`](../lib/features/social/presentation/social_profile_utils.dart#L52) — it takes Firestore-shaped `SocialUnlockedAchievement` records and reconstructs `ProgressionAchievement` instances by looking up the local catalog, falling back to a synthetic instance with `Rarity.common` and `criterionType: rewardCountAtLeast` when no definition exists. This means:

- Renaming/removing an achievement id silently breaks friend profile rendering for users who unlocked it under the old id.
- Social pages can never render an achievement the local app doesn't know about (e.g. friend on a newer build, or an achievement that has been deleted in V2).
- All UI display branches (`friendAchievementCompactSummary` switching on `ProgressionAchievementCriterionType`) would have to be updated each time a new criterion is added.

### 2.7 Snapshot resolution duplicated between achievement evaluator and cosmetic dispatch

`ProgressionAchievementEvaluator` reads quest grants, evaluations, streaks, profile to compute achievement values. `CosmeticUnlockSnapshotExtractor` does almost the same to feed cosmetic rule evaluation. The shared `PerfectPeriodEvaluator` was extracted to fix one specific divergence (perfect days), but the broader duplication remains.

### 2.8 Devtools and factory reset only know about progression-as-it-is

[devtools_progression_section.dart](../lib/features/devtools/presentation/sections/devtools_progression_section.dart) and [devtools_user_data_purge_service.dart](../lib/features/devtools/application/factory_reset/devtools_user_data_purge_service.dart) use the legacy provider API (`devToolsResetEverything`, `devToolsSetTotalXp`, `devToolsGrantAchievement`). Any V2 has to provide an equivalent surface or the devtools panel breaks.

### 2.9 No catalog validator

There is no automated check that quest `achievementId` references resolve, that prerequisite quest ids exist, that cosmetic ids are real, that chapter ids are coherent (open + finale + members), or that level cosmetic ids match the cosmetics catalog. Bugs surface as silent runtime no-ops.

### 2.10 Localization is well-handled — keep the pattern

[progression_localized_extensions.dart](../lib/features/progression/domain/progression_localized_extensions.dart) and the `ProgressionLocalizedText` typedef (function `(AppLocalizations) → String`) mean every catalog title/description is one closure, resolved at render time. No string literals in catalogs. **Don't break this pattern in V2.**

---

## 3. Recommended V2 Module / Folder Structure

Build V2 as a sibling of legacy progression. Suggested location:

```
lib/features/progression_engine/
├── README.md
├── domain/
│   ├── models/
│   │   ├── objective_definition.dart        # pure machine condition
│   │   ├── progression_node_definition.dart # player-facing node
│   │   ├── reward_definition.dart           # explicit reward types
│   │   ├── unlock_condition.dart            # gating predicate
│   │   ├── claim_policy.dart                # automatic | manual
│   │   ├── content_tag.dart                 # core | rpg | ...
│   │   ├── activation_policy.dart           # always | rpgOnly | ...
│   │   ├── progression_metric.dart          # reused / re-exported
│   │   ├── progression_period.dart          # reused
│   │   ├── progression_resolution_result.dart
│   │   ├── progression_resolution_reason.dart
│   │   ├── ledger_event.dart
│   │   └── node_state.dart                  # locked|available|completed|claimed
│   ├── catalog/
│   │   ├── objective_catalog.dart
│   │   ├── progression_node_catalog.dart
│   │   ├── chapter_catalog.dart             # if chapters have their own metadata
│   │   └── catalog_validator.dart
│   ├── evaluator/
│   │   ├── objective_evaluator.dart
│   │   ├── progression_node_resolver.dart
│   │   ├── unlock_condition_resolver.dart
│   │   └── reward_grant_planner.dart
│   ├── policy/
│   │   ├── level_policy.dart                # may reuse legacy
│   │   ├── streak_policy.dart               # may reuse legacy
│   │   └── reward_finalization_policy.dart  # may reuse legacy
│   ├── repository/
│   │   ├── progression_engine_repository.dart   # interface
│   │   └── progression_engine_local_repository.dart # devtools surface
│   └── display/
│       ├── progression_display_resolver.dart # the social-facing facade
│       └── progression_display_snapshot.dart # serializable display payload
├── application/
│   ├── progression_engine.dart           # orchestrator
│   ├── progression_engine_provider.dart         # ChangeNotifier wrapper
│   ├── progression_engine_source.dart           # source interface
│   ├── reward_grant_service.dart            # actual mutation of ledger
│   └── cosmetic_unlock_bridge.dart          # progression_engine → cosmetics
├── data/
│   ├── local/
│   │   ├── progression_engine_database.dart
│   │   ├── progression_engine_local_models.dart
│   │   └── progression_engine_local_models.g.dart
│   ├── firestore/
│   │   └── progression_engine_firestore_mapper.dart
│   ├── progression_engine_repository_impl.dart
│   └── provider_progression_engine_source.dart
└── presentation/
    └── (filled in Phase 6)
```

Adapter hub for celebration (lives in the `celebration` feature, not under `progression_engine`):

```
lib/features/celebration/application/
└── progression_engine_celebration_adapter.dart  # consumes ProgressionResolutionResult
```

Adapter hub for social (lives in `social`):

```
lib/features/social/application/
└── progression_display_consumer.dart        # uses ProgressionDisplayResolver only
```

---

## 4. Proposed Core Domain Model

### 4.1 ObjectiveDefinition

A pure, machine-readable condition. **No UI, no rewards, no rarity, no display strings.**

```dart
class ObjectiveDefinition {
  const ObjectiveDefinition({
    required this.id,
    required this.metric,
    required this.scope,
    required this.operator,
    required this.targetValue,
    this.upperTargetValue,
    this.toleranceRatio = 0,
    this.window,
    this.debugLabel,
  });

  final String id;
  final ObjectiveMetric metric;          // steps, calories, level, xp, questsCompleted, ...
  final ObjectiveScope scope;            // today, thisWeek, lifetime, currentChapter, rolling7d, ...
  final ObjectiveOperator operator;      // atLeast, atMost, between, withinTolerance
  final double targetValue;
  final double? upperTargetValue;
  final double toleranceRatio;
  final ObjectiveWindow? window;         // for rolling-window objectives
  final String? debugLabel;
}
```

`ObjectiveMetric` is the union of every measurable input: legacy `ProgressionMetric` plus `level`, `totalXp`, `rewardCount`, `streakDays`, `questCompletions(category)`, `achievementUnlocked(id)`, `nodeCompleted(id)`, `chapterCompleted(id)`. Adding a new metric is a single enum case + a single resolver case.

One objective = one condition. No composite objectives — composition lives at the node level via `UnlockCondition.allOf` (see 4.4).

### 4.2 ProgressionNodeDefinition (sealed hierarchy)

The player-facing meaning of a completed objective or unlock condition. **The single home for display + reward metadata** that today is scattered across quest/achievement/level/chapter.

Rather than one monolithic `ProgressionNodeDefinition` with 35+ optional fields gated by a `type` enum (the original V1 mistake), V2 uses a Dart 3 **sealed hierarchy** so each node type carries only the fields it actually needs and the evaluator/display layer get exhaustive `switch` checking for free.

```dart
sealed class ProgressionNode {
  const ProgressionNode({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.rewards,
    this.unlockConditions = const [],
    this.claimPolicy = ClaimPolicy.automatic,
    this.activationPolicy = ActivationPolicy.always,
    this.contentTags = const [],
    this.rarity = Rarity.common,
    this.lockedHintKey,
    this.assetKey,
    this.visualDomain,
    this.sortOrder = 0,
  });

  final String id;
  final ProgressionLocalizedText titleKey;
  final ProgressionLocalizedText descriptionKey;
  final List<RewardDefinition> rewards;
  final List<UnlockCondition> unlockConditions;
  final ClaimPolicy claimPolicy;
  final ActivationPolicy activationPolicy;
  final List<ContentTag> contentTags;
  final Rarity rarity;                            // single grading axis (no difficultyScore, no Difficulty enum)
  final ProgressionLocalizedText? lockedHintKey;
  final String? assetKey;
  final ProgressionDomain? visualDomain;
  final int sortOrder;
}

class QuestNode extends ProgressionNode {
  const QuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    required this.displayBucket,           // daily, weekly, chapter, longTerm
    this.chainId,
    this.chainOrder,
    this.chapterId,
    this.displayGroupId,
    this.comboPoolId,                      // references ComboPoolDefinition (see §4.6)
    this.dailyTierGroupId,                 // for tiered daily slots (see §4.7); replaces dailySequenceId/Step
    this.dailyTier,                        // 1, 2, 3 — which tier within the group this quest is
    this.progressStartPolicy = ProgressStartPolicy.lifetime,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.visualDomain,
    super.sortOrder,
  });

  final String objectiveId;
  final QuestDisplayBucket displayBucket;
  final String? chainId;
  final int? chainOrder;
  final String? chapterId;
  final String? displayGroupId;
  final String? comboPoolId;
  final String? dailyTierGroupId;
  final int? dailyTier;
  final ProgressStartPolicy progressStartPolicy;
}

class AchievementNode extends ProgressionNode {
  const AchievementNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    this.badgeEmoji = '\u{1F3C5}',
    super.unlockConditions,
    super.claimPolicy = ClaimPolicy.automatic,    // achievements are always automatic
    super.activationPolicy,
    super.contentTags,
    super.rarity,                                 // single grading axis — no Difficulty enum
    super.assetKey,
    super.sortOrder,
  });

  final String objectiveId;
  final String badgeEmoji;
}

class MilestoneNode extends ProgressionNode {
  const MilestoneNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    required this.journeyMapAnchor,        // shows on the journey map
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.assetKey,
    super.sortOrder,
  });

  final String objectiveId;
  final bool journeyMapAnchor;
}

class LevelMilestoneNode extends ProgressionNode {
  const LevelMilestoneNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.level,
    required this.emoji,
    required this.isTitleBreakpoint,
    required this.isJourneyMapAnchor,
    super.contentTags,
    super.rarity,
  });

  final int level;
  final String emoji;
  final bool isTitleBreakpoint;
  final bool isJourneyMapAnchor;
}

class ChapterCompletionNode extends ProgressionNode {
  const ChapterCompletionNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.chapterId,
    required super.unlockConditions,       // typically AllOf(NodeCompleted(...) for each chapter quest)
    super.activationPolicy,
    super.contentTags,
    super.rarity,
  });

  final String chapterId;
}

class CompanionAvailabilityNode extends ProgressionNode {
  const CompanionAvailabilityNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,                // typically [CompanionAvailabilityReward(companionId)]
    required this.companionId,
    required super.unlockConditions,       // requirements that must be met
    super.contentTags = const [ContentTag.rpg, ContentTag.companions],
    super.rarity,
    super.lockedHintKey,
  })  : super(claimPolicy: ClaimPolicy.manual); // companions ALWAYS manual-claim

  final String companionId;
}

class RelicNode extends ProgressionNode {
  const RelicNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,                // typically [RelicReward(relicId)]
    required this.relicId,
    required super.unlockConditions,
    super.contentTags = const [ContentTag.rpg, ContentTag.relics],
    super.rarity,
  })  : super(claimPolicy: ClaimPolicy.automatic); // relics auto-unlock; no claim step

  final String relicId;
}

class ContentUnlockNode extends ProgressionNode {
  const ContentUnlockNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,                // typically [ChapterUnlockReward(chapterId)]
    required super.unlockConditions,
    super.contentTags,
    super.rarity,
  });
}
```

The evaluator branches on `objectiveId != null` vs `unlockConditions.isNotEmpty` vs both. The display layer + celebration adapter `switch` on the sealed type for routing decisions, and the compiler enforces every new node type is handled everywhere.

The catalog returns `List<ProgressionNode>`; concrete subtypes are constructed inline.

### 4.3 RewardDefinition

Explicit, readable, easy to add. No more "XP lives on this field, cosmetics on that field, next-chapter unlock implicit in a sibling node."

```dart
sealed class RewardDefinition {
  const RewardDefinition({this.contentTags = const []});
  final List<ContentTag> contentTags;
}

class XpReward extends RewardDefinition {
  const XpReward({required this.amount, super.contentTags});
  final int amount;
}

class CosmeticReward extends RewardDefinition {
  const CosmeticReward({required this.cosmeticId, super.contentTags});
  final String cosmeticId;
}

class ChapterUnlockReward extends RewardDefinition {
  const ChapterUnlockReward({required this.chapterId, super.contentTags});
  final String chapterId;
}

class CompanionAvailabilityReward extends RewardDefinition {
  const CompanionAvailabilityReward({required this.companionId, super.contentTags});
  final String companionId;
}

class TitleReward extends RewardDefinition {
  const TitleReward({required this.titleId, super.contentTags});
  final String titleId;
}

class EmblemReward extends RewardDefinition {
  const EmblemReward({required this.emblemId, super.contentTags});
  final String emblemId;
}

class RelicReward extends RewardDefinition {
  const RelicReward({required this.relicId, super.contentTags});
  final String relicId;
}
```

Sealed class + `switch (reward)` exhaustiveness in Dart 3 means a new reward type can't silently slip past the dispatcher or celebration mapper.

Rewards are inline on nodes (no separate reward catalog). A node has `List<RewardDefinition> rewards`.

### 4.4 UnlockCondition

Composable predicate. Replaces the scattered "level X required", "prerequisite quest Y", "chapter Z started" gates.

```dart
sealed class UnlockCondition {
  const UnlockCondition();
}

class LevelAtLeast extends UnlockCondition {
  const LevelAtLeast(this.level);
  final int level;
}

class ObjectiveCompleted extends UnlockCondition {
  const ObjectiveCompleted(this.objectiveId);
  final String objectiveId;
}

class NodeCompleted extends UnlockCondition {
  const NodeCompleted(this.nodeId);
  final String nodeId;
}

class ChapterUnlocked extends UnlockCondition {
  const ChapterUnlocked(this.chapterId);
  final String chapterId;
}

class CompanionAvailable extends UnlockCondition {
  const CompanionAvailable(this.companionId);
}

class RpgModeEnabled extends UnlockCondition {
  const RpgModeEnabled();
}

class AllOf extends UnlockCondition {
  const AllOf(this.conditions);
  final List<UnlockCondition> conditions;
}

class AnyOf extends UnlockCondition {
  const AnyOf(this.conditions);
  final List<UnlockCondition> conditions;
}
```

### 4.5 ClaimPolicy + ActivationPolicy + ContentTag

```dart
enum ClaimPolicy {
  automatic,   // node completion immediately grants rewards (achievements, milestones, normal quests)
  manual,      // node becomes "available", player taps to claim (companions, inventory unlocks, optional rewards)
}

enum ActivationPolicy {
  always,                     // core progression — runs regardless of RPG mode
  onlyWhenRpgEnabled,         // rpg-only nodes; if RPG off, hidden but historical state preserved
  onlyWhenRpgEnabledNoBackfill, // rpg-only and never retroactively granted (optional stricter mode)
}

enum ContentTag {
  core,
  rpg,
  fitness,
  journey,
  cosmetics,
  relics,
  companions,
  social,
}
```

The brief explicitly calls out manual companion claim as the test case: requirements met → companion is `available`, player must tap to actually equip/unlock.

### 4.6 ComboPoolDefinition

First-class catalog entity for combo / triple-combo quest mechanics. Replaces V1's hard-coded combo quest id sets in `ProgressionAchievementEvaluator`.

```dart
class ComboPoolDefinition {
  const ComboPoolDefinition({
    required this.id,
    required this.titleKey,
    required this.questIds,           // quests that participate in this pool's rotation
    required this.rotationPolicy,     // daily, weekly, manual
    this.contentTags = const [ContentTag.core],
  });

  final String id;
  final ProgressionLocalizedText titleKey;
  final List<String> questIds;
  final ComboRotationPolicy rotationPolicy;
  final List<ContentTag> contentTags;
}

enum ComboRotationPolicy { daily, weekly, manual }
```

`QuestNode.comboPoolId` references one of these. The active group within a pool for the current period is persisted in `ActiveSelectionRecord` (see §6) — selection survives across sessions.

**Achievement integration.** Achievements that count combo completions reference the *pool id*, not a hard-coded id list. New criterion shape:

```dart
class ComboCompletionsObjective extends ObjectiveDefinition {
  // metric: comboPoolCompletions(comboPoolId)
  // operator: atLeast
  // targetValue: 5
}
```

Adding a new combo pool: one entry in `ComboPoolCatalog`, one quest tag bump on the participating quests, no edits to evaluators or achievements that count combos. Triple-combo is just a pool of pools — implementation detail of the metric resolver.

### 4.7 TieredDailyConfig

Replaces V1's `dailySequenceId` / `dailySequenceStep` rotation. Each daily slot has 2–3 tier variants; the engine picks one tier per period based on player state.

```dart
class TieredDailyConfig {
  const TieredDailyConfig({
    required this.groupId,
    required this.titleKey,
    required this.tiers,              // tier 1 = easiest, last = hardest
    this.selectionPolicy = TierSelectionPolicy.byLevel,
  });

  final String groupId;
  final ProgressionLocalizedText titleKey;
  final List<TieredDailyTier> tiers;
  final TierSelectionPolicy selectionPolicy;
}

class TieredDailyTier {
  const TieredDailyTier({
    required this.tier,               // 1, 2, 3
    required this.questId,
    required this.minLevel,           // engine picks the highest tier whose minLevel <= player.level
  });

  final int tier;
  final String questId;
  final int minLevel;
}

enum TierSelectionPolicy {
  byLevel,         // pick highest tier with minLevel <= player.level
  byYesterday,     // bump tier if yesterday's quest was completed; drop one if missed
  random,          // weighted random — rare, mostly for testing
}
```

Each `QuestNode` referenced in a tier carries `dailyTierGroupId` + `dailyTier` so the resolver can find its parent group. The chosen tier per period is persisted in `ActiveSelectionRecord`.

**Why this replaces sequences.** Sequences modeled "ramp up over multiple days as state". Tiered dailies model "right level for today" without persisted step state — same player effect (variability + difficulty ramp), simpler implementation. Engine becomes stateless w.r.t. sequence position; only the tier roll persists.

### 4.8 ProgressionResolutionResult

The canonical evaluation output. **The only thing other features (UI, celebration, social, devtools, future cloud) consume.**

```dart
class ProgressionResolutionResult {
  const ProgressionResolutionResult({
    required this.runId,
    required this.reason,
    required this.profile,
    required this.completedObjectives,
    required this.completedNodes,
    required this.availableNodes,
    required this.grantedRewards,
    this.skippedEvents = const [],
    this.warnings = const [],
  });

  final String runId;
  final ProgressionResolutionReason reason;
  final ProgressionProfile profile;
  final List<ObjectiveCompletion> completedObjectives;
  final List<NodeCompletion> completedNodes;
  final List<NodeAvailability> availableNodes;       // for manual-claim nodes
  final List<RewardGrant> grantedRewards;
  final List<SkippedEvent> skippedEvents;            // e.g. duplicate idempotent grants
  final List<ResolutionWarning> warnings;            // catalog issues caught at runtime
}

enum ProgressionResolutionReason {
  liveUpdate,              // user did a thing, recomputed
  manualRefresh,
  backgroundSync,
  historicalResync,        // bulk import, suppress noisy celebrations
  devTool,
  factoryResetSeed,        // welcome flow
  claim,                   // result from a manual claim action
}
```

This is the type the celebration mapper, social facade, and devtools all consume. They never look at the engine internals.

### 4.9 LedgerEvent (persisted record)

```dart
sealed class LedgerEvent {
  const LedgerEvent({required this.eventKey, required this.timestamp});
  final String eventKey;
  final DateTime timestamp;
}

class ObjectiveCompletionEvent extends LedgerEvent { ... }
class NodeCompletionEvent extends LedgerEvent { ... }
class NodeClaimEvent extends LedgerEvent { ... }       // for manual-claim nodes
class RewardGrantEvent extends LedgerEvent { ... }
class ChapterStartEvent extends LedgerEvent { ... }    // optional, may be derivable
```

`eventKey` is deterministic and unique — same shape as today, but normalized:

```text
objective|{objectiveId}|{periodKey?}|completed
node|{nodeId}|{periodKey?}|complete
node|{nodeId}|{periodKey?}|claim
reward|{nodeId}|{rewardOrdinal}|{periodKey?}|grant
```

The only difference from legacy keys is that `node` replaces both `quest` and `achievement` since they're the same concept now.

---

## 5. Proposed Evaluation Flow

```text
Source data (snapshots, profile, prior ledger)
  ↓
ObjectiveEvaluator
  • For each ObjectiveDefinition: read metric for scope, compare against operator+target.
  • Output: Map<objectiveId, ObjectiveOutcome { value, completed, period? }>
  ↓
UnlockConditionResolver
  • Given current node states + objective outcomes + profile:
    resolves AllOf/AnyOf/LevelAtLeast/etc. to bool per node.
  ↓
ProgressionNodeResolver
  • For each node: combines objective outcome + unlock conditions + claim policy
    + existing ledger to decide:
      - locked / available / completed (automatic) / completed-but-unclaimed (manual)
  • Emits NodeCompletion / NodeAvailability events for state transitions only.
  ↓
RewardGrantPlanner
  • For each newly-completed (automatic) or freshly-claimed (manual) node:
    plans RewardGrant for each reward in node.rewards.
  • Idempotent: skips if reward eventKey already in ledger (returns SkippedEvent).
  ↓
RewardGrantService
  • Persists ledger events (single Isar transaction).
  • Applies XP scaling for XpReward via LevelPolicy at the running running-XP point.
  • Calls CosmeticUnlockBridge for CosmeticReward.
  ↓
ProgressionResolutionResult
  • Canonical output with runId, reason, all granted rewards, all transitions.
```

Key invariants:

- **One objective is evaluated once per run.** Multiple nodes can reference the same `objectiveId`; they all read from the single outcome map. No parallel evaluator paths.
- **Idempotency at the planner.** Re-running with no changes produces an empty result. The ledger is the source of truth; everything downstream is derived.
- **Manual claim is a real state.** A node with `ClaimPolicy.manual` whose objective is satisfied emits `NodeAvailability`, not `NodeCompletion`. The player's claim action triggers a second pass that resolves the availability into completion + reward grants.
- **`reason` propagates.** A `historicalResync` run produces a result the celebration layer can compress into one summary instead of N popups.

---

## 6. Proposed Ledger / Persistence Design

Because there are no production users and no migration is required, V2 gets a clean slate. New Isar collections (so V1 and V2 can coexist):

| Collection | Key field | Purpose |
|---|---|---|
| `ObjectiveCompletionRecord` | `eventKey` (unique, replace) | Per-period objective outcomes; rebuilt on rule version bump |
| `NodeCompletionRecord` | `eventKey` (unique, no-replace) | Append-only completions |
| `NodeClaimRecord` | `eventKey` (unique, no-replace) | Claim actions (for manual-claim nodes) |
| `RewardGrantRecord` | `eventKey` (unique, no-replace) | All grants (xp, cosmetic, chapter unlock, companion availability, …) |
| `ChapterStartRecord` | `eventKey` (unique, no-replace) | Kept if chapter-start needs to be queryable; otherwise derivable |
| `ActiveSelectionRecord` | `selectionKey` (unique, replace) | Stochastic per-period selections (combo pool rotation, daily sequence step) |
| `ProgressionEngineMetaRecord` | singleton | last evaluation timestamp, schema version |

Reward grant records carry a `rewardKind` discriminator so a single table holds all reward types. Claim-time XP scaling fields (`finalXp`, `levelAtClaim`, `multiplierAtClaim`) only populate for `XpReward`.

**ActiveSelectionRecord** (replaces legacy `ProgressionActiveQuestRecord`) — persisted, not derived. The legacy active-quest set looks like a UI cache, but it actually carries **stochastic state that must survive sessions**:

- `comboPoolId` rotation: which group within a combo pool is active for this user *today*
- `dailySequenceId` step: which step (1/2/3) of a daily sequence the user is currently on
- Manual chapter pin (if/when added)

Recomputing these on every load would re-roll the daily quest selection between app launches. The selection record is small and bounded (one row per active selection key). Schema:

```dart
@Collection()
class ActiveSelectionRecord {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String selectionKey;     // e.g. "comboPool|fitness_combo|2026-05-10" or "dailySequence|steps_seq|2026-05-10"
  late String selectedValue;    // group id, step number, etc.
  late DateTime assignedAt;
  late DateTime expiresAt;      // for daily-scoped selections
}
```

The `availableNodes` list in `ProgressionResolutionResult` *is* derived from current ledger + active selections + objective outcomes, but the selection rolls themselves are persisted by the engine on first computation per period.

Repository abstraction mirrors V1:

```dart
abstract class ProgressionEngineRepository {
  Future<LedgerSnapshot> loadLedger();
  Future<LedgerSnapshot> persistEvents(List<LedgerEvent> events);
  Future<LedgerSnapshot> claim({required String nodeId, ...});
}

abstract class ProgressionEngineLocalRepository extends ProgressionEngineRepository {
  Future<void> wipeAll();
  Future<void> insertSyntheticReward(...); // devtools
}
```

Cloud overlay (Firestore) can wrap the local repo with a hybrid like today's `HybridProgressionRepository`. Defer to Phase 9.

---

## 7. Catalog Design and Validator Rules

### 7.1 Catalogs

```dart
class ObjectiveCatalog {
  const ObjectiveCatalog();
  List<ObjectiveDefinition> build(ProgressionGoalSet goals) { ... }
  static ObjectiveDefinition? definitionForId(String id) => ...;
}

class ProgressionNodeCatalog {
  const ProgressionNodeCatalog();
  List<ProgressionNode> build() { ... }            // sealed nodes; see §4.2
  static ProgressionNode? definitionForId(String id) => ...;
}

class ChapterCatalog { ... }                        // chapter id, title, theme, order, member node ids
class ComboPoolCatalog { ... }                      // see §4.6
class TieredDailyCatalog { ... }                    // see §4.7
```

Each catalog is a constant `build()` that returns a const-list of definitions. Same pattern as today, but the definitions are smaller and authored together (objective + nodes that reference it co-located in the file for grep-ability).

### 7.2 Catalog Validator

A pure validator run at app startup in debug, optionally as a CI test target. Fails fast with a thrown `CatalogValidationException` listing every issue.

Checks:

1. **Identity** — duplicate objective ids; duplicate node ids; duplicate combo pool ids; duplicate tiered daily group ids; duplicate reward ordinals within a node.
2. **References** — every `node.objectiveId` resolves; every `UnlockCondition` reference (`ObjectiveCompleted`, `NodeCompleted`, `ChapterUnlocked`, `CompanionAvailable`) resolves; every `CosmeticReward.cosmeticId` resolves against `CosmeticCatalog`; every `QuestNode.comboPoolId` resolves to a `ComboPoolDefinition`; every `QuestNode.dailyTierGroupId` resolves to a `TieredDailyConfig`.
3. **Chapter integrity** — every `chapterId` referenced by a node exists in `ChapterCatalog`; chapter has at least one entry node and one completion node.
4. **Reward × policy coherence** — `ClaimPolicy.manual` nodes must have a `lockedHintKey` (so the player knows what to do); `CompanionAvailabilityNode` is `ClaimPolicy.manual` by construction (compiler-enforced); `RelicNode` is `ClaimPolicy.automatic` by construction; nodes tagged `core` must not contain RPG-only rewards unless `ActivationPolicy != always`.
5. **Display coverage** — visible nodes (not `displayBucket: hidden`) must have non-empty `titleKey` and `descriptionKey`; `lockedHintKey` recommended.
6. **Chain coherence** — all nodes sharing a `chainId` form a strict order via `chainOrder`; no cycles; no gaps.
7. **Localization** — every `*Key` closure resolves to a non-empty string for all supported locales (the closure system already enforces this at compile time, so this is a smoke test).
8. **Activation × content tag** — `ActivationPolicy.onlyWhenRpgEnabled` nodes must have `ContentTag.rpg` (or some RPG-flavored tag); avoid drift between the two axes.
9. **ComboPool integrity** — every `questId` in `ComboPoolDefinition.questIds` resolves to a real `QuestNode`; every `QuestNode.comboPoolId` exists; rotation policy is consistent (e.g. all combo pools referenced by daily achievements are `daily`).
10. **TieredDaily integrity** — `TieredDailyConfig.tiers` are ordered by tier number; `minLevel` is monotonically non-decreasing across tiers; every `questId` resolves; every `QuestNode.dailyTierGroupId` exists.

The validator is invoked from `ProgressionEngine` constructor in debug builds via `assert(...)`, and as a test in `test/features/progression_engine/catalog_validator_test.dart`.

---

## 8. Celebration Integration Plan

Today the queueing logic lives inside `ProgressionProvider._queueCelebrations()` and the adapter inside `ProgressionCelebrationAdapter`. The brief asks for celebration to be a *renderer* of resolved events, not an evaluator.

### 8.1 Target shape

```text
ProgressionEngine.sync() → ProgressionResolutionResult
  ↓
ProgressionEngineCelebrationAdapter.convert(result) → List<CelebrationEvent>
  ↓
ProgressionEngineProvider.pendingCelebrations (queue)
  ↓
CelebrationOverlayHost (existing) → fullscreen / topsheet variant
```

The provider owns the queue but **does not synthesize events itself**. The adapter's `convert(ProgressionResolutionResult)` is pure: same input → same output, no diffing.

### 8.2 Event grouping rules (codified in adapter, not provider)

The adapter knows:

- A `NodeCompletion` of type `levelMilestone` with no extra rewards is suppressed unless `levelHasTitleBreakpoint(level)` or there are level cosmetics.
- A `NodeCompletion` with `claim != null` (`ClaimPolicy.manual` node entering availability) renders the gold "Vyzvednout +XP" pill.
- Multiple `NodeCompletion` events that share a chain or chapter are grouped into a single celebration when the result reason indicates a bulk run (historicalResync, factoryResetSeed).
- `reason: historicalResync` or `factoryResetSeed` ⇒ aggregate into a single compact summary (no per-event popups).

### 8.3 Display ordering (as per brief)

When multiple events land in one resolution:

1. Level up
2. Milestone reached
3. Chapter / content unlocked
4. Quest completed
5. Achievement unlocked
6. Reward granted (orphan)
7. Companion available

The adapter sorts the result before emitting. XP is aggregated visually per-celebration; cosmetics/relics/emblems/chapters/companions are shown individually.

### 8.4 Migration path

- Phase 5 introduces `ProgressionEngineCelebrationAdapter` next to the existing `ProgressionCelebrationAdapter`.
- `CelebrationOverlayHost` already consumes `CelebrationEvent` shapes — no change needed there.
- During migration, both adapters coexist; the legacy provider feeds the legacy adapter, the V2 provider feeds the V2 adapter, and the host queues from both (or the app shell switches based on a build-time flag).
- Phase 9 deletes the legacy adapter + `ProgressionCelebrationEvent`.

---

## 9. Social Integration Plan

The 15 social → progression imports are the largest single dependency leak. The plan is to introduce a **`ProgressionDisplayResolver` facade** before touching any UI, so social can be cut over without rewriting the social UI.

### 9.1 ProgressionDisplayResolver

```dart
class ProgressionDisplayResolver {
  const ProgressionDisplayResolver({...});

  // Levels — replaces level_config.dart imports
  LevelDisplay levelDisplay(int level);
  Iterable<LevelMilestoneDisplay> levelMilestones(); // for journey map

  // Nodes — replaces achievement_catalog.dart and rule_catalog.dart imports
  NodeDisplay? nodeDisplay(String nodeId, AppLocalizations l10n);
  Iterable<NodeDisplay> friendNodeDisplays(
    Iterable<SocialUnlockedAchievement> friendUnlocks,
    AppLocalizations l10n,
  );

  // Compact strings — replaces friendAchievementCompactSummary
  String compactSummary(NodeDisplay node, AppLocalizations l10n, String locale);
}

class NodeDisplay {
  final String nodeId;
  final ProgressionLocalizedText title;
  final ProgressionLocalizedText description;
  final ProgressionLocalizedText? lockedHint;
  final Rarity rarity;
  final ContentTag primaryTag;
  final String? badgeAssetKey;
  final List<String> rewardSummaries;
  final DateTime? unlockedAt;
}
```

The resolver is the **only** progression-facing type social imports. It sits in `lib/features/progression_engine/domain/display/`. The cloud-shaped `SocialUnlockedAchievement` remains untouched (Firestore is append-only friend data) but the resolver is responsible for translating it into a `NodeDisplay`.

### 9.2 Snapshot-vs-live (hybrid, per surface)

Different social surfaces have different semantics — historical vs current state — so they use different resolution strategies.

| Surface | Strategy | Why |
|---|---|---|
| **Activity feed** | Snapshot at publish | Feed is a record of what happened *then*. Renaming an achievement in the new engine should not rewrite history. |
| **Friend profile achievement grid** | Live resolution | Profile shows what the friend has *now*. Live lookup means typo fixes / display tweaks propagate immediately. |
| **Leaderboard** | Live | Only level/XP — no node-id semantics. |
| **Friend notifications** | Snapshot at publish | Same reasoning as feed. |

**Snapshot shape** — added to every published `SocialActivityEvent`:

```dart
class SocialActivitySnapshot {
  final String titleAtPublish;
  final String descAtPublish;
  final String rarityAtPublish;        // enum name string
  final String? assetPathAtPublish;
  final String contentTagPrimary;      // for icon / category coloring
}
```

**Receiver behavior** — feed renderer reads snapshot first. If snapshot is missing (legacy event from before snapshots were introduced), fall back to `ProgressionDisplayResolver.nodeDisplay(nodeId)`. If resolver also returns null (unknown id), render a generic "Achievement unlocked" tile with the publish timestamp.

**Profile grid** — always live. Unknown id → "Unknown achievement" tile with the unlock timestamp; do not synthesize a fake `ProgressionAchievement` instance the way V1 does today.

### 9.3 Migration path

- Phase 7 introduces `ProgressionDisplayResolver` powered by the V2 catalog.
- Each social file is migrated one at a time:
  1. Replace `import '.../progression/...'` with `import '.../progression_engine/domain/display/...'`.
  2. Replace direct catalog/model usage with `resolver.X(...)` calls.
  3. Remove the now-unused legacy import.
- The legacy `ProgressionAchievementCatalog` is deleted in Phase 9 once all social call sites have moved.

---

## 10. RPG Mode Readiness Plan

The brief is unambiguous: do not build the toggle UI yet, but design the engine so flipping a setting can hide RPG-flavored content without re-running progression in a different mode.

### 10.1 Two axes of control

- **`ContentTag`** on every node and reward — declarative metadata.
- **`ActivationPolicy`** on every node — behavioral.

### 10.2 Behavior matrix

| RPG setting | Node activation | Display filter | Notes |
|---|---|---|---|
| RPG **on** | All policies eligible | Show everything tagged anything | Default for current users |
| RPG **off** | `always` eligible; `onlyWhenRpgEnabled` skipped during evaluation; `onlyWhenRpgEnabledNoBackfill` skipped *and* never granted retroactively | Hide nodes tagged only with `rpg`/`relics`/`companions`/etc. (no `core` overlap) | Core fitness progression continues |

`ActivationPolicy.onlyWhenRpgEnabled` (no `NoBackfill` suffix) means: when RPG is re-enabled later, the engine catches up the user as if it had been on (idempotent ledger pass).

`ActivationPolicy.onlyWhenRpgEnabledNoBackfill` means: missed while off ⇒ stays missed. Use this for time-limited chapter content or "ironman" style modes if they ever exist.

### 10.3 Where the filter lives

- **Engine evaluation** — applies activation policy. Honest about what's actually granted.
- **Display layer** — applies content-tag filter for rendering. A user who turned RPG off then back on may have RPG ledger entries from before the toggle; the display layer hides the RPG section while RPG is off, but the ledger keeps the data.
- **Celebration adapter** — uses the same content-tag filter; doesn't celebrate RPG events while RPG is off.
- **Social publisher** (future) — same filter; doesn't emit RPG-flavored events to friends while RPG is off.

### 10.4 What does *not* happen

- No `if (rpgModeEnabled) { ... }` checks scattered across UI widgets.
- No second engine, no second catalog, no engine fork.
- No "RPG-aware" copies of node types.

The RPG setting is one boolean read by the activation evaluator and the display filter. Everything else is data.

---

## 11. Factory Reset / No-Migration Assumptions

### 11.1 Explicit assumptions

- No production users → no upgrade path required.
- All existing progression state, achievement unlocks, quest reward grants, cosmetic unlocks, ledger keys, chapter starts, and active-quest persistence may be discarded.
- Welcome flow (welcome_to_journey, level 1 starter cosmetics) is acceptable to re-trigger after factory reset.
- Social Firestore data referencing old node ids is acceptable to break — friend achievement grids can render "Unknown" tiles for historical entries until those ids are re-published under new V2 names.

### 11.2 What factory reset must do in V2

`devToolsResetEverythingEngine()` (replaces the legacy `devToolsResetEverything` once the cutover completes; during coexistence both methods exist on different providers):

1. Wipe all V2 Isar collections.
2. Wipe progression-sourced cosmetics inventory (same hook as today).
3. Wipe legacy V1 collections (during the coexistence window).
4. Re-bind sources → engine cold-loads → emits `ProgressionResolutionResult{reason: factoryResetSeed}`.
5. Adapter compresses to a single welcome celebration sequence.

The brief recommends `factoryResetSeed` as a distinct reason so the celebration adapter can hand-craft the welcome sequence (level 1 cosmetics + welcome achievement + journey introduction) instead of cascading dozens of micro-celebrations.

### 11.3 Coexistence window

During Phases 1–8, V1 and V2 Isar collections coexist. The factory reset purge service ([devtools_user_data_purge_service.dart](../lib/features/devtools/application/factory_reset/devtools_user_data_purge_service.dart)) gets a new V2 helper alongside the existing V1 helper, and `Reset everything` wipes both. After Phase 9, the V1 helper and collections are deleted.

---

## 12. Risks and Tradeoffs

### 12.1 Sizing risk — the catalog port is large

The legacy quest catalog is 1918 lines and the achievement catalog is 605. Even with the new model being more uniform, the V2 catalog will be similarly sized. Phase 3 (catalog port) is the riskiest single phase; budget realistically.

**Mitigation:** port catalog in chunks per category (rules → daily quests → weekly quests → chapter quests → achievements → milestones → level milestones). Each chunk is independently validatable.

### 12.2 Coexistence cost

While both engines run, every devtools reset must wipe both ledgers; every UI consumer that hasn't been migrated still talks to V1. The temptation will be to read from V1 in some places and V2 in others, leading to display drift.

**Mitigation:** introduce a single "active engine" feature flag (build-time constant), default to V1 for production code paths until Phase 6 explicitly switches it. Devtools can show both engines side-by-side for diff testing.

### 12.3 Quest evaluator's hidden complexity

The 1607-line quest evaluator handles daily sequences, combo pools, chapter gating, prerequisite resolution, repeatable rewards, dailySequence rotations. Some of this is genuinely complex *game design* (combo pool rotation), not just over-engineered code.

**Mitigation:** in Phase 2, port only the simplest patterns (one-shot quests, chained quests, repeatable daily quests). Defer combo pools and tiered dailies to a dedicated Phase 3 sub-step. Combo mechanic survives but moves to first-class `ComboPoolDefinition` (Q1 decision); daily sequences are *replaced* by tiered dailies, not ported (Q2 decision) — this means the V1 evaluator's daily sequence step persistence is dropped entirely, simplifying the new resolver.

### 12.4 Cosmetic dispatcher's tier-2 fixed-point loop

[cosmetic_unlock_dispatcher.dart:194](../lib/features/progression/application/cosmetic_unlock_dispatcher.dart#L194) bounded fixed-point loop catches compound cosmetic chains (`relic_dragon_scale` → `companion_dragonling`). V2's reward-on-node model can express these as just ordinary rewards on ordinary nodes — but the dispatcher logic must move into the V2 reward grant service.

**Mitigation:** in V2, "compound" cosmetics become `ProgressionNodeDefinition` instances whose unlock condition is "this other node completed". The fixed-point loop becomes a single deterministic resolver pass over the node graph (since the dependency graph is acyclic and small).

### 12.5 Social Firestore field names

Friend data on Firestore stores raw `achievementId` strings keyed to V1 node ids. After Phase 9, the V1 catalog is gone and those ids no longer resolve to anything in the local app.

**Mitigation:** the `ProgressionDisplayResolver`'s "unknown id" fallback (Phase 7) handles this gracefully. Optionally, a one-shot Firestore migration can rewrite legacy ids to V2 ids — but per the brief, this is acceptable to skip.

### 12.6 Test coverage

[test/features/progression/](../test/features/progression/) — there are existing tests for the evaluator, achievements localization, and quest detail view model. V2 will need parallel tests, and during coexistence both suites run.

**Mitigation:** new test suite under `test/features/progression_engine/`. Legacy tests continue passing until Phase 9. The catalog validator test runs in CI from Phase 1 onward.

### 12.7 Levels are weird

Today, levels are not nodes — they're synthesized as achievements (`level_<N>` ids) plus a parallel `ProgressionLevelTier` config plus per-level cosmetic dispatch. In V2 they become first-class `ProgressionNodeType.levelMilestone` nodes. This is conceptually cleaner but means three different code paths that today read level info must be reconciled.

**Mitigation:** Phase 1 introduces `levelMilestone` nodes as a thin wrapper over `ProgressionLevelTier` data so the same level table feeds both V1 (synthesized achievements) and V2 (level nodes). Phase 9 can then delete `kProgressionLevelTiers` entirely or keep it as a build-time data source for the V2 node catalog.

### 12.8 Tradeoff: sealed RewardDefinition vs. inline reward fields

Sealed-class rewards are more verbose to author than today's `cosmeticRewards: ['frame_x']` shorthand. The win is exhaustiveness checking; the cost is more boilerplate per node.

**Mitigation:** const constructors + a small set of factory helpers (`Rewards.xp(100)`, `Rewards.cosmetic('frame_x')`) keep authoring concise. The brief explicitly prefers explicit/readable over clever, so pay the small verbosity tax.

---

## 13. Concrete Implementation Phases

Each phase keeps the app compiling and the legacy progression system functional. Phases 1–4 are non-user-visible; Phase 5 starts visible changes.

### Phase 0 — Read-only audit ✅

Output: this document.

### Phase 0.5 — Display Resolver bridge (decouples social *now*)

The 15 social → progression imports are independent of the V2 redesign. Fixing them first removes the largest dependency leak and unblocks every social PR from now until Phase 9. The resolver lives in V2's eventual location but in this phase reads from the **legacy** catalog — same data, new facade.

Create:

- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` — initially backed by `ProgressionAchievementCatalog` + `kProgressionLevelTiers` + `ProgressionRuleCatalog`.
- `lib/features/progression_engine/domain/display/progression_display_models.dart` — `LevelDisplay`, `NodeDisplay`, `LevelMilestoneDisplay` (the same shapes that V2 will produce later).
- `test/features/progression_engine/progression_display_resolver_legacy_backed_test.dart`.

Edit (one social file per commit, in this order — lowest risk first):

1. [social_lv_badge.dart](../lib/features/social/presentation/widgets/social_lv_badge.dart)
2. [social_friends_tab.dart](../lib/features/social/presentation/tabs/social_friends_tab.dart)
3. [social_profile_friends_section.dart](../lib/features/social/presentation/widgets/social_profile_friends_section.dart)
4. [social_profile_header.dart](../lib/features/social/presentation/widgets/social_profile_header.dart)
5. [social_user_profile_sheet.dart](../lib/features/social/presentation/widgets/social_user_profile_sheet.dart)
6. [social_feed_card.dart](../lib/features/social/presentation/widgets/social_feed_card.dart)
7. [social_profile_achievement_grid.dart](../lib/features/social/presentation/widgets/social_profile_achievement_grid.dart)
8. [social_profile_utils.dart](../lib/features/social/presentation/social_profile_utils.dart) — delete `mapSocialAchievementsToProgression`, replace call sites with `resolver.friendNodeDisplays(...)`.
9. [social_provider.dart](../lib/features/social/application/social_provider.dart) — replace `ProgressionProvider` reads with `ProgressionDisplayResolver` reads where possible (level, achievements). `progressionProvider` may still be needed for *own* state — call out exactly what stays.
10. [social_leaderboard_tab.dart](../lib/features/social/presentation/tabs/social_leaderboard_tab.dart).

When V2 catalog goes live in Phase 7, swap the resolver's backing data source (single file change in the resolver) — no further social changes needed.

**Acceptance:**
- Zero direct **catalog / level_config / widget** imports from `progression/` in `social/` (display leak fixed).
- The few remaining `progression/` imports in social are *state* dependencies (`ProgressionProvider`, `ProgressionAchievement` type used by the provider's API, `ProgressionDomain` enum value passed to state queries). These are not display leaks; they will swap to the new provider in Phase 6 once V2 state APIs exist.
- Friend profile rendering visually unchanged (regression-tested with a known friend account).
- Resolver smoke test passes against legacy catalog (every catalog achievement produces a non-null compactSummary + accentColor; every level tier yields a milestone display).
- Note: this phase no longer needs to be repeated in Phase 7 — Phase 7 becomes a single internal swap of the resolver's data source.

### Phase 0.6 — Extract Journey as standalone feature

Journey map is today inside `lib/features/progression/presentation/journey/` but is functionally a pure consumer of progression state — it produces no signals back to the engine. Extracting it now (a) decouples it from the engine for the rest of the migration, (b) establishes the same `ProgressionDisplayResolver`-as-public-API pattern used for social, (c) gives journey room to grow (per-chapter inner maps, map effects via `CosmeticType.mapEffect`, discovery system, mini-maps embedded elsewhere) without touching the engine.

Create:

- `lib/features/journey/README.md`
- `lib/features/journey/domain/journey_models.dart` — moved from `lib/features/progression/domain/journey_models.dart`
- `lib/features/journey/domain/journey_map_layout.dart` — anchor positioning logic extracted from existing journey widgets
- `lib/features/journey/application/journey_view_model.dart` — consumes `ProgressionDisplayResolver`, exposes journey-shaped state to widgets
- `lib/features/journey/presentation/hero_journey_map_screen.dart` — moved from progression
- `lib/features/journey/presentation/journey_map_route.dart` — moved
- `lib/features/journey/presentation/widgets/journey_adapter.dart` — moved
- `lib/features/journey/presentation/widgets/journey_event_feed.dart` — moved
- `lib/features/journey/presentation/widgets/journey_interactive_map.dart` — moved
- `lib/features/journey/presentation/widgets/journey_preview_card.dart` — moved
- `lib/features/journey/presentation/widgets/journey_primitives.dart` — moved
- `test/features/journey/journey_view_model_test.dart`

Edit:

- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` — extend with journey-specific methods: `currentLevel()`, `chapterMilestones()`, `recentlyCompletedNodes({int limit})`, `journeyAnchors()`. Still backed by legacy catalog in this phase.
- `lib/features/progression_engine/domain/display/progression_display_models.dart` — add `ChapterMilestoneDisplay`, `JourneyAnchorPosition`, `RecentCompletionDisplay`.
- `lib/features/app_shell/presentation/main_shell.dart` — update import path for journey route.
- `lib/features/progression/presentation/widgets/progression_home_card.dart` — if it embeds journey preview, update import.
- Any other call site that imports from `progression/presentation/journey/` or `progression/domain/journey_models.dart`.

Delete (after move):

- `lib/features/progression/presentation/journey/` (whole subtree)
- `lib/features/progression/domain/journey_models.dart`

**Acceptance:**
- Zero `import '.../progression/...journey...'` lines remain anywhere outside `lib/features/journey/`.
- Journey map renders identically to before extraction (visual regression check).
- Journey reads only from `ProgressionDisplayResolver` (no direct catalog imports, no `kProgressionLevelTiers` import).
- `flutter analyze` clean; existing journey tests pass with updated imports.

### Phase 1 — V2 domain skeleton

Create `lib/features/progression_engine/` with:

- `domain/models/objective_definition.dart`, `progression_node_definition.dart`, `reward_definition.dart` (sealed), `unlock_condition.dart` (sealed), `claim_policy.dart`, `content_tag.dart`, `activation_policy.dart`, `progression_resolution_result.dart`, `progression_resolution_reason.dart`, `ledger_event.dart` (sealed), `node_state.dart`.
- `domain/catalog/objective_catalog.dart` (empty `build()`), `progression_node_catalog.dart` (empty `build()`), `catalog_validator.dart` (skeleton with at least the duplicate-id check).
- `README.md` explaining the module, status, and pointer to this plan.

**Acceptance:**
- App still compiles.
- `flutter analyze` clean for the new module.
- New test `test/features/progression_engine/catalog_validator_skeleton_test.dart` passes (catches a duplicate id in a synthetic catalog).
- No imports from any other feature into `progression_engine/` yet.

### Phase 2 — V2 evaluation skeleton

- `domain/evaluator/objective_evaluator.dart` — implements at least 3–4 representative metrics (`steps`, `level`, `totalXp`, `questCompletions`).
- `domain/evaluator/unlock_condition_resolver.dart`.
- `domain/evaluator/progression_node_resolver.dart`.
- `domain/evaluator/reward_grant_planner.dart` — produces planned grants without persisting.
- `application/progression_engine.dart` — composes the four evaluators; produces `ProgressionResolutionResult`. Uses an in-memory repository for now.
- `application/reward_grant_service.dart` — applies XP scaling via the existing `ProgressionLevelPolicy`.
- `application/cosmetic_unlock_bridge.dart` — initially a no-op stub.
- DevTools section: a temporary `DevToolsProgressionEngineSection` with two buttons: "Run V2 evaluation" and "Show last result" rendering the result as JSON-ish text.

**Acceptance:**
- DevTools button runs an end-to-end evaluation against a tiny seeded catalog and prints a non-empty `ProgressionResolutionResult`.
- Unit tests cover idempotency: same inputs → same result, no spurious grants on second run.
- Legacy progression unaffected.

### Phase 3 — Catalog port

Port real content from V1 catalogs into new definitions, in this order:

1. Objectives for current rule catalog (one objective per rule, scope = today/thisWeek).
2. Objectives for level/XP-based achievements (`totalXp`, `level`).
3. Objectives for streak achievements.
4. Objectives for quest-completion achievements.
5. Daily-quest nodes (referencing the rule objectives).
6. **Tiered daily configs** — convert V1 `dailySequenceId`/`dailySequenceStep` quests into `TieredDailyConfig` entries with 2–3 tiers each (per Q2 decision).
7. Weekly-quest nodes.
8. **Combo pool definitions** — extract V1 hard-coded combo quest id sets into `ComboPoolCatalog` entries; convert combo-counting achievements to use `comboPoolCompletions(poolId)` metric (per Q1 decision).
9. Chapter chain nodes (chapter open + chapter quests + chapter finale as one chain per chapter).
10. Achievement nodes (referencing existing objectives where possible — explicitly catching the brief's "shared objective" cases). No `Difficulty` field — `Rarity` is the only grading axis (per Q5).
11. Level milestone nodes (one per `kProgressionLevelTiers` entry).
12. Companion-availability nodes (manual claim) and Relic nodes (auto-unlock) — distinct sealed subclasses per Q3.

For each chunk:

- Add validator coverage.
- Add a unit test verifying the catalog builds without validation errors.
- Confirm with user whether each chunk's IDs should be cleaned up (V2 IDs are decoupled from V1; renames are free).

**Acceptance:**
- `progression_engine_catalog_validator_test.dart` passes for the full catalog.
- Cardinality matches expectation (rough parity with V1: same number of daily/weekly quests, same number of achievements, same chapters).
- DevTools "Run V2 evaluation" produces a result whose `availableNodes` includes the same intuitive set as the V1 active quest list.

### Phase 4 — Persistence

- `data/local/progression_engine_local_models.dart` — the new Isar collections.
- `data/local/progression_engine_database.dart`.
- `data/progression_engine_repository_impl.dart`.
- Wire into the app's Isar instance setup (sibling of legacy progression).
- Replace the in-memory repository in the engine.
- Devtools section gains: "Wipe V2 ledger" button.

**Acceptance:**
- A V2 evaluation persisted then reloaded reconstructs the same `ProgressionResolutionResult`.
- Wipe button clears V2 collections without touching V1.
- Existing factory reset flow still works on V1 (V2 wipe is a separate button for now).

### Phase 5 — Celebration integration

- `lib/features/celebration/application/progression_engine_celebration_adapter.dart` — pure transformer from `ProgressionResolutionResult` to `List<CelebrationEvent>`.
- `application/progression_engine_provider.dart` — owns state, exposes `pendingCelebrations` queue powered by the adapter.
- DevTools: a "Trigger V2 celebration" button that runs the adapter on a seeded fake result and pushes events to the existing `CelebrationOverlayHost`.
- Implement `factoryResetSeed` aggregation in the adapter (compresses to a single welcome celebration).

**Acceptance:**
- Devtools "Trigger V2 celebration" shows a celebration that visually matches the V1 equivalent.
- Manual-claim node correctly renders the gold "Vyzvednout" pill; tapping it triggers a second resolution that grants the reward.
- A `historicalResync` reason produces a single compact celebration, not N popups.

### Phase 6 — Progression UI integration

Migrate UI consumers from `ProgressionProvider` to `ProgressionEngineProvider` one screen at a time. Suggested order (smallest blast radius first):

1. `progression_home_card.dart` (simple level/XP rendering).
2. `hero_screen.dart`.
3. `quests_screen.dart` + `quest_screen_sections.dart`.
4. `hero_journey_map_screen.dart` + journey widgets.
5. `main_shell.dart` (the navigation shell).
6. `home/overview_screen.dart`.
7. `onboarding_steps.dart`.
8. `cosmetics_provider.dart` (unlock callback wiring).

For each migration: update imports, replace getters with V2 equivalents, run the screen. Legacy provider remains alive for screens not yet migrated.

**Acceptance:**
- All migrated screens render visually identical content with V2 data.
- No screen reads from both providers simultaneously (avoid drift).
- Build flag flipped: V2 is now the canonical engine for migrated screens.

### Phase 7 — Swap Display Resolver to V2 catalog

Social was already migrated to `ProgressionDisplayResolver` in Phase 0.5. This phase is now a single internal change: swap the resolver's backing data source from the legacy catalog to the V2 catalog.

Edit:
- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` — replace `ProgressionAchievementCatalog.definitionForId(...)` reads with `ProgressionNodeCatalog.definitionForId(...)` reads. Map `ProgressionNode` (sealed) to `NodeDisplay` via exhaustive switch.
- `test/features/progression_engine/progression_display_resolver_v2_backed_test.dart` — replaces the legacy-backed test from Phase 0.5.

**Acceptance:**
- Friend profile rendering still visually unchanged for known V2 nodes.
- Unknown / removed node ids (legacy ids that don't exist in V2) render an explicit "Unknown achievement" tile rather than a synthetic guess.
- Social file count touched in this phase: zero. (All social files were migrated in Phase 0.5.)

### Phase 8 — RPG mode readiness

- Add a `RpgModeProvider` (a thin `ChangeNotifier` over a SharedPreferences-backed bool) — but **no toggle UI**.
- Wire `ActivationPolicy` enforcement into the resolver and display layer.
- Add a hidden devtools toggle: `Devtools → Progression V2 → RPG mode (debug)`.
- Add catalog validator rules linking activation policy to content tags.

**Acceptance:**
- Flipping the devtools RPG toggle hides RPG-tagged nodes from quest screen and journey map without breaking core fitness display.
- Re-enabling RPG retroactively grants any `onlyWhenRpgEnabled` (non-NoBackfill) nodes whose objectives are already complete.
- No `if (rpgModeEnabled)` literals exist in UI files (grep verifies).

### Phase 9 — Remove legacy

- Delete `lib/features/progression/` (or move to `lib/features/_legacy_progression/` for one PR cycle if anyone wants to diff).
- Delete legacy Isar collections from the database setup.
- Delete `ProgressionCelebrationAdapter` and `ProgressionCelebrationEvent`.
- Rename `progression_engine/` → `progression/` (and adapt imports — single sweep with the IDE).
- (No file renames needed in Phase 9 — the new module was named `progression_engine` from Phase 1, so files keep their final names. Just delete the legacy `lib/features/progression/` tree and remove any `as legacy` import prefixes.)
- Update Isar generated bindings.
- Run a final factory reset for any test devices.

**Acceptance:**
- `flutter analyze` clean.
- Full test suite passes.
- App boots into a clean V2 progression state on a test device.
- No file in the repo contains the string `progression_engine` or `ProgressionEngine`.

---

## 14. Acceptance Criteria Summary

| Phase | Hard gate |
|---|---|
| 0.5 | Zero display-related `progression/...` imports in `social/` (only state imports remain, slated for Phase 6); legacy-backed resolver smoke test passes |
| 0.6 | Journey extracted to `lib/features/journey/`; reads only from resolver; visual parity verified |
| 1 | Validator catches duplicate ids; module compiles in isolation |
| 2 | DevTools E2E button runs full evaluation; idempotent on re-run |
| 3 | Full V2 catalog passes validator; node count parity with V1 |
| 4 | Persisted result reloads identically; V2 wipe is independent of V1; active selection persists across restart |
| 5 | V2 celebration visually matches V1; manual-claim works; resync compacts |
| 6 | All 8 UI surfaces render from V2; legacy provider can be unbound for them |
| 7 | Resolver swap to V2 backing complete; social files untouched in this phase; unknown ids degrade gracefully |
| 8 | RPG toggle hides RPG nodes engine-side and UI-side; no scattered `if`s |
| 9 | Legacy directory deleted; analyze + tests + smoke test all green |

---

## 15. Suggested Order of Files to Create / Change

### Phase 0.5 (decouple social before V2 work begins)

Create:
- `lib/features/progression_engine/README.md`
- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` (legacy-backed)
- `lib/features/progression_engine/domain/display/progression_display_models.dart`
- `test/features/progression_engine/progression_display_resolver_legacy_backed_test.dart`

Edit (one social file per commit, in order — see Phase 0.5 in Section 13 for the full list).

### Phase 0.6 (extract journey as standalone feature)

Create:
- `lib/features/journey/README.md`
- `lib/features/journey/application/journey_view_model.dart`
- `lib/features/journey/domain/journey_map_layout.dart`
- `test/features/journey/journey_view_model_test.dart`

Move (with `git mv`):
- `lib/features/progression/domain/journey_models.dart` → `lib/features/journey/domain/journey_models.dart`
- `lib/features/progression/presentation/journey/*` → `lib/features/journey/presentation/widgets/*` (and the screen + route to `lib/features/journey/presentation/`)

Edit:
- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` — extend with `currentLevel()`, `chapterMilestones()`, `recentlyCompletedNodes()`, `journeyAnchors()`.
- `lib/features/progression_engine/domain/display/progression_display_models.dart` — add `ChapterMilestoneDisplay`, `JourneyAnchorPosition`, `RecentCompletionDisplay`.
- All imports of `progression/.../journey/...` and `progression/domain/journey_models.dart` (find via grep).

### Phase 1 (new files only)

Create:
- [lib/features/progression_engine/README.md](../lib/features/progression_engine/README.md)
- [lib/features/progression_engine/domain/models/objective_definition.dart](../lib/features/progression_engine/domain/models/objective_definition.dart)
- [lib/features/progression_engine/domain/models/progression_node_definition.dart](../lib/features/progression_engine/domain/models/progression_node_definition.dart)
- [lib/features/progression_engine/domain/models/reward_definition.dart](../lib/features/progression_engine/domain/models/reward_definition.dart)
- [lib/features/progression_engine/domain/models/unlock_condition.dart](../lib/features/progression_engine/domain/models/unlock_condition.dart)
- [lib/features/progression_engine/domain/models/claim_policy.dart](../lib/features/progression_engine/domain/models/claim_policy.dart)
- [lib/features/progression_engine/domain/models/content_tag.dart](../lib/features/progression_engine/domain/models/content_tag.dart)
- [lib/features/progression_engine/domain/models/activation_policy.dart](../lib/features/progression_engine/domain/models/activation_policy.dart)
- [lib/features/progression_engine/domain/models/progression_resolution_result.dart](../lib/features/progression_engine/domain/models/progression_resolution_result.dart)
- [lib/features/progression_engine/domain/models/progression_resolution_reason.dart](../lib/features/progression_engine/domain/models/progression_resolution_reason.dart)
- [lib/features/progression_engine/domain/models/ledger_event.dart](../lib/features/progression_engine/domain/models/ledger_event.dart)
- [lib/features/progression_engine/domain/models/node_state.dart](../lib/features/progression_engine/domain/models/node_state.dart)
- [lib/features/progression_engine/domain/catalog/objective_catalog.dart](../lib/features/progression_engine/domain/catalog/objective_catalog.dart)
- [lib/features/progression_engine/domain/catalog/progression_node_catalog.dart](../lib/features/progression_engine/domain/catalog/progression_node_catalog.dart)
- [lib/features/progression_engine/domain/catalog/catalog_validator.dart](../lib/features/progression_engine/domain/catalog/catalog_validator.dart)
- [test/features/progression_engine/catalog_validator_skeleton_test.dart](../test/features/progression_engine/catalog_validator_skeleton_test.dart)

### Phase 2 (new files only)

Create:
- `lib/features/progression_engine/domain/evaluator/objective_evaluator.dart`
- `lib/features/progression_engine/domain/evaluator/unlock_condition_resolver.dart`
- `lib/features/progression_engine/domain/evaluator/progression_node_resolver.dart`
- `lib/features/progression_engine/domain/evaluator/reward_grant_planner.dart`
- `lib/features/progression_engine/application/progression_engine.dart`
- `lib/features/progression_engine/application/progression_engine_source.dart`
- `lib/features/progression_engine/application/reward_grant_service.dart`
- `lib/features/progression_engine/application/cosmetic_unlock_bridge.dart` (no-op stub)
- `lib/features/progression_engine/domain/repository/progression_engine_repository.dart` (in-memory impl inline for now)
- `lib/features/devtools/presentation/sections/devtools_progression_engine_section.dart`
- `test/features/progression_engine/objective_evaluator_test.dart`
- `test/features/progression_engine/progression_engine_engine_idempotency_test.dart`

Edit:
- [lib/features/devtools/presentation/devtools_screen.dart](../lib/features/devtools/presentation/devtools_screen.dart) — add the new section.

### Phase 3 (new files only)

Edit (heavy):
- `lib/features/progression_engine/domain/catalog/objective_catalog.dart`
- `lib/features/progression_engine/domain/catalog/progression_node_catalog.dart`
- `lib/features/progression_engine/domain/catalog/chapter_catalog.dart` (new)
- `lib/features/progression_engine/domain/catalog/catalog_validator.dart` (extend)

Create:
- `test/features/progression_engine/catalog_full_test.dart`

### Phase 4 (new files only)

Create:
- `lib/features/progression_engine/data/local/progression_engine_local_models.dart` — includes `ActiveSelectionRecord` for combo pool / daily sequence persistence
- `lib/features/progression_engine/data/local/progression_engine_database.dart`
- `lib/features/progression_engine/data/progression_engine_repository_impl.dart`
- `lib/features/progression_engine/domain/repository/progression_engine_local_repository.dart`
- `test/features/progression_engine/repository_impl_test.dart`
- `test/features/progression_engine/active_selection_persistence_test.dart` — verifies combo pool selection survives restart

Edit:
- App-level Isar setup (find via grep for `Isar.open`) to register V2 schemas.
- `lib/features/devtools/presentation/sections/devtools_progression_engine_section.dart` — add wipe button.

### Phase 5

Create:
- `lib/features/celebration/application/progression_engine_celebration_adapter.dart`
- `lib/features/progression_engine/application/progression_engine_provider.dart`
- `test/features/celebration/progression_engine_celebration_adapter_test.dart`

Edit:
- [lib/features/celebration/presentation/celebration_overlay_host.dart](../lib/features/celebration/presentation/celebration_overlay_host.dart) — add a V2 source path (parallel to V1).
- `lib/main.dart` — provide `ProgressionEngineProvider` (initially unused by UI).

### Phase 6 (the bulk migration)

Edit (in this order; journey already extracted in Phase 0.6 so it's not on this list):
1. [lib/features/progression/presentation/widgets/progression_home_card.dart](../lib/features/progression/presentation/widgets/progression_home_card.dart)
2. [lib/features/progression/presentation/hero/hero_screen.dart](../lib/features/progression/presentation/hero/hero_screen.dart)
3. [lib/features/progression/presentation/quests/quests_screen.dart](../lib/features/progression/presentation/quests/quests_screen.dart) + [quest_screen_sections.dart](../lib/features/progression/presentation/quests/quest_screen_sections.dart)
4. `lib/features/journey/application/journey_view_model.dart` — swap from legacy-resolver to engine-resolver (single internal change)
5. [lib/features/app_shell/presentation/main_shell.dart](../lib/features/app_shell/presentation/main_shell.dart)
6. [lib/features/home/presentation/overview_screen.dart](../lib/features/home/presentation/overview_screen.dart)
7. [lib/features/onboarding/presentation/onboarding_steps.dart](../lib/features/onboarding/presentation/onboarding_steps.dart)
8. [lib/features/cosmetics/application/cosmetics_provider.dart](../lib/features/cosmetics/application/cosmetics_provider.dart)

Each edit replaces `ProgressionProvider` reads with `ProgressionEngineProvider` reads and adapts shape via the V2 display models. Move presentation widgets that are V2-aware into `lib/features/progression_engine/presentation/` rather than mutating files under the legacy `progression/` tree.

### Phase 7 (resolver backing swap only)

Edit:
- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` — replace legacy catalog reads with V2 catalog reads. Map sealed `ProgressionNode` subtypes to `NodeDisplay` via exhaustive switch.

Create:
- `test/features/progression_engine/progression_display_resolver_v2_backed_test.dart` — replaces the legacy-backed test from Phase 0.5.

Delete:
- `test/features/progression_engine/progression_display_resolver_legacy_backed_test.dart`.

No social files touched in this phase — they were all migrated in Phase 0.5.

### Phase 8

Create:
- `lib/features/progression_engine/application/rpg_mode_provider.dart`
- `test/features/progression_engine/activation_policy_test.dart`

Edit:
- `lib/features/progression_engine/domain/evaluator/progression_node_resolver.dart` — apply activation policy.
- `lib/features/progression_engine/domain/display/progression_display_resolver.dart` — apply content-tag filter.
- `lib/features/celebration/application/progression_engine_celebration_adapter.dart` — apply content-tag filter.
- `lib/features/devtools/presentation/sections/devtools_progression_engine_section.dart` — add hidden RPG toggle.
- `lib/features/progression_engine/domain/catalog/catalog_validator.dart` — add RPG-tag/policy coherence rule.

### Phase 9

Delete:
- `lib/features/progression/` (entire directory)
- `lib/features/celebration/application/progression_celebration_adapter.dart`
- The `ProgressionCelebrationEvent` type from anywhere it survives
- All legacy Isar schema files
- `lib/features/devtools/presentation/sections/devtools_progression_engine_section.dart` (old `devtools_progression_section.dart` was already replaced in earlier phases)

Edit:
- App-level Isar setup — drop legacy schemas.
- Rename `progression_engine/` → `progression/` (single IDE refactor).
- Rename every `*_v2*` file and identifier — drop the suffix.
- `lib/main.dart` — drop V1 wiring.

Verify:
- `grep -r "as legacy" lib/ test/` → empty (all coexistence import prefixes removed).
- `grep -r "lib/features/progression/" lib/ test/` → empty (legacy folder deleted).
- `flutter analyze` → clean.
- `flutter test` → all pass.
- Manual smoke test on a fresh device install.

---

## Appendix A — Resolved decisions (locked-in before Phase 1)

1. **Combo / triple-combo quests** — **KEEP**, model cleanly. Introduce `ComboPool` as a first-class catalog entity; achievements that count combo completions reference the pool id, not hard-coded quest id sets. Adding a new combo pool becomes a single catalog edit, not a parallel-table edit. See §4.6 and §7.1.
2. **Daily sequences** — **REPLACE** with a "tiered daily" model. Each daily slot has tier 1/2/3 quest variants; engine selects a tier based on player level (or yesterday's success). No persistent step state, no `dailySequenceId`/`dailySequenceStep` fields, simpler evaluator. See §4.7.
3. **Companion / relic semantics** — **SPLIT** into two node subtypes:
   - **Companions**: 3-state (locked → available → unlocked/equipped), `ClaimPolicy.manual`. Player consciously chooses.
   - **Relics**: 2-state (locked → unlocked), `ClaimPolicy.automatic`. Pasivní items, hráč prostě dostane.
   - Equipped state for both lives in the cosmetics feature.
4. **Difficulty score (1.0–10.0)** — **DROP**. Dead signal in V1; YAGNI for V2. Add later when a real consumer (balance dashboard) needs it, in the same PR.
5. **`Rarity` vs `Difficulty`** — **COLLAPSE** to `Rarity` only. Drop `ProgressionAchievementDifficulty` enum. Badge label = `rarity.label(l10n)`, badge color = `rarity.color`. Design tokens already carry rarity colors for celebration aura — same source.
6. **Social feed snapshots** — **HYBRID**:
   - Feed (historical events) → snapshot at publish time (`displaySnapshot { titleAtPublish, descAtPublish, rarityAtPublish, assetPathAtPublish }`).
   - Profile grid (current state) → live resolution via `ProgressionDisplayResolver`. Unknown ids → "Unknown achievement" tile.
   - Leaderboards → live (level/XP only).
7. **Folder name** — new module is `lib/features/progression_engine/`. Legacy `lib/features/progression/` deleted in Phase 9. No rename afterwards. Class-name conflict on `ProgressionEngine` resolved by `as legacy` import prefix during coexistence.

---

## Appendix B — Files audited (with line counts)

| File | Lines |
|---|---|
| [lib/features/progression/application/progression_engine.dart](../lib/features/progression/application/progression_engine.dart) | 754 |
| [lib/features/progression/application/progression_provider.dart](../lib/features/progression/application/progression_provider.dart) | 829 |
| [lib/features/progression/application/cosmetic_unlock_dispatcher.dart](../lib/features/progression/application/cosmetic_unlock_dispatcher.dart) | 273 |
| [lib/features/progression/domain/catalog/quest_catalog.dart](../lib/features/progression/domain/catalog/quest_catalog.dart) | 1918 |
| [lib/features/progression/domain/catalog/achievement_catalog.dart](../lib/features/progression/domain/catalog/achievement_catalog.dart) | 605 |
| [lib/features/progression/domain/catalog/rule_catalog.dart](../lib/features/progression/domain/catalog/rule_catalog.dart) | 196 |
| [lib/features/progression/domain/evaluator/quest_evaluator.dart](../lib/features/progression/domain/evaluator/quest_evaluator.dart) | 1607 |
| [lib/features/progression/domain/evaluator/achievement_evaluator.dart](../lib/features/progression/domain/evaluator/achievement_evaluator.dart) | 650 |
| [lib/features/progression/domain/policy/level_config.dart](../lib/features/progression/domain/policy/level_config.dart) | 398 |
| [lib/features/progression/domain/models/quest_models.dart](../lib/features/progression/domain/models/quest_models.dart) | 308 |
| [lib/features/progression/domain/models/achievement_models.dart](../lib/features/progression/domain/models/achievement_models.dart) | 221 |
| [lib/features/progression/domain/models/rule_models.dart](../lib/features/progression/domain/models/rule_models.dart) | 264 |
| [lib/features/progression/data/local/progression_local_models.dart](../lib/features/progression/data/local/progression_local_models.dart) | 152 |
| [lib/features/celebration/application/progression_celebration_adapter.dart](../lib/features/celebration/application/progression_celebration_adapter.dart) | 245 |
| [lib/features/celebration/domain/models/celebration_event.dart](../lib/features/celebration/domain/models/celebration_event.dart) | 119 |
| [lib/features/social/presentation/social_profile_utils.dart](../lib/features/social/presentation/social_profile_utils.dart) | 247 |
| [lib/features/devtools/presentation/sections/devtools_progression_section.dart](../lib/features/devtools/presentation/sections/devtools_progression_section.dart) | 477 |

Total audited: ~9,200 lines across 17 files.
