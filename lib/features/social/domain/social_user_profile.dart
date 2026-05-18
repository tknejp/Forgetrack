import 'achievement_share.dart';

/// Denormalised per-user statistics mirrored from the Player
/// aggregate + Journal counters into Firestore for fast friend-list
/// rendering.
///
/// **Cache, not source of truth.** Phase 17 of the domain refactor
/// documents this explicitly (`docs/domain_model/proposal.md` §5):
/// every field here can be re-derived from the canonical Player
/// aggregate (`level`, `totalXp`) + the engine's ledger
/// (`unlockedAchievementCount`, `grantedRewardCount`, streaks). The
/// Firestore row exists only because friends' tabs need a single
/// document read per friend — pulling the full ledger over the
/// network on every render would be prohibitive.
///
/// **Rebuild trigger.** Any time the local Player or Journal mutates
/// (claim, level-up, streak roll), `SocialProvider.publishProfile`
/// pushes a fresh snapshot. Phase 20 (`JournalProjection`) will
/// promote this into a first-class projection so the rebuild happens
/// via a documented contract rather than ad-hoc.
class SocialUserStats {
  const SocialUserStats({
    required this.level,
    required this.totalXp,
    required this.unlockedAchievementCount,
    required this.grantedRewardCount,
    required this.bestStepsStreak,
    required this.bestNutritionStreak,
    this.updatedAt,
  });

  final int level;
  final int totalXp;
  final int unlockedAchievementCount;

  /// Total reward grants in the engine ledger. V2 grants rewards
  /// immediately at evaluation time, so there is no claimed/pending
  /// split — every grant is by definition granted.
  final int grantedRewardCount;
  final int bestStepsStreak;
  final int bestNutritionStreak;
  final DateTime? updatedAt;
}

/// Denormalised public-profile row published to Firestore for a
/// signed-in user.
///
/// **Cache, not source of truth.** Owned by the Social feature for
/// friend-discovery + leaderboard reads; rebuilt from Player + Loadout
/// + Inventory + Journal on every `SocialProvider.publishProfile`
/// call. Renaming or restructuring fields here is a Firestore wire-
/// format change — Phase 17 explicitly does NOT touch the shape.
class SocialUserProfile {
  const SocialUserProfile({
    required this.uid,
    required this.displayName,
    required this.handle,
    required this.email,
    required this.socialEnabled,
    required this.stats,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.pinnedAchievementIds = const [],
    this.equippedCosmetics = const SocialEquippedCosmetics.empty(),
  });

  final String uid;
  final String displayName;
  final String handle;
  final String email;
  final String? photoUrl;
  final bool socialEnabled;
  final SocialUserStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> pinnedAchievementIds;
  final SocialEquippedCosmetics equippedCosmetics;
}

/// Subset of [Loadout] (cosmetics feature) that is broadcast to
/// friends through the Firestore profile mirror. Kept as a separate
/// type because the Social feature does not import the cosmetics
/// catalog — only ids cross the network boundary.
class SocialEquippedCosmetics {
  const SocialEquippedCosmetics({
    this.frameId,
    this.relicId,
    this.backgroundId,
    this.emblemId,
    this.companionId,
    this.titleFlairId,
    this.mapEffectId,
  });

  const SocialEquippedCosmetics.empty()
      : frameId = null,
        relicId = null,
        backgroundId = null,
        emblemId = null,
        companionId = null,
        titleFlairId = null,
        mapEffectId = null;

  final String? frameId;
  final String? relicId;
  final String? backgroundId;
  final String? emblemId;
  final String? companionId;
  final String? titleFlairId;
  final String? mapEffectId;

  bool get hasAny =>
      frameId != null ||
      relicId != null ||
      backgroundId != null ||
      emblemId != null ||
      companionId != null ||
      titleFlairId != null ||
      mapEffectId != null;
}

/// Bundle the Social repository takes when pushing a fresh profile
/// snapshot to Firestore. Carries everything the wire format needs in
/// one immutable payload so the provider doesn't have to assemble
/// arguments at every call site.
class SocialProfileSyncPayload {
  const SocialProfileSyncPayload({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.handle,
    required this.photoUrl,
    required this.socialEnabled,
    required this.stats,
    required this.unlockedAchievements,
    required this.equippedCosmetics,
  });

  final String uid;
  final String displayName;
  final String email;
  final String handle;
  final String? photoUrl;
  final bool socialEnabled;
  final SocialUserStats stats;
  final List<SocialUnlockedAchievement> unlockedAchievements;
  final SocialEquippedCosmetics equippedCosmetics;

  SocialProfileSyncPayload copyWith({
    String? displayName,
    String? email,
    String? handle,
    Object? photoUrl = _unchanged,
    bool? socialEnabled,
    SocialUserStats? stats,
    List<SocialUnlockedAchievement>? unlockedAchievements,
    SocialEquippedCosmetics? equippedCosmetics,
  }) {
    return SocialProfileSyncPayload(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      photoUrl:
          identical(photoUrl, _unchanged) ? this.photoUrl : photoUrl as String?,
      socialEnabled: socialEnabled ?? this.socialEnabled,
      stats: stats ?? this.stats,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
    );
  }
}

const Object _unchanged = Object();
