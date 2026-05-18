// Phase 7 value-object contract pin for PlayerQuest.
//
// PlayerQuest is the projection unit inside PlayerQuestCatalog. It
// binds a QuestId, a sealed lifecycle, and the evaluation timestamp
// that produced the snapshot. The catalog uses == for change
// detection (e.g. cache invalidation in Phase 8+ consumers) so the
// equality contract is load-bearing.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_quest.dart';
import 'package:forgetrack/domain/progression/player/player_quest_lifecycle.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 5, 18, 12);

  PlayerQuest make({
    String id = 'daily_steps',
    PlayerQuestLifecycle lifecycle = const QuestAvailable(
      actual: 5000,
      target: 10000,
      progress: 0.5,
    ),
    DateTime? when,
  }) {
    return PlayerQuest(
      id: QuestId(id),
      lifecycle: lifecycle,
      evaluatedAt: when ?? evaluatedAt,
    );
  }

  group('PlayerQuest equality + hashCode', () {
    test('identical fields → equal', () {
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('differing id breaks equality', () {
      expect(make(id: 'a'), isNot(make(id: 'b')));
    });

    test('differing lifecycle breaks equality', () {
      expect(
        make(lifecycle: const QuestLocked()),
        isNot(make(lifecycle: const QuestClaimed(finalXp: 230))),
      );
    });

    test('differing evaluatedAt breaks equality', () {
      expect(
        make(when: DateTime.utc(2026, 5, 18, 12)),
        isNot(make(when: DateTime.utc(2026, 5, 18, 13))),
      );
    });

    test('lifecycle payload diff propagates through equality', () {
      // Two QuestAvailable values with different progress are unequal,
      // so PlayerQuest wrapping them is unequal — the catalog's
      // change detection sees per-tick progress updates.
      expect(
        make(
          lifecycle: const QuestAvailable(
            actual: 3000,
            target: 10000,
            progress: 0.3,
          ),
        ),
        isNot(
          make(
            lifecycle: const QuestAvailable(
              actual: 6000,
              target: 10000,
              progress: 0.6,
            ),
          ),
        ),
      );
    });
  });

  group('PlayerQuest.copyWith', () {
    test('returns an identical value when no override is supplied', () {
      final base = make();
      expect(base.copyWith(), base);
    });

    test('overrides only the named fields', () {
      final base = make();
      final swapped = base.copyWith(
        lifecycle: const QuestClaimed(finalXp: 500),
      );
      expect(swapped.lifecycle, const QuestClaimed(finalXp: 500));
      expect(swapped.id, base.id);
      expect(swapped.evaluatedAt, base.evaluatedAt);
    });
  });
}
