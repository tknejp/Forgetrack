# Guilds — Group System Plan

Foundational group/membership infrastructure pro Forgetrack. Není
samostatnou produktovou featurou v UI — je to **sdílený základ** pro
[Raids](../raids/plan.md) (near-term) a [Coaching](../coaching/rough_plan.md)
(deferred), plus budoucí guild-like featury (friend groups, team
challenges, public guilds…).

**Status:** plánováno, po dalším releasu. Implementace ještě nezačala.

Tento dokument je hrubší plán — kostlivec pro pozdější `proposal.md` +
`data_model.md` + `migration_plan.md` (po vzoru
[domain_model refactoru](../../domain_model/)). Před začátkem prací je
nutné udělat full design pass.

---

## Princip

Jedna `Group` entita, dva (zatím) konzumenti:

```
Guilds (groups + membership + sharing + invite)
   ├── Raids       (type: raid_party)        — near-term
   └── Coaching    (type: coach_space)       — deferred
```

`group.type` je diskriminátor. Sdílí se: membership, invite/accept
flow, role hint, sharing capability bits, audit log. Specifické
chování (settlement raidu, consent flow trenéra) žije ve své feature
složce.

**Záměrně sdílené:** infrastruktura, kterou bychom jinak psali dvakrát.
**Záměrně oddělené:** business pravidla, permission semantika,
UI flow — v `lib/features/raids/` a `lib/features/coaching/`, ne v
`lib/features/guilds/`.

---

## Datový model (návrh, ne finální)

