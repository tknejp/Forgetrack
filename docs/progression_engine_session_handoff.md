# Progression Engine V2 — Session Handoff (2026-05-11)

Read this on session resume. Authoritative plan in
[progression_engine_v2_phased_plan.md](progression_engine_v2_phased_plan.md);
this doc is the working state.

## Branch + commits

`refactor/progression-engine-v2` — 19 commits this session.
`flutter analyze` clean (only pre-existing `sheets_export _round` warning).
`flutter test` 364/364 passing.

## Phase status

| Phase | State |
|---|---|
| 0.5 Display Resolver + social cutover | ✅ done |
| 0.6 Journey extraction | ✅ done |
| 1 Domain skeleton | ✅ done |
| 2 Evaluation skeleton | ✅ done |
| 3 Catalog port (full, by-domain split) | ✅ done |
| 4 Isar persistence | ✅ done |
| 5 Celebration adapter | ✅ done |
| 6 foundation (provider + main wiring + devtools section) | ✅ done |
| 6.1 Source binding + cosmetic bridge | ✅ done |
| 6.2 Social leaderboard + profile header migration | ✅ done |
| 6.3 Manual claim + StreakSource + derived state | ✅ done |
| 6.4 Home card migration + dynamic XP scaling + claim-all devtools | ✅ done |
| 6.5 quests_screen migration | ⏳ next |
| 6.6 social_provider state migration | ⏳ |
| 6.7 hero_screen + journey adapter | ⏳ |
| 6.8 main_shell, overview_screen, onboarding_steps | ⏳ |
| 6.9 cosmetics_provider hook | ⏳ |
| 7 Display Resolver swap to V2 catalog | ⏳ |
| 8 RPG mode toggle | ⏳ |
| 9 Delete legacy progression module | ⏳ |

## What runs in the app

V2 engine is wired into MultiProvider, auto-evaluates on every
fitness/nutrition/goals change, persists to its own Isar store, and
dispatches granted cosmetics through CosmeticUnlockBridge. Two UI
surfaces consume V2 directly: **home card** (level/XP/badges/daily
quest preview) and **social profile header + leaderboard**. Everything
else still runs on V1; both engines coexist behind their own providers.

DevTools → Engine V2 surfaces:
- ledger row counts + last-result summary
- "Run V2 evaluation (ambitious-player input)"
- "Claim all available quests" — iterates `pendingClaimNodeIds` and
  calls `engine.claim(...)` so XP lands without needing a UI claim
  button (quests_screen still V1 → claim only via devtools today)
- "Set total XP" — wipes ledger + inserts synthetic XP grant so
  `profile.totalXp` matches the chosen value (V1 had this too)
- "Wipe V2 ledger"

## Key design decisions locked in

| # | Topic | Decision |
|---|---|---|
| 1 | Combo/triple-combo quests | Keep mechanic; first-class `ComboPoolDefinition` (not yet ported) |
| 2 | Daily sequences | Replaced by `TieredDailyConfig` (not yet ported) |
| 3 | Companions / relics | 3-state companion (manual claim) vs 2-state relic (auto). Both placeholder nodes ship in `rpg_placeholders.dart` |
| 4 | difficultyScore | Dropped |
| 5 | Difficulty enum vs Rarity | Collapsed to Rarity only |
| 6 | Social feed snapshots | Hybrid: snapshot for activity feed, live for profile grid (not yet implemented; legacy unchanged) |
| 7 | Module name | `lib/features/progression_engine/` (no rename in Phase 9; legacy `progression/` deleted) |
| 8 | Manual claim for quest XP | All `QuestNode`s use `ClaimPolicy.manual` → XP lands in ledger only after `engine.claim(nodeId, input)` |
| 9 | Catalog split by domain | `domain/catalog/content/<domain>_content.dart` per topic; `objective_catalog` + `progression_node_catalog` are aggregators |

## Architecture quick map

