// Phase 5 source-of-truth verification for Player.fromJournal.
//
// Three guarantees we want pinned by tests:
//
// 1. **Golden derivation.** Feeding a known XP-grant sequence to
//    Player.fromJournal yields the same level + totalXp that
//    LevelCurve.resolve(sum) would produce directly. Non-XP grants
//    (cosmetic / chapter unlock / etc.) must NOT contribute to the
//    XP total — the rewardKind discriminator is load-bearing.
//
// 2. **Side-by-side parity with the engine's derivation.** Before
//    Phase 5, ProgressionEngineProvider summed XP and resolved a
//    level inline (`_totalClaimedXp` + `_levelPolicy.resolve`).
//    Phase 5 routes both that engine path AND PlayerProvider through
//    the same Player.fromJournal factory; the test mimics the engine's
//    pre-Phase-5 inline derivation for a handful of seeded ledgers
//    and asserts the numbers match. Catches any future drift if
//    someone restructures the XP sum.
//
// 3. **Performance gate.** 1000 RewardGrantEvents must resolve to a
//    Player in well under 10ms — the Phase 5 DoD bullet. The fold +
//    resolve is O(n); blowing past 10ms means something accidentally
//    quadratic has been introduced.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/level_curve.dart';
import 'package:forgetrack/domain/player/player.dart';

