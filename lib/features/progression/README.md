# Progression Engine (legacy)

> **Status:** this is the legacy progression module. A V2 engine is being
> built in parallel at [`lib/features/progression_engine/`](../progression_engine/),
> tracked in [docs/progression_engine/](../../../docs/progression_engine/).
> The legacy module stays here as the production source of truth until
> Phase 9 of the V2 plan, then is deleted entirely.

Progression Engine deterministicky vyhodnocuje fitness a nutrition data,
vytvari auditovatelny ledger evaluaci, claimnutych XP rewardu a achievement
unlocku, a synchronizuje dulezite ledger udalosti do Firestore.

Zakladni princip:

- evaluation/completion = prepocitatelny stav podle aktualnich dat
- claim/grant = historicka XP udalost
- achievement unlock = historicka non-XP udalost
- XP/level = odvozeny pouze z claimnutych rewardu
- Firestore = cloud source of truth pro claimy a achievement unlocky
- Isar = lokalni cache + lokalni persistence pro rychle UI/offline rezim

Raw health/nutrition data se do Firestore neukladaji.

---

## Goal

Feature ma byt:

- deterministicka
- auditovatelna
- idempotentni
- oddelena od UI logiky
- funkcni offline
- bezpecna proti duplicitnimu claimovani
- obnovitelna po reinstallu / smazani app dat / novem telefonu
- pripravena pro social/leaderboard features bez nutnosti menit core engine

Aktualne neresi AI cast. AI vrstva se muze pozdeji napojit pres novy source,
novy rule catalog nebo generator questu, aniz by menila reward ledger.

---

## Current Implementation

Aktualni implementace obsahuje:

- XP a level policy
- reward rule catalog pro daily a weekly cile
- deterministic goal evaluator
- evaluation status a miss reason metadata
- persistent evaluation ledger v Isaru
- persistent reward grant ledger v Isaru
- persistent quest reward grant ledger v Isaru
- persistent achievement unlock ledger v Isaru
- claim-time XP finalizaci pres `finalXp`
- level scaling pocitany az v okamziku claimu
- historicke XP zobrazovane pres `effectiveXpGranted`
- derived streak summaries from evaluation history
- derived achievements s persistentnim unlock stavem
- long-tail achievement milestones pro XP, rewards, steps a streaks
- static derived quests from reward, XP, achievement and streak history
- quest categories, prerequisites and deterministic highlighted quest set
- persistent active quest set pro stable mission board across refreshes
- idempotentni reward claim pres persistentni `rewardKey`
- idempotentni achievement unlock pres persistentni `unlockKey`
- repository + Isar persistence
- Firestore mapper + gateway
- HybridProgressionRepository pro local-first + cloud sync
- migraci lokalniho ledgeru do Firestore po loginu
- Firestore summary document `users/{uid}/progression/state`
- provider napojeni do UI

Aktualni reward rules zahrnuji mimo jine:

- daily `steps`
- daily `calories`
- daily `protein`
- daily `sleep`
- daily `weight log`
- daily `weight goal`
- weekly `activity minutes`

---

## Feature Structure

- `domain/`
  - ciste modely
  - rule definitions
  - quest definitions
  - achievement definitions
  - evaluators
  - level policy
  - repository contracts

- `application/`
  - orchestrace sync/evaluation/claim flow
  - progression engine
  - source contracts
  - provider pro UI state

- `data/`
  - local Isar repository implementation
  - Firestore gateway + mapper
  - hybrid repository
  - persistence mapping
  - provider-backed source adapter

- `presentation/`
  - progression screen
  - home card
  - UI widgets
  - display helpers / localized labels

---

## Core Concepts

### Evaluation

`ProgressionEvaluation` rika, co bylo podle aktualnich dat splneno nebo nesplneno
pro konkretni pravidlo a periodu.

Evaluation je prepocitatelna. Muze se zmenit, pokud se zmeni Health Connect data,
nutrition data, user goals nebo evaluator logic.

Evaluation sama o sobe nikdy nepridava XP.

### Reward Grant / Claim

Reward grant reprezentuje claimable nebo claimed XP reward pro konkretni pravidlo
a periodu.

Reward ma lifecycle:

1. `evaluation achieved = true`
2. vytvori se claimable grant, pokud jeste neexistuje
3. user klikne claim
4. engine spocita `finalXp` podle aktualniho levelu
5. grant se oznaci jako claimed
6. XP/level se odvozuje pouze z claimed grants

