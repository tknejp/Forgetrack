# Coaching — Rough Plan (deferred)

> ⚠️ **Status:** odloženo. Tento dokument je **hrubý nástřel**, ne plán k implementaci.
> Nezačínat bez:
> 1. Produktového proposalu (in/out scope, persona trenéra)
> 2. **Legal / GDPR go/no-go** (viz [Otevřené otázky](#otevřené-otázky))
> 3. Hotové [Guilds](../guilds/plan.md) infrastruktury (G.0–G.5)
> 4. Raids feature v produkci (validuje group infrastrukturu)

Coaching je produktově nejcennější social feature, ale **nejcitlivější**
po technické, právní i UX stránce. Záměrně odložené za raidy.

---

## Účel

Trenér ↔ klient(i) dlouhodobý vztah v rámci Forgetracku:

- Trenér vidí (sdílená) data klienta (HC, KT, questy, progression).
- Trenér může klientovi navrhovat / nastavovat cíle.
- Trenér může vytvořit **měsíční challenge** napříč svou klientelou.
- Klient může push-shareovat Sheets export přímo trenérovi.

---

## Vztah ke Guilds a Raids

Coaching = nový `group.type: 'coach_space'` nad [Guilds](../guilds/plan.md).

| | Coaching | Raids |
|---|---|---|
| Lifecycle | trvalý vztah, oboustranný revoke | měsíční, expires |
| Role | asymetrické (coach ⇄ client) | symetrické (member) |
| Data sharing | hluboké, per doména, explicit consent | žádné raw, jen agregát |
| Sync | **read-through** (rules) | copy-through |
| Discovery | invite-only, manuální | invite-only MVP, později open |
| Legal | **DPA, GDPR**, audit log | minimální |

Coaching používá Guilds infrastrukturu (membership, invite, shares,
audit log), ale **business logika a UI žije v `lib/features/coaching/`**.
Nedávat do `lib/features/guilds/`.

---

## Hrubý datový model

Nad existujícím `groups/` (type `coach_space`) + vlastní subkolekce:

```
groups/{groupId}                      // coach space — typicky 1 trenér + N klientů
  type: 'coach_space'
  config.coachUid

groups/{groupId}/members/{uid}
  role: 'coach' | 'client'
  shares: {
    healthConnect: false,
    kalorickeTabulky: false,
    questsProgress: false,
    progressionLedger: false,
    sheetExports: false,
    goalManagement: false,            // smí trenér setovat klientovi cíle
  }                                   // klient řídí, default vše false

groups/{groupId}/assignedGoals/{goalId}
  assignedBy (coach uid), assignedTo (client uid)
  goalSpec (cíl: kalorie, kroky, kg, …)
  status: 'proposed' | 'accepted' | 'rejected' | 'active' | 'completed'
  // klient musí accept před aktivací

groups/{groupId}/challenges/{challengeId}
  questTemplate                       // reuse existing quest definition
  assignedTo: [clientUids…]
  window, reward
  // materializuje se klientovi jako standardní quest

groups/{groupId}/sharedExports/{exportId}
  sharedBy (client uid), sheetUrl, period, sharedAt
  // klient push-shareuje, trenér read-only
```

---

## Consent flow (kritické)

**Princip:** žádný sweeping "souhlasím se sdílením s trenérem". Každá
doména = samostatný explicit consent, samostatně odvolatelný, vždy s audit
záznamem.

```
1. Trenér pozve klienta (invite) → role 'client'
2. Klient přijme invite → member.status = 'active', všechny shares = false
3. Klient v UI vidí "Trenér vidí:" seznam s toggly:
     [ ] Health Connect data
     [ ] Kalorické Tabulky
     [ ] Quest progres
     [ ] Progression ledger
     [ ] Sheet exporty
     [ ] Smí mi navrhovat cíle
4. Každý toggle = jeden zápis do shares + audit log
5. Revoke kdykoli, instant (flip bit), audit log
6. Trenérovo UI vidí jen domény, kde shares[x] == true
```

Audit log musí být **read-only pro trenéra** (transparency) a **append-only**
(žádný delete).

---

## Settling assigned goals

Klient musí cíl **accept** před aktivací. Důvody:

- Klient si může nesouhlasit s cílem trenéra.
- Právní (klient zůstává vlastníkem rozhodnutí o vlastním tréninku).
- Praktické (klient může mít fyzický důvod, který trenér nezná).

Po acceptu se cíl chová jako standardní goal v progression enginu —
žádná separátní vrstva.

---

## Otevřené otázky (musí být zodpovězeny PŘED proposal pass)

### Legal / regulatorní

1. **Data processor vs controller**: pokud trenér je třetí strana (ne
   zaměstnanec), Forgetrack je data processor pro klienta a … co pro
   trenéra? Joint controller? Vyžaduje právní review.
2. **DPA šablona**: musíme mít? Pro EU pravděpodobně ano. Kdo ji
   sestaví? Existuje template?
3. **Privacy policy update**: dnešní PP nezná koncept "sdílení dat
   třetí osobě". Update nutný.
4. **DPO povinnost**: pokud rozšíříme processing o systematic
   monitoring zdraví, GDPR Art. 37 může vyžadovat DPO. Konzultace?
5. **Right to erasure**: pokud klient požádá o smazání, co se stane
   s daty, která už viděl trenér? Cache na jeho zařízení? Audit záznam
   sdílení musí zůstat (pro dokazování).
6. **Health data special category**: GDPR Art. 9 vyžaduje explicit
   consent pro health data. Naše current consent UI to splňuje? Per
   doména consent ano, ale wording musí být precise.
7. **Trenér jako persona**: business model? Free pro klienta, paid pro
   trenéra? Nebo obojí free? Ovlivní DPA a smluvní vztah.
8. **Země mimo EU**: jurisdikce? Pokud trenér v UK / US a klient v EU,
   cross-border transfer rules.

### Produktové

9. **Coach onboarding**: stejná app nebo samostatná "Coach mode"?
   Single-app je jednodušší tech, ale UX challenge.
10. **Coach může být i hráč**: vlastní progression nesmí být ovlivněna
    tím, co vidí u klientů.
11. **Multiple coaches per client**: povolíme? Nebo jen 1 coach na
    klienta? (Doporučuji 1 pro MVP.)
12. **Coach může vidět agregát všech klientů**: dashboard? Aggregace
    nesmí být re-identifikovatelná, pokud klient nesdílí identifikační info.
13. **Coach žádá o reactivation share**: notifikační flow ("trenér chce
    vidět tvoje HC data, povolit?").
14. **Klient opustí coach group**: data smazat z trenérova devicu? Read
    access skončí, ale jeho cache?

### Technické

15. **Read-through scaling**: každý trenér s 20 klienty = 20× group lookup
    per read. Quota / latence? Možná denormalizace klíčových polí?
16. **Coach offline**: vidí cached data klientů? Jak old? Banner?
17. **Sheet share security**: klient sdílí Sheets URL. Sheet musí být
    accessible trenérovi — kdo nastaví permissions? Forgetrack pres Sheets API?

---

## Naivní fázový plán (nedělat dokud nejsou OO zodpovězené)

Fáze C.0 — **Proposal + legal**
- Produktový proposal: persona trenéra, MVP scope, pricing.
- Legal review: DPA, PP update, DPO check.
- **Go / no-go gate.** Pokud no-go → coaching zaříznout, ne tlačit.

Fáze C.1 — **CoachSpace + invite (jen membership, bez sdílení)**
- Group type `coach_space`, role coach/client.
- Invite trenér → klient, accept.
- Žádný read sdílených dat zatím.

Fáze C.2 — **Consent UI + první doména (questsProgress)**
- Klient zapíná/vypíná `questsProgress` share.
- Trenér vidí klientův quest log read-only.
- Audit log funkční.

Fáze C.3 — **Goal proposal flow**
- Trenér navrhne cíl, klient accept/reject.
- Integrace s progression goals.

Fáze C.4 — **Další sdílené domény**
- HC, KT, progression ledger, sheet exports — postupně, každá vlastní toggle.

Fáze C.5 — **Cross-client challenges**
- Reuse Raids settlement infra (Cloud Function).
- Trenér vytvoří challenge napříč svými klienty.

Fáze C.6 — **Coach dashboard UI**
- Přehled klientů, jejich progress, alerty.

---

## Non-goals (vědomé)

- ❌ Real-time chat trenér ↔ klient (existuje Slack/WhatsApp).
- ❌ Video session / streaming.
- ❌ Platby trenérovi přes Forgetrack.
- ❌ Trenérská marketplace ("najdi si trenéra").
- ❌ AI coach jako trenér (samostatný produktový směr).
- ❌ Public profil trenéra s reviews.

---

## Odkazy

- [Guilds — foundational group system](../guilds/plan.md)
- [Raids — sibling feature (in flight first)](../raids/plan.md)
- [Coach Log Export](../coach_log_export.md) (existující týdenní Sheets report — předchůdce konceptu)
- Trello: **#26** (Coaching / umbrella) — vlastní karta; #128 (Guilds), #129 (Raids)
