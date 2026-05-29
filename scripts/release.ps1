<#
.SYNOPSIS
    Release orchestrator pro Forgetrack — podle docs/git_workflow.md §3.

.DESCRIPTION
    Provede release flow:
      1. Validace prostředí (větev, sync, čistý working tree, tooling)
      2. Vytvoří release/<version> branch
      3. Bumpne pubspec.yaml (version + build number)
      4. Aktualizuje CHANGELOG.md
      5. flutter analyze (gate)
      6. flutter build apk --release --flavor internal
      7. Publish: upload APK na Firebase Storage + write Firestore manifest doc
         (publish_internal_build.js) — toto je, co testerovi spustí in-app
         update prompt při dalším otevření appky
      8. FCM push na topic forgetrack-internal-builds (send_release_push.js,
         volitelné — pokud secrets/firebase-service-account.json existuje)
      9. Merge --no-ff do main, tag, merge zpět do develop, archivace
     10. Push všeho

    Skript je idempotentní: pokud spadne v půlce, můžeš ho rebootnout
    s -Resume (TODO — zatím manuálně cleanup).

.PARAMETER Version
    Nová SemVer verze (např. 0.2.0). Bez prefixu 'v'.

.PARAMETER BuildNumber
    Volitelné. Pokud chybí, auto-inkrementuje aktuální z pubspec.yaml.

.PARAMETER ReleaseNotesFile
    Cesta k release notes pro testery (markdown). Default: release_notes/v<version>.md.
    Soubor MUSÍ existovat před spuštěním.

.PARAMETER SkipBuild
    Přeskočí flutter analyze + build + Storage upload + Firestore manifest write.
    Jen git operace. Použít POUZE pro testování git části skriptu.

.PARAMETER SkipTests
    Přeskočí flutter test. Default: testy se NEspouští (zapne se opt-in přes -RunTests).

.PARAMETER RunTests
    Spustí flutter test před buildem. Doporučeno pro netriviální release.

.PARAMETER DryRun
    Žádné side-effecty (žádné commity, žádný git push, žádný Storage upload,
    žádný Firestore write, žádná FCM push). Vypíše, co by se stalo.

.EXAMPLE
    .\scripts\release.ps1 -Version 0.2.0

.EXAMPLE
    .\scripts\release.ps1 -Version 0.2.0 -RunTests -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$')]
    [string]$Version,

    [int]$BuildNumber = 0,

    [string]$ReleaseNotesFile = "",

    [switch]$SkipBuild,
    [switch]$RunTests,
    [switch]$DryRun,

    # -Yes: auto-confirm všech Confirm-Step pauz (Trello blocker check /
    # commit-confirm / CHANGELOG-naplněn). Použít POUZE když byly tyto kontroly
    # provedeny jinde (typicky Claude orchestrací přes .claude/commands/release.md,
    # kde Trello check + changelog draft proběhnou interaktivně předem). Bez -Yes
    # skript čeká na Read-Host — což zamrzne v non-interaktivním shellu.
    [switch]$Yes,

    # -Resume: pokračování z existující release/$Version po neúspěšném pokusu.
    # Předpoklady: jsme na release/$Version, release commit (release: $Version) existuje,
    # pubspec a CHANGELOG jsou už upravené, working tree je čistý.
    # Skript přeskočí Trello check + section 3-6 a pokračuje od flutter analyze.
    [switch]$Resume,

    # Cesta k Firebase service-account JSON. Skript ho používá pro:
    #   1) publish_internal_build.js → upload APK do Storage + write manifest
    #      docu do Firestore (povinné, bez něj se publish přeskočí a release
    #      fail-uje)
    #   2) send_release_push.js → FCM push na topic forgetrack-internal-builds
    #      (volitelné — když klíč chybí, push se přeskočí s varováním)
    # Service account potřebuje práva: Editor na projektu nebo (least-privilege)
    # Storage Object Admin + Cloud Datastore User + Firebase Cloud Messaging
    # API Admin.
    [string]$ServiceAccountKey = 'secrets/firebase-service-account.json'
)

$ErrorActionPreference = 'Stop'

# ─── Konfigurace ─────────────────────────────────────────────────────────────

# Build flavor pro distribuci kamarádům-testerům — pulluje
# REQUEST_INSTALL_PACKAGES permission + FileProvider pro in-app updater
# (viz docs/git_workflow.md §3.1). Sdílí applicationId s prod.
$BuildFlavor = 'internal'
$ApkPath = "build/app/outputs/flutter-apk/app-$BuildFlavor-release.apk"

