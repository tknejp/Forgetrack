# Changelog

VÅ¡echny vÃ½znamnÃ© zmÄ›ny v Forgetrack. FormÃ¡t podle [Keep a Changelog](https://keepachangelog.com/), verzovÃ¡nÃ­ podle [SemVer](https://semver.org/).

GenerovÃ¡nÃ­ pÅ™i release: viz [docs/git_workflow.md Â§3a](docs/git_workflow.md).

## [Unreleased]

## [0.2.0] - 2026-05-27

## [0.1.0] - 2026-05-22

PrvnÃ­ testovacÃ­ build â€” internÃ­ validace Firestore sync, distribuovÃ¡no 1 testerovi. Tag retroaktivnÄ› pÅ™idÃ¡n 2026-05-27 jako souÄÃ¡st zavedenÃ­ git workflow; samotnÃ½ release event probÄ›hl 2026-05-22.

### Added

- Sentry crash reporting + in-app feedback (Tier 0 #70).

### Notes

- Build artefakt nesl verzi `1.0.0+1` (Flutter default, nikdy nebumpnutÃ½). RetroaktivnÄ› oznaÄeno `v0.1.0` aby odpovÃ­dalo skuteÄnÃ©mu stavu projektu (pre-stable, SemVer `0.x.y`).
- 2026-05-27 (samostatnÃ½ commit po tomto tagu): bumpnuto `pubspec.yaml` â†’ `0.1.0+2` a zaloÅ¾en tento changelog jako souÄÃ¡st zavedenÃ­ [git workflow](docs/git_workflow.md). Build number `+2` kvÅ¯li Android monotonic check; reinstalace u testera vyÅ¾aduje uninstall.
- Historie pÅ™ed tÃ­mto tagem je pre-workflow â€” Å¾Ã¡dnÃ½ backfill changelogu.

[Unreleased]: https://github.com/tknejp/Forgetrack/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/tknejp/Forgetrack/releases/tag/v0.2.0
[0.1.0]: https://github.com/tknejp/Forgetrack/releases/tag/v0.1.0
