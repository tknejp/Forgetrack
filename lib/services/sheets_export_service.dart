import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_log.dart';
import '../core/constants.dart';
import '../models/sheet_export_field.dart';
import 'google_auth_service.dart';
import 'sheets_export/sheet_merge_engine.dart';
import 'sheets_service.dart';

class SheetsExportException implements Exception {
  final String message;
  const SheetsExportException(this.message);
  @override
  String toString() => 'SheetsExportException: $message';
}

class SheetsExportResult {
  final int rowsWritten;
  final int rowsAdded;
  final int rowsUpdated;
  final String spreadsheetId;
  final String spreadsheetUrl;

  const SheetsExportResult({
    required this.rowsWritten,
    required this.rowsAdded,
    required this.rowsUpdated,
    required this.spreadsheetId,
    required this.spreadsheetUrl,
  });
}

/// Coordinates the full Sheets-export pipeline:
/// auth → spreadsheet bootstrap → read existing → merge by date → write back.
///
/// All Sheets API access is delegated to [SheetsService]; merge math lives in
/// [SheetMergeEngine]. This class owns the orchestration and logging.
class SheetsExportService {
  final SheetsService _sheets;
  final GoogleAuthService _auth;

  SheetsExportService({
    SheetsService? sheets,
    GoogleAuthService? auth,
  })  : _sheets = sheets ?? SheetsService(),
        _auth = auth ?? GoogleAuthService.instance;

  // ─── Spreadsheet ID persistence ────────────────────────────────────────────

  Future<String?> loadSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefSpreadsheetId);
  }

  Future<void> _saveSpreadsheetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefSpreadsheetId, id);
  }

  Future<void> clearSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSpreadsheetId);
  }

  String spreadsheetUrl(String id) =>
      'https://docs.google.com/spreadsheets/d/$id';

  // ─── Bootstrap ─────────────────────────────────────────────────────────────

  /// Ensures Sheets API is ready. Returns the spreadsheet id (creating one if
  /// necessary) and the canonical sheet/tab name.
  Future<({String spreadsheetId, String sheetName})> _prepare() async {
    AppLog.sync.info('prepare: requesting auth client');
    final client = await _auth.getAuthClient();
    if (client == null) {
      throw const SheetsExportException(
        'Not signed in to Google. Sign in to enable Sheets export.',
      );
    }
    _sheets.initialize(client);

    var spreadsheetId = await loadSpreadsheetId();

    if (spreadsheetId != null) {
      final meta = await _sheets.getSpreadsheet(spreadsheetId);
      if (meta == null) {
        AppLog.sync.warn(
          'prepare: stored spreadsheet not accessible — creating a new one',
          payload: spreadsheetId,
        );
        spreadsheetId = null;
      }
    }

    if (spreadsheetId == null) {
      AppLog.sync.info('prepare: creating new export spreadsheet');
      spreadsheetId = await _sheets.createExportSpreadsheet();
      await _saveSpreadsheetId(spreadsheetId);
      AppLog.sync.success('prepare: spreadsheet created', payload: spreadsheetId);
    }

    await _sheets.ensureSheetExists(
      spreadsheetId: spreadsheetId,
      sheetName: AppConstants.exportSheetName,
    );

    return (
      spreadsheetId: spreadsheetId,
      sheetName: AppConstants.exportSheetName,
    );
  }

  /// Returns the configured spreadsheet info (id + url) if any, without
  /// mutating state. Useful for showing the target before the user exports.
  Future<({String id, String url})?> currentTarget() async {
    final id = await loadSpreadsheetId();
    if (id == null) return null;
    return (id: id, url: spreadsheetUrl(id));
  }

  // ─── Export ────────────────────────────────────────────────────────────────

  /// Builds export rows for [from..to] using [selected] fields and [src],
  /// merges by date with the existing sheet, and writes the result back.
  Future<SheetsExportResult> export({
    required DateTime from,
    required DateTime to,
    required List<SheetExportField> selected,
    required SheetExportDataSources src,
  }) async {
    if (selected.isEmpty) {
      throw const SheetsExportException('Select at least one field to export.');
    }
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    if (end.isBefore(start)) {
      throw const SheetsExportException('Invalid range: "to" is before "from".');
    }

    final prep = await _prepare();
    final spreadsheetId = prep.spreadsheetId;
    final sheetName = prep.sheetName;

    AppLog.sync.info(
      'export: range ${_key(start)} → ${_key(end)} '
      '(${selected.length} field(s))',
      payload: selected.map((f) => f.key).join(','),
    );

    // Build new rows by date.
    final newRows = <String, Map<String, Object?>>{};
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = _key(d);
      final row = <String, Object?>{};
      for (final f in selected) {
        row[f.header] = f.resolve(d, src);
      }
      newRows[key] = row;
    }

    // Read existing sheet content (full reasonable range; A1:ZZ covers 702 cols).
    AppLog.sync.info('export: reading existing sheet "$sheetName"');
    final existing = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1:ZZ',
    );
    AppLog.sync.debug('export: existing rows=${existing.length}');

    // Merge.
    final selectedHeaders = selected.map((f) => f.header).toList();
    final merge = SheetMergeEngine.merge(
      existing: existing,
      selectedHeaders: selectedHeaders,
      newRowsByDate: newRows,
    );
    AppLog.sync.info(
      'export: merged — totalRows=${merge.rows.length} '
      'added=${merge.addedDates} updated=${merge.updatedDates}',
    );

    // Write back. Clear A1:ZZ first so any rows beyond the new last row are
    // removed (the row count may shrink if the user changed the range).
    AppLog.sync.info('export: clearing prior range');
    await _sheets.clearRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1:ZZ',
    );

    final body = <List<Object?>>[merge.headers, ...merge.rows];
    AppLog.sync.info('export: writing ${body.length} row(s)');
    await _sheets.writeRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1',
      values: body,
    );

    AppLog.sync.success(
      'export: done — wrote ${merge.rows.length} data row(s)',
      payload: spreadsheetUrl(spreadsheetId),
    );

    return SheetsExportResult(
      rowsWritten: merge.rows.length,
      rowsAdded: merge.addedDates,
      rowsUpdated: merge.updatedDates,
      spreadsheetId: spreadsheetId,
      spreadsheetUrl: spreadsheetUrl(spreadsheetId),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
