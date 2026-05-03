# Bushido / Coach Log Export — návrh funkce

## Cíl

Vytvořit samostatný exportní režim vedle současného raw Google Sheets exportu.

Současný raw export zůstává jako „DB dump“ pro osobní analýzu, debugging a kompletní datový přehled. Nový **Bushido / Coach Log export** má řešit jiný use-case: týdenní report pro nutričního kouče a klienta.

Hlavní cíl není jen zapsat data do Google Sheets, ale vytvořit opakovatelný týdenní workflow:

- klient nemusí ručně přepisovat data,
- kouč dostane jednotný formát u všech klientů,
- ruční pole zůstávají flexibilní,
- data z appky se dají bezpečně opakovaně aktualizovat,
- chybějící týdny a dny zůstávají viditelné,
- později lze přidat adherence, flagy a import cílů zpět do appky.

---

## Základní produktový princip

Uživatel nemá řešit technické volby typu:

- obnovit Health Connect,
- obnovit Kalorické Tabulky,
- vytvořit nový blok,
- aktualizovat existující blok,
- připravit další týden.

Všechny tyto operace mají být automatické.

Doporučené UI akce:

```text
Coach Log / Bushido export

[ Exportovat aktuální týden ]

Vlastní rozsah:
Od: [datum]
Do: [datum]
[ Exportovat rozsah ]
```

Interně se při každém exportu provede:

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

## Export aktuálního týdne

Tlačítko „Exportovat aktuální týden“ by mělo aktualizovat celý aktuální ISO týden od pondělí do dneška.

Důvod:

- data za předchozí dny v aktuálním týdnu se mohou zpětně změnit,
- Health Connect může doplnit kroky/spánek později,
- Kalorické Tabulky mohou být doplněny zpětně,
- týdenní průměry se tím udrží aktuální.

Doporučené chování:

```dart
final today = dateOnly(DateTime.now());
final from = startOfIsoWeek(today);
final to = today;
await exportRange(from, to);
```

Budoucí dny aktuálního týdne se nemají vyplňovat nulami. Zůstanou prázdné.

---

## Export vlastního rozsahu

Vlastní rozsah slouží pro doplnění nebo opravu historie. Uživatel vybere libovolné datum od/do. Appka rozsah automaticky rozpadne na odpovídající ISO týdny.

Důležité pravidlo:

> Týdny bez dat se nesmí přeskočit. Musí vzniknout jako prázdné týdenní bloky.

Příklad:

```text
Vybraný rozsah: 10.4.2026–28.4.2026

Dotčené týdny:
- 2026-W15
- 2026-W16
- 2026-W17
- 2026-W18

Výsledek:
Appka vytvoří nebo aktualizuje všechny tyto týdny, i kdyby některý týden neměl žádná data.
```

Důvody:

- zachování chronologie,
- jednodušší pozdější doplnění,
- kouč vidí, že týden existuje, ale není vyplněný,
- export se chová jako kalendářní report, ne jako dump existujících záznamů,
- merge dat je stabilnější.

---

## Chování při opakovaném exportu

Export musí být idempotentní.

```text
Týdenní blok existuje    → aktualizovat automatická pole
Týdenní blok neexistuje → vytvořit blok
Ruční pole existují      → nikdy nepřepsat
Chybějící data           → zapsat prázdnou buňku, ne nulu
```

To znamená, že uživatel může export spustit denně bez rizika, že přepíše koučův feedback, cíle, poznámky, hlad, hydrataci nebo tréninkové checkboxy.

---

## Týdenní blok jako kalendářní jednotka

Týdenní blok reprezentuje ISO týden, ne jen sadu existujících záznamů.

Každý týdenní blok by měl mít stabilní identifikátor, například:

```text
BUSHIDO_WEEK:2026-W18
```

Možnosti uložení markeru:

1. skrytý sloupec, například `Z`,
2. Google Sheets developer metadata.

Pro MVP je jednodušší skrytý sloupec. Developer metadata je čistší, ale implementačně složitější.

Doporučená logika:

