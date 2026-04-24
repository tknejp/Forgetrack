import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_log.dart';
import '../../../core/constants.dart';
import '../../../l10n/app_localizations.dart';
import '../data/sheets_service.dart';
import '../domain/sheet_export_field.dart';
import '../domain/sheet_merge_engine.dart';
import 'google_sheets_auth_service.dart';

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
  final GoogleSheetsAuthService _sheetsAuth;

  SheetsExportService({
    SheetsService? sheets,
    GoogleSheetsAuthService? sheetsAuth,
  })  : _sheets = sheets ?? SheetsService(),
        _sheetsAuth = sheetsAuth ?? GoogleSheetsAuthService();

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

  Future<({String spreadsheetId, String sheetName})> _prepare(
    AppLocalizations l10n,
  ) async {
    AppLog.sync.info('prepare: requesting Sheets auth client');
    final client = await _sheetsAuth.getAuthClient(interactive: true);
    if (client == null) {
      throw SheetsExportException(l10n.exportErrorNotSignedIn);
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
      AppLog.sync
          .success('prepare: spreadsheet created', payload: spreadsheetId);
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

  Future<SheetsExportResult> export({
    required DateTime from,
    required DateTime to,
    required List<SheetExportField> selected,
    required SheetExportDataSources src,
    required AppLocalizations l10n,
  }) async {
    if (selected.isEmpty) {
      throw SheetsExportException(l10n.exportErrorNoFields);
    }
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    if (end.isBefore(start)) {
      throw SheetsExportException(l10n.exportErrorInvalidRange);
    }

    final prep = await _prepare(l10n);
    final spreadsheetId = prep.spreadsheetId;
    final sheetName = prep.sheetName;

    // Sort selected fields by their declared catalog order to enforce a
    // stable, predictable column layout regardless of the UI selection order.
    final orderedSelected = [...selected]
      ..sort((a, b) => a.order.compareTo(b.order));
    final dateHeader = l10n.exportHeaderDate;
    final orderedSelectedHeaders =
        orderedSelected.map((f) => f.header(l10n)).toList();

    AppLog.sync.info(
      'export: range ${_isoKey(start)} → ${_isoKey(end)} '
      '(${orderedSelected.length} field(s))',
      payload: orderedSelected.map((f) => f.key).join(','),
    );

    // Build new rows by ISO date — header keys are localized current headers.
    final newRows = <String, Map<String, Object?>>{};
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = _isoKey(d);
      final row = <String, Object?>{};
      for (final f in orderedSelected) {
        row[f.header(l10n)] = f.resolve(d, src);
      }
      newRows[key] = row;
    }

    AppLog.sync.info('export: reading existing sheet "$sheetName"');
    final existing = await _sheets.readRange(
      spreadsheetId: spreadsheetId,
      range: '$sheetName!A1:ZZ',
    );
    AppLog.sync.debug('export: existing rows=${existing.length}');

    // Build legacy → current header rename map across the whole catalog so
    // the merge engine can migrate sheets created with prior versions.
    final legacyMap = <String, String>{};
    for (final f in SheetExportFields.all) {
      final current = f.header(l10n);
      for (final legacy in f.legacyHeaders) {
        if (legacy == current) continue;
        legacyMap[legacy] = current;
      }
    }

    final displayFmt = DateFormat('dd.MM.yyyy');
    final merge = SheetMergeEngine.merge(
      existing: existing,
      dateHeader: dateHeader,
      orderedSelectedHeaders: orderedSelectedHeaders,
      legacyHeaderMap: legacyMap,
      newRowsByIsoDate: newRows,
      formatDateCell: (iso) {
        final dt = DateTime.tryParse(iso);
        return dt == null ? iso : displayFmt.format(dt);
      },
      parseIsoDate: _parseIsoOrDottedDate,
    );
    AppLog.sync.info(
      'export: merged — totalRows=${merge.rows.length} '
      'added=${merge.addedDates} updated=${merge.updatedDates}',
    );

    // Clear A1:ZZ first so any rows beyond the new last row are removed
    // (the row count may shrink if the user changed the range).
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

  static String _isoKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Parses both the canonical ISO format (`yyyy-MM-dd`) and the legacy
  /// dotted display format (`dd.MM.yyyy`). Returns the ISO key, or null when
  /// the input cannot be interpreted as a date.
  static String? _parseIsoOrDottedDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return _isoKey(iso);
    final m = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(s);
    if (m != null) {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final year = int.parse(m.group(3)!);
      try {
        final dt = DateTime(year, month, day);
        if (dt.year == year && dt.month == month && dt.day == day) {
          return _isoKey(dt);
        }
      } catch (_) {}
    }
    return null;
  }
}
