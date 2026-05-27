# Raids — Plan

Měsíční time-boxed event, hráči si tvoří malé party, plní společný cíl,
dostanou odměnu. Standalone feature postavená nad [Guilds](../guilds/plan.md)
infrastrukturou.

**Status:** plánováno, near-term (start po dalším releasu, po G.0–G.3 fázích
Guilds). Raidy jsou primární driver Guilds infrastruktury — pokud se rozjedou
samy, validují celou základnu pro pozdější [Coaching](../coaching/rough_plan.md).

---

## Proč raidy jako první konzument

- **Nízké riziko** — žádná privátní data (jen agregovaná metrika), žádná
  legal/GDPR komplikace.
- **Time-boxed** — chyba v MVP se sama vyresetuje na konci měsíce.
- **Zábavná feature** — gamifikace, retence, samo se "prodá" hráčům.
- **Validuje Guilds** — pokud group/invite/sharing infrastruktura unese
  raid, unese i coaching.

---

## Produktový princip

- Každý měsíc se globálně odemkne **jeden raid** s tématem, cílem a odměnou.
- Hráči si tvoří **malou party** (3–10 členů, finální číslo TBD) nebo se
  připojí k existující.
- Party plní jeden společný **agregovaný cíl** za měsíc (např. 1 000 000 kroků,
  300 splněných questů, 1 000 km).
- Při splnění → všichni členové dostanou stejnou **odměnu** (kosmetika,
  banner, frame, title — existující cosmetic flow).
- Po konci měsíce party zaniká (status `expired`), nové se tvoří pro
  další raid.

---

## Datový model

Nad existující `groups/` (type `raid_party`). Specifické subkolekce:

```
raidEvents/{raidEventId}             // globální definice raidu
  month              '2026-06'
  theme              'Dungeon of Iron'
  objective: {
    metric           'steps' | 'completedQuests' | 'distanceKm' | …
    target           1000000
    aggregation      'sum'   // později možná 'min', 'max', …
  }
  partySizeMin       3
  partySizeMax       10
  reward             { cosmeticKeys: [...], xp: 500, … }
  opensAt, closesAt  timestamps
  settledAt          timestamp (null dokud běží)

groups/{groupId}                     // raid party
  type: 'raid_party'
  config.raidEventId
  config.partyName    // user-zvolený

groups/{groupId}/contributions/{uid}
  metric, value, updatedAt
  // copy-through publish, NE read-through
  // klient sám zapisuje vlastní agregát
```

**Proč copy-through:** raid party leaderboard chce sekundové refreshe,
contribution je jediné číslo per user per period, NEcheteme dávat partě
read-rights do `users/{uid}/quests/...`.

### Kde žije RaidEvent

Ve Firestore (ne Remote Config), protože:

- Settlement Cloud Function potřebuje odkaz.
- Leaderboard agregace napříč party potřebuje odkaz.
- Admin update mid-event (oprava chyby, prodloužení) musí být per-event.

Remote Config se použije jen pro **feature toggle** ("raids enabled / disabled")
a pro **safety override** (force-close all running raids).

---

## Lifecycle

```
[Admin]   vytvoří RaidEvent ve Firestore (manual / admin tool)
[T-7d]    raid se "objeví" v UI, party se začnou tvořit
[T-0]     raid se otevře, contributions se začnou počítat
[active]  klienti publikují contributions/ při dosažení milníku
          nebo periodicky (debounce)
[T+30d]   raid se uzavře, žádné další contributions
[T+30d+]  settleRaid Cloud Function:
            - načte všechny party tohoto eventu
            - sečte contributions
            - každé party, která splnila → reward grant všem členům
            - zapíše settledAt, status → 'expired' na party
[T+60d]   archivace party (smaže contributions, zachová party metadata)
```

---

## Settlement

Cloud Function, cron-triggered (denně, kontrola eventů s
`closesAt < now() && settledAt == null`).

```
for each raidEvent to settle:
  for each party in groups where config.raidEventId == event.id:
    total = sum(contributions[*].value)
    if total >= event.objective.target:
      for each member in party.members where status == 'active':
        write RewardGrantEvent(...) do users/{uid}/engineRewardGrants/
          (jde to stejným kanálem jako každý progression reward)
    party.status = 'expired'
    party.config.settled = { total, succeeded: bool, settledAt }
  raidEvent.settledAt = now()
```

**Důležité:** reward jde **přes existující progression ledger**, ne přes
samostatný kanál. Tím dostáváme zdarma: idempotenci, replay, audit, sync
přes Firestore Sync.

---

## Anti-cheat (MVP úroveň)

Klient zapisuje `contributions/{uid}` přímo. Žádný server-side recompute v MVP.
Riziko: zlomyslný klient zapíše nesmyslnou hodnotu.

MVP zmírnění (ne plné řešení):

1. Security rule: `contributions/{uid}` smí psát jen `uid` sám.
2. Security rule: `value` smí jen růst (no decrease), max delta per write
   capped (sanity check).
3. Cap na `value` per metric per period (např. max 500 000 kroků/měsíc na
   člověka — biologický limit).
4. Audit log neobvyklých skoků (server-side log, alert pro adminy).

**Co NEděláme v MVP:**
- ❌ Server-side recompute z `users/{uid}/...` (drahé, vyžaduje read-rights
  serveru do privátních dat).
