import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/data/bushido_sheets_service.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_day_row.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_export_config.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_sheet_layout.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';
import 'package:forgetrack/features/sheets_export/data/sheets_service.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Fake SheetsService — captures writeRange / batchUpdate calls and serves
// readRange responses from a preconfigured map.
// ---------------------------------------------------------------------------

class _Write {
  final String range;
  final List<List<Object?>> values;
  const _Write(this.range, this.values);
}

class _FakeSheetsService extends SheetsService {
  final Map<String, List<List<Object?>>> readMap = {};
  final List<_Write> writes = [];
  final List<sheets.Request> batchRequests = [];
  int sheetIdToReturn = 100;

  @override
  void initialize(http.Client authClient) {
    /* no-op */
  }

  @override
  bool get isReady => true;

  @override
  Future<sheets.Spreadsheet?> getSpreadsheet(String spreadsheetId) async {
    return sheets.Spreadsheet(
      spreadsheetId: spreadsheetId,
      sheets: [
        sheets.Sheet(
          properties: sheets.SheetProperties(
            sheetId: sheetIdToReturn,
            title: 'Coach Log',
          ),
        ),
      ],
    );
  }

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
    return readMap[range] ?? const [];
  }

  @override
  Future<void> writeRange({
    required String spreadsheetId,
    required String range,
    required List<List<Object?>> values,
  }) async {
    writes.add(_Write(range, values));
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

const _spreadsheetId = 'spreadsheet-xyz';
const _sheetName = 'Coach Log';

BushidoSheetsService _service(_FakeSheetsService fake) =>
    BushidoSheetsService(sheets: fake);

_Write _findWrite(_FakeSheetsService fake, String suffix) =>
    fake.writes.firstWhere((w) => w.range.endsWith(suffix),
        orElse: () =>
            throw StateError('No write matching "$suffix"; got ${fake.writes.map((w) => w.range).toList()}'));

void main() {
  group('BushidoSheetsService.loadExistingWeekIndex', () {
    test('empty sheet → empty map', () async {
      final fake = _FakeSheetsService();
      final map = await _service(fake).loadExistingWeekIndex(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
      );
      expect(map, isEmpty);
    });

    test('single current-version marker → mapped to its row', () async {
      final fake = _FakeSheetsService();
      // Z:Z, marker on row 5 (1-indexed). Rows 1..4 are empty arrays.
      fake.readMap['$_sheetName!Z:Z'] = [
        const [],
        const [],
        const [],
        const [],
        ['BUSHIDO_WEEK:2026-W18:v1'],
      ];
      final map = await _service(fake).loadExistingWeekIndex(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
      );

      expect(map.length, 1);
      final entry = map.entries.single;
      expect(entry.key.year, 2026);
      expect(entry.key.weekNumber, 18);
      expect(entry.value, 5);
    });

    test('foreign-version marker → skipped (empty map)', () async {
      final fake = _FakeSheetsService();
      fake.readMap['$_sheetName!Z:Z'] = [
        const [],
        ['BUSHIDO_WEEK:2026-W18:v2'],
      ];
      final map = await _service(fake).loadExistingWeekIndex(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
      );
      expect(map, isEmpty);
    });

    test('mix of versions → only current version is returned', () async {
      final fake = _FakeSheetsService();
      final rows = List.generate(17, (_) => const <Object?>[]);
      rows[4] = ['BUSHIDO_WEEK:2026-W18:v1']; // row 5
      rows[16] = ['BUSHIDO_WEEK:2026-W19:v2']; // row 17
      fake.readMap['$_sheetName!Z:Z'] = rows;

      final map = await _service(fake).loadExistingWeekIndex(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
      );

      expect(map.length, 1);
      final entry = map.entries.single;
      expect(entry.key.weekNumber, 18);
      expect(entry.value, 5);
    });
  });

  group('BushidoSheetsService.ensureWeekBlock', () {
    test('week already in cache → returns cached row, no writes', () async {
      final fake = _FakeSheetsService();
      final week = IsoWeek.fromDate(DateTime(2026, 5, 4)); // 2026-W18 starts 2026-04-27, but easier: any week
      final cache = <IsoWeek, int>{week: 5};

      final row = await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );

      expect(row, 5);
      expect(fake.writes, isEmpty);
      expect(fake.batchRequests, isEmpty);
    });

    test('empty cache + empty sheet → appends at row headerRows+1, marker at Z(headerRows+1)', () async {
      final fake = _FakeSheetsService();
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1)); // 2026-W01
      final cache = <IsoWeek, int>{};

      final row = await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );

      final expectedRow = BushidoSheetLayout.headerRows + 1;
      expect(row, expectedRow);
      expect(cache[week], expectedRow);

      final markerWrite = _findWrite(fake, '!Z$expectedRow');
      expect(markerWrite.values.first.first, 'BUSHIDO_WEEK:2026-W01:v1');
    });

    test('empty cache + non-empty A:A → startRow follows lastFilledRow + spacer', () async {
      final fake = _FakeSheetsService();
      // 7 rows of arbitrary content already in column A.
      fake.readMap['$_sheetName!A:A'] = List.generate(7, (i) => ['x']);
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1));
      final cache = <IsoWeek, int>{};

      final row = await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );

      // 7 + spacer(1) + 1 = 9
      expect(row, 7 + BushidoSheetLayout.spacerRowsBetweenWeeks + 1);
    });

    test('cache has existing block → next block lands strictly past it', () async {
      final fake = _FakeSheetsService();
      final w18 = IsoWeek.fromDate(DateTime(2026, 4, 30)); // some week
      final cache = <IsoWeek, int>{w18: 5};
      final w19 = IsoWeek.fromDate(
        DateTime(2026, 4, 30).add(const Duration(days: 7)),
      );

      final row = await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: w19,
        startRowCache: cache,
      );

      expect(row, greaterThan(5 + BushidoSheetLayout.weekBlockHeight));
      expect(cache[w18], 5);
      expect(cache[w19], row);
    });

    test('older week vs cached newer week → inserts via insertDimension and shifts cache', () async {
      final fake = _FakeSheetsService();
      // W18/2026 already in the sheet at row 9 (after the sticky header).
      final newer = IsoWeek.fromDate(DateTime(2026, 5, 1)); // 2026-W18
      final older = IsoWeek.fromDate(DateTime(2026, 4, 24)); // 2026-W17
      final cache = <IsoWeek, int>{newer: 9};

      final row = await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: older,
        startRowCache: cache,
      );

      // Older block lands at the row previously occupied by the newer one,
      // and the newer one shifted down by weekBlockHeight + spacer.
      expect(row, 9);
      expect(cache[older], 9);
      expect(
        cache[newer],
        9 +
            BushidoSheetLayout.weekBlockHeight +
            BushidoSheetLayout.spacerRowsBetweenWeeks,
      );

      // An insertDimension request was issued before the new content was
      // written.
      final inserts = fake.batchRequests
          .where((r) => r.insertDimension != null)
          .toList();
      expect(inserts.length, 1);
      final dim = inserts.single.insertDimension!.range!;
      expect(dim.dimension, 'ROWS');
      expect(dim.startIndex, 8); // 0-indexed = row 9
      expect(
        dim.endIndex! - dim.startIndex!,
        BushidoSheetLayout.weekBlockHeight +
            BushidoSheetLayout.spacerRowsBetweenWeeks,
      );

      // Marker for the new block landed at Z9.
      final markerWrite = _findWrite(fake, '!Z9');
      expect(markerWrite.values.first.first,
          'BUSHIDO_WEEK:${older.year}-W${older.weekNumber.toString().padLeft(2, '0')}:v1');
    });

    test('two consecutive calls for the same week → only one append', () async {
      final fake = _FakeSheetsService();
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1));
      final cache = <IsoWeek, int>{};
      final svc = _service(fake);

      final row1 = await svc.ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );
      final writesAfterFirst = fake.writes.length;
      final batchAfterFirst = fake.batchRequests.length;

      final row2 = await svc.ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );

      expect(row1, row2);
      expect(fake.writes.length, writesAfterFirst);
      expect(fake.batchRequests.length, batchAfterFirst);
    });

    test('append writes marker, headers, dates, AVERAGE formulas, target box', () async {
      final fake = _FakeSheetsService();
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1));
      final cache = <IsoWeek, int>{};

      final startRow = await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );

      final endRow = startRow + BushidoSheetLayout.weekBlockHeight - 1;
      final blockWrite = _findWrite(fake, '!A$startRow:O$endRow');
      final block = blockWrite.values;

      // Daily column header row contains all BushidoColumn labels in order.
      final headerRow = block[BushidoSheetLayout.dailyHeaderRowOffset];
      for (final col in BushidoColumn.values) {
        expect(headerRow[col.columnOffset], col.label,
            reason: 'header for ${col.name}');
      }

      // 7 day dates in column A on the day rows.
      for (var d = 0; d < 7; d++) {
        final cell = block[BushidoSheetLayout.firstDayRowOffset + d][0];
        expect(cell, isA<String>());
        expect((cell as String).contains('.'), isTrue,
            reason: 'day $d date should be dotted dd.MM.yyyy');
      }

      // AVERAGE formulas on the average row for B..H (auto cols except date).
      final avgRow = block[BushidoSheetLayout.averageRowOffset];
      expect(avgRow[BushidoColumn.date.columnOffset], 'Průměr');
      for (final col in BushidoExportConfig.dailyAutoColumns) {
        if (col == BushidoColumn.date) continue;
        final cell = avgRow[col.columnOffset];
        expect(cell, isA<String>());
        expect((cell as String).startsWith('=IFERROR(ROUND(AVERAGE('), isTrue,
            reason: 'avg formula for ${col.name}');
      }

      // Target box: 'CÍLE / VÝSLEDEK' header + label + AVERAGE formula per metric.
      final mIndex = BushidoSheetLayout.targetBoxStartColumn - 1;
      expect(block[BushidoSheetLayout.headerRowOffset][mIndex],
          'CÍLE / VÝSLEDEK');
      for (var i = 0; i < BushidoExportConfig.targetMetrics.length; i++) {
        final metric = BushidoExportConfig.targetMetrics[i];
        final row = block[BushidoSheetLayout.firstTargetMetricRowOffset + i];
        expect(row[mIndex], metric.label);
        expect(row[mIndex + 1], isNull, reason: 'goal cell stays blank');
        expect(row[mIndex + 2], isA<String>());
        expect((row[mIndex + 2] as String).startsWith('=IFERROR(ROUND(AVERAGE('),
            isTrue);
      }

      // Marker at Z{startRow}.
      final markerWrite = _findWrite(fake, '!Z$startRow');
      expect(markerWrite.values.first.first, 'BUSHIDO_WEEK:2026-W01:v1');

      // Three data validations submitted.
      final validations = fake.batchRequests
          .where((r) => r.setDataValidation != null)
          .toList();
      expect(validations.length, 3);
    });

    test('marker format is exactly BUSHIDO_WEEK:{year}-W{ww}:v{layoutVersion}',
        () async {
      final fake = _FakeSheetsService();
      final week = IsoWeek.fromDate(DateTime(2026, 5, 1)); // 2026-W18 (Friday May 1)
      final cache = <IsoWeek, int>{};

      await _service(fake).ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );

      final markerWrite = fake.writes.firstWhere(
        (w) => w.range.contains('!Z'),
        orElse: () => throw StateError('marker write not found'),
      );
      expect(markerWrite.values.first.first,
          'BUSHIDO_WEEK:${week.year}-W${week.weekNumber.toString().padLeft(2, '0')}:v1');
    });
  });

  group('BushidoSheetsService.writeAutoCells', () {
    final week = IsoWeek.fromDate(DateTime(2026, 1, 1));

    List<BushidoDayRow> emptyDays() => List.generate(
          7,
          (i) => BushidoDayRow(date: week.monday.add(Duration(days: i))),
        );

    test('writes only to A:H — manual columns I..L are out of range', () async {
      final fake = _FakeSheetsService();

      await _service(fake).writeAutoCells(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
        week: week,
        startRow: 1,
        dayRows: emptyDays(),
      );

      expect(fake.writes.length, 1);
      final w = fake.writes.single;
      // Range must end at column H — never reach I, J, K, or L.
      expect(w.range.endsWith(':H${1 + BushidoSheetLayout.firstDayRowOffset + 6}'),
          isTrue,
          reason: 'expected range to stop at H, got ${w.range}');
      // Each row payload has exactly 8 cells (A..H), no manual columns.
      for (final row in w.values) {
        expect(row.length, BushidoExportConfig.dailyAutoColumns.length);
      }
      // No batchUpdate side-effects.
      expect(fake.batchRequests, isEmpty);
    });

    test('null in BushidoDayRow → blank cell (empty string), not omitted',
        () async {
      final fake = _FakeSheetsService();

      await _service(fake).writeAutoCells(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
        week: week,
        startRow: 1,
        dayRows: emptyDays(),
      );

      final firstRow = fake.writes.single.values.first;
      // Date is always present (column A).
      expect(firstRow[BushidoColumn.date.columnOffset], isA<String>());
      // All metric columns are blank (empty string), never null.
      for (final col in BushidoExportConfig.dailyAutoColumns) {
        if (col == BushidoColumn.date) continue;
        expect(firstRow[col.columnOffset], '',
            reason: '${col.name} should be blank when source is null');
      }
    });

    test('0 in BushidoDayRow → literal 0 in payload, distinct from blank',
        () async {
      final fake = _FakeSheetsService();
      final days = [
        BushidoDayRow(
          date: week.monday,
          weightKg: 0,
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
          fiberG: 0,
          steps: 0,
        ),
        for (var i = 1; i < 7; i++)
          BushidoDayRow(date: week.monday.add(Duration(days: i))),
      ];

      await _service(fake).writeAutoCells(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
        week: week,
        startRow: 1,
        dayRows: days,
      );

      final mondayRow = fake.writes.single.values.first;
      expect(mondayRow[BushidoColumn.weightKg.columnOffset], 0);
      expect(mondayRow[BushidoColumn.kcal.columnOffset], 0);
      expect(mondayRow[BushidoColumn.proteinG.columnOffset], 0);
      expect(mondayRow[BushidoColumn.carbsG.columnOffset], 0);
      expect(mondayRow[BushidoColumn.fatG.columnOffset], 0);
      expect(mondayRow[BushidoColumn.fiberG.columnOffset], 0);
      expect(mondayRow[BushidoColumn.steps.columnOffset], 0);
    });

    test('re-export of same range is idempotent: no duplicate block, '
        'manual columns never re-written', () async {
      final fake = _FakeSheetsService();
      final cache = <IsoWeek, int>{};
      final days = [
        for (var i = 0; i < 7; i++)
          BushidoDayRow(
            date: week.monday.add(Duration(days: i)),
            weightKg: 80.0,
            kcal: 2000,
            steps: 5000,
          ),
      ];
      final svc = _service(fake);

      // First export: append + writeAutoCells.
      final row1 = await svc.ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );
      await svc.writeAutoCells(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
        week: week,
        startRow: row1,
        dayRows: days,
      );

      final firstPassWriteCount = fake.writes.length;
      final firstPassBatchCount = fake.batchRequests.length;

      // Second export of the same range.
      final row2 = await svc.ensureWeekBlock(
        spreadsheetId: _spreadsheetId,
        sheetId: 100,
        sheetName: _sheetName,
        week: week,
        startRowCache: cache,
      );
      await svc.writeAutoCells(
        spreadsheetId: _spreadsheetId,
        sheetName: _sheetName,
        week: week,
        startRow: row2,
        dayRows: days,
      );

      // Same row → no duplicate block.
      expect(row1, row2);

      // ensureWeekBlock returned from cache → no new batch validations.
      expect(fake.batchRequests.length, firstPassBatchCount);

      // Second pass produced exactly one new write (writeAutoCells), into A:H.
      final secondPass = fake.writes.skip(firstPassWriteCount).toList();
      expect(secondPass.length, 1);
      final secondWrite = secondPass.single;
      expect(secondWrite.range.contains(':H'), isTrue);
      // No second-pass write touches columns I..L or column Z.
      expect(secondWrite.range.contains('!Z'), isFalse);
      for (final letter in ['I', 'J', 'K', 'L']) {
        expect(secondWrite.range.endsWith(':$letter'), isFalse,
            reason: 'second pass must not write into manual column $letter');
      }
    });
  });
}
