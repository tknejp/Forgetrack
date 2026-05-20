import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/health_connect/data/goal_history_firestore_gateway.dart';
import 'package:forgetrack/features/health_connect/domain/player_goal.dart';

void main() {
  group('GoalHistoryFirestoreGateway.merge', () {
    test('empty + empty → empty', () {
      expect(GoalHistoryFirestoreGateway.merge(const [], const []), isEmpty);
    });

    test('empty local + non-empty cloud → cloud copy', () {
      final cloud = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 10), value: 10000),
        GoalRevision(effectiveFrom: DateTime(2026, 5, 15), value: 12000),
      ];
      final merged = GoalHistoryFirestoreGateway.merge(const [], cloud);
      expect(merged, cloud);
    });

    test('non-empty local + empty cloud → local copy', () {
      final local = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 10), value: 10000),
      ];
      final merged = GoalHistoryFirestoreGateway.merge(local, const []);
      expect(merged, local);
    });

    test('union by date when no overlap', () {
      final local = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 10), value: 10000),
      ];
      final cloud = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 15), value: 12000),
      ];
      final merged = GoalHistoryFirestoreGateway.merge(local, cloud);
      expect(merged.map((r) => r.effectiveFrom).toList(), [
        DateTime(2026, 5, 10),
        DateTime(2026, 5, 15),
      ]);
      expect(merged.map((r) => r.value).toList(), [10000, 12000]);
    });

    test('cloud wins on same-day conflict (anti-cheat)', () {
      // Player lowered goal locally; cloud holds the original.
      final local = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 10), value: 5000),
      ];
      final cloud = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 10), value: 10000),
      ];
      final merged = GoalHistoryFirestoreGateway.merge(local, cloud);
      expect(merged, hasLength(1));
      expect(merged.single.value, 10000,
          reason: 'cloud is server truth; local lowering must not win');
    });

    test('output is sorted ascending by effectiveFrom', () {
      final local = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 15), value: 12000),
      ];
      final cloud = [
        GoalRevision(effectiveFrom: DateTime(2026, 5, 10), value: 10000),
        GoalRevision(effectiveFrom: DateTime(2026, 5, 20), value: 14000),
      ];
      final merged = GoalHistoryFirestoreGateway.merge(local, cloud);
      final dates = merged.map((r) => r.effectiveFrom).toList();
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isTrue);
      }
    });
  });

  group('GoalRevision JSON round-trip', () {
    test('preserves date and value through toJson/fromJson', () {
      final original = GoalRevision(
        effectiveFrom: DateTime(2026, 5, 10),
        value: 12345.67,
      );
      final json = original.toJson();
      final restored = GoalRevision.fromJson(json);
      expect(restored, original);
    });
  });
}
