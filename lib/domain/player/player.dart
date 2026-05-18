import 'package:meta/meta.dart';

/// Player aggregate root for the single-player Forgetrack app.
///
/// Phase 4 of the domain refactor introduces [Player] as a value object
/// that bundles the per-user durable state surfaces the UI reads today
/// (level / totalXp / joined-at timestamp / RPG mode toggle / display
/// chrome). It is intentionally a **read-through wrapper** in this
/// phase — its fields are populated from the existing providers
/// (`AuthProvider`, `ProgressionEngineProvider`) and nothing reads
/// through [Player] yet.
///
/// Source-of-truth migration (level / totalXp computed from the
/// [Journal] rather than the engine's [EngineProfile]) lands in
/// Phase 5. Until then [Player] is shape-only — verifying the seam
/// is correct without changing dataflow.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.1 (Player AR).
///   - `docs/domain_model/migration_plan.md` §Phase 4 (scaffolding) and
///     §Phase 5 (Player-as-source-of-truth).
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
  /// Sourced from `ProgressionEngineProvider.joinedAt` in Phase 4 (the
  /// engine persists it in SharedPreferences via
  /// `forgetrack_joined_at_iso`); Phase 5+ will derive it from the
  /// Journal's earliest event.
  final DateTime joinedAt;

  /// View-layer filter toggle (proposal §10 Q7). Engine evaluator
  /// receives this through `EngineEvaluationInput.rpgModeEnabled`;
  /// presentation surfaces hide cosmetic / RPG framing when false.
  /// Defaults to `true` in Phase 4 — no settings surface persists it
  /// yet, matching the engine's existing default.
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