void main() {
  final joinedAt = DateTime.utc(2026, 1, 1);
  const levelCurve = LevelCurve();

  RewardGrantEvent xpGrant({
    required String key,
    required int amount,
    DateTime? timestamp,
  }) {
    return RewardGrantEvent(
      eventKey: key,
      timestamp: timestamp ?? DateTime.utc(2026, 1, 2),
      nodeId: 'node-$key',
      rewardOrdinal: 0,
      rewardKind: RewardGrantKind.xp,
      xpAmount: amount,
    );
  }

  RewardGrantEvent cosmeticGrant(String key) {
    return RewardGrantEvent(
      eventKey: key,
      timestamp: DateTime.utc(2026, 1, 2),
      nodeId: 'node-$key',
      rewardOrdinal: 0,
      rewardKind: RewardGrantKind.cosmetic,
      cosmeticId: 'cos-$key',
    );
  }

  group('Player.totalXpFromGrants', () {
    test('empty iterable yields zero', () {
      expect(Player.totalXpFromGrants(const []), 0);
    });

    test('sums only RewardGrantKind.xp grants', () {
      final grants = <RewardGrantEvent>[
        xpGrant(key: 'a', amount: 230),
        cosmeticGrant('c1'),
        xpGrant(key: 'b', amount: 120),
        cosmeticGrant('c2'),
      ];
      expect(Player.totalXpFromGrants(grants), 350);
    });

    test('null xpAmount on an xp-kind grant is treated as zero', () {
      final grants = <RewardGrantEvent>[
        RewardGrantEvent(
          eventKey: 'k',
          timestamp: DateTime.utc(2026, 1, 2),
          nodeId: 'n',
          rewardOrdinal: 0,
          rewardKind: RewardGrantKind.xp,
          // xpAmount intentionally omitted
        ),
        xpGrant(key: 'b', amount: 50),
      ];
      expect(Player.totalXpFromGrants(grants), 50);
    });
  });

  group('Player.fromJournal — golden states', () {
    test('zero XP yields level 1 totalXp 0', () {
      final player = Player.fromJournal(
        uid: 'u',
        rewardGrants: const [],
        levelCurve: levelCurve,
        joinedAt: joinedAt,
      );
      expect(player.level, 1);
      expect(player.totalXp, 0);
    });

    test('XP under first threshold stays at level 1', () {
      // levelCurve.xpRequiredForLevel(2) is the first threshold —
      // anything strictly below keeps the player at level 1.
      final threshold = levelCurve.xpRequiredForLevel(2);
      final justBelow = threshold - 1;
      final player = Player.fromJournal(
        uid: 'u',
        rewardGrants: <RewardGrantEvent>[
          xpGrant(key: 'g', amount: justBelow),
        ],
        levelCurve: levelCurve,
        joinedAt: joinedAt,
      );
      expect(player.totalXp, justBelow);
      expect(player.level, 1);
    });

    test('reaching threshold N advances to level N', () {
      final threshold = levelCurve.xpRequiredForLevel(5);
      final player = Player.fromJournal(
        uid: 'u',
        rewardGrants: <RewardGrantEvent>[
          xpGrant(key: 'g', amount: threshold),
        ],
        levelCurve: levelCurve,
        joinedAt: joinedAt,
      );
      expect(player.totalXp, threshold);
      expect(player.level, 5);
    });

    test('non-XP rewards do not bump level or totalXp', () {
      final player = Player.fromJournal(
        uid: 'u',
        rewardGrants: <RewardGrantEvent>[
          cosmeticGrant('c1'),
          cosmeticGrant('c2'),
        ],
        levelCurve: levelCurve,
        joinedAt: joinedAt,
      );
      expect(player.level, 1);
      expect(player.totalXp, 0);
    });

    test('chrome fields and rpgModeEnabled pass through', () {
      final player = Player.fromJournal(
        uid: 'u',
        rewardGrants: const [],
        levelCurve: levelCurve,
        joinedAt: joinedAt,
        rpgModeEnabled: false,
        displayName: 'Alice',
        photoUrl: 'https://example.com/a.png',
      );
      expect(player.rpgModeEnabled, isFalse);
      expect(player.displayName, 'Alice');
      expect(player.photoUrl, 'https://example.com/a.png');
      expect(player.joinedAt, joinedAt);
      expect(player.uid, 'u');
    });
  });

  group('Side-by-side parity with engine inline derivation', () {
    // Re-implementation of the pre-Phase-5 engine inline code, kept
    // here as the side-by-side oracle. If a future change to
    // Player.fromJournal or LevelCurve drifts this, the test fails
    // with the exact level/XP mismatch in the message.
    int legacyTotalXp(Iterable<RewardGrantEvent> grants) {
      var sum = 0;
      for (final e in grants) {
        if (e.rewardKind == RewardGrantKind.xp) {
          sum += e.xpAmount ?? 0;
        }
      }
      return sum;
    }

    LevelResolution legacyResolve(Iterable<RewardGrantEvent> grants) {
      return levelCurve.resolve(legacyTotalXp(grants));
    }

    final seedFixtures = <String, List<RewardGrantEvent>>{
      'empty': const <RewardGrantEvent>[],
      'one-small-xp': <RewardGrantEvent>[xpGrant(key: 'a', amount: 100)],
      'mixed-with-cosmetics': <RewardGrantEvent>[
        xpGrant(key: 'a', amount: 230),
        cosmeticGrant('c1'),
        xpGrant(key: 'b', amount: 120),
        cosmeticGrant('c2'),
        xpGrant(key: 'c', amount: 60),
      ],
      'crosses-level-5': <RewardGrantEvent>[
        for (var i = 0; i < 20; i++) xpGrant(key: 's$i', amount: 250),
      ],
      'crosses-level-30': <RewardGrantEvent>[
        for (var i = 0; i < 600; i++) xpGrant(key: 't$i', amount: 230),
      ],
    };

    seedFixtures.forEach((label, grants) {
      test('fixture "$label": Player.fromJournal matches inline derivation',
          () {
        final player = Player.fromJournal(
          uid: 'u',
          rewardGrants: grants,
          levelCurve: levelCurve,
          joinedAt: joinedAt,
        );
        final legacy = legacyResolve(grants);
        expect(player.totalXp, legacy.totalXp,
            reason: 'totalXp diverged from legacy inline sum');
        expect(player.level, legacy.level,
            reason: 'level diverged from legacy LevelCurve.resolve');
      });
    });
  });

  group('Performance gate', () {
    test('1000 reward grants resolve to a Player in well under 10 ms', () {
      final grants = <RewardGrantEvent>[
        for (var i = 0; i < 1000; i++) xpGrant(key: 'g$i', amount: 230),
      ];

      // Warm-up — first call pays for any JIT / class-init cost we
      // do not want polluting the measurement.
      Player.fromJournal(
        uid: 'u',
        rewardGrants: grants,
        levelCurve: levelCurve,
        joinedAt: joinedAt,
      );

      final sw = Stopwatch()..start();
      final player = Player.fromJournal(
        uid: 'u',
        rewardGrants: grants,
        levelCurve: levelCurve,
        joinedAt: joinedAt,
      );
      sw.stop();

      // 10ms is the DoD bullet; we expect well under 1ms in practice
      // on a fold of 1000 ints + a level resolve. The looser ceiling
      // keeps the test stable on slow CI runners without losing the
      // regression signal — if this blows past 10ms, something
      // accidentally quadratic has been introduced.
      expect(sw.elapsedMilliseconds, lessThan(10),
          reason: 'Player.fromJournal must stay O(n) over rewardGrants');
      expect(player.totalXp, 230 * 1000);
      expect(player.level, greaterThan(1));
    });
  });
}
