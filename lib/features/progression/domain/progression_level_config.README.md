# Progression Level Config — single source of truth

Tento soubor dokumentuje refactor, který sjednotil metadata o levelech (titul, emoji, obtížnost, journey breakpointy, achievement IDs) do jednoho centrálního konfiguračního modulu.

> **Slouží jako trvalá reference.** Pokud budeš někdy upravovat tituly, emoji nebo obtížnost levelů, čti nejdřív tohle.

---

## Proč tenhle refactor vznikl

Před refaktorem byla data o levelech roztroušená přes 4+ souborů a vzájemně nekonzistentní:

- `progression_level_policy.dart` mělo svou ladder (Troll → Wanderer → Pathfinder → … → Living Legend)
- `social_helpers.dart` mělo **úplně jinou** ladder (Novice Adventurer → Pathfinder → Trail Vanguard → … → Living Legend) → ten samý level zobrazoval různé tituly podle obrazovky
- `progression_achievement_catalog.dart` mělo achievementy s **třetí variantou** názvů zakódovaných v `id` (např. `pathfinder_level_5` ale title v ARB byl „Wanderer"; `dawn_sentinel_level_30` ale title byl „Castle Lord")
- `progression_badge_specs.dart` drželo level → emoji mapu a duplikovaný breakpoint list
- `journey_adapter.dart` drželo další seznam milestone úrovní

Cíl: **jeden config, jeden zdroj pravdy.** Změna titulu/emoji/obtížnosti = úprava jednoho záznamu.

---

## Architektura

```
┌──────────────────────────────────────────────────────────────────┐
│  progression_level_config.dart   ◄── SINGLE SOURCE OF TRUTH       │
│  ────────────────────────────                                     │
│  • kProgressionLevelTiers : List<ProgressionLevelTier>            │
│       (level, achievementId, emoji, difficulty, anchor flags)     │
│  • kProgressionDecorativeLevelEmoji : Map<int, String>            │
│  • tierForLevel / emojiForLevel / levelFromAchievementId          │
│  • kLevelTitleBreakpoints / kJourneyMapAnchors                    │
│  • ProgressionLevelMilestone : runtime view-model                 │
└──────────────────────────────────────────────────────────────────┘
                          ▲             ▲             ▲
              ┌───────────┘             │             └───────────┐
              │                         │                         │
   ┌──────────┴──────────┐   ┌──────────┴──────────┐   ┌──────────┴──────────┐
   │ achievement_catalog │   │   badge_specs       │   │   journey_adapter   │
   │ generuje level      │   │   delegáty na       │   │   _staticMilestone  │
   │ achievements z      │   │   config            │   │   z config          │
   │ tier listu          │   │                     │   │                     │
   └─────────────────────┘   └─────────────────────┘   └─────────────────────┘
                                       ▲
                                       │
                       ┌───────────────┴───────────────┐
                       │      progression_l10n         │
                       │   • levelTitle(int)           │
                       │   • achievementTitle/Desc     │
                       │     (level achievements →     │
                       │      progLevelTitle*/Desc)    │
                       └───────────────────────────────┘
                                       ▲
                       ┌───────────────┴───────────────┐
                       │  social_friends_tab           │
                       │  social_user_profile_sheet    │
                       │  ft_progression_home_card     │
                       │  journey_preview_card         │
                       │  devtools_*_section           │
                       │  → progL10n.levelTitle(level) │
                       └───────────────────────────────┘
```

### `ProgressionLevelTier`

Statická data jednoho level breakpointu:

| field | význam |
|---|---|
| `level` | Číslo levelu (1, 5, 10, …, 100) |
| `achievementId` | Stabilní opaque klíč pro persistenci (`level_5`, …, `level_100`). Tyto IDs jsou doc IDs ve Firestore `users/{uid}/achievementUnlocks/{id}` a součástí Isar `unlockKey: achievement\|{id}`. |
| `emoji` | Milestone emoji (zobrazené v journey mapě a na badge) |
| `difficulty` | `ProgressionAchievementDifficulty` (easy / medium / hard / extraHard) — určuje barvu badge a obtížnostní pruh |
| `isJourneyMapAnchor` | True pokud level je anchor node na statickém journey map páteři |
| `isTitleBreakpoint` | True pokud na tomto levelu se mění zobrazovaný titul |

### `ProgressionLevelMilestone` (runtime view-model)

Spojuje statický `ProgressionLevelTier` s runtime stavem (`isUnlocked`, `unlockedAt`, `isCurrent`, `isNext`). Buduje se až v adapteru, když máme přístup k `ProgressionProvider`.

### Tituly žijí v ARB, ne v configu

