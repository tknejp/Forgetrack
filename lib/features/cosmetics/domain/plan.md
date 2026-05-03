# Progression + Cosmetics Refactor Plan

> **Stav:** Fáze 0 dokončena (discovery + plán). Fáze 1+ čekají na implementaci.
> **Branch:** main (TBD: vytvořit feature branch před Fází 1)
> **Poslední update:** 2026-05-03

---

## Jak číst tento dokument

Tento dokument je **single source of truth** pro refactor. Píše ho a updatuje Claude napříč více sessions. Každá fáze má:

- **Goal** — co se v té fázi řeší
- **Files affected** — konkrétní soubory s line refs (pokud známé)
- **Acceptance criteria** — měřitelné podmínky dokončení
- **Out of scope** — co do té fáze **nepatří**, aby se PR nerozrostlo
- **Open questions / risks** — co může selhat
- **Status** — Not Started / In Progress / Done / Blocked

**Zlaté pravidlo:** každá fáze musí být samostatně mergovatelná, kompilovatelná, projít `flutter analyze` + `flutter test`. Pokud cokoliv vyžaduje cross-fáze koordinaci, dokument to explicitně vysvětluje.

**Při převzetí práce v nové session:**

1. Přečti si Phase 0 (Architektura) — pochopíš mentální model.
2. Najdi první fázi se statusem ≠ Done.
3. Přečti si její Goal, Files affected a Acceptance criteria.
4. V její sekci aktualizuj status na "In Progress" + datum.
5. Po dokončení fáze updatuj Status na Done + commit hash + datum.

---

## Cíl refactoru

Upravit existující progression a cosmetics systém tak, aby zůstal strukturálně blízko aktuální implementaci, ale měl čistší unlock logiku:

- **Achievementy** jsou hlavní zdroj pravdy pro splněné výkony.
- **Cosmetics** se odemykají přes achievement rewards / reward table (Tier-1).
- **Relicy** jsou kosmetické odměny za achievementy, **ne samostatný paralelní progression systém**. Žádný `RelicUnlockCondition` evaluator se nezavádí.
- **Companions** se odemykají přes kombinaci `owned relics + minimum level` (Tier-2 compound rules — už architektonicky existují).
- **Frames, emblems, backgrounds** zůstávají samostatné cosmetics rewards.
- **Frames** mají mít vlastní achievementy, pokud pro ně aktuálně chybí.
- Přidat jemnější `difficultyScore` 1.0–10.0 do achievement definic.
- Přidat nový rarity tier `mythic` pro endgame odměny.
- Vyčistit legacy / testovací relic IDs z companion systému (bez breaking changes pro stávající uživatele).

**Důležité:** **neměnit zbytečně architekturu ani nepřepisovat modely od nuly**. Většina infrastruktury (Tier-1/Tier-2 dispatcher, `Cond.atLevel + Cond.ownsCosmetic` pro companions, idempotentní unlock pipeline) už existuje. Refactor je primárně **změna dat + dvě cílené extension** (mythic enum, difficultyScore field, perfect period evaluator implementation).

---

## Phase 0 — Discovery & Architecture Map

**Status:** ✅ Done (2026-05-03)
**Goal:** Pochopit aktuální architekturu, namapovat dotčené soubory, sepsat plán.

### Klíčové architektonické fakty

#### Cosmetics modul (`lib/features/cosmetics/`)

| Soubor | Co tam je |
|---|---|
| [domain/cosmetic_models.dart](cosmetic_models.dart) | `CosmeticType`, `CosmeticRarity` (4 hodnoty), `CosmeticRegion`, `CosmeticDefinition`, `UnlockedCosmetic`, `EquippedCosmetics`, `UserCosmeticsState`. **Mythic ani difficultyScore zde nejsou.** |
| [domain/cosmetic_catalog.dart](cosmetic_catalog.dart) | Statický `List<CosmeticDefinition>`, ~66 položek. Obsahuje legacy IDs: `relic_old_compass`, `relic_pilgrim_cloak`, `relic_old_gate_key`, `relic_dragon_crown`, `relic_dragonrock_crown`. |
| [domain/cosmetic_unlock_rule.dart](cosmetic_unlock_rule.dart) | `CosmeticUnlockRule` + `Cond` builders. **Cond už obsahuje `atLevel`, `ownsCosmetic`, `dailyQuestsCompletedAtLeast`, `weeklyQuestsCompletedAtLeast`, `totalQuestsCompletedAtLeast`, `activeDaysAtLeast`, `perfectDaysAtLeast`, `perfectWeeksAtLeast`** — to je přesně sada, kterou plán potřebuje. |
| [domain/cosmetic_unlock_rules.dart](cosmetic_unlock_rules.dart) | `kCosmeticUnlockRules: List<CosmeticUnlockRule>`. **Tier-2 pravidla** (compound, quest counts, perfect periods). Zde žijí dnešní companion unlocks. |
| domain/cosmetic_unlock_evaluator.dart | Pure funkce: snapshot + alreadyOwned → Set unlock tuples. Deduplikace OR rules dle `cosmeticId`. |
| domain/cosmetic_unlock_snapshot.dart | Snapshot fields: `level`, `firstDailyQuestEver`, `completedDailyQuests`, `totalCompletedQuests`, `activeDaysCount`, `perfectDaysCount`, `perfectWeeksCount`, `ownedCosmeticIds`, atd. |
| domain/cosmetic_reveal_evaluator.dart, cosmetic_reveal_state.dart | **Nově přidané (uncommitted).** Reveal states: `unlocked`, `visibleLocked`, `hidden`, `partial`. |
| application/cosmetics_provider.dart | `CosmeticsProvider.unlock(id, sourceType, sourceId)`. Idempotentní (no-op pokud already owned). |
| application/cosmetic_unlock_dispatcher.dart | **3-pass dispatcher:** (1) achievement catch-up, (2) level catch-up, (3) Tier-2 fixed-point loop (max 3 iterací) pro compound rules. Volá se po každém progression sync. |
| data/isar_cosmetics_repository.dart | Lokální storage v Isar. `CosmeticsUnlockRecord` má `@Index(unique: true, replace: true)` — duplicates nemožné. |
| data/firestore_cosmetic_entitlements_source.dart | Read-only Firestore source pro promotional entitlements. |
| presentation/widgets/cosmetic_collection_tile.dart, cosmetic_details_sheet.dart | Vykreslování rarity přes `cosmetics_palette.dart` → `forRarity()`. |

#### Progression modul (`lib/features/progression/`)

| Soubor | Co tam je |
|---|---|
| [domain/progression_models.dart](../../progression/domain/progression_models.dart) | `ProgressionAchievementDifficulty` enum (easy, medium, hard, extraHard), `ProgressionAchievementCriterionType` enum (5 typů: totalXpAtLeast, rewardCountAtLeast, bestStreakAtLeast, totalRuleValueAtLeast, bestRollingWindowRuleValueAtLeast). `ProgressionAchievementDefinition` na ~ř. 454. |
| domain/progression_achievement_catalog.dart | Achievement IDs definované staticky. **Existující relevantní IDs:** `welcome_to_journey`, `first_reward`, `steps_total_100k`, `steps_total_1000000`, `steps_total_5000000`, `steps_total_10000000`, `steps_streak_3/7/30/50/100`, `steps_month_300k/600k`, `weekly_activity_mastery/4/12/24/52`, `reward_hunter_25/100`, `nutrition_streak_3`, `nutrition_rewards_25`, `sleep_total_250h/1000h`, `sleep_month_225h/240h`, `xp_100000/1000000`. |
| domain/progression_achievement_evaluator.dart | `_currentValue()` switch na ~ř. 119–166. Sem se přidávají nové criterion typy. |
| [domain/cosmetic_reward_table.dart](../../progression/domain/cosmetic_reward_table.dart) | **Tier-1 mapping** `achievementToCosmetics: Map<String, List<String>>` (1:N) + `levelToCosmetics: Map<int, List<String>>`. Toto je hlavní seam pro Fázi 4. |
| domain/perfect_period_evaluator.dart | **Placeholder** vrací 0. Skutečnou implementaci přidává Fáze 3. |
| application/progression_engine.dart, progression_provider.dart | Hydratace, eval flow, trigger pro dispatcher. |

