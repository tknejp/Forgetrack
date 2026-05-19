# Forgetrack — Claude Code Instructions

Flutter fitness/RPG tracking app. Feature-first architecture under `lib/features/`.

## Where to look

- **Architecture, layering rules, design tokens, dependency rules, HC / KT / progression invariants:** [docs/architecture.md](docs/architecture.md)
- **Progression Engine V2:** the V2 migration shipped 2026-05-19. Live open work is [docs/progression_engine/rpg_mode_readiness.md](docs/progression_engine/rpg_mode_readiness.md). Completed plans (V2 phased migration, Phase 8/9 handoff, quest history refactor) are permanent design records under [docs/progression_engine/archive/](docs/progression_engine/archive/).
- **Domain model refactor:** shipped (2026-05-19) and the Track A close-out round (R.1–R.8) shipped the same day. Permanent design records in [docs/domain_model/](docs/domain_model/) — `proposal.md` (target shape) — plus archived plans under [docs/domain_model/archive/](docs/domain_model/archive/) — `migration_plan.md` (the 22-phase plan) and `follow_ups.md` (Track A bounded round + Track B/C/D parking lots). Architectural decisions land as ADRs in `docs/site/data/decisions.json` (see `track-a-closed` for the umbrella close-out).
- **Feature designs:** [docs/features/](docs/features/) — coach log export, Firestore sync.
- **External API capture:** [docs/integrations/](docs/integrations/) — Kalorické Tabulky.
- **Feature internals:** READMEs in `lib/features/<feature>/`.
- **Interaktivní architektura (web):** [docs/site/](docs/site/) — statický web s mapou feature, grafem providerů, datovými toky, úložištěm, integracemi, slovníkem, RPG vrstvou a ADRs. Spuštění: `python -m http.server 8000 --directory docs/site`; hosting přes GitHub Pages.

## Coding style

- Prefer simple imperative code. Avoid streams unless they clearly simplify the solution.
- Keep business logic out of widgets; put it in `application/` providers or `domain/` services.
- Use `AppLog` from `lib/core/logging/app_log.dart` for sync / reset / export / progression / cosmetics steps. Never use `print()`.
- No migrations unless explicitly requested — the app can be reset during development.

## Localization

- Strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_cs.arb`. After editing either file, run `flutter gen-l10n`.
- Catalog entries use closure-style localization: `name: (l10n) => l10n.cosmeticXxxName`. Missing ARB keys break the build.

## Verification after changes

- `flutter analyze` clean (pre-existing Isar `.g.dart` warnings are accepted).
- Run relevant `flutter test` files for the area you touched.

## Documentation conventions

- READMEs in `lib/features/<feature>/` describe **what is currently there** — current files, current dependencies, current behavior. They do NOT contain phase status, planning, work logs, or status tables.
- Plans, refactor docs, and phase trackers live in `docs/`, never inside `lib/`.
- **Interactive architecture site** lives in `docs/site/`. Update its JSON data when the underlying architecture changes:
  - New feature → `docs/site/data/features.json`
  - New provider / new DI edge → `docs/site/data/providers.json`
  - New Isar collection, Firestore subcollection, prefs key → `docs/site/data/storage.json`
  - New external system → `docs/site/data/integrations.json`
  - New significant data flow → `docs/site/data/dataflows.json`
  - New sealed type → `docs/site/data/glossary.json`
  - New architectural decision → `docs/site/data/decisions.json`

### Closing out a finished plan

When every phase of a `docs/<area>/*_refactor.md` (or similar plan doc) has shipped, treat it as a permanent design record and clean up the surrounding docs in the same commit:

1. **Archive, don't delete.** Move the plan to `docs/<area>/archive/<plan>.md` (create `archive/` if it doesn't exist). It stays as a permanent design record — future maintainers should be able to read why the system looks the way it does.
2. **Update the working-state doc** in the same area (per-handoff doc focused on the open phases — e.g. `docs/progression_engine/rpg_mode_readiness.md` for the V2 successor work). Add a dated block summarising the outcomes + linking to the archived plan, so a cold-start session sees the latest state without reading the whole archive. Once the handoff's own scope closes, retire it too — don't accumulate stale handoffs.
3. **Update the interactive architecture site JSONs** per the table above for every architectural change the plan introduced — new collections / providers / sealed types / data flows / external integrations.
4. **Add ADRs** to `docs/site/data/decisions.json` for non-trivial design decisions the plan landed (context + decision + consequences + alternatives). The code says HOW; the ADR says WHY.
5. **Surface user-visible features** in the top-level `README.md` so the project description reflects what the app actually does today.
6. **Update related feature docs** in `docs/features/*.md` (e.g. `firestore_sync.md`) when the plan changes wire formats, sync semantics, or introduces known limitations / gaps.

## Output expectations

- Before editing, inspect the relevant files.
- Make minimal targeted changes.
- After changes, summarize modified files and remaining risks.
