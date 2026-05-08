import 'dart:math' as math;

import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:intl/intl.dart';

import 'package:forgetrack/core/config/constants.dart';
import 'package:forgetrack/core/logging/app_log.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_a1_notation.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_day_row.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_export_config.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_sheet_layout.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';
import 'package:forgetrack/features/sheets_export/application/google_sheets_auth_service.dart';
import 'package:forgetrack/features/sheets_export/data/sheets_service.dart';
import 'package:forgetrack/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BushidoExportException implements Exception {
  final String message;
  const BushidoExportException(this.message);
  @override
  String toString() => 'BushidoExportException: $message';
}

/// Owns the Coach Log tab inside the user's existing export spreadsheet.
///
/// Responsibilities (Phase 3a):
/// - Spreadsheet bootstrap (auth, ensure 'Coach Log' tab exists).
/// - Lookup of existing weekly blocks via the hidden marker in column Z.
/// - Append new blocks (header, daily table, average formulas, target box,
///   data validations) at the end of the sheet.
///
/// Auto/manual cell writes for individual days live in Phase 3b.
class BushidoSheetsService {
  final SheetsService _sheets;
  final GoogleSheetsAuthService _sheetsAuth;

  BushidoSheetsService({
    SheetsService? sheets,
    GoogleSheetsAuthService? sheetsAuth,
  })  : _sheets = sheets ?? SheetsService(),
        _sheetsAuth = sheetsAuth ?? GoogleSheetsAuthService();

  // ─── Bootstrap ─────────────────────────────────────────────────────────────

  Future<({String spreadsheetId, int sheetId, String sheetName})> prepare(
    AppLocalizations l10n,
  ) async {
    AppLog.sync.info('bushido.prepare: requesting Sheets auth client');
    final client = await _sheetsAuth.getAuthClient(interactive: true);
    if (client == null) {
      throw BushidoExportException(l10n.exportErrorNotSignedIn);
    }
    _sheets.initialize(client);

    final prefs = await SharedPreferences.getInstance();
    var spreadsheetId = prefs.getString(AppConstants.prefSpreadsheetId);

    if (spreadsheetId != null) {
      final meta = await _sheets.getSpreadsheet(spreadsheetId);
      if (meta == null) {
        AppLog.sync.warn(
          'bushido.prepare: stored spreadsheet not accessible — creating a new one',
          payload: spreadsheetId,
        );
        spreadsheetId = null;
      }
    }

    if (spreadsheetId == null) {
      AppLog.sync.info('bushido.prepare: creating new spreadsheet');
      spreadsheetId = await _sheets.createExportSpreadsheet();
      await prefs.setString(AppConstants.prefSpreadsheetId, spreadsheetId);
      AppLog.sync.success('bushido.prepare: spreadsheet created',
          payload: spreadsheetId);
    }

    const sheetName = AppConstants.coachLogSheetName;
    await _sheets.ensureSheetExists(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
    );

    final sheetId =
        await _sheets.getSheetId(spreadsheetId: spreadsheetId, sheetName: sheetName);
    if (sheetId == null) {
      throw BushidoExportException(
        'Coach Log tab "$sheetName" was not found after ensureSheetExists',
      );
    }

    return (spreadsheetId: spreadsheetId, sheetId: sheetId, sheetName: sheetName);
  }

  // ─── Lookup ────────────────────────────────────────────────────────────────

  /// Reads column Z of the entire sheet and returns a map of weeks (with the
  /// current `layoutVersion`) to their 1-indexed `startRow`.
  ///
  /// Foreign-version markers (e.g. `v2` when the code is `v1`) are logged and
  /// skipped — Phase 4 will append a fresh `v1` block for that week instead.
  /// Migration of older versions is out of scope for MVP 1.
  Future<Map<IsoWeek, int>> loadExistingWeekIndex({
    required String spreadsheetId,
    required String sheetName,
  }) async {
    final values = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z:Z',
    );

