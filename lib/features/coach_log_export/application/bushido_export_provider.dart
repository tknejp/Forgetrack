import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:forgetrack/core/logging/app_log.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_export_data_builder.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_sheets_service.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week_utils.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

typedef BushidoRefreshFn = Future<void> Function(DateTime from, DateTime to);

@immutable
class BushidoExportResult {
  final String spreadsheetId;
  final String spreadsheetUrl;
  final int weeksExported;
  final IsoWeek firstWeek;
  final IsoWeek lastWeek;

  const BushidoExportResult({
    required this.spreadsheetId,
    required this.spreadsheetUrl,
    required this.weeksExported,
    required this.firstWeek,
    required this.lastWeek,
  });
}

/// Orchestrates the Bushido coach-log export pipeline:
/// refresh upstream data → ensure week blocks → write auto cells → seed
/// the next-week block. Produces a [BushidoExportResult] for UI feedback.
class BushidoExportProvider extends ChangeNotifier {
  final BushidoSheetsService _sheets;
  final BushidoExportDataBuilder _dataBuilder;
  final BushidoRefreshFn _refreshFitness;
  final BushidoRefreshFn _refreshNutrition;
  final DateTime Function() _now;

  BushidoExportProvider({
    required BushidoSheetsService sheets,
    required BushidoExportDataBuilder dataBuilder,
    required BushidoRefreshFn refreshFitness,
    required BushidoRefreshFn refreshNutrition,
    DateTime Function()? now,
  })  : _sheets = sheets,
        _dataBuilder = dataBuilder,
        _refreshFitness = refreshFitness,
        _refreshNutrition = refreshNutrition,
        _now = now ?? DateTime.now;

  // ─── Observable state ──────────────────────────────────────────────────────

  bool _isExporting = false;
  String? _lastError;
  BushidoExportResult? _lastResult;

  bool get isExporting => _isExporting;
  String? get lastError => _lastError;
  BushidoExportResult? get lastResult => _lastResult;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Exports every ISO week overlapping `[from, to]` plus the immediately
  /// following week (seeded as an empty block so the coach has a fresh
  /// canvas to fill).
  Future<BushidoExportResult> exportRange({
    required DateTime from,
    required DateTime to,
    required AppLocalizations l10n,
  }) async {
    final start = dateOnly(from);
    final end = dateOnly(to);
    if (end.isBefore(start)) {
      throw BushidoExportException(l10n.exportErrorInvalidRange);
    }

    _isExporting = true;
    _lastError = null;
    notifyListeners();

    try {
      AppLog.sync.info(
        'bushido.exportRange: $start → $end',
      );

      // 1) Refresh upstream sources in parallel.
      await Future.wait([
        _refreshFitness(start, end),
        _refreshNutrition(start, end),
      ]);

      // 2) Compute weeks and prepare the spreadsheet.
      final weeks = isoWeeksOverlapping(start, end);
      final prep = await _sheets.prepare(l10n);

      // 2b) Write the sticky profile header on the first export (idempotent).
      final hasSheetHeader = await _sheets.ensureSheetHeader(
        spreadsheetId: prep.spreadsheetId,
        sheetId: prep.sheetId,
        sheetName: prep.sheetName,
      );

      // 3) Load existing-week index once and reuse the cache for all
      //    ensureWeekBlock calls in this run.
      final cache = await _sheets.loadExistingWeekIndex(
        spreadsheetId: prep.spreadsheetId,
        sheetName: prep.sheetName,
      );

      // 4) Per week: ensure block + write auto cells.
      final currentWeek = IsoWeek.fromDate(_now());
      for (final week in weeks) {
        final startRow = await _sheets.ensureWeekBlock(
          spreadsheetId: prep.spreadsheetId,
          sheetId: prep.sheetId,
          sheetName: prep.sheetName,
          week: week,
          startRowCache: cache,
        );
        final report = await _dataBuilder.build(week);
        await _sheets.writeAutoCells(
          spreadsheetId: prep.spreadsheetId,
          sheetName: prep.sheetName,
          week: week,
          startRow: startRow,
          dayRows: report.days,
        );
      }

      // 5) Seed the next-week block so the coach finds an empty block ready
      //    to fill in. Idempotent via cache for re-exports.
      final nextWeek = nextIsoWeekAfter(end);
      await _sheets.ensureWeekBlock(
        spreadsheetId: prep.spreadsheetId,
        sheetId: prep.sheetId,
        sheetName: prep.sheetName,
        week: nextWeek,
        startRowCache: cache,
      );

      final currentWeekStartRow = cache[currentWeek];
      if (hasSheetHeader && currentWeekStartRow != null) {
        await _sheets.updateCurrentWeekHeaderLink(
          spreadsheetId: prep.spreadsheetId,
          sheetId: prep.sheetId,
          sheetName: prep.sheetName,
          startRow: currentWeekStartRow,
        );
      }

      final result = BushidoExportResult(
        spreadsheetId: prep.spreadsheetId,
        spreadsheetUrl:
            'https://docs.google.com/spreadsheets/d/${prep.spreadsheetId}',
        weeksExported: weeks.length,
        firstWeek: weeks.first,
        lastWeek: weeks.last,
      );
      _lastResult = result;

      AppLog.sync.success(
        'bushido.exportRange: done — ${weeks.length} week(s) + 1 next-week block',
        payload: result.spreadsheetUrl,
      );
      return result;
    } catch (e, st) {
      _lastError = _friendlyErrorMessage(e, l10n);
      AppLog.sync.error(
        'bushido.exportRange: failed',
        err: e,
        stackTrace: st,
      );
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Maps caught exceptions to a localized, user-facing message. Anything not
  /// recognized falls back to a generic "Export failed" wrapper instead of the
  /// raw `toString()` (which leaks SDK internals like
  /// `GoogleSignInException(code …, SDK reported an exception: 16: …)`).
  String _friendlyErrorMessage(Object error, AppLocalizations l10n) {
    if (error is BushidoExportException) {
      // Already user-facing — built from l10n at the throw site.
      return error.message;
    }
    if (error is GoogleSignInException) {
      final description = error.description?.toLowerCase() ?? '';
      final isCancelled =
          error.code == GoogleSignInExceptionCode.canceled ||
              description.contains('cancel');
      if (isCancelled) {
        return l10n.exportErrorSignInCancelled;
      }
      return l10n.exportErrorNotSignedIn;
    }
    if (error is SocketException) {
      return l10n.exportErrorNetwork;
    }
    return l10n.exportErrorPrefix(l10n.exportErrorGeneric);
  }

  /// Exports the current ISO week up to (and including) today.
  Future<BushidoExportResult> exportCurrentWeek({
    required AppLocalizations l10n,
  }) {
    final today = _now();
    return exportRange(
      from: startOfIsoWeek(today),
      to: today,
      l10n: l10n,
    );
  }
}