# ─── Helper functions ────────────────────────────────────────────────────────

function Write-Section($title) {
    Write-Host ""
    Write-Host "════ $title ════" -ForegroundColor Cyan
}

function Write-Ok($msg) { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red }

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
    if ($DryRun -and ($Args[0] -in @('commit','push','tag','merge','checkout','branch'))) {
        $isReadonly = $Args -contains '--show-current' -or $Args[0] -in @('status','log','diff','rev-parse','show')
        if (-not $isReadonly) {
            Write-Host "  [DRY-RUN] git $($Args -join ' ')" -ForegroundColor DarkGray
            return ""
        }
    }
    $result = & git @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') selhal (exit $LASTEXITCODE)"
    }
    return $result
}

function Confirm-Step($prompt) {
    if ($DryRun) {
        Write-Host "  [DRY-RUN] auto-confirm: $prompt" -ForegroundColor DarkGray
        return
    }
    if ($Yes) {
        Write-Host "  [-Yes] auto-confirm: $prompt" -ForegroundColor DarkGray
        return
    }
    $resp = Read-Host "$prompt [y/N]"
    if ($resp -ne 'y' -and $resp -ne 'Y') {
        throw "Přerušeno uživatelem."
    }
}

# UTF-8 file IO helpers — PowerShell 5.1 'Get-Content -Raw' defaultně čte ANSI
# (na cs-CZ locale Windows-1252), což rozbije UTF-8 soubory s diakritikou.
# Set-Content -Encoding utf8 v PS5.1 zase přidává BOM. Tady řešíme oboje
# přes .NET API — read auto-detect BOM, write vždy UTF-8 bez BOM.
$Script:Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Read-Utf8File($path) {
    return [System.IO.File]::ReadAllText((Resolve-Path $path))
}

function Write-Utf8File($path, $content) {
    # Resolve-Path failuje na neexistujícím cíli, takže si normalizujeme cestu manuálně.
    $abs = Join-Path (Get-Location) $path
    [System.IO.File]::WriteAllText($abs, $content, $Script:Utf8NoBom)
}

# ─── Sekce 1: Preflight validace ─────────────────────────────────────────────

Write-Section "Preflight"

# 1.1 Aktuální větev: develop (normál) nebo release/$Version (resume)
$currentBranch = (Invoke-Git rev-parse --abbrev-ref HEAD).Trim()
if ($Resume) {
    if ($currentBranch -ne "release/$Version") {
        Write-Fail "Resume mode: očekáván branch release/$Version, jsi na $currentBranch"
        throw "Pro resume přepni na release/$Version (nebo spusť bez -Resume)."
    }
    # Validuj že release commit existuje
    $expectedSubject = "release: $Version"
    $headSubject = (Invoke-Git log -1 --pretty=%s).Trim()
    # Hlava může být release commit, nebo follow-up fix commit nad ním
    $hasReleaseCommit = (Invoke-Git log --pretty=%s -50 | Where-Object { $_ -eq $expectedSubject }) -ne $null
    if (-not $hasReleaseCommit) {
        Write-Fail "Resume mode: nenašel jsem commit '$expectedSubject' v posledních 50 commitech na release/$Version"
        throw "Stav vypadá nečekaně — radši zresetuj a spusť bez -Resume."
    }
    Write-Ok "Na release/$Version (resume mode, release commit nalezen)"
} else {
    if ($currentBranch -ne 'develop') {
        Write-Fail "Aktuální větev: $currentBranch (očekáváno: develop)"
        throw "Release musí startovat z develop."
    }
    Write-Ok "Na develop"
}

# 1.2 Resolve release-notes path early (povolíme ho v dirty-tree checku níž)
if (-not $ReleaseNotesFile) {
    $ReleaseNotesFile = "release_notes/v$Version.md"
}
# git status --porcelain používá / — normalizuj pro porovnání.
$expectedNotesPath = $ReleaseNotesFile -replace '\\','/'

