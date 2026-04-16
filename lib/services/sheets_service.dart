import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Obal nad Google Sheets API v4.
/// Inicializuj voláním [initialize] s autentizovaným HTTP klientem.
class SheetsService {
  sheets.SheetsApi? _api;

  void initialize(http.Client authClient) {
    _api = sheets.SheetsApi(authClient);
  }

  bool get isReady => _api != null;

  // --- Spreadsheet ---

  /// Vytvoří nový spreadsheet s výchozími listy a vrátí jeho ID.
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

  /// Připojí řádky na konec listu. [range] např. "Kroky!A1".
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

  /// Přečte všechny hodnoty z daného rozsahu.
  Future<List<List<Object?>>> readRange({
    required String spreadsheetId,
    required String range,
  }) async {
    _assertReady();
    final result = await _api!.spreadsheets.values.get(spreadsheetId, range);
    return result.values ?? [];
  }

  // --- Helpers ---

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
      throw StateError(
          'SheetsService není inicializována. Zavolej nejdříve initialize().');
    }
  }
}
