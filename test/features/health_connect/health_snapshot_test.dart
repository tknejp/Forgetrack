import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/health_connect/domain/health_snapshot.dart';

void main() {
  group('HealthSnapshot', () {
    test('empty sentinel anchored at unix epoch with zero metrics', () {
      final snap = HealthSnapshot.empty;
      expect(snap.evaluatedDate,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      expect(snap.stepsToday, 0);
      expect(snap.stepsThisWeek, 0);
      expect(snap.stepsLifetime, 0);
      expect(snap.sleepMinutesToday, 0);
      expect(snap.activityMinutesToday, 0);
      expect(snap.weightLoggedToday, isFalse);
    });

    test('equality is value-based across every field', () {
      final base = HealthSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        stepsToday: 8000,
        stepsThisWeek: 42000,
        stepsLifetime: 1500000,
        sleepMinutesToday: 420,
        activityMinutesToday: 35,
        weightLoggedToday: true,
      );
      final twin = HealthSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        stepsToday: 8000,
        stepsThisWeek: 42000,
        stepsLifetime: 1500000,
        sleepMinutesToday: 420,
        activityMinutesToday: 35,
        weightLoggedToday: true,
      );
      expect(base, equals(twin));
      expect(base.hashCode, twin.hashCode);

      expect(base, isNot(equals(base.copyWith(stepsToday: 8001))));
      expect(base, isNot(equals(base.copyWith(weightLoggedToday: false))));
    });

    test('copyWith preserves untouched fields', () {
      final base = HealthSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        stepsToday: 8000,
        stepsThisWeek: 42000,
      );
      final updated = base.copyWith(stepsToday: 9500);

      expect(updated.stepsToday, 9500);
      expect(updated.stepsThisWeek, 42000);
      expect(updated.evaluatedDate, DateTime(2026, 5, 18));
    });

    test('signature changes when any tracked field changes', () {
      final base = HealthSnapshot(
        evaluatedDate: DateTime(2026, 5, 18),
        stepsToday: 8000,
      );
      expect(base.signature,
          isNot(base.copyWith(stepsToday: 8001).signature));
      expect(base.signature,
          isNot(base.copyWith(weightLoggedToday: true).signature));
      expect(base.signature,
          isNot(base.copyWith(evaluatedDate: DateTime(2026, 5, 19)).signature));
    });
  });
}
