# Progression Engine V2 — Session Handoff (2026-05-11)

Read this on session resume. Authoritative plan in
[v2_phased_plan.md](v2_phased_plan.md);
this doc is the working state.

## Branch + commits

`refactor/progression-engine-v2` — through Phase 6.5e
(quest screen refactor + full chapter content port). The screen reached
feature parity with V1 across all sections (chapter / daily / weekly /
long-term / locked / DOKONČENÉ / nedávné odměny), and the V2 catalog
now ships all 11 chapters (Pilgrim Path → Dragonrock Sovereign) chained
end-to-end. `flutter analyze` clean (only pre-existing
`sheets_export _round` warning). `flutter test` 373/373 passing.

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
| 6.5 quests_screen migration (parallel V2 screen, V1 evicted from route) | ✅ done |
| 6.5b V1-parity quest screen (assets, expand, streak, history feed, completed rollup, chain mechanics, forest_trial chapter, chapter UI) | ✅ done |
| 6.5c V1 visual + UX parity (asset sizing, chain position, chapter expand, daily 2-of-N, long-term goals, history vs completed split) | ✅ done |
| 6.5d Plan-aligned cleanup (revert long-term duplicate, split completed vs daily, chapter chain icons + level lock) | ✅ done |
| 6.5e Quest screen refactor + chapter content port (long-term + DOKONČENÉ + locked next-up + 11 chapters chained) | ✅ done |
| 6.6 social_provider state migration | ⏳ next |
| 6.7 hero_screen + journey adapter | ⏳ |
| 6.8 overview_screen, onboarding_steps (main_shell already on V2) | ⏳ |
| 6.9 cosmetics_provider hook | ⏳ |
| 7 Display Resolver swap to V2 catalog | ⏳ |
| 8 RPG mode toggle | ⏳ |
| 9 Delete legacy progression module | ⏳ |

## What runs in the app

V2 engine is wired into MultiProvider, auto-evaluates on every
fitness/nutrition/goals change, persists to its own Isar store, and
dispatches granted cosmetics through CosmeticUnlockBridge. Four UI
surfaces consume V2 directly: **home card** (level/XP/badges/daily
quest preview), **social profile header + leaderboard**,
**bottom nav quest badge** (`pendingClaimNodeIds.length`), and the
**quests tab** (new V2 screen, daily + weekly with manual claim).
Hero screen, journey, overview daily-goal section, and onboarding
still run on V1; both engines coexist behind their own providers.

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
| (UI assembled input manually) | `currentInput` + `currentCatalogContext` getters — UI claim handlers read these instead of building inputs themselves |
| `refresh()` | `refresh()` |
| `lastEvaluatedAt` | not yet exposed (TODO when needed) |

`EngineQuestProgress` fields: `node`, `actualValue`, `targetValue`,
`progress` (0..1), `isCompleted`, `isAvailableForClaim`, `domain`,
`baseXp`, `previewXp` (level-scaled, updates as player levels up — V1
parity).

## Known coexistence quirks

- V1 hero screen / journey screen still read V1 ledger.
  Run V2 eval in devtools → home card + quests tab see V2 progress, V1
  hero/journey do not. Goes away once each screen migrates.
- Cosmetics that V2 grants flow into the same CosmeticsProvider as V1
  (via `CosmeticUnlockBridge`, `sourceType: 'engineNode'`).
- Devtools "Wipe V2 ledger" only wipes V2 — legacy stays. Same for set XP.
- Legacy `lib/features/progression/presentation/quests/quests_screen.dart`
  (the 2 081-LOC monolith) is now dead code — no production import. Two
  helpers in the same folder (`quest_daily_selection.dart`,
  `quest_screen_sections.dart`) are still imported by
  `progression_internals.dart` (used by hero_screen) and the
  corresponding unit tests. Delete the monolith + its V1 unit tests
  (`test/features/progression/quest_screen_sections_test.dart`,
  `quest_detail_view_model_test.dart`) once hero/journey migrate.

## Next session — first concrete step

V2 quests screen shipped (Phase 6.5). Recommended next step is **Phase
6.6 — social_provider state migration**. SocialProvider currently reads
`ProgressionProvider` for the published profile snapshot
(level/totalXp/achievements/recent reward grants/streaks). Switch it to
`ProgressionEngineProvider` so the published profile is V2-derived end
to end and we can drop the Social↔V1 coupling. After that, the
hero_screen and journey adapter (Phase 6.7) are the largest remaining
V1 surface.

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
7. Run `flutter test` after each commit. Currently 367 tests; baseline
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

## Phase 6.5b — files added/modified