```dart
Future<void> exportRange(DateTime from, DateTime to) async {
  final normalizedFrom = dateOnly(from);
  final normalizedTo = dateOnly(to);

  await healthProvider.refreshRange(normalizedFrom, normalizedTo);
  await ktProvider.refreshRange(normalizedFrom, normalizedTo);

  final weeks = isoWeeksOverlapping(normalizedFrom, normalizedTo);

  for (final week in weeks) {
    final startRow = await sheetsService.ensureWeekBlock(week);

    await sheetsService.updateAutoCellsForWeek(
      week: week,
      startRow: startRow,
      range: DateRange(normalizedFrom, normalizedTo),
    );

    await sheetsService.ensureWeekFormulas(
      week: week,
      startRow: startRow,
    );
  }

  await sheetsService.ensureWeekBlock(nextIsoWeekAfter(normalizedTo));
}
```

---

## Chybějící data

Zásadní pravidlo:

```text
missing data = blank cell
real zero = 0
```

Nikdy nezapisovat `0` jako fallback pro chybějící hodnotu.

Příklady:

```text
KT den není vyplněný        → kcal/protein/carbs/fat/fiber prázdné
váha chybí                 → prázdná buňka
Health Connect bez záznamu → prázdná buňka
validní hodnota 0          → 0 pouze pokud je skutečně potvrzená nula
```

Důvod:

- Sheets `AVERAGE` ignoruje prázdné buňky,
- nuly by rozbily týdenní průměry,
- kouč rychle pozná, co není doplněné.

---

## Navržený layout týdne

Existují dvě dobré varianty. Rozhodnutí je vhodné ověřit s koučem.

### Varianta A — denní tabulka vlevo, cíle/průměry vedle

Výhody:

- jasné rozdělení klientská data vs. koučovací cíle,
- přehlednější pro kouče,
- méně zahlcená hlavní tabulka,
- dobře sedí na 7 dní + header.

Příklad:

```text
┌──────────────────────────────────────────────────────────────┬──────────────────────────────┐
│ WEEK 39 — 27.4.2026–3.5.2026                                 │ CÍLE / VÝSLEDEK              │
├────────────┬──────┬──────┬──────┬──────┬─────┬──────┬───────┼──────────────┬─────┬─────────┤
│ Datum      │ Váha │ Kcal │ B    │ S    │ T   │ Vlákn│ Kroky │ Metrika      │ Cíl │ Průměr  │
├────────────┼──────┼──────┼──────┼──────┼─────┼──────┼───────┼──────────────┼─────┼─────────┤
│ Pondělí    │      │      │      │      │     │      │       │ Váha         │     │ =...    │
│ Úterý      │      │      │      │      │     │      │       │ Kcal         │     │ =...    │
│ Středa     │      │      │      │      │     │      │       │ Bílkoviny    │     │ =...    │
│ Čtvrtek    │      │      │      │      │     │      │       │ Sacharidy    │     │ =...    │
│ Pátek      │      │      │      │      │     │      │       │ Tuky         │     │ =...    │
│ Sobota     │      │      │      │      │     │      │       │ Vláknina     │     │ =...    │
│ Neděle     │      │      │      │      │     │      │       │ Kroky        │     │ =...    │
├────────────┴──────┴──────┴──────┴──────┴─────┴──────┴───────┴──────────────┴─────┴─────────┤
│ PRŮMĚR / poznámky / feedback                                                               │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Varianta B — cíle jako řádek pod průměry

Výhody:

- méně redundantních popisků,
- kompaktnější struktura,
- jednodušší exportní layout,
- podobnější raw tabulce.

Nevýhody:

- vzniká jedna velká tabulka,
- méně jasné rozdělení mezi klientskými daty a koučovací částí,
- cíle nejsou tak vizuálně oddělené.

Příklad:

```text
Datum | Váha | Kcal | B | S | T | Vláknina | Kroky | Trénink | Hlad | Hydratace | Poznámka
Po
Út
St
Čt
Pá
So
Ne
Průměr
Cíl
```

### Doporučení pro MVP

Pro MVP bych mírně preferoval **variantu A**:

- denní tabulka vlevo,
- cíle/výsledek vpravo,
- dole volitelně ponechat řádek průměrů.

Důvod: lépe odděluje klientský log od koučovacího vyhodnocení. Pokud kouč preferuje jednodušší tabulku, lze přejít na variantu B bez změny základní datové logiky.

---

## Metriky pro cíle a týdenní výsledek

Do boxu cílů/průměrů zatím dávat pouze metriky, které coaching aktuálně řeší:

```text
Cílová váha
Kcal
Bílkoviny
Sacharidy
Tuky
Vláknina
Kroky
```

S headerem je to 8 řádků, což sedí vedle týdenní tabulky se 7 dny + headerem.

Spánek, hlad, hydrataci a tréninkové dny zatím nedávat do týdenních cílů, pokud je kouč aktivně nevyhodnocuje.

---

## Denní tabulka — doporučené sloupce MVP

Automatická pole:

```text
Datum
Váha
Kcal
Bílkoviny
Sacharidy
Tuky
Vláknina
Kroky
```

Ruční pole:

```text
Trénink
Hlad
Hydratace
Poznámka
```

Volitelně později:

```text
Flag dne
Spánek
Usnutí
Probuzení
Aktivní kalorie
Sůl
Cukry
Nasycené tuky
```

Pro MVP držet tabulku úzkou. Raw export už slouží jako kompletní datový dump.

---

## Týdenní průměry: Sheets vzorce vs. výpočet v appce

Doporučené řešení: **počítat průměry pomocí Sheets vzorců**, ne v appce.

Důvody:

- pokud kouč nebo klient ručně opraví hodnotu, průměr se přepočítá automaticky,
- pokud appka později doplní chybějící den, vzorec se přepočítá sám,
- méně aplikační logiky,
- jednodušší debugging,
- Google Sheets je pro tento typ výpočtů vhodný.

Appka má při vytvoření bloku vložit vzorce. Při re-exportu je může ověřit nebo obnovit, ale neměla by natvrdo zapisovat vypočtené výsledky.

Příklad:

```text
=AVERAGE(B3:B9)
=AVERAGE(C3:C9)
=AVERAGE(D3:D9)
```

Protože `AVERAGE` ignoruje prázdné buňky, je důležité zapisovat chybějící data jako prázdné buňky, ne jako nuly.

Poznámka: u váhy může být později vhodné zvážit, zda zobrazovat průměr, poslední hodnotu, trend nebo změnu mezi začátkem a koncem týdne. Pro MVP stačí průměr.

---

## Flag dne

„Flag dne“ je dobrý budoucí sloupec pro rychlou orientaci kouče.

Možný význam:

```text
OK
Zkontrolovat
Chybí data
Mimo plán
```

Pro MVP není nutné jej implementovat, ale layout by s ním měl počítat jako s volitelným sloupcem.

Příklady pravidel pro budoucnost:

```text
Chybí kcal nebo makra     → Chybí data
Kcal mimo toleranci       → Zkontrolovat
Protein výrazně pod cílem → Zkontrolovat
Kroky výrazně pod cílem   → Zkontrolovat
Jinak                     → OK
```

Flag lze řešit buď:

1. vzorcem přímo v Sheets,
2. zápisem hodnoty z appky,
3. podmíněným formátováním bez samostatného textového flagu.

Doporučení: nejdřív podmíněné formátování, později případně explicitní sloupec `Flag`.

---

## Podmíněné formátování

Ano, má smysl o tom přemýšlet. Google Sheets API podporuje conditional formatting přes `spreadsheets.batchUpdate` a `AddConditionalFormatRuleRequest`.

Doporučení:

- neimplementovat v MVP,
- layout a config připravit tak, aby šlo pravidla později přidat,
- pravidla mít v konfiguračním souboru, ne natvrdo v export servisu.

Budoucí příklady:

```text
Kcal ±5 % od cíle        → OK
Kcal ±10 % od cíle       → warning
Kcal mimo ±10 %          → alert
Protein >= 95 % cíle     → OK
Protein 85–95 % cíle     → warning
Protein < 85 % cíle      → alert
Kroky >= 100 % cíle      → OK
Kroky 80–100 % cíle      → warning
Kroky < 80 % cíle        → alert
```

Tolerance by měly být konfigurovatelné podle kouče/template.

---

## Styling a config

Formátování nemá být rozeseté v servisní třídě. Vytvořit samostatný config/layout soubor.

Doporučená struktura:

```text
features/sheets_export/
  domain/
    export_field_config.dart          // současný raw export order/config
    bushido_export_config.dart        // metriky, sloupce, ruční pole
    bushido_sheet_layout.dart         // layout pozice, offsets, velikosti bloků
    bushido_sheet_style.dart          // barvy, fonty, formáty, borders