# 1.3 Čistý working tree
$dirtyLines = (Invoke-Git status --porcelain) -split "`n" | Where-Object { $_.Trim() }
if ($Resume) {
    # V resume modu nesmí být nic dirty — release commit už proběhl, all-clean očekáváno.
    if ($dirtyLines) {
        Write-Fail "Resume mode vyžaduje čistý working tree, ale:"
        $dirtyLines | ForEach-Object { Write-Host "  $_" }
        throw "Commitni nebo stashni změny před resume."
    }
    Write-Ok "Working tree čistý"
} else {
    # Normální mode: release-notes soubor pro tuto verzi je povolený jako untracked / staged.
    $unexpectedDirty = $dirtyLines | Where-Object {
        $path = ($_ -replace '^...','').Trim()
        if ($path.StartsWith('"') -and $path.EndsWith('"')) {
            $path = $path.Substring(1, $path.Length - 2)
        }
        $path -ne $expectedNotesPath
    }
    if ($unexpectedDirty) {
        Write-Fail "Working tree není čistý (mimo $expectedNotesPath):"
        $unexpectedDirty | ForEach-Object { Write-Host "  $_" }
        throw "Commitni nebo stashni změny před release."
    }
    if ($dirtyLines) {
        Write-Ok "Working tree čistý (mimo release notes — budou součástí release commitu)"
    } else {
        Write-Ok "Working tree čistý"
    }
}

# 1.4 Develop synced s origin (v resume modu N/A — jsme na release/$Version)
if (-not $Resume) {
    Invoke-Git fetch origin develop --quiet
    $localHead = (Invoke-Git rev-parse HEAD).Trim()
    $remoteHead = (Invoke-Git rev-parse origin/develop).Trim()
    if ($localHead -ne $remoteHead) {
        Write-Fail "develop není synced s origin/develop"
        Write-Host "  local:  $localHead"
        Write-Host "  remote: $remoteHead"
        throw "Push / pull develop před release."
    }
    Write-Ok "develop synced s origin"
}

# 1.4 Verze ještě neexistuje jako tag
$existingTag = git tag -l "v$Version"
if ($existingTag) {
    throw "Tag v$Version už existuje. Zvol jinou verzi."
}
Write-Ok "Tag v$Version neexistuje"

# 1.5 Tooling
foreach ($tool in @('flutter','node')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool není v PATH."
    }
}
Write-Ok "flutter + node v PATH"

# 1.6 Service-account key check (publish krok nemůže běžet bez něj)
if (-not $SkipBuild -and -not (Test-Path $ServiceAccountKey)) {
    Write-Fail "Service-account JSON nenalezen: $ServiceAccountKey"
    Write-Host "  Tento klíč skript potřebuje pro upload APK do Storage + write Firestore manifest."
    Write-Host "  Vytvoř ho ve Firebase Console (Project settings → Service accounts → Generate new private key)"
    Write-Host "  a ulož do $ServiceAccountKey (gitignored)."
    throw "Chybí service-account JSON."
}
if (-not $SkipBuild) {
    Write-Ok "Service-account JSON: $ServiceAccountKey"
}

# 1.7 Release notes file (cesta vyřešena v sekci 1.2)
if (-not $SkipBuild -and -not (Test-Path $ReleaseNotesFile)) {
    Write-Fail "Release notes pro testery chybí: $ReleaseNotesFile"
    Write-Host "  Vytvoř soubor (vzor: release_notes/TEMPLATE.md) a pusť znovu."
    throw "Chybí release notes."
}
if (-not $SkipBuild) {
    Write-Ok "Release notes: $ReleaseNotesFile"
}

# ─── Sekce 2–6: jen v non-resume modu ───────────────────────────────────────
if (-not $Resume) {

# ─── Sekce 2: Trello blocker check (manuální) ────────────────────────────────

Write-Section "Trello blocker check (manuální)"

Write-Host "  Otevři Trello, sloupec 'Probíhá'. Žádná Tier 0 (release-blocker) karta tam nesmí být."
Write-Host "  (Tier 0 = release-blockery z docs/release/beta_readiness.md.)"
Confirm-Step "Zkontrolováno, žádné blockers?"

# ─── Sekce 3: Aktuální stav + changelog draft ────────────────────────────────

Write-Section "Aktuální stav"

# Najdi předchozí tag. Pouze release tagy (v*) — archive/* a jiné lightweight
# tagy by jinak vyhrály (jsou topologicky blíž HEAD po mergi feature branche),
# což rozbije commit-log od posledního *vydaného* releasu.
$prevTag = git describe --tags --abbrev=0 --match "v*" 2>$null
if (-not $prevTag) {
    Write-Warn "Žádný předchozí tag — generuji změny od počátku historie."
    $prevTag = (Invoke-Git rev-list --max-parents=0 HEAD).Trim()
}
Write-Host "  Předchozí tag: $prevTag"
Write-Host "  Nová verze:    v$Version"
Write-Host ""
Write-Host "  Commits od $prevTag (excl. merges):"
$commitLog = git log "$prevTag..HEAD" --oneline --no-merges
$commitLog | ForEach-Object { Write-Host "    $_" }

if (-not $commitLog) {
    throw "Žádné commity od $prevTag — není co releasovat."
}

Confirm-Step "Pokračovat s těmito commity?"

# ─── Sekce 4: Bump pubspec.yaml ──────────────────────────────────────────────

Write-Section "Bump pubspec.yaml"

$pubspecPath = "pubspec.yaml"
$pubspecContent = Read-Utf8File $pubspecPath
if ($pubspecContent -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?)\+(\d+)') {
    throw "Nepodařilo se naparsovat version z pubspec.yaml"
}
$currentVersion = $Matches[1]
$currentBuild = [int]$Matches[3]

