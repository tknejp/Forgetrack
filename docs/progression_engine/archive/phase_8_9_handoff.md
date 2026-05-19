# Progression Engine V2 — Phase 8 + Phase 9 handoff

> **Archived 2026-05-19.** Phase 9 (V1 delete) shipped as domain
> refactor Phase 22. Phase 8 (RPG mode readiness) was extracted into
> a standalone, phase-free spec at
> [`../rpg_mode_readiness.md`](../rpg_mode_readiness.md). This
> handoff is kept as a permanent record of how the two phases were
> framed at hand-off time.

Cold-start brief for the two remaining V2 phases. Authoritative plan
+ full design context: [v2_phased_plan.md](v2_phased_plan.md).
Everything before Phase 8 has shipped on `main`.

## Status (2026-05-17)

| Phase | State |
|---|---|
| 0, 0.5, 0.6 — audit, social/journey decouple | ✅ done |
| 1 — domain skeleton | ✅ done |
| 2 — evaluation skeleton | ✅ done |
| 3 — catalog port | ✅ done |
| 4 — persistence (Isar) | ✅ done |
| 5 — celebration integration | ✅ done |
| 6 — progression UI integration (all 8 surfaces) | ✅ done |
| 7 — display resolver swap to V2 catalog | ✅ done |
| **8 — RPG mode readiness** | ⏳ **TODO** |
| **9 — remove legacy progression module** | ⏳ **TODO** (drafts landed, final cleanup pending) |

Phase 9 status caveat: parts of the legacy `lib/features/progression/`
module have already been displaced as side-effects of phase 6 / 7
work, but no single committed pass has done the full
delete-and-verify sweep. Treat phase 9 as TODO and re-validate each
acceptance bullet before closing.

## Orthogonal work landed since Phase 7

A separate post-V2 refactor (retroactive claim window + per-day
quest rotation history) shipped on top of the V2 foundation. Plan
archived at [archive/quest_history_refactor.md](archive/quest_history_refactor.md).
Most relevant for Phase 8 / 9:

- New `QuestOfferedEvent` ledger type + `QuestOfferingRecord` Isar
  collection + `engineQuestOfferings` Firestore subcollection. Phase
  9's "delete legacy Isar collections" sweep should leave these
  intact.
- `EngineBackfillSection` ("Historie odměn") on the quests screen
  replaced the old "Recent rewards" rollup. The legacy delete
  shouldn't touch this surface.
- `claimDailyGoal` / `claimDailyQuest` / `claimActivity` provider
  APIs were added; they live in V2 and don't depend on the legacy
  module.

## Phase 8 — RPG mode readiness ⏳

Quick recap (full spec in [v2_phased_plan.md#phase-8](v2_phased_plan.md)):

- New `RpgModeProvider` (`ChangeNotifier` over a SharedPreferences-
  backed bool). No user-facing toggle.
- `ActivationPolicy` enforcement wired into the resolver + display
  layer.
- Hidden devtools toggle: `Devtools → Progression V2 → RPG mode
  (debug)`.
- Catalog validator rule linking activation policy to content tags.

Acceptance:

- Devtools toggle hides RPG-tagged nodes from quest screen + journey
  without breaking core fitness display.
- Re-enabling RPG retroactively grants any
  `onlyWhenRpgEnabled` (non-NoBackfill) nodes whose objectives are
  already complete.
- No `if (rpgModeEnabled)` literals in UI files (grep verifies).

## Phase 9 — Remove legacy ⏳

Quick recap (full spec in [v2_phased_plan.md#phase-9](v2_phased_plan.md)):

- Delete `lib/features/progression/` entirely (or stash to
  `_legacy_progression/` for one PR cycle).
- Delete legacy Isar collections from the database setup.
- Delete `ProgressionCelebrationAdapter` + `ProgressionCelebrationEvent`.
- Remove any `as legacy` import prefixes.
- Update Isar generated bindings; factory-reset test devices.

Acceptance:

- `flutter analyze` clean.
- Full test suite passes.
- App boots into a clean V2 progression state on a test device.

Verification checklist before closing:

- [ ] `grep -r "progression/" lib/` returns zero hits (apart from
      `progression_engine/`).
- [ ] `grep -r "ProgressionCelebrationAdapter\|ProgressionCelebrationEvent" lib/`
      returns zero hits.
- [ ] No `as legacy` prefixes remain.
- [ ] Old Isar collections (`ProgressionEvaluationRecord`,
      `ProgressionRewardGrantRecord`, `ProgressionQuestRewardGrantRecord`,
      `ProgressionActiveQuestRecord`, `ProgressionAchievementUnlockRecord`,
      `ProgressionChapterStartLocalRecord`) are removed from
      `ProgressionDatabase` schema list.

## Closing the V2 plan

Once Phase 8 + Phase 9 are both green:

1. Mark them ✅ in [v2_phased_plan.md](v2_phased_plan.md).
2. Move `v2_phased_plan.md` into `archive/` per the CLAUDE.md
   "closing out a finished plan" workflow.
3. Delete this handoff doc.
4. Update [docs/site/data/decisions.json](../site/data/decisions.json)
   if Phase 8 introduced any ADR-worthy design call (RPG-mode
   activation policy, content-tag linkage).