V1-parity polish on top of Phase 6.5. Eight commits:

- `0262a2d` PNG assets on V2 quest cards (quest_assets.dart + assetKey
  on every existing daily/weekly QuestNode + Image.asset render with
  ProgDomIco fallback)
- `8f5f46d` rewardHistory + completedQuests getters +
  EngineCompletedQuest model on the provider; nodeById exposes catalog
  lookup so UI can resolve titles for ledger-only ids
- `f782813` expandable EngineQuestCard with one-at-a-time expansion
  (V1 pattern), 🔥 streak chip, expanded XP-scaling / streak-best /
  locked-hint detail panel + 3 new l10n keys
  (`progXpFlatDetail`, `progXpScalingDetail`, `progStreakBestDetail`)
- `c3c21d1` EngineRewardHistoryFeed (chronological from
  ledger.rewardGrants) + EngineCompletedQuestsSection (compact list
  with "Show all (N)" reveal); domainForNodeId resolves
  node→objective→domain on the provider
- `44dbe57` Chain mechanics on QuestNode: prerequisiteNodeIds /
  nextNodeIds / chainStepLabelKey. Engine expands prereqs into
  NodeCompleted unlock conditions
- `dd278e1` forest_trial chapter content port — pilot chapter with
  open + 3 steps + finale; auto-claim open at level 10, manual-claim
  steps gated by NodeCompletionsMetric on existing daily quests,
  finale drops emblem_forest_mark cosmetic. 3 new tests
- `8db603d` Chapter section + chain preview in QuestsScreenV2;
  EngineChapterCard renders parallax bg image + chain preview row
  (current step glows, completed steps show check). New provider
  getters `currentChapterQuests` + `chainQuestsFor(chainId)`

## Phase 6.5c — files added/modified (V1 visual + UX parity)

Four commits on top of 6.5b:

- `18d66bb` Card visuals — assets bumped to `Tokens.questAssetCollapsed`
  (64) / `questAssetExpanded` (76) instead of cramped 32/44; chapter
  card chain preview moved between title row and progress (V1 layout);
  chapter cards gained the expanded-details panel (XP scaling, chain
  step label, locked hint) the daily/weekly cards already had.
- `b190893` Daily 2-of-N rotation — `currentDailyQuests` now picks two
  quests per day deterministically (FNV-1a per (dayKey, questId), V1
  parity). `allDailyQuests` exposes the un-narrowed list. New test
  `daily_pick_test.dart`.
- `7016f1b` Long-term goals — new `long_term_content.dart` with five
  representative quests (`earn_first_reward`, steps_streak 7→30 chain,
  reach_500_xp → reach_2000_xp chain). Provider getter
  `currentLongTermQuests` does V1's `compactQuestChainRepresentatives`
  (one entry per chain). Screen renders the new section between weekly
  and the completed rollup.
- `52c6018` Sections split — `recentRewardHistory` filters out quest
  XP grants so the "Recent rewards" feed is just cosmetics, emblems,
  achievement-driven rewards. `EngineCompletedQuest.xpGranted` is
  summed from the ledger so the rollup row keeps a "+96 XP" badge
  instead of just a check icon.

## Phase 6.5e — files added/modified (quest screen refactor + chapter port)

One large commit (`7f50847`) landing the full quest-screen V2 surface
and porting every remaining chapter from V1. Highlights:

### Quest screen sections

- DLOUHODOBÉ CÍLE — `EngineLongTermCard` aggregates a long-term quest
  with companion achievement nodes that share its objective. Renders
  the quest's XP pill + a chip strip + chain dots; expanded panel
  shows next-step hint, "Také odemkne" companion list, and the chain's
  finale rewards as rich rows.
- DOKONČENÉ — `EngineCompletedQuestCard` collapses each chain into a
  single row (representative = highest-chainOrder touched step). Gold
  glow + claim pill only while a step is claimable; greyed once fully
  claimed. "Vyzvednout vše" drains the pending claims with a cascade
  loop (up to 8 passes) so derived unlocks land in the same tap.
- ZAMČENÉ — `_LockedSection` shows at most one chapter chain at a time
  (next-up by sortOrder); hint preference is prereq chapter name
  ("Dokonči Stezku poutníka") over level ("Reach level 10"). Non-chapter
  level-gated quests still surface individually.
- Daily section surfaces claimable quests outside today's 2-of-N
  rotation so `pendingClaimNodeIds` is never invisible.

### Engine + provider (6.5e)

