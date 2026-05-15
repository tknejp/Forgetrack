# Coach Log Export (Bushido)

Týdenní coaching report do Google Sheets. Implementováno v
[../../lib/features/coach_log_export/](../../lib/features/coach_log_export/).
Tento dokument je trvalá designová reference — produktové chování,
invarianty a wire format, které musí jakákoli budoucí změna respektovat.

Existuje vedle raw Sheets exportu ([../../lib/features/sheets_export/](../../lib/features/sheets_export/)),
který slouží jako kompletní DB dump pro osobní analýzu. Coach Log má
jiný use-case: opakovatelný týdenní report pro nutričního kouče a
klienta.

---

## Produktový princip

Uživatel nemá řešit technické volby (obnovit Health Connect, obnovit
KT, vytvořit nový blok, aktualizovat existující blok, připravit další
týden). Všechny tyto operace jsou automatické.

UI nabízí dvě akce:

- **Exportovat aktuální týden** — aktualizuje aktuální ISO týden od
  pondělí do dneška. Budoucí dny zůstávají prázdné.
- **Exportovat rozsah** — uživatel zvolí libovolné datum od/do. Appka
  rozsah automaticky rozpadne na ISO týdny a zajistí, že každý ISO
  týden v rozsahu existuje jako blok (i kdyby byl bez dat).

Při každém exportu se interně provede:

```text
sync Health Connect
sync Kalorické Tabulky
normalizace rozsahu na datumy
rozpad rozsahu na ISO týdny
zajištění existence všech týdenních bloků v rozsahu
aktualizace automatických buněk
zachování ručních buněk
zajištění jednoho dalšího prázdného týdne
```

---

## Invarianty (platí napříč všemi změnami)

- Každý `BushidoWeekReport` má vždy přesně 7 denních řádků.
- Chybějící data = `null` v doméně, blank buňka v Sheets. **Nikdy
  fallback `0`.** Skutečná nula (0 kroků v existujícím záznamu) se
  zapisuje jako `0`.
- Re-export nikdy nepřepisuje manual sloupce.
- Re-export je idempotentní — stejný rozsah dvakrát = stejný stav v
  Sheets.
- Týdny bez dat se vytváří jako prázdné bloky, neskáčou.
- Marker `BUSHIDO_WEEK:{year}-W{ww}:v{layoutVersion}` je jediný zdroj
  pravdy o existenci a verzi bloku.
- Průměry a target box vzorce řeší Sheets, ne appka. Appka vzorce
  zapisuje při vytvoření bloku, neaktualizuje výsledky.
- Konfigurace (sloupce, barvy, dropdown hodnoty, tolerance) patří do
  configu, ne do servisních tříd.
- Existující raw export se nemění.

---

## Marker design (lookup týdenních bloků)

Lookup řešíme **scanem skrytého sloupce Z** s těmito pravidly:

1. **Marker nese verzi layoutu.** Formát:

   ```text
   BUSHIDO_WEEK:{year}-W{ww}:v{layoutVersion}
   ```

   Příklad: `BUSHIDO_WEEK:2026-W18:v1`. Verze (`v1`) umožní v budoucnu
   měnit layout bez rozbití starých týdnů.

2. **Marker je pouze na headeru bloku.** Jen jeden řádek bloku má
   marker ve sloupci Z. Všechny ostatní řádky bloku mají Z prázdné.
   Počítání řádků uvnitř bloku je vždy `headerRow + offset` podle
   `BushidoSheetLayout`.

3. **Layout je verzovaný v configu.** Když se v budoucnu změní výška
   bloku nebo offsety, povýší se `layoutVersion` na `v2`.
   `ensureWeekBlock` pozná, že existující blok je `v1` a nový kód umí
   jen `v2` — loguje warning a založí nový blok pod `v2` na konci
   listu. Migrace starých bloků v MVP řešena není.

4. **Lookup logika:**

   ```text
   načti Z:Z (jeden API call)
   najdi řádek s markerem 'BUSHIDO_WEEK:{week}:v{currentLayoutVersion}'
     → existuje:                     startRow = ten řádek
     → existuje s jinou verzí:       log warning, append nový blok
     → neexistuje:                   append nový blok na konec listu
   ```

5. **Append, ne insert.** Nové týdny se přidávají vždy na konec listu,
   ne mezi existující. Chronologie není zaručena pořadím v listu, ale
   markerem. Tím se vyhneme complexity s posouváním existujících bloků
   a invalidací cached `startRow` během jedné `exportRange` operace.

6. **Cache scan v rámci jedné exportRange operace.** Načteš Z:Z jednou
   na začátku `exportRange`, pak pracuješ s in-memory mapou
   `{IsoWeek → startRow}`. Po každém appendu nového bloku přidáš
   záznam do mapy. Žádné opakované `values.get` během iterace přes
   týdny.

### Proč ne jiné varianty

- **Index list** (samostatný sheet `_bushido_index` s mapováním
  `week → startRow`): zavedl by druhý zdroj pravdy. Pokud uživatel
  ručně přesune řádky, index a realita se rozejdou.