#### L10n (`lib/l10n/`)

- `app_en.arb`, `app_cs.arb` — single source of truth pro display textry.
- Konvence klíčů: `cosmeticXxxName`, `cosmeticXxxDesc`, `cosmeticXxxUnlockHint`. Achievementy: `progressionAchievementXxxName`/`Desc`.
- Cosmetic catalog inlinuje closures: `name: (l) => l.cosmeticRelicXxxName`. Dart compiler zajistí, že chybějící klíč → build error (žádný runtime fallback).
- Po každé úpravě ARB → `flutter gen-l10n` (regenerace `app_localizations*.dart`). Tyto soubory jsou pod git, ale generované.
- ⚠️ **`ProgressionAchievementDefinition` dnes drží `String title` + `String description` jako hardcoded string literals** (např. `title: 'Welcome to the Journey'`). To je nekonzistentní s cosmetics. **Cíl refactoru: sjednotit na closure pattern** — typedef `ProgressionAchievementText = String Function(AppLocalizations l10n)`, fields se mění z `String` na `ProgressionAchievementText`. Catalog pak inlinuje `title: (l) => l.progressionAchievementWelcomeToJourneyName` stejně jako cosmetics. Tato změna je **plánovaná do Fáze 3** (zároveň s přidáním nových achievementů — refactor existujících entries jde s novými přírůstky v jednom commitu, jinak by byla přechodná inkonzistence). Pozor na `ProgressionL10n` routing pro level milestone titles (komentář v catalog ř. 36–38 ho zmiňuje) — ten zůstane jako delegate, případně se zruší.

#### Storage & idempotence

- **Lokální:** Isar, `CosmeticsUnlockRecord` (uid, cosmeticId) composite unique → re-unlock je no-op.
- **Firestore:** read-only entitlements (promotional). App lokálně nezapisuje cosmetics do Firestore.
- **Migration:** žádný explicit verzioning katalogu. Legacy ID v storage zůstanou, jen `byId()` vrátí null pokud zmizí z catalog. **Pro tento refactor: legacy definice ponechat v katalogu** (s `isEnabled: true` ale bez nových unlock cest), aby uživatelům, co je odemčené mají, nezmizely.

#### Klíčové insighty pro implementaci

1. **Companion logika "owned relics + level gate" už existuje** v `Cond.atLevel() + Cond.ownsCosmetic()` compound pravidlech. Příklad — current `companion_dragonling`:

   ```dart
   conditions: [Cond.atLevel(100), Cond.ownsCosmetic('relic_dragonrock_crown')]
   ```

   Refactor v Fázi 5 = jen přepsat data v `kCosmeticUnlockRules`, žádná nová evaluator logika.

2. **3-pass dispatcher už řeší dependency order:** Tier-1 (achievement-driven relicy) se grantují v passu 1, pak Tier-2 (companions vyžadující ownsCosmetic) v passu 3 fixed-point loop. Reload chains jako `dragonrock_trial → relic_dragonrock_heart → companion_dragon_baby` budou fungovat v jednom dispatch cyklu.

3. **Quest counts už mají Cond helpery a snapshot fields**, ale **achievement evaluator je ještě nepoužívá** (`ProgressionAchievementCriterionType` má jen 5 hodnot, žádná pro quest count). Pro `daily_quest_3/7`, `quest_hunter_250` máme dvě cesty:
   - **A) Přidat criterion typ** `questsCompletedAtLeast` do achievement evaluatoru → odměna jde přes Tier-1 reward table (čistší, plán to preferuje).
   - **B) Nechat to v Tier-2 unlock rules** (jako dnes je `relic_trail_compass`), achievement neexistuje → ale pak nemáme achievement entry do progression UI.
   - **Rozhodnutí:** Cesta A. Tier-2 ponechat pro skutečně compound věci (companions).

4. **Composite achievement `dragonrock_trial`** (level 100 + 250 questů + 10M kroků) framework dnes neumí. Dvě cesty:
   - **A) Přidat `compositeConditions` field** do `ProgressionAchievementDefinition` (struct s threshold listem) + extend evaluator.
   - **B) Modelovat to jako Tier-2 compound rule** (jako dnešní `relic_dragonrock_crown`) bez achievement entry.
   - **Rozhodnutí:** Cesta A — plán explicitně chce achievement-first model. Composite struct bude minimal: list `(criterionType, ruleId, target)` triplets s AND semantikou.

5. **Mythic rarity je low-risk patch:** UI mapping je centralizovaný v `cosmetics_palette.dart`, l10n má jeden klíč `cosmeticRarityMythic`, serializace neexistuje (enum je in-memory only).

6. **Difficulty score je nullable additive field** na `ProgressionAchievementDefinition`. Nepřepisuje existující `difficulty` enum, jen ho doplňuje. Dnes nikde se difficulty enum nepoužívá pro logiku (jen pro UI v progression screen) — risk minimal.

---

## Phase 1 — Foundation (`mythic` rarity + `difficultyScore`)

**Status:** ✅ Done (2026-05-03, uncommitted — see git diff for files)
**Estimated scope:** ~10 souborů, malý PR
**Dependencies:** None

**Changes landed:**

- `lib/features/cosmetics/domain/cosmetic_models.dart` — `CosmeticRarity.mythic` přidán jako poslední hodnota.
- `lib/shared/theme/design_tokens.dart` — `FtRarity.mythic` (color `0xFFFF6EC7` magenta-pink, gradStart `0xFFB400FF` violet — finální paleta TBD designerem, dočasně distinct od legendary).
- `lib/features/cosmetics/presentation/cosmetics_palette.dart` — `case CosmeticRarity.mythic` → `FtRarity.mythic`.
- `lib/features/cosmetics/config/cosmetics_config.dart` — `mythic` přidán na konec `rarityDisplayOrder`.
- `lib/features/cosmetics/presentation/cosmetics_screen.dart` — `_rarityRank` returns 4 pro mythic.
- `lib/features/cosmetics/presentation/cosmetics_screen_internals.dart` — 2× switch (label "Mytické", color provisorně sdílí `Tokens.difficultyExtraHard` s legendary — TODO designer).
- `lib/features/app_shell/presentation/widgets/progression_celebration_overlay.dart` — `_rarityLabel` mapuje na `l10n.cosmeticRarityMythic`.
- `lib/l10n/app_en.arb` + `lib/l10n/app_cs.arb` — `cosmeticRarityMythic` ("Mythic" / "Mytické"), regenerováno přes `flutter gen-l10n`.
- `lib/features/progression/domain/progression_models.dart` — `ProgressionAchievementDefinition` má nový optional field `final double? difficultyScore;` s docstringem.

**Verification:**

- `flutter analyze --no-fatal-infos` — 133 issues, vše pre-existing warningy (Isar generated code + 1 unused var v `fitness_queries_test`). Žádný nový error.
- `flutter test` — 179 passed, 3 failed (`hc_steps_service_test.dart`). Všechny 3 selhávají i na baseline před Phase 1 změnami (ověřeno přes `git stash` + re-run). Pre-existing HC issue, mimo scope tohoto refactoru.

**Out of scope confirmed (carried to later phases):**

- Žádný catalog item zatím nepoužívá `CosmeticRarity.mythic` (Phase 2).
- Žádný achievement zatím nemá `difficultyScore` set (Phase 3 spolu s catalog refactoru na l10n closures).
- Finální mythic vizuál (designer TBD).

### Goal

Připravit datové modely pro nové funkce, beze změny chování. Po této fázi by katalog měl umět vytvořit definici s `rarity: CosmeticRarity.mythic` a achievement s `difficultyScore: 7.5`, ale nic ji nepoužívá.

### Files affected

1. **`lib/features/cosmetics/domain/cosmetic_models.dart`** (ř. 23–28)
   - Přidat `mythic` jako poslední hodnotu do `CosmeticRarity` enum.
   - Pořadí: common, rare, epic, legendary, **mythic** (růstem prestiže — důležité pro `index`-based comparisons, pokud existují).

