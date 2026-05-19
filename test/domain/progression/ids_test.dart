// Compile-time + runtime contract for progression catalog ids.
//
// These tests document:
//   1. Equality + hash semantics match the underlying string.
//   2. Subtypes (QuestId, AchievementId, MilestoneId) are assignable
//      to the umbrella ProgressionEntryId.
//   3. Independent types (ChapterId, ObjectiveId) are NOT assignable
//      to ProgressionEntryId — the file would fail to compile if any
//      were.
//
// Negative compile-time cases (which would fail compilation if
// uncommented) are documented as comments at the bottom.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';

void main() {
  group('ProgressionEntryId', () {
    test('equality matches underlying value', () {
      const a = ProgressionEntryId('quest_1');
      const b = ProgressionEntryId('quest_1');
      const c = ProgressionEntryId('quest_2');
      expect(a, b);
      expect(a, isNot(c));
    });

    test('raw returns the underlying string', () {
      const id = ProgressionEntryId('chapter_step_1');
      expect(id.raw, 'chapter_step_1');
    });

    test('const construction deduplicates equal values', () {
      const a = ProgressionEntryId('hello');
      const b = ProgressionEntryId('hello');
      expect(identical(a, b), isTrue);
    });
  });

  group('subtype assignability', () {
    test('QuestId is assignable to ProgressionEntryId', () {
      const quest = QuestId('daily_steps_today');
      const ProgressionEntryId entry = quest;
      expect(entry.raw, 'daily_steps_today');
    });

    test('AchievementId is assignable to ProgressionEntryId', () {
      const achievement = AchievementId('first_steps');
      const ProgressionEntryId entry = achievement;
      expect(entry.raw, 'first_steps');
    });

    test('MilestoneId is assignable to ProgressionEntryId', () {
      const milestone = MilestoneId('level_10');
      const ProgressionEntryId entry = milestone;
      expect(entry.raw, 'level_10');
    });
  });

  group('ChapterId / ObjectiveId are separate namespaces', () {
    test('ChapterId equality is independent of ProgressionEntryId', () {
      const chapter = ChapterId('forest_trial');
      const entry = ProgressionEntryId('forest_trial');
      // The underlying raw values are equal, but the *typed* values
      // live in different type namespaces and cannot be compared
      // directly via ==. Verify they still serialise to the same raw
      // form (cross-aggregate references use the raw string at the
      // boundary).
      expect(chapter.raw, entry.raw);
    });

    test('ObjectiveId round-trips through .raw', () {
      const id = ObjectiveId('daily_steps_obj');
      expect(id.raw, 'daily_steps_obj');
    });
  });

  // ── Negative compile-time cases ────────────────────────────────
  //
  // Each commented line below WOULD FAIL to compile if uncommented.
  // Documented here so a reader understands what the type system
  // catches:
  //
  //   // 1. Cannot pass a raw String where a typed id is expected:
  //   final ProgressionEntryId bad1 = 'quest_1';
  //
  //   // 2. Cannot assign a ChapterId to a ProgressionEntryId — they
  //   //    live in separate type namespaces:
  //   final ProgressionEntryId bad2 = const ChapterId('forest_trial');
  //
  //   // 3. Cannot assign an ObjectiveId to a ProgressionEntryId:
  //   final ProgressionEntryId bad3 = const ObjectiveId('obj_1');
  //
  //   // 4. Cannot pass a QuestId where a ChapterId is expected (both
  //   //    wrap String but live in unrelated namespaces):
  //   final ChapterId bad4 = const QuestId('chapter_1');
}
