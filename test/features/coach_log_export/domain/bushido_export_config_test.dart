import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_export_config.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_sheet_layout.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';

void main() {
  group('BushidoExportConfig.dailyAutoColumns', () {
    test('contains exactly 8 auto columns in the specified order', () {
      expect(BushidoExportConfig.dailyAutoColumns, [
        BushidoColumn.date,
        BushidoColumn.weightKg,
        BushidoColumn.kcal,
        BushidoColumn.proteinG,
        BushidoColumn.carbsG,
        BushidoColumn.fatG,
        BushidoColumn.fiberG,
        BushidoColumn.steps,
      ]);
    });

    test('all auto columns carry isAuto == true', () {
      for (final col in BushidoExportConfig.dailyAutoColumns) {
        expect(col.isAuto, isTrue, reason: '${col.name} should be auto');
      }
    });

    test('column offsets are 0-indexed and sequential from 0', () {
      for (var i = 0; i < BushidoExportConfig.dailyAutoColumns.length; i++) {
        expect(
          BushidoExportConfig.dailyAutoColumns[i].columnOffset,
          i,
          reason: 'auto column $i should have offset $i',
        );
      }
    });
  });

  group('BushidoExportConfig.dailyManualColumns', () {
    test('contains exactly 4 manual columns in the specified order', () {
      expect(BushidoExportConfig.dailyManualColumns, [
        BushidoColumn.training,
        BushidoColumn.hunger,
        BushidoColumn.hydration,
        BushidoColumn.note,
      ]);
    });

    test('all manual columns carry isAuto == false', () {
      for (final col in BushidoExportConfig.dailyManualColumns) {
        expect(col.isAuto, isFalse, reason: '${col.name} should be manual');
      }
    });

    test('manual columns follow immediately after auto columns (offsets 8–11)', () {
      final autoCount = BushidoExportConfig.dailyAutoColumns.length;
      for (var i = 0; i < BushidoExportConfig.dailyManualColumns.length; i++) {
        expect(
          BushidoExportConfig.dailyManualColumns[i].columnOffset,
          autoCount + i,
          reason: 'manual column $i should have offset ${autoCount + i}',
        );
      }
    });
  });

  group('BushidoExportConfig.targetMetrics sourceColumn references', () {
    test('each metric references the correct BushidoColumn', () {
      expect(BushidoTargetMetric.targetWeightKg.sourceColumn, BushidoColumn.weightKg);
      expect(BushidoTargetMetric.kcal.sourceColumn, BushidoColumn.kcal);
      expect(BushidoTargetMetric.proteinG.sourceColumn, BushidoColumn.proteinG);
      expect(BushidoTargetMetric.carbsG.sourceColumn, BushidoColumn.carbsG);
      expect(BushidoTargetMetric.fatG.sourceColumn, BushidoColumn.fatG);
      expect(BushidoTargetMetric.fiberG.sourceColumn, BushidoColumn.fiberG);
      expect(BushidoTargetMetric.steps.sourceColumn, BushidoColumn.steps);
    });

    test('targetMetrics list contains 7 metrics in the specified order', () {
      expect(BushidoExportConfig.targetMetrics, [
        BushidoTargetMetric.targetWeightKg,
        BushidoTargetMetric.kcal,
        BushidoTargetMetric.proteinG,
        BushidoTargetMetric.carbsG,
        BushidoTargetMetric.fatG,
        BushidoTargetMetric.fiberG,
        BushidoTargetMetric.steps,
      ]);
    });
  });

  group('BushidoSheetLayout.layoutVersion wired into IsoWeek.marker', () {
    test('IsoWeek.marker uses BushidoSheetLayout.layoutVersion', () {
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1));
      expect(
        week.marker,
        'BUSHIDO_WEEK:2026-W01:${BushidoSheetLayout.layoutVersion}',
      );
    });

    test('marker format is unchanged from Phase 0 (still v1)', () {
      final week = IsoWeek.fromDate(DateTime(2026, 1, 1));
      expect(week.marker, 'BUSHIDO_WEEK:2026-W01:v1');
    });
  });
}