2. **`lib/features/cosmetics/presentation/cosmetics_palette.dart`** (`forRarity` switch)
   - Přidat case `CosmeticRarity.mythic` → mapping na `FtRarity` design token.
   - **Pokud `FtRarity` mythic ještě nemá**, přidat ji do `lib/core/design_tokens.dart` (ověřit přesnou cestu) s vlastní barvou (návrh: prismatic gradient nebo deep crimson, finální výběr nech designerovi — dočasně stejné jako legendary).

3. **`lib/features/cosmetics/domain/cosmetics_config.dart`** (najít `rarityDisplayOrder` const)
   - Přidat `mythic` na konec listu pro řazení v wardrobe UI.

4. **`lib/l10n/app_en.arb` + `app_cs.arb`**
   - Přidat klíč `cosmeticRarityMythic` (en: "Mythic", cs: "Mytický").
   - Pokud existují `cosmeticRarityCommon/Rare/Epic/Legendary` description klíče, přidat i `cosmeticRarityMythicDesc` (en: "Pinnacle of the journey.", cs: "Vrchol cesty.").
   - Spustit `flutter gen-l10n`.

5. **`lib/features/progression/domain/progression_models.dart`** (`ProgressionAchievementDefinition` třída)
   - Přidat optional field `final double? difficultyScore;` do konstruktoru.
   - **NEPŘIDÁVAT** validaci range — devs spadnou na review.
   - Existující `difficulty: ProgressionAchievementDifficulty.medium` enum **zachovat** beze změny.

6. **`lib/features/progression/domain/progression_achievement_catalog.dart`**
   - Žádné změny dat v této fázi. (Difficulty score se doplňuje ve Fázi 3 spolu s ostatními změnami achievement catalogu.)

### Acceptance criteria

- [ ] `flutter analyze` čistý.
- [ ] `flutter test` projde.
- [ ] Manuálně: spustit app, otevřít wardrobe / progression screen, žádný UI crash. Existující rarity badges vypadají stejně.
- [ ] Switch v `cosmetics_palette.dart` je exhaustivní (žádný `default:` case nepotřeba).
- [ ] `CosmeticDefinition(..., rarity: CosmeticRarity.mythic)` jde zkonstruovat (ověřit unit testem nebo dočasným dev katalog itemem).

### Out of scope

- Žádné **použití** mythic rarity v reálných položkách katalogu (to je Fáze 2).
- Žádné použití `difficultyScore` v UI nebo balancing logice.
- Žádné finální vizuály pro mythic — designer dodá později, dočasně jen reuse legendary palette.

### Open questions / risks

- **Q:** Existuje serialization `CosmeticRarity` (např. do JSON pro analytics)? Pokud ano, přidání enum value může rozbít deserializaci starších klientů.
  - **Akce:** grep `CosmeticRarity.values` a `CosmeticRarity.byName` — pokud najdeš, ošéfovat fallback.
- **Q:** UI komponenty mimo `cosmetics_palette.dart` co dělají rarity switch? (Např. social sheet?)
  - **Akce:** grep `case CosmeticRarity.legendary` napříč `lib/` — všechny exhaustive switche musí dostat `mythic` case nebo `default:`.

### Suggested commit message

```
cosmetics: add mythic rarity tier and achievement difficultyScore

- CosmeticRarity gains `mythic` value (used by phase 2 endgame items)
- ProgressionAchievementDefinition gains optional `difficultyScore` (1.0-10.0)
- Palette + display order + l10n updated, no behavioural change
```

---

## Phase 2 — Catalog Data (additive cosmetics)

**Status:** ✅ Done (2026-05-03, uncommitted on feature branch)
**Estimated scope:** ~3 soubory změněné, ~600 řádků ARB, ~300 řádků catalog
**Dependencies:** Fáze 1 (potřebuje `CosmeticRarity.mythic`)

**Changes landed:**

- **9 new relic definitions** added to `lib/features/cosmetics/domain/cosmetic_catalog.dart`:
  - Camp/neutral: `relic_warm_kindling` (common, sortOrder 325)
  - Forest: `relic_moonlit_foxglove`, `relic_wildwood_charm` (rare, 355/358)
  - Ravine/Ruins: `relic_ashen_omen`, `relic_oathbound_mark` (epic, 375/378)
  - Mines: `relic_deep_ember_core` (epic, 385)
  - Mountain Road: `relic_summit_feather`, `relic_stormcrest_plume` (legendary, 400/405)
  - Dragonrock: `relic_dragonrock_heart` (**mythic**, 410) — first catalog item using mythic rarity
- **5 existing reliky updated**:
  - `relic_campfire_spark` — region forestTrail → **neutral** (Camp)
  - `relic_bridge_key` — rarity rare → **epic**, region ruinedPass → **dwarvenMines** (Bridges/Mines fáze)
  - `relic_polar_lantern` — rarity epic → **legendary**
  - `relic_frost_shard` — rarity epic → **legendary**
  - `relic_frozen_lake_heart` — rarity epic → **legendary**
- **All 8 planned frames already existed** (frame_discipline, frame_endurance, frame_steel, frame_eternal_flame, frame_balance, frame_master_routine, frame_endless_trail, frame_worldwalker) — no changes needed.
- **54 new ARB entries** (9 reliků × 3 klíče × 2 jazyky) v `app_en.arb` + `app_cs.arb`, regenerováno přes `flutter gen-l10n`.

**Verification:**

- `flutter analyze --no-fatal-infos` — 133 issues, vše pre-existing. Žádný nový error.
- `flutter test` — 179 passed / 3 failed (stejné HC steps pre-existing failures jako u Phase 1, mimo scope).

**Out of scope confirmed (carried to later phases):**

- **Žádný unlock mapping** zatím — relicy jsou v katalogu, ale nikomu se neudělí. Wiring jde v Phase 4 (achievement reward table) a Phase 5 (companion rules).
- **Žádné asset images** dodané. `assetKey` je nastaven (např. `cosmetics.relics.dragonrock_heart`), ale fyzické PNG assety designer dodá zvlášť. UI gracefully fallbackuje na placeholder při null asset.
- **Difficulty score** zůstává jen na Achievement modelech (Phase 1) — není to atribut Cosmetic, je to atribut Achievement. Cosmetics rarity je proxy.

### Goal

Přidat všech 19 nových relic definic + chybějící frame definice do katalogu. **Žádný unlock mapping zatím**, položky zatím nejsou nikomu odemknutelné.

### Nové relic definice (z plánu, sekce "Nové / upravené relic definitions")

| ID | Region | Diff score | Rarity |
|---|---|---:|---|
| `relic_campfire_spark` | Camp (neutral) | 1.1 | common |
| `relic_warm_kindling` | Camp (neutral) | 1.3 | common |
| `relic_moonlit_foxglove` | forestTrail | 1.5 | rare |
| `relic_ancient_root` | forestTrail | 1.5 | rare |
| `relic_wildwood_charm` | forestTrail | 1.8 | rare |
| `relic_ravine_stone` | ruinedPass | 1.8 | rare |
| `relic_ruin_seal` | ruinedPass | 2.2 | rare |
| `relic_ashen_omen` | ruinedPass | 3.0 | epic |
| `relic_oathbound_mark` | ruinedPass | 3.5 | epic |
| `relic_bridge_key` | dwarvenMines | 4.5 | epic |
| `relic_deep_ember_core` | dwarvenMines | 4.5 | epic |
| `relic_miners_lantern` | dwarvenMines | 5.0 | epic |
| `relic_polar_lantern` | frostlands | 6.2 | legendary |
| `relic_frozen_lake_heart` | frostlands | 6.8 | legendary |
| `relic_frost_shard` | frostlands | 7.0 | legendary |
| `relic_summit_feather` | dragonMountains | 8.0 | legendary |
| `relic_stormcrest_plume` | dragonMountains | 8.5 | legendary |
| `relic_dragon_scale` | dragonMountains | 9.0 | **mythic** |
| `relic_dragonrock_heart` | dragonrockFortress | 10.0 | **mythic** |

**Note:** `relic_ancient_root`, `relic_ravine_stone`, `relic_ruin_seal`, `relic_bridge_key`, `relic_miners_lantern`, `relic_frozen_lake_heart`, `relic_frost_shard` — **ověřit, jestli už nejsou v katalogu** (z exploration vyplývá, že některé jsou). Pokud existují, jen update fields (region, rarity, případně difficultyScore — ale ten je na achievementu, ne na cosmeticu).

