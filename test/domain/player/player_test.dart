// Unit tests for the Phase 4 Player aggregate.
//
// Phase 4 introduces Player as a pure value object — no providers, no
// I/O, no widgets. These tests pin the value-object contract (equality,
// hashCode, copyWith, the anonymous sentinel) so later phases that
// repoint Player at the Journal can refactor freely without breaking
// downstream identity checks.
//
// See:
//   - lib/domain/player/player.dart
//   - docs/domain_model/migration_plan.md §Phase 4.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/player/player.dart';

void main() {
  final aJoinedAt = DateTime.utc(2026, 1, 1);
  final bJoinedAt = DateTime.utc(2026, 2, 1);

  Player makePlayer({
    String uid = 'user-1',
    int level = 3,
    int totalXp = 500,
    DateTime? joinedAt,
    bool rpgModeEnabled = true,
    String? displayName = 'Test User',
    String? photoUrl = 'https://example.com/avatar.png',
  }) {
    return Player(
      uid: uid,
      level: level,
      totalXp: totalXp,
      joinedAt: joinedAt ?? aJoinedAt,
      rpgModeEnabled: rpgModeEnabled,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  group('Player equality + hashCode', () {
    test('two players with identical fields are equal', () {
      final a = makePlayer();
      final b = makePlayer();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing uid breaks equality', () {
      expect(makePlayer(uid: 'a'), isNot(equals(makePlayer(uid: 'b'))));
    });

    test('differing level / totalXp / joinedAt break equality', () {
      final base = makePlayer();
      expect(base, isNot(equals(makePlayer(level: base.level + 1))));
      expect(base, isNot(equals(makePlayer(totalXp: base.totalXp + 1))));
      expect(base, isNot(equals(makePlayer(joinedAt: bJoinedAt))));
    });

    test('differing rpgModeEnabled breaks equality', () {
      expect(
        makePlayer(rpgModeEnabled: true),
        isNot(equals(makePlayer(rpgModeEnabled: false))),
      );
    });

    test('differing display chrome breaks equality', () {
      final base = makePlayer();
      expect(base, isNot(equals(makePlayer(displayName: 'Other'))));
      expect(base, isNot(equals(makePlayer(photoUrl: 'https://x/y.png'))));
    });

    test('null display chrome is a distinct value', () {
      final withChrome = makePlayer();
      final withoutChrome =
          makePlayer(displayName: null, photoUrl: null);
      expect(withChrome, isNot(equals(withoutChrome)));
    });
  });

  group('Player.copyWith', () {
    test('returns an identical value when no override is supplied', () {
      final base = makePlayer();
      expect(base.copyWith(), equals(base));
    });

    test('overrides only the named fields', () {
      final base = makePlayer();
      final next = base.copyWith(level: 9, totalXp: 1234);
      expect(next.level, 9);
      expect(next.totalXp, 1234);
      expect(next.uid, base.uid);
      expect(next.joinedAt, base.joinedAt);
      expect(next.displayName, base.displayName);
      expect(next.photoUrl, base.photoUrl);
      expect(next.rpgModeEnabled, base.rpgModeEnabled);
    });

    test('rpgModeEnabled override flips the flag without touching XP', () {
      final base = makePlayer();
      final flipped = base.copyWith(rpgModeEnabled: false);
      expect(flipped.rpgModeEnabled, isFalse);
      expect(flipped.level, base.level);
      expect(flipped.totalXp, base.totalXp);
    });
  });

  group('Player.anonymous sentinel', () {
    test('anonymous instance has empty uid and zero-level defaults', () {
      final anon = Player.anonymous;
      expect(anon.uid, isEmpty);
      expect(anon.level, 1);
      expect(anon.totalXp, 0);
      expect(anon.rpgModeEnabled, isTrue);
      expect(anon.displayName, isNull);
      expect(anon.photoUrl, isNull);
    });

    test('anonymous joinedAt is the UTC epoch sentinel', () {
      expect(
        Player.anonymous.joinedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('anonymous is value-equal to a freshly constructed sentinel', () {
      final manual = Player(
        uid: '',
        level: 1,
        totalXp: 0,
        joinedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      expect(Player.anonymous, equals(manual));
    });
  });
}
