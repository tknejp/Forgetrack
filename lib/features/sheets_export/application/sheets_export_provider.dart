import 'package:flutter/foundation.dart';

import '../../../core/logging/app_log.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/sheet_export_field.dart';
import 'sheets_export_service.dart';

enum SheetsExportStatus { idle, exporting, success, error }

class SheetsExportProvider extends ChangeNotifier {
  final SheetsExportService _service;

  SheetsExportProvider({SheetsExportService? service})
      : _service = service ?? SheetsExportService() {
    // Default: last 30 days, all fields enabled.
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 29));
    _selectedKeys = {for (final f in SheetExportFields.all) f.key};
    _loadTarget();
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  late DateTime _from;
  late DateTime _to;
  late Set<String> _selectedKeys;

  SheetsExportStatus _status = SheetsExportStatus.idle;
  String? _errorMessage;
  SheetsExportResult? _lastResult;
  String? _spreadsheetId;
  String? _spreadsheetUrl;

  // ─── Getters ───────────────────────────────────────────────────────────────

  DateTime get from => _from;
  DateTime get to => _to;
  Set<String> get selectedKeys => _selectedKeys;
  SheetsExportStatus get status => _status;
  bool get isExporting => _status == SheetsExportStatus.exporting;
  String? get errorMessage => _errorMessage;
  SheetsExportResult? get lastResult => _lastResult;
  String? get spreadsheetId => _spreadsheetId;
  String? get spreadsheetUrl => _spreadsheetUrl;

  int get dayCount => _to.difference(_from).inDays + 1;
  bool get hasValidRange => !_to.isBefore(_from);
  bool get hasAnyFieldSelected => _selectedKeys.isNotEmpty;
  bool get canExport => !isExporting && hasValidRange && hasAnyFieldSelected;

  List<SheetExportField> get selectedFields => [
        for (final f in SheetExportFields.all)
          if (_selectedKeys.contains(f.key)) f,
      ];

  // ─── Mutations ─────────────────────────────────────────────────────────────

  void setRange(DateTime from, DateTime to) {
    _from = DateTime(from.year, from.month, from.day);
    _to = DateTime(to.year, to.month, to.day);
    notifyListeners();
  }

  void setFrom(DateTime d) {
    _from = DateTime(d.year, d.month, d.day);
    if (_to.isBefore(_from)) _to = _from;
    notifyListeners();
  }

  void setTo(DateTime d) {
    _to = DateTime(d.year, d.month, d.day);
    if (_to.isBefore(_from)) _from = _to;
    notifyListeners();
  }

  void toggleField(String key, bool enabled) {
    if (enabled) {
      _selectedKeys.add(key);
    } else {
      _selectedKeys.remove(key);
    }
    notifyListeners();
  }

  void selectAllFields() {
    _selectedKeys = {for (final f in SheetExportFields.all) f.key};
    notifyListeners();
  }

  void clearAllFields() {
    _selectedKeys.clear();
    notifyListeners();
  }

  void resetMessage() {
    if (_status == SheetsExportStatus.idle) return;
    _status = SheetsExportStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Spreadsheet target ────────────────────────────────────────────────────

  Future<void> _loadTarget() async {
    final target = await _service.currentTarget();
    _spreadsheetId = target?.id;
    _spreadsheetUrl = target?.url;
    notifyListeners();
  }

  Future<void> refreshTarget() => _loadTarget();

  Future<void> forgetSpreadsheet() async {
    await _service.clearSpreadsheetId();
    _spreadsheetId = null;
    _spreadsheetUrl = null;
    notifyListeners();
  }

  // ─── Export ────────────────────────────────────────────────────────────────

  Future<void> runExport(
    SheetExportDataSources src, {
    required AppLocalizations l10n,
  }) async {
    if (isExporting) {
      AppLog.sync.debug('runExport: skipped — already exporting');
      return;
    }
    if (!hasValidRange) {
      _failWith(l10n.exportErrorInvalidRange);
      return;
    }
    if (!hasAnyFieldSelected) {
      _failWith(l10n.exportErrorNoFields);
      return;
    }

    _status = SheetsExportStatus.exporting;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      final result = await _service.export(
        from: _from,
        to: _to,
        selected: selectedFields,
        src: src,
        l10n: l10n,
      );
      _lastResult = result;
      _spreadsheetId = result.spreadsheetId;
      _spreadsheetUrl = result.spreadsheetUrl;
      _status = SheetsExportStatus.success;
    } on SheetsExportException catch (e) {
      AppLog.sync.warn('runExport: export failed', payload: e.message);
      _failWith(e.message);
      return;
    } catch (e, st) {
      AppLog.sync.error('runExport: unexpected error', err: e, stackTrace: st);
      _failWith(l10n.exportErrorPrefix(e.toString()));
      return;
    }
    notifyListeners();
  }

  void _failWith(String message) {
    _errorMessage = message;
    _status = SheetsExportStatus.error;
    notifyListeners();
  }
}
