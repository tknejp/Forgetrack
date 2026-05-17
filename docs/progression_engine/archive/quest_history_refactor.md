# Quest History Refactor — Plan

Working doc for the daily-quest history + rotation refactor.
Cold-start read this end-to-end before resuming.

## Problem

1. Daily challenge pool uses `LifetimeScope` — once any challenge is
   claimed it leaves the pool permanently. Player frustration:
   challenges should rotate constantly with anti-repeat protection,
   not retire after one claim.
2. When the engine evaluates a daily quest as completed but the
   player hasn't tapped the claim pill, the `sticky-claim-today`
   branch in `DailySectionResolver` pins that quest in the slot for
   the rest of the day. Combined with `LifetimeScope`, this lets a
   completed-not-claimed quest block a fresh pick the next day too.
3. No mechanism tracks "which quests were offered on which day".
   Without history, the rotation has no memory and can show the same
   challenge back-to-back via FNV(date) coincidence.
4. `_CompletedSection` on the quests screen collects every completion,
   so chapter milestones mix with one-off daily claims. The sections
   should split by lifespan: long-term / chapter milestones in the
   completed section, daily rotations in the backfill audit.

## Final design

### Universal rule

**A quest stays in its daily-section slot for the full calendar day it
was offered.** Rotation only happens across the midnight boundary,
never mid-day. Completion or claim within the day does NOT free the
slot; the player sees the slot evolve through `available → claimable
→ claimed` states without the underlying quest changing.

### Per-tier behaviour

| Tier | Source | Mid-day behaviour | Midnight rotation | Cooldown |
|---|---|---|---|---|
| 1 Pinned chapter side quest | `PinClaimedTodayUntilMidnight` | Today's pick locked; can be completed + claimed in slot. | Next eligible side quest (or chapter retires). | None — picked by first-eligible. |
| 2 Combo chain step | `ChainPlaceholderUntilMidnight` | Today's step locked. After claim, the engine's `NodeCompletedBeforeToday` already keeps the next step gated; placeholder branch holds the just-claimed step in the slot. | Walks `chainOrder` to the next step. | None — chain naturally advances. |
| 3 Daily challenge | `DailyChallengeHashPick` | Today's pick locked. Completed + claimed → claimed pill shown until midnight. | Fresh pick from cooldown-filtered pool. | **2 days** — challenge can't be offered the day after today. Day +2 is allowed. |

### Scope flip for daily challenges

`daily_challenge_*_obj` objectives change `LifetimeScope` →
`TodayScope`. Each calendar day gets its own
`ObjectiveCompletionEvent` / `NodeCompletionEvent` (period-keyed),
so the same challenge can complete + claim every day it's offered.
Lifetime "once and done" semantics retire.

**Migration**: existing pre-refactor `LifetimeScope` completion
events for these objectives stay in the ledger untouched. They have
`periodKey: null` and don't interfere with the new `TodayScope`
evaluation, since the evaluator keys today's completion by
`periodKey = yyyy-MM-dd`. Dead data, no migration pass required.

### New ledger event: `QuestOfferedEvent`

```dart
class QuestOfferedEvent extends LedgerEvent {
  const QuestOfferedEvent({
    required super.eventKey, // "offered|<nodeId>|<yyyy-MM-dd>"
    required super.timestamp,
    required this.nodeId,
    required this.dayKey,    // "yyyy-MM-dd"
  });
}
```

Idempotent by eventKey. Written **once per (nodeId, day)** by the
provider's evaluation cycle — NOT by the resolver itself, to keep the
resolver pure. Resolver returns the planned events alongside the slot
list; provider diffs against ledger and writes new ones.

### Cooldown filter

`recentlyOfferedNodeIds(N)` reads all `QuestOfferedEvent`s with
`dayKey` in the last `N` calendar days (exclusive of today). The
challenge tier filters its pool against this set; chain and pin
tiers ignore it (their own gating handles rotation).

`N = 2` per design decision. Six challenges with two-day cooldown
gives reasonable variety without strict round-robin (which would
require N=5).

### Backfill section becomes the daily-quest history

`EngineBackfillSection` (Historie odměn) grows a third row type —
`_DailyQuestRow` — alongside the existing daily-goal rows and
activity rows. A daily quest appears in the day card matching its
`QuestOfferedEvent.dayKey`. State: `locked / claimable / claimed`
follows the engine's standard pill semantics.

