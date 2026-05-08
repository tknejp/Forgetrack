import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/application/bushido_export_provider.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_export_data_builder.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_sheets_service.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_data_sources.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week_utils.dart';
import 'package:forgetrack/features/health_connect/domain/activity_record.dart';
import 'package:forgetrack/features/health_connect/domain/weight_record.dart';
import 'package:forgetrack/features/nutrition/data/kaloricke_tabulky_service.dart'
    show KtDayNutrition;
import 'package:forgetrack/features/sheets_export/data/sheets_service.dart';
import 'package:forgetrack/l10n/app_localizations_en.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Fake Sheets layer — full enough that loadExistingWeekIndex on the second
// run sees what the first run wrote into column Z.
// ---------------------------------------------------------------------------

class _Write {
  final String range;
  final List<List<Object?>> values;
  const _Write(this.range, this.values);
}

class _FakeSheetsService extends SheetsService {
  final List<_Write> writes = [];
  final List<sheets.Request> batchRequests = [];
  final Map<int, String> zColumn = {}; // row → marker
  int sheetIdToReturn = 100;

  static final _zCellRange = RegExp(r'!Z(\d+)$');

  @override
  void initialize(http.Client authClient) {
    /* no-op */
  }

  @override
  bool get isReady => true;

  @override
  Future<sheets.Spreadsheet?> getSpreadsheet(String spreadsheetId) async =>
      sheets.Spreadsheet(spreadsheetId: spreadsheetId);

  @override
  Future<void> ensureSheetExists({
    required String spreadsheetId,
    required String sheetName,
  }) async {/* no-op */}

  @override
  Future<int?> getSheetId({
    required String spreadsheetId,
    required String sheetName,
  }) async =>
      sheetIdToReturn;

  @override
  Future<List<List<Object?>>> readRange({
    required String spreadsheetId,
    required String range,
  }) async {
    if (range.endsWith('!Z:Z')) {
      if (zColumn.isEmpty) return const [];
      final maxRow = zColumn.keys.reduce(math.max);
      return List.generate(maxRow, (i) {
        final row = i + 1;
        return zColumn.containsKey(row)
            ? <Object?>[zColumn[row]]
            : const <Object?>[];
      });
    }
    // Single Z-cell read (e.g. !Z1) — used by ensureSheetHeader.
    final zCellMatch = _zCellRange.firstMatch(range);
    if (zCellMatch != null) {
      final row = int.parse(zCellMatch.group(1)!);
      return zColumn.containsKey(row) ? [[zColumn[row]!]] : const [];
    }
    // !A:A and other reads — empty by default.
    return const [];
  }

  @override
  Future<void> writeRange({
    required String spreadsheetId,
    required String range,
    required List<List<Object?>> values,
  }) async {
    writes.add(_Write(range, values));
    final m = _zCellRange.firstMatch(range);
    if (m != null) {
      zColumn[int.parse(m.group(1)!)] = values.first.first.toString();
    }
  }

  @override
  Future<void> batchUpdate({
    required String spreadsheetId,
    required List<sheets.Request> requests,
  }) async {
    batchRequests.addAll(requests);
  }
}

// ---------------------------------------------------------------------------
// Fake data sources for the data builder.
// ---------------------------------------------------------------------------

class _FakeFitness implements BushidoFitnessSource {
  final Map<String, int> stepsMap;
  final Map<String, double> weightMap;

  _FakeFitness({this.stepsMap = const {}, this.weightMap = const {}});