```
lib/features/progression_engine/
├── domain/
│   ├── models/                       # sealed ObjectiveMetric/Scope/Operator,
│   │                                 # ObjectiveDefinition (with .domain),
│   │                                 # sealed ProgressionNode hierarchy,
│   │                                 # sealed RewardDefinition / UnlockCondition,
│   │                                 # LedgerEvent, ProgressionResolutionResult
│   ├── catalog/
│   │   ├── content/                  # 9 per-domain content files
│   │   ├── objective_catalog.dart    # aggregator
│   │   ├── progression_node_catalog.dart # aggregator
│   │   └── catalog_validator.dart    # duplicate ids, missing refs, level coherence
│   ├── evaluator/
│   │   ├── objective_evaluator.dart  # metric × scope × operator → outcome
│   │   ├── unlock_condition_resolver.dart
│   │   ├── progression_node_resolver.dart
│   │   ├── reward_grant_planner.dart
│   │   └── engine_streak_source.dart # streak by objective + by domain
│   ├── repository/                   # LedgerSnapshot + interface
│   └── display/                      # ProgressionDisplayResolver (Phase 0.5,
│                                     # backed by legacy catalog still)
├── application/
│   ├── progression_engine.dart       # orchestrator (class name CLASHES with
│   │                                 # legacy: import via `as v2_engine` or
│   │                                 # `as legacy` where both needed)
│   ├── progression_engine_provider.dart # ChangeNotifier with bind() + derived
│   │                                 # state (profile, currentDailyQuests,
│   │                                 # streakForDomain, etc.)
│   ├── reward_grant_service.dart     # XP scaling at grant time
│   └── cosmetic_unlock_bridge.dart   # forwards cosmetic grants
└── data/
    ├── local/progression_engine_database.dart # parallel Isar store
    ├── local/progression_engine_local_models.dart (.g.dart generated)
    ├── isar_progression_engine_repository.dart
    └── provider_engine_input_source.dart # GoalsProvider+FitnessProvider+
                                        # KalorickeTabulkyProvider →
                                        # EngineEvaluationInput
```

## Provider cheatsheet — V1 ↔ V2

| V1 ProgressionProvider | V2 ProgressionEngineProvider |
|---|---|
| `profile.{level,totalXp,xpIntoLevel,nextLevelXp,levelFloorXp}` | identical (`EngineProfile` mirrors shape) |
| `pendingRewards.length` | `pendingClaimNodeIds.length` |
| `achievements.where((a) => a.unlocked).length` | `unlockedAchievementCount` |
| `completedQuests.length` | `completedQuestCount` |
| `quests` for `selectDailyGoalQuestsForDate` | `currentDailyQuests` (`List<EngineQuestProgress>`) |
| `streakForDomain(domain)` | `streakForDomain(domain)` (returns `EngineStreakSummary`) |
| `streakForRule(ruleId)` | `streakForObjective(objectiveId)` |
| `claimReward(rewardKey)` / `claimQuestReward(...)` | `claimNode(nodeId: ..., input: ...)` |
| `refresh()` | `refresh()` |
| `lastEvaluatedAt` | not yet exposed (TODO when needed) |

`EngineQuestProgress` fields: `node`, `actualValue`, `targetValue`,
`progress` (0..1), `isCompleted`, `isAvailableForClaim`, `domain`,
`baseXp`, `previewXp` (level-scaled, updates as player levels up — V1
parity).

## Known coexistence quirks

- V1 quest screen / hero screen / journey screen still read V1 ledger.
  Run V2 eval in devtools → home card sees V2 progress, V1 screens do not.
  Goes away once each screen migrates.
- Cosmetics that V2 grants flow into the same CosmeticsProvider as V1
  (via `CosmeticUnlockBridge`, `sourceType: 'engineNode'`).
- Devtools "Wipe V2 ledger" only wipes V2 — legacy stays. Same for set XP.

## Next session — first concrete step