- ❌ Cross-device deduplikace.
- ❌ Cheat detection ML / anomaly.

**Až bude problém:** přidat server-side recompute jako verification pass
před settlement. Do té doby žijeme s tím, že nejhorší scénář je "někdo
zacheatuje a dostane kosmetiku" — nízká škoda.

---

## Edge cases

1. **Člen opustí party mid-event** — jeho contribution se **zmrazí** (zůstává
   v `contributions/`, ale read-only). Party počítá jeho příspěvek dál,
   on už nedostane reward (status `left` při settlementu).
2. **Party se rozpadne celá** — pokud `active members` klesne pod
   `partySizeMin` před settlementem, party má status `expired` ale
   reward se nevyplácí (failed by attrition). Edge case — adminovat manuálně?
3. **Splnění před koncem** — party může pokračovat (over-perform), settlement
   čeká na `closesAt` (aby všichni měli šanci doběhnout).
4. **Member joinne uprostřed** — povoleno do `T+50%` periody? Konfigurovatelné
   per raid. Default: do `T+25%`. Pozdější join → nemůže.
5. **Více raid eventů paralelně** — MVP: max 1 active raidEvent. Pozdější
   verze: 1 raid per kategorie (cardio / strength / nutrition).
6. **Player ban / delete** — pokud uživatel smaže účet mid-raid, contribution
   tombstoneované, party počítá bez něj.
7. **Time zone** — `closesAt` je UTC timestamp, klient si přepočítá. Žádné
   "půlnoc lokálně".
8. **Offline klient** — contribution se zapíše do queue, sync až online.
   Pokud sync přijde po `closesAt` → odmítnuto rules. Tradeoff: férový vůči
   ostatním, ale frustrující pro hráče. Buffer +1 den po close?

---

## Fázový plán

Vyžaduje minimálně **Guilds G.0–G.3** (core entity + invite + sharing infra).
Bez toho nelze začít.

Fáze R.0 — **Design pass** (krátký, navazuje na Guilds proposal)
- Doplnit `proposal.md` v této složce: vybrat MVP metriku, MVP party size,
  MVP cooldown mezi raidy.
- ADR: copy-through pro contributions (nepomyslné, ale zapsat proč).

Fáze R.1 — **RaidEvent + admin definition**
- Schema + security rules (read all, write none z klienta).
- Manuální seed přes Firebase console / skript pro testing.
- Žádné UI.

Fáze R.2 — **Party formation**
- Klient: založ party pro aktuální raid, pozvi přátele, accept invite.
- Stojí na Guilds G.2 (invite flow).
- Minimal UI.

Fáze R.3 — **Contributions publish + leaderboard**
- Klient: periodicky publish contribution (po dokončeném questu,
  HC sync, …).
- Realtime listener pro party leaderboard.
- Sanity caps v security rules.

Fáze R.4 — **Settlement Cloud Function**
- Cron job, denní run.
- Reward grant přes ledger.
- Status update na raidEvent + party.

Fáze R.5 — **Production UI**
- Raid screen na social screen (per [UI refactor](../../ui_refactor/plan.md)).
- Discover/join active raid, party management, leaderboard, history.
- Notifikace (FCM): raid opens, party complete, settlement done.

Fáze R.6 — **Admin tooling** (later)
- Admin screen v devtools (založ raidEvent, force-settle, ban contribution).
- Zatím manual / Firebase console stačí.

---

## Non-goals

- ❌ PvP raidy (party vs party).
- ❌ Real-time co-op během raidu (nějaký "boss fight" v reálném čase).
- ❌ Sezónní cosmetics tier (battle pass) — odděleně, ne raidy.
- ❌ Custom community-created raidy — vždy admin-managed.
- ❌ Multi-stage raidy (week 1, week 2, …) — možná pozdější verze.
- ❌ Item drops jiné než kosmetika (žádné "power").

---

## Otevřené otázky

1. **Party formation discovery** — jen "pozvat přítele" (invite-only), nebo
   "připojit se k otevřené party" (lobby)? MVP: jen invite. Lobby pozdější.
2. **MVP metrika** — kroky (universal, low-friction) vs splněné questy
   (vyžaduje aktivní hru). Kroky jednodušší pro start.
3. **Reward grade** — všichni stejně, nebo top contributor bonus? MVP:
   všichni stejně (jednodušší, méně toxic).
4. **Failure penalty** — party nesplnila → nic, nebo "consolation"? MVP:
   nic. Možná malá kosmetika za samotnou účast.
5. **Solo raid** — povolit party of 1? MVP: ne (min 3). Solo questy už máme.
6. **Inactive member** — člen, co nepřispěl ničím, dostane reward? Diskuze.
   Návrh: ano (party-effort, ne individual). Možná minimum threshold.
7. **Cross-raid leaderboard** — "nejlepší party všech dob"? Zajímavé,
   ale nepatří do MVP.

---

## Odkazy

- [Guilds — foundational group system](../guilds/plan.md)
- [Coaching — deferred sibling feature](../coaching/rough_plan.md)
- Progression ledger: [docs/progression_engine/](../../progression_engine/)
- Cosmetics grant flow: [docs/features/firestore_sync.md](../firestore_sync.md)
- Trello: **#129** (Raids) — vlastní karta; #128 (Guilds), #26 (umbrella / Coaching)
