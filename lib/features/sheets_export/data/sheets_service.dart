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