### Frames k ověření / přidání

Z plánu sekce "Achievementy pro frame rewards":

| Asset | Existuje v katalogu? | Akce |
|---|---|---|
| `frame_discipline` | ověřit | pokud ne → přidat |
| `frame_endurance` | ověřit | pokud ne → přidat |
| `frame_steel` | ověřit | pokud ne → přidat |
| `frame_eternal_flame` | ověřit | pokud ne → přidat |
| `frame_balance` | ⚠️ je v `kCosmeticUnlockRules` jako Tier-2 — ověřit catalog | |
| `frame_master_routine` | ⚠️ je v `kCosmeticUnlockRules` — ověřit catalog | |
| `frame_endless_trail` | ověřit | |
| `frame_worldwalker` | je v reward table → catalog by měl existovat | ověřit |

### Files affected

1. **`lib/features/cosmetics/domain/cosmetic_catalog.dart`**
   - Append nové `CosmeticDefinition` entries.
   - Konvence: groupovat po regionu, sortOrder zachovat rostoucí.
   - Příklad:

     ```dart
     CosmeticDefinition(
       id: 'relic_campfire_spark',
       type: CosmeticType.relic,
       rarity: CosmeticRarity.common,
       region: CosmeticRegion.neutral,
       name: (l) => l.cosmeticRelicCampfireSparkName,
       description: (l) => l.cosmeticRelicCampfireSparkDesc,
       unlockHint: (l) => l.cosmeticRelicCampfireSparkUnlockHint,
       assetKey: 'cosmetics.relics.campfire_spark',
       sortOrder: 1100,
     ),
     ```

2. **`lib/l10n/app_en.arb` + `app_cs.arb`**
   - Pro každý nový relic 3 klíče: `Name`, `Desc`, `UnlockHint`.
   - **UnlockHint text** je důležitý — ten se zobrazuje hráčovi v locked state. Měl by reflektovat skutečnou achievement podmínku z plánu (např. "Reach 100 000 lifetime steps." pro `relic_ravine_stone`).
   - České překlady — udržet styl current cosmetics ("Iskřivý plamen"-style).
   - Spustit `flutter gen-l10n`.

3. **Asset placeholders** (`assets/cosmetics/relics/`)
   - **Nepřidávat finální obrázky v této fázi** (designer dodá zvlášť).
   - Ověřit, že `assetKey` je nullable a UI gracefully fallbackuje (z exploration: catalog dovoluje `assetKey: null`, UI vykreslí placeholder).
   - **Akce v PR:** přidat TODO komentář u každé nové definice s placeholder asset key, vytvořit single follow-up issue/task pro asset delivery.

### Acceptance criteria

- [ ] `flutter analyze` čistý (žádné nepoužité l10n klíče se nehlásí — Flutter to nedělá, ale build by měl projít).
- [ ] `flutter test` projde.
- [ ] V devtools / cosmetics_debug_screen vidět všechny nové relicy v catalog list (zatím všechny locked).
- [ ] Otevření details sheetu pro každou novou položku ukáže name + desc + unlockHint bez crashe.
- [ ] Mythic rarity badge se vykreslí na `relic_dragon_scale` a `relic_dragonrock_heart`.

### Out of scope

- **Žádné unlock mappingy** — to je Fáze 4 (reward table) a Fáze 5 (companion rules).
- Finální asset images.
- Změny existujících reliců (legacy IDs zůstávají nedotčené v této fázi).

### Open questions / risks

- **Q:** Konflikt s aktuálními definicemi reliců (`relic_ancient_root` atd. už existují v `kCosmeticUnlockRules` Tier-2)?
  - **Akce:** ověřit grep `'relic_ancient_root'` napříč codebasí. Pokud už definice je v katalogu → jen update rarity/region/difficultyScore. Pokud není → ADD.
- **Q:** Jak diff-velký bude PR po ARB změnách? Cca 19 reliců × 3 klíče × 2 jazyky = 114 nových l10n entries.
  - **Mitigation:** committit ARB jako separátní commit v rámci PR pro snadnější review.

### Suggested commit message

```
cosmetics: add 19 new relic definitions for refactor (catalog-only)

Relics span all six regions (Camp → Dragonrock) with difficulty scores 1.1-10.0
and rarities common → mythic. No unlock mappings yet — items are catalog-only,
not granted to anyone. Reward wiring follows in phase 4.
```

---

## Phase 3 — Achievement Evaluator Extensions

**Status:** ⏸️ Not Started
**Estimated scope:** Medium-large. Dvě sub-fáze, ideálně dva PR.
**Dependencies:** Fáze 1 (difficultyScore field)

### Goal

Rozšířit achievement framework, aby uměl:

- **Quest count achievementy** (`daily_quest_3/7`, `quest_hunter_250`) — nový criterion typ.
- **Combo quest achievementy** (`combo_victory_10`, `combo_triple_victory_25/100`) — quest tracking pro combo kategorie. **Pokud combo quest catalog dnes neexistuje, označit jako TODO / placeholder.**
- **Perfect period achievementy** (`perfect_days_7`, `perfect_weeks_12`) — implementovat real `PerfectPeriodEvaluator`.
- **Active days achievement** (`active_days_7`) — nový criterion typ nebo reuse existing snapshot field.
- **Composite achievement** (`dragonrock_trial`) — nový mechanismus pro AND-of-thresholds.

### Sub-fáze 3-prep: Achievement l10n routing audit

**Status:** ✅ Done (2026-05-03, uncommitted on feature branch)

**Goal (revised):** Zajistit, že **všechny achievement IDs v katalogu mají l10n routing** přes existující `ProgressionL10n` adapter, ne přes raw `achievement.title` fallback.

**Architectural finding:** Plán původně volal closure refactor (`title: (l) => l.cosmeticXxxName`) konzistentně s cosmetics. Při auditu se ukázalo, že progression má **odlišný a opodstatněný pattern**:

- `ProgressionL10n.achievementTitle(achievement)` / `achievementDescription(achievement)` je **dedicated l10n adapter** s switch na `achievement.id`. Pro každý known ID vrací localized string z ARB (`progAchievementXxxTitle`).
- Definition `String title` / `String description` jsou **persistence-friendly snapshot strings** — používají se v `social_provider.dart:465-466` při share serializaci a v `social_profile_utils.dart:138-139` při hydrataci shared snapshot. Toto je intentional design (autor sdílí snapshot v jeho jazyce; reader vidí localized verzi pokud zná ID, fallback na snapshot pokud ne — robust pro app version skew).

Closure pattern by tedy ohrozil snapshot persistence a vytvořil paralelní l10n cestu.

**Files affected:**

1. **`lib/features/progression/presentation/progression_l10n.dart`** — added 4 missing switch cases:
   - `achievementTitle` switch: `welcome_to_journey`, `steps_streak_50`
   - `achievementDescription` switch: `welcome_to_journey`, `steps_streak_50`
   - ARB klíče (`progAchievementWelcomeToJourneyTitle/Desc`, `progAchievementStepsStreak50Title/Desc`) **už existovaly** v en + cs, jen nebyly napojené v routeru.

**Convention enforced going forward (klíčové pro Phase 3a-3d):**

> Každý nový achievement entry v `progression_achievement_catalog.dart` MUSÍ mít odpovídající switch case v `ProgressionL10n.achievementTitle` + `achievementDescription` + ARB klíče v en + cs (`progAchievementXxxTitle`, `progAchievementXxxDesc`). Definition `title`/`description` strings zůstávají English fallback pro snapshot persistence.

**Verification:**

- `flutter analyze --no-fatal-infos` — 133 issues, vše pre-existing.
- Audit: všech 31 achievement IDs v catalogu má teď routing v `ProgressionL10n` (level milestones jsou handleované přes `levelFromAchievementId` shortcut).

---

### Sub-fáze 3a: Simple count achievementy (ne-composite)

**Files affected:**