Unclaimed grant nikdy nezvysuje XP ani level.

### Achievement Unlock

Achievement unlock je persistentni non-XP udalost.

Achievementy nedavaji XP. Pokud se achievement jednou unlockne, zapise se
`ProgressionAchievementUnlockEvent` / `ProgressionAchievementUnlockRecord`.
Pri dalsim syncu se uz nepocita znovu jako novy unlock, ale pouzije se ulozeny
`unlockedAt`.

### Profile

`ProgressionProfile` je derived read model.

Source of truth neni ulozeny profile, ale soucet claimnutych rewardu:

```text
totalXp = sum(ruleReward.effectiveXpGranted)
        + sum(questReward.effectiveXpGranted)
```

`level`, `rank`, `xpIntoCurrentLevel` a `xpForNextLevel` se pocitaji z `totalXp`.

---

## Data Flow

1. `ProgressionSource` doda snapshoty a user goals.
2. `ProgressionRuleCatalog` vytvori aktivni reward rules.
3. `ProgressionEngine` deterministicky seradi rules i snapshoty.
4. `ProgressionEvaluator` vyhodnoti kazde pravidlo nad relevantnimi periodami.
5. `ProgressionRepository.persistEvaluations()` ulozi evaluation records.
6. Repository vytvori claimable reward grant pouze pokud pro dany `rewardKey`
   jeste neexistuje grant.
7. Engine vyhodnoti achievement candidates.
8. Repository ulozi nove achievement unlocky pouze pokud pro dany `unlockKey`
   jeste neexistuji.
9. `ProgressionProvider` vystavi profile, goals, quests, achievements a claimable
   rewards pro UI.
10. User claimne reward.
11. Engine spocita `finalXp` podle aktualniho claimed-XP levelu.
12. Repository oznaci reward jako claimed a ulozi claim-time metadata.
13. Hybrid repository zapise claimed reward / achievement unlock do Firestore,
   pokud je user prihlaseny.
14. Firestore summary document se best-effort aktualizuje.

---

## Source Of Truth

### Local source of truth

V lokalnim rezimu je source of truth Isar ledger:

- `ProgressionEvaluationRecord`
- `ProgressionRewardGrantRecord`
- `ProgressionQuestRewardGrantRecord`
- `ProgressionAchievementUnlockRecord`
- `ProgressionActiveQuestRecord`

### Cloud source of truth

Po loginu je Firestore source of truth pro udalosti, ktere musi prezit reinstall
nebo novy telefon:

```text
users/{uid}/progressionClaims/{rewardKey}
users/{uid}/achievementUnlocks/{achievementId}
```

Firestore uklada pouze:

- claimed rule rewards
- claimed quest rewards
- achievement unlocks
- derived summary cache

Firestore neuklada:

- raw Health Connect data
- nutrition logs
- evaluation records
- active quest set
- unclaimed rewards

---

## Firestore Layout

### Claimed rewards

```text
users/{uid}/progressionClaims/{rewardKey}
```

Dokument obsahuje napr.:

- `rewardKey`
- `type` = `rule` nebo `quest`
- `ruleId`
- `questId`
- `ruleVersion`
- `domainName`
- `periodKindName`
- `periodStart`
- `baseXp`
- `finalXp`
- `levelAtClaim`
- `multiplierAtClaim`
- `rewardStatusName = claimed`
- `unlockedAt`
- `claimedAt`
- `createdAt`

`finalXp` je povinne pro cloud zapis.

Pro legacy lokalni claimed record, kde `finalXp == null`, se pri uploadu pouzije:

```text
finalXpForFirestore = finalXp ?? xpGranted
```

### Achievement unlocks

```text
users/{uid}/achievementUnlocks/{achievementId}
```

Dokument obsahuje:

- `achievementId`
- `unlockKey`
- `unlockedAt`
- `createdAt`

### Derived summary

```text
users/{uid}/progression/state
```

Dokument obsahuje:

- `totalXp`
- `level`
- `claimCount`
- `achievementCount`
- `lastSyncedAt`

Tento document je pouze cache pro rychle zobrazeni / social / leaderboard.
Neni source of truth.

---

## Local-first Cloud Sync

Aplikace pouziva `HybridProgressionRepository`.

Hybrid repository obaluje:

