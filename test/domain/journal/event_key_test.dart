// EventKey is a typed wrapper around String — zero runtime cost,
// compile-time type safety. These tests document the contract: equality
// matches the underlying value, raw round-trips, and the type prevents
// stringly-typed identifier confusion at compile time (verified by the
// fact that this file compiles — see the `unused commented assertion`
// below for the negative case).

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/journal/event_key.dart';

void main() {
  group('EventKey', () {
    test('equality matches the underlying value', () {
      const a = EventKey('node|quest_1|2026-05-17|complete');
      const b = EventKey('node|quest_1|2026-05-17|complete');
      const c = EventKey('node|quest_2|2026-05-17|complete');
      expect(a, b);
      expect(a, isNot(c));
    });

    test('raw returns the underlying string verbatim', () {
      const key = EventKey('reward|quest_1|0|2026-05-17|grant');
      expect(key.raw, 'reward|quest_1|0|2026-05-17|grant');
    });

    test('hashCode is stable across equal values', () {
      const a = EventKey('node|quest_1|complete');
      const b = EventKey('node|quest_1|complete');
      expect(a.hashCode, b.hashCode);
    });

    test('const construction works (compile-time deduplication)', () {
      const a = EventKey('node|quest_1|complete');
      const b = EventKey('node|quest_1|complete');
      // Const values with identical representation are the same instance.
      expect(identical(a, b), isTrue);
    });
  });

  // Compile-time type safety note:
  //
  // Because EventKey wraps String, you cannot accidentally use a raw
  // String where an EventKey is expected:
  //
  //   void store(EventKey key) { ... }
  //   store('not_a_key');  // compile error — String is not EventKey
  //
  // The reverse direction (EventKey → String) is allowed via `.raw`,
  // which is the explicit serialisation boundary used by persistence
  // mappers. This catches refactoring typos that previously slipped
  // through Dart's stringly-typed conventions (see proposal §7.3).
}
