import 'dart:math' as math;

import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:intl/intl.dart';

import 'package:forgetrack/core/config/constants.dart';
import 'package:forgetrack/core/logging/app_log.dart';
import 'package:forgetrack/features/coach_log_export/config/bushido_sheet_format_config.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_a1_notation.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_block_grid.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_format_requests.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_week_marker.dart';
import 'package:forgetrack/features/coach_log_export/config/bushido_export_config.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_day_row.dart';
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
/// Responsibilities (orchestration only — the actual grid construction lives
/// in [BushidoBlockGrid] and request building in [BushidoFormatRequests]):
/// - Spreadsheet bootstrap (auth, ensure 'Coach Log' tab exists).
/// - Sticky sheet header (profile box + logo + 'Aktuální týden' link).
/// - Lookup of existing weekly blocks via the hidden marker in column Z.
/// - Append / chronological insert of new week blocks.
/// - Auto cell writes for individual days (manual columns are never touched).
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

    final sheetId = await _sheets.getSheetId(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
    );
    if (sheetId == null) {
      throw BushidoExportException(
        'Coach Log tab "$sheetName" was not found after ensureSheetExists',
      );
    }

    return (
      spreadsheetId: spreadsheetId,
      sheetId: sheetId,
      sheetName: sheetName,
    );
  }

  // ─── Lookup ────────────────────────────────────────────────────────────────

  /// Reads column Z and returns a map of weeks (with the current
  /// `layoutVersion`) to their 1-indexed `startRow`. Foreign-version markers
  /// are logged and skipped — Phase 4 will append a fresh `v1` block for that
  /// week instead. Migration of older versions is out of scope for MVP 1.
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

      final parsed = BushidoWeekMarker.parse(cell);
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
    if (cached != null) {
      await _formatBlockAt(
        spreadsheetId: spreadsheetId,
        sheetId: sheetId,
        startRow: cached,
      );
      return cached;
    }

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

  // ─── Auto cell write ──────────────────────────────────────────────────────

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

  // ─── Sheet header (sticky profile zone) ───────────────────────────────────

  /// Writes the sticky profile header (rows 1–[headerRows]) on the first call
  /// and is a no-op on every subsequent call. Also applies sheet-wide
  /// formatting (black background, frozen rows).
  ///
  /// Skipped silently if A1 is non-empty so that legacy sheets (blocks at
  /// row 1) are never overwritten.
  Future<bool> ensureSheetHeader({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
  }) async {
    final markerCell = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z1',
    );
    final hasHeaderMarker = markerCell.isNotEmpty &&
        markerCell.first.isNotEmpty &&
        markerCell.first.first?.toString() == BushidoSheetLayout.headerMarker;

    if (!hasHeaderMarker) {
      // Legacy sheet guard: if A1 has content, leave it alone.
      final a1 = await _sheets.readRange(
        spreadsheetId: spreadsheetId,
        range: '$sheetName!A1',
      );
      if (a1.isNotEmpty && a1.first.isNotEmpty && a1.first.first != null) {
        AppLog.sync.warn(
          'bushido.ensureSheetHeader: A1 non-empty — skipping (legacy sheet)',
        );
        return false;
      }
    }

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1:B${BushidoSheetLayout.headerRows}',
      values: List.generate(
        BushidoSheetLayout.headerRows,
        (_) => ['', ''],
        growable: false,
      ),
    );

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range:
          '$sheetName!C3:C${2 + BushidoSheetFormatConfig.profileLabels.length}',
      values: BushidoSheetFormatConfig.profileLabels
          .map((label) => [label])
          .toList(growable: false),
    );

    final logoFormula = _logoImageFormula();
    if (logoFormula != null) {
      await _sheets.writeRange(
        spreadsheetId: spreadsheetId,
        range: '$sheetName!A2',
        values: [[logoFormula]],
      );
    }

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z1',
      values: [[BushidoSheetLayout.headerMarker]],
    );

    await _sheets.batchUpdate(
      spreadsheetId: spreadsheetId,
      requests: BushidoFormatRequests.buildHeaderFormat(sheetId),
    );

    AppLog.sync.success('bushido.ensureSheetHeader: header written');
    return true;
  }

  Future<void> updateCurrentWeekHeaderLink({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required int startRow,
  }) async {
    final url =
        'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit#gid=$sheetId&range=A$startRow';
    final escapedUrl = url.replaceAll('"', '""');
    final escapedLabel =
        BushidoSheetFormatConfig.currentWeekLinkText.replaceAll('"', '""');
    final formula = '=HYPERLINK("$escapedUrl", "$escapedLabel")';

    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!D7',
      values: [[formula]],
    );
  }

  // ─── Append / insert ─────────────────────────────────────────────────────

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
    // Conditional rules are added once per block creation. _formatBlockAt
    // (re-format on cached weeks) intentionally skips them — Sheets has no
    // upsert for conditional format rules, so re-applying would duplicate.
    final condRequests = BushidoFormatRequests.buildConditionalFormat(
      sheetId: sheetId,
      startRow: startRow,
    );
    if (condRequests.isNotEmpty) {
      await _sheets.batchUpdate(
        spreadsheetId: spreadsheetId,
        requests: condRequests,
      );
    }
    AppLog.sync.success(
      'bushido.appendWeekBlock: ${week.toString()} at row $startRow',
    );
    return startRow;
  }

  /// Inserts [BushidoSheetLayout.weekBlockHeight + spacerRowsBetweenWeeks]
  /// empty rows at [insertAtRow] (1-indexed) and writes the new block content
  /// into the freshly-inserted slot. The whole operation runs in a single
  /// atomic `batchUpdate` so Google processes the row insertion, content
  /// writes, validations, and format requests together — splitting them
  /// across separate API calls intermittently produced 500 Internal errors.
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
    final block = BushidoBlockGrid.build(week: week, startRow: insertAtRow);
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
                    values:
                        row.map(BushidoFormatRequests.toCellData).toList(),
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
            sheets.RowData(
              values: [BushidoFormatRequests.toCellData(BushidoWeekMarker.format(week))],
            ),
          ],
          fields: 'userEnteredValue',
        ),
      ),
      // 4) Validations + format + conditional rules.
      ...BushidoFormatRequests.buildValidations(
        sheetId: sheetId,
        startRow: insertAtRow,
      ),
      ...BushidoFormatRequests.buildBlockFormat(
        sheetId: sheetId,
        startRow: insertAtRow,
      ),
      ...BushidoFormatRequests.buildConditionalFormat(
        sheetId: sheetId,
        startRow: insertAtRow,
      ),
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

  /// Writes block content + marker + validations/formatting at [startRow].
  /// Shared by both append and insert paths.
  Future<void> _writeBlockAt({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required IsoWeek week,
    required int startRow,
  }) async {
    final block = BushidoBlockGrid.build(week: week, startRow: startRow);
    final endRow = startRow + BushidoSheetLayout.weekBlockHeight - 1;
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A$startRow:O$endRow',
      values: block,
    );

    await _formatBlockAt(
      spreadsheetId: spreadsheetId,
      sheetId: sheetId,
      startRow: startRow,
    );

    final markerRow = startRow + BushidoSheetLayout.headerRowOffset;
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z$markerRow',
      values: [
        [BushidoWeekMarker.format(week)],
      ],
    );
  }

  Future<void> _formatBlockAt({
    required String spreadsheetId,
    required int sheetId,
    required int startRow,
  }) async {
    await _sheets.batchUpdate(
      spreadsheetId: spreadsheetId,
      requests: [
        ...BushidoFormatRequests.buildValidations(
          sheetId: sheetId,
          startRow: startRow,
        ),
        ...BushidoFormatRequests.buildBlockFormat(
          sheetId: sheetId,
          startRow: startRow,
        ),
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

  // ─── Sheet header helpers ────────────────────────────────────────────────

  /// Builds the optional in-cell logo formula. The URL must be reachable by
  /// Google Sheets; local bundled assets cannot be rendered directly.
  String? _logoImageFormula() {
    final imageUrl = BushidoSheetFormatConfig.logoImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final escapedUrl = imageUrl.replaceAll('"', '""');
    return '=IMAGE("$escapedUrl", 4, '
        '${BushidoSheetFormatConfig.logoHeightPx}, '
        '${BushidoSheetFormatConfig.logoWidthPx})';
  }
}