- `LocalProgressionRepository` / Isar
- `ProgressionCloudGateway` / Firestore

Chovani:

- vsechny ready jsou z Isaru
- `loadLedger()` vraci lokalni snapshot okamzite
- Firestore pull/hydrate bezi na pozadi
- claim se nejdriv zapise do Isaru
- Firestore write je fire-and-forget
- Firestore chyba nesmi rozbit lokalni claim
- logged-out user funguje ciste lokalne
- pokud Firebase neni dostupny, app pouzije lokalni repository

### Login / migration

Po loginu se spusti migrace lokalniho progression ledgeru do Firestore.

Migrace:

- bezi jednou per canonical uid
- stav je ulozen v SharedPreferences pod klicem typu:

```text
progression_migrated_{uid}
```

Uploaduje:

- claimed rule rewards
- claimed quest rewards
- achievement unlocks

Neuploaduje:

- unclaimed rewards
- evaluations
- active quest set
- raw health/nutrition data

Migrace je idempotentni. Pokud selze, neoznaci se jako dokoncena a muze se
zkusit znovu.

### New phone / reinstall

Po reinstallu nebo na novem telefonu:

1. User se prihlasi.
2. Hybrid repository stahne Firestore `progressionClaims` a `achievementUnlocks`.
3. Claimy a unlocky se hydratuji do Isaru.
4. Engine znovu prepocita evaluations z dostupnych health/nutrition dat.
5. Pokud rewardKey / unlockKey uz existuje, nevznikne duplicitni claim/unlock.
6. XP/level se obnovi ze stazenych claimed rewards.

---

## Idempotence

### Reward idempotence

Reward idempotence je zajistena pres `rewardKey`.

Format pro rule reward:

```text
ruleId + ruleVersion + periodKind + periodAnchor + rewardSuffix
```

Priklad:

```text
daily_steps|2026-04-defaults-v1|day|2026-04-27|reward
```

Quest reward:

```text
quest|{questId}|reward
quest|{questId}|{dateKey}|reward
```

Dusledek:

- stejny reward se nepripise dvakrat pri refreshi
- stejny reward se nepripise dvakrat pri resyncu
- stejny reward se nepripise dvakrat po Firestore restore
- opakovane vyhodnoceni stejneho dne nebo tydne je bezpecne

### Achievement idempotence

Achievement unlock idempotence je zajistena pres `unlockKey`.

Format:

```text
achievement|{achievementId}
```

Achievement se unlockne pouze jednou.

### Firestore idempotence

Firestore zapisy pouzivaji create-if-not-exists semantiku:

1. transaction read
2. pokud dokument existuje, skip
3. pokud neexistuje, create

Server-side pravidla by mela povolit create, ale blokovat update/delete pro claimy
a achievement unlocky.

---

## XP Semantics

### Fields

Reward grant muze obsahovat:

- `xpGranted`
  - legacy / evaluation-time hodnota
  - zustava kvuli kompatibilite a fallbacku

- `finalXp`
  - skutecne pripsane XP v okamziku claimu
  - nullable pro unclaimed nebo legacy zaznamy

- `effectiveXpGranted`
  - jedina hodnota, ktera se smi pocitat do XP/levelu

```text
effectiveXpGranted = isClaimed ? (finalXp ?? xpGranted) : 0
```

- `levelAtClaim`
  - level v okamziku claimu

- `multiplierAtClaim`
  - level multiplier v okamziku claimu

### Display rules

UI by melo pouzivat:

- claimed history:
  - `effectiveXpGranted`

- claimed quest reward:
  - `effectiveXpGranted`

- unclaimed / pending reward:
  - current-level preview z `baseXp` / rule base XP

- locked / future quest:
  - current-level preview, pokud je dostupny

Past claimed rewards se nesmi retroaktivne menit pri dalsim levelupu.

### Claim all

`claimAllRewards()` claimuje rewardy sekvencne.

Pokud user behem claim-all batchu leveluje, dalsi rewardy v batchi mohou dostat
vyssi `finalXp`. To je zamerne RPG chovani.

---

## Defaults In Current Version

- tyden zacina v pondeli
- kaloricky cil pouziva toleranci `+-10 %`
- weight goals jsou soucasti rule catalogu:
  - `daily_weight_log`
  - `daily_weight_goal`
