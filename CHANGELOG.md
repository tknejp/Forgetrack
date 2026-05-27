# Changelog

Všechny významné změny v Forgetrack. Formát podle [Keep a Changelog](https://keepachangelog.com/), verzování podle [SemVer](https://semver.org/).

Generování při release: viz [docs/git_workflow.md §3a](docs/git_workflow.md).

## [Unreleased]

## [0.1.0] - 2026-05-27

Baseline release — zavedení správného SemVer verzování (`0.x.y` pro pre-stable) a [git workflow](docs/git_workflow.md).

### Changed

- Verze v `pubspec.yaml` z výchozího Flutter `1.0.0+1` na `0.1.0+2`. Reflektuje skutečný stav (pre-beta) místo zavádějícího `1.0.0`, které by sémanticky znamenalo stabilní veřejné API. Build number bumpnut na `+2` kvůli monotónnímu růstu (Android blokuje downgrade přes stejné application ID).

### Notes

- Historie před tímto tagem je pre-workflow — žádný backfill changelogu.
- První testovací build (1.0.0+1) byl distribuován pouze jednomu interním testerovi; reinstalace přes 0.1.0+2 vyžaduje uninstall.

[Unreleased]: https://github.com/tknejp/Forgetrack/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tknejp/Forgetrack/releases/tag/v0.1.0
