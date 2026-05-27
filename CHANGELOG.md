# Changelog

Všechny významné změny v Forgetrack. Formát podle [Keep a Changelog](https://keepachangelog.com/), verzování podle [SemVer](https://semver.org/).

Generování při release: viz [docs/git_workflow.md §3a](docs/git_workflow.md).

## [Unreleased]

## [0.1.0] - 2026-05-22

První testovací build — interní validace Firestore sync, distribuováno 1 testerovi. Tag retroaktivně přidán 2026-05-27 jako součást zavedení git workflow; samotný release event proběhl 2026-05-22.

### Added

- Sentry crash reporting + in-app feedback (Tier 0 #70).

### Notes

- Build artefakt nesl verzi `1.0.0+1` (Flutter default, nikdy nebumpnutý). Retroaktivně označeno `v0.1.0` aby odpovídalo skutečnému stavu projektu (pre-stable, SemVer `0.x.y`).
- 2026-05-27 (samostatný commit po tomto tagu): bumpnuto `pubspec.yaml` → `0.1.0+2` a založen tento changelog jako součást zavedení [git workflow](docs/git_workflow.md). Build number `+2` kvůli Android monotonic check; reinstalace u testera vyžaduje uninstall.
- Historie před tímto tagem je pre-workflow — žádný backfill changelogu.

[Unreleased]: https://github.com/tknejp/Forgetrack/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tknejp/Forgetrack/releases/tag/v0.1.0
