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
  /// appends a new empty block to the end of the sheet and updates the cache.
  Future<int> ensureWeekBlock({
    required String spreadsheetId,
    required int sheetId,
    required String sheetName,
    required IsoWeek week,
    required Map<IsoWeek, int> startRowCache,
  }) async {
    final cached = startRowCache[week];
    if (cached != null) return cached;

    final startRow = await _appendWeekBlock(
      spreadsheetId: spreadsheetId,
      sheetId: sheetId,
      sheetName: sheetName,
      week: week,
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

    // 1) Block content (A:O across weekBlockHeight rows).
    final block = _buildBlockGrid(week: week, startRow: startRow);
    final endRow = startRow + BushidoSheetLayout.weekBlockHeight - 1;
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A$startRow:O$endRow',
      values: block,
    );

    // 2) Hidden marker in column Z on the header row.
    final markerRow = startRow + BushidoSheetLayout.headerRowOffset;
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!Z$markerRow',
      values: [
        [_markerFor(week)],
      ],
    );

    // 3) Data validations (checkbox + dropdowns) on the day rows.
    final requests = _buildValidationRequests(sheetId: sheetId, startRow: startRow);
    await _sheets.batchUpdate(
      spreadsheetId: spreadsheetId,
      requests: requests,
    );

    AppLog.sync.success(
      'bushido.appendWeekBlock: ${week.toString()} at row $startRow',
    );
    return startRow;
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
    if (aColumn.isEmpty) return 1;
    return aColumn.length + BushidoSheetLayout.spacerRowsBetweenWeeks + 1;
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

    // Row 1 — daily column headers (A..L).
    final dailyHeaderRow = grid[BushidoSheetLayout.dailyHeaderRowOffset];
    for (final col in BushidoColumn.values) {
      dailyHeaderRow[col.columnOffset] = col.label;
    }

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
      rowGrid[mIndex + 2] =
          '=IFERROR(AVERAGE($col$firstDayAbsRow:$col$lastDayAbsRow), "")';
    }

    // Row 9 — average row for daily auto columns.
    final avgRow = grid[BushidoSheetLayout.averageRowOffset];
    avgRow[BushidoColumn.date.columnOffset] = 'Průměr';
    for (final col in BushidoExportConfig.dailyAutoColumns) {
      if (col == BushidoColumn.date) continue;
      final letter = columnLetter(col.columnOffset);
      avgRow[col.columnOffset] =
          '=IFERROR(AVERAGE($letter$firstDayAbsRow:$letter$lastDayAbsRow), "")';
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
