# Coach Log Export — Lookup design a fázování implementace

Tento dokument doplňuje `coach-log-export-plan.md` o dvě věci:

1. Konkrétní rozhodnutí, jak řešit lookup existujících týdenních bloků v Google Sheets.
2. Rozpad MVP 1 implementace na fáze s jasnou definition of done.

Plán (`coach-log-export-plan.md`) je zdroj pravdy pro produktové chování a layout. Tento dokument je zdroj pravdy pro implementační rozhodnutí, která plán nechává otevřená.

---

## Lookup týdenních bloků

### Rozhodnutí

Lookup řešíme **scanem skrytého sloupce Z** s těmito pravidly:

1. **Marker nese verzi layoutu.**
   Formát:
```
   BUSHIDO_WEEK:{year}-W{ww}:v{layoutVersion}
```
   Příklad:
```
   BUSHIDO_WEEK:2026-W18:v1
```
   Verze (`v1`) umožní v budoucnu měnit layout bez rozbití starých týdnů.

2. **Marker je pouze na headeru bloku.**
   Jen jeden řádek bloku má marker ve sloupci Z — řádek headeru týdne. Všechny ostatní řádky bloku mají Z prázdné. Tím je scan jednoznačný a počítání řádků uvnitř bloku je vždy `headerRow + offset` podle `BushidoSheetLayout`.

3. **Layout je verzovaný v configu.**
```dart
   class BushidoSheetLayout {
     static const layoutVersion = 'v1';
     static const weekBlockHeight = 12;
     // ...
   }
```
   Když se v budoucnu změní výška bloku nebo offsety, povýší se `layoutVersion` na `v2`. `ensureWeekBlock` pozná, že existující blok je `v1` a nový kód umí jen `v2` — pro MVP loguje warning a založí nový blok pod `v2` na konci listu. Migrace starých bloků není v MVP řešena.

4. **Lookup logika.**
```
   načti Z:Z (jeden API call)
   najdi řádek s markerem 'BUSHIDO_WEEK:{week}:v{currentLayoutVersion}'
     → existuje:                     startRow = ten řádek
     → existuje s jinou verzí:       log warning, append nový blok
     → neexistuje:                   append nový blok na konec listu
```

5. **Append, ne insert.**
   Nové týdny se přidávají vždy na konec listu, ne mezi existující. Chronologie není zaručena pořadím v listu, ale markerem. Tím se vyhneš complexity s posouváním existujících bloků a invalidací cached `startRow` během jedné `exportRange` operace.

6. **Cache scan v rámci jedné exportRange operace.**
   Načteš Z:Z jednou na začátku `exportRange`, pak pracuješ s in-memory mapou `{IsoWeek → startRow}`. Po každém appendu nového bloku přidáš záznam do mapy. Žádné opakované `values.get` během iterace přes týdny.

### Proč ne jiné varianty

**Index list** (samostatný sheet `_bushido_index` s mapováním `week → startRow`): zavedl by druhý zdroj pravdy. Pokud uživatel ručně přesune řádky, index a realita se rozejdou. Pro MVP overkill.

**Developer metadata** (Sheets API mechanismus pro přiřazení metadat k řádku): nejčistší teoretické řešení, posouvá se s řádkem při insert/delete. Ale neviditelné v UI (horší debug), víc Sheets API kódu, horší recovery při rozbití. Stojí za zvážení v budoucnu, pokud scan Z:Z začne být limitní.

### Důsledky pro implementaci

- `BushidoSheetsService.findWeekBlock(week)` čte Z:Z a hledá marker s aktuální verzí.
- `BushidoSheetsService.appendWeekBlock(week)` appenduje na konec listu, zapisuje marker, headery, vzorce, validace.
- `BushidoSheetsService.ensureWeekBlock(week, cache)` orchestruje find + append, používá cache.
- `BushidoExportProvider.exportRange(from, to)` načte Z:Z jednou, předá cache do iterace.

---

## Fáze implementace MVP 1

Každá fáze = jedna Claude Code session = jeden commit. Po každé fázi review diff před commitem.

### Fáze 0 — Doménové modely a ISO week utility

**Co:**
- `IsoWeek` (year, weekNumber, monday, sunday, marker getter)
- `BushidoDayRow` (date + nullable metriky)
- `BushidoWeekReport` (week, days vždy 7 prvků v chronologickém pořadí)
- Utility: `dateOnly()`, `startOfIsoWeek()`, `isoWeeksOverlapping(from, to)`, `nextIsoWeekAfter()`

**DoD:**
- Unit testy pokrývají edge cases:
  - Přelom roku (2025-W53 vs 2026-W01).
  - Rozsah uvnitř jednoho týdne.
  - Rozsah pondělí–neděle (1 týden).
  - Rozsah pondělí–následující pondělí (2 týdny).
  - Rozsah přes 4+ týdnů.
- Žádná závislost na Sheets ani na data providerech.

### Fáze 1 — Configy

**Co:**
- `BushidoExportConfig` (sloupce auto/manual, target metriky, dropdown hodnoty pro hlad/hydrataci).
- `BushidoSheetLayout` (offsets, výška bloku, sloupec markeru, `layoutVersion`).
- `BushidoSheetStyle` (barvy, fonty — placeholdery, doladí se s koučem).
- Enumy `BushidoColumn`, `BushidoTargetMetric`.

**DoD:**
- Pouze statická data, žádná logika.
- `IsoWeek.marker` z Fáze 0 přejde na použití `BushidoSheetLayout.layoutVersion` místo hardcoded `"v1"` (TODO komentář z Fáze 0 zmizí).
- Vše konzumovatelné v testech bez mocků.

### Fáze 2 — `BushidoExportDataBuilder`

