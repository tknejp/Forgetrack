# Beta Readiness Plan

**Stav: 2026-05-21**

Cíl: dovést Forgetrack do stavu, kdy lze poslat build malému okruhu testerů (~5–10 lidí na Androidu) bez rizika pro produkční data, s funkční telemetrií a feedback smyčkou. Plán se řídí po vlnách — první vlna validuje základní mechanismy, druhá staví na zpětné vazbě.

Tento dokument je pracovní tracker. Architektonické rozhodnutí, které se v průběhu plánu udělají, patří do ADR ([docs/site/data/decisions.json](../site/data/decisions.json)), ne sem.

## Stav v Trellu k dnešku

Sloupec **Probíhá** po reklasifikaci (2026-05-21):

| Tier | # | Karta | Stav |
|---|---|---|---|
| 0 | [#108](https://trello.com/c/SOQFZYgU) | Android — vlastní applicationId + release signingConfig | ✓ shipped 2026-05-21 |
| 0 | [#75](https://trello.com/c/g4ADmdO9) | Debug + production build flavors | ✓ shipped 2026-05-21 |
| 0 | [#70](https://trello.com/c/x2nl5b6y) | Crash reporting + feedback SDK | ⚠ code shipped 2026-05-22 — e2e verify pending |
| 1 | [#97](https://trello.com/c/ez8f3wXm) | KT sync — error banner eskalační kaskáda | — |
| 1 | [#79](https://trello.com/c/E3YaeVBK) | Persistence schema migration framework | — |
| 2 | [#110](https://trello.com/c/ay5Pk5Ri) | Cosmetics — Firestore hybrid repo | — |
| 2 | [#106](https://trello.com/c/QawQ5XxC) | Devtools — Firestore `devUsers/{uid}` lookup | — |
| 2 | [#74](https://trello.com/c/rdHZqAcP) | Light theme | — |
| 2 | [#73](https://trello.com/c/FfJR6mve) | RPG mode — toggle pro skrytí RPG obsahu | — |

## Sprint plán

### Sprint 1 — Tier 0 (release-blockers, ~5–7 dní)

Vyřešit dřív, než si první tester nainstaluje build. Cíl: existuje **prod build flavor** s vlastním podpisovým klíčem, který telemetruje crash + feedback do existujícího Firebase projektu.

**Pořadí:** #108 → #75 → #70

#108 a #75 se prolínají (oba šahají do `android/app/build.gradle.kts`); doporučuji #108 ukončit jako samostatný commit, pak na něm postavit flavor split.

### Sprint 2 — Tier 1 (~3–5 dní)

První tester už má build a začíná hlásit. Vyřešit známý UX dead-end (KT banner) a postavit pojistku proti ztrátě dat při budoucích schema změnách.

**Pořadí:** #97 (rychlá UX oprava) → #79 (architektonická pojistka)

Mezi Sprintem 1 a 2 = **gate na první beta build**. Až po něm jdou Tier 1 karty.

### Sprint 3 — Tier 2 (~1–2 týdny, dle priorit z feedbacku)

Karty řazené po hlasité poptávce od testerů. Reálné pořadí se rozhodne na základě zpětné vazby.

**Default pořadí:** #110 → #106 → #73 → #74

---

## Tier 0 — Release blockers

### #108 — Android: vlastní applicationId + release signing

**Cíl:** release build je podepsaný produkčním klíčem, ne debug klíčem.

**Aktuální stav** ([android/app/build.gradle.kts:39](../../android/app/build.gradle.kts#L39)): `signingConfigs.release` chybí, release build dědí debug klíč. To znamená: nelze rotovat klíč, nelze nahrát na Play Store (zachytí to validace).

**applicationId** je už dnes `com.knejp.forgetrack` ([android/app/build.gradle.kts:26](../../android/app/build.gradle.kts#L26)) a `google-services.json` na něj má registrované OAuth clients. Tj. jediná open otázka je *suffix pro debug flavor* (řeší se v #75).

**Kroky:**

1. Vygenerovat release keystore mimo repo (`keytool -genkey -v -keystore forgetrack-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias forgetrack`).
2. Uložit klíč do bezpečného password manageru (1Password / Bitwarden). **Nikdy do gitu.**
3. Vytvořit [android/key.properties](../../android/key.properties) (gitignored) s `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
4. Přidat `key.properties` do [android/.gitignore](../../android/.gitignore) (ověřit, že tam ještě není).
5. V [android/app/build.gradle.kts](../../android/app/build.gradle.kts):
   - Načíst `key.properties` přes `Properties().load()`.
   - Definovat `signingConfigs { create("release") { ... } }`.
   - Připojit `signingConfig = signingConfigs.getByName("release")` na `buildTypes.release`.
6. Otestovat `flutter build apk --release` — APK musí být podepsaný novým klíčem (`apksigner verify --print-certs app-release.apk`).

**Acceptance:**
- [x] `flutter build apk --release` vytvoří podepsaný APK ne debug klíčem. *(2026-05-21: ověřeno přes `apksigner verify --print-certs` — V2 scheme, CN=Tomas Knejp, RSA 2048; viz changelog níže pro fingerprint.)*
- [x] `key.properties` a `.jks` jsou v `.gitignore` a nejsou commitnuté. *(2026-05-21: `android/.gitignore` řádky 12–14 pokrývají `key.properties` + `**/*.jks` + `**/*.keystore`.)*
- [ ] Hash klíče je zaznamenaný offline (pro budoucí rotaci se musí zachovat původní hash u Google Play Console). *(SHA-256 / SHA-1 / MD5 byly předány v chat session 2026-05-21 — uživatel je má uložit do password manageru offline.)*

**Velikost:** ½ dne (mechanická operace, jen pozor na ztrátu klíče).

**Závislosti:** žádné.

---

### #75 — Debug + production build flavors

**Cíl:** dva paralelně instalovatelné flavor builds (`debug` + `prod`) s oddělenými `applicationId`, oddělenými Firebase apps, oddělenými lokálními daty. Tester nainstaluje `prod`, vývojář současně používá `debug` na tom samém zařízení bez kolize stavu.

**Aktuální stav:** žádný flavor split, jediný `applicationId = com.knejp.forgetrack`. Veškerá runtime differenciace běží na `kDebugMode` (5+ míst v `lib/`). iOS bundle ID je dnes `com.example.forgetracker` v [firebase_options.dart](../../lib/firebase_options.dart) — to je dev placeholder, který musí padnout.

**Kroky:**

1. **Rozhodnout o Firebase strukturuře** *(otevřená otázka, decide dřív, než začneš)*:
   - **Varianta A — jeden projekt, dvě apps** (doporučeno pro malý tým): sdílené Auth, Firestore, ale `applicationId` rozlišuje. Build flavor jen volí, do které app se inicializuje.
   - **Varianta B — dva Firebase projekty**: úplná izolace dat. Výhoda: vývojářské experimenty nemohou rozbít produkční Firestore. Nevýhoda: duplikace setupu (rules, indexy, billing).
   - **Default:** Varianta A. Reálná izolace dat se dosáhne separátním `applicationId` (Android), což znamená separátní lokální Isar/Prefs adresář. Firestore data se mohou rozlišit prefixem v document path nebo seedingem dev users.
2. **Android `productFlavors`** v [android/app/build.gradle.kts](../../android/app/build.gradle.kts):
   ```kotlin
   flavorDimensions += "default"
   productFlavors {
     create("debug") {
       dimension = "default"
       applicationIdSuffix = ".debug"
       resValue("string", "app_name", "Forgetrack DEV")
     }
     create("prod") {
       dimension = "default"
       resValue("string", "app_name", "Forgetrack")
     }
   }
   ```
3. **Vytvořit launcher ikonu** pro `debug` flavor (overlay s textem „DEV" / odlišná barva). `android/app/src/debug/res/mipmap-*/ic_launcher.*`. Bez tohohle vývojář nepozná, kterou appku zrovna otevírá.
4. **iOS schemes** — `Runner-Debug` + `Runner-Prod`, xcconfig per flavor s `PRODUCT_BUNDLE_IDENTIFIER`. iOS bundle ID musí být sjednocený s Android (`com.knejp.forgetrack` / `.debug`) — současný `com.example.forgetracker` v `firebase_options.dart` pochází z `flutterfire configure` defaultu a musí být přegenerovaný. *Poznámka:* iOS plnou TestFlight pipeline řeší [#2](https://trello.com/b/du34lNAt) — pro Sprint 1 stačí mít flavor scaffolding připravený, plný Apple Developer setup může počkat.
5. **Firebase apps**:
   - V Firebase console založit druhou Android app (`com.knejp.forgetrack.debug`).
   - Stáhnout druhý `google-services.json` do `android/app/src/debug/`.
   - Existující `google-services.json` přesunout do `android/app/src/prod/`.
6. **`firebase_options.dart` per flavor** — vygenerovat přes `flutterfire configure --project=<id> --out=lib/firebase_options_prod.dart` a `--out=lib/firebase_options_debug.dart`. V `main.dart` přepnout podle `BuildConfig.flavor`.
7. **`BuildConfig` enum**:
   ```dart
   // lib/core/build_config.dart
   enum Flavor { debug, prod }
   class BuildConfig {
     static const flavor = Flavor.values.byName(
       String.fromEnvironment('FLAVOR', defaultValue: 'debug'),
     );
     static bool get isDebug => flavor == Flavor.debug;
     static bool get isProd => flavor == Flavor.prod;
   }
   ```
   Předávat přes `--dart-define=FLAVOR=prod` v build commandě.
8. **Devtools gating** v [lib/features/devtools/application/devtools_permission_service.dart](../../lib/features/devtools/application/devtools_permission_service.dart): nahradit `kReleaseMode` kontrolu za `BuildConfig.isProd` + explicit dev user list (souvisí s #106).
9. **Health Connect**: debug build musí být zaregistrovaný v Health Connect manifest s vlastním package name. Otestovat, že debug flavor dostane permission grant po reinstalaci.
10. **Dokumentace**: zápis do [README.md](../../README.md) — `flutter run --flavor debug --dart-define=FLAVOR=debug` vs. `--flavor prod --dart-define=FLAVOR=prod`.

**Acceptance:**
- [ ] Lze nainstalovat `debug` i `prod` zároveň, ikonky jsou rozlišitelné.
- [ ] Devtools se v `prod` buildu nezobrazí (nezávisle na `kDebugMode`).
- [ ] Crash v `debug` buildu jde do `debug` Firebase appky, ne do produkční.
- [ ] Isar databáze a SharedPreferences jsou oddělené (smazat `debug` data nezničí `prod` data).
- [ ] Health Connect funguje v obou flavors (po opětovném schválení permissions).

**Velikost:** ~2–3 dny (Android straightforward, iOS schemes + Apple setup je nejvíc neznámý faktor).

**Závislosti:** #108 (signing) má smysl udělat předtím, ať release config existuje na `prod` flavoru.

**Otevřené:**
- Třetí `staging` flavor pro betatestery někde mezi tím — *odložit*, řeší se až s reálnou potřebou pre-prod testů.
- CI/CD pipeline (TestFlight upload, Play Console upload) — *odložit* mimo MVP, manuální build do první beta vlny stačí.

---

### #70 — Crash reporting + feedback (Sentry)

**Cíl:** automatický sběr crashů + způsob, jak tester nahlásí bug s kontextem (screenshot, repro kroky).

**Vendor: Sentry** (rozhodnutí 2026-05-21, viz changelog níže). Plná capability: Crash + Performance + Session Replay + in-app User Feedback widget. ADR `sentry-crash-reporting` v [docs/site/data/decisions.json](../site/data/decisions.json) drží PROČ + uvažované alternativy (Crashlytics, Instabug). Volume risk free-tier (5k errors / 100k transactions / 50 replays měsíčně) je documented known-risk; sample rates jsou konzervativní (`tracesSampleRate: 0.2`, `replaysSessionSampleRate: 0.1`, `replaysOnErrorSampleRate: 1.0`).

**Architektura ([lib/core/sentry/](../../lib/core/sentry/)):**

- [`sentry_bootstrap.dart`](../../lib/core/sentry/sentry_bootstrap.dart) — three-gate init (`BuildConfig.isProd` + `--dart-define=SENTRY_DSN=<dsn>` + user consent). Když jakákoli gate selže, `SentryFlutter.init` se nikdy nezavolá a `SentryBreadcrumbSink` zůstane no-op. `setUserId(uid)` helper pro auth scope binding.
- [`sentry_consent_provider.dart`](../../lib/core/sentry/sentry_consent_provider.dart) — `ChangeNotifier` nad SharedPreferences (`sentry.collection_enabled` default `true`, `sentry.consent_seen` default `false`).
- [`sentry_consent_gate.dart`](../../lib/core/sentry/sentry_consent_gate.dart) — first-frame dialog na cold-startu pokud `!hasSeenDialog && SentryBootstrap.isAvailable`. Default pre-checked Allow; explicit "No thanks" flippne pref na false.
- [`sentry_pii_scrubber.dart`](../../lib/core/sentry/sentry_pii_scrubber.dart) — strict denylist (regex pro email-likes + 24+ char tokeny, klíče `email`/`password*`/`fcm_token`/`weight*`/`food*`/`kcal`/`cookie`/`session`).
- [`sentry_breadcrumb_sink.dart`](../../lib/core/sentry/sentry_breadcrumb_sink.dart) — interface, který `AppLog._emit` volá BEFORE `_shouldLog` gate. Default no-op; bootstrap nainstaluje real impl s whitelist `{AUTH, SYNC, KT, HEALTH}`.

**Implementace (shipped 2026-05-22):**

1. `sentry_flutter: ^9.20.0` + `sentry_dart_plugin: ^3.3.0` (pubspec wizard scaffold; ručně refactored aby splňovala plán).
2. [`lib/main.dart`](../../lib/main.dart) — `SentryBootstrap.init` gated na consent + `BuildConfig.isProd` + non-empty `SENTRY_DSN`. Wizard's hardcoded DSN + `kReleaseMode` gate + test log calls **odstraněny**. `appRunner` callback nastaví tagy (`flavor`, `app_version`) a nainstaluje breadcrumb sink. `SentryWidget` wrapping kolem `MultiProvider` zůstává (no-op když Sentry off).
3. `Selector<AuthProvider, String?>` pod `MultiProvider` v main.dart pushuje opaque `firebaseUid` do `SentryUser(id: …)` po postFrameCallback — strict PII: ŽÁDNÝ email / displayName / photoUrl.
4. [`lib/core/logging/app_log.dart`](../../lib/core/logging/app_log.dart) — `_emit` forwarduje do `SentryBreadcrumbSink.instance.add(...)` PŘED `_shouldLog` gate. V release módě AppLog skipuje terminal output, ale breadcrumby tečou dál. Cost v dev: jeden virtual dispatch do no-op.
5. PII scrubbing přes `options.sendDefaultPii = false`, `options.attachScreenshot = false`, `beforeSend` (`event.user = SentryUser(id: …)` + `event.request = null` + message scrub), `beforeBreadcrumb` (message + data scrub přes `SentryPiiScrubber`).
6. PII audit grep AppLog volání v `lib/features/auth/`, `lib/features/social/data/social_firebase_session.dart`, `lib/core/services/`, `lib/features/health_connect/`, `lib/features/nutrition/data/kaloricke_tabulky_service/` — žádný call v AUTH/SYNC/KT/HEALTH whitelistu neloguje email / KT credentials / weight / food / FCM token v message stringu. Strict scrubber je defense-in-depth.
7. Settings UI ([lib/features/settings/presentation/sections/settings_preferences_section.dart](../../lib/features/settings/presentation/sections/settings_preferences_section.dart)) — toggle `Crash reporting` v Preferences sekci. Když `SentryBootstrap.isAvailable == false` (dev / no-DSN build), toggle pořád funguje (uloží pref pro budoucí prod build) ale subtitle ukazuje „Available only in production builds" a restart-required snackbar se nepouští.
8. Feedback button ([lib/features/settings/presentation/sections/settings_static_sections.dart](../../lib/features/settings/presentation/sections/settings_static_sections.dart)) — `SettingsTile` „Send feedback" v About sekci volá `SentryFeedbackWidget.show(context)` (full-screen route s name/email/message + screenshot attachment). Na dev/no-DSN buildech místo toho fallback snackbar „Feedback is available only in production builds".
9. Devtools force-crash ([lib/features/devtools/presentation/sections/devtools_app_section.dart](../../lib/features/devtools/presentation/sections/devtools_app_section.dart)) — `DevToolsActionTile` „Force crash" + Sentry status tile (`reporting` / `disabled (opt-out)` / `off (dev / no DSN)`). Crash dispatch přes `Future<void>(() => throw StateError(...))` aby šel přes Flutter's onError hook, ne přes InkWell callback try/catch. Visible only via `DevToolsPermissionService.hasAccess(uid)` — dev flavor + UID allowlist v prod.

**Acceptance:**

- [x] Code path: Sentry init gate na `BuildConfig.isProd` + DSN + consent — všechny tři ověřené v [`sentry_bootstrap.dart`](../../lib/core/sentry/sentry_bootstrap.dart).
- [x] AppLog breadcrumb bridge pro AUTH/SYNC/KT/HEALTH (release-mode passthrough).
- [x] PII scrubber: `beforeSend` + `beforeBreadcrumb` + `sendDefaultPii: false`.
- [x] Custom tags (flavor, app_version) + user scope (opaque UID) hooked.
- [x] GDPR opt-in dialog: první start, default ON, persistovaný (`sentry.collection_enabled`).
- [x] Settings toggle pro pozdější změnu (s restart-required snackbar).
- [x] In-app feedback widget napojený na Settings → „Send feedback".
- [x] Devtools „Force crash" tlačítko (devtools-gated, ne mainstream prod UX).
- [x] **End-to-end verify (2026-05-22):** ověřeno přes `flutter run --flavor prod --dart-define=FLAVOR=prod --dart-define=SENTRY_DSN=<dsn>` v debug módu — force crash z devtools dorazil do Sentry dashboardu, appka pokračovala v běhu díky `runZonedGuarded` který Sentry instaluje kolem `appRunner`. Dev flavor paralelně ověřen — žádné events do Sentry (gate `BuildConfig.isProd` blokuje init). Full prod release APK acceptance ještě pending (release-mode signed APK → install na test device → force crash → dashboard verify).
- [ ] **Volume re-tune:** po prvním plném měsíci tester usage zkontrolovat free-tier consumption v Sentry dashboardu; pokud blízko limitu, snížit `tracesSampleRate` / `replaysSessionSampleRate` přes dashboard rate limits (no code change).

**Velikost:** ~1 den implementace (větší než plánovaný odhad ~1–2 dny pro Crashlytics, ale s plnou Performance + Replay capability + PII scrubber + GDPR flow).

**Závislosti:** #75 (`BuildConfig.flavor` jako primary gate) ✓ splněno.

---

## Tier 1 — UX a data integrita pro testery

### #97 — KT sync error banner eskalační kaskáda

**Cíl:** error banner v nutrition screenu místo neúčinného „Zkusit znovu" nabízí eskalační kaskádu: retry → silent relogin → forced sign-out s deep linkem do Settings.

**Aktuální stav:**
- Banner widget: [lib/features/nutrition/presentation/widgets/kt_sync_error_banner.dart](../../lib/features/nutrition/presentation/widgets/kt_sync_error_banner.dart)
- Současný retry callback: [lib/features/home/presentation/overview_screen.dart:740](../../lib/features/home/presentation/overview_screen.dart#L740) — `onRetry: () => kt.refreshRange(...)`. Jedna úroveň, žádná eskalace.
- KT session client: [lib/features/nutrition/data/kaloricke_tabulky_service/kt_session_client.dart:81](../../lib/features/nutrition/data/kaloricke_tabulky_service/kt_session_client.dart#L81) — `logout()` metoda existuje (čistí FlutterSecureStorage + invalidates cookies).
- Credentials: FlutterSecureStorage s MD5 hash hesla (`_ktEmailKey`, `_ktPasswordHashKey`).

**Kroky:**

1. **Klasifikovat error typy** v KT service:
   - `KtTransientError` (network down, 5xx) — retry má smysl.
   - `KtSessionExpiredError` (401, redirect na login page) — retry je marný, potřeba relogin.
   - `KtCredentialsInvalidError` (relogin selhal) — sign out + nasměrovat usera.
2. **`relogin()` metoda** v `KtSessionClient` — vezme uložené credentials z SecureStorage, zopakuje login flow, vrátí nový session cookie. Idempotentní; lze volat z error handleru.
3. **Banner state machine** — `KtBannerState` enum: `transientError` / `sessionExpiredRetrying` / `credentialsInvalid`. Banner UI mění text a primary action podle stavu.
4. **Eskalační kaskáda** v handleru:
   ```
   retry → success? done
         → fail (transient)? show transientError
         → fail (401)? trigger relogin
            relogin success? retry original request
            relogin fail? trigger logout() + show credentialsInvalid (link → Settings)
   ```
5. **Deep link do Settings KT sekce** — pravděpodobně už existuje route, ověřit ([lib/features/settings/](../../lib/features/settings/)).
6. **AppLog** pro každý krok kaskády — domain `kt-sync`, scope `escalation`. Užitečné pro Crashlytics breadcrumbs (viz #70).
7. **L10n** — nové ARB klíče pro tři banner stavy v [lib/l10n/app_en.arb](../../lib/l10n/app_en.arb) a [lib/l10n/app_cs.arb](../../lib/l10n/app_cs.arb), pak `flutter gen-l10n`.

**Acceptance:**
- [ ] Retry → silent relogin → sign-out s deep-linkem funguje jako řetěz.
- [ ] Tři rozlišené banner stavy s odlišným textem (l10n).
- [ ] AppLog pokrývá každý krok kaskády (retry / relogin attempt / forced sign-out).
- [ ] Tester s vypršelými KT cookies se dostane do funkčního stavu bez dev pomoci.

**Velikost:** ~1–2 dny.

**Závislosti:** žádné (může běžet paralelně s Tier 0). #70 z toho profituje (breadcrumbs).

---

### #79 — Persistence schema migration framework

**Cíl:** zachytit první stored-shape change, aniž by tester ztratil data.

**Aktuální stav:** žádný `schemaVersion` field na Isar collections. Žádný migration runner. Žádné Firestore wire codec versioning. Track B.3 v [docs/domain_model/archive/follow_ups.md](../domain_model/archive/follow_ups.md). Isar collections dnes: `CosmeticsUserStateRecord`, `CosmeticsUnlockRecord`, `HcStepsDayRecord`, `HcCalorieDayRecord`, `EngineObjectiveCompletionRecord`, `EngineNodeCompletionRecord`, `NutritionDayRecord` + další engine records.

**Pre-produkční pravidlo:** jakmile vyjde první beta build s persistentními daty (tj. tester očekává, že update appky mu nemaže progres), MUSÍ být schema versioning na svém místě. **První beta build (Sprint 1 exit) může jít ven bez něj**, ale s explicitní notou testerům „data v této verzi se můžou ztratit; jakmile vyjde verze 2, data se uchovají".

**Kroky (high-level — detailní design v samostatném docs/persistence/migrations_design.md, který vznikne během této karty):**

1. **Per-collection `schemaVersion: int = 1`** field — přidat na všechny Isar collection classes. Zachovat backward-readable shape (nullable nebo default).
2. **`MigrationRunner` per databáze** — při app boot načte stored `schemaVersion`, porovná s `currentVersion` v kódu, aplikuje migrations forward.
3. **Migration registry** — `Map<int, Migration>` per collection. Migration = funkce `(oldRecord) -> newRecord` nebo bulk operation.
4. **Failed migration strategy** — log + report do Crashlytics + soft-reset té jedné kolekce. NIKDY tichý fallback do prázdného stavu.
5. **Firestore wire codec versioning** — `__schema: 1` field v každém top-level Firestore dokumentu. Codec při deserializaci respektuje `__schema` a pouští odpovídající decoder.
6. **Idempotentní migrations** — opakované spuštění musí dát stejný výsledek (důležité pro Firestore — multiple devices mohou pustit migration paralelně).
7. **Test fixture** — golden data shape v1, test že `MigrationRunner` produkuje v2 shape, byte-by-byte porovnání.

**Otevřené (rozhodnout v samostatném design dokumentu):**
- Per-collection `schemaVersion` field vs. separate `_schema` collection.
- Migration runner timing: app boot (blocking) vs. lazy on first read.
- Failed migration rollback strategy.

**Acceptance:**
- [ ] Všechny existující Isar collections mají `schemaVersion: 1` (no-op migration baseline).
- [ ] `MigrationRunner` existuje, je volaný z app boot, loguje běh.
- [ ] Firestore root docs mají `__schema: 1` field.
- [ ] Test fixture pro v1 → v2 migration (umělá schema change) prochází.
- [ ] Design dokument `docs/persistence/migrations_design.md` existuje.

**Velikost:** ~1–2 týdny (~3–5 dní framework + ongoing daň per future migration).

**Závislosti:** žádné. Lze pustit kdykoli; raději dřív (před Sprint 2 exit), aby tester#1 build už v.2 dostal migraci, ne factory reset.

---

## Tier 2 — Sekundární kolo

Karty v tomto tier se aktivují **podle hlasité poptávky od testerů** ze Sprintu 1–2. Default pořadí níže reflektuje moji apriorní odhad, ale realita rozhodne.

### #110 — Cosmetics Firestore hybrid repo — **SHIPPED 2026-05-26**

**Cíl:** cosmetic ownership (unlocked set) a equipped slots syncovat napříč zařízeními. Tester na druhém zařízení nepřijde o získané cosmetics.

**Shipped (2026-05-26):**

- `HybridCosmeticsRepository` obaluje `IsarCosmeticsRepository` + `FirestoreCosmeticsGateway`.
- Wire layout pod `users/{uid}`: `cosmeticUnlocks/{cosmeticId}` (doc per unlock, idempotent set()) + `cosmeticState/state` (single doc s Loadout + selectedRaceId + updatedAt).
- Mutace: lokální write authoritativní, cloud push fire-and-forget; klasifikované error logging.
- První `loadForUser` per uid pulluje cloud + merguje (union unlocks earlier-unlockedAt vyhrává, loadout last-write-wins podle updatedAt).
- Factory reset wipuje obě nové subkolekce přes `FirestoreCosmeticsGateway.wipeAll(uid)`.
- API zůstalo Future-based — k stream-first absorpci #82 nedošlo (následoval samostatný shipping).

### #82 — Cosmetic entitlements realtime stream — **SHIPPED 2026-05-27**

**Shipped:** `FirestoreCosmeticEntitlementsSource.watchForUser(uid)` vrací `Stream<Result<List<CosmeticEntitlement>, AppError>>`. `CosmeticsProvider` subscribuje po dokončení `_load`, každá emise je authoritativní replacement set, nové unlocky jdou přes `service.unlock` (idempotent). Cloud-Function-pushed promo grant landne live bez restartu. `loadForUser` retained pro testy / one-shot reads. Stream errors → `Failure(classifyFirebaseError(...))` přes `StreamTransformer.fromHandlers` (žádný uncaught error na sinku). Trigger pro reálný use-case (Cloud Function píšící entitlements) zatím není postavený — současný stream emituje jen initial-load snapshot.

---

### #106 — Devtools Firestore `devUsers/{uid}` lookup — **SHIPPED 2026-05-27**

**Shipped:** `DevToolsPermissionService` přestaven ze static class na `ChangeNotifier`. Třívrstvý access check:

1. `BuildConfig.isDev` — vždy true v dev flavor.
2. Hardcoded UID allowlist — offline fallback baked do prod buildu.
3. Firestore `devUsers/{uid}.enabled == true` — runtime grant, bind na auth uid kickne async refresh.

Cache v SharedPreferences (`devtools_remote_granted_uid` + `devtools_remote_granted_checked_at_ms`) přežívá restart — udělený dev otevře offline DevTools i po reboot. ChangeNotifier emituje, když Firestore vrátí změnu, takže Settings entry tile se objeví bez restartu appky. Service je nasazen ve čtyřech call sites přes `context.watch<DevToolsPermissionService>()`.

**Bonus:** „Access via" status tile v DevTools nyní rozlišuje `UID allowlist` vs `devUsers/{uid} (Firestore)`, takže je vidět, jak konkrétní uid přistupuje.

**Nezbývá:** Firestore Security Rules pro `devUsers/{uid}` zatím nejsou ve `firestore.rules` (read jen vlastník, write deny pro klienta). Bez nich může klient sám psát do své `devUsers/{uid}` doc — tj. udělit si dev access. Sepsat rules + deploy. Nutné PŘED prod releasem.

**Cesta dál:** s `devUsers` v rules jako auth-fence můžeš v Tier 2 #82 (a budoucích admin callable funkcích) použít `request.auth != null && get(/databases/.../devUsers/$(request.auth.uid)).data.enabled == true` jako jednotný `isAdmin()` check.

---

### #73 — RPG mode toggle

**Cíl:** jeden setting flippne mezi „full RPG experience" a „čistý fitness tracking". Tester, kterého neoslovují relics/companions/narrative chapters, dostane uklizenější aplikaci.

**Aktuální stav:** spec ready v [docs/progression_engine/rpg_mode_readiness.md](../progression_engine/rpg_mode_readiness.md). Engine podporuje `ActivationPolicy` a `ContentTag` axes, ale UI toggle + idempotent backfill ještě nestaví. Detailní acceptance v spec dokumentu.

**Kroky:** viz spec. Hrubě:
1. Engine respektuje `ActivationPolicy.onlyWhenRpgEnabled` při evaluaci.
2. Display layer filtruje podle `ContentTag` + aktuálního RPG settingu.
3. Idempotentní backfill při re-enable.
4. Settings flag (boolean) → UserSetting persistovaný (viz Config systém, [Trello #60](https://trello.com/c/m0241Xee)).
5. UI toggle v Settings.

**Velikost:** ~1 týden (engine + display + backfill + UI).

**Závislosti:** žádné nutné. Pokud Config systém #60 ještě nestojí, RPG flag persistovat naparam přímo do SharedPreferences (later migrate to UserSettings).

---

### #74 — Light theme

**Cíl:** příjemnější UX pro testery, co preferují light mode (a iOS users, kde light = default systému).

**Aktuální stav:** app je dark-first. Material theming částečně připravený, ale konkrétní assety jsou kreslené pod tmavé pozadí.

**Scope dle popisu karty:** color tokens + light variants assetů + theme switcher (System/Light/Dark) v Settings. Asset work je největší část — pravděpodobně mimo Sprint 3.

**Doporučení:** **odložit za feedback**. Pokud testeři výslovně poptají light mode, aktivovat; jinak prioritizovat reálné UX bugy z #70 reportů.

**Velikost:** ~2 týdny pokud full asset set, ~3–5 dní pokud jen klíčové obrazovky.

**Závislosti:** žádné.

---

## Tier 3 — Mimo scope pre-beta

**Trigger-driven karty** zůstávají v sloupci Refactoring. Reaktivovat pouze při splnění explicitního triggeru:

- [#81](https://trello.com/c/XFB7JmCA) Provider rebuild granularity — trigger: observable UI jank.
- ~~[#82](https://trello.com/c/9gxWrE5D) Cosmetic entitlements realtime stream~~ — **SHIPPED 2026-05-27** jako samostatná karta po #110. Stream API hotové, čeká už jen na Cloud Function side.
- [#83](https://trello.com/c/2xqdGBBz) Firestore codec strict mode — trigger: external writer do engine collections.
- [#84](https://trello.com/c/G205Ct56) BackgroundSync exponential backoff — trigger: user-visible sync degradation.

**Feature work, který se ladí reálným feedbackem:**

- [#6](https://trello.com/b/du34lNAt) AI vypravěč, [#39](https://trello.com/b/du34lNAt) Training log AI parser, [#62](https://trello.com/c/9EenWsS9) Weekly quests, [#46](https://trello.com/b/du34lNAt) Fog of war, [#63](https://trello.com/b/du34lNAt) Chapter accent colors, [#48](https://trello.com/b/du34lNAt) first login marker, [#114](https://trello.com/b/du34lNAt) companion_collector — odložit, dokud testeři nepoptají.

**Velké iniciativy mimo MVP beta scope:**

- [#2](https://trello.com/b/du34lNAt) iOS TestFlight — po stabilní Android iteraci.
- [#3](https://trello.com/b/du34lNAt) Admin dashboard — až existují data k zobrazení.
- [#26](https://trello.com/b/du34lNAt) Groups coach↔client, [#72](https://trello.com/b/du34lNAt) Dungeons — velký scope.
- [#78](https://trello.com/b/du34lNAt) Cloud-hosted catalogs (~1–2 měsíce) — overengineering před produktovou validací.
- [#80](https://trello.com/b/du34lNAt) V2 background push notifications — nice-to-have.

**Refactoring, co počká na post-feedback fázi:**

- [#60](https://trello.com/c/m0241Xee) Config systém — *velký initiative*, vyžaduje samostatnou diskuzi. `BuildConfig` z #75 staví začátek (build-time layer); UserSettings + AdminConfig přijdou potom.
- [#67](https://trello.com/c/O40BhKfH) Chapters split + rebalance, [#85](https://trello.com/c/GWo7wZqJ) UI refactor 1000+ LoC screeny, [#103](https://trello.com/c/sF9VO2b4) Journey ledger, [#104](https://trello.com/c/aQoYrQZr) Domain export concerns, [#111](https://trello.com/c/wWMo0Zss) integration testy, [#102](https://trello.com/c/ftr3yfN4) devtools l10n.

## Exit kritéria pro beta release

**Sprint 1 exit** (= první beta build pro 5–10 testerů):
- Prod flavor build podepsaný produkčním klíčem (#108 + #75).
- Crashlytics propojený, dashboard zobrazuje crash do 5 min (#70).
- Feedback flow funguje (e-mail s pre-fillem nebo lepší).
- Testeři dostanou explicit notu „data v této verzi nejsou trvalá, build #2 přinese persistenci".

**Sprint 2 exit** (= druhý beta build, persistent data):
- KT banner kaskáda funguje pro vypršené cookies (#97).
- Schema versioning framework existuje, baseline `schemaVersion: 1` na všech collections (#79).
- Plán pro upcoming schema change (pokud nějaký je) má sepsanou migration.

**Sprint 3 trigger** (= druhá beta vlna na základě feedbacku):
- Reálné UX/bug nahlášky od testerů uzavřené.
- Tier 2 karty aktivované podle hlasité poptávky.

## Změny v této verzi plánu

- **2026-05-21**: První verze. 9 karet v Probíhá. Karty #82, #83 vráceny do Refactoring jako trigger-driven (viz dodatek-komentáře na kartách).
- **2026-05-21**: #108 shipped — release signing wired v [android/app/build.gradle.kts](../../android/app/build.gradle.kts) (Properties loader + `signingConfigs.release` s graceful fallback na debug pro fresh checkouts bez `key.properties`). APK podepsán prod cert (RSA 2048, V2 scheme); fingerprinty předány uživateli k offline uložení.
- **2026-05-21**: #70 vendor rozhodnutí — **Sentry** (ne Crashlytics jak default v sekci #70 počítal). Důvod: lepší DX (issue grouping, performance traces). ADR doplnit při startu #70 ticketu; sekce #70 v tomto dokumentu se přepíše tehdy.
- **2026-05-21**: #108 follow-up — release cert SHA-1 (`639146796b…`) + SHA-256 (`fc12d160…`) doregistrované na produkční Firebase app `1:798278342104:android:a44ecd497db4f28161cead` přes Firebase MCP. Bez toho by Google Sign-In testerům na release buildu nepoběžel.
- **2026-05-21**: #75 shipped — Android product flavors `dev` / `prod` ([android/app/build.gradle.kts](../../android/app/build.gradle.kts)), nová Firebase app `Forgetrack DEV` (`1:798278342104:android:9a16491e8d45918b61cead`, package `com.knejp.forgetrack.dev`) v projektu `forgetracker-493415`, sjednocený `google-services.json` s oběma `client` bloky, `lib/core/build_config.dart` runtime gate, `DevToolsPermissionService` přepnut z `kDebugMode` na `BuildConfig.isDev`, dev launcher ikona dostává oranžové pozadí přes `src/dev/res/values/colors.xml`, manifest swap `android:label="@string/app_name"`. iOS flavor scaffolding odloženo do Trello #2. Ověřeno: `flutter build apk --release --flavor prod` produkuje `app-prod-release.apk` podepsaný stále prod certem; `flutter build apk --debug --flavor dev` produkuje dev APK. ADR `android-flavor-split-dev-prod` v [docs/site/data/decisions.json](../site/data/decisions.json).
- **2026-05-22**: #70 implementace shipped — Sentry Flutter 9.20.0 + `sentry_dart_plugin` 3.3.0. Wizard scaffold (hardcoded DSN + `kReleaseMode` gate + test log calls) přepsán: DSN přes `--dart-define=SENTRY_DSN=<dsn>`, three-gate init (`BuildConfig.isProd` + DSN + consent) v [`lib/core/sentry/sentry_bootstrap.dart`](../../lib/core/sentry/sentry_bootstrap.dart). Sample rates: traces 0.2, replay 0.1 session / 1.0 onError. Strict PII scrubber ([`sentry_pii_scrubber.dart`](../../lib/core/sentry/sentry_pii_scrubber.dart)) + `sendDefaultPii: false` + `event.user = SentryUser(id: …)` v `beforeSend`. AppLog ↔ Sentry breadcrumb bridge přes `SentryBreadcrumbSink` (whitelist AUTH/SYNC/KT/HEALTH; release-mode passthrough před `_shouldLog` gate). GDPR opt-in dialog (`SentryConsentGate` wrapping `MaterialApp.home`, default ON) + Settings toggle + Send feedback widget (`SentryFeedbackWidget.show`) + devtools force-crash. ADR `sentry-crash-reporting` v [docs/site/data/decisions.json](../site/data/decisions.json). Open: end-to-end verify v Sentry dashboardu (user-side prod build + force crash) + volume re-tune po prvním měsíci tester usage.