```

Nebo při samostatné feature:

```text
features/coach_log_export/
  application/
    bushido_export_provider.dart

  domain/
    bushido_export_config.dart
    bushido_sheet_layout.dart
    bushido_sheet_style.dart
    bushido_week.dart
    bushido_day_row.dart
    iso_week.dart

  data/
    bushido_export_data_builder.dart
    bushido_sheets_service.dart
```

### `BushidoExportConfig`

Určuje, co exportovat a v jakém pořadí.

Příklad:

```dart
class BushidoExportConfig {
  static const dailyAutoColumns = [
    BushidoColumn.date,
    BushidoColumn.weightKg,
    BushidoColumn.kcal,
    BushidoColumn.proteinG,
    BushidoColumn.carbsG,
    BushidoColumn.fatG,
    BushidoColumn.fiberG,
    BushidoColumn.steps,
  ];

  static const dailyManualColumns = [
    BushidoColumn.training,
    BushidoColumn.hunger,
    BushidoColumn.hydration,
    BushidoColumn.note,
  ];

  static const targetMetrics = [
    BushidoTargetMetric.targetWeightKg,
    BushidoTargetMetric.kcal,
    BushidoTargetMetric.proteinG,
    BushidoTargetMetric.carbsG,
    BushidoTargetMetric.fatG,
    BushidoTargetMetric.fiberG,
    BushidoTargetMetric.steps,
  ];
}
```

### `BushidoSheetLayout`

Určuje souřadnice a velikost bloku.

Příklad:

```dart
class BushidoSheetLayout {
  static const hiddenMarkerColumn = 26; // Z

  static const weekBlockHeight = 12; // podle finálního layoutu upravit
  static const spacerRowsBetweenWeeks = 1;

  static const headerRowOffset = 0;
  static const dailyHeaderRowOffset = 1;
  static const firstDayRowOffset = 2;
  static const daysPerWeek = 7;
  static const averageRowOffset = 9;

  static const targetBoxStartColumn = 13;
  static const targetHeaderRowOffset = 1;
  static const firstTargetMetricRowOffset = 2;
}
```

### `BushidoSheetStyle`

Určuje styling.

Příklad:

```dart
class BushidoSheetStyle {
  static const headerBackground = '#D97763';
  static const headerText = '#FFFFFF';
  static const bodyBackground = '#F5E6A8';
  static const manualBackground = '#FCE7A3';
  static const targetBackground = '#E8B4AA';

  static const fontFamily = 'Arial';
  static const headerBold = true;
}
```

Konkrétní barvy zatím ponechat jako placeholder a doladit s koučem podle designu coachingu.

---

## Ruční buňky a ochrana před přepsáním

Při aktualizaci existujícího týdne zapisovat pouze automatické rozsahy.

Příklad:

```text
Denní auto columns:   A:H
Denní manual columns: I:L