Compact styling: small quest icon + title + pill. No description, no
chain dots — those live on the main quest cards. Retroactive claim
window stays at 7 days (same as daily goals), independent of the
2-day rotation cooldown.

### Completed section narrows

`_CompletedSection` on the quests screen filters out everything that
now belongs in the backfill:

- All `QuestDisplayBucket.daily` nodes (per-metric daily goals + the
  bonus daily section slots).
- Individual combo chain steps (chain finale stays; per-step claims
  go to backfill).
- Chapter side quests (the side quest's finale node stays; per-step
  claims if any go to backfill).

Section keeps: chapter milestone finales, long-term entries, weekly
quests, achievements.

## Implementation phases

Each phase ships independently with `flutter analyze` clean and is
committed before moving on.

### Phase 1 — Ledger event scaffolding

- `domain/models/ledger_event.dart` — new sealed-class child
  `QuestOfferedEvent`.
- `domain/repository/ledger_snapshot.dart` — new field
  `List<QuestOfferedEvent> questOfferings`, `hasEventKey` covers it,
  `all` yields it.
- `data/local/progression_engine_local_models.dart` — Isar
  collection `QuestOfferingRecord` (`eventKey`, `timestamp`, `nodeId`,
  `dayKey`).
- `data/local/progression_engine_local_models.g.dart` — regen via
  build_runner if used; otherwise hand-write the schema.
- `data/isar_progression_engine_repository.dart` — load/save mapping.
- `data/in_memory_progression_engine_repository.dart` — append +
  loadLedger mapping.
- `data/firestore_progression_engine_gateway.dart` — collection
  `_questOfferingCollection`, doc mapping, push/pull.
- `data/hybrid_progression_engine_repository.dart` — wire through.

**Commit**: `Engine ledger: QuestOfferedEvent type + persistence`.

### Phase 2 — Catalog scope flip

- `domain/catalog/content/daily_challenge_content.dart` —
  6× `scope: LifetimeScope()` → `scope: TodayScope()` on the
  `daily_challenge_*_obj` definitions.
- Verify operator + target unchanged.

Existing tests using these objectives may need a per-day periodKey
update — check `progression_engine/` test files and adjust.

**Commit**: `Daily challenges become TodayScope (per-day rotation)`.

### Phase 3 — DailySectionResolver refactor

- New signature returns `({List<EngineQuestProgress> slots, List<QuestOfferedEvent> plannedOfferings})`.
- Inputs: existing + `recentlyOfferedNodeIds: Set<String>`,
  `todayOfferedByNodeId: Map<String, QuestOfferedEvent>`, `engineNow`.
- Algorithm:
  1. Reuse today's existing offered events: for each, find the
     matching `EngineQuestProgress` and add to slots.
  2. Fill remaining slots: tier 1 (pin) → tier 2 (chain) → tier 3
     (challenge, cooldown-filtered).
  3. For every newly-picked node, generate a `QuestOfferedEvent`
     for today and add to `plannedOfferings`.
- Drop the `sticky-claim-today` early-return branch in
  `_pickChallenge` — today's offered event already pins it.
- Tests in `test/progression_engine/daily_section_resolver_test.dart`
  cover: cooldown filter, sticky-by-offered-event, fresh pick.

**Commit**: `DailySectionResolver: offered-history-based rotation`.

### Phase 4 — Provider wiring

- `progression_engine_provider.dart`:
  - `currentDailyQuests` getter still returns slots; reads
    `_lastResult.dailySectionSlots` or re-runs resolver.
  - In `_evaluate()` (post-engine-evaluation): call resolver, diff
    `plannedOfferings` vs existing ledger by `eventKey`, append new.
    Reload ledger if any written.
  - New `claimDailyQuest({String nodeId, DateTime day})` — analog
    of `claimDailyGoal`. Writes the 4-event sequence
    (`ObjectiveCompletionEvent` + `NodeCompletionEvent` +
    `NodeClaimEvent` + `RewardGrantEvent`) with `periodKey = yyyy-MM-dd`.
    Reuses the same retroactive-window check.
- `_ledgerEventSignature()` extends to include `questOfferings.length`
  so refresh invalidation fires when offerings change.

**Commit**: `Provider: persist daily offerings + claimDailyQuest API`.