    final result = <IsoWeek, int>{};
    for (var i = 0; i < values.length; i++) {
      final row = values[i];
      if (row.isEmpty) continue;
      final cell = row.first?.toString().trim();
      if (cell == null || cell.isEmpty) continue;

      final parsed = _parseMarker(cell);
      if (parsed == null) continue;

      if (parsed.version != BushidoSheetLayout.layoutVersion) {
        AppLog.sync.warn(
          'bushido.loadExistingWeekIndex: skipping foreign-version marker',
          payload: '$cell at row ${i + 1}',
        );
        continue;
      }
      // Sheets API returns rows in the order they appear; row index → 1-indexed.
      result[parsed.week] = i + 1;
    }
    return result;
  }

  /// Returns the `startRow` for [week]. Reads from [startRowCache]; if missing,
  /// either appends (newer than all existing) or inserts (older / between
  /// existing weeks) a new block, keeping the sheet in chronological order.
  Future<int> ensureWeekBlock({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required IsoWeek week,
    required Map<IsoWeek, int> startRowCache,
  }) async {
    final cached = startRowCache[week];
    if (cached != null) return cached;

    // Find the existing week that should come *after* the new one, if any.
    IsoWeek? successor;
    int? successorRow;
    for (final entry in startRowCache.entries) {
      if (!entry.key.monday.isAfter(week.monday)) continue;
      if (successor == null || entry.key.monday.isBefore(successor.monday)) {
        successor = entry.key;
        successorRow = entry.value;
      }
    }

    final startRow = successor == null
        ? await _appendWeekBlock(
            spreadsheetId: spreadsheetId,
            sheetId: sheetId,
            sheetName: sheetName,
            week: week,
            startRowCache: startRowCache,
          )
        : await _insertWeekBlock(
            spreadsheetId: spreadsheetId,
            sheetId: sheetId,
            sheetName: sheetName,
            week: week,
            insertAtRow: successorRow!,
            startRowCache: startRowCache,
          );
    startRowCache[week] = startRow;
    return startRow;
  }

  // ─── Auto cell write (Phase 3b) ────────────────────────────────────────────

  /// Writes the 7 day rows into the **auto** columns only (A..H).
  ///
  /// Manual columns (I..L: training, hunger, hydration, note) are never
  /// touched — the range stops at H, so re-export preserves whatever the
  /// coach or user has filled in by hand.
  ///
  /// `null` in [BushidoDayRow] becomes an empty string (`''`) so that
  /// USER_ENTERED clears any prior value. Real `0` is written as `0` and
  /// stays distinct from a missing measurement.
  Future<void> writeAutoCells({
    required String spreadsheetId,
    required String sheetName,
    required IsoWeek week,
    required int startRow,
    required List<BushidoDayRow> dayRows,
  }) async {
    assert(
      dayRows.length == BushidoSheetLayout.daysPerWeek,
      'writeAutoCells expects exactly ${BushidoSheetLayout.daysPerWeek} day rows',
    );

    final firstDayRow = startRow + BushidoSheetLayout.firstDayRowOffset;
    final lastDayRow = firstDayRow + BushidoSheetLayout.daysPerWeek - 1;
    final autoCount = BushidoExportConfig.dailyAutoColumns.length;
    final lastAutoLetter = columnLetter(autoCount - 1); // 'H'

    final dateFmt = DateFormat('dd.MM.yyyy');
    final grid = <List<Object?>>[];
    for (final day in dayRows) {
      // Order matches BushidoColumn offsets 0..7 (A..H).
      grid.add(<Object?>[
        dateFmt.format(day.date),
        day.weightKg ?? '',
        day.kcal ?? '',
        day.proteinG ?? '',
        day.carbsG ?? '',
        day.fatG ?? '',
        day.fiberG ?? '',
        day.steps ?? '',
      ]);
    }

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A$firstDayRow:$lastAutoLetter$lastDayRow',
      values: grid,
    );

    AppLog.sync.debug(
      'bushido.writeAutoCells: ${week.toString()} '
      'rows $firstDayRow..$lastDayRow (A:$lastAutoLetter)',
    );
  }

  // ─── Sheet header (Phase 6) ────────────────────────────────────────────────

  /// Writes the sticky profile header (rows 1–[headerRows]) on the first call
  /// and is a no-op on every subsequent call. Also applies sheet-wide
  /// formatting (black background, frozen rows).
  ///
  /// Skipped silently if A1 is non-empty so that legacy sheets (blocks at
  /// row 1) are never overwritten.
  Future<void> ensureSheetHeader({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
  }) async {
    // Already set up?
    final markerCell = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z1',
    );
    if (markerCell.isNotEmpty &&
        markerCell.first.isNotEmpty &&
        markerCell.first.first?.toString() == BushidoSheetLayout.headerMarker) {
      return;
    }

    // Legacy sheet guard: if A1 has content, leave it alone.
    final a1 = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1',
    );
    if (a1.isNotEmpty && a1.first.isNotEmpty && a1.first.first != null) {
      AppLog.sync.warn(
        'bushido.ensureSheetHeader: A1 non-empty — skipping (legacy sheet)',
      );
      return;
    }

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1:L${BushidoSheetLayout.headerRows}',
      values: _buildHeaderGrid(),
    );

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z1',
      values: [[BushidoSheetLayout.headerMarker]],
    );

    await _sheets.batchUpdate(
      spreadsheetId: spreadsheetId,
      requests: _buildHeaderFormatRequests(sheetId),
    );

    AppLog.sync.success('bushido.ensureSheetHeader: header written');
  }

  // ─── Append ────────────────────────────────────────────────────────────────

  Future<int> _appendWeekBlock({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required IsoWeek week,
    required Map<IsoWeek, int> startRowCache,
  }) async {
    final startRow = await _resolveAppendStartRow(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
      startRowCache: startRowCache,
    );
    await _writeBlockAt(
      spreadsheetId: spreadsheetId,
      sheetId: sheetId,
      sheetName: sheetName,
      week: week,
      startRow: startRow,
    );
    AppLog.sync.success(
      'bushido.appendWeekBlock: ${week.toString()} at row $startRow',
    );
    return startRow;
  }

  /// Inserts [BushidoSheetLayout.weekBlockHeight + spacerRowsBetweenWeeks]
  /// empty rows at [insertAtRow] (1-indexed) and writes the new block content
  /// into the freshly-inserted slot. The whole operation runs in a single
  /// atomic `batchUpdate` so Google processes the row insertion, content
  /// writes, and table/format requests together — splitting them across
  /// separate API calls intermittently produced 500 Internal errors when
  /// AddTableRequest fired immediately after a row insertion.
  Future<int> _insertWeekBlock({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required IsoWeek week,
    required int insertAtRow,
    required Map<IsoWeek, int> startRowCache,
  }) async {
    final rowsToInsert = BushidoSheetLayout.weekBlockHeight +
        BushidoSheetLayout.spacerRowsBetweenWeeks;
    final block = _buildBlockGrid(week: week, startRow: insertAtRow);
    final blockStart0 = insertAtRow - 1;
    final markerRow0 = blockStart0 + BushidoSheetLayout.headerRowOffset;
    final markerCol0 = BushidoSheetLayout.hiddenMarkerColumn - 1;

    final requests = <sheets.Request>[
      // 1) Insert empty rows. Inherit from the row after so the inserted rows
      //    don't pick up any header-section quirks.
      sheets.Request(
        insertDimension: sheets.InsertDimensionRequest(
          inheritFromBefore: false,
          range: sheets.DimensionRange(
            sheetId: sheetId,
            dimension: 'ROWS',
            startIndex: blockStart0,
            endIndex: blockStart0 + rowsToInsert,
          ),
        ),
      ),
      // 2) Block content (A..O across weekBlockHeight rows).
      sheets.Request(
        updateCells: sheets.UpdateCellsRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: blockStart0,
            endRowIndex: blockStart0 + BushidoSheetLayout.weekBlockHeight,
            startColumnIndex: 0,
            endColumnIndex: 15,
          ),
          rows: block
              .map((row) => sheets.RowData(
                    values: row.map(_toCellData).toList(),
                  ))
              .toList(),
          fields: 'userEnteredValue',
        ),
      ),
      // 3) Hidden marker in column Z on the header row.
      sheets.Request(
        updateCells: sheets.UpdateCellsRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: markerRow0,
            endRowIndex: markerRow0 + 1,
            startColumnIndex: markerCol0,
            endColumnIndex: markerCol0 + 1,
          ),
          rows: [
            sheets.RowData(values: [_toCellData(_markerFor(week))]),
          ],
          fields: 'userEnteredValue',
        ),
      ),
      // 4) Validations + table/format requests.
      ..._buildValidationRequests(sheetId: sheetId, startRow: insertAtRow),
      ..._buildFormatRequests(sheetId: sheetId, startRow: insertAtRow, week: week),
    ];

    await _sheets.batchUpdate(
      spreadsheetId: spreadsheetId,
      requests: requests,
    );

    // Shift every cached row at or below the insertion point. Done after the
    // batchUpdate succeeds so a server-side failure leaves the cache
    // consistent with the actual sheet.
    for (final key in startRowCache.keys.toList()) {
      if (startRowCache[key]! >= insertAtRow) {
        startRowCache[key] = startRowCache[key]! + rowsToInsert;
      }
    }

    AppLog.sync.success(
      'bushido.insertWeekBlock: ${week.toString()} at row $insertAtRow',
    );
    return insertAtRow;
  }

  static sheets.CellData _toCellData(Object? value) {
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
        userEnteredValue:
            sheets.ExtendedValue(numberValue: value.toDouble()),
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

  /// Writes block content + marker + validations/formatting at [startRow].
  /// Shared by both append and insert paths.
  Future<void> _writeBlockAt({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required IsoWeek week,
    required int startRow,
  }) async {
    final block = _buildBlockGrid(week: week, startRow: startRow);
    final endRow = startRow + BushidoSheetLayout.weekBlockHeight - 1;
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A$startRow:O$endRow',
      values: block,
    );

    final markerRow = startRow + BushidoSheetLayout.headerRowOffset;
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z$markerRow',
      values: [
        [_markerFor(week)],
      ],
    );

    await _sheets.batchUpdate(
      spreadsheetId: spreadsheetId,
      requests: [
        ..._buildValidationRequests(sheetId: sheetId, startRow: startRow),
        ..._buildFormatRequests(sheetId: sheetId, startRow: startRow, week: week),
      ],
    );
  }

  Future<int> _resolveAppendStartRow({
    required String spreadsheetId,
    required String sheetName,
    required Map<IsoWeek, int> startRowCache,
  }) async {
    if (startRowCache.isNotEmpty) {
      final maxStart = startRowCache.values.reduce(math.max);
      return maxStart +
          BushidoSheetLayout.weekBlockHeight +
          BushidoSheetLayout.spacerRowsBetweenWeeks;
    }
    final aColumn = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A:A',
    );
    if (aColumn.isEmpty) return BushidoSheetLayout.headerRows + 1;
    return math.max(
      aColumn.length + BushidoSheetLayout.spacerRowsBetweenWeeks + 1,
      BushidoSheetLayout.headerRows + 1,
    );
  }

  // ─── Header grid & format helpers (Phase 6) ──────────────────────────────

  /// Static profile placeholder for rows 1–[headerRows]. The coach fills in
  /// column B values; cell B6 is reserved for an =IMAGE() formula.
  List<List<Object?>> _buildHeaderGrid() {
    return [
      ['BUSHIDO COACH LOG'],
      ['Jméno:'],
      ['Věk:'],
      ['Váhová kategorie:'],
      ['Příští závod:'],
      [],
      [],
      ['Aktuální týden →'],
    ];
  }

  /// Freeze top [headerRows] rows + black sheet background + white bold title.
  List<sheets.Request> _buildHeaderFormatRequests(int sheetId) {
    return [
      // Freeze header rows.
      sheets.Request(
        updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
          fields: 'gridProperties.frozenRowCount',
          properties: sheets.SheetProperties(
            sheetId: sheetId,
            gridProperties: sheets.GridProperties(
              frozenRowCount: BushidoSheetLayout.headerRows,
            ),
          ),
        ),
      ),
      // Black background for entire sheet (covers header + future week blocks).
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 0,
            endRowIndex: 1000,
            startColumnIndex: 0,
            endColumnIndex: 26,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColorStyle: _cs(0, 0, 0),
            ),
          ),
          fields: 'userEnteredFormat.backgroundColorStyle',
        ),
      ),
      // White bold 14pt title in A1.
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 0,
            endRowIndex: 1,
            startColumnIndex: 0,
            endColumnIndex: 1,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 14,
                foregroundColorStyle: _cs(255, 255, 255),
              ),
            ),
          ),
          fields: 'userEnteredFormat.textFormat',
        ),
      ),
    ];
  }

  /// Per-week formatting:
  ///   - Two AddTableRequests with `rowsProperties` carrying header/footer
  ///     colors plus banded row colors. Empty `rowsProperties` (or column-
  ///     scoped RepeatCellRequest with `backgroundColorStyle` on table
  ///     cells) reliably triggered server-side 500s, so we drive the entire
  ///     row palette through the table itself.
  ///   - RepeatCellRequest for white bold 12pt text on the header/footer.
  ///   - RepeatCellRequest for centered alignment over the table area.
  List<sheets.Request> _buildFormatRequests({
    required int sheetId,
    required int startRow,
    required IsoWeek week,
  }) {
    final wHdr0 = startRow - 1 + BushidoSheetLayout.dailyHeaderRowOffset;
    final wFtr0 = startRow - 1 + BushidoSheetLayout.averageRowOffset;

    final tHdr0 = startRow - 1 + BushidoSheetLayout.targetHeaderRowOffset;
    final tDataEnd0 = startRow -
        1 +
        BushidoSheetLayout.firstTargetMetricRowOffset +
        BushidoExportConfig.targetMetrics.length;

    final csRedBerry = _cs(204, 0, 0);            // #CC0000
    final csLightRedBerry1 = _cs(221, 126, 107);  // #DD7E6B
    final csLightGray3 = _cs(243, 243, 243);      // #F3F3F3
    final csGray = _cs(217, 217, 217);            // #D9D9D9
    final csTargetHdr = _cs(204, 204, 204);       // #CCCCCC
    final csWhite = _cs(255, 255, 255);

    final wk = '${week.year}_W${week.weekNumber.toString().padLeft(2, '0')}';

    return [
      // Weekly data table (A:L, header + 7 days + avg footer).
      sheets.Request(
        addTable: sheets.AddTableRequest(
          table: sheets.Table(
            name: 'Týden_$wk',
            range: sheets.GridRange(
              sheetId: sheetId,
              startRowIndex: wHdr0,
              endRowIndex: wFtr0 + 1,
              startColumnIndex: 0,
              endColumnIndex: 12,
            ),
            rowsProperties: sheets.TableRowsProperties(
              headerColorStyle: csRedBerry,
              footerColorStyle: csLightRedBerry1,
              firstBandColorStyle: csLightGray3,
              secondBandColorStyle: csGray,
            ),
          ),
        ),
      ),
      // Target box table (M:O, header + 7 metric rows).
      sheets.Request(
        addTable: sheets.AddTableRequest(
          table: sheets.Table(
            name: 'Cíle_$wk',
            range: sheets.GridRange(
              sheetId: sheetId,
              startRowIndex: tHdr0,
              endRowIndex: tDataEnd0,
              startColumnIndex: 12,
              endColumnIndex: 15,
            ),
            rowsProperties: sheets.TableRowsProperties(
              headerColorStyle: csTargetHdr,
              firstBandColorStyle: csLightGray3,
              secondBandColorStyle: csLightGray3,
            ),
          ),
        ),
      ),
      // Weekly table header — white bold 12pt.
      _formatCells(
        sheetId: sheetId,
        startRow0: wHdr0,
        endRow0: wHdr0 + 1,
        startCol: 0,
        endCol: 12,
        textColor: csWhite,
        bold: true,
        fontSize: 12,
      ),
      // Weekly table footer (avg row) — white bold 12pt.
      _formatCells(
        sheetId: sheetId,
        startRow0: wFtr0,
        endRow0: wFtr0 + 1,
        startCol: 0,
        endCol: 12,
        textColor: csWhite,
        bold: true,
        fontSize: 12,
      ),
      // Target table header — white bold 12pt.
      _formatCells(
        sheetId: sheetId,
        startRow0: tHdr0,
        endRow0: tHdr0 + 1,
        startCol: 12,
        endCol: 15,
        textColor: csWhite,
        bold: true,
        fontSize: 12,
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
    ];
  }

  // ─── Color & format helpers ────────────────────────────────────────────────

  static sheets.Color _rgb(int r, int g, int b) =>
      sheets.Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0);

  static sheets.ColorStyle _cs(int r, int g, int b) =>
      sheets.ColorStyle(rgbColor: _rgb(r, g, b));

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
    int? fontSize,
    bool center = false,
  }) {
    final fields = <String>[];
    if (backgroundColor != null) {
      fields.add('userEnteredFormat.backgroundColorStyle');
    }
    if (textColor != null) fields.add('userEnteredFormat.textFormat.foregroundColorStyle');
    if (bold != null) fields.add('userEnteredFormat.textFormat.bold');
    if (fontSize != null) fields.add('userEnteredFormat.textFormat.fontSize');
    if (center) {
      fields.add('userEnteredFormat.horizontalAlignment');
      fields.add('userEnteredFormat.verticalAlignment');
    }

    final hasText = textColor != null || bold != null || fontSize != null;

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
                    fontSize: fontSize,
                  )
                : null,
            horizontalAlignment: center ? 'CENTER' : null,
            verticalAlignment: center ? 'MIDDLE' : null,
          ),
        ),
        fields: fields.join(','),
      ),
    );
  }

  // ─── Block grid construction ───────────────────────────────────────────────

  /// Builds a 12-row × 15-column grid (A..O) for the week block:
  /// row 0 (headerRowOffset)        : week header (A) + 'CÍLE / VÝSLEDEK' (M)
  /// row 1 (dailyHeaderRowOffset)   : daily column headers A..L
  /// rows 2..8 (firstDayRowOffset+) : day dates (A) + target metrics (M..O)
  /// row 9 (averageRowOffset)       : 'Průměr' (A) + AVERAGE formulas B..H
  /// rows 10..11                    : reserve (empty)
  List<List<Object?>> _buildBlockGrid({
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
    final shortFmt = DateFormat('dd.MM');

    // Row 0 — week header (A) + target box title (M).
    grid[BushidoSheetLayout.headerRowOffset][0] =
        'Týden ${week.weekNumber.toString().padLeft(2, '0')}: '
        '${shortFmt.format(week.monday)} – ${dateFmt.format(week.sunday)}';
    final mIndex = BushidoSheetLayout.targetBoxStartColumn - 1;
    grid[BushidoSheetLayout.headerRowOffset][mIndex] = 'CÍLE / VÝSLEDEK';

    // Row 1 — daily column headers (A..L) + target table headers (M..O).
    final dailyHeaderRow = grid[BushidoSheetLayout.dailyHeaderRowOffset];
    for (final col in BushidoColumn.values) {
      dailyHeaderRow[col.columnOffset] = col.label;
    }
    dailyHeaderRow[mIndex] = 'Metrika';
    dailyHeaderRow[mIndex + 1] = 'Cíl';
    dailyHeaderRow[mIndex + 2] = 'Výsledek';

    // Rows 2..8 — day dates (A) and target metrics (M..O).
    final firstDayAbsRow = startRow + BushidoSheetLayout.firstDayRowOffset;
    final lastDayAbsRow = firstDayAbsRow + BushidoSheetLayout.daysPerWeek - 1;
    for (var d = 0; d < BushidoSheetLayout.daysPerWeek; d++) {
      final rowGrid = grid[BushidoSheetLayout.firstDayRowOffset + d];
      final date = week.monday.add(Duration(days: d));
      rowGrid[BushidoColumn.date.columnOffset] = dateFmt.format(date);
    }
    for (var i = 0; i < BushidoExportConfig.targetMetrics.length; i++) {
      final metric = BushidoExportConfig.targetMetrics[i];
      final rowGrid =
          grid[BushidoSheetLayout.firstTargetMetricRowOffset + i];
      // M = label, N = goal (manual, blank), O = AVERAGE formula
      rowGrid[mIndex] = metric.label;
      rowGrid[mIndex + 1] = null; // coach fills the target manually
      final col = columnLetter(metric.sourceColumn.columnOffset);
      final decimals = metric.sourceColumn == BushidoColumn.weightKg ? 1 : 0;
      rowGrid[mIndex + 2] =
          '=IFERROR(ROUND(AVERAGE($col$firstDayAbsRow:$col$lastDayAbsRow), $decimals), "")';
    }

    // Row 9 — average row for daily auto columns.
    final avgRow = grid[BushidoSheetLayout.averageRowOffset];
    avgRow[BushidoColumn.date.columnOffset] = 'Průměr';
    for (final col in BushidoExportConfig.dailyAutoColumns) {
      if (col == BushidoColumn.date) continue;
      final letter = columnLetter(col.columnOffset);
      final decimals = col == BushidoColumn.weightKg ? 1 : 0;
      avgRow[col.columnOffset] =
          '=IFERROR(ROUND(AVERAGE($letter$firstDayAbsRow:$letter$lastDayAbsRow), $decimals), "")';
    }

    // Rows 10..11 — reserve, intentionally blank.
    return grid;
  }

  // ─── Data validations ──────────────────────────────────────────────────────

  List<sheets.Request> _buildValidationRequests({
    required int sheetId,
    required int startRow,
  }) {
    // GridRange uses 0-indexed half-open ranges.
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
      // Training: checkbox.
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

  // ─── Marker helpers ────────────────────────────────────────────────────────

  String _markerFor(IsoWeek week) => 'BUSHIDO_WEEK:${week.year}-W'
      '${week.weekNumber.toString().padLeft(2, '0')}'
      ':${BushidoSheetLayout.layoutVersion}';

  static final RegExp _markerRegex =
      RegExp(r'^BUSHIDO_WEEK:(\d{4})-W(\d{2}):v(\d+)$');

  ({IsoWeek week, String version})? _parseMarker(String raw) {
    final m = _markerRegex.firstMatch(raw);
    if (m == null) return null;
    final year = int.parse(m.group(1)!);
    final weekNum = int.parse(m.group(2)!);
    final version = 'v${m.group(3)!}';
    // Reconstruct the IsoWeek by anchoring to the Thursday of (year, weekNum):
    // ISO Thursday determines the year, so this round-trips correctly.
    final jan4 = DateTime.utc(year, 1, 4);
    final mondayOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    final monday =
        mondayOfWeek1.add(Duration(days: 7 * (weekNum - 1)));
    final week = IsoWeek.fromDate(monday);
    return (week: week, version: version);
  }
}