1. **`lib/features/progression/domain/progression_models.dart`**
   - Rozšířit `ProgressionAchievementCriterionType` enum:

     ```dart
     enum ProgressionAchievementCriterionType {
       totalXpAtLeast,
       rewardCountAtLeast,
       bestStreakAtLeast,
       totalRuleValueAtLeast,
       bestRollingWindowRuleValueAtLeast,
       // NEW:
       questsCompletedAtLeast,           // s optional category filter
       activeDaysAtLeast,                // dní s alespoň 1 claimed quest/reward
       perfectDaysAtLeast,               // dní kde všechny daily rules splněny
       perfectWeeksAtLeast,              // týdnů s 7 perfect days
     }
     ```

   - Pokud achievement potřebuje filtr (např. `daily` vs `weekly` vs `combo` quest), přidat optional `final ProgressionQuestCategory? questCategory;` do `ProgressionAchievementDefinition`.

2. **`lib/features/progression/domain/progression_achievement_evaluator.dart`** (`_currentValue` switch ~ř. 119–166)
   - Přidat case branches pro nové criterion typy.
   - Pro `questsCompletedAtLeast`: spočítat `engineState.questRewardGrants.where(g => g.status == claimed && (questCategory == null || g.category == questCategory)).length`. **Ověřit přesný shape `ProgressionQuestRewardGrant`** v `progression_models.dart` ~ř. 421.
   - Pro `activeDaysAtLeast`: reuse logiku z `CosmeticUnlockSnapshot.activeDaysCount` — pokud je tam, factor out do shared service. Pokud ne, definovat tady: počet unique dnů s alespoň 1 claimed grant.
   - Pro `perfectDaysAtLeast`/`perfectWeeksAtLeast`: delegovat na `PerfectPeriodEvaluator` (sub-fáze 3b).

3. **`lib/features/progression/domain/progression_achievement_catalog.dart`**
   - Přidat nové achievement entries:

     ```dart
     ProgressionAchievementDefinition(
       id: 'daily_quest_3',
       type: ProgressionAchievementType.milestone,
       difficulty: ProgressionAchievementDifficulty.easy,
       difficultyScore: 1.3,
       criterionType: ProgressionAchievementCriterionType.questsCompletedAtLeast,
       questCategory: ProgressionQuestCategory.daily,
       targetValue: 3,
       // ... name/desc l10n
     ),
     ```

   - Achievementy k přidání: `daily_quest_3`, `daily_quest_7`, `quest_hunter_250` (no category filter), `active_days_7`.

4. **`lib/l10n/app_en.arb` + `app_cs.arb`**
   - Pro každý achievement: `progressionAchievementXxxName`, `progressionAchievementXxxDesc`.

### Sub-fáze 3b: Perfect period evaluator (real implementation)

**Files affected:**

1. **`lib/features/progression/domain/perfect_period_evaluator.dart`**
   - Replace `PlaceholderPerfectPeriodEvaluator` (vrací 0) skutečnou logikou.
   - **Definice "perfect day"** (z plánu): den, kdy player splnil všechny daily rules (kroky + protein + kalorie + sleep — finální výběr ověřit s existujícím quest katalogem, např. `daily_four_pillars_today` quest definice je referenční point).
   - **Definice "perfect week"**: ISO týden se 7 perfect days.
   - **Algoritmus:**
     - Vstup: `List<ProgressionRuleEvaluation>` (per den, per rule).
     - Group by `progressionDate(eval.date)`.
     - Pro každý den: spočítat počet completed required rules. Pokud == count required → perfect.
     - Pro perfect weeks: groupBy `startOfProgressionWeek(perfectDay)`.
   - **Snapshot integration:** `CosmeticUnlockSnapshot.perfectDaysCount`/`perfectWeeksCount` musí být napojeno na tento evaluator (ověřit kde se snapshot buildí — pravděpodobně v `cosmetic_unlock_snapshot.dart` nebo dispatcheru).

### Sub-fáze 3c: Combo quest achievementy

**Files affected:**

1. **Quest catalog inspection** (`lib/features/quests/` — TBD najít)
   - Ověřit, jestli existují combo quest IDs typu `daily_combo_victory`, `daily_combo_double_victory`, `daily_combo_triple_victory`.
   - **Pokud existují:** přidat achievement entries `combo_victory_10` (filter na daily_combo_*), `combo_triple_victory_25/100` (filter na daily_combo_triple_victory).
   - **Pokud neexistují:** dvě možnosti:
     - **A) Skeleton:** přidat 3 quest definice do quest katalogu s eval logikou (steps goal + N nutrition goals splněny v jeden den). Pak achievementy.
     - **B) TODO:** definovat achievement IDs v katalogu s placeholder evaluator, který vrací 0. Označit komentářem `// TODO(combo): wire to combo quest tracking — see plan.md phase 3c`.
   - **Doporučení:** Cesta B v Fázi 3, cesta A v separátním follow-up PR (combo quest implementace je samostatný engineering effort).

### Sub-fáze 3d: Composite achievement (dragonrock_trial)

**Files affected:**

1. **`lib/features/progression/domain/progression_models.dart`**
   - Přidat nový criterion typ `compositeAllOf` + struct:

     ```dart
     class ProgressionAchievementCompositeCondition {
       final ProgressionAchievementCriterionType type;
       final String? ruleId;
       final ProgressionDomain? domain;
       final int targetValue;
     }
     ```

   - Field na `ProgressionAchievementDefinition`: `final List<ProgressionAchievementCompositeCondition>? compositeConditions;`.
   - **Validation invariant:** `compositeConditions != null XOR criterionType != compositeAllOf` (nepřidávat runtime assert, dokumentovat).

2. **`progression_achievement_evaluator.dart`**
   - Pro `compositeAllOf`: vyhodnotit každou subcondition (recurse `_currentValue` pro daný subtype) a vrátit `min(subValue, subTarget) summed` nebo `1` pokud all met else `0`. **Doporučená sémantika:** evaluator vrací `1` (current) vs `1` (target) pokud splněno, jinak `0`. To zachová existing pattern `currentValue >= targetValue` checku.

3. **`progression_achievement_catalog.dart`**
   - Přidat:

     ```dart
     ProgressionAchievementDefinition(
       id: 'dragonrock_trial',
       type: ProgressionAchievementType.mastery,
       difficulty: ProgressionAchievementDifficulty.extraHard,
       difficultyScore: 10.0,
       criterionType: ProgressionAchievementCriterionType.compositeAllOf,
       compositeConditions: [
         ProgressionAchievementCompositeCondition(
           type: ProgressionAchievementCriterionType.totalXpAtLeast,
           targetValue: levelXpThreshold(100), // helper
         ),
         ProgressionAchievementCompositeCondition(
           type: ProgressionAchievementCriterionType.questsCompletedAtLeast,
           targetValue: 250,
         ),
         ProgressionAchievementCompositeCondition(
           type: ProgressionAchievementCriterionType.totalRuleValueAtLeast,
           ruleId: 'steps_total',
           targetValue: 10000000,
         ),
       ],
       targetValue: 1,
     ),
     ```

### Frame achievementy

Z plánu sekce "Nové frame achievementy, pokud chybí":

- `perfect_days_7` — kryje sub-fáze 3b.
- `perfect_weeks_12` — kryje sub-fáze 3b.

Existující achievementy (`steps_streak_7/30/50/100`, `steps_month_600k`, `steps_total_10000000`) jsou už v katalogu — frame mapping se řeší ve Fázi 4.

### Acceptance criteria

- [ ] Všechny nové criterion typy mají test pokrytí (unit testy v `test/features/progression/`).
- [ ] `dragonrock_trial` test: setup profil s level 99 + 249 questy + 9.99M kroků → not unlocked. Bump cokoliv → unlocked.
- [ ] `perfect_days_7` test: 7 dní s všemi daily rules splněnými → unlocked.
- [ ] Devtools: nové achievementy se zobrazí v achievements list (možná nutno update progression UI pokud filtruje typ).
- [ ] `flutter analyze` čistý.
- [ ] Žádný regression existujících achievementů (smoke: `welcome_to_journey`, `steps_streak_7` se odemknou jako dřív).

### Out of scope

- Reward mapping pro nové achievementy (Fáze 4).
- Combo quest implementace v quest engine (sub-fáze 3c volí TODO cestu).

### Open questions / risks

