class BushidoSheetLayout {
  BushidoSheetLayout._();

  // Verze layoutu — nese se v markeru týdenního bloku (BUSHIDO_WEEK:{week}:v1).
  // Povýšit na 'v2' při změně výšky bloku nebo offsetů, aby ensureWeekBlock
  // rozpoznal nekompatibilní starý blok.
  static const String layoutVersion = 'v1';

  // Marker pro záhlaví sheetu (zapsaný do Z1 po prvním vytvoření).
  static const String headerMarker = 'BUSHIDO_HEADER:v1';

  // Počet řádků vyhrazených pro stickovaný záhlaví (profil + Aktuální týden).
  // Týdenní bloky začínají od řádku headerRows + 1.
  static const int headerRows = 8;

  // Sloupec Z (1-indexed) obsahuje marker týdenního bloku v řádku headeru.
  static const int hiddenMarkerColumn = 26;

  // Celková výška týdenního bloku v řádcích:
  // 0 header týdne + 1 header sloupců + 7 dní + 1 průměrový řádek + 1 spacer uvnitř + 2 rezerva = 12.
  // TODO: doladit s koučem v Fázi 6.
  static const int weekBlockHeight = 12;

  // Počet prázdných řádků mezi bloky (za posledním řádkem bloku).
  static const int spacerRowsBetweenWeeks = 1;

  // Offsety řádků uvnitř bloku (0 = první řádek bloku).
  static const int headerRowOffset = 0;
  static const int dailyHeaderRowOffset = 1;
  static const int firstDayRowOffset = 2;
  static const int daysPerWeek = 7;
  static const int averageRowOffset = 9; // firstDayRowOffset + daysPerWeek

  // Target box (cíle / průměry) — začíná sloupcem M (1-indexed = 13).
  // TODO: doladit s koučem v Fázi 6.
  static const int targetBoxStartColumn = 13;
  static const int targetHeaderRowOffset = 1;
  static const int firstTargetMetricRowOffset = 2;
}