if ($BuildNumber -eq 0) {
    $BuildNumber = $currentBuild + 1
}

Write-Host "  $currentVersion+$currentBuild → $Version+$BuildNumber"

if (-not $DryRun) {
    $newPubspec = $pubspecContent -replace '(?m)^version:.*', "version: $Version+$BuildNumber"
    Write-Utf8File $pubspecPath $newPubspec
}
Write-Ok "pubspec.yaml bumped"

# ─── Sekce 5: CHANGELOG.md ──────────────────────────────────────────────────

Write-Section "CHANGELOG.md"

$changelogPath = "CHANGELOG.md"
$changelogContent = Read-Utf8File $changelogPath
$today = Get-Date -Format 'yyyy-MM-dd'

# Najdi [Unreleased] sekci, přejmenuj na [version] - date
if ($changelogContent -notmatch '(?ms)^## \[Unreleased\]') {
    Write-Warn "Sekce [Unreleased] nenalezena v CHANGELOG.md — přidávám prázdnou."
}

# Nová struktura: nová [Unreleased] nahoře + přejmenovaná stará na [version]
$newSection = @"
## [Unreleased]

## [$Version] - $today
"@

$updatedChangelog = $changelogContent -replace '## \[Unreleased\]', $newSection

# Přidat link reference na konec (před existující links sekci, nebo na konec)
$linkLine = "[$Version]: https://github.com/tknejp/Forgetrack/releases/tag/v$Version"
# Aktualizovat [Unreleased] link reference
$updatedChangelog = $updatedChangelog -replace '\[Unreleased\]:\s*https://github\.com/tknejp/Forgetrack/compare/v[\d.]+\.\.\.HEAD',
    "[Unreleased]: https://github.com/tknejp/Forgetrack/compare/v$Version...HEAD"
# Vložit link pro novou verzi (nad ostatní version linky)
$updatedChangelog = $updatedChangelog -replace '(\[Unreleased\]:[^\n]+\n)', "`$1$linkLine`n"

if (-not $DryRun) {
    Write-Utf8File $changelogPath $updatedChangelog
}
Write-Ok "CHANGELOG.md aktualizován"

Write-Host ""
Write-Host "  Zkontroluj/uprav CHANGELOG.md (commits → user-facing věty)."
Write-Host "  Sekce [$Version] je teď prázdná — naplň ji nyní v jiném okně."
Confirm-Step "CHANGELOG.md upravený a uložený?"

# ─── Sekce 6: Vytvořit release branch + commit ───────────────────────────────

Write-Section "Release branch"

Invoke-Git checkout -b "release/$Version" develop
Write-Ok "Vytvořena release/$Version"

if (-not $DryRun) {
    git add pubspec.yaml CHANGELOG.md
    if (Test-Path $ReleaseNotesFile) {
        git add -- $ReleaseNotesFile
    }
    git commit -m "release: $Version" | Out-Null
}
Write-Ok "Commit s bumpem + changelogem + release notes"

} else {
    Write-Section "Resume mode — přeskakuji Trello/commit-confirm/bump/changelog/branch-create"
    Write-Ok "Pokračuji od flutter analyze (sekce 7)"
}

# ─── Sekce 7: Build + analyze (volitelně testy) ──────────────────────────────