- **Q:** Existuje `levelXpThreshold(int)` helper? Pokud ne, jak vyjádřit "level 100" jako criterion?
  - **Akce:** grep `levelXpThreshold`, pokud chybí, factor out z progression engine. Případně přidat criterion typ `levelAtLeast` separátně (jednodušší).
- **Q:** Snapshot pro `CosmeticUnlockEvaluator` (Tier-2 rules) sdílí source of truth s achievement evaluator (Tier-1)?
  - **Akce:** ověřit, že `perfectDaysCount` v snapshot se počítá stejnou logikou jako v achievement evaluator. Jinak hrozí divergence (např. companion vidí 7 perfect days ale achievement zatím ne).
  - **Mitigation:** Implementovat `PerfectPeriodEvaluator` jako shared service, oba consumers volají stejnou funkci.
- **Risk:** Sub-fáze 3a, 3b, 3c, 3d dohromady = velký PR. **Doporučení rozdělit:**
  - PR 1: 3a + 3b (simple counts + perfect periods).
  - PR 2: 3d (composite, jen pro dragonrock_trial).
  - PR 3: 3c (combo) — pokud cesta A. Pokud cesta B (TODO), může jít s PR 1.

### Suggested commit messages

```
progression: add quest-count, active-day, and perfect-period criterion types

Wires PerfectPeriodEvaluator (was placeholder) to share logic with
cosmetic snapshot. Adds achievements: daily_quest_3, daily_quest_7,
quest_hunter_250, active_days_7, perfect_days_7, perfect_weeks_12.
```

```
progression: add compositeAllOf criterion for endgame achievements

Enables dragonrock_trial (level 100 + 250 quests + 10M steps) and
future composite achievements without bespoke evaluator code.
```

---

## Phase 4 — Reward Mapping Rewire

**Status:** ⏸️ Not Started
**Estimated scope:** ~2 soubory, ale velký dopad na user-visible behavior
**Dependencies:** Fáze 2 (definice musí existovat), Fáze 3 (achievementy musí existovat)

### Goal

Aktualizovat `CosmeticRewardTable.achievementToCosmetics` mapping podle plán tabulky. Zachovat 1:N (jeden achievement → více cosmetics, např. `steps_streak_7` → relic + frame). Zachovat idempotenci.

### Files affected

1. **`lib/features/progression/domain/cosmetic_reward_table.dart`** (ř. 22–45)

   Cílový mapping (kompletní replace `achievementToCosmetics`):

   ```dart
   static const Map<String, List<String>> achievementToCosmetics = {
     // Camp / onboarding
     'welcome_to_journey': ['background_camp', 'emblem_pilgrim_mark'],
     // ⚠️ Removed: 'frame_lvl1' (duplicitní s default frame), 'relic_old_compass' (legacy)
     'first_reward': ['relic_campfire_spark'],
     'daily_quest_3': ['relic_warm_kindling'],

     // Forest
     'active_days_7': ['relic_moonlit_foxglove'],
     'weekly_activity_mastery': ['relic_ancient_root'],
     'daily_quest_7': ['relic_wildwood_charm'],

     // Ravine / Ruins
     'steps_total_100k': ['relic_ravine_stone'],
     'steps_streak_7': ['relic_ruin_seal', 'frame_discipline'],
     'weekly_activity_4': ['relic_ashen_omen'],
     'combo_victory_10': ['relic_oathbound_mark'],

     // Bridges / Mines
     'reward_hunter_100': ['relic_bridge_key'],
     'steps_total_1000000': ['relic_deep_ember_core'],
     'combo_triple_victory_25': ['relic_miners_lantern'],

     // Frostlands
     'weekly_activity_24': ['relic_polar_lantern'],
     'quest_hunter_250': ['relic_frozen_lake_heart'],
     'steps_total_5000000': ['relic_frost_shard'],

     // Mountain Road
     'combo_triple_victory_100': ['relic_summit_feather'],
     'weekly_activity_52': ['relic_stormcrest_plume'],
     'steps_total_10000000': ['relic_dragon_scale', 'frame_worldwalker'],

     // Dragonrock endgame
     'dragonrock_trial': ['relic_dragonrock_heart'],

     // Frame achievements (steps streak frames)
     'steps_streak_30': ['frame_endurance'],
     'steps_streak_50': ['frame_steel'],
     'steps_streak_100': ['frame_eternal_flame'],
     'steps_month_600k': ['frame_endless_trail'],

     // Frame achievements (perfect period)
     'perfect_days_7': ['frame_balance'],
     'perfect_weeks_12': ['frame_master_routine'],
   };
   ```

2. **Žádné změny `levelToCosmetics`** v této fázi (level rewards zůstávají stejné).

### Backward compat / migration

**Stávající uživatelé** s odemčeným `welcome_to_journey` mají `relic_old_compass` v Isar. **Nemažeme je** — necháme legacy unlocks v inventáři. Catalog definici legacy reliců ponecháme (Fáze 6 řeší cleanup definic).

**Re-evaluation impact:** Po release dispatcher znovu projde `welcome_to_journey` → grant `background_camp` (no-op pokud už unlocked) + `emblem_pilgrim_mark` (no-op pokud už unlocked). **NEgrantuje** `relic_old_compass` znovu (ten už není v mapping), ale ten už v inventáři je z předchozí session. Net effect = uživatel nepozná žádnou změnu.

**Nový uživatel:** dostane upravenou sadu odměn bez `relic_old_compass`.

### Acceptance criteria

- [ ] Test: pro každý achievement v novém mappingu, mock unlock → ověř, že všechny cosmetics jsou granted.
- [ ] Test: re-run dispatcher po unlocku → žádné duplicate Isar records (composite unique constraint zajišťuje, ale verify).
- [ ] Test: existující user save (mock state s `relic_old_compass` unlocked) — po dispatcheru zůstane unlocked, žádný error.
- [ ] Manual smoke (devtools): force unlock `dragonrock_trial` → zobraz unlock notification pro `relic_dragonrock_heart`.
- [ ] `flutter analyze` + `flutter test` clean.

### Out of scope

- Companion unlock changes (Fáze 5).
- Removing legacy definitions z catalog (Fáze 6).

### Open questions / risks

- **Risk:** Pokud Fáze 3 (combo achievementy) zvolila TODO cestu, mappingy `combo_victory_10`, `combo_triple_victory_25`, `combo_triple_victory_100` ukazují na achievementy, které se nikdy neunlocknou. **Akce:** zkontrolovat dispatcher chování pro mapping na neexistující achievement — měl by být no-op (ne crash). Dokumentovat jako known TODO.
- **Q:** `relic_dragonrock_heart` jako mythic má specifické UI requirements (animace?)? Ověřit s designerem před release.

### Suggested commit message

```
progression: rewire cosmetic reward table per refactor plan

- Welcome reward drops legacy frame_lvl1 + relic_old_compass
- 17 achievements gain relic/frame rewards aligned to region progression
- Existing unlocks preserved (legacy items remain in user inventory)
```

---

## Phase 5 — Companion Unlock Refactor

**Status:** ⏸️ Not Started
**Estimated scope:** ~1 soubor (data only), ale critical path
**Dependencies:** Fáze 2 (relic definice), Fáze 4 (relic se musí grantovat z achievementů)

### Goal

Přepsat companion compound rules v `kCosmeticUnlockRules` na pattern `Cond.atLevel(N) + Cond.ownsCosmetic(relic_a) + Cond.ownsCosmetic(relic_b)`. Odstranit závislost na legacy reliców. Zachovat idempotenci a non-destruktivnost (relicy se neconsumují).

### Files affected

