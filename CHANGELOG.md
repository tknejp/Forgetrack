# Changelog

Všechny významné změny v Forgetrack. Formát podle [Keep a Changelog](https://keepachangelog.com/), verzování podle [SemVer](https://semver.org/).

Generování při release: viz [docs/git_workflow.md §3a](docs/git_workflow.md).

## [Unreleased]

## [0.2.0] - 2026-05-27

Druhý testovací build. Avatary (race × skin), kosmetika přes Firestore, redesign profilu, interactive journey map, V2 background notifikace. Vyžaduje úplnou přeinstalaci — měnilo se DB schéma a proběhl wipe Firestore dat.

### Added

- Race × skin avatar systém + redesign profil hero karty.
- Tabbed own-profile screen (Přehled / Inventář).
- Unified profile detail s painted scene + scroll-up appbarem.
- Emblem-board slot progression + level-tier title isolation.
- Equippable title banner slot + katalog 7 bannerů.
- Profile stats section s per-stat visibility overrides.
- Background slot sheet pro hero-scene picker.
- Cosmetics Firestore hybrid sync + realtime entitlements stream [#82] [#110].
- Preview-thumb systém + live-chrome banner v inventáři.
- Oathbound skin (lvl 30) + level-aware unlock hints.
- Skin odměny na meziúrovních + sjednocená rarity paleta.
- Interactive journey map s fog overlay; milestone tooltip s reward/date daty.
- V2 background quest + achievement push notifikace [#80].
- Per-category notification settings + gated boot permission prompt.
- HC offline-cache status + recovery flow na home kartách.
- KT auth recovery cascade + unified home/detail prompt.
- Android: opt-in high refresh rate přes flutter_displaymode.
- Devtools: cosmetic entitlement grant script + Firestore devUsers/{uid} runtime grant [#82] [#106].

### Changed

- **Auth:** Firebase UID jako canonical Firestore key + plné security rules.
- **Firestore rules:** devUsers/{uid} + cosmetic hybrid carve-outs.
- **Progression:** sjednocený chapter katalog s level-bandovanými rarities odpovídajícími emblémům.
- Hero/profile: split dashboard vs social card roles [#85].
- Quest UI Phase 1–2 perf pass: EngineCard template + hero-pattern bg, StatCard expand raster fix, scroll jank fix + home per-card subscriptions, quest screen split do `sections/` [#85].
- Home: sjednocené titulky karet + goal inline + relokace XP bonus chipů.
- Shell: SnappyPageScrollPhysics + DragRevealPager side-page warm-up.
- Avatars Phase 2: compact thumbs + social wire format `raceId`/`skinId`.
- Social: zvětšen banner level gem + dropnutý prefix "Lv."
- Social: zvětšen emblem artwork + zmenšen frame u empty/locked slotů.
- Social: sjednocený slot-sheet chrome + inline identity row pod jménem.
- Android: migrace na Built-in Kotlin.
- Progression engine: pre-allocate combo chain generations [#117].

### Fixed

- Progression: replay background-fired completions při návratu do foreground.
- Devtools: force engine re-eval po factory reset, aby se znovu odpálila welcome sekvence.
- Shell: snappy page physics se vracela při tapu během forward swipe.
- Home: cache pager pages během day swipe (per-tick rebuild jank).
- Perf: memoise katalogu + read projections, oprava mrtvé snappy page physics.
- l10n: cosmetics screen + notifikace routovány přes AppLocalizations.

### Removed

- Photo upload — nahrazen race × skin systémem.

## [0.1.0] - 2026-05-22

První testovací build — interní validace Firestore sync, distribuováno 1 testerovi. Tag retroaktivně přidán 2026-05-27 jako součást zavedení git workflow; samotný release event proběhl 2026-05-22.

### Added

- Sentry crash reporting + in-app feedback (Tier 0 #70).

### Notes

- Build artefakt nesl verzi `1.0.0+1` (Flutter default, nikdy nebumpnutý). Retroaktivně označeno `v0.1.0` aby odpovídalo skutečnému stavu projektu (pre-stable, SemVer `0.x.y`).
- 2026-05-27 (samostatný commit po tomto tagu): bumpnuto `pubspec.yaml` → `0.1.0+2` a založen tento changelog jako součást zavedení [git workflow](docs/git_workflow.md). Build number `+2` kvůli Android monotonic check; reinstalace u testera vyžaduje uninstall.
- Historie před tímto tagem je pre-workflow — žádný backfill changelogu.

[Unreleased]: https://github.com/tknejp/Forgetrack/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/tknejp/Forgetrack/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tknejp/Forgetrack/releases/tag/v0.1.0