  @override
  Future<List<StepsRecord>> stepsHistoryForRange(DateTime from, DateTime to) async {
    final out = <StepsRecord>[];
    var d = from;
    while (!d.isAfter(to)) {
      final key = _key(d);
      if (stepsMap.containsKey(key)) {
        out.add(StepsRecord(date: d, steps: stepsMap[key]!));
      }
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  @override
  Future<WeightRecord?> weightForDate(DateTime date) async {
    final w = weightMap[_key(date)];
    return w != null ? WeightRecord(date: date, weight: w) : null;
  }
}

class _FakeNutrition implements BushidoNutritionSource {
  final Map<String, KtDayNutrition> map;
  _FakeNutrition(this.map);

  @override
  Future<KtDayNutrition?> nutritionForDate(DateTime date) async => map[_key(date)];
}

String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

// ---------------------------------------------------------------------------

const _expectedSpreadsheetId = 'spreadsheet-xyz';

({
  BushidoExportProvider provider,
  _FakeSheetsService fakeSheets,
  int Function() refreshFitnessCount,
  int Function() refreshNutritionCount,
}) _wire({
  Map<String, int> steps = const {},
  Map<String, double> weight = const {},
  Map<String, KtDayNutrition> nutrition = const {},
}) {
  final fakeSheets = _FakeSheetsService();
  final builder = BushidoExportDataBuilder(
    fitness: _FakeFitness(stepsMap: steps, weightMap: weight),
    nutrition: _FakeNutrition(nutrition),
  );
  // Override BushidoSheetsService prepare path: the auth/bootstrap branch
  // calls SharedPreferences. Sidestep by constructing the service with a
  // fake whose getSpreadsheet returns valid metadata, but we still need a
  // spreadsheet id from prefs. Approach: subclass BushidoSheetsService to
  // short-circuit prepare for tests.
  final sheetsSvc = _TestableBushidoSheetsService(
    fakeSheets: fakeSheets,
    spreadsheetId: _expectedSpreadsheetId,
  );

  var fitnessCalls = 0;
  var nutritionCalls = 0;

  final provider = BushidoExportProvider(
    sheets: sheetsSvc,
    dataBuilder: builder,
    refreshFitness: (from, to) async {
      fitnessCalls++;
    },
    refreshNutrition: (from, to) async {
      nutritionCalls++;
    },
  );

  return (
    provider: provider,
    fakeSheets: fakeSheets,
    refreshFitnessCount: () => fitnessCalls,
    refreshNutritionCount: () => nutritionCalls,
  );
}

/// BushidoSheetsService whose `prepare` skips auth + SharedPreferences and
/// returns a deterministic spreadsheet id + sheet id. All other methods
/// inherit the real lookup/append/writeAutoCells logic, delegated through
/// the fake `SheetsService`.
class _TestableBushidoSheetsService extends BushidoSheetsService {
  final _FakeSheetsService _fakeSheets;
  final String _spreadsheetId;

  _TestableBushidoSheetsService({
    required _FakeSheetsService fakeSheets,
    required String spreadsheetId,
  })  : _fakeSheets = fakeSheets,
        _spreadsheetId = spreadsheetId,
        super(sheets: fakeSheets);

  @override
  Future<({int sheetId, String sheetName, String spreadsheetId})> prepare(
    dynamic l10n,
  ) async =>
      (
        spreadsheetId: _spreadsheetId,
        sheetId: _fakeSheets.sheetIdToReturn,
        sheetName: 'Coach Log',
      );
}

// ---------------------------------------------------------------------------

void main() {
  final l10n = AppLocalizationsEn();

  group('BushidoExportProvider.exportRange', () {
    test('three weeks, middle empty → all 3 blocks + next-week block exist; '
        'middle week\'s auto cells are blank', () async {
      // Pick three consecutive ISO weeks.
      final wA = IsoWeek.fromDate(DateTime(2026, 1, 5)); // 2026-W02
      final wB = IsoWeek.fromDate(DateTime(2026, 1, 12)); // 2026-W03 (middle)
      final wC = IsoWeek.fromDate(DateTime(2026, 1, 19)); // 2026-W04
      final nextW = nextIsoWeekAfter(wC.sunday); // 2026-W05

      // Seed weeks A and C with steps; week B has nothing.
      Map<String, int> steps = {};
      for (var i = 0; i < 7; i++) {
        steps[_key(wA.monday.add(Duration(days: i)))] = 5000 + i;
        steps[_key(wC.monday.add(Duration(days: i)))] = 6000 + i;
      }

      final w = _wire(steps: steps);

      await w.provider.exportRange(
        from: wA.monday,
        to: wC.sunday,
        l10n: l10n,
      );

      // Markers for all 4 blocks (3 input weeks + next-week seed).
      final expectedMarkers = {
        'BUSHIDO_WEEK:${wA.year}-W${wA.weekNumber.toString().padLeft(2, '0')}:v1',
        'BUSHIDO_WEEK:${wB.year}-W${wB.weekNumber.toString().padLeft(2, '0')}:v1',
        'BUSHIDO_WEEK:${wC.year}-W${wC.weekNumber.toString().padLeft(2, '0')}:v1',
        'BUSHIDO_WEEK:${nextW.year}-W${nextW.weekNumber.toString().padLeft(2, '0')}:v1',
      };
      // Filter out the sheet header marker written by ensureSheetHeader.
      final weekMarkers = w.fakeSheets.zColumn.values
          .where((v) => v.startsWith('BUSHIDO_WEEK:'))
          .toSet();
      expect(weekMarkers, expectedMarkers);

      // Each input week (not the seed) got a writeAutoCells call → 3 such writes.
      final autoCellsWrites = w.fakeSheets.writes
          .where((wr) => RegExp(r'!A\d+:H\d+$').hasMatch(wr.range))
          .toList();
      expect(autoCellsWrites.length, 3);

      // Identify the middle-week (wB) writeAutoCells by date in column A.
      final middleWrite = autoCellsWrites.firstWhere(
        (wr) => (wr.values.first.first as String).startsWith('12.01'),
      );
      // Every metric cell on every day is blank for the middle week.
      for (final row in middleWrite.values) {
        // Column A (index 0) is date — non-empty. Columns 1..7 are metrics.
        for (var i = 1; i < row.length; i++) {
          expect(row[i], '',
              reason: 'middle week metric cell should be blank, got ${row[i]}');
        }
      }

      // Refresh callbacks fired exactly once.
      expect(w.refreshFitnessCount(), 1);
      expect(w.refreshNutritionCount(), 1);
    });

    test('re-export of the same range is idempotent', () async {
      final week = IsoWeek.fromDate(DateTime(2026, 1, 5));
      final w = _wire(steps: {
        for (var i = 0; i < 7; i++)
          _key(week.monday.add(Duration(days: i))): 7000,
      });

      // First export.
      await w.provider.exportRange(
        from: week.monday,
        to: week.sunday,
        l10n: l10n,
      );

      final markersAfterFirst = Map<int, String>.from(w.fakeSheets.zColumn);
      final batchAfterFirst = w.fakeSheets.batchRequests.length;
      final writesAfterFirst = w.fakeSheets.writes.length;

      // Second export — same range.
      await w.provider.exportRange(
        from: week.monday,
        to: week.sunday,
        l10n: l10n,
      );

      // Z column unchanged: no duplicate blocks appended.
      expect(w.fakeSheets.zColumn, markersAfterFirst);

      // No new validation requests (ensureWeekBlock cache-hit on every week).
      expect(w.fakeSheets.batchRequests.length, batchAfterFirst);

      // Second pass writes only the auto-cell ranges (one per input week,
      // here just 1) — no new block-grid (A:O) or marker (Z) writes.
      final secondPassWrites = w.fakeSheets.writes.skip(writesAfterFirst).toList();
      expect(secondPassWrites.length, 1);
      expect(
        RegExp(r'!A\d+:H\d+$').hasMatch(secondPassWrites.single.range),
        isTrue,
      );
    });

    test('after exportRange(from, to) the next-week block exists', () async {
      final week = IsoWeek.fromDate(DateTime(2026, 1, 5));
      final next = nextIsoWeekAfter(week.sunday);
      final w = _wire();

      await w.provider.exportRange(
        from: week.monday,
        to: week.sunday,
        l10n: l10n,
      );

      final marker =
          'BUSHIDO_WEEK:${next.year}-W${next.weekNumber.toString().padLeft(2, '0')}:v1';
      expect(w.fakeSheets.zColumn.values, contains(marker));
    });

    test('reverse range throws BushidoExportException', () async {
      final w = _wire();

      expect(
        () => w.provider.exportRange(
          from: DateTime(2026, 1, 10),
          to: DateTime(2026, 1, 5),
          l10n: l10n,
        ),
        throwsA(isA<BushidoExportException>()),
      );
      // No work was done.
      expect(w.fakeSheets.writes, isEmpty);
    });

    test('isExporting toggles around the call and notifies listeners',
        () async {
      final w = _wire();
      final week = IsoWeek.fromDate(DateTime(2026, 1, 5));

      var notifications = 0;
      w.provider.addListener(() => notifications++);

      expect(w.provider.isExporting, isFalse);
      final future = w.provider.exportRange(
        from: week.monday,
        to: week.sunday,
        l10n: l10n,
      );
      // After the synchronous prefix (which calls notifyListeners),
      // isExporting is true.
      expect(w.provider.isExporting, isTrue);
      await future;
      expect(w.provider.isExporting, isFalse);
      expect(notifications, greaterThanOrEqualTo(2)); // start + finish
      expect(w.provider.lastResult, isNotNull);
      expect(w.provider.lastError, isNull);
    });
  });
}