Re-export smí zapisovat A:H.
Re-export nesmí zapisovat I:L.
```

Cíle:

```text
Metrika   → lze zapsat při vytvoření bloku
Cíl       → ruční, po vytvoření nikdy nepřepisovat
Průměr    → vzorec, lze obnovit/ověřit
```

Pokud se blok vytváří poprvé, appka může vyplnit názvy metrik a prázdné cílové buňky. Při dalších exportech nechá cílové buňky nedotčené.

---

## Dropdowny a checkboxy

MVP ruční pole:

### Trénink

Google Sheets checkbox.

Hodnoty:

```text
TRUE/FALSE
```

### Hlad

Dropdown, například:

```text
Nízký hlad
Průměrný pocit hladu
Vysoký hlad
```

### Hydratace

Dropdown, například:

```text
Nedostatečná
Částečně hydratovaný
Hydratovaný
Velmi hydratovaný
```

Přesné hodnoty doladit s koučem.

Důležité: dropdown hodnoty dát do configu, ne natvrdo do service.

---

## Data builder

Exportní service by neměla sama tahat data z providerů a zároveň řešit layout. Doporučené oddělení:

```text
BushidoExportProvider
  → řídí workflow a sync

BushidoExportDataBuilder
  → sestaví týdenní model z dostupných zdrojů

BushidoSheetsService
  → zapisuje týdenní model do Google Sheets

BushidoSheetLayout / Style / Config
  → definuje strukturu a vzhled
```

Doporučené doménové modely:

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
```

```dart
class BushidoWeekReport {
  final IsoWeek week;
  final DateTime startDate;
  final DateTime endDate;
  final List<BushidoDayRow> days; // always 7 rows
}
```

```dart
class IsoWeek {
  final int year;
  final int weekNumber;
  final DateTime monday;
  final DateTime sunday;

  String get marker => 'BUSHIDO_WEEK:$year-W${weekNumber.toString().padLeft(2, '0')}';
}
```

`BushidoWeekReport.days` má vždy obsahovat 7 dní. Pokud data chybí, hodnoty jsou `null`, ne `0`.

---

## Sheets vzorce

Appka by při vytvoření bloku měla zapisovat vzorce pro průměry.

Příklad pro daily table:

```text
A: Datum
B: Váha
C: Kcal
D: Bílkoviny
E: Sacharidy
F: Tuky
G: Vláknina
H: Kroky
```

Průměrový řádek:

```text
B_avg = =AVERAGE(B{firstDayRow}:B{lastDayRow})
C_avg = =AVERAGE(C{firstDayRow}:C{lastDayRow})
...
```

Target box:

```text
Váha      target manual      =AVERAGE(B{firstDayRow}:B{lastDayRow})
Kcal      target manual      =AVERAGE(C{firstDayRow}:C{lastDayRow})
Protein   target manual      =AVERAGE(D{firstDayRow}:D{lastDayRow})
Carbs     target manual      =AVERAGE(E{firstDayRow}:E{lastDayRow})
Fat       target manual      =AVERAGE(F{firstDayRow}:F{lastDayRow})
Fiber     target manual      =AVERAGE(G{firstDayRow}:G{lastDayRow})
Steps     target manual      =AVERAGE(H{firstDayRow}:H{lastDayRow})
```

Později lze nahradit robustnějšími vzorci typu `IFERROR`, například:

```text
=IFERROR(AVERAGE(C3:C9), "")
```

To zabrání zobrazování chyb, pokud je celý týden prázdný.

Doporučený default:

```text
=IFERROR(AVERAGE(range), "")
```

---

## Conditional formatting — budoucí návrh

Podmíněné formátování řešit přes Google Sheets API až po stabilizaci layoutu.

Implementačně přes:

```text
spreadsheets.batchUpdate
AddConditionalFormatRuleRequest
```

Pravidla dát do configu, například:

```dart
class BushidoConditionalFormattingConfig {
  static const kcalToleranceOk = 0.05;
  static const kcalToleranceWarning = 0.10;

  static const proteinOkRatio = 0.95;
  static const proteinWarningRatio = 0.85;

  static const stepsOkRatio = 1.00;
  static const stepsWarningRatio = 0.80;
}
```

Nad tím lze později postavit i `Flag dne`.

---

## Import cílů od kouče do appky — future TODO

Toto nedávat do MVP, ale připravit jako budoucí směr.

### Cíl

Kouč vyplní cíle v Google Sheets a appka je později umí načíst a nabídnout uživateli k aplikování do lokálních cílů.

### Doporučené chování

