# Forgetrack — Claude Code Instructions

Flutter fitness/RPG tracking app. Feature-first architecture under `lib/features/`.

## Where to look

- **Architecture, layering rules, design tokens, dependency rules, HC / KT / progression invariants:** [docs/architecture.md](docs/architecture.md)
- **Progression Engine V2:** plan + live phase status in [docs/progression_engine/](docs/progression_engine/) — read `session_handoff.md` first when resuming V2 work.
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
- Plans, refactor docs, and phase trackers live in `docs/`, never inside `lib/`. When a plan is fully implemented, delete it — durable knowledge belongs in the relevant feature README or in `docs/architecture.md`.
- **Interactive architecture site** lives in `docs/site/`. Update its JSON data when the underlying architecture changes:
  - New feature → `docs/site/data/features.json`
  - New provider / new DI edge → `docs/site/data/providers.json`
  - New Isar collection, Firestore subcollection, prefs key → `docs/site/data/storage.json`
  - New external system → `docs/site/data/integrations.json`
  - New significant data flow → `docs/site/data/dataflows.json`
  - New sealed type → `docs/site/data/glossary.json`
  - New architectural decision → `docs/site/data/decisions.json`

## Output expectations

- Before editing, inspect the relevant files.
- Make minimal targeted changes.
- After changes, summarize modified files and remaining risks.
