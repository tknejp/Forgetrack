# Git Workflow

Zjednodušený GitFlow pro sólo vývoj. Cíl: udržet `main` čistý a release-ready, oddělit denní integraci od release historie, a přitom se nezahltit ceremoniálem feature-per-branch.

Tento dokument je závazný — Claude i člověk se ho drží. Pokud se ukáže nepraktický, **nejdřív se upraví dokument**, pak se podle něj pracuje.

---

## 1. Větve

| Větev | Účel | Životnost | Push na origin |
|---|---|---|---|
| `main` | Pouze release commits + tagy. Každý commit zde = vydaný build (nebo připravený k vydání). | Trvalá | Ano |
| `develop` | Integrační větev. Sem směřuje veškerý denní vývoj. | Trvalá | Ano |
| `feature/<slug>` | Volitelná. Pro rizikové / víceúčelové změny, experimenty, nebo když si nejsem jistý směrem. | Krátkodobá (dny) | Volitelné |
| `release/<x.y.z>` | Příprava release: bump verze, changelog, last-minute fixy. | Krátkodobá (hodiny–dny) | Volitelné |
| `hotfix/<slug>` | Urgentní oprava produkčního buildu, kterou nelze čekat přes `develop`. | Krátkodobá | Volitelné |

Smazané větve (release, feature, hotfix) **archivujeme tagem**, ne mazáním bez stopy (viz §5).

---

## 2. Denní vývoj

1. Defaultní pracovní větev je `develop`, ne `main`.
2. Drobné, samostatné změny (jeden commit, low-risk, dokument, lint fix) jdou rovnou na `develop`.
3. Větší / rizikové / víceúčelové změny dostanou `feature/<slug>` větev odvětvenou z `develop`. Merge zpět přes `--no-ff` (zachovat strukturu) NEBO rebase + fast-forward, pokud je historie čistá. Volba per case — preferujeme fast-forward, pokud branch má smysl jako lineární série.
4. Na `main` se přímo **necommituje nikdy**, kromě výjimky v §4 (hotfix).
5. Push na `origin/develop` po každém logickém celku — slouží jako záloha.

**Pravidlo pro Claude:** pokud uživatel řekne „pracuj na X" bez upřesnění větve, předpokládej `develop`. Pokud aktuální větev je `main`, **zastav se a zeptej se** (nebo přepni na `develop`, pokud uživatel řekl, že chce autonomně pokračovat).

---

## 3. Release

Když je na `develop` sada změn hodná release:

1. `git checkout -b release/x.y.z develop`
2. Bump verze v `pubspec.yaml`.
3. **Vygeneruj release notes** (viz §3a) a zapiš do `CHANGELOG.md`.
4. Build + smoke test (`flutter analyze`, relevantní `flutter test`, manuální průchod kritických flow).
5. Last-minute fixy committuj přímo na release branch.
6. Merge do `main` přes `--no-ff`: `git checkout main && git merge --no-ff release/x.y.z`.
7. **Tag na mainu**: `git tag -a v<x.y.z> -m "Release x.y.z"` (do tag message zkopíruj sekci changelogu pro tento release).
8. Merge `main` zpět do `develop` (kvůli verzi, changelogu a fixům): `git checkout develop && git merge main`.
9. Push: `git push origin main develop --tags`.
10. Archivuj release branch (viz §5).

Verzování: SemVer (`MAJOR.MINOR.PATCH`). Pre-release builds = `x.y.z-beta.N`.

---

## 3a. Release notes & CHANGELOG

**Princip:** release notes negenerujeme průběžně — generujeme je **at-release-time** z `git log` od posledního tagu. Disciplína je v commit messages (§6), ne v paralelním psaní changelogu.