Důvod: tituly jsou lokalizované (CS + EN) a měnit se mohou bez nutnosti dotýkat se domain kódu. Config drží jen **klíč** (`achievementId`); překlad přes `ProgressionL10n.levelTitle(level)` → ARB klíč `progLevelTitle<N>`.

---

## Aktuální tituly (CS + EN)

| Level | CS | EN |
|------:|---|---|
| 1 | Poutník | Wanderer |
| 5 | Průzkumník stezek | Trail Explorer |
| 10 | Hraničář hvozdu | Ranger of the Wildwood |
| 15 | Strážce průsmyku | Guardian of the Pass |
| 20 | Dobyvatel ruin | Conqueror of Ruins |
| 25 | Klíčník starých bran | Keeper of the Old Gates |
| 30 | Sestupník hlubin | Delver of the Depths |
| 40 | Trpasličí spojenec | Dwarven Ally |
| 50 | Pán podzemních cest | Lord of the Underground Paths |
| 60 | Strážce mrazu | Guardian of Frost |
| 70 | Ledový chodec | Icewalker |
| 80 | Horský vyzyvatel | Mountain Challenger |
| 90 | Dračí jezdec | Dragon Rider |
| 100 | Pán dračí skály | Lord of Dragonrock |

> **Změnit titul = upravit dva ARB klíče (`progLevelTitle<N>` v `app_en.arb` a `app_cs.arb`)** a pustit `flutter gen-l10n`. Žádný jiný kód neměnit.

---

## Aktuální mapa emoji + obtížností

| Level | Emoji | Difficulty | Anchor |
|------:|:---:|---|---|
| 1   | 🧌      | easy      | ✓ |
| 5   | 🥾      | easy      | ✓ |
| 10  | 🧭      | easy      | ✓ |
| 15  | ⚒️      | medium    | ✓ |
| 20  | 🛡️      | medium    | ✓ |
| 25  | 🌩️      | hard      | ✓ |
| 30  | 🏰      | hard      | ✓ |
| 40  | 🐉      | hard      | ✓ |
| 50  | 🏹      | extraHard | ✓ |
| 60  | 🔱      | extraHard | ✓ |
| 70  | 🌌      | extraHard | ✓ |
| 80  | ♾️      | extraHard | ✓ |
| 90  | 👑      | extraHard | ✓ |
| 100 | 🐦‍🔥    | extraHard | ✓ |

Plus dekorativní emoji pro mezi-tier levely (žádný titul, žádný achievement, jen vizuál v journey mapě): 35: 🏔️, 45: ⚔️, 55: 🦅, 65: 🌠, 75: ☄️, 85: 🪽, 95: 🜲.

---

## Achievement IDs (persistence)

Level achievementy mají IDs ve formátu **`level_<N>`** — tj. **`level_1`, `level_5`, `level_10`, … `level_100`**.

Důležité:
- IDs jsou **opaque** — neenkódují titul, takže přejmenování titulu nikdy nevyžaduje migraci dat.
- Regex parser `levelFromAchievementId(String id)` je `^level_(\d+)$` — drží se striktně tohoto formátu.
- Achievementy jsou perzistované ve Firestore (`users/{uid}/achievementUnlocks/{id}`) a Isar (`ProgressionAchievementUnlockRecord` s `unlockKey: achievement|{id}`).
- **Level 1** je v configu, ale není v achievement katalogu — je to journey origin (start node), ne milestone, který by se "získával".

> **Předchozí refaktor přejmenoval IDs** ze stylu `<title>_level_<N>` (např. `pathfinder_level_5`, `trail_vanguard_level_10`, `dawn_sentinel_level_30`, `rift_walker_level_40`) na `level_<N>`. Lokální DB i Firestore data byly při refaktoru ručně vyčištěny — žádná migrace v kódu není.

---

## Jak provést běžné změny

### Změnit titul levelu
1. Uprav `progLevelTitle<N>` v `lib/l10n/app_en.arb` a `lib/l10n/app_cs.arb`.
2. Pusť `flutter gen-l10n`.
3. Done. Všechna místa zobrazí nový titul.

### Změnit emoji levelu
Uprav `emoji` pole v příslušné `ProgressionLevelTier` v `kProgressionLevelTiers`. Done.

### Přidat nový level breakpoint
1. Přidej novou entry do `kProgressionLevelTiers` (zachovej řazení podle `level`).
2. Přidej `progLevelTitle<N>` klíč do obou ARB souborů + regeneruj.
3. Přidej case do `ProgressionL10n.levelTitle(int)` switch.
4. Pokud má svůj Material icon v journey/achievement liście, přidej case do `FtProgressionDomainTheme._iconForLevelMilestone`.

### Změnit obtížnost levelu
Uprav `difficulty` v příslušné `ProgressionLevelTier`. Catalog se přegeneruje automaticky.

