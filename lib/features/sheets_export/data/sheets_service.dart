import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import '../../../core/config/constants.dart';

/// Wrapper around Google Sheets API v4.
/// Call [initialize] with an authenticated HTTP client before use.
class SheetsService {
  sheets.SheetsApi? _api;

  void initialize(http.Client authClient) {
    _api = sheets.SheetsApi(authClient);
  }

  bool get isReady => _api != null;

  // ─── Spreadsheet ──────────────────────────────────────────────────────────

  /// Creates a new spreadsheet with default sheets and returns its ID.
  Future<String> createSpreadsheet() async {
    _assertReady();
    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(title: AppConstants.sheetsTitle),
      sheets: [
        _makeSheet(AppConstants.stepsSheet,
            ['Datum', 'Kroky']),
        _makeSheet(AppConstants.activitiesSheet,
            ['Začátek', 'Typ', 'Trvání (min)', 'Kalorie', 'Vzdálenost (km)']),
        _makeSheet(AppConstants.caloriesSheet,
            ['Čas', 'Jídlo', 'Potravina', 'Gramy', 'kcal', 'Bílkoviny', 'Sacharidy', 'Tuky']),
      ],
    );

    final result = await _api!.spreadsheets.create(spreadsheet);
    return result.spreadsheetId!;
  }

  /// Creates an empty spreadsheet with a single tab named [AppConstants.exportSheetName],
  /// suitable for the unified date-merge export pipeline.
  Future<String> createExportSpreadsheet() async {
    _assertReady();
    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(title: AppConstants.sheetsTitle),
      sheets: [
        sheets.Sheet(
          properties: sheets.SheetProperties(title: AppConstants.exportSheetName),
        ),
      ],
    );
    final result = await _api!.spreadsheets.create(spreadsheet);
    return result.spreadsheetId!;
  }

  /// Loads spreadsheet metadata. Returns `null` if the spreadsheet is missing
  /// or inaccessible.
  Future<sheets.Spreadsheet?> getSpreadsheet(String spreadsheetId) async {
    _assertReady();
    try {
      return await _api!.spreadsheets.get(spreadsheetId);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new tab named [sheetName] to [spreadsheetId] if missing.
  Future<void> ensureSheetExists({
    required String spreadsheetId,
    required String sheetName,
  }) async {
    _assertReady();
    final meta = await _api!.spreadsheets.get(spreadsheetId);
    final exists = (meta.sheets ?? []).any(
      (s) => s.properties?.title == sheetName,
    );
    if (exists) return;
    await _api!.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(requests: [
        sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: sheetName),
          ),
        ),
      ]),
      spreadsheetId,
    );
  }

  /// Appends rows to the end of the sheet.
  Future<void> appendRows({
    required String spreadsheetId,
    required String sheetName,
    required List<List<Object?>> rows,
  }) async {
    _assertReady();
    if (rows.isEmpty) return;

    final body = sheets.ValueRange(values: rows);
    await _api!.spreadsheets.values.append(
      body,
      spreadsheetId,
      '$sheetName!A1',
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  /// Reads all values from the given range.
  Future<List<List<Object?>>> readRange({
    required String spreadsheetId,
    required String range,
  }) async {
    _assertReady();
    final result = await _api!.spreadsheets.values.get(spreadsheetId, range);
    return result.values ?? [];
  }

  /// Overwrites values starting at [range] (USER_ENTERED parsing).
  Future<void> writeRange({
    required String spreadsheetId,
    required String range,
    required List<List<Object?>> values,
  }) async {
    _assertReady();
    await _api!.spreadsheets.values.update(
      sheets.ValueRange(values: values),
      spreadsheetId,
      range,
      valueInputOption: 'USER_ENTERED',
    );
  }

  /// Clears all values in [range].
  Future<void> clearRange({
    required String spreadsheetId,
    required String range,
  }) async {
    _assertReady();
    await _api!.spreadsheets.values.clear(
      sheets.ClearValuesRequest(),
      spreadsheetId,
      range,
    );
  }

  /// Returns the numeric `sheetId` for the named tab, or `null` when the tab
  /// is missing. Required by batch-update operations that target a specific
  /// sheet via `GridRange` (e.g. data validations, cell formatting).
  Future<int?> getSheetId({
    required String spreadsheetId,
    required String sheetName,
  }) async {
    _assertReady();
    final meta = await _api!.spreadsheets.get(spreadsheetId);
    return (meta.sheets ?? [])
        .firstWhere(
          (s) => s.properties?.title == sheetName,
          orElse: () => sheets.Sheet(),
        )
        .properties
        ?.sheetId;
  }

  /// Generic wrapper around `spreadsheets.batchUpdate`. Use for operations
  /// that don't fit the `values.{get,update,clear}` API (data validations,
  /// formatting, sheet structure changes).
  Future<void> batchUpdate({
    required String spreadsheetId,
    required List<sheets.Request> requests,
  }) async {
    _assertReady();
    if (requests.isEmpty) return;
    await _api!.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(requests: requests),
      spreadsheetId,
    );
  }

  /// Applies formatting to the export sheet:
  /// - Header row: bold text + dark background + bottom border
  /// - Data rows: alternating background colors per week with vivid colors
  /// - Week separators: top border on Monday rows
  /// 
  /// [data] should be the first row as headers, followed by data rows.
  /// Column A is expected to contain dates in 'dd.MM.yyyy' format.
  Future<void> formatExportSheet({
    required String spreadsheetId,
    required String sheetName,
    required List<List<Object?>> data,
  }) async {
    _assertReady();
    if (data.isEmpty) return;

    // Get the sheet ID
    final meta = await _api!.spreadsheets.get(spreadsheetId);
    final sheetId = (meta.sheets ?? [])
        .firstWhere((s) => s.properties?.title == sheetName,
            orElse: () => sheets.Sheet())
        .properties
        ?.sheetId;
    if (sheetId == null) return;

    final updates = <sheets.Request>[];
    final columnCount = data.first.length;

    // ── Format header row (row 0) with dark background and border ─────────
    updates.add(sheets.Request(
      updateCells: sheets.UpdateCellsRequest(
        range: sheets.GridRange(
          sheetId: sheetId,
          startRowIndex: 0,
          endRowIndex: 1,
          startColumnIndex: 0,
          endColumnIndex: columnCount,
        ),
        rows: [
          sheets.RowData(
            values: List.generate(
              columnCount,
              (col) => sheets.CellData(
                userEnteredFormat: sheets.CellFormat(
                  textFormat: sheets.TextFormat(
                    bold: true,
                    fontSize: 11,
                    foregroundColor: sheets.Color(red: 1, green: 1, blue: 1),
                  ),
                  backgroundColor: sheets.Color(
                    red: 0.3,
                    green: 0.3,
                    blue: 0.3,
                  ),
                  borders: sheets.Borders(
                    bottom: sheets.Border(
                      style: 'SOLID',
                      width: 2,
                      color: sheets.Color(red: 0, green: 0, blue: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        fields: 'userEnteredFormat(textFormat,backgroundColor,borders)',
      ),
    ));

    // ── Format data rows with week-based coloring and borders ──────────────
    if (data.length > 1) {
      int currentWeek = 0;
      int? lastDayOfWeek;
      final dataRowUpdates = <sheets.RowData>[];

      for (int i = 1; i < data.length; i++) {
        final row = data[i];
        final dateStr = row.isNotEmpty ? row.first?.toString() ?? '' : '';
        final dayOfWeek = _getDayOfWeek(dateStr);

        // Check if this is Monday and we have a previous day
        final isMonday = dayOfWeek == DateTime.monday && lastDayOfWeek != null;
        if (isMonday) {
          currentWeek = 1 - currentWeek; // Toggle 0 ↔ 1
        }
        lastDayOfWeek = dayOfWeek;

        // Vivid alternating colors per week
        final bgColor = currentWeek == 0
            ? sheets.Color(red: 0.68, green: 0.85, blue: 1.0) // Vivid blue
            : sheets.Color(red: 1.0, green: 0.93, blue: 0.70); // Vivid orange

        // Create row data with formatting
        dataRowUpdates.add(
          sheets.RowData(
            values: List.generate(
              row.length,
              (col) => sheets.CellData(
                userEnteredFormat: sheets.CellFormat(
                  backgroundColor: bgColor,
                  borders: isMonday
                      ? sheets.Borders(
                          top: sheets.Border(
                            style: 'SOLID',
                            width: 2,
                            color: sheets.Color(red: 0.2, green: 0.2, blue: 0.2),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      }

      // Update data rows
      if (dataRowUpdates.isNotEmpty) {
        updates.add(sheets.Request(
          updateCells: sheets.UpdateCellsRequest(
            range: sheets.GridRange(
              sheetId: sheetId,
              startRowIndex: 1,
              endRowIndex: data.length,
              startColumnIndex: 0,
              endColumnIndex: columnCount,
            ),
            rows: dataRowUpdates,
            fields: 'userEnteredFormat(backgroundColor,borders)',
          ),
        ));
      }
    }

    // Execute all formatting updates
    if (updates.isNotEmpty) {
      await _api!.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: updates),
        spreadsheetId,
      );
    }
  }

  /// Extracts day of week (1=Monday, 7=Sunday) from date string in 'dd.MM.yyyy' format.
  /// Returns null if parsing fails.
  static int? _getDayOfWeek(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return null;

    final m = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(trimmed);
    if (m == null) return null;

    try {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final year = int.parse(m.group(3)!);
      final dt = DateTime(year, month, day);
      return dt.weekday; // 1=Monday, 7=Sunday
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  sheets.Sheet _makeSheet(String title, List<String> headers) {
    return sheets.Sheet(
      properties: sheets.SheetProperties(title: title),
      data: [
        sheets.GridData(
          startRow: 0,
          startColumn: 0,
          rowData: [
            sheets.RowData(
              values: headers
                  .map((h) => sheets.CellData(
                        userEnteredValue:
                            sheets.ExtendedValue(stringValue: h),
                        userEnteredFormat: sheets.CellFormat(
                          textFormat: sheets.TextFormat(bold: true),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  void _assertReady() {
    if (_api == null) {
      throw StateError('SheetsService is not initialized. Call initialize() first.');
    }
  }
}
