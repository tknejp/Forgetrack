import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_day_row.dart';
import 'package:forgetrack/features/coach_log_export/domain/bushido_week_report.dart';
import 'package:forgetrack/features/coach_log_export/domain/iso_week.dart';

void main() {
  // 2026-W01: Mon Jan 5 – Sun Jan 11 2026
  final week = IsoWeek.fromDate(DateTime(2026, 1, 5));

  List<BushidoDayRow> validDays() => [
        for (var i = 0; i < 7; i++)
          BushidoDayRow(date: week.monday.add(Duration(days: i))),
      ];

  group('BushidoWeekReport construction', () {
    test('valid 7-day report constructs without error', () {
      expect(
        () => BushidoWeekReport(week: week, days: validDays()),
        returnsNormally,
      );
    });

    test('all-null fields are allowed — missing data must not default to zero', () {
      final report = BushidoWeekReport(week: week, days: validDays());
      for (final day in report.days) {
        expect(day.weightKg, isNull);
        expect(day.kcal, isNull);
        expect(day.proteinG, isNull);
        expect(day.steps, isNull);
      }
    });

    test('assert fires when fewer than 7 days are provided', () {
      expect(
        () => BushidoWeekReport(week: week, days: validDays().sublist(0, 6)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert fires when more than 7 days are provided', () {
      final extra = [
        ...validDays(),
        BushidoDayRow(date: week.sunday.add(const Duration(days: 1))),
      ];
      expect(
        () => BushidoWeekReport(week: week, days: extra),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert fires when days are in reverse order', () {
      final reversed = validDays().reversed.toList();
      expect(
        () => BushidoWeekReport(week: week, days: reversed),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert fires when days belong to a different week', () {
      // W02: Mon Jan 12 – Sun Jan 18
      final wrongDays = [
        for (var i = 0; i < 7; i++)
          BushidoDayRow(date: DateTime(2026, 1, 12).add(Duration(days: i))),
      ];
      expect(
        () => BushidoWeekReport(week: week, days: wrongDays),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
