import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import 'package:forgetrack/features/health_connect/data/health_connect_service/hc_read_client.dart';
import 'package:forgetrack/features/health_connect/data/health_connect_service/hc_steps_service.dart';

// ---------------------------------------------------------------------------
// Fake client — overrides all platform-touching methods so tests run offline.
// ---------------------------------------------------------------------------

class _FakeHcReadClient extends HcReadClient {
  _FakeHcReadClient() : super();

  final Map<String, int?> _aggregateSteps = {};
  List<HealthDataPoint> rawPoints = [];

  void setTotalSteps(DateTime start, DateTime end, int? steps) {
    _aggregateSteps['${start.toIso8601String()}_${end.toIso8601String()}'] =
        steps;
  }

  @override
  Future<void> ensureConfigured() async {}

  @override
  Future<void> assertAvailable() async {}

  @override
  Future<List<HealthDataPoint>> fetchData({
    required String label,
    required DateTime start,
    required DateTime end,
    required List<HealthDataType> types,
  }) async =>
      rawPoints;

  @override
  Future<int?> getTotalStepsInInterval(DateTime start, DateTime end) async {
    final key = '${start.toIso8601String()}_${end.toIso8601String()}';
    return _aggregateSteps[key];
  }
}

// ---------------------------------------------------------------------------

void main() {
  late _FakeHcReadClient client;
  late HcStepsService service;

  // Use a fixed "today" so tests are date-independent.
  final today = DateTime(2026, 4, 27);
  final now = DateTime(2026, 4, 27, 12);
  final tomorrowStart = DateTime(2026, 4, 28);

  setUp(() {
    client = _FakeHcReadClient();
    service = HcStepsService(client, now: () => now);
  });

  group('getStepsHistory', () {
    test('always includes a record for today even when HC returns 0', () async {
      // Aggregate returns 0 for today (no steps yet).
      client.setTotalSteps(today, now, 0);
      client.setTotalSteps(today, tomorrowStart, 0);

      final records = await service.getStepsHistory(7);

      expect(records.length, 7);
      final todayRecord = records.where((r) => r.date == today).firstOrNull;
      expect(todayRecord, isNotNull, reason: 'today must have a record');
      expect(todayRecord!.steps, 0);
    });

    test(
        'uses full-day aggregate (todayStart->tomorrowStart) for today, not the now-capped value',
        () async {
      // today->now returns 0 (Samsung Health all-day record not yet visible).
      // today->tomorrow returns 3829 (HC aggregate covers full interval).
      client.setTotalSteps(today, tomorrowStart, 3829);

      final records = await service.getStepsHistory(7);

      final todayRecord = records.where((r) => r.date == today).firstOrNull;
      expect(todayRecord!.steps, 3829,
          reason:
              'full-day aggregate must be used, not the partial-day result');
    });

    test('produces exactly `days` records sorted oldest-first', () async {
      client.setTotalSteps(today, tomorrowStart, 500);

      final records = await service.getStepsHistory(7);

      expect(records.length, 7);
      for (var i = 1; i < records.length; i++) {
        expect(records[i].date.isAfter(records[i - 1].date), isTrue);
      }
    });

    test('today with 0 steps does not fall back to yesterday via raw data',
        () async {
      // Yesterday has raw steps but today aggregate returns 0.
      client.setTotalSteps(today, tomorrowStart, 0);

      final records = await service.getStepsHistory(7);

      final todayRecord = records.where((r) => r.date == today).firstOrNull;
      expect(todayRecord!.steps, 0,
          reason: 'today must be 0, not inherited from yesterday raw data');
    });

    test(
        'today record is present after 7-day refresh regardless of raw point count',
        () async {
      // No raw points at all for today.
      client.rawPoints = [];
      client.setTotalSteps(today, tomorrowStart, 0);

      final records = await service.getStepsHistory(7);

      expect(records.any((r) => r.date == today), isTrue);
    });
  });

  group('getStepsHistoryForRange', () {
    test('includes today record when range ends today', () async {
      final rangeStart = today.subtract(const Duration(days: 6));
      client.setTotalSteps(today, tomorrowStart, 1234);

      final records = await service.getStepsHistoryForRange(rangeStart, today);

      final todayRecord = records.where((r) => r.date == today).firstOrNull;
      expect(todayRecord, isNotNull);
      expect(todayRecord!.steps, 1234);
    });

    test('returns empty list when start is after end', () async {
      final records = await service.getStepsHistoryForRange(
          today, today.subtract(const Duration(days: 1)));
      expect(records, isEmpty);
    });

    test('single-day range for today uses full-day aggregate', () async {
      client.setTotalSteps(today, tomorrowStart, 5000);

      final records = await service.getStepsHistoryForRange(today, today);

      expect(records.length, 1);
      expect(records.first.steps, 5000);
    });
  });
}