1. Appka načte target box z aktuálního nebo příštího týdne.
2. Validuje hodnoty.
3. Porovná je s aktuálními cíli v appce.
4. Zobrazí diff.
5. Uživatel explicitně potvrdí import.
6. Appka aktualizuje lokální cíle.

Nedoporučuje se automaticky přepisovat cíle bez potvrzení.

Důvody:

- kouč může hodnoty rozepsat jen pracovně,
- může dojít k omylu v buňce,
- klient může mít v appce vlastní cíle,
- automatický import by mohl být překvapivý.

### Příklad UX

```text
Našli jsme nové cíle od kouče pro týden 2026-W18.

Kcal:       2700 → 2650
Bílkoviny:  220 → 230
Sacharidy:  300 → 275
Tuky:        80 → 70
Vláknina:    25 → 35
Kroky:     8000 → 8500

[ Použít cíle v appce ]
[ Ignorovat ]
```

### Technické TODO

```text
TODO future:
- přidat CoachTargetImportService
- načíst target cells z aktuálního/next week blocku
- validovat numeric hodnoty
- namapovat Sheets metriky na app goal model
- zobrazit diff uživateli
- po potvrzení uložit do app goals provideru
- uložit timestamp posledního importu
- řešit konflikt, pokud se cíle v appce změnily po posledním importu
```

---

## Doporučený MVP rozsah

### MVP 1 — základní Coach Log export

- samostatný exportní flow vedle raw exportu,
- dvě akce: aktuální týden, vlastní rozsah,
- automatický Health + KT sync,
- ISO week split,
- vytvoření všech týdnů v rozsahu včetně týdnů bez dat,
- vytvoření jednoho dalšího prázdného týdne,
- marker týdne ve skrytém sloupci,
- idempotentní update existujících týdnů,
- zápis jen automatických buněk,
- ruční buňky nedotčené,
- chybějící hodnoty jako blank,
- Sheets vzorce pro průměry,
- základní styling přes config.

### MVP 2 — ruční UX v tabulce

- checkbox pro trénink,
- dropdown hlad,
- dropdown hydratace,
- poznámky klienta,
- případně feedback/poznámka kouče.

### MVP 3 — adherence a flagy

- conditional formatting podle cílů,
- volitelný `Flag dne`,
- zvýraznění chybějících dat,
- zvýraznění dnů mimo plán.

### Future — import cílů

- čtení cílů z Google Sheets,
- diff vůči appce,
- potvrzený import uživatelem,
- aktualizace lokálních cílů.

---

## Implementační poznámky pro code model

- Neměnit chování současného raw exportu.
- Nepřetěžovat `SheetsExportService` coach-specific layoutem.
- Přidat samostatný `BushidoExportProvider` / `CoachLogExportProvider`.
- Přidat samostatný `BushidoSheetsService` / `CoachLogSheetsService`.
- Reuse existující autentizaci a Google Sheets klienta.
- Reuse existující data source/read modely, ale layout držet odděleně.
- Sync orchestrace patří do provideru/use-casu, ne do Sheets writeru.
- Všechny barvy/sloupce/dropdown hodnoty/tolerance držet v configu.
- Ruční rozsahy nesmí být při re-exportu zapisované.
- Každý týdenní report má vždy 7 denních řádků.
- Týdny bez dat se vytváří jako prázdné bloky.
- Průměry primárně řešit Sheets vzorci.
- Chybějící hodnoty zapisovat jako blank, nikdy jako fallback 0.

---

## Shrnutí

Coach Log export má být samostatný kalendářní reportovací workflow, ne upravený raw export.

Finální směr:

```text
Raw export = kompletní datový dump pro uživatele/appku.
Coach Log export = přehledný týdenní report pro kouče a klienta.
```

Uživatel spustí export aktuálního týdne nebo vlastního rozsahu. Appka automaticky zajistí sync, vytvoření týdnů, merge dat, zachování ručních polí a přípravu dalšího týdne.

Týdenní blok má ideálně kombinovat denní tabulku a box cíl vs. výsledek. Chybějící data zůstávají prázdná. Průměry řeší Sheets vzorce. Formátování a budoucí adherence pravidla mají být konfigurovatelné.
