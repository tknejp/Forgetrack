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

**Praktický flow je automatizovaný v [scripts/release.ps1](../scripts/release.ps1)** a orchestraci přes Claude pokrývá [`.claude/commands/release.md`](../.claude/commands/release.md) (stačí napsat „udělej release" nebo `/release`).

Tato sekce popisuje, **co se děje** — abys při ručním zásahu (skript spadne, nebo to chceš provést sám) věděl, co je třeba.

### 3.1 Distribuční kanál

- **DIY in-app updater** (Trello #132). Tester dostane APK link, sideloads → appka se od té chvíle updatuje sama bez sign-inu / Chrome Custom Tab / FAD plugin friction. UX jako u sideloaded apek odjinud (F-Droid styl).
- Firebase App ID: `1:798278342104:android:a44ecd497db4f28161cead` (package `com.knejp.forgetrack`).
- Build flavor: **`internal`** (`flutter build apk --release --flavor internal`) — pulluje `REQUEST_INSTALL_PACKAGES` permission + FileProvider pro APK handoff. `prod` zůstává Play Store policy-clean. Sdílí applicationId s `prod`, takže tester upgraduje in-place mezi flavorama bez data loss.
- **Hosting APK:** Firebase Storage, path `internal-builds/forgetrack-<version>-<buildNumber>.apk`, public read (security rules v `storage.rules`).
- **Manifest:** Firestore doc `app_config/latest_internal` se `{version, buildNumber, apkStoragePath, notes, releasedAt}`. Public read (security rules v `firestore.rules`).
- AAB až při přechodu na Play Internal Testing — pak DIY updater pojede do důchodu.

**Historie:** předchozí Firebase App Distribution (FAD) pokus je archivován tagem `archive/feature-fad-in-app-updater` (Trello karta #131). UX byla pro 5 kamarádů jako testery zbytečně friction-heavy; commity zůstávají ke cherry-picku, kdyby projekt přerostl na QA-style distribuci.

### 3.1a Tester notifikace o novém buildu

- **In-app updater:** tester otevře app → `ForgetrackApp.didChangeAppLifecycleState` (resumed) zavolá `AppUpdateService.checkForUpdate()` → poll Firestore manifest doc → pokud `buildNumber > current`, vlastní `AlertDialog` se ptá „Stáhnout a nainstalovat?". Tap → stream APK z Storage do app cache s progress barem → `Intent.ACTION_VIEW` přes FileProvider → systémový install prompt. (Žádný blokační overlay na home screen — updater běží paralelně s `refreshOnAppOpen`.)
- **FCM push:** tester se při app startu (jen na `internal` flavor) subscribe k topicu **`forgetrack-internal-builds`**. Release skript po úspěšném publish kroku odešle push „Forgetrack {version} k dispozici" — tap zařízení vzbudí, otevření appky pak triggernul in-app updater.
- **První install kamaráda:** manuálně přes Signal / Telegram / email — pošleš mu link na latest APK. Vyžaduje jednorázové „Install from unknown sources" enable per device. Další update už jen jeden tap.

### 3.2 Předpoklady před release

- Aktuální větev = `develop`, čistý working tree, synced s `origin/develop`.
- Žádná Tier 0 (release-blocker) karta v Trello sloupci **Probíhá** (viz [docs/release/beta_readiness.md](release/beta_readiness.md)).
- Existuje `release_notes/v<x.y.z>.md` s user-facing textem pro testera (vzor: [release_notes/TEMPLATE.md](../release_notes/TEMPLATE.md)). **Tento text se zobrazí přímo v in-app update dialogu** (Firestore doc field `notes`).
- **Firebase service-account JSON** na `secrets/firebase-service-account.json` (gitignored). Skript ho používá pro upload APK + write Firestore doc + FCM push. Service account potřebuje role:
  - `Editor` na projektu (one-shot, ale široký), NEBO least-privilege kombinace:
    - `Storage Object Admin` pro Storage upload
    - `Cloud Datastore User` pro Firestore write
    - `Firebase Cloud Messaging API Admin` pro FCM push
  - Vytvoření: [Google Cloud Console → IAM → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) → nový SA s rolemi → *Keys → Add Key → JSON*.
- **Firebase Storage bucket** musí být enabled v projektu (jednorázové, [Firebase Console → Storage → Get started](https://console.firebase.google.com/project/forgetracker-493415/storage)). Default bucket `forgetracker-493415.appspot.com`.
- **Firestore + Storage security rules deployed:** `firebase deploy --only firestore:rules,storage` (taky jednorázové, po každé změně rulů).
- **Node.js 18+** v PATH (`scripts/publish_internal_build.js` + `scripts/send_release_push.js` používají globální `fetch` + `node:crypto` pro JWT). Žádné `npm install` není potřeba.

### 3.3 Postup (co dělá `scripts/release.ps1`)

1. **Preflight** — validace všeho z 3.2 + dostupnost `flutter` a `node` CLI + neexistence cílového tagu + existence service-account JSON.
2. **Trello check** — interaktivní pauza s prompt na potvrzení.
3. **`release/x.y.z`** branch z `develop`.
4. **Bump `pubspec.yaml`** — version + build number (auto-inkrement, lze přebít `-BuildNumber`).
5. **`CHANGELOG.md`** — přejmenování `[Unreleased]` → `[x.y.z] - YYYY-MM-DD`, vložení nové prázdné `[Unreleased]` nahoře, link references. **Skript pauzne**, abys obsah sekce naplnil (commits → user-facing věty per §3a).
6. **Commit** bumpu + changelogu na release branch.
7. **`flutter analyze`** — gate (musí být clean).
8. **`flutter test`** — opt-in přes `-RunTests`.
9. **`flutter build apk --release --flavor internal`** → `build/app/outputs/flutter-apk/app-internal-release.apk`.
10. **Publish** přes `scripts/publish_internal_build.js`:
    - Upload APK na `gs://<project>.appspot.com/internal-builds/forgetrack-<version>-<buildNumber>.apk`
    - PATCH Firestore doc `app_config/latest_internal` se `{version, buildNumber, apkStoragePath, notes, releasedAt}`
    - Pokud kterýkoli z těchto kroků selže, release fail-uje (před git operacemi)
11. **FCM push** na topic `forgetrack-internal-builds` přes `scripts/send_release_push.js`. Při selhání jen warning — publish už proběhl, tester se o nové verzi dozví při dalším otevření appky tak jako tak.
12. **Merge `--no-ff` do `main`**, **tag `v<x.y.z>`**.
13. **Merge `main` zpět do `develop`** (kvůli verzi + changelogu).
14. **Archivace** release branch jako `archive/release-<x.y.z>` (viz §5).
15. **Push** `main`, `develop`, tags.

### 3.4 Manuální spuštění

```powershell
# Standard release
.\scripts\release.ps1 -Version 0.2.0

# Větší změny — spustit i testy
.\scripts\release.ps1 -Version 0.2.0 -RunTests

# Dry-run (žádné side-effecty)
.\scripts\release.ps1 -Version 0.2.0 -DryRun
```

### 3.5 Verzování

SemVer (`MAJOR.MINOR.PATCH`). Pre-1.0 znamená „pre-stable" (žádné API stability garance). Pre-release builds = `x.y.z-beta.N`.

Build number (`+N` v `pubspec.yaml`) je vždy monotónně rostoucí — **nikdy nesnižuj**, Android blokuje downgrade přes stejné application ID.

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