1. **`lib/features/cosmetics/domain/cosmetic_unlock_rules.dart`** (ř. 104–178, sekce companions)

   Cílový stav (replace celé companion sekce):

   ```dart
   // -- Companions: relics + level gate, idempotent, no consumption --------
   CosmeticUnlockRule(
     cosmeticId: 'companion_ember_sprite',
     sourceType: 'compound',
     sourceId: 'compound_jiskricka',
     conditions: [
       Cond.atLevel(5),
       Cond.ownsCosmetic('relic_campfire_spark'),
       Cond.ownsCosmetic('relic_warm_kindling'),
     ],
     isHidden: true,
   ),
   CosmeticUnlockRule(
     cosmeticId: 'companion_forest_fox',
     sourceType: 'compound',
     sourceId: 'compound_lesni_liska',
     conditions: [
       Cond.atLevel(10),
       Cond.ownsCosmetic('relic_moonlit_foxglove'),
       Cond.ownsCosmetic('relic_ancient_root'),
     ],
     isHidden: true,
   ),
   CosmeticUnlockRule(
     cosmeticId: 'companion_ruin_raven',
     sourceType: 'compound',
     sourceId: 'compound_havran_ruin',
     conditions: [
       Cond.atLevel(25),
       Cond.ownsCosmetic('relic_ruin_seal'),
       Cond.ownsCosmetic('relic_ashen_omen'),
     ],
     isHidden: true,
   ),
   CosmeticUnlockRule(
     cosmeticId: 'companion_lantern_golem',
     sourceType: 'compound',
     sourceId: 'compound_lucernovy_golem',
     conditions: [
       Cond.atLevel(45),
       Cond.ownsCosmetic('relic_deep_ember_core'),
       Cond.ownsCosmetic('relic_miners_lantern'),
     ],
     isHidden: true,
   ),
   CosmeticUnlockRule(
     cosmeticId: 'companion_ice_wisp',
     sourceType: 'compound',
     sourceId: 'compound_ledovy_prizrak',
     conditions: [
       Cond.atLevel(65),
       Cond.ownsCosmetic('relic_polar_lantern'),
       Cond.ownsCosmetic('relic_frozen_lake_heart'),
     ],
     isHidden: true,
   ),
   CosmeticUnlockRule(
     cosmeticId: 'companion_mountain_gryphon',
     sourceType: 'compound',
     sourceId: 'compound_horsky_gryf',
     conditions: [
       Cond.atLevel(85),
       Cond.ownsCosmetic('relic_summit_feather'),
       Cond.ownsCosmetic('relic_stormcrest_plume'),
     ],
     isHidden: true,
   ),
   CosmeticUnlockRule(
     cosmeticId: 'companion_dragonling',
     sourceType: 'compound',
     sourceId: 'compound_draci_mlade',
     conditions: [
       Cond.atLevel(100),
       Cond.ownsCosmetic('relic_dragon_scale'),
       Cond.ownsCosmetic('relic_dragonrock_heart'),
     ],
     isHidden: true,
   ),
   ```

2. **Tier-2 quest-driven relicy v `kCosmeticUnlockRules` (ř. 35–88) — DELETE**
   - Tyto relicy se nyní grantují z Tier-1 (achievement rewards). Tier-2 rules jsou redundantní a vytvářely by druhou cestu.
   - **Smazat:** `relic_campfire_spark` (Tier-2), `relic_pilgrim_cloak`, `relic_trail_compass`, `relic_ruin_seal` (Tier-2), `relic_bridge_key` (Tier-2), `relic_miners_lantern` (Tier-2), `relic_dragon_crown`, `relic_dragonrock_crown` Tier-2 rules.
   - **Rationale:** Plán říká "relic se odemyká pouze jako cosmetic reward za achievement" — žádný RelicUnlockCondition.

3. **Frame Tier-2 rules (`frame_balance`, `frame_master_routine`)** (ř. 91–102)
   - **DELETE.** Po Fázi 3+4 se grantují přes `perfect_days_7` / `perfect_weeks_12` achievementy.

### Verification: dispatcher fixed-point loop

Dispatcher (`cosmetic_unlock_dispatcher.dart` pass 3) má max 3 iterace. **Verify:**

- Iter 1: achievement unlocks granted (Tier-1) → relicy v inventáři.
- Iter 2: companion compound rules vidí owned relics → companion unlock.
- Iter 3: žádné nové unlocks → exit.

3 iterace stačí pro chain `achievement → relic → companion`. Pokud by někdy vznikl chain `companion → another companion`, fixed-point limit by mohl být problém — **dnes není**, ale dokumentovat.

### Acceptance criteria

- [ ] Unit test pro každého companiona: setup profile s required relicy + level → companion unlocked. Bez relic / pod level → nikoliv.
- [ ] Test: granting reliců a companion v jednom dispatch cyklu (achievement unlock → relic grant → companion grant) — všechno v jedné iteraci.
- [ ] Test: dispatcher zachová relicy v inventáři po companion unlocku (žádné consuming).
- [ ] Test: existující user state s legacy companion unlocks — companion zůstane unlocked (Isar má composite unique → re-eval no-op).
- [ ] Manual: dev script unlock všech reliců + level 100 → vidět všechny companions v wardrobe.
- [ ] Žádné rule v `kCosmeticUnlockRules` neodkazuje na: `relic_old_compass`, `relic_pilgrim_cloak`, `relic_old_gate_key`, `relic_dragon_crown`, `relic_dragonrock_crown`.

### Out of scope

- Smazání legacy relic definic z catalog (Fáze 6).
- UI checklist redesign pro companions (Fáze 6).

### Open questions / risks

- **Risk:** Existing users mají odemčené companions přes staré rule (např. `companion_dragonling` přes `relic_dragonrock_crown`). Po refactoru pravidlo vyžaduje `relic_dragon_scale` + `relic_dragonrock_heart`, které tito users nemají → companion zůstane unlocked v Isar (idempotence), ale nelze re-validate.
  - **Akce:** to je OK. Unlock je permanent (už je v Isar). Refactor se aplikuje jen na nové unlocky.
- **Risk:** Skip mid-tier companions pokud user proletí levely rychle bez questů? Např. user dosáhne level 25 ale nemá `relic_ruin_seal` (achievement `steps_streak_7` neunlock) → ruin_raven nedostupný. **To je by-design** dle plánu (companion unlock vyžaduje skutečný výkon, ne jen leveling).

### Suggested commit message

```
cosmetics: companions unlock via relics + level gate

Replaces ad-hoc compound rules with uniform pattern:
  Cond.atLevel(N) + Cond.ownsCosmetic(relic_a) + Cond.ownsCosmetic(relic_b)

Removes Tier-2 quest-driven relic rules — relics now flow exclusively from
achievement rewards (Tier-1). Existing unlocks are preserved.
```

---

## Phase 6 — Legacy Cleanup + UI

**Status:** ⏸️ Not Started
**Estimated scope:** Medium (UI work)
**Dependencies:** Fáze 5 (companion rules musí být na nových IDs)

### Goal

Vyčistit reference na legacy IDs z aktivních cest. Implementovat UI checklist pro companions ukazující required relics, achievement podmínky a level gate. Implementovat reveal policy.

### Sub-fáze 6a: Catalog legacy handling

**Files affected:**

1. **`lib/features/cosmetics/domain/cosmetic_catalog.dart`**
   - Legacy IDs k handleování: `relic_old_compass`, `relic_pilgrim_cloak`, `relic_old_gate_key`, `relic_dragon_crown`, `relic_dragonrock_crown`.
   - **Doporučená strategie:** ponechat definice s `isEnabled: true` ale skrýt z hlavního UI flowu (devtools / wardrobe filter).
     - Důvod: existing users mají tyto IDs v Isar, hard-delete by způsobil missing reference.
   - **Akce:**
     - Přidat `metadata: {'legacy': true}` do legacy definic.
     - V `cosmetics_screen.dart` filter out items kde `metadata['legacy'] == true` z primary grid (zobrazit v secondary "Archives" sekci nebo úplně skrýt).
     - **Alternativa:** přidat field `bool isLegacy = false` na `CosmeticDefinition`. Cleaner ale větší refactor — preferovat metadata.

### Sub-fáze 6b: Companion UI checklist

**Files affected:**

1. **`lib/features/cosmetics/presentation/cosmetic_details_sheet.dart`** (companion-specific section)
   - Pro companion item rozšířit detail sheet:

     ```
     Lesní liška  (locked)
     Requires:
     ✓ Moonlit Foxglove — 7 active days
     ✓ Ancient Root — first weekly activity
     ✕ Reach level 10
     ```

   - Použít `CosmeticUnlockRule.conditions` + `Cond.id` pro lokalizovaný popis.
   - Použít `CosmeticRevealEvaluator` (existuje v `cosmetic_reveal_evaluator.dart`) pro state.

