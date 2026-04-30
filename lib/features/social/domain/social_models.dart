class SocialUserStats {
  const SocialUserStats({
    required this.level,
    required this.totalXp,
    required this.unlockedAchievementCount,
    required this.claimedRewardCount,
    required this.pendingRewardCount,
    required this.bestStepsStreak,
    required this.bestNutritionStreak,
    this.updatedAt,
  });

  final int level;
  final int totalXp;
  final int unlockedAchievementCount;
  final int claimedRewardCount;
  final int pendingRewardCount;
  final int bestStepsStreak;
  final int bestNutritionStreak;
  final DateTime? updatedAt;
}

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

class SocialUnlockedAchievement {
  const SocialUnlockedAchievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.type,
    required this.unlockedAt,
    this.domain,
    this.ruleId,
  });

  final String achievementId;
  final String title;
  final String description;
  final String difficulty;
  final String type;
  final String? domain;
  final String? ruleId;
  final DateTime unlockedAt;
}

enum SocialFriendRequestStatus {
  pending,
  accepted,
  declined,
}

class SocialFriendRequest {
  const SocialFriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final SocialFriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == SocialFriendRequestStatus.pending;
}

class SocialFriendship {
  const SocialFriendship({
    required this.id,
    required this.memberUids,
    required this.createdAt,
    this.sourceRequestId,
  });

  final String id;
  final List<String> memberUids;
  final DateTime createdAt;
  final String? sourceRequestId;

  String counterpartFor(String uid) {
    for (final memberUid in memberUids) {
      if (memberUid != uid) return memberUid;
    }
    return uid;
  }
}

enum SocialShareVisibility {
  friends,
}

class SocialAchievementActorSnapshot {
  const SocialAchievementActorSnapshot({
    required this.displayName,
    this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
}

class SocialAchievementSnapshot {
  const SocialAchievementSnapshot({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.type,
    this.domain,
  });

  final String title;
  final String description;
  final String difficulty;
  final String type;
  final String? domain;
}

class SocialReactionSnapshot {
  const SocialReactionSnapshot({required this.displayName, this.photoUrl});
  final String displayName;
  final String? photoUrl;
}

class SocialAchievementShare {
  const SocialAchievementShare({
    required this.id,
    required this.actorUid,
    required this.achievementId,
    required this.createdAt,
    required this.visibility,
    required this.actorSnapshot,
    required this.achievementSnapshot,
    this.message,
    this.reactions = const {},
    this.reactorSnapshots = const {},
  });

  final String id;
  final String actorUid;
  final String achievementId;
  final DateTime createdAt;
  final String? message;
  final SocialShareVisibility visibility;
  final SocialAchievementActorSnapshot actorSnapshot;
  final SocialAchievementSnapshot achievementSnapshot;

  /// uid → emoji
  final Map<String, String> reactions;

  /// uid → snapshot
  final Map<String, SocialReactionSnapshot> reactorSnapshots;
}

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.shareId,
    required this.achievementTitle,
    required this.emoji,
    required this.createdAt,
    required this.read,
    this.actorPhoto,
  });

  final String id;
  final String actorUid;
  final String actorName;
  final String? actorPhoto;
  final String shareId;
  final String achievementTitle;
  final String emoji;
  final DateTime createdAt;
  final bool read;
}

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

String normalizeSocialHandle(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized;
}

String buildDefaultSocialHandle({
  required String uid,
  required String email,
  String? displayName,
}) {
  final candidates = <String>[
    if (displayName != null && displayName.trim().isNotEmpty) displayName,
    email.split('@').first,
    'user_$uid',
  ];

  for (final candidate in candidates) {
    final handle = normalizeSocialHandle(candidate);
    if (handle.isNotEmpty) return handle;
  }

  return 'user';
}

String buildNumberedSocialHandle({
  required String baseHandle,
  required int suffix,
}) {
  final normalized = normalizeSocialHandle(baseHandle);
  final fallback = normalized.isNotEmpty ? normalized : 'user';
  if (suffix <= 0) return fallback;
  return '${fallback}_$suffix';
}

List<String> buildSocialHandleSearchTokens(String handle) {
  final normalized = normalizeSocialHandle(handle);
  if (normalized.isEmpty) return const [];

  final tokens = <String>{};
  for (var i = 1; i <= normalized.length; i++) {
    tokens.add(normalized.substring(0, i));
  }

  final ordered = tokens.toList()..sort((a, b) => a.length.compareTo(b.length));
  return ordered;
}

String buildSocialFriendshipId(String firstUid, String secondUid) {
  final sorted = [firstUid, secondUid]..sort();
  return '${sorted[0]}__${sorted[1]}';
}

String buildSocialParticipantsKey(String firstUid, String secondUid) {
  final sorted = [firstUid, secondUid]..sort();
  return '${sorted[0]}:${sorted[1]}';
}