**Co:**
- Z existujících providerů (Health Connect, Kalorické Tabulky, váha) sestaví `BushidoWeekReport` pro daný `IsoWeek`.
- Chybějící hodnoty = `null`.
- Skutečné nuly (např. 0 kroků v existujícím záznamu) zůstávají `0`.

**DoD:**
- Test: týden bez dat → 7 dnů s `null` hodnotami.
- Test: týden s částečnými daty → správně namapováno na dny, chybějící = `null`.
- Test: skutečná nula zůstává `0`, ne `null`.
- Žádná závislost na Sheets. Builder bere zdrojové providery jako dependencies.

### Fáze 3a — `BushidoSheetsService`: lookup a append

**Co:**
- `findWeekBlock(week) → int?` — scan Z:Z, marker matching s verzí.
- `appendWeekBlock(week) → int` — append prázdného bloku na konec listu, zápis markeru, headerů, vzorců, dropdown a checkbox validací.
- `ensureWeekBlock(week, cache) → int` — orchestrace find + append, používá in-memory cache.

**DoD:**
- Test (s mockem Sheets klienta): nový týden → append, marker zapsán na správný řádek a sloupec.
- Test: existující týden → find vrátí správný `startRow`.
- Test: existující týden s jinou verzí markeru → log warning, append nového.
- Test: cache se konzistentně updatuje po appendu.

### Fáze 3b — `BushidoSheetsService`: write auto cells, ochrana manual buněk

**Co:**
- `writeAutoCells(week, startRow, dayRows)` — zápis jen do auto sloupců (`A:H` podle layoutu).
- Manual sloupce (`I:L`) se nikdy nezapisují při re-exportu.
- Chybějící hodnoty (`null`) → blank buňka, nikdy `0`.

**DoD:**
- Test: write auto cells nezapíše nic do manual sloupců.
- Test: `null` v `BushidoDayRow` → blank cell v Sheets payloadu.
- Test: `0` v `BushidoDayRow` → `0` v Sheets payloadu.
- Test: opakovaný export stejného rozsahu → idempotentní (žádné duplikáty bloků, žádné změny v manual sloupcích).

### Fáze 4 — `BushidoExportProvider`

**Co:** Orchestrace `exportRange(from, to)`:

```
1. dateOnly normalizace from a to.
2. healthProvider.refreshRange(from, to) + ktProvider.refreshRange(from, to).
3. weeks = isoWeeksOverlapping(from, to).
4. načti Z:Z → cache existujících týdnů.
5. for week in weeks:
     startRow = sheetsService.ensureWeekBlock(week, cache)
     report   = dataBuilder.build(week)
     sheetsService.writeAutoCells(week, startRow, report.days)
6. sheetsService.ensureWeekBlock(nextIsoWeekAfter(to), cache)
```

A `exportCurrentWeek()` jako tenký wrapper (`from = startOfIsoWeek(today), to = today`).

**DoD:**
- Integration test s in-memory fake Sheets klientem:
  - Test 3 týdny, prostřední bez dat → všechny 3 bloky existují, prostřední je prázdný.
  - Test re-export stejného rozsahu → idempotentní.
  - Test: po `exportRange(from, to)` existuje i blok pro `nextIsoWeekAfter(to)`.

### Fáze 5 — UI

**Co:** Sekce v existující export obrazovce:
- Tlačítko "Exportovat aktuální týden" → `exportCurrentWeek()`.
- Date range pickers + tlačítko "Exportovat rozsah" → `exportRange(from, to)`.
- Loading state, error handling, success feedback s odkazem na Sheets.

**DoD:** Manuální test obou flows v dev buildu proti reálnému testovacímu Sheets dokumentu.

### Fáze 6 — End-to-end ověření a polish

**Co:**
- Spustit export na 4 týdny zpětně, ověřit layout v Sheets vizuálně.
- Spustit znovu, ověřit idempotenci.
- Ručně vyplnit manual buňky, znovu spustit, ověřit, že se nepřepsaly.
- Doladit barvy/fonty s koučem (`BushidoSheetStyle`).
- Drobné fixy.

**DoD:** Skutečný week report v Google Sheets, který lze poslat kouči.

---

## Co je mimo MVP 1

Plán (`coach-log-export-plan.md`) popisuje další etapy. Pro úplnost shrnutí, co MVP 1 NEobsahuje:

- **MVP 2:** checkbox pro trénink, dropdown hlad/hydratace na úrovni daily rows, poznámky klienta, feedback kouče.
- **MVP 3:** conditional formatting podle cílů, `Flag dne`, zvýraznění chybějících dat.
- **Future:** import cílů z Sheets do appky, diff UI, validace.

Tyto etapy se plánují až po dokončení MVP 1 a ověření s koučem.

---

## Implementační invarianty

Tyto invarianty platí napříč všemi fázemi a Claude Code je má dodržovat bez výjimky:

- Každý `BushidoWeekReport` má vždy přesně 7 dnů.
- Chybějící data = `null` v doméně, blank v Sheets. Nikdy fallback `0`.
- Re-export nikdy nepřepisuje manual sloupce.
- Re-export je idempotentní — stejný rozsah dvakrát = stejný stav v Sheets.
- Týdny bez dat se vytváří jako prázdné bloky, neskáčou.
- Marker `BUSHIDO_WEEK:{week}:v{layoutVersion}` je jediný zdroj pravdy o existenci a verzi bloku.
- Průměry a target box vzorce řeší Sheets, ne appka. Appka vzorce zapisuje při vytvoření bloku, neaktualizuje výsledky.
- Konfigurace (sloupce, barvy, dropdown hodnoty, tolerance) patří do configu, ne do servisních tříd.
- Existující raw export se nemění.