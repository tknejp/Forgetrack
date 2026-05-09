import 'package:googleapis/sheets/v4.dart' as sheets;

import 'package:forgetrack/features/coach_log_export/config/bushido_sheet_format_config.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_a1_notation.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_export_config.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_sheet_layout.dart';

/// Builds Sheets API `Request` objects for everything formatting-related on
/// the Coach Log tab: sticky header, per-week block formatting, dropdown /
/// checkbox validations, and per-metric conditional formatting.
///
/// Pure: no I/O, no state. Each `build…` method returns a list of requests
/// that the caller bundles into a `batchUpdate`.
class BushidoFormatRequests {
  BushidoFormatRequests._();

  // ─── Sheet-level (sticky header zone) ─────────────────────────────────────

  /// Frozen header rows + black background + profile box + logo slot +
  /// header-zone text styling. Run once when the sheet is bootstrapped.
  static List<sheets.Request> buildHeaderFormat(int sheetId) {
    return [
      sheets.Request(
        updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
          fields: 'gridProperties.frozenRowCount,gridProperties.hideGridlines',
          properties: sheets.SheetProperties(
            sheetId: sheetId,
            gridProperties: sheets.GridProperties(
              frozenRowCount: BushidoSheetLayout.headerRows,
              hideGridlines: true,
            ),
          ),
        ),
      ),
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 0,
            endRowIndex: BushidoSheetLayout.headerRows,
            startColumnIndex: 0,
            endColumnIndex: 26,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColorStyle:
                  _styleColor(BushidoSheetFormatConfig.sheetBackground),
              textFormat: sheets.TextFormat(
                fontFamily: BushidoSheetFormatConfig.fontMostserrat,
              ),
            ),
          ),
          fields:
              'userEnteredFormat.backgroundColorStyle,userEnteredFormat.textFormat.fontFamily',
        ),
      ),
      // Logo slot: A2:B7 merged + centered.
      sheets.Request(
        unmergeCells: sheets.UnmergeCellsRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 1,
            endRowIndex: 7,
            startColumnIndex: 0,
            endColumnIndex: 2,
          ),
        ),
      ),
      sheets.Request(
        mergeCells: sheets.MergeCellsRequest(
          mergeType: 'MERGE_ALL',
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 1,
            endRowIndex: 7,
            startColumnIndex: 0,
            endColumnIndex: 2,
          ),
        ),
      ),
      _formatCells(
        sheetId: sheetId,
        startRow0: 1,
        endRow0: 7,
        startCol: 0,
        endCol: 2,
        center: true,
      ),
      // Profile labels (C3:C{n}) and values (D3:D{n}).
      _formatCells(
        sheetId: sheetId,
        startRow0: 2,
        endRow0: 2 + BushidoSheetFormatConfig.profileLabels.length,
        startCol: 2,
        endCol: 3,
        backgroundColor: _styleColor(BushidoSheetFormatConfig.profileLabel),
        textColor: _styleColor(BushidoSheetFormatConfig.black),
        fontFamily: BushidoSheetFormatConfig.fontMostserrat,
        center: true,
        borders: _solidBorders(BushidoSheetFormatConfig.black),
      ),
      _formatCells(
        sheetId: sheetId,
        startRow0: 2,
        endRow0: 2 + BushidoSheetFormatConfig.profileLabels.length,
        startCol: 3,
        endCol: 4,
        backgroundColor: _styleColor(BushidoSheetFormatConfig.profileValue),
        textColor: _styleColor(BushidoSheetFormatConfig.black),
        fontFamily: BushidoSheetFormatConfig.fontMostserrat,
        center: true,
        borders: _solidBorders(BushidoSheetFormatConfig.black),
      ),
      // "Aktuální týden:" hyperlink at D7 — override link color to dark berry.
      _formatCells(
        sheetId: sheetId,
        startRow0: 6,
        endRow0: 7,
        startCol: 3,
        endCol: 4,
        textColor: _styleColor(BushidoSheetFormatConfig.darkBerry),
        bold: true,
      ),
      // Widen column C (profile labels) and column L (Poznámka).
      _columnWidthRequest(sheetId: sheetId, columnIndex: 2, pixelSize: 170),
      _columnWidthRequest(sheetId: sheetId, columnIndex: 11, pixelSize: 280),
    ];
  }

  // ─── Per-week block formatting ────────────────────────────────────────────

  /// Per-week formatting. We intentionally avoid the Sheets `Table` object:
  /// repeated AddTableRequest + per-zone formatting has been the source of
  /// intermittent API 500s. Normal cell formatting is less fancy but reliable
  /// and still preserves dropdown/checkbox validations.
  static List<sheets.Request> buildBlockFormat({
    required int sheetId,
    required int startRow,
  }) {
    final wHdr0 = startRow - 1 + BushidoSheetLayout.dailyHeaderRowOffset;
    final wFtr0 = startRow - 1 + BushidoSheetLayout.averageRowOffset;

    final tHdr0 = startRow - 1 + BushidoSheetLayout.targetHeaderRowOffset;
    final tDataEnd0 = startRow -
        1 +
        BushidoSheetLayout.firstTargetMetricRowOffset +
        BushidoExportConfig.targetMetrics.length;

    final csRedBerry = _styleColor(BushidoSheetFormatConfig.weeklyHeader);
    final csFooter = _styleColor(BushidoSheetFormatConfig.weeklyFooter);
    final csGray = _styleColor(BushidoSheetFormatConfig.bodyGray);
    final csGrayDark = _styleColor(BushidoSheetFormatConfig.bodyGrayDark);
    final csTargetHdr = _styleColor(BushidoSheetFormatConfig.targetHeader);
    final csWhite = _styleColor(BushidoSheetFormatConfig.white);
    final csNote = _styleColor(BushidoSheetFormatConfig.noteBody);

    final blockStart0 = startRow - 1;
    final blockEnd0 = blockStart0 +
        BushidoSheetLayout.weekBlockHeight +
        BushidoSheetLayout.spacerRowsBetweenWeeks;

    return [
      _baseBackgroundRequest(
        sheetId: sheetId,
        startRow0: blockStart0,
        endRow0: blockEnd0,
      ),
      sheets.Request(
        updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
          range: sheets.DimensionRange(
            sheetId: sheetId,
            dimension: 'ROWS',
            startIndex: wHdr0,
            endIndex: wFtr0 + 1,
          ),
          properties: sheets.DimensionProperties(
            pixelSize: BushidoSheetFormatConfig.tableRowHeightPx,
          ),
          fields: 'pixelSize',
        ),
      ),
      // Weekly table header (red).
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0,
        endRow0: wHdr0 + 1,
        startCol: 0,
        endCol: 12,
        backgroundColor: csRedBerry,
        textColor: csWhite,
        bold: true,
        fontFamily: BushidoSheetFormatConfig.fontOswald,
        fontSize: BushidoSheetFormatConfig.tableHeaderFontSize,
        center: true,
      ),
      // Date column body — Oswald bold, white bg.
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0 + 1,
        endRow0: wFtr0,
        startCol: BushidoColumn.date.columnOffset,
        endCol: BushidoColumn.date.columnOffset + 1,
        backgroundColor: csWhite,
        fontFamily: BushidoSheetFormatConfig.fontOswald,
        bold: true,
        center: true,
      ),
      // Auto metric columns (B..H) — gray body.
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0 + 1,
        endRow0: wFtr0,
        startCol: BushidoColumn.weightKg.columnOffset,
        endCol: BushidoColumn.steps.columnOffset + 1,
        backgroundColor: csGray,
        fontFamily: BushidoSheetFormatConfig.fontMostserrat,
        center: true,
      ),
      // Manual training/hunger/hydration columns — white body.
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0 + 1,
        endRow0: wFtr0,
        startCol: BushidoColumn.training.columnOffset,
        endCol: BushidoColumn.hydration.columnOffset + 1,
        backgroundColor: csWhite,
        fontFamily: BushidoSheetFormatConfig.fontMostserrat,
        center: true,
      ),
      // Note column — pale yellow body, left-aligned (not centered).
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0 + 1,
        endRow0: wFtr0,
        startCol: BushidoColumn.note.columnOffset,
        endCol: BushidoColumn.note.columnOffset + 1,
        backgroundColor: csNote,
        fontFamily: BushidoSheetFormatConfig.fontMostserrat,
      ),
      // Target body — M label column: darker gray + Oswald bold.
      _formatCells(
        sheetId: sheetId,
        startRow0: tHdr0 + 1,
        endRow0: tDataEnd0,
        startCol: 12,
        endCol: 13,
        backgroundColor: csGrayDark,
        bold: true,
        fontFamily: BushidoSheetFormatConfig.fontOswald,
        center: true,
      ),
      // Target body — N..O value columns: regular gray.
      _formatCells(
        sheetId: sheetId,
        startRow0: tHdr0 + 1,
        endRow0: tDataEnd0,
        startCol: 13,
        endCol: 15,
        backgroundColor: csGray,
        fontFamily: BushidoSheetFormatConfig.fontMostserrat,
        center: true,
      ),
      // Weekly table footer (Průměr).
      _formatCells(
        sheetId: sheetId,
        startRow0: wFtr0,
        endRow0: wFtr0 + 1,
        startCol: 0,
        endCol: 12,
        backgroundColor: csFooter,
        textColor: csWhite,
        bold: true,
        fontFamily: BushidoSheetFormatConfig.fontOswald,
        fontSize: BushidoSheetFormatConfig.tableHeaderFontSize,
        center: true,
      ),
      // Target table header — white bold 12pt.
      _formatCells(
        sheetId: sheetId,
        startRow0: tHdr0,
        endRow0: tHdr0 + 1,
        startCol: 12,
        endCol: 15,
        backgroundColor: csTargetHdr,
        textColor: csWhite,
        bold: true,
        fontFamily: BushidoSheetFormatConfig.fontOswald,
        fontSize: BushidoSheetFormatConfig.tableHeaderFontSize,
        center: true,
      ),
      // Target table footer.
      _formatCells(
        sheetId: sheetId,
        startRow0: wFtr0,
        endRow0: wFtr0 + 1,
        startCol: 12,
        endCol: 15,
        backgroundColor: csTargetHdr,
        textColor: csWhite,
        bold: true,
        fontFamily: BushidoSheetFormatConfig.fontOswald,
        fontSize: BushidoSheetFormatConfig.tableHeaderFontSize,
        center: true,
      ),
      // Center alignment across the whole weekly table area.
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0,
        endRow0: wFtr0 + 1,
        startCol: 0,
        endCol: 12,
        center: true,
      ),
      // Center alignment across the whole target table area.
      _formatCells(
        sheetId: sheetId,
        startRow0: tHdr0,
        endRow0: tDataEnd0,
        startCol: 12,
        endCol: 15,
        center: true,
      ),
      // Header-zone tweaks reapplied on every export so existing sheets pick
      // them up (ensureSheetHeader is a no-op once Z1 marker exists).
      _columnWidthRequest(sheetId: sheetId, columnIndex: 2, pixelSize: 170),
      _columnWidthRequest(sheetId: sheetId, columnIndex: 11, pixelSize: 280),
      _formatCells(
        sheetId: sheetId,
        startRow0: 6,
        endRow0: 7,
        startCol: 3,
        endCol: 4,
        textColor: _styleColor(BushidoSheetFormatConfig.darkBerry),
        bold: true,
      ),
      // Outer border around the weekly table — same color as its header.
      _outerBorderRequest(
        sheetId: sheetId,
        startRow0: wHdr0,
        endRow0: wFtr0 + 1,
        startCol: 0,
        endCol: 12,
        color: BushidoSheetFormatConfig.weeklyHeader,
      ),
      // Outer border around the target table — same color as its header.
      _outerBorderRequest(
        sheetId: sheetId,
        startRow0: tHdr0,
        endRow0: tDataEnd0 + 1,
        startCol: 12,
        endCol: 15,
        color: BushidoSheetFormatConfig.targetHeader,
      ),
    ];
  }

  // ─── Data validations (checkbox + dropdowns) ──────────────────────────────

  static List<sheets.Request> buildValidations({
    required int sheetId,
    required int startRow,
  }) {
    final firstDayIndex0 = startRow + BushidoSheetLayout.firstDayRowOffset - 1;
    final endRowIndex0 = firstDayIndex0 + BushidoSheetLayout.daysPerWeek;

    sheets.GridRange columnRange(int columnOffset) => sheets.GridRange(
          sheetId: sheetId,
          startRowIndex: firstDayIndex0,
          endRowIndex: endRowIndex0,
          startColumnIndex: columnOffset,
          endColumnIndex: columnOffset + 1,
        );

    sheets.Request listValidation(
      int columnOffset,
      List<String> options,
    ) =>
        sheets.Request(
          setDataValidation: sheets.SetDataValidationRequest(
            range: columnRange(columnOffset),
            rule: sheets.DataValidationRule(
              condition: sheets.BooleanCondition(
                type: 'ONE_OF_LIST',
                values: options
                    .map((o) => sheets.ConditionValue(userEnteredValue: o))
                    .toList(),
              ),
              strict: true,
              showCustomUi: true,
            ),
          ),
        );

    return [
      sheets.Request(
        setDataValidation: sheets.SetDataValidationRequest(
          range: columnRange(BushidoColumn.training.columnOffset),
          rule: sheets.DataValidationRule(
            condition: sheets.BooleanCondition(type: 'BOOLEAN'),
            strict: true,
            showCustomUi: true,
          ),
        ),
      ),
      listValidation(
        BushidoColumn.hunger.columnOffset,
        BushidoExportConfig.hungerOptions,
      ),
      listValidation(
        BushidoColumn.hydration.columnOffset,
        BushidoExportConfig.hydrationOptions,
      ),
    ];
  }

  // ─── Conditional formatting (per-metric goal completion) ──────────────────

  /// Per-metric `addConditionalFormatRule` requests that color the result
  /// cell (O column) and daily input cells based on how close the value is to
  /// its goal in column N.
  ///
  /// Bands (default — kcal, carbs, fat, fiber, steps):
  ///   95–105 % → green, 85–95 % or 105–115 % → yellow, else → red.
  /// Protein (`upperOpenEnded`):
  ///   ≥95 % → green, 85–95 % → yellow, <85 % → red. Above 100 % stays green.
  ///
  /// Daily cells get only the red rule so the table stays readable; problem
  /// days still pop without a chaotic per-cell heatmap.
  ///
  /// Weight is intentionally skipped — % deviation isn't useful there.
  ///
  /// Only called from append/insert paths. Re-formatting an existing week
  /// does NOT re-add these rules (Sheets has no upsert for conditional rules,
  /// so re-applying would duplicate).
  static List<sheets.Request> buildConditionalFormat({
    required int sheetId,
    required int startRow,
  }) {
    final firstDayRow = startRow + BushidoSheetLayout.firstDayRowOffset;
    final lastDayRow = firstDayRow + BushidoSheetLayout.daysPerWeek - 1;
    final mIndex0 = BushidoSheetLayout.targetBoxStartColumn - 1;
    final goalColLetter = columnLetter(mIndex0 + 1); // N
    final resultCol0 = mIndex0 + 2; // O

    final requests = <sheets.Request>[];

    for (var i = 0; i < BushidoExportConfig.targetMetrics.length; i++) {
      final metric = BushidoExportConfig.targetMetrics[i];
      // Weight: % deviation is misleading near the goal — skip for now.
      if (metric == BushidoTargetMetric.targetWeightKg) continue;

      final goalRow =
          startRow + BushidoSheetLayout.firstTargetMetricRowOffset + i;
      final goalRef = '\$$goalColLetter\$$goalRow';
      final colIdx0 = metric.sourceColumn.columnOffset;
      final colLetter = columnLetter(colIdx0);
      final upperOpenEnded = metric == BushidoTargetMetric.proteinG;

      final resultRange = sheets.GridRange(
        sheetId: sheetId,
        startRowIndex: goalRow - 1,
        endRowIndex: goalRow,
        startColumnIndex: resultCol0,
        endColumnIndex: resultCol0 + 1,
      );
      final dailyRange = sheets.GridRange(
        sheetId: sheetId,
        startRowIndex: firstDayRow - 1,
        endRowIndex: lastDayRow,
        startColumnIndex: colIdx0,
        endColumnIndex: colIdx0 + 1,
      );

      // CUSTOM_FORMULA references the top-left cell of each range relatively;
      // Sheets adapts it per cell when the range spans multiple rows.
      final resultTopLeft = '${columnLetter(resultCol0)}$goalRow';
      final dailyTopLeft = '$colLetter$firstDayRow';

      // Full 3-band rules on the result cell (O).
      requests.add(_conditionalRule(
        range: resultRange,
        formula: _greenFormula(resultTopLeft, goalRef,
            upperOpenEnded: upperOpenEnded),
        bg: BushidoSheetFormatConfig.condGood,
      ));
      requests.add(_conditionalRule(
        range: resultRange,
        formula: _yellowFormula(resultTopLeft, goalRef,
            upperOpenEnded: upperOpenEnded),
        bg: BushidoSheetFormatConfig.condWarn,
      ));
      requests.add(_conditionalRule(
        range: resultRange,
        formula: _redFormula(resultTopLeft, goalRef,
            upperOpenEnded: upperOpenEnded),
        bg: BushidoSheetFormatConfig.condBad,
      ));

      // Daily input cells — only the red band, kept subtle.
      requests.add(_conditionalRule(
        range: dailyRange,
        formula: _redFormula(dailyTopLeft, goalRef,
            upperOpenEnded: upperOpenEnded),
        bg: BushidoSheetFormatConfig.condBad,
      ));
    }
    return requests;
  }

  // ─── Internal: cell payload + cell helpers ────────────────────────────────

  /// Wraps a primitive into a `CellData` userEnteredValue for atomic writes.
  /// Strings starting with `=` become formulas.
  static sheets.CellData toCellData(Object? value) {
    if (value == null) return sheets.CellData();
    if (value is String) {
      if (value.startsWith('=')) {
        return sheets.CellData(
          userEnteredValue: sheets.ExtendedValue(formulaValue: value),
        );
      }
      return sheets.CellData(
        userEnteredValue: sheets.ExtendedValue(stringValue: value),
      );
    }
    if (value is num) {
      return sheets.CellData(
        userEnteredValue: sheets.ExtendedValue(numberValue: value.toDouble()),
      );
    }
    if (value is bool) {
      return sheets.CellData(
        userEnteredValue: sheets.ExtendedValue(boolValue: value),
      );
    }
    return sheets.CellData(
      userEnteredValue: sheets.ExtendedValue(stringValue: value.toString()),
    );
  }

  // ─── Conditional formula helpers ─────────────────────────────────────────

  static String _greenFormula(
    String cell,
    String goal, {
    required bool upperOpenEnded,
  }) {
    if (upperOpenEnded) {
      return '=AND(ISNUMBER($cell), $goal>0, $cell>=$goal*0.95)';
    }
    return '=AND(ISNUMBER($cell), $goal>0, '
        '$cell/$goal>=0.95, $cell/$goal<=1.05)';
  }

  static String _yellowFormula(
    String cell,
    String goal, {
    required bool upperOpenEnded,
  }) {
    if (upperOpenEnded) {
      return '=AND(ISNUMBER($cell), $goal>0, '
          '$cell>=$goal*0.85, $cell<$goal*0.95)';
    }
    return '=AND(ISNUMBER($cell), $goal>0, '
        'OR(AND($cell/$goal>=0.85, $cell/$goal<0.95), '
        'AND($cell/$goal>1.05, $cell/$goal<=1.15)))';
  }

  static String _redFormula(
    String cell,
    String goal, {
    required bool upperOpenEnded,
  }) {
    if (upperOpenEnded) {
      return '=AND(ISNUMBER($cell), $goal>0, $cell<$goal*0.85)';
    }
    return '=AND(ISNUMBER($cell), $goal>0, '
        'OR($cell/$goal<0.85, $cell/$goal>1.15))';
  }

  static sheets.Request _conditionalRule({
    required sheets.GridRange range,
    required String formula,
    required BushidoSheetColor bg,
  }) {
    return sheets.Request(
      addConditionalFormatRule: sheets.AddConditionalFormatRuleRequest(
        rule: sheets.ConditionalFormatRule(
          ranges: [range],
          booleanRule: sheets.BooleanRule(
            condition: sheets.BooleanCondition(
              type: 'CUSTOM_FORMULA',
              values: [sheets.ConditionValue(userEnteredValue: formula)],
            ),
            format: sheets.CellFormat(
              backgroundColorStyle: _styleColor(bg),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Color & low-level cell-format helpers ───────────────────────────────

  static sheets.Color _rgb(int r, int g, int b) =>
      sheets.Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0);

  static sheets.ColorStyle _styleColor(BushidoSheetColor color) =>
      sheets.ColorStyle(rgbColor: _rgb(color.r, color.g, color.b));

  static sheets.Borders _solidBorders(BushidoSheetColor color) {
    final border = sheets.Border(
      style: 'SOLID',
      colorStyle: _styleColor(color),
    );
    return sheets.Borders(
      top: border,
      bottom: border,
      left: border,
      right: border,
    );
  }

  static sheets.Request _baseBackgroundRequest({
    required int sheetId,
    required int startRow0,
    required int endRow0,
  }) {
    return sheets.Request(
      repeatCell: sheets.RepeatCellRequest(
        range: sheets.GridRange(
          sheetId: sheetId,
          startRowIndex: startRow0,
          endRowIndex: endRow0,
          startColumnIndex: 0,
          endColumnIndex: 26,
        ),
        cell: sheets.CellData(
          userEnteredFormat: sheets.CellFormat(
            backgroundColorStyle:
                _styleColor(BushidoSheetFormatConfig.sheetBackground),
            textFormat: sheets.TextFormat(
              fontFamily: BushidoSheetFormatConfig.fontMostserrat,
            ),
          ),
        ),
        fields:
            'userEnteredFormat.backgroundColorStyle,userEnteredFormat.textFormat.fontFamily',
      ),
    );
  }

  /// Builds a RepeatCellRequest covering a single rectangle. `fields` is
  /// constructed to update only the properties whose arguments are non-null,
  /// so existing format on unrelated properties is preserved.
  static sheets.Request _formatCells({
    required int sheetId,
    required int startRow0,
    required int endRow0,
    required int startCol,
    required int endCol,
    sheets.ColorStyle? backgroundColor,
    sheets.ColorStyle? textColor,
    bool? bold,
    String? fontFamily,
    int? fontSize,
    bool center = false,
    sheets.Borders? borders,
  }) {
    final fields = <String>[];
    if (backgroundColor != null) {
      fields.add('userEnteredFormat.backgroundColorStyle');
    }
    if (textColor != null) {
      fields.add('userEnteredFormat.textFormat.foregroundColorStyle');
    }
    if (bold != null) fields.add('userEnteredFormat.textFormat.bold');
    if (fontFamily != null) {
      fields.add('userEnteredFormat.textFormat.fontFamily');
    }
    if (fontSize != null) fields.add('userEnteredFormat.textFormat.fontSize');
    if (center) {
      fields.add('userEnteredFormat.horizontalAlignment');
      fields.add('userEnteredFormat.verticalAlignment');
    }
    if (borders != null) {
      fields.add('userEnteredFormat.borders');
    }

    final hasText = textColor != null ||
        bold != null ||
        fontFamily != null ||
        fontSize != null;

    return sheets.Request(
      repeatCell: sheets.RepeatCellRequest(
        range: sheets.GridRange(
          sheetId: sheetId,
          startRowIndex: startRow0,
          endRowIndex: endRow0,
          startColumnIndex: startCol,
          endColumnIndex: endCol,
        ),
        cell: sheets.CellData(
          userEnteredFormat: sheets.CellFormat(
            backgroundColorStyle: backgroundColor,
            textFormat: hasText
                ? sheets.TextFormat(
                    foregroundColorStyle: textColor,
                    bold: bold,
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                  )
                : null,
            horizontalAlignment: center ? 'CENTER' : null,
            verticalAlignment: center ? 'MIDDLE' : null,
            borders: borders,
          ),
        ),
        fields: fields.join(','),
      ),
    );
  }

  static sheets.Request _outerBorderRequest({
    required int sheetId,
    required int startRow0,
    required int endRow0,
    required int startCol,
    required int endCol,
    required BushidoSheetColor color,
  }) {
    final border = sheets.Border(
      style: 'SOLID_MEDIUM',
      colorStyle: _styleColor(color),
    );
    return sheets.Request(
      updateBorders: sheets.UpdateBordersRequest(
        range: sheets.GridRange(
          sheetId: sheetId,
          startRowIndex: startRow0,
          endRowIndex: endRow0,
          startColumnIndex: startCol,
          endColumnIndex: endCol,
        ),
        top: border,
        bottom: border,
        left: border,
        right: border,
      ),
    );
  }

  static sheets.Request _columnWidthRequest({
    required int sheetId,
    required int columnIndex,
    required int pixelSize,
  }) {
    return sheets.Request(
      updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
        range: sheets.DimensionRange(
          sheetId: sheetId,
          dimension: 'COLUMNS',
          startIndex: columnIndex,
          endIndex: columnIndex + 1,
        ),
        properties: sheets.DimensionProperties(pixelSize: pixelSize),
        fields: 'pixelSize',
      ),
    );
  }
}