User chose between four options last turn but session ran out of context.
Recommended: **build a parallel V2 quests screen** at
`lib/features/progression_engine/presentation/quests_screen.dart`
covering daily + weekly with claim button. Route swap when ready. Keeps
V1 chapter/chain still working until full content port.

Per-screen migration cookbook (apply to each remaining screen):

1. Replace `import '.../progression/application/progression_provider.dart'`
   with `import '.../progression_engine/application/progression_engine_provider.dart'`.
2. Replace `context.watch<ProgressionProvider>()` with
   `context.watch<ProgressionEngineProvider>()`.
3. Map field accesses via the cheatsheet above.
4. Replace `tierForLevel(level).title(l10n)` with
   `const ProgressionDisplayResolver().levelDisplay(level).title(l10n)`.
5. Replace `ProgressionLevelBadge(level: l, size: s)` with
   `LevelBadge(level: l, accentColor: <accent>, size: s)` — pull accent
   from `levelDisplay.accentColor`.
6. Run `flutter analyze` after each file. IDE diagnostics often stale —
   trust `flutter analyze` output, not the IDE squiggles.
7. Run `flutter test` after each commit. Currently 364 tests; baseline
   should not regress.

## Provider declaration order in main.dart

V2 ProgressionEngineProvider MUST be declared after CosmeticsProvider
+ legacy ProgressionProvider in MultiProvider. `bind()` reads
CosmeticsProvider; declaring it earlier crashes with
"Could not find the correct Provider<CosmeticsProvider>". Fixed in
commit `d3026b2`.

## Outstanding design questions for next session

1. **Quests screen UX** — V2 has manual claim (matches V1). Do we want
   per-quest "+96 XP" pill (matches V1) or simplified "Claim" button?
   Current `EngineQuestProgress.previewXp` supports either.
2. **Chapter chains** — needed for full V1 parity but not yet ported in
   V2 catalog. Could keep V1 chapter screen alive until ported.
3. **StreakSource limits** — only daily-scoped objectives currently
   contribute. Weekly streaks would need ThisWeekScope handling.
4. **Manual-claim notifications** — when an objective is satisfied and a
   quest enters available state, V1 fires a notification. V2 doesn't yet.
5. **Factory reset for V2** — devtools has wipe ledger; full app reset
   service (`factory_reset_service.dart`) doesn't yet wipe V2 store.

## Quick test workflow (after `flutter run`)

1. **DevTools → Engine V2** → "Wipe V2 ledger"
2. → "Run V2 evaluation (ambitious-player input)" — completes 4
   objectives, daily quests go to availableNodes.
3. → "Claim all available quests" — XP lands.
4. **Open Overview** → home card now shows level/XP from V2 (legacy
   home/quest screens still legacy).
5. **Open social → leaderboard** — entries built from V2 profile.
6. **Open social → own profile sheet header** — level + XP from V2.

## Files modified today (high-signal)

- New: `lib/features/progression_engine/**/*` (~30 files)
- New: `lib/features/journey/**/*` (extracted 8 files)
- New: `docs/progression_engine_v2_phased_plan.md` (the plan)
- New: `docs/progression_engine_v2_phase_plan_prompt.md` (original brief)
- Modified: `lib/main.dart` (V2 provider wiring)
- Modified: `lib/features/progression/presentation/widgets/progression_home_card.dart` (migrated)
- Modified: `lib/features/progression/presentation/hero/hero_screen.dart` (journey import path only)
- Modified: 8 social/* files (display resolver migration in Phase 0.5)
- Modified: `lib/features/social/presentation/tabs/social_leaderboard_tab.dart` (V2 provider)
- Modified: `lib/features/social/presentation/widgets/social_profile_header.dart` (V2 provider)
- Modified: `lib/features/devtools/presentation/devtools_screen.dart` + new section
- Tests: `test/features/progression_engine/*` (51 tests, all green)
