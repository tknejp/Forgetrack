# Emblem XP buffs — implementation plan

**Trello card:** [#93 — Emblem XP bonusy — stackable claim-specific buffs (chapter rewards)](https://trello.com/c/SNNduXTX)
**Status:** active (created 2026-05-21)
**Area:** `lib/features/cosmetics/` ↔ `lib/features/progression_engine/`
**Prereq Trello:** [#101 — Body domain weightXp candidate](https://trello.com/c/HgL2dnTi) (not a blocker; documented for follow-up)

---

## How to resume this plan in a new session

Every session that picks up the next phase **MUST** follow this checklist before touching code:

1. Read [CLAUDE.md](../../CLAUDE.md) — project conventions are authoritative.
2. Read this plan top-to-bottom. The design decisions section is locked; don't re-litigate without explicit user approval.
3. Identify the next un-checked phase. **Do exactly one phase per session unless the user says otherwise.** Phases are ordered — don't skip.
4. Re-read the phase's DoD before starting. Treat it as the acceptance contract.
5. Inspect current code touching the phase scope. Don't trust the plan's path references blindly — files move.
6. Implement minimum diff to satisfy the phase DoD. No drive-by refactors, no scope creep.
7. `flutter analyze` clean (accept pre-existing Isar `.g.dart` warnings per CLAUDE.md).
8. Run / add relevant `flutter test` files for what you touched.
9. Use `AppLog` ([lib/core/logging/app_log.dart](../../lib/core/logging/app_log.dart)) for new claim / buff / progression code paths. Never `print()`.
10. After ARB edits run `flutter gen-l10n`.
11. Update interactive site JSONs (per CLAUDE.md doc conventions table) for any architectural change the phase shipped.
12. Commit using project's scope-prefix format: `emblems(93): <what>` for #93 phases; `goals(93): <what>` for Phase 0 (still tied to #93 as prereq).
13. Tick the phase's checkbox in this plan in the same commit.
14. If the phase was the last one (Phase 5): execute the **Close-out** section below.

If a phase reveals a design decision that contradicts what's locked here, **stop and surface it to the user** — don't silently diverge. Update the plan only after user agreement.

---

## Locked design decisions

These are settled. Do not reopen without user sign-off.

| Decision | Choice | Rationale |
|---|---|---|
| Buff source pool | **Equipped** (pinned to `EmblemBoard` slots), not owned | Future-proofs for grids smaller than collection or limited equip slots; gives player a meaningful loadout decision |
| Auto-fill behavior | Engine reads `EmblemBoardProvider.boardForUserOrAutoFill(uid, unlockedIds)` | Fresh players who never opened picker still get buffs from their unlocks |
| Stacking math | **Additive percent sum, single multiplier:** `final = base × (1 + (companion% + emblem%) / 100)` | User preference — easier mental math, bigger felt bonuses |
| Daily cap | **None** — remove existing 25% companion daily cap entirely | User preference — some companion buffs already exceed 25% by design; level curve will compensate later |
| Granularity carrier | New sealed `EmblemTarget` with `DailyGoalTarget(GoalMetric)` + `ComboQuestTarget` variants | `RewardSourceKind` is too coarse (nutritionXp groups all 5 macros); `GoalMetric` enum already has the right resolution |
| Endgame model | `BlanketEmblemBuff(percent)` that applies to any `EmblemTarget` currently covered by some `PerTargetEmblemBuff` | Avoids endgame buffing future un-buffable targets; preserves single VO shape |
| RPG-mode gate | Emblem buffs return 0 when `!player.rpgModeEnabled` | Mirrors companion buff gating |
| Telemetry | `AppLog` scope `progression.claim.buff` logs per-claim companion% / emblem% / final XP | Critical for retro-tuning |

## Mapping (10 + 1 endgame)

| # | Emblem | EmblemTarget | Buff |
|---|---|---|---|
| 1 | `emblem_pilgrim_mark` (common) | `DailyGoalTarget(GoalMetric.dailyCalories)` | +10% |
| 2 | `emblem_forest_mark` (uncommon) | `DailyGoalTarget(GoalMetric.dailySteps)` | +10% |
| 3 | `emblem_ruin_sigil` (uncommon) | `DailyGoalTarget(GoalMetric.dailyProtein)` | +10% |
| 4 | `emblem_gatekeeper_mark` (rare) | `DailyGoalTarget(GoalMetric.dailyFat)` | +10% |
| 5 | `emblem_mine_crest` (rare) | `DailyGoalTarget(GoalMetric.dailyActivityMins)` ★ | +10% |
| 6 | `emblem_underways_mark` (epic) | `DailyGoalTarget(GoalMetric.dailyCarbs)` | +10% |
| 7 | `emblem_frost_sigil` (epic) | `DailyGoalTarget(GoalMetric.sleepHours)` | +10% |
| 8 | `emblem_icewalker_mark` (epic) | `DailyGoalTarget(GoalMetric.dailyFiber)` | +10% |
| 9 | `emblem_mountain_crest` (legendary) | `DailyGoalTarget(GoalMetric.targetWeight)` | +10% |
| 10 | `emblem_dragon_mark` (legendary) | `ComboQuestTarget()` | +10% |
| 11 | `emblem_dragonrock_emblem` (mythic) | `BlanketEmblemBuff` | +5% to every target covered above |

★ `GoalMetric.dailyActivityMins` does NOT exist yet — Phase 0 adds it.

---

## Phases

### ☑ Phase 0 — Daily activity goal becomes configurable

**Why:** Three sites hardcode the 30-minute daily activity target ([activity_content.dart#L19](../../lib/features/progression_engine/domain/catalog/content/activity_content.dart#L19), [progression_engine_provider.dart#L3451](../../lib/features/progression_engine/application/progression_engine_provider.dart#L3451), [overview_screen.dart#L1309](../../lib/features/home/presentation/overview_screen.dart#L1309)). Phase 1 emblem mapping #5 (`emblem_mine_crest`) targets `dailyActivityMins`, which needs a real `GoalMetric` value backed by a configurable goal. Fixing the hardcode first keeps Phase 1+ clean.

**Scope**
- Add `dailyActivityMins` to [GoalMetric enum](../../lib/features/health_connect/domain/player_goal.dart#L14-L24).
- Add `_kDailyActivityMins` prefs key + `dailyActivity` getter/setter to `GoalsProvider`, default 30.
- Replace the 3 hardcoded `30`s with goal lookups.
- Settings screen exposes the daily activity goal field (minutes integer, range 5–300 or whatever steps/sleep use).
- L10n: new key `goalDailyActivityLabel` (+ Czech translation), `flutter gen-l10n`.

**DoD**
- [ ] `GoalMetric.dailyActivityMins` exists, defaults to 30 when no pref set.
- [ ] All 3 hardcoded `30` sites replaced; grep `dailyActivity.*30` / `_dailyActivityTargetMinutes` returns nothing except the default constant.
- [ ] Settings UI lets user edit the value; persists across app restart (verify via `AppLog` line on save).
- [ ] Existing users (no pref set) see 30 — behavior unchanged.
- [ ] `flutter analyze` clean.
- [ ] Unit test: `GoalsProvider.dailyActivity` round-trips through prefs.
- [ ] Integration test (or manual smoke note): overview activity card respects user-set value.
- [ ] Phase checkbox ticked; commit `goals(93): daily activity goal becomes configurable`.

---

### ☐ Phase 1 — `EmblemBuff` domain layer + catalog

**Scope**
- New file [lib/features/cosmetics/domain/emblem_buff.dart](../../lib/features/cosmetics/domain/emblem_buff.dart):
  - Sealed `EmblemTarget` { `DailyGoalTarget(GoalMetric)`, `ComboQuestTarget()` }.
  - Sealed `EmblemBuff` with `int resolvePercent(EmblemBuffContext)`.
  - `PerTargetEmblemBuff({required EmblemTarget target, required int percent})`.
  - `BlanketEmblemBuff({required int percent})` — applies whenever the context's target is covered by some `PerTargetEmblemBuff` in the active catalogue. Coverage lookup is a static helper for V1.
  - `EmblemBuffContext({required EmblemTarget target, required RewardSourceKind rewardSourceKind})`.
- Extend `Emblem` ([lib/features/cosmetics/domain/cosmetic_models.dart#L215-L233](../../lib/features/cosmetics/domain/cosmetic_models.dart#L215-L233)) with `final EmblemBuff? buff;`, nullable, defaulted in constructor.
- Populate `buff:` for all 11 emblems in [cosmetic_catalog.dart#L321-L442](../../lib/features/cosmetics/domain/cosmetic_catalog.dart#L321-L442) per the mapping table.

**DoD**
- [ ] All new types compile; `Emblem.buff` is nullable on every existing call site without breaking them.
- [ ] 11 emblems each have the correct `EmblemBuff` per the mapping table.
- [ ] Unit tests in `test/features/cosmetics/emblem_buff_test.dart`:
  - per-target match returns the configured percent
  - per-target mismatch returns 0
  - blanket buff returns percent for any covered target
  - blanket buff returns 0 for an uncovered (synthetic) target
  - sealed exhaustiveness check (compile-time)
- [ ] `flutter analyze` clean. Existing cosmetics tests still pass.
- [ ] Phase checkbox ticked; commit `emblems(93): EmblemBuff sealed hierarchy + catalog mapping`.

---

### ☐ Phase 2 — Engine integration (equipped resolve, additive math, no cap)

**Scope**
- Extend [EngineEvaluationContext](../../lib/features/progression_engine/domain/models/engine_evaluation_context.dart#L62-L87) with `final List<EmblemBuff> equippedEmblemBuffs;` (default `const []`).
- [ProgressionEngineProvider](../../lib/features/progression_engine/application/progression_engine_provider.dart) construction reads:
  - `EmblemBoardProvider.boardForUserOrAutoFill(uid, unlockedIds)` to resolve effective equipped set.
  - For each non-null pinned slot id → lookup `Emblem` via catalog → collect non-null `.buff`.
  - RPG mode disabled → pass `const []`.
- New helper [lib/features/progression_engine/application/emblem_target_mapping.dart](../../lib/features/progression_engine/application/emblem_target_mapping.dart):
  - `EmblemTarget? emblemTargetForNode(QuestNode node)` — string switch on node.id for `DailyGoalTarget`, falls back to `ComboQuestTarget` for nodes with `displayBucket == DisplayBucket.combo`, else null.
- Refactor [RewardGrantService._buildXpEvent](../../lib/features/progression_engine/application/reward_grant_service.dart#L175-L210):
  - Compute `companionPct` (percent only, not XP) from existing resolver.
  - Compute `emblemPct` = sum over `context.equippedEmblemBuffs` of `b.resolvePercent(ctx)`.
  - `totalPct = companionPct + emblemPct`.
  - `bonus = (scaled * totalPct / 100).round()`.
  - Split bonus for telemetry: `companionBonusXp = (bonus * companionPct / totalPct).round()` (when `totalPct > 0`), `emblemBonusXp = bonus - companionBonusXp`. Edge case: `totalPct == 0` → both 0.
  - **Remove the `_DailyBuffAccountant` daily cap entirely** ([reward_grant_service.dart#L265-L319](../../lib/features/progression_engine/application/reward_grant_service.dart#L265-L319)). Locked design decision.
- Add `final int? emblemBuffBonusXp;` to [RewardGrantEvent](../../lib/domain/journal/journal_event.dart#L112-L162), persisted to journal.
- `AppLog` scope `progression.claim.buff` — log structured line per claim that touched a buff: nodeId, sourceKind, companionPct, emblemPct, companionBonusXp, emblemBonusXp, finalXp.

**DoD**
- [ ] `EngineEvaluationContext.equippedEmblemBuffs` plumbed through provider.
- [ ] Engine resolves emblem set from `EmblemBoard` (pinned slots), NOT from unlocked set. Verified by integration test where user owns emblem but it's not pinned → no buff applied.
- [ ] Auto-fill path verified: fresh user with unlocked emblem and untouched board → buff applied (boardForUserOrAutoFill populates effective slots).
- [ ] `_DailyBuffAccountant` removed (or its `allowBonus` call sites bypassed); existing companion buff golden tests updated.
- [ ] Math: golden test for `base × (1 + (comp + emb) / 100)` with concrete numbers, rounding behavior locked.
- [ ] Telemetry split: `companionBuffBonusXp + emblemBuffBonusXp == totalBonus` (proportional split, rounding falls into emblem).
- [ ] RPG mode off → `equippedEmblemBuffs` empty → no emblem bonus.
- [ ] `flutter analyze` clean; new + existing tests pass.
- [ ] Phase checkbox ticked; commit `emblems(93): equipped-based buff resolve + additive engine integration (no cap)`.

---

### ☐ Phase 3 — UI discoverability (inventory + claim toast)

**Scope**
- **Inventory emblem tile**: under each emblem in cosmetics inventory list, render 1-line buff label ("Bonus: +10 % XP z denního kcal cíle" / blanket: "Bonus: +5 % XP ze všech denních cílů, na které máš nasazený znak"). Helper pure-function `emblemBuffLabel(EmblemBuff, AppLocalizations)`.
- **Equipped indicator** on emblem tile: badge or border highlight when the emblem is currently pinned somewhere on the user's `EmblemBoard` (since equipped = buffed).
- **Claim toast adornment**: existing reward toast displays `xpAmount`; when `event.emblemBuffBonusXp != null && > 0`, render a small emblem icon + "+N XP (znak)" sub-line. Companion bonus already has analogous treatment — mirror it.
- L10n keys: `emblemBuffPerTarget(metric, percent)`, `emblemBuffBlanket(percent)`, `emblemBuffEquippedBadge`, `claimToastEmblemBonus(amount)`. ARB en + cs. Run `flutter gen-l10n`.

**DoD**
- [ ] Inventory tile shows correct label per emblem definition (per-target and blanket variants both render).
- [ ] Equipped emblems visually distinct from unlocked-but-unequipped ones in inventory.
- [ ] Claim toast for a buffed claim shows the bonus XP line; non-buffed claims unchanged.
- [ ] L10n: en + cs filled, `flutter gen-l10n` ran, no untranslated keys.
- [ ] Widget test: claim toast renders both companion + emblem sub-lines when both fired.
- [ ] Manual UI test in emulator: equip → unequip → buff visibly toggles on next claim.
- [ ] `flutter analyze` clean.
- [ ] Phase checkbox ticked; commit `emblems(93): discoverability — inventory buff labels + claim toast adornment`.

---

### ☐ Phase 4 — Architecture docs

**Scope** (per CLAUDE.md doc conventions table)
- **ADR** in [docs/site/data/decisions.json](../../docs/site/data/decisions.json): id `emblem-buffs`, context (emblems were pure cosmetic; this gives them mechanical weight), decision (equipped-based, additive percent sum, no cap, sealed `EmblemTarget`), consequences (level curve will need recalibration when balance telemetry lands; `_DailyBuffAccountant` removed has knock-on for companion buff ceiling), alternatives rejected (owned-based, multiplicative stack, per-source cap, per-emblem rarity scaling — all deferred to Phase 2 if needed).
- **Glossary** in [docs/site/data/glossary.json](../../docs/site/data/glossary.json): entries for `EmblemBuff`, `EmblemTarget`, `PerTargetEmblemBuff`, `BlanketEmblemBuff`, `EmblemBuffContext`.
- **DataFlows** in [docs/site/data/dataflows.json](../../docs/site/data/dataflows.json): new edge `EmblemBoardProvider → EngineEvaluationContext → RewardGrantService`.
- **Providers** in [docs/site/data/providers.json](../../docs/site/data/providers.json): wire `EmblemBoardProvider` if not yet listed; cross-link to progression engine.
- **Storage** in [docs/site/data/storage.json](../../docs/site/data/storage.json): if `dailyActivityMins` pref key is new architecturally relevant storage, list it.
- **Feature README** [lib/features/cosmetics/README.md](../../lib/features/cosmetics/README.md): add `EmblemBuff` section describing current behavior (no phase status per CLAUDE.md convention).
- **Top-level README** [README.md](../../README.md): mention emblem XP buffs as a player-facing feature in the relevant section.

**DoD**
- [ ] All JSON updates land and the site renders without parse errors (verify by serving `docs/site/` and checking the affected pages).
- [ ] No stale references to "owned-based" or "multiplicative stack" in the JSONs (those were earlier proposals).
- [ ] Feature READMEs match current state — no "TODO" or "planned" markers (per CLAUDE.md convention).
- [ ] Phase checkbox ticked; commit `emblems(93): architecture docs + ADR for emblem buff system`.

---

### ☐ Phase 5 — Close-out

This phase is purely procedural. No new code.

**Scope**
1. Verify all prior phases are checked.
2. Re-run full `flutter analyze` and the target test suites end-to-end.
3. Manual smoke in emulator: equip 2 emblems (one per-target, dragonrock) → claim each daily goal → bonus XP appears in toast + journal.
4. Archive this plan: `git mv docs/emblem_buffs/plan.md docs/emblem_buffs/archive/plan.md`.
5. Move Trello [#93](https://trello.com/c/SNNduXTX) to the **Hotovo** list. Per project Trello workflow (memory: `project_trello_workflow.md`), Hotovo is unused — archive the card directly via `mcp__trello__archive_card` instead, AND apply the right done-marker label if the workflow uses one. Re-check the workflow memory before acting.
6. If [#101 weightXp candidate](https://trello.com/c/HgL2dnTi) revealed additional issues during implementation, comment on it with findings before closing this plan.

**DoD**
- [ ] All phases 0–4 checkboxes ticked.
- [ ] Full `flutter analyze` clean.
- [ ] Manual smoke test confirms end-to-end behavior in emulator.
- [ ] Plan moved to `docs/emblem_buffs/archive/plan.md`.
- [ ] Trello #93 archived/moved per project workflow.
- [ ] Final commit: `emblems(93): close-out — archive plan + done`.

---

## Open questions / risks to surface during implementation

- **`activity` interpretation** — Phase 0 introduces `dailyActivityMins` as a separate goal from `weeklyActivityMins`. Verify the weekly accumulator still works as expected after the daily goal is configurable (no overlap / double-counting in claim events).
- **`_DailyBuffAccountant` removal blast radius** — companion buff balance test fixtures may have baked the 25% cap assumption into expected XP totals. Expect to update those goldens in Phase 2.
- **Catalog coverage of `BlanketEmblemBuff`** — V1 helper is hardcoded against the 10 per-target metrics above. If Phase 0 adds another buffable metric in the future, the blanket coverage must update in lockstep — flag this in code comments at the helper site.
- **Telemetry rounding drift** — proportional split `(bonus * companionPct / totalPct)` may differ from independent computation by ±1 XP. Phase 2 commits to "proportional split, remainder to emblem". Tests must lock this.
- **Migration concern** — none. No persisted state changes shape; new fields default to safe values.

---

## Out of scope (Phase 2+ / future cards)

- Per-emblem rarity scaling (e.g., legendary +15% vs common +10%).
- Diminishing returns for multiple emblems on the same target (mapping is 1:1; activates only if future catalog expands).
- Daily progress screen per-card emblem icon adornment.
- Settings summary "Tvé emblemy buffují X z 10 cílů".
- Per-claim AppLog dashboard / aggregation view (raw lines land in V1; analysis tooling later).
- Address [#101 weightXp candidate](https://trello.com/c/HgL2dnTi) — independent card, not blocking #93.