- `ObjectiveDefinition.baselineFromNodeId` — chapter step objectives
  count progress *since the prereq node completed*, not lifetime.
  Provider precomputes per-objective overrides via
  `EngineEvaluationInput.objectiveActualOverrides`; evaluator just
  reads from the map when present. Today supports
  `NodeCompletionsMetric` + `RewardCountMetric`; `StepsMetric` falls
  back to lifetime (no per-event history yet — chain prereqs still
  enforce ordering).
- `EngineQuestProgress.prereqGateNodeId` exposes the first unmet
  prereq node id so the locked-row hint can name the blocker.
- `claimNode` rebuilds input from the latest ledger on every call;
  the old stale-input bug where sequential claim-all left a counter
  unsatisfied is gone.
- `bind()` guards against duplicate `addListener` via instance
  tracking; `dispose()` detaches.

### Catalog port — all 11 chapters now in V2

- Pilgrim Path (level 1 starter, ships its own
  `chapter_pilgrim_path_content.dart`). Drops
  `emblem_pilgrim_mark` from the welcome achievement; the finale
  awards it instead.
- Forest Trail (level 10, pilot — keeps its own file as the canonical
  hand-authored chapter the V2 tests reference).
- Nine remaining chapters (Ruins of Discipline → Dragonrock Sovereign)
  in shared `chapter_content.dart` via a spec / builder pattern. Cross-
  chapter chain wired via `prerequisiteNodeIds`: each chapter's open
  depends on the previous chapter's finale being in the ledger.
- All 10 emblem unlock hints rewritten from "Reach level X" to
  "Dokonči X" / "Complete the X" (CS + EN regenerated).
- Chapter step criterion mapping V1 → V2 documented in the chapter
  content file header. Known limitations preserved:
  - `ruleSetCompletionsAtLeast` ("four pillars" etc.) collapses to the
    first listed daily rule's `NodeCompletionsMetric` proxy.
  - `totalRuleValueAtLeast` (250k/500k steps) maps to `StepsMetric`
    lifetime — no baseline-at-unlock until step history per timestamp
    exists.

### Cosmetic preview integration

- Reward preview tap on a chain finale reuses the canonical
  `CosmeticDetailsSheet` from the inventory via
  `showEngineRewardPreviewSheet` shim. Locked emblems read the same as
  in the cosmetics screen with the chapter-specific unlock hint.
- `CosmeticAssetThumb` widget resolves a cosmetic by id via
  `CosmeticCatalog` + `CosmeticsConfig.resolveAssetPath`; falls back
  to typed icon when the id isn't in the catalog.

### Other UI primitives (6.5e)

- `EngineCompanionPill` (badge + animated chevron, doubles as expand
  affordance under the XP pill).
- `EngineRewardChip` (icon-only chips for compact reward strips).
- `AnimatedSize` on all expandable card types.
- Palette icon swapped for `card_giftcard` glyph everywhere.

## Phase 6.5d — files added/modified (plan-aligned cleanup)

Three commits after the user flagged 6.5c drift back toward V1
patterns:

- `dd5e41e` Reverted `long_term_content.dart` — those five "long-term
  quests" violated the V2 plan's "Quest and Achievement With Same
  Goal — both should reference the same ObjectiveDefinition" rule.
  They created new QuestNodes whose objectives (RewardCountMetric,
  StreakDaysMetric.byRule, TotalXpMetric) were already covered by
  existing AchievementNodes in `steps_content`, `welcome_content`,
  and `meta_content`. Long-term display in V2 should surface those
  same nodes (achievements / milestones) through a shared resolver
  rather than re-authoring duplicate quests.