**Formát:** `CHANGELOG.md` v root repozitáře, [Keep-a-Changelog](https://keepachangelog.com/) styl:

```markdown
# Changelog

## [Unreleased]

(volitelné — věci, které by z commit logu nebyly zřejmé: breaking changes,
migrace dat, deprecations, user-facing chování, které potřebuje vysvětlení)

## [0.4.0] - 2026-06-15

### Added
- progression: V2 quest engine s background notifikacemi
- ui: light theme

### Changed
- kt: error banner s eskalační kaskádou

### Fixed
- progression: replay completions po background fire

### Removed
- (nic)
```

Kategorie: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

**Postup generování při release (krok 3 v §3):**

1. `git log v<previous>..develop --oneline --no-merges` → surový seznam commitů.
2. Roztřiď podle scope-prefixu do kategorií Keep-a-Changelog. Pomůcka:
   - `feat:` / nové scope → **Added**
   - `fix:` / `hotfix:` → **Fixed**
   - refactor s viditelným chováním, perf, UX změna → **Changed**
   - `BREAKING:` v commit body → vlastní sekce + warning v textu
   - čistý refactor, docs, test, internal → **vynech** (nepatří do user-facing changelogu)
3. Přepiš z commit-shortu na user-facing větu (komu na tom záleží? co se změnilo z jeho pohledu?).
4. Pokud existovala sekce `[Unreleased]`, slij ji dovnitř (a vyprázdni).
5. Změň `## [Unreleased]` na `## [x.y.z] - YYYY-MM-DD` a přidej novou prázdnou `[Unreleased]` sekci nad.

**Kdy zapsat něco do `[Unreleased]` průběžně (a tedy NEzapomenout):**

Pouze pokud to z commit logu nebude poznat, typicky:

- Breaking change pro tester / uživatele (změna dat, reset, migrace).
- Deprecation s časovým rámcem.
- Známé regrese / `known issues`.

Vše ostatní vzniká až při release. **Default je nepsat do Unreleased — psát dobré commit messages.**

**Pravidlo pro Claude:** kdykoliv merguji větev s breaking změnou pro uživatele nebo s nutnou migrací dat, **připomeň přidání řádku do `[Unreleased]`** sekce `CHANGELOG.md`, i když to uživatel sám neřekne.

---

## 4. Hotfix

Pokud produkční build potřebuje opravu a `develop` má rozpracované změny, které ještě nejsou release-ready:

1. `git checkout -b hotfix/<slug> main`
2. Fix + bump PATCH verze.
3. Merge do `main` (`--no-ff`) + tag.
4. Merge `main` (nebo přímo hotfix branch) zpět do `develop`.
5. Archivuj.

---

## 5. Archivace short-lived branches

Po mergi `release/*`, `feature/*`, nebo `hotfix/*` větev **nemažeme rovnou**. Místo toho:

```bash
git tag archive/<original-branch-name> <branch>
git branch -d <branch>           # lokálně
git push origin --tags
git push origin --delete <branch>  # pokud byla pushnutá
```

Tagy `archive/*` jsou prohledatelné (`git tag -l "archive/*"`) a drží referenci na poslední commit té větve i po smazání. Release tagy `v*` jsou samostatné a nepřekrývají se.

---

## 6. Commit messages

- Imperativ, malé písmeno na začátku po prefixu, žádná tečka na konci řádku.
- Scope-prefix: `progression: …`, `kt: …`, `ui: …`, `docs: …`, `release: …`, `hotfix: …`.
- První řádek ≤ 72 znaků. Tělo (volitelné) vysvětluje *proč*, ne *co*.
- Žádné `Co-Authored-By: Claude` apod. — sólo projekt, lepší věrnost `git blame` (vidět, co psal AI vs. člověk).

### Linkování s Trello

Trello karty mají scope-prefix titulky (viz user memory `trello_workflow`). Pokud commit / branch / changelog řádek řeší konkrétní kartu, **uveď její číslo v hranatých závorkách**:

```text
progression: V2 background quest + achievement push notifications [#80]
fix/kt-banner-cascade  ← branch name
```

Pravidla:

- Číslo karty = krátké číslo z Trello URL (`https://trello.com/c/<shortlink>` → v UI vidíš `#80`).
- Více karet odděl čárkou: `[#80, #97]`.
- V changelog řádku se `[#NNN]` zobrazí jako `[#NNN](https://trello.com/c/<shortlink>)` pokud Claude / člověk doplní markdown link. Pokud ne, číslo samotné stačí — uživatel ho vyhledá.
- **Archivované karty:** Trello URL `https://trello.com/c/<shortlink>` funguje i pro archivované karty (jen nejsou viditelné v board view). Linkování tedy nepřestane fungovat po archivaci karty (což je důležité, protože workflow `trello_workflow` archivuje karty přímo, bez Hotovo sloupce).
- Pro plnou prohledatelnost archivovaných karet v Trello UI: filter v boardu → „Show archived cards" (nebo přímo `Menu → Archived items`).

**Pravidlo pro Claude:** když píšeš commit message nebo CHANGELOG řádek a v promptu / kontextu vidíš číslo Trello karty (`#NNN` nebo `cardId`), zařaď ho do hranatých závorek na konec řádku.

---

## 7. Co dělat NE

- ❌ Commit přímo do `main` mimo release/hotfix merge.
- ❌ Force-push na `main` nebo `develop` (na vlastní `feature/*` OK).
- ❌ Mazat větev bez archivačního tagu.
- ❌ Rebase commits, které už jsou pushnuté na `develop`/`main`.
- ❌ Mergovat `develop` do `main` mimo `release/*` proces (i kdyby to „jen procházelo").

---

## 8. Když je workflow překážka

Pokud konkrétní situace nesedí (např. nutnost rychlého experimentu mimo `develop`, paralelní rozpracovaná funkce), **uprav nejdřív tento dokument** a vysvětli proč. Workflow má sloužit, ne brzdit.