### Změnit zda level je map anchor
Přepni `isJourneyMapAnchor`. `JourneyAdapter._staticMilestoneLevels` se pochopí automaticky.

---

## Soubory dotčené refaktorem

| Soubor | Změna |
|---|---|
| `lib/features/progression/domain/progression_level_config.dart` | **NEW** — jediný zdroj pravdy |
| `lib/features/progression/domain/progression_level_policy.dart` | Smazáno `titleForLevel()`, vyčištěno `resolve()` |
| `lib/features/progression/domain/progression_models.dart` | Smazáno `ProgressionProfile.levelTitle` |
| `lib/features/progression/domain/progression_achievement_catalog.dart` | 13 ručně psaných level achievementů → for-loop nad `kProgressionLevelTiers` |
| `lib/features/progression/presentation/badges/progression_badge_specs.dart` | Wrappers nad config; sjednoceno regex parsing |
| `lib/features/progression/presentation/widgets/journey_adapter.dart` | `_staticMilestoneLevels` z config; `_levelPolicy.titleForLevel` → `progL10n.levelTitle` |
| `lib/features/progression/presentation/progression_l10n.dart` | + `levelTitle(int)` metoda; achievement title/desc pro level achievementy řešené přes `levelFromAchievementId` |
| `lib/features/progression/presentation/widgets/ft_progression_domain_theme.dart` | `iconForAchievement` pro level achievementy přes `_iconForLevelMilestone(int)` (klíčované levelem, ne titulem) |
| `lib/features/progression/presentation/widgets/ft_progression_home_card.dart` | `progL10n.levelTitle(profile.level)` |
| `lib/features/progression/presentation/widgets/journey_preview_card.dart` | totéž |
| `lib/features/progression/application/progression_provider.dart` | Fallback profile bez `levelTitle` |
| `lib/features/social/presentation/social_helpers.dart` | Smazáno `socialLevelTitle()` |
| `lib/features/social/presentation/widgets/social_user_profile_sheet.dart` | `ProgressionL10n(context.l10n).levelTitle(stats.level)` |
| `lib/features/social/presentation/tabs/social_friends_tab.dart` | totéž |
| `lib/features/devtools/presentation/sections/devtools_progression_section.dart` | totéž |
| `lib/features/devtools/presentation/sections/devtools_provider_section.dart` | totéž |
| `lib/l10n/app_en.arb`, `app_cs.arb` | + 14 `progLevelTitle*` klíčů + parametrizovaný `progLevelAchievementDesc` |
| `test/features/progression/progression_engine_test.dart` | Aktualizováno na nové IDs (`level_5`, …) |
| `test/features/progression/unclaimed_preview_refresh_test.dart` | Smazán už neexistující `levelTitle` parametr |

---

## Verifikace (po refaktoru, 2026-04-29)

- ✅ `flutter analyze` → 0 errors (109 pre-existing warnings v Isar `.g.dart` souborech jsou nesouvisející)
- ✅ `flutter test test/features/progression/` → all tests pass
- ✅ `flutter gen-l10n` → bez chyb, nové klíče vygenerovány v `app_localizations*.dart`

### Manuální testy doporučeno provést
- Hero Journey Map screen — ověř nové tituly v CS i EN (přepnout locale)
- Social user profile sheet — ověř že titul friend stejný jako journey map
- Achievement screen — odemčené level achievementy ukáží nové tituly + ikony
- Devtools "Progression / RPG" sekce — Level řádek ukazuje nové tituly
- Progression home card — `LEVEL N · TITLE` v hlavičce ukazuje nový titul
- Achievement notification (background sync) — nový titul v notifikaci

---

## Záměrná rozhodnutí, která stojí za zaznamenání

1. **IDs nesmí kódovat titul.** Tituly se mění, IDs jsou perzistovaná data → IDs jsou číselné (`level_5`).
2. **Tituly nepatří do domain layer.** `ProgressionLevelPolicy` se zabývá jen XP matematikou. `ProgressionProfile` drží jen `level: int`. Titul se resolvuje až v presentation přes `ProgressionL10n.levelTitle(level)`.
3. **Level 1 je origin, ne achievement.** Je v configu (kvůli journey mapě a titulu „Poutník"), ale není v achievement katalogu — hráč ho nezíská, začíná na něm.
4. **Decorative emoji** (35, 45, 55, …) jsou vizuální záležitost journey mapy; nemají vlastní tier (žádný titul, žádný achievement). Drží se v separátní mapě `kProgressionDecorativeLevelEmoji`.
5. **Žádná migrace dat.** V době refaktoru jediný uživatel (Tomáš) — DB i Firestore byly vyčištěny ručně. Při dalších změnách IDs (pokud někdy nastanou) bude třeba napsat migraci.
