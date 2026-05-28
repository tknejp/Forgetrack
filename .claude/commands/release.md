---
description: Provedeš release podle docs/git_workflow.md §3 — preflight, blocker check, build, FAD upload, git operace.
---

# /release — orchestrace release procesu

Uživatel chce nový release Forgetrack. Postupuj **přesně podle těchto kroků**. Mezi kroky se zastav a počkej na potvrzení — release proces je destruktivní (push, tag, FAD upload) a stojí za to se ujistit.

## Kontext

- Workflow: [docs/git_workflow.md](../../docs/git_workflow.md) §3 (release) + §3a (changelog)
- Skript: [scripts/release.ps1](../../scripts/release.ps1) provádí build + FAD + git operace
- Beta readiness Tier 0 = release-blockery: [docs/release/beta_readiness.md](../../docs/release/beta_readiness.md)

## Postup

### 0. Bezpečnostní confirm gate

Release je destruktivní operace (push na main, tag, Firebase Storage upload, Firestore manifest write, FCM push testerům). Než cokoli začneš dělat, **explicitně se zeptej uživatele na potvrzení záměru**. Smyslem je odchytit `/release` zadaný omylem (překlep, špatné okno).

Formuluj jednou větou — krátce a konkrétně. Příklad:

> Spustím release proces (push na main, tag, build, upload do Storage, manifest do Firestore, push notifikace testerům). Pokračovat? Potvrď `ano` / `pokračuj` / `release`.

Akceptuj pouze jasné potvrzení (`ano`, `yes`, `ok`, `pokračuj`, `release`, `proveď` apod.). Pokud uživatel odpoví neutrálně / nejasně / vyhýbavě, **nepokračuj** — ptej se znovu nebo se zeptej, co měl na mysli.

Pokud user napsal `/release X.Y.Z` (s konkrétní verzí), zopakuj tu verzi ve své otázce („Spustím release v0.2.0 — pokračovat?"), aby měl šanci chytit překlep ve verzi.

**Tuto bránu nepřeskakuj nikdy.** I když to uživatel v minulé konverzaci povolil, vždy se ptej znovu.

### 1. Preflight (čistě informativní)

Spusť paralelně a vrať souhrn:

- `git rev-parse --abbrev-ref HEAD` — aktuální větev (musí být `develop`)
- `git status --porcelain` — musí být prázdné
- `git fetch origin develop --quiet && git rev-list --count develop..origin/develop` a opačně — sync s origin
- `git describe --tags --abbrev=0` — předchozí tag
- `git log <prev-tag>..HEAD --oneline --no-merges` — co bude v releasu

Pokud cokoli z toho selže (jiná větev, dirty tree, ahead/behind origin), **zastav se** a vysvětli uživateli, co opravit. Nepokoušej se to opravit sám (mohl bys ztratit nepushnutou práci).

### 2. Trello blocker check

Skript blocker check neumí (nemáš Trello MCP). Místo toho **explicitně se zeptej uživatele**:

> Zkontroluj Trello sloupec **Probíhá**. Není tam žádná Tier 0 (release-blocker) karta? Pokud ano, řekni mi — neřešený blocker = release se odkládá.

Počkej na "ok" / "potvrzeno" / nebo seznam karet. Pokud uživatel zmíní rozpracovaný blocker, **release nezahajuj** a navrhni další postup (dokončit blocker, nebo release přesto pokud user explicitně řekne).

### 3. Volba verze

Na základě commit logu od posledního tagu navrhni **SemVer bump**:

- `patch` (`0.1.0 → 0.1.1`): jen fixy, žádné nové features
- `minor` (`0.1.0 → 0.2.0`): nové features bez breaking changes
- `major` (`0.1.0 → 1.0.0`): breaking change *nebo* první stabilní release (přechod z `0.x` na `1.0`)

Vypiš commity setříděné podle scope-prefixu a u každého zařaď do kategorie. Pak navrhni `X.Y.Z` s odůvodněním. **Nech uživatele rozhodnout.**

### 4. Příprava release notes pro testery

Vytvoř `release_notes/v<X.Y.Z>.md` podle [release_notes/TEMPLATE.md](../../release_notes/TEMPLATE.md). Naplň ho na základě commit logu — **user-facing věty**, ne raw commit shorts. Sekce „Co testovat prioritně" naplň podle toho, co se nejvíc změnilo.

Ukaž uživateli draft a požádej o úpravy / schválení. Tester tento text uvidí přímo v in-app update dialogu (Firestore manifest field `notes`).

### 5. Příprava CHANGELOG.md draftu

Vygeneruj návrh, jak by měla vypadat sekce `[X.Y.Z]` v `CHANGELOG.md`:

- Seskup commity podle Keep-a-Changelog kategorií (`Added` / `Changed` / `Fixed` / `Removed`).
- Vynech čistý refactor, docs, test, internal commits (per §3a workflow doku).
- Zachovej Trello reference `[#NNN]`.

Ukaž draft uživateli. **Skript ti dá pauzu po bumpu changelogu** — naplníš tam tento draft ručně. Drž draft v conversation context, abys ho mohl rychle vložit.

### 6. Spuštění release skriptu

Spusť:

```powershell
.\scripts\release.ps1 -Version <X.Y.Z>
```

Pro netriviální release (víc než pár commitů) přidej `-RunTests`.

Skript je interaktivní (pauzuje na konfirmace). **Spusť ho ve foreground Bash/PowerShell — ne v background**, aby uživatel viděl prompty a mohl odpovídat. Pokud chce dry-run první, přidej `-DryRun`.

**Distribuční flow:** skript buildí `--flavor internal` (jediný flavor s REQUEST_INSTALL_PACKAGES + FileProvider, viz `docs/git_workflow.md §3.1`), pak `node scripts/publish_internal_build.js` uploadne APK do Firebase Storage + napíše Firestore manifest doc `app_config/latest_internal`. Bez `secrets/firebase-service-account.json` skript fail-uje hned v preflight (Storage / Firestore write potřebuje SA klíč). Po publish jde FCM push na topic `forgetrack-internal-builds` přes `send_release_push.js`. Pokud push selže, release pokračuje — tester to uvidí na resumed events tak jako tak.

### 7. Po dokončení

- Ověř výstup skriptu (poslední sekce „Hotovo").
- Připomeň uživateli, ať otevře app na zařízení s předchozím internal buildem a ověří, že na resume přijde in-app dialog „Nová verze". Tap → progress bar → systémový install prompt.
- Pokud byl release netriviální, nabídni aktualizaci `docs/release/beta_readiness.md` (přesun shippednutých karet).

## Co dělat NE

- ❌ Neprovádět žádné git push / tag operace mimo skript.
- ❌ Neopravovat dirty working tree „jen tak" — uživatel může mít rozpracovanou práci.
- ❌ Nepokračovat bez explicitního Trello-check potvrzení (krok 2).
- ❌ Nepřeskakovat draft fázi changelogu/release notes — generování → review → uložení, ne všechno naráz.
