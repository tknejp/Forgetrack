import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/devtools/domain/devtools_sync_event.dart';

void main() {
  group('DevToolsSyncEvent', () {
    final base = DevToolsSyncEvent(
      timestamp: DateTime(2026, 4, 26, 12, 0, 0),
      source: 'manual',
      feature: 'health',
      result: 'success',
      durationMs: 1234,
      errorMessage: null,
      extra: {'stepsBefore': 0, 'stepsAfter': 8500},
    );

    test('toJson / fromJson roundtrip preserves all fields', () {
      final json = base.toJson();
      final restored = DevToolsSyncEvent.fromJson(json);

      expect(restored.timestamp, base.timestamp);
      expect(restored.source, base.source);
      expect(restored.feature, base.feature);
      expect(restored.result, base.result);
      expect(restored.durationMs, base.durationMs);
      expect(restored.errorMessage, base.errorMessage);
      expect(restored.extra, base.extra);
    });

    test('toJson omits null optional fields', () {
      final event = DevToolsSyncEvent(
        timestamp: DateTime(2026, 1, 1),
        source: 'background',
        feature: 'all',
        result: 'failure',
      );
      final json = event.toJson();

      expect(json.containsKey('durationMs'), isFalse);
      expect(json.containsKey('errorMessage'), isFalse);
      expect(json.containsKey('extra'), isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final minimal = {
        'timestamp': '2026-04-26T12:00:00.000',
        'source': 'foreground',
        'feature': 'progression',
        'result': 'success',
      };
      final event = DevToolsSyncEvent.fromJson(minimal);

      expect(event.durationMs, isNull);
      expect(event.errorMessage, isNull);
      expect(event.extra, isNull);
    });

    test('copyWith replaces only specified fields', () {
      final copy = base.copyWith(result: 'failure', durationMs: 9999);

      expect(copy.result, 'failure');
      expect(copy.durationMs, 9999);
      expect(copy.source, base.source);
      expect(copy.feature, base.feature);
      expect(copy.timestamp, base.timestamp);
      expect(copy.extra, base.extra);
    });

    test('copyWith with no args returns equivalent event', () {
      final copy = base.copyWith();

      expect(copy.timestamp, base.timestamp);
      expect(copy.source, base.source);
      expect(copy.feature, base.feature);
      expect(copy.result, base.result);
      expect(copy.durationMs, base.durationMs);
      expect(copy.errorMessage, base.errorMessage);
      expect(copy.extra, base.extra);
    });
  });
}