- `daily_weight_goal` ma vyssi XP hodnotu, protoze reprezentuje dlouhodobejsi cil
- level policy pouziva rostouci XP curve a reward scaling
- rank ladder je rozsireny pro dlouhodoby progress az na `100+` levels

Known product nuance:

- pokud je enumerace dni rizena jen nekterymi metric sources, muze den s vahou
  bez kroku chybet v evaluaci
- pokud user nema realisticky nastaveny `targetWeightKg`, `daily_weight_goal`
  muze dlouhodobe missovat
- weight goals nemusi byt zapocitane do vsech combo questu

---

## Auditability

Kazda evaluation uklada:

- `evaluationKey`
- `rewardKey`
- `ruleId`
- `ruleVersion`
- `period`
- `actualValue`
- `targetValue`
- `progress`
- `achieved`
- `status`
- `missReason`
- `explanation`
- `evaluatedAt`

Kazdy reward grant uklada:

- `rewardKey`
- `ruleId`
- `ruleVersion`
- `period`
- `xpGranted`
- `finalXp`
- `levelAtClaim`
- `multiplierAtClaim`
- `claimedAt`
- `rewardStatus`
- `userId`
- `sourceDeviceId`

Kazdy achievement unlock uklada:

- `unlockKey`
- `achievementId`
- `unlockedAt`
- `userId`

---

## Quest Model

Quest system je derived z evaluation/reward/achievement/streak historie, ale rewardy
za questy maji vlastni persistentni claim ledger.

Quest categories:

- `journey`
- `daily`
- `daily combo`
- `weekly`
- `chain`

Quest states:

- `locked`
- `available`
- `active`
- `completed`
- `claimed`

Quest system podporuje:

- prerequisites
- level gates
- time gates
- persistent active mission board
- deterministic doplnovani volnych slotu
- daily questy vyhodnocene podle aktualni relevantni periody
- lifetime milestone questy podle kumulativni historie
- quest reward claim pres persistentni `rewardKey`

Default rozhodnuti:

- aktivni set se perzistuje a drzi se stabilni mezi syncy, pokud quest zustava validni
- sloty se doplnuji deterministicky podle category, priority, progress a sort order
- default slot caps:
  - `1x chain`
  - `1x weekly`
  - `1x daily`
  - `2x journey`
- prerequisites se vyhodnocuji jen proti jiz zpracovanym questum v katalogovem poradi
- quest completion timestamp se nikdy nevymysli synteticky mimo ledger nebo prerequisite flow

---

## Repository Implementations

### LocalProgressionRepository

Isar-backed local implementation.

Odpovida za:

- persist evaluations
- persist claimable reward grants
- claim rewards
- claim quest rewards
- persist achievement unlocks
- restore cloud claims/unlocks do Isaru
- load local ledger

### FirestoreProgressionGateway

Cloud gateway pro Firestore.

Odpovida za:

- upload claimed rule rewards
- upload claimed quest rewards
- upload achievement unlocks
- pull progression claims
- pull achievement unlocks
- migrate local ledger
- update progression summary document

### HybridProgressionRepository

Production repository wrapper.

Odpovida za:

- local-first reads
- local-first writes
- fire-and-forget Firestore writes
- background Firestore pull/hydrate
- migration trigger po loginu
- fallback na local-only chovani pri logoutu nebo Firebase failure

---

## Extension Points

Bez zmeny zakladni architektury lze doplnit:

- dalsi comparators a threshold typy
- nove daily/weekly/monthly rules
- nove quest categories
- nove achievement definitions
- richer player progression summary
- social/leaderboard views
- admin/debug dashboards
- Cloud Functions pro server-side validation
- AI quest generator
- alternativni source adapters
- retroactive claim policy

---

## Current Boundaries

Feature zatim vedome nedela:

- server-side validaci Health Connect dat
- ukladani raw health/nutrition dat do cloudu
- Cloud Functions claim endpoint
- hard anti-cheat
- retroactive claim cutoff
- plne product-balanced weight goal redesign
- full emulator E2E test suite
- automaticke reseni vsech edge casu pri chybejicich metric days

To je vedomy scope cut.

Core ledger engine uz ale podporuje:

- lokalni claim persistence
- claim-time XP
- achievement unlock persistence
- Firestore cloud persistence
- migraci lokalniho ledgeru
- restore po reinstallu / novem telefonu
- derived progression summary pro social/admin/leaderboard