Vše ve Firestore. Lokální cache v Isaru viz [Offline](#offline--local-first).

```
groups/{groupId}
  type            'raid_party' | 'coach_space' | (budoucí: 'friend_group', 'guild')
  name            string
  ownerUid        string
  status          'active' | 'archived' | 'expired'
  visibility      'private' | 'invite_only' | 'public'    // public zatím nepoužíváme
  createdAt       timestamp
  config          map<string, any>     // type-specific (raidEventId, maxMembers, …)

groups/{groupId}/members/{uid}
  role            'owner' | 'coach' | 'client' | 'member' | 'captain'
  status          'invited' | 'active' | 'left' | 'removed'
  joinedAt        timestamp
  invitedBy       string
  shares          map<string, bool>    // capability bits — viz Permissions
                                       //   default ALL FALSE
                                       //   ovládá vlastník dat, ne owner group

groups/{groupId}/invites/{inviteId}
  email | uid     string
  role            string
  expiresAt       timestamp
  status          'pending' | 'accepted' | 'declined' | 'expired'

groups/{groupId}/auditLog/{eventId}
  actorUid, action, target, before, after, at
```

Specifické subkolekce (`challenges/`, `contributions/`, …) patří do
příslušné feature složky, ne sem.

---

## Permission model — capability per data doména

**Klíčový princip:** autorizace pro čtení sdílených dat se NEodvozuje
z role. Odvozuje se z **konkrétního `shares` flagu na membership**,
který zapíná vlastník dat.

```dart
shares: {
  healthConnect: false,
  kalorickeTabulky: false,
  questsProgress: false,
  progressionLedger: false,
  exports: false,
  // …rozšiřitelné po doménách
}
```

- **Role je UI hint** (kdo má jakou ikonu, jaké tlačítko vidí).
- **Capability bit je zdroj pravdy** pro autorizaci v security rules.
- Default = deny. Vlastník dat každý bit explicitně zapíná.
- Revoke = atomic flip, žádný cleanup kopií (viz [Sync strategie](#sync-strategie)).

Tím dostáváme GDPR-friendly model: žádný "trenér automaticky vidí HC"
typu sweeping consent. Každá doména je samostatné rozhodnutí.

### Audit log

Každá změna `shares` (nebo membership status) → záznam do
`auditLog/`. Levné, povinné pro pozdější coaching (spor "co kdo komu
sdílel kdy").

---

## Sync strategie

Dvě cesty podle use-case. Důležité **rozhodnout per konzument**:

| | Read-through (rules) | Copy-through (publish) |
|---|---|---|
| Cesta čtení | reader → `users/{ownerUid}/...` přes rules | reader → `groups/{gid}/snapshots/{ownerUid}/...` |
| Revoke | flip jednoho bitu, instant | musí smazat kopie |
| Náklady | každý read = group lookup v rules | každý write = fan-out |
| Vhodné pro | hluboká privátní data, vysoký objem, granularita důležitá | jedno číslo per period, malá party, leaderboard |
| Použije | **Coaching** | **Raids** |

Guilds vrstva poskytuje **oba mechanismy**, ale neřeší kterou kdo
použije — to je rozhodnutí konzumenta.

---

## Server-side

Cloud Functions, ne hot path:

- `acceptInvite(inviteId)` — atomický zápis: invite.status, member doc,
  audit log. Spouští validace (limity, expirace, duplicate).
- `revokeMembership(groupId, uid)` — flip status na 'removed', cascade
  na `shares` (vše false), audit log.
- `assignChallenge / settleRaid / …` — domain-specific, řeší si konzument.

Security rules:

- Read `groups/{gid}` → musí být member (status active).
- Read `groups/{gid}/members` → member.
- Write `members/{uid}.shares` → jen `uid` sám (vlastník dat).
- Read `users/{ownerUid}/<doména>` přes group → check (a) společný
  group s active status, (b) `members/{ownerUid}.shares[<doména>] == true`.
  Konkrétní pravidlo žije v rules té domény, ne v guilds.

**Co NEdělat na serveru:** žádné agregace, žádné read-through
proxy endpointy, žádný hot-path business logic. Vše čte klient přes rules.

---

## Offline / local-first

Forgetrack je local-first nad Isarem. Guilds vrstva musí to ctít:

- `IsarGuildMembership` — cache membership + `shares`. Refresh při
  startu + reactive listener.
- Invite accept / revoke / member zápisy → queued (existující
  hybrid-repo vzor à la [HybridProgressionEngineRepository](../../../lib/features/progression_engine/data/hybrid_progression_engine_repository.dart)).
- Read sdílených dat: degradace na last-known cache, banner "offline".
- Žádný blocking call na network pro UI rendering.

---

## Lifecycle

- **Create:** owner založí group, sám je `owner` + `active`. `shares`
  defaultně všechny false (i pro ownera — řeší až per konzument).
- **Invite:** owner / oprávněný role pošle invite. Invite má TTL.
- **Accept:** invitee přijme → `members/{uid}` s `status: active`.
  Sharing zapíná separátním krokem (NE součást acceptu).
- **Leave:** vlastní rozhodnutí, status → `left`, audit.
- **Remove:** owner odebere, status → `removed`, audit. `shares`
  resetované na false (i kdyby remove byl temporary).
- **Archive group:** owner archivuje, status → `archived`, čtení
  read-only.
- **Expire:** systémový (raidy), status → `expired`, čtení read-only.

---

## Limity (předběžné, nutno revidovat)

- Max groups per user: TBD (návrh: 50). Jinak quota / rules exploze.
- Max members per group: per `type` (raid: ~20, coach: ~200, friend: ~50).
- Max pending invites per group: ~100.

---

## Non-goals (explicit)

- ❌ Chat / messaging — nikdy v MVP, asi nikdy v Guilds vrstvě.
  Pokud někdy, samostatná feature s vlastní moderací.
- ❌ Public guild directory / discovery — odloženo.
- ❌ Real-time presence ("kdo je online") — odloženo.
- ❌ Veřejné profily skupin pro nečleny — odloženo.
- ❌ Nested groups / sub-groups — odloženo.
- ❌ Cross-group analytics — odloženo.

---

## Otevřené otázky

1. **Identita členů**: zobrazujeme display name + avatar z `users/{uid}/profile`.
   Co když uživatel nemá veřejný profil? Globální opt-in "viditelný v groupách"?
2. **Free vs paid**: jsou Guilds free? Coaching možná premium? Raid free?
   Ovlivní limity i security rules.
3. **Notifikace**: invite, settlement, milestone — FCM? In-app feed? Obojí?
   (Existující FCM už máme.)
4. **i18n group jmen**: uživatelem zadaná jména jsou plain text bez překladu — OK.
   Systémem generovaná (raid party "Iron Wolves") chceme localizovat?
5. **Moderace**: pokud někdy public discovery, kdo řeší abuse / urážlivé
   názvy? Reporting flow? (Dlouhodobá otázka, ne MVP.)
6. **GDPR DPA**: pokud nějaký share znamená data processing pro třetí stranu
   (jiný user), nepotřebujeme to ošetřit smlouvou? Pro coaching určitě,
   pro raid pravděpodobně ne (sdílíme jen agregát). Vyžaduje právní review.

---

## Fázový plán (rough, nepouštět bez proposal review)

Fáze G.0 — **Design pass**
- proposal.md (produktový rozsah, non-goals)
- data_model.md (finální shape)
- permissions.md (capability model, consent UX, audit log spec)
- ADR v `docs/site/data/decisions.json`: (a) capability vs role,
  (b) read-through vs copy-through, (c) sdílený Group entity vs feature-specific.

Fáze G.1 — **Core entity**
- `lib/features/guilds/domain/` — `Group`, `GroupMember`, `GroupRole`,
  `GroupShares`, `GroupStatus`.
- Firestore schema + base security rules (jen self-read, žádné sdílení dat).
- Isar cache + reactive provider.
- Žádné UI.

Fáze G.2 — **Invite / accept flow**
- `acceptInvite` Cloud Function.
- Klient: vytvoř group → odešli invite → přijmi.
- Minimal UI (debug screen / devtools).

Fáze G.3 — **Sharing capability infrastruktura**
- `updateShares` flow (client píše vlastní bity).
- Base security rule pattern pro read-through (template, používaný v G.4+).
- Audit log zápisy.

Fáze G.4 — **Konzument: Raids** (přepíná do [Raids plánu](../raids/plan.md))

Fáze G.5 — **Production UI**
- Sekce v social screen, profil, …
- Per [UI refactor](../../ui_refactor/plan.md) konvencí.

Fáze G.6 (later) — **Konzument: Coaching** (přepíná do [Coaching plánu](../coaching/rough_plan.md))

---

## Vztah k existujícím systémům

- **Progression engine V2**: Guilds NEMĚNÍ engine. Challenge / raid metrika
  se materializuje jako standardní quest, engine ji konzumuje stejně jako HC/KT.
- **Firestore sync**: Guilds používá vlastní gateway + hybrid repo vzor,
  konzistentní s [Firestore Sync](../firestore_sync.md).
- **Cosmetics**: rewardy z raidů/challenges jdou stávajícím
  `RewardGrantEvent(rewardKind: cosmetic)` flow. Žádný nový grant kanál.
- **Auth**: spoléhá na existující FirebaseAuth. Anonymous users — TBD
  (asi nemůžou být v groupách, signed-only).
- **Config**: limity, raid definice — vrstva AdminConfig z
  [Config systému](../../config/) (až bude).

---

## Odkazy

- [Raids — near-term feature plan](../raids/plan.md)
- [Coaching — deferred rough sketch](../coaching/rough_plan.md)
- Architektura: [docs/architecture.md](../../architecture.md)
- Firestore sync vzor: [docs/features/firestore_sync.md](../firestore_sync.md)
- Domain refactor jako šablona fázování: [docs/domain_model/](../../domain_model/)
- Trello: **#128** (Guilds) — vlastní karta; #26 (umbrella / Coaching), #129 (Raids)
