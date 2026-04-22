# Progression Engine

Progression Engine deterministicky vyhodnocuje cile nad fitness a nutrition daty,
uklada auditovatelny ledger evaluaci a idempotentne grantuje XP rewardy.

## Goal

Feature ma byt:

- deterministicka
- auditovatelna
- idempotentni
- oddelena od UI logiky
- pripravena na budouci rozsireni bez rozbiti persistence a provider flow

Aktualne neresi AI cast. AI vrstva se muze pozdeji napojit pres novy source,
novy rule catalog nebo generator questu, aniz by menila reward ledger.

## Current Implementation

Aktualni implementace obsahuje:

- XP a level policy
- reward rule catalog pro daily a weekly cile
- deterministic goal evaluator
- evaluation status a miss reason metadata
- derived streak summaries from evaluation history
- derived achievements from reward, XP and streak history
- long-tail achievement milestones for XP, rewards, steps and streaks
- static derived quests from reward, XP, achievement and streak history
- quest categories, prerequisites and deterministic highlighted quest set
- persistent active quest set for a stable mission board across refreshes
- idempotentni reward grantovani pres persistentni reward key
- repository + Isar persistence
- provider napojeni do UI

Aktualni reward rules:

- daily `steps`
- daily `calories`
- daily `protein`
- daily `sleep`
- weekly `activity minutes`

## Feature Structure

- `domain/`
  - ciste modely
  - rule definitions
  - evaluator
  - level policy
- `application/`
  - orchestrace sync/evaluation flow
  - source contracts
- `data/`
  - repository implementation
  - persistence mapping
  - provider-backed source adapter
- `presentation/`
  - provider pro UI

## Data Flow

1. `ProgressionSource` doda snapshoty a goals.
2. `ProgressionRuleCatalog` vytvori aktivni reward rules.
3. `ProgressionEngine` deterministicky seradi rules i snapshoty.
4. `ProgressionEvaluator` vyhodnoti kazde pravidlo nad kazdym relevantnim obdobim.
5. `ProgressionRepository` ulozi evaluation records.
6. Repository grantne reward jen pokud pro dany `rewardKey` jeste neexistuje grant.
7. `ProgressionProvider` nacte ledger a vystavi XP/level summary pro UI.

## Source Of Truth

Source of truth pro progression stav je reward + evaluation ledger v repository.

- `ProgressionEvaluation` uklada vysledek vyhodnoceni pravidla pro konkretni periodu
- `ProgressionRewardGrant` uklada skutecne pripsany reward
- `ProgressionProfile` se dopocteva z reward grants, neuklada se separatne
- streak summaries se dopoctavaji z evaluation history, neukladaji se separatne
- achievements se dopoctavaji z reward grants, XP a streaks, neukladaji se separatne
- quests se dopoctavaji z reward grants, XP, achievements a streaks, neukladaji se separatne
- active quest set se uklada separatne, ale stale se opira o reward/evaluation ledger
- quest activation a highlight se po reloadu odvodi z persisted active quest setu

Tento model drzi auditovatelnost i jednoduchost:

- evaluace rika "co bylo vyhodnoceno"
- reward grant rika "co bylo opravdu pripsano"

## Idempotence

Idempotence rewardu je zajistena pres `rewardKey`.

Format je:

- `rule id + rule version + period kind + period anchor + reward suffix`

Dusledek:

- stejny reward se nepripise dvakrat pri refreshi
- stejny reward se nepripise dvakrat pri resyncu
- opakovane vyhodnoceni stejneho dne nebo tydne je bezpecne

Repository pri persistenci:

- vzdy updatne evaluation record
- reward grant vytvori pouze pokud dany `rewardKey` jeste neexistuje

## Defaults In V1

- tyden zacina v pondeli
- kaloricky cil pouziva toleranci `+-10 %`
- weight zatim neni soucast reward rule katalogu
- level policy pouziva rostouci XP curve:
- base `250 XP`
- `+50 XP` linear growth per level
- `+5 XP * (level offset)^2` quadratic growth component
- rank ladder je rozsireny pro dlouhodoby progress az na `100+` levels

Weight je zatim mimo reward engine zamerne. Bez presne produktove definice by
denni nebo tydenni reward za weight mohl byt nepresny nebo zavadejici.

## Auditability

Kazda evaluace uklada:

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
- `grantedAt`

## Extension Points

Bez zmeny zakladni architektury lze doplnit:

- dalsi comparators a threshold typy
- reward scaling misto fixniho XP
- streak rules
- achievements
- quest system
- richer player progression summary
- alternativni source adapters

## Quest Model V2

Quest system je zatim stale derived-only, ale uz ma prvni vylepsenou strukturu:

- `journey` questy pro dlouhodobe milestone cile
- `daily` questy pro aktualni den, vyhodnocene podle posledni relevantni periody
- `daily combo` questy pro vice soucasne splnenych cilu v jednom dni
- `weekly` questy pro periodicke mastery cile
- `chain` questy pro navazujici progression flow
- `locked` stav pro questy s prerequisites
- `locked` stav i pro questy gated levelem nebo casem
- `available` stav pro odemcene questy mimo aktivni set
- `active` stav jen pro questy zarazene v aktivnim mission boardu
- `completed` stav pro splnene questy
- perzistentni aktivni mission board s deterministickym doplnovanim volnych slotu
- daily quest splnuje jen posledni relevantni den pro dane pravidlo, ne historicky soucet
- lifetime milestone questy a achievementy se opiraji o kumulativni hodnoty z evaluation history
- tezsi questy se mohou odemknout az od urciteho levelu nebo po urcitem poctu kalendarnich dni od prvniho trackovaneho dne

Default rozhodnuti v teto fazi:

- aktivni set se perzistuje a drzi se stabilni mezi syncy, pokud quest zustava validni
- sloty se doplnuji deterministicky podle category, priority, progress a sort order
- default slot caps:
- `1x chain`
- `1x weekly`
- `1x daily`
- `2x journey`
- prerequisites se vyhodnocuji jen proti jiz zpracovanym questum v katalogovem poradi
- quest completion timestamp se nikdy nevymysli synteticky mimo ledger nebo prerequisite flow

## Current Boundaries

Feature zatim nedela:

- complex reward multipliers
- persistovane quest completion eventy
- persistovane achievement unlock eventy
- retroaktivni migrace rules mezi verzemi

To je vedomy scope cut pro prvni stabilni verzi engine.
