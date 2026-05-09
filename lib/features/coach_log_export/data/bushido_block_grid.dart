import 'package:intl/intl.dart';

import 'package:forgetrack/features/coach_log_export/config/bushido_sheet_format_config.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_a1_notation.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_export_config.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_sheet_layout.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';

/// Builds the in-memory cell grid that's written into a week block.
///
/// The grid is `weekBlockHeight × 15` (A..O). Layout:
///   row 0 (headerRowOffset)        : week header (A) + 'CÍLE / VÝSLEDEK' (M)
///   row 1 (dailyHeaderRowOffset)   : daily column headers A..L + target headers M..O
///   rows 2..8 (firstDayRowOffset+) : day dates (A) + target metrics (M..O)
///   row 9 (averageRowOffset)       : 'Průměr' (A) + AVERAGE formulas B..H
///   rows 10..11                    : reserve (empty)
class BushidoBlockGrid {
  BushidoBlockGrid._();

  static String weekTitle(IsoWeek week) => 'Týden ${week.weekNumber}';

  static List<List<Object?>> build({
    required IsoWeek week,
    required int startRow,
  }) {
    const cols = 15; // A..O
    final grid = List.generate(
      BushidoSheetLayout.weekBlockHeight,
      (_) => List<Object?>.filled(cols, null, growable: false),
      growable: false,
    );

    final dateFmt = DateFormat('dd.MM.yyyy');
    final title = weekTitle(week);
    final mIndex = BushidoSheetLayout.targetBoxStartColumn - 1;

    grid[BushidoSheetLayout.headerRowOffset][0] = title;
    grid[BushidoSheetLayout.headerRowOffset][mIndex] = 'CÍLE / VÝSLEDEK';

    final dailyHeaderRow = grid[BushidoSheetLayout.dailyHeaderRowOffset];
    for (final col in BushidoColumn.values) {
      dailyHeaderRow[col.columnOffset] =
          col == BushidoColumn.date ? title : col.label;
    }
    dailyHeaderRow[mIndex] = BushidoSheetFormatConfig.coachFillHeaderLabel;
    dailyHeaderRow[mIndex + 1] = 'Cíl';
    dailyHeaderRow[mIndex + 2] = 'Výsledek';

    final firstDayAbsRow = startRow + BushidoSheetLayout.firstDayRowOffset;
    final lastDayAbsRow = firstDayAbsRow + BushidoSheetLayout.daysPerWeek - 1;
    for (var d = 0; d < BushidoSheetLayout.daysPerWeek; d++) {
      final rowGrid = grid[BushidoSheetLayout.firstDayRowOffset + d];
      final date = week.monday.add(Duration(days: d));
      rowGrid[BushidoColumn.date.columnOffset] = dateFmt.format(date);
    }

    for (var i = 0; i < BushidoExportConfig.targetMetrics.length; i++) {
      final metric = BushidoExportConfig.targetMetrics[i];
      final rowGrid = grid[BushidoSheetLayout.firstTargetMetricRowOffset + i];
      // M = label, N = goal (manual, blank), O = AVERAGE formula
      rowGrid[mIndex] = metric.label;
      rowGrid[mIndex + 1] = null;
      final col = columnLetter(metric.sourceColumn.columnOffset);
      final decimals = metric.sourceColumn == BushidoColumn.weightKg ? 1 : 0;
      rowGrid[mIndex + 2] =
          '=IFERROR(ROUND(AVERAGE($col$firstDayAbsRow:$col$lastDayAbsRow), $decimals), "")';
    }

    final avgRow = grid[BushidoSheetLayout.averageRowOffset];
    avgRow[BushidoColumn.date.columnOffset] = 'Průměr';
    for (final col in BushidoExportConfig.dailyAutoColumns) {
      if (col == BushidoColumn.date) continue;
      final letter = columnLetter(col.columnOffset);
      final decimals = col == BushidoColumn.weightKg ? 1 : 0;
      avgRow[col.columnOffset] =
          '=IFERROR(ROUND(AVERAGE($letter$firstDayAbsRow:$letter$lastDayAbsRow), $decimals), "")';
    }

    return grid;
  }
}