### Phase 5 — Backfill section integration

- `domain/backfill/daily_backfill_models.dart`:
  - New view model `DailyQuestClaimItem` (parallel to
    `DailyGoalClaimItem`): `node`, `domain`, `previewXp`, `isClaimed`,
    `isClaimable`, `isWithinWindow`.
  - `DailyBackfillEntry.dailyQuests: List<DailyQuestClaimItem>`.
  - `claimableXp`, `claimedXp`, `pendingCount`, `hasAnyContent`
    fold the new collection in.
- `progression_engine_provider.dart`:
  - `dailyBackfillForRange` computes daily quests per day by reading
    `QuestOfferedEvent`s and resolving each to a claim item.
- `presentation/widgets/engine_backfill_section.dart`:
  - New `_DailyQuestRow` widget: quest icon + title (`node.titleKey`)
    + `XpClaimPill`. Compact, no description / chain dots.
  - `_BackfillDayCard` expanded body renders quests before activities,
    after daily goals (priority order: goals → quests → activities).
- L10n: empty-state caption + maybe a section subheader.

**Commit**: `Backfill section: per-day daily-quest history rows`.

### Phase 6 — Completed section narrowing

- `presentation/quests_screen.dart` `_CompletedSection`:
  - Filter input list of `EngineCompletedEntry` to exclude:
    - `QuestDisplayBucket.daily` nodes,
    - per-step combo chain entries (keep only the chain's finale node).
  - Empty state copy if entire section ends up empty.
- Provider `completedEntries` getter may need an opt-in
  `includeDailyAndCombo: bool = false` parameter so other surfaces
  (devtools, journey) can still see the full list.

**Commit**: `Completed section drops daily/combo per-step entries`.

### Phase 7 — Localization sweep

- `lib/l10n/app_en.arb` + `app_cs.arb`:
  - `progBackfillDailyQuestSectionLabel` (optional sub-divider in
    day card).
  - Quest-row variant strings if needed.
- Drop any orphaned strings from the old completed flow.

**Commit**: `L10n: backfill daily-quest section strings`.

### Phase 8 — "Pro dnešek splněno" slot overlay (visual polish)

- Daily challenge card in DENNÍ ÚKOLY: when the engine resolves it as
  completed-claimed today, render a subtle overlay or chip
  ("Pro dnešek splněno · Návrat zítra") so the player understands
  why the slot doesn't rotate.
- Pure presentation. No engine impact.

**Commit**: `Daily quest slot: completed-today overlay`.

## Risk register

- **Day-rollover while app is open**: `_evaluate()` only re-runs on
  input changes. If the user keeps the app open across midnight, the
  resolver won't write tomorrow's offerings until the next refresh
  trigger. Reality: cold-starts cover 99 % of cases. If we see a real
  bug, add a periodic timer that bumps `_lastEvaluatedSignature`
  every 60 s.
- **`devDayOffset` interaction**: devtools' "Advance day +1" already
  routes through `_engineNow()`. Make sure resolver uses
  `engineNow` parameter (not `DateTime.now()` directly) so the
  devtools button keeps working end-to-end.
- **Firestore sync ordering**: a `QuestOfferedEvent` followed
  rapidly by a `NodeClaimEvent` for the same node should arrive in
  order. The gateway batches by collection, so cross-collection
  ordering isn't strict. Idempotent eventKeys mean replay-safe; the
  resolver doesn't care which arrived first.
- **Reward-count metrics**: existing `RewardCountMetric(ruleId:
  'daily_challenge_*')` (if any) count `RewardGrantEvent`s. The new
  per-day grant flow continues to fire grants, so the count keeps
  ticking. No catalog change needed.
- **Combo finale visibility**: chain finale node currently lives in
  `_CompletedSection` after the whole chain closes. Phase 6's filter
  must keep it (only per-step entries drop). Test this — the
  `EngineCompletedEntry.chainQuests` shape needs to be re-inspected.

## Followups (out of scope)

- Pinned-side-quest cooldown: not needed today, but if/when chapters
  carry many parallel side quests we may want explicit rotation.
- Combo finale → "Dokončené úkoly": currently auto-handled. Confirm
  during Phase 6 testing.
- Day-rollover timer: see risk register.
- Devtools button to wipe offered-history for testing.
