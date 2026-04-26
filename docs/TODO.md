# TODO

## Open issues / follow-up checks

- [ ] **Progression evaluates today's nutrition as `0` after midnight**
  - Verify whether this is expected because the current day has no KT entries yet.
  - Decide whether progression should evaluate:
    - current calendar day,
    - last synced day,
    - or selected day context.
  - Important for daily nutrition quests after midnight.

- [ ] **Health range refresh: monitor calories alignment**
  - Range refresh was fixed to use exclusive end date and filter results back to the selected inclusive range.
  - Watch for active calories alignment because calories are still stored as `List<double>` aligned by position with steps.
  - Better future model: `CaloriesRecord(date, kcal)`.

- [ ] **KT overview week/month UI optimization**
  - Avoid repeated `avgField()` / `getRange()` calls inside `build()`.
  - Use one `nutritionSummaryForRange(start, end)` and reuse values for calories, protein, fat, carbs, fiber, etc.

- [ ] **Background sync / notifications: long-term device testing**
  - Test over time on a real device.
  - Android WorkManager timing is not exact and can be deferred.
  - Verify whether debug notifications correctly show background sync behavior.

- [ ] **Health Connect quota monitoring**
  - Avoid unnecessary full 365-day fetches.
  - Prefer incremental/range fetches where possible.
  - Keep DevTools diagnostics available to confirm whether quota errors are caused by app behavior or platform limits.

---

## DevTools

- [ ] **Cache clear actions**
  - Add safe clear actions for Health / KT / Progression cache.
  - Must require confirmation.

- [ ] **Richer DB stats**
  - Add date ranges, record counts, per-day counts, last updated timestamps.

- [ ] **Safe one-off WorkManager trigger**
  - Add a debug-only one-off background sync trigger.
  - Must not affect production scheduling.

- [ ] **Debug metric overrides**
  - Wire debug overrides into calculations.
  - Must be gated by debug mode and never affect production users.

- [ ] **Progression test actions**
  - Add safe debug actions:
    - grant test XP
    - complete test quest
  - Must be clearly marked as debug-only.

- [ ] **Full DevTools l10n**
  - Localize internal DevTools labels.
  - Currently only main entry/title is localized.

---

## Progression Engine

### Bugs / fixes

- [ ] **Achievement reset after data deletion**
  - Check whether achievements remain completed after deleting local/app data.
  - Verify if data is immediately reloaded and achievements are recalculated from historical data.

- [ ] **Completed quest shows time `00:00`**
  - Completed quest currently displays `00:00`, likely future midnight / wrong timestamp formatting.

- [ ] **Achievement notifications repeat on every refresh**
  - Achievement notifications are triggered repeatedly during refresh.
  - Likely related to historical data evaluation and missing persisted claim/notification state.
  - May be addressed by the planned Progression Engine refactor with Firebase-stored claims.

### Planned improvements

- [ ] **Refactor Progression Engine with Firebase claim persistence**
  - Store claimed rewards / achievement notification state in Firebase DB.
  - Prevent duplicate notifications and repeated historical reward claims.
  - Make progression state more reliable across devices/reinstalls.

- [ ] **Add “Your Journey” screen**
  - Overview of levels and long-term progression.
  - Ideas:
    - level timeline
    - XP/progress graph
    - world map / RPG journey map
    - milestone history

---

## UI / UX

- [ ] **Unify visual effects**
  - Sjednotit šipky, glow, přidat třpyt.

- [ ] **Refactor screens into smaller widgets**
  - Split larger screens into smaller presentation widgets.
  - Keep feature-first architecture.
  - Avoid moving business logic into widgets.

- [ ] **Fix weight detail for week/month**
  - Weight detail currently shows current/latest weight instead of average when week/month is selected.
  - For week/month views, show the relevant average for the selected period.

---

## AI Narrator

- [ ] **AI vypravěč**
  - Custom story-based quests.
  - Lightweight analysis of user statistics.
  - RPG/D&D-like guidance and progression flavor.

---

## Platform / Integrations

- [ ] **iOS integration**
  - Prepare/test iOS build and platform-specific health data behavior.

- [ ] **Firebase DB admin dashboard**
  - Admin dashboard/check for monitoring user progression.
  - Useful for checking:
    - XP
    - levels
    - completed achievements
    - quest completion
    - whether progression tuning is reasonable

---

## Notes

- Several Progression Engine bugs may be solved by the planned refactor with Firebase-stored claims and notification state.