if (-not $SkipBuild) {
    Write-Section "flutter analyze"
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        throw "flutter analyze selhal."
    }
    Write-Ok "analyze clean"

    if ($RunTests) {
        Write-Section "flutter test"
        flutter test
        if ($LASTEXITCODE -ne 0) {
            throw "flutter test selhal."
        }
        Write-Ok "testy prošly"
    }

    # flutter clean před release buildem — incremental build cache umí držet
    # stale libapp.so v APK (testeři viděli staré chování v release modu, viz
    # Trello #132 post-mortem). Clean stojí ~1-2 min navíc, ale release build
    # musí být deterministicky čistý.
    Write-Section "flutter clean (stale libapp.so guard)"
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        throw "flutter clean selhal."
    }
    Write-Ok "clean"

    Write-Section "flutter build apk --release --flavor $BuildFlavor"
    flutter build apk --release --flavor $BuildFlavor --dart-define=FLAVOR=$BuildFlavor
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build selhal."
    }
    if (-not (Test-Path $ApkPath)) {
        throw "APK nenalezeno na $ApkPath po buildu."
    }
    Write-Ok "APK: $ApkPath"

    # ─── Sekce 8: Publish — Storage upload + Firestore manifest write ───────

    Write-Section "Publish (Storage + Firestore)"

    $publishArgs = @(
        'scripts/publish_internal_build.js',
        $Version, $BuildNumber, $ApkPath, $ReleaseNotesFile, $ServiceAccountKey
    )

    if ($DryRun) {
        Write-Host "  [DRY-RUN] node $($publishArgs -join ' ')" -ForegroundColor DarkGray
    } else {
        node @publishArgs
        if ($LASTEXITCODE -ne 0) {
            throw "publish_internal_build.js selhal (exit $LASTEXITCODE)."
        }
        Write-Ok "APK na Storage + manifest doc na Firestore"
    }

    # ─── Sekce 8a: FCM push na topic forgetrack-internal-builds ─────────────

    Write-Section "FCM push (forgetrack-internal-builds)"

    if ($DryRun) {
        Write-Host "  [DRY-RUN] node scripts/send_release_push.js $Version $BuildNumber $ServiceAccountKey" -ForegroundColor DarkGray
    } else {
        node scripts/send_release_push.js $Version $BuildNumber $ServiceAccountKey
        if ($LASTEXITCODE -ne 0) {
            # Publish krok už proběhl, push selhání nesmí shodit zbytek release
            # flow. Tester příšte appku otevře → checkForUpdate() přečte
            # Firestore manifest → dialog se zobrazí tak jako tak.
            Write-Warn "FCM push selhal (exit $LASTEXITCODE) — release pokračuje."
        } else {
            Write-Ok "Push odeslán na topic forgetrack-internal-builds"
        }
    }
} else {
    Write-Section "Build & publish SKIPPED (-SkipBuild)"
}

# ─── Sekce 9: Merge do main + tag ───────────────────────────────────────────

Write-Section "Merge → main + tag"

Invoke-Git checkout main
Invoke-Git merge --no-ff "release/$Version" -m "release: merge release/$Version → main"

$tagMessage = "Release $Version`n`nViz CHANGELOG.md sekce [$Version]."
if (-not $DryRun) {
    git tag -a "v$Version" -m $tagMessage
    Write-Ok "Tag v$Version vytvořen"
} else {
    Write-Host "  [DRY-RUN] git tag -a v$Version" -ForegroundColor DarkGray
}

# ─── Sekce 10: Merge main → develop, archivace ──────────────────────────────

Write-Section "Sync develop + archivace"

Invoke-Git checkout develop
Invoke-Git merge main -m "release: merge main back to develop (v$Version)"
Write-Ok "main → develop"

if (-not $DryRun) {
    git tag "archive/release-$Version" "release/$Version"
    git branch -d "release/$Version"
}
Write-Ok "release/$Version archivován jako archive/release-$Version"

# ─── Sekce 11: Push ─────────────────────────────────────────────────────────

Write-Section "Push"

if ($DryRun) {
    Write-Host "  [DRY-RUN] git push origin main develop --tags" -ForegroundColor DarkGray
} else {
    git push origin main develop --tags
    Write-Ok "Pushnuto: main, develop, tags"
}

# ─── Done ───────────────────────────────────────────────────────────────────

Write-Section "Hotovo"
Write-Host "  Release v$Version" -ForegroundColor Green
Write-Host "  - Build:    $ApkPath (flavor: $BuildFlavor)"
Write-Host "  - Storage:  internal-builds/forgetrack-$Version-$BuildNumber.apk"
Write-Host "  - Manifest: app_config/latest_internal"
Write-Host "  - Push:     topic forgetrack-internal-builds"
Write-Host "  - Git tag:  v$Version (na main HEAD)"
Write-Host "  - Archive:  archive/release-$Version"
Write-Host ""
Write-Host "  Další krok: otevři appku na zařízení s předchozím buildem internal"
Write-Host "              flavoru → resumed → AppUpdateService najde novější"
Write-Host "              build → in-app dialog → Stáhnout a nainstalovat."
