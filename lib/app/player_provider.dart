import 'package:flutter/foundation.dart';

import '../domain/journal/journal_event.dart';
import '../domain/player/level_curve.dart';
import '../domain/player/player.dart';

/// Provider facade that exposes a [Player] computed from the Journal.
///
/// **Phase 5 source-of-truth shift.** The provider no longer reads a
/// pre-computed `level` / `totalXp` from `ProgressionEngineProvider`.
/// Instead the proxy in `main.dart` passes the ledger's reward grants
/// + a [LevelCurve] into [applySnapshot], which routes through
/// [Player.fromJournal] — the canonical Player derivation. Both this
/// provider and `ProgressionEngineProvider`'s `EngineProfile` getter
/// invoke the same factory, so the two consumers can never drift.
///
/// **Lazy cache.** Each [applySnapshot] checks whether the supplied
/// rewardGrants iterable is identical (by reference) to the one used
/// for the last build AND whether ancillary fields (uid, joinedAt,
/// display chrome, RPG flag) are unchanged. When everything matches,
/// the rebuild is skipped — no XP fold, no level resolve, no
/// notifyListeners. This matters because the proxy fires on every
/// upstream notification (auth → display name change, engine → ledger
/// refresh, engine → settings change), and most of those don't shift
/// the XP totals.
///
/// The 1000-event resolve is well under 10ms by itself (see
/// `test/domain/player/player_from_journal_test.dart` perf case), so
/// the cache is about cutting churn through the widget tree more than
/// shaving CPU.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider();

  Player _player = Player.anonymous;

  // Cache keys for the lazy-skip check. The rewardGrants iterable is
  // compared by reference because LedgerSnapshot is immutable and
  // replaced wholesale on each refresh — identical reference ⇒
  // identical XP, no need to re-fold. Other fields piggyback so a
  // chrome-only auth notify (display name change) still rebuilds the
  // visible Player even when the ledger ref is stable.
  Iterable<RewardGrantEvent>? _lastRewardGrants;
  String? _lastUid;
  DateTime? _lastJoinedAt;
  bool? _lastRpgModeEnabled;
  String? _lastDisplayName;
  String? _lastPhotoUrl;
  LevelCurve? _lastLevelCurve;

  /// Current [Player] snapshot. Equal to [Player.anonymous] until the
  /// first [applySnapshot] call completes; consumers can read fields
  /// (e.g. `player.level`) without a null guard.
  Player get player => _player;

  /// Rebuild [player] from upstream-derived primitives + the ledger
  /// reward-grants iterable. Called by the
  /// `ChangeNotifierProxyProvider2.update` callback in `main.dart`
  /// whenever auth or the progression engine notifies.
  ///
  /// [rewardGrants] is forwarded into [Player.fromJournal] to derive
  /// `level` / `totalXp`; pass `const []` when the engine's ledger
  /// hasn't loaded yet.
  ///
  /// Skips both the recompute and the notify when the inputs are
  /// reference-equal to the last call — see the class-level lazy
  /// cache comment.
  void applySnapshot({
    required String uid,
    required Iterable<RewardGrantEvent> rewardGrants,
    required LevelCurve levelCurve,
    required DateTime joinedAt,
    String? displayName,
    String? photoUrl,
    bool rpgModeEnabled = true,
  }) {
    final cacheHit = identical(_lastRewardGrants, rewardGrants) &&
        identical(_lastLevelCurve, levelCurve) &&
        _lastUid == uid &&
        _lastJoinedAt == joinedAt &&
        _lastRpgModeEnabled == rpgModeEnabled &&
        _lastDisplayName == displayName &&
        _lastPhotoUrl == photoUrl;
    if (cacheHit) return;

    final next = Player.fromJournal(
      uid: uid,
      rewardGrants: rewardGrants,
      levelCurve: levelCurve,
      joinedAt: joinedAt,
      rpgModeEnabled: rpgModeEnabled,
      displayName: displayName,
      photoUrl: photoUrl,
    );

    _lastRewardGrants = rewardGrants;
    _lastLevelCurve = levelCurve;
    _lastUid = uid;
    _lastJoinedAt = joinedAt;
    _lastRpgModeEnabled = rpgModeEnabled;
    _lastDisplayName = displayName;
    _lastPhotoUrl = photoUrl;

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