- **Developer metadata** (Sheets API mechanismus pro přiřazení metadat
  k řádku): nejčistší teoretické řešení, posouvá se s řádkem při
  insert/delete. Ale neviditelné v UI (horší debug), víc Sheets API
  kódu, horší recovery při rozbití. Stojí za zvážení v budoucnu,
  pokud scan Z:Z začne být limitní.

---

## Layout týdenního bloku

Denní tabulka vlevo, cíle/výsledek vpravo (varianta A). Lépe odděluje
klientský log od koučovacího vyhodnocení.

```text
┌──────────────────────────────────────────────────────────────┬──────────────────────────────┐
│ WEEK 39 — 27.4.2026–3.5.2026                                 │ CÍLE / VÝSLEDEK              │
├────────────┬──────┬──────┬──────┬──────┬─────┬──────┬───────┼──────────────┬─────┬─────────┤
│ Datum      │ Váha │ Kcal │ B    │ S    │ T   │ Vlákn│ Kroky │ Metrika      │ Cíl │ Průměr  │
├────────────┼──────┼──────┼──────┼──────┼─────┼──────┼───────┼──────────────┼─────┼─────────┤
│ Pondělí    │      │      │      │      │     │      │       │ Váha         │     │ =...    │
│ ...        │      │      │      │      │     │      │       │ ...          │     │ =...    │
└────────────┴──────┴──────┴──────┴──────┴─────┴──────┴───────┴──────────────┴─────┴─────────┘
```

### Sloupce

**Denní auto pole** (zapisuje appka):

```text
Datum | Váha | Kcal | Bílkoviny | Sacharidy | Tuky | Vláknina | Kroky
```

**Denní manual pole** (nikdy nepřepsáno re-exportem):

```text
Trénink (checkbox) | Hlad (dropdown) | Hydratace (dropdown) | Poznámka
```

**Target box metriky:** cílová váha, kcal, bílkoviny, sacharidy, tuky,
vláknina, kroky. Cíle jsou manual — po vytvoření bloku je appka
nikdy nepřepisuje. Průměr je Sheets vzorec.

Volitelně později: flag dne, spánek, usnutí, probuzení, aktivní kalorie,
sůl, cukry, nasycené tuky. Raw export už slouží jako kompletní datový
dump, takže coach log držíme úzký.

---

## Sheets vzorce

Appka při vytvoření bloku zapisuje vzorce pro průměry; při re-exportu
je nepřepisuje natvrdo vypočtenými hodnotami. Důvod: pokud kouč nebo
klient ručně opraví hodnotu, průměr se přepočítá automaticky.

Doporučený default:

```text
=IFERROR(AVERAGE(B{firstDayRow}:B{lastDayRow}), "")
```

`AVERAGE` ignoruje prázdné buňky, takže chybějící hodnoty zapsané jako
blank korektně nezatahují průměr dolů. To je důvod, proč invariant
"chybějící = blank, nikdy 0" musí platit.

---

## Modul / oddělení odpovědností

```text
BushidoExportProvider          → řídí workflow a sync
BushidoExportDataBuilder       → sestaví týdenní model z dostupných zdrojů
BushidoSheetsService           → zapisuje týdenní model do Google Sheets
BushidoSheetLayout/Style/Config → definuje strukturu a vzhled
```

Sync orchestrace patří do provideru/use-casu, ne do Sheets writeru.
Všechny barvy / sloupce / dropdown hodnoty / tolerance držet v configu.

### Domain modely

```dart
class BushidoDayRow {
  final DateTime date;
  final double? weightKg;
  final int? kcal;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final int? fiberG;
  final int? steps;
}

class BushidoWeekReport {
  final IsoWeek week;
  final DateTime startDate;
  final DateTime endDate;
  final List<BushidoDayRow> days; // vždy 7
}

class IsoWeek {
  final int year;
  final int weekNumber;
  final DateTime monday;
  final DateTime sunday;
  String get marker => 'BUSHIDO_WEEK:$year-W${weekNumber.toString().padLeft(2, '0')}';
}
```

`BushidoWeekReport.days` má vždy obsahovat 7 dní. Pokud data chybí,
hodnoty jsou `null`, ne `0`.

---

## Roadmap (mimo aktuální stav)

- **Manual UX v tabulce:** checkbox pro trénink, dropdown hlad,
  dropdown hydratace, poznámky klienta, feedback kouče.
- **Adherence a flagy:** conditional formatting podle cílů, volitelný
  `Flag dne` (OK / Zkontrolovat / Chybí data / Mimo plán),
  zvýraznění chybějících dat. Implementačně přes
  `spreadsheets.batchUpdate` + `AddConditionalFormatRuleRequest`.
  Pravidla do configu (`BushidoConditionalFormattingConfig`), ne
  natvrdo do servisu.
- **Import cílů od kouče do appky:** kouč vyplní cíle v Sheets, appka
  je načte, porovná s lokálními cíli, zobrazí diff, uživatel
  explicitně potvrdí. Nikdy automaticky přepisovat — kouč může
  hodnoty rozepsat jen pracovně, může dojít k omylu v buňce.
