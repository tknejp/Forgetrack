// Single-language (cs) export target — the Czech labels below are the on-sheet
// column / metric headers the coach reads in Google Sheets, not localizable UI
// strings. Treated as a documented exception to the project-wide ARB pattern.

// Sloupce denní tabulky, 0-indexed od levého okraje bloku (sloupec A = offset 0).
enum BushidoColumn {
  date(label: 'Datum', isAuto: true, columnOffset: 0),
  weightKg(label: 'Váha', isAuto: true, columnOffset: 1),
  kcal(label: 'Kcal', isAuto: true, columnOffset: 2),
  proteinG(label: 'Bílkoviny', isAuto: true, columnOffset: 3),
  carbsG(label: 'Sacharidy', isAuto: true, columnOffset: 4),
  fatG(label: 'Tuky', isAuto: true, columnOffset: 5),
  fiberG(label: 'Vláknina', isAuto: true, columnOffset: 6),
  steps(label: 'Kroky', isAuto: true, columnOffset: 7),
  training(label: 'Trénink', isAuto: false, columnOffset: 8),
  hunger(label: 'Hlad', isAuto: false, columnOffset: 9),
  hydration(label: 'Hydratace', isAuto: false, columnOffset: 10),
  note(label: 'Poznámka', isAuto: false, columnOffset: 11);

  const BushidoColumn({
    required this.label,
    required this.isAuto,
    required this.columnOffset,
  });

  final String label;
  final bool isAuto;

  // 0-indexed offset od začátku bloku: date=0(A), weightKg=1(B), …, note=11(L).
  final int columnOffset;

  bool get isManual => !isAuto;
}

// Metriky zobrazené v target boxu vpravo od denní tabulky.
// sourceColumn odkazuje na sloupec, ze kterého Sheets sestaví AVERAGE vzorec (Fáze 3a).
enum BushidoTargetMetric {
  targetWeightKg(label: 'Cílová váha', sourceColumn: BushidoColumn.weightKg),
  kcal(label: 'Kcal', sourceColumn: BushidoColumn.kcal),
  proteinG(label: 'Bílkoviny', sourceColumn: BushidoColumn.proteinG),
  carbsG(label: 'Sacharidy', sourceColumn: BushidoColumn.carbsG),
  fatG(label: 'Tuky', sourceColumn: BushidoColumn.fatG),
  fiberG(label: 'Vláknina', sourceColumn: BushidoColumn.fiberG),
  steps(label: 'Kroky', sourceColumn: BushidoColumn.steps);

  const BushidoTargetMetric({
    required this.label,
    required this.sourceColumn,
  });

  final String label;
  final BushidoColumn sourceColumn;
}

class BushidoExportConfig {
  BushidoExportConfig._();

  static const List<BushidoColumn> dailyAutoColumns = [
    BushidoColumn.date,
    BushidoColumn.weightKg,
    BushidoColumn.kcal,
    BushidoColumn.proteinG,
    BushidoColumn.carbsG,
    BushidoColumn.fatG,
    BushidoColumn.fiberG,
    BushidoColumn.steps,
  ];

  static const List<BushidoColumn> dailyManualColumns = [
    BushidoColumn.training,
    BushidoColumn.hunger,
    BushidoColumn.hydration,
    BushidoColumn.note,
  ];

  static const List<BushidoTargetMetric> targetMetrics = [
    BushidoTargetMetric.targetWeightKg,
    BushidoTargetMetric.kcal,
    BushidoTargetMetric.proteinG,
    BushidoTargetMetric.carbsG,
    BushidoTargetMetric.fatG,
    BushidoTargetMetric.fiberG,
    BushidoTargetMetric.steps,
  ];

  // Hodnoty pro hlad dropdown. Přesné znění doladit s koučem v Fázi 6.
  static const List<String> hungerOptions = [
    'Nízký hlad',
    'Průměrný pocit hladu',
    'Vysoký hlad',
  ];

  // Hodnoty pro hydrataci dropdown. Přesné znění doladit s koučem v Fázi 6.
  static const List<String> hydrationOptions = [
    'Nedostatečná',
    'Částečně hydratovaný',
    'Hydratovaný',
    'Velmi hydratovaný',
  ];
}