- `a5ca7f8` Split completed quests vs daily completions. V2 now
  mirrors V1's bottom layout: "Splněné cíle" (non-daily completed
  quests — chapter / weekly / future long-term) and "Nedávné odměny"
  (today's daily-goal claims). Provider getters `completedQuests`
  (excludes daily bucket) and `recentDailyCompletions` (daily-bucket
  only) drive the two sections; both use the same
  `EngineCompletedQuestsSection` widget with configurable header /
  empty copy. Claimed rows now show a soft success-toned check chip
  (V1 parity, no gold "+XP" pill once claimed). The achievement
  reward feed (`EngineRewardHistoryFeed`) is gone — achievements
  surface on their own screen, not the quests tab.
- `6918ad2` Chapter chain icons + level lock. `QuestNode` gains
  `chainStepIcon: IconData?` so chapter open / finale can render
  play / shield glyphs instead of "Start" / "Emblem" text. The
  forest_trial open node also picks up an explicit
  `LevelAtLeast(10)` unlock condition; the provider extracts the
  first unmet `LevelAtLeast` onto `EngineQuestProgress.levelGate`
  and the chapter card swaps its XP pill for a "Lv 10" lock chip,
  hides the progress bar, and darkens the background image while
  the gate stands.

## Outstanding catalog work (deferred)

All chapters now in V2. Remaining content gaps:

- **All 8 V1 achievements ported (Phase 9c follow-up).** Live in
  `meta_content.dart`:
  - `daily_quest_3` / `daily_quest_7` / `quest_hunter_250` /
    `active_days_7` (the four non-combo ones).
  - `combo_victory_10` / `combo_triple_victory_25` /
    `combo_triple_victory_100` (combo achievements driven by the
    new combo infra).
  - `dragonrock_trial` (composite — `objectiveId: null` with
    `unlockConditions: [LevelAtLeast(100),
    ObjectiveCompleted('quest_count_250'),
    ObjectiveCompleted('lifetime_steps_10m')]`).
- **Combo system rebuilt** (Phase 9c follow-up — supersedes the 5 V1
  combo daily quests). The old V1-parity combo quests fought the
  2-per-day base daily rotation and rarely surfaced. They've been
  replaced with three themed sequential chains in `combo_content.dart`:
  - `combo_balanced` (4 steps) → any 1/2/3/4 daily goals today
  - `combo_recovery` (4 steps) → sleep → +steps → +protein → +calories
  - `combo_nutrition` (5 steps) → kcal → +protein → +carbs → +fat → +fiber
  
  Each step uses `TodayCompletionsAmongMetric` with a growing
  `nodeIds` set + `targetValue`, gated linearly by
  `prerequisiteNodeIds`. Chain N+1's first step references chain N's
  finale as its prerequisite — cross-chain rotation is **finite**:
  chain 1 → 2 → 3 → end. Perpetual rotation needs an engine-level
  lap counter (not implemented; documented as future work).
  
  Combo content lives in its own `QuestDisplayBucket.combo` bucket
  rendered as a new "DENNÍ COMBO" section on the quest screen
  (provider getter `currentComboQuests`; `_ComboSection` widget;
  `lockedQuests` skips combo so locked steps don't crowd the section).
  
  Combo quests still share `comboPoolId: 'daily_combo_pool'` so
  `combo_victory_10` keeps counting. `combo_triple_victory_25/100`
  now reference the 7 "3+ atoms" combo node ids
  (`combo_*_step_3`, `combo_*_finale`, `combo_nutrition_step_4`).
- **Nutrition expansion** — added `CarbsGramsMetric`,
  `FatGramsMetric`, `FiberGramsMetric` and three new daily quests
  (`daily_carbs_today` / `daily_fat_today` / `daily_fiber_today`).
  `EngineEvaluationInput` gains `carbsGramsToday`, `fatGramsToday`,
  `fiberGramsToday`; `ProviderEngineInputSource` pulls them from
  `KalorickeTabulkyProvider`. Fiber goal uses the `EngineGoalSet`
  default (30 g) since `GoalsProvider` has no fiber setter yet.
- **Celebration multi-merge** — fold pass now bundles ≥2 solo
  `CelebrationType.achievement` events from the same evaluation
  result into a single fullscreen "moment pack" event. Fixes the
  welcome flow that previously showed `welcome_to_journey` and
  `first_reward` as two separate popups. New l10n keys:
  `celebrationAchievementPackEyebrow` /
  `celebrationAchievementPackTitle(count)`.
- **DevTools — progression engine controls** (Phase 9c). New panels
  in `DevToolsProgressionEngineSection`:
  - **Add XP**: appends a synthetic XP grant on top of existing
    ledger state (additive, vs. the existing destructive "Set XP").
  - **Set level**: derives target XP via
    `ProgressionLevelPolicy.xpRequiredForLevel(N)` and calls
    `devToolsSetTotalXp`.
  - **Force complete node**: by id; injects a synthetic
    `NodeCompletionEvent` + matching reward grants and re-evaluates
    so cascading unlocks (companion, chapter content, level
    milestones) fire as for real completion.
  - **Complete all daily quests (today)**: shortcut that
    force-completes every `QuestDisplayBucket.daily` node so the
    day's combo chain advances + downstream achievements fire.
- **All 7 companion availability nodes ported** to
  `content/companions_content.dart`, mirroring the
  `cosmetics/plan.md` chain spec: each `CompanionAvailabilityNode`
  is gated on a level + completion of the two relic-granting
  achievements (`NodeCompleted` references; relics live as
  `CosmeticReward`s on the achievements, no standalone `RelicNode`
  entries). Eight content tiers from `ember_sprite` (level 5) up to
  `dragonling` (level 100, mythic).
- **Required new metric infrastructure** (`objective_metric.dart`):
  - `QuestCompletionsByBucketMetric({bucket})` — drives
    `daily_quest_3/7` (bucket = daily) and `quest_hunter_250`
    (bucket = null → total).
  - `DistinctActiveDaysMetric()` — drives `active_days_7`.
  - `TodayCompletionsAmongMetric({nodeIds})` — drives the combo
    daily quests' "K of M daily rules met today" objective.
  - `LifetimeCompletionsAmongMetric({nodeIds})` — drives the
    `triple_combo_25/100` objectives that span both `triple_win`
    and `four_pillars` quests (a quest can have at most one
    `comboPoolId`, so a node-set sum was the cleanest expression).
- **`EngineEvaluationInput` additions**: `totalQuestCompletions`,
  `questCompletionsByBucket`, `distinctActiveDays`,
  `nodesCompletedToday`, plus the previously declared-but-unused
  `comboPoolCompletionCounts` is now populated.
- **Ledger aggregators in `progression_engine_provider.dart`**:
  `_questCompletionsFromLedger()` (joins ledger with catalog to
  filter to `QuestNode` completions, returns total + per-bucket
  counts), `_distinctActiveDaysFromLedger()`,
  `_nodesCompletedTodayFromLedger()`, and
  `_comboPoolCompletionCountsFromLedger()`. Both `buildInput`
  call sites thread the new aggregations through.
- **`rpg_placeholders.dart` deleted** (Phase 9c cleanup). It
  contained a fake `companion_pilgrim_fox` (cosmetic id didn't exist
  in the catalog) and a standalone `RelicNode` `relic_pilgrim_compass`
  that shadowed the established "relic = `CosmeticReward` on
  achievement" pattern used by every other relic. Both fired
  spurious duplicate "Vítej na cestě" celebrations at level 20.
- Step-based chapter steps (`mine_descent_steps_250k`,
  `icewalker_route_steps_500k`) fall back to lifetime semantics
  because the baseline-at-unlock override only handles
  `NodeCompletionsMetric` + `RewardCountMetric` today. Chain prereqs
  still enforce ordering; the player who's already past the threshold
  just instantly satisfies the step. Fix needs per-event step history
  scoped to a timestamp.
- "Four pillars" / `ruleSetCompletionsAtLeast` chapter steps are
  proxied to the first listed daily rule's `NodeCompletionsMetric`.
  Full semantics ("K of M rules per day") need a new metric
  (`DailyRuleSetCompletionsMetric` or similar).
- Long-term content port is intentionally narrow — covers the three
  threshold chains (lifetime_steps, xp_milestones, reward_hunter).
  More V1 long-term content (sleep totals, weekly mastery,
  recovery combo finale) can land later in the same shape.

## Follow-up cleanup not blocking next phase

- `engine_companion_pill.dart` is 858 lines and bundles five distinct
  concerns (pill widget, badge helpers, companion detail sheet, reward
  preview sheet, public reward detail row). Splitting into focused
  files would be cleaner but not urgent — leave for a polish pass.

## Phase 6.5 — original-foundation files (Phase 6.5 commit `510a5d4`)

- New: `lib/features/progression_engine/presentation/quests_screen.dart`
  (`QuestsScreenV2` + public `QuestSectionPanel`)
- New: `lib/features/progression_engine/presentation/widgets/engine_quest_card.dart`
  (`EngineQuestCard` — single quest row with domain icon, title +
  description, progress bar, and the locked/claimable/claimed XP pill)
- New: `lib/features/progression_engine/presentation/widgets/engine_quest_section.dart`
  (`EngineQuestSection`, `EngineQuestEmptyLine`, `EngineQuestErrorBanner`,
  `EngineQuestLoadingBlock` — V2-local clones of the legacy
  progression primitives so the V2 module stays import-clean)
- Modified: `lib/features/progression_engine/application/progression_engine_provider.dart`
  (added `currentInput` + `currentCatalogContext` getters so UI claim
  handlers don't have to assemble inputs themselves)
- Modified: `lib/features/app_shell/presentation/main_shell.dart`
  (route index 1 → `QuestsScreenV2`; bottom nav `questBadge` switched
  from `ProgressionProvider.pendingRewards.length` to
  `ProgressionEngineProvider.pendingClaimNodeIds.length`; legacy
  imports dropped)
- New tests: `test/features/progression_engine/quest_section_panel_test.dart`
  (3 widget tests — empty state, claim-all visibility, claim-all
  callback)
