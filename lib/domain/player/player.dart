import 'package:meta/meta.dart';

import '../journal/journal_event.dart';
import 'level_curve.dart';

/// Player aggregate root for the single-player Forgetrack app.
///
/// Bundles the per-user durable state surfaces the UI reads today:
/// level / totalXp / joined-at timestamp / RPG mode toggle / display
/// chrome. Immutable value object with a `const` ctor and value-based
/// equality.
///
/// **Source-of-truth.** Phase 5 of the domain refactor makes
/// [Player.fromJournal] the canonical computation for `level` and
/// `totalXp`. The factory sums XP from `RewardGrantEvent`s and applies
/// the supplied [LevelCurve]. Both [PlayerProvider] (UI-facing
/// snapshot) and `ProgressionEngineProvider` (engine input filler)
/// invoke this factory against the same ledger — they share the
/// derivation rather than re-deriving level/XP locally. See
/// `docs/site/data/decisions.json` ADR `player-from-journal-canonical`
/// for why both providers go through the factory instead of one
/// depending on the other.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.1 (Player AR).
///   - `docs/domain_model/migration_plan.md` §Phase 4 (scaffolding) +
///     §Phase 5 (Player as source-of-truth).
@immutable
class Player {
  const Player({
    required this.uid,
    required this.level,
    required this.totalXp,
    required this.joinedAt,
    this.rpgModeEnabled = true,
    this.displayName,
    this.photoUrl,
  });

  /// Stable per-user identifier matching `Identity.id`. Empty string
  /// when no user is signed in — providers fabricate a "no-player"
  /// instance rather than nulling the whole aggregate, so widgets that
  /// read a single field don't need a null check at every site.
  final String uid;

  final int level;
  final int totalXp;

  /// First-touch timestamp anchoring retroactive claim windows.
  /// Sourced from `ProgressionEngineProvider.joinedAt` today (which
  /// persists it in SharedPreferences via
  /// `forgetrack_joined_at_iso`). A later phase will derive it from
  /// the Journal's earliest event.
  final DateTime joinedAt;

  /// View-layer filter toggle (proposal §10 Q7). Engine evaluator
  /// receives this through `EngineEvaluationInput.rpgModeEnabled`;
  /// presentation surfaces hide cosmetic / RPG framing when false.
  /// Defaults to `true` — no settings surface persists this yet,
  /// matching the engine's existing default.
  final bool rpgModeEnabled;

  /// Optional profile-chrome fields mirrored from [Identity]. Null
  /// before sign-in or when the upstream auth provider has not yet
  /// resolved a display name / avatar.
  final String? displayName;
  final String? photoUrl;

  /// Sentinel "no signed-in user" instance. Cheaper than nullable
  /// providers — UI can read `player.level` without a null guard, and
  /// gets `1` / `0` (matching `EngineProfile.zero`).
  static final Player anonymous = Player(
    uid: '',
    level: 1,
    totalXp: 0,
    joinedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// Canonical Player derivation from a slice of the Journal.
  ///
  /// [rewardGrants] must be the full set of XP-bearing reward events
  /// the player has accumulated — typically `LedgerSnapshot.rewardGrants`
  /// in production, or a hand-rolled list in tests. Non-XP grants
  /// (cosmetic / companion availability / chapter unlock / …) are
  /// ignored by the XP sum.
  ///
  /// Performance: a single pass over [rewardGrants] plus one
  /// [LevelCurve.resolve] call. For a 1000-event ledger this resolves
  /// in well under 10ms (verified in
  /// `test/domain/player/player_from_journal_test.dart`); see
  /// `PlayerProvider`'s lazy invalidation comment for the cache that
  /// keeps repeated reads off the hot path.
  factory Player.fromJournal({
    required String uid,
    required Iterable<RewardGrantEvent> rewardGrants,
    required LevelCurve levelCurve,
    required DateTime joinedAt,
    bool rpgModeEnabled = true,
    String? displayName,
    String? photoUrl,
  }) {
    final totalXp = totalXpFromGrants(rewardGrants);
    final resolution = levelCurve.resolve(totalXp);
    return Player(
      uid: uid,
      level: resolution.level,
      totalXp: resolution.totalXp,
      joinedAt: joinedAt,
      rpgModeEnabled: rpgModeEnabled,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// Sum of `xpAmount` across XP-kind reward grants. Exposed as a
  /// public static so `ProgressionEngineProvider` can keep its
  /// `EngineProfile` derivation (which needs `LevelResolution`'s full
  /// shape) going through the same XP-sum logic that
  /// [Player.fromJournal] uses — one canonical XP sum, two consumers.
  static int totalXpFromGrants(Iterable<RewardGrantEvent> rewardGrants) {
    var sum = 0;
    for (final grant in rewardGrants) {
      if (grant.rewardKind == RewardGrantKind.xp) {
        sum += grant.xpAmount ?? 0;
      }
    }
    return sum;
  }

  Player copyWith({
    String? uid,
    int? level,
    int? totalXp,
    DateTime? joinedAt,
    bool? rpgModeEnabled,
    String? displayName,
    String? photoUrl,
  }) {
    return Player(
      uid: uid ?? this.uid,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      joinedAt: joinedAt ?? this.joinedAt,
      rpgModeEnabled: rpgModeEnabled ?? this.rpgModeEnabled,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.uid == uid &&
        other.level == level &&
        other.totalXp == totalXp &&
        other.joinedAt == joinedAt &&
        other.rpgModeEnabled == rpgModeEnabled &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        level,
        totalXp,
        joinedAt,
        rpgModeEnabled,
        displayName,
        photoUrl,
      );

  @override
  String toString() =>
      'Player(uid: $uid, level: $level, totalXp: $totalXp, '
      'joinedAt: $joinedAt, rpgModeEnabled: $rpgModeEnabled, '
      'displayName: $displayName, photoUrl: $photoUrl)';
}
