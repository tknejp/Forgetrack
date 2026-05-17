# Config Model Refactor — Placeholder

**Status:** Deferred. **Do not start design until [docs/domain_model/proposal.md](../domain_model/proposal.md) is accepted.**

---

## Why this folder exists

The user identified that configuration settings are scattered across the codebase (SharedPreferences keys, secure storage, in-code constants, per-feature config classes, build-time environment) and wants a consolidated config system separate from the domain model refactor.

This folder reserves the slot. The actual handoff + proposal will be written in a dedicated session once the domain model lands.

---

## Why config is separate from the domain model

See [docs/domain_model/session_handoff.md § "Out of scope — configuration"](../domain_model/session_handoff.md) for the discriminating heuristic. Short version:

| Domain | Config |
|---|---|
| History, per-instance, event-derivable | Current value, singleton-ish, key/value |
| Mutated by use cases | Mutated by settings UI / build flags / remote |

Mixing them in one design session dilutes both. The two refactors share no persistence, no aggregate semantics, no migration path.

---

## Surfaces the config refactor will need to consolidate

Inventory done in earlier sessions ([docs/site/data/storage.json](../site/data/storage.json), and from code surveys). When the config session kicks off, start here:

### 1. `SharedPreferences` (11 keys at last audit)
- `joinedAt` — player's first-launch timestamp
- locale preference
- RPG mode flag
- last-sync timestamps per feature (multiple keys)
- onboarding-completion flags
- (verify exact list against current code at session start)

### 2. `flutter_secure_storage` (2 keys)
- Kalorické tabulky credentials (cookie / session)
- (verify)

### 3. In-code constants (scattered across `config/` and `_config.dart` files)
- `kBackfillClaimLookbackDays` (`progression_engine/domain/backfill/backfill_config.dart`)
- `CosmeticsConfig.standard()` (`cosmetics/config/cosmetics_config.dart`)
- Any other `kXxx` constants the audit surfaces

### 4. Per-feature config classes
- `CosmeticsConfig` — slot allow-list, experimental flags
- Possibly engine catalog context (`EngineCatalogContext`) — borderline; may stay where it is
- (audit at session start)

### 5. Build-time / environment
- Firebase config (`firebase_options.dart`)
- API keys (if any inlined)
- Debug build flags (`kDebugMode`, custom dev flags)
- `flavor` if introduced

### 6. Theming / design tokens
- `lib/shared/theme/design_tokens.dart` — colors, spacing, radii. **This is design system, not config.** Note it here so the next session can explicitly decide whether to leave it alone (recommended) or fold a sliver into config (e.g. user-selectable theme).

---

## Open questions for the config kickoff (do not answer now)

1. **Typed config root vs split per concern?**
   - Single `AppConfig` aggregate vs `UserPreferences` + `FeatureFlags` + `BuildEnv` separated.
2. **Remote config (Firebase Remote Config, custom backend)?**
   - Is A/B / live tunability a near-future requirement, or is local-only enough?
3. **Settings UI surface.**
   - Where do user-editable settings live? Existing `settings/` feature is the natural home — confirm it stays.
4. **Migration of existing SharedPreferences keys.**
   - Backwards compat for users on the current build — keys can't be renamed without a migration path.
5. **Code-gen for config (e.g. `envied`, `flutter_config_plus`)?**
   - Probably overkill for the current scale; revisit only if env-var injection becomes a real need.
6. **Devtools toggle UX.**
   - Many configs are devtools-only (e.g. day-shift offset). Should they live in a unified `FeatureFlags` surface or stay scattered?

---

## Definition of done for the eventual config refactor

Like the domain model: the proposal landing in `docs/config_model/proposal.md` is "done" when:

- [ ] Every config-y thing in the codebase has been catalogued (one searchable list).
- [ ] Each entry is classified: user preference / feature flag / tunable / build-time / secret.
- [ ] A single typed API for reading / writing each kind is proposed.
- [ ] Persistence layer per kind is named (SharedPreferences / secure storage / Firebase Remote / env file).
- [ ] Migration path from current scattered state is sketched.
- [ ] Devtools integration is decided (single panel vs current scattered tiles).

---

## When to revisit

After [docs/domain_model/proposal.md](../domain_model/proposal.md) is accepted **and at least one aggregate (Player) is implemented**. Implementing the first aggregate will inform what config seams emerge — better to design config knowing what it has to serve, not in the abstract.
