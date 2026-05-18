import 'package:flutter/foundation.dart';

import '../domain/player/player.dart';

/// Provider facade that exposes a [Player] read-through the existing
/// auth + progression-engine providers.
///
/// Phase 4 of the domain refactor stands the aggregate up without
/// changing the source-of-truth dataflow. The provider receives
/// primitives via [applySnapshot]; the proxy declared in `main.dart`
/// extracts those primitives from `AuthProvider` and
/// `ProgressionEngineProvider` on every upstream notification:
///
///   - `uid`, `displayName`, `photoUrl` — `AuthProvider.user`.
///   - `level`, `totalXp` — `ProgressionEngineProvider.profile`.
///   - `joinedAt` — `ProgressionEngineProvider.joinedAt`.
///   - `rpgModeEnabled` defaults to `true` — no settings surface
///     persists this yet; the engine evaluator's
///     `EngineEvaluationInput.rpgModeEnabled` uses the same default.
///
/// Phase 5+ will repoint the level / XP / joinedAt sources at the
/// [Journal] directly so [Player] becomes the source of truth, but
/// per the migration plan **no consumer reads through [Player] in
/// Phase 4** — this provider is intentionally unused at first.
///
/// Keeping the provider's input surface narrow (primitives instead
/// of the live `AuthProvider` / `ProgressionEngineProvider` types)
/// keeps the unit test surface narrow too — tests drive
/// [applySnapshot] directly without spinning up Firebase or Isar.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider();

  Player _player = Player.anonymous;

  /// Current [Player] snapshot. Equal to [Player.anonymous] until the
  /// first [applySnapshot] call completes; consumers can read fields
  /// (e.g. `player.level`) without a null guard.
  Player get player => _player;

  /// Rebuild [player] from upstream-derived primitives. Called by
  /// the `ChangeNotifierProxyProvider2.update` callback in
  /// `main.dart` whenever auth or the progression engine notifies.
  ///
  /// Notifies listeners only when the new value differs from the
  /// cached one; identical upstream snapshots do not produce a
  /// downstream rebuild storm.
  void applySnapshot({
    required String uid,
    required int level,
    required int totalXp,
    required DateTime joinedAt,
    String? displayName,
    String? photoUrl,
    bool rpgModeEnabled = true,
  }) {
    final next = Player(
      uid: uid,
      level: level,
      totalXp: totalXp,
      joinedAt: joinedAt,
      rpgModeEnabled: rpgModeEnabled,
      displayName: displayName,
      photoUrl: photoUrl,
    );
    if (next == _player) return;
    _player = next;
    notifyListeners();
  }

  @visibleForTesting
  set debugPlayer(Player value) {
    if (value == _player) return;
    _player = value;
    notifyListeners();
  }
}