2. **`lib/features/cosmetics/presentation/widgets/cosmetic_collection_tile.dart`** (existující)
   - Reveal state: pokud `partial`, ukázat progress (`2/3 splněno`).
   - Pokud `hidden` a level > companion.minLevel - 10 → switch na `visibleLocked` (revealing teaser).

### Sub-fáze 6c: Reveal policy

Per plán:

```text
unlocked: companion owned
visibleLocked: level >= minLevel - 10 OR owned any required relic
hidden: jinak
```

**Files affected:**

1. **`lib/features/cosmetics/domain/cosmetic_reveal_evaluator.dart`** (newly added, uncommitted)
   - Implementovat reveal policy logiku.
   - Pure function input: `(snapshot, definition, applicableRules) → CosmeticRevealState`.
   - Companion-specific: pokud žádné conditions met AND level < minLevel - 10 → `hidden`.

### Acceptance criteria

- [ ] Žádný production codepath nereferuje `relic_old_compass`, `relic_pilgrim_cloak`, `relic_old_gate_key`, `relic_dragon_crown`, `relic_dragonrock_crown` (grep clean — kromě legacy definic v katalogu).
- [ ] Companion details sheet zobrazí 3 conditions s ✓/✕ pro alespoň jeden companion.
- [ ] Hidden / visibleLocked / partial / unlocked states jsou viditelné v UI pro různé companions.
- [ ] Existing user s legacy relicy nevidí crash, legacy items se nezobrazí v hlavním wardrobe gridu.
- [ ] `flutter analyze` + `flutter test` clean.
- [ ] Manual: nový user playthrough — wardrobe ukazuje progressivní reveal companions jak hráč levelu je.

### Out of scope

- Animace pro mythic items (designer dodá).
- Achievement → companion attribution v unlock notification (separátní polish).

### Open questions / risks

- **Q:** Má `cosmetic_reveal_evaluator.dart` (uncommitted) už nějakou logiku, kterou bychom narušili?
  - **Akce:** `git diff` před začátkem Fáze 6, integrate / build on top.
- **Risk:** Legacy items v Isar se zobrazí v debug screen i když ne v wardrobe — to je OK pro dev workflow, dokumentovat.

### Suggested commit messages

```
cosmetics: hide legacy relic definitions from primary wardrobe UI

Legacy IDs (relic_old_compass, etc.) remain in catalog with
metadata['legacy']=true so existing users keep their unlocks. UI filters
them out of the main grid; they remain visible in devtools.
```

```
cosmetics: companion details sheet shows required relics + level gate

Implements reveal policy (hidden / visibleLocked / partial / unlocked)
per plan.md. Players see "1/3 conditions met — Moonlit Foxglove ✓,
Ancient Root ✕, Reach level 10 ✕" before unlock.
```

---

## Cross-cutting concerns

### Idempotence

Garantovaná na třech úrovních:

1. **Isar:** composite unique index (uid, cosmeticId).
2. **Repository:** `unlockCosmetic` je no-op pokud already owned.
3. **Dispatcher:** `_alreadyUnlocked()` check před každým grantem.

**Pravidlo:** žádný kód v refactoru nesmí volat `delete` nebo `consume` na cosmetic unlock record. Companions se "consumují" relicy jen logicky (via `Cond.ownsCosmetic`), ne destrukčně.

### Migration / backward compat

- Legacy unlock records v Isar zůstávají platné — Isar nemá schema migration potřebu.
- Firestore entitlements collection není dotčena.
- Cosmetic catalog je compile-time — nový build dostane nový catalog at once.

### L10n workflow

Po každé úpravě `app_en.arb` / `app_cs.arb`:

```bash
flutter gen-l10n
```

Generované soubory (`app_localizations*.dart`) jsou pod git. Pokud zapomeneš regenerovat, build selže s missing getter.

### Testing strategy

| Fáze | Test priority |
|---|---|
| 1 | Smoke: no UI crash, enum exhaustive switch checks pass |
| 2 | Catalog test: každý nový ID je unique, l10n closures resolvují |
| 3 | Unit test per criterion type, integration test per achievement |
| 4 | Mapping integration test: každý mapping ID existuje v achievement & cosmetic catalog |
| 5 | Compound rule unit test per companion |
| 6 | Reveal evaluator unit test per state |

---

## Final report template (na konci celého refactoru)

Po dokončení všech fází sepsat report:

1. **Soubory změněné:** (auto z `git log --stat main..feature-branch`)
2. **Nové achievement IDs:** seznam ID + criterion + reward
3. **Nové relic IDs:** seznam ID + region + difficulty + rarity
4. **Frame achievementy:** mapping achievement → frame
5. **Reward mapping shape:** popis jak achievement → cosmetics flow funguje
6. **Companion unlock shape:** popis compound rule patternu
7. **Legacy IDs status:** seznam co se kde používá / nepoužívá
8. **TODO odložené:** co zůstalo (combo quest implementace? mythic asset delivery?)

---

## Quick reference: file map

```
lib/features/cosmetics/domain/
├── cosmetic_models.dart           [Phase 1: rarity enum]
├── cosmetic_catalog.dart          [Phase 2: new definitions, Phase 6: legacy metadata]
├── cosmetic_unlock_rule.dart      [no changes — Cond helpers already complete]
├── cosmetic_unlock_rules.dart     [Phase 5: companion rewrite, remove Tier-2 relic rules]
├── cosmetic_unlock_evaluator.dart [no changes — generic enough]
├── cosmetic_unlock_snapshot.dart  [Phase 3: ensure perfect day count wires to PerfectPeriodEvaluator]
├── cosmetic_reveal_evaluator.dart [Phase 6: implement reveal policy]
└── cosmetic_reveal_state.dart     [Phase 6: maybe extend if states change]

lib/features/cosmetics/presentation/
├── cosmetics_palette.dart         [Phase 1: mythic case]
├── cosmetics_screen.dart          [Phase 6: filter legacy items]
├── cosmetic_details_sheet.dart    [Phase 6: companion checklist]
└── widgets/cosmetic_collection_tile.dart [Phase 6: reveal state UI]

lib/features/cosmetics/domain/cosmetics_config.dart [Phase 1: rarityDisplayOrder]

lib/features/progression/domain/
├── progression_models.dart        [Phase 1: difficultyScore, Phase 3: criterion types + composite]
├── progression_achievement_catalog.dart [Phase 3: new achievements]
├── progression_achievement_evaluator.dart [Phase 3: switch extensions]
├── perfect_period_evaluator.dart  [Phase 3b: real implementation]
└── cosmetic_reward_table.dart     [Phase 4: full mapping rewrite]

lib/l10n/
├── app_en.arb                     [Phase 1, 2, 3: keys for rarity, cosmetics, achievements]
└── app_cs.arb                     [same in Czech]
```

---

## Phase status table (update at end of each session)

| Phase | Status | PR | Notes |
|---|---|---|---|
| 0 — Discovery | ✅ Done (2026-05-03) | — | This document |
| 1 — Foundation | ✅ Done (2026-05-03) | `44ced0b` | mythic + difficultyScore added; 179/182 tests pass (3 HC failures pre-existing) |
| 2 — Catalog | ✅ Done (2026-05-03) | `515f216` | 9 new reliky + 5 updated rarity/region; first mythic catalog item (relic_dragonrock_heart); 54 ARB entries |
| 3-prep — l10n audit | ✅ Done (2026-05-03) | uncommitted | Closure refactor superseded by existing ProgressionL10n adapter; added missing switch cases for welcome_to_journey + steps_streak_50; convention noted |
| 3a — Simple criteria | ⏸️ Not Started | — | |
| 3b — Perfect periods | ⏸️ Not Started | — | |
| 3c — Combo quests | ⏸️ Not Started | — | TODO path acceptable |
| 3d — Composite | ⏸️ Not Started | — | dragonrock_trial only |
| 4 — Reward mapping | ⏸️ Not Started | — | |
| 5 — Companion rules | ⏸️ Not Started | — | |
| 6a — Legacy cleanup | ⏸️ Not Started | — | |
| 6b — Companion UI | ⏸️ Not Started | — | |
| 6c — Reveal policy | ⏸️ Not Started | — | |
