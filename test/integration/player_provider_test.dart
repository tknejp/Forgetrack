// Integration tests for PlayerProvider.
//
// PlayerProvider is wired into the MultiProvider tree as a
// `ChangeNotifierProxyProvider2<AuthProvider, ProgressionEngineProvider,
// PlayerProvider>`. The proxy's `update` callback in main.dart pulls
// primitives from the upstream providers (uid / chrome from auth,
// rewardGrants + joinedAt from the engine ledger) and forwards them
// to `PlayerProvider.applySnapshot`. Phase 5 routes that snapshot
// through `Player.fromJournal`, so the seam tested here covers:
//
//   - rebuild + notify when rewardGrants change
//   - rebuild + notify when chrome-only fields change (auth notify)
//   - cache short-circuit when the same upstream snapshot is replayed
//     (notifyListeners must not fire)
//   - rebuild on sign-out → anonymous shape
//   - rpgModeEnabled passthrough
//
// Tests deliberately do not instantiate the live AuthProvider or
// ProgressionEngineProvider — those drag in Firebase / Isar setup
// that belongs to their own provider-level tests. PlayerProvider's
// input surface is primitives + an iterable, so the rebuild seam is
// exercised directly.
//
// See:
//   - lib/app/player_provider.dart
//   - lib/main.dart (proxy wiring)
//   - docs/domain_model/migration_plan.md Â§Phase 5.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/app/player_provider.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/level_curve.dart';
import 'package:forgetrack/domain/player/player.dart';

void main() {
  final joinedAt = DateTime.utc(2026, 1, 1);
  const levelCurve = LevelCurve();

  RewardGrantEvent xpGrant({
    required String eventKey,
    required int amount,
    DateTime? timestamp,
  }) {
    return RewardGrantEvent(
      eventKey: eventKey,
      timestamp: timestamp ?? DateTime.utc(2026, 1, 2),
      nodeId: ProgressionEntryId('node-$eventKey'),
      rewardOrdinal: 0,
      rewardKind: RewardGrantKind.xp,
      xpAmount: amount,
    );
  }

  test('initial player is the anonymous sentinel', () {
    final provider = PlayerProvider();
    expect(provider.player, equals(Player.anonymous));
  });

  test('applySnapshot rebuilds via Player.fromJournal and notifies', () {
    final provider = PlayerProvider();
    var notifications = 0;
    provider.addListener(() => notifications += 1);

    final grants = <RewardGrantEvent>[
      xpGrant(eventKey: 'a', amount: 100),
      xpGrant(eventKey: 'b', amount: 130),
    ];
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: grants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Alice',
      photoUrl: 'https://example.com/alice.png',
    );

    final expected = Player.fromJournal(
      uid: 'user-1',
      rewardGrants: grants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Alice',
      photoUrl: 'https://example.com/alice.png',
    );
    expect(provider.player, equals(expected));
    expect(provider.player.totalXp, 230);
    expect(notifications, 1);
  });

  test('cache hit: same iterable + same chrome does NOT fire notify', () {
    final provider = PlayerProvider();
    final grants = <RewardGrantEvent>[xpGrant(eventKey: 'a', amount: 100)];
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: grants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Alice',
    );

    var laterNotifications = 0;
    provider.addListener(() => laterNotifications += 1);
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: grants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Alice',
    );

    expect(laterNotifications, 0,
        reason: 'identical inputs must short-circuit notifyListeners');
  });

  test('different rewardGrants iterable rebuilds even with same totals', () {
    final provider = PlayerProvider();
    final firstGrants = <RewardGrantEvent>[
      xpGrant(eventKey: 'a', amount: 100),
    ];
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: firstGrants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
    );

    final secondGrants = <RewardGrantEvent>[
      xpGrant(eventKey: 'a', amount: 100),
    ];

    var notifications = 0;
    provider.addListener(() => notifications += 1);
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: secondGrants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
    );

    // Cache miss (new iterable reference) recomputes Player. The
    // resulting value object is `==`-equal to the previous one
    // (same XP / same level / same chrome), so notify is suppressed
    // by the Player.== guard inside applySnapshot.
    expect(notifications, 0);
    expect(provider.player.totalXp, 100);
  });

  test('appending an XP grant raises level/totalXp and notifies', () {
    final provider = PlayerProvider();
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: const <RewardGrantEvent>[],
      levelCurve: levelCurve,
      joinedAt: joinedAt,
    );

    var notifications = 0;
    provider.addListener(() => notifications += 1);
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: <RewardGrantEvent>[
        xpGrant(eventKey: 'a', amount: 50000),
      ],
      levelCurve: levelCurve,
      joinedAt: joinedAt,
    );

    expect(provider.player.totalXp, 50000);
    expect(provider.player.level, greaterThan(1));
    expect(notifications, 1);
  });

  test('chrome-only change (display name) rebuilds the player', () {
    final provider = PlayerProvider();
    final grants = <RewardGrantEvent>[xpGrant(eventKey: 'a', amount: 100)];
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: grants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Alice',
    );

    var notifications = 0;
    provider.addListener(() => notifications += 1);
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: grants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Bob',
    );

    expect(provider.player.displayName, 'Bob');
    expect(notifications, 1);
  });

  test('signing out flips the player back to the anonymous shape', () {
    final provider = PlayerProvider();
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: <RewardGrantEvent>[xpGrant(eventKey: 'a', amount: 100)],
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      displayName: 'Alice',
    );

    provider.applySnapshot(
      uid: '',
      rewardGrants: const <RewardGrantEvent>[],
      levelCurve: levelCurve,
      joinedAt: Player.anonymous.joinedAt,
    );

    expect(provider.player, equals(Player.anonymous));
  });

  test('rpgModeEnabled=false flows through to the cached player', () {
    final provider = PlayerProvider();
    provider.applySnapshot(
      uid: 'user-1',
      rewardGrants: const <RewardGrantEvent>[],
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      rpgModeEnabled: false,
    );
    expect(provider.player.rpgModeEnabled, isFalse);
  });
}