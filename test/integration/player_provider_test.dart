// Integration tests for PlayerProvider.
//
// Phase 4 of the domain refactor wires PlayerProvider into the
// MultiProvider tree as a `ChangeNotifierProxyProvider2<AuthProvider,
// ProgressionEngineProvider, PlayerProvider>`. The proxy's `update`
// callback in main.dart extracts primitives from the upstream
// providers and forwards them to `PlayerProvider.applySnapshot`, which
// is the seam tested here — covering both rebuild on upstream change
// and the value-equality short-circuit that suppresses redundant
// notifications.
//
// Tests deliberately do not instantiate the live AuthProvider or
// ProgressionEngineProvider — those drag in Firebase / Isar setup that
// belongs to their own provider-level tests. PlayerProvider's input
// surface is primitives, so the rebuild seam can be exercised
// directly.
//
// See:
//   - lib/app/player_provider.dart
//   - lib/main.dart (proxy wiring)
//   - docs/domain_model/migration_plan.md §Phase 4.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/app/player_provider.dart';
import 'package:forgetrack/domain/player/player.dart';

void main() {
  final joinedAt = DateTime.utc(2026, 1, 1);

  test('initial player is the anonymous sentinel', () {
    final provider = PlayerProvider();
    expect(provider.player, equals(Player.anonymous));
  });

  test('applySnapshot rebuilds the player and notifies listeners', () {
    final provider = PlayerProvider();
    var notifications = 0;
    provider.addListener(() => notifications += 1);

    provider.applySnapshot(
      uid: 'user-1',
      level: 5,
      totalXp: 1200,
      joinedAt: joinedAt,
      displayName: 'Alice',
      photoUrl: 'https://example.com/alice.png',
    );

    expect(provider.player.uid, 'user-1');
    expect(provider.player.level, 5);
    expect(provider.player.totalXp, 1200);
    expect(provider.player.joinedAt, joinedAt);
    expect(provider.player.displayName, 'Alice');
    expect(provider.player.photoUrl, 'https://example.com/alice.png');
    expect(provider.player.rpgModeEnabled, isTrue);
    expect(notifications, 1);
  });

  test('applySnapshot with identical inputs does NOT notify', () {
    final provider = PlayerProvider();

    provider.applySnapshot(
      uid: 'user-1',
      level: 5,
      totalXp: 1200,
      joinedAt: joinedAt,
      displayName: 'Alice',
      photoUrl: 'https://example.com/alice.png',
    );

    var laterNotifications = 0;
    provider.addListener(() => laterNotifications += 1);

    provider.applySnapshot(
      uid: 'user-1',
      level: 5,
      totalXp: 1200,
      joinedAt: joinedAt,
      displayName: 'Alice',
      photoUrl: 'https://example.com/alice.png',
    );

    expect(laterNotifications, 0,
        reason: 'value-equal snapshot must short-circuit notifyListeners');
  });

  test('applySnapshot notifies when only level changes', () {
    final provider = PlayerProvider();
    provider.applySnapshot(
      uid: 'user-1',
      level: 5,
      totalXp: 1200,
      joinedAt: joinedAt,
    );

    var levelUpNotifications = 0;
    provider.addListener(() => levelUpNotifications += 1);

    provider.applySnapshot(
      uid: 'user-1',
      level: 6,
      totalXp: 1500,
      joinedAt: joinedAt,
    );

    expect(provider.player.level, 6);
    expect(provider.player.totalXp, 1500);
    expect(levelUpNotifications, 1);
  });

  test('signing out flips the player back to the anonymous shape', () {
    final provider = PlayerProvider();
    provider.applySnapshot(
      uid: 'user-1',
      level: 5,
      totalXp: 1200,
      joinedAt: joinedAt,
      displayName: 'Alice',
    );

    provider.applySnapshot(
      uid: '',
      level: 1,
      totalXp: 0,
      joinedAt: Player.anonymous.joinedAt,
    );

    expect(provider.player, equals(Player.anonymous));
  });

  test('rpgModeEnabled=false flows through to the cached player', () {
    final provider = PlayerProvider();
    provider.applySnapshot(
      uid: 'user-1',
      level: 1,
      totalXp: 0,
      joinedAt: joinedAt,
      rpgModeEnabled: false,
    );
    expect(provider.player.rpgModeEnabled, isFalse);
  });
}